//! FPF 1.1 reference implementation — encode/decode of the transport payload.
//! Mirrors the JS reference implementation at ../js/lib/fpf.js.

use std::io::{Read, Write};

use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use flate2::read::DeflateDecoder;
use flate2::write::DeflateEncoder;
use flate2::Compression;
use serde::{Deserialize, Serialize};

const PREFIX_RAW: &str = "1.";
const PREFIX_DEFLATE: &str = "2.";

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct FpfDocument {
    pub fpf: String,
    pub kind: String,
    pub legal: Legal,
    pub einvoice: Einvoice,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub billing: Option<Billing>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub contact: Option<Contact>,
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct Legal {
    pub country: String,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub form: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ids: Option<Vec<LegalId>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub vat: Option<String>,
}

// A registration identifier (EN 16931 BT-47) qualified by its ICD scheme code
// (BT-47-1), drawn from the same registry as einvoice.eas. What a scheme means —
// 0002 is a French SIREN, 0009 a SIRET — belongs to the country profiles.
#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct LegalId {
    pub scheme: String,
    pub value: String,
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq)]
pub struct Einvoice {
    pub eas: String,
    pub address: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub platform: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Default)]
pub struct Billing {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub street: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub zip: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub city: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub country: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, Clone, PartialEq, Default)]
pub struct Contact {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    #[serde(rename = "ref", skip_serializing_if = "Option::is_none")]
    pub r#ref: Option<String>,
    #[serde(rename = "buyerReference", skip_serializing_if = "Option::is_none")]
    pub buyer_reference: Option<String>,
}

// `ref` is a Rust reserved keyword — the field above is named `r#ref` (raw
// identifier) and explicitly renamed to the JSON key "ref" via #[serde(rename = "ref")].
// A `///` doc comment is deliberately not used here: with a blank line before
// the next item, it would attach to `FpfError` below instead of to `Contact`.

#[derive(Debug)]
pub enum FpfError {
    UnknownPrefix,
    Base64(base64::DecodeError),
    Inflate(std::io::Error),
    Json(serde_json::Error),
}

impl std::fmt::Display for FpfError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FpfError::UnknownPrefix => write!(f, "FPF: unknown payload prefix"),
            FpfError::Base64(e) => write!(f, "FPF: base64 decode error: {e}"),
            FpfError::Inflate(e) => write!(f, "FPF: inflate error: {e}"),
            FpfError::Json(e) => write!(f, "FPF: JSON error: {e}"),
        }
    }
}

impl std::error::Error for FpfError {}

impl From<base64::DecodeError> for FpfError {
    fn from(e: base64::DecodeError) -> Self {
        FpfError::Base64(e)
    }
}

impl From<std::io::Error> for FpfError {
    fn from(e: std::io::Error) -> Self {
        FpfError::Inflate(e)
    }
}

impl From<serde_json::Error> for FpfError {
    fn from(e: serde_json::Error) -> Self {
        FpfError::Json(e)
    }
}

/// Serializes and encodes a document into a transport payload. Infallible:
/// serializing an already-built `FpfDocument` and compressing in memory
/// cannot reasonably fail, mirroring the JS reference which documents no
/// error path for `encode`.
pub fn encode(doc: &FpfDocument, compress: bool) -> String {
    let bytes = serde_json::to_vec(doc).expect("FpfDocument always serializes");
    if !compress {
        return format!("{PREFIX_RAW}{}", URL_SAFE_NO_PAD.encode(&bytes));
    }
    let mut encoder = DeflateEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(&bytes).expect("in-memory write cannot fail");
    let deflated = encoder.finish().expect("in-memory finish cannot fail");
    format!("{PREFIX_DEFLATE}{}", URL_SAFE_NO_PAD.encode(&deflated))
}

/// Decodes a transport payload back into a document.
pub fn decode(payload: &str) -> Result<FpfDocument, FpfError> {
    let bytes = if let Some(body) = payload.strip_prefix(PREFIX_DEFLATE) {
        let compressed = URL_SAFE_NO_PAD.decode(body)?;
        let mut decoder = DeflateDecoder::new(&compressed[..]);
        let mut out = Vec::new();
        decoder.read_to_end(&mut out)?;
        out
    } else if let Some(body) = payload.strip_prefix(PREFIX_RAW) {
        URL_SAFE_NO_PAD.decode(body)?
    } else {
        return Err(FpfError::UnknownPrefix);
    };
    Ok(serde_json::from_slice(&bytes)?)
}

fn is_ascii_digits(s: &str, len: usize) -> bool {
    s.len() == len && s.chars().all(|c| c.is_ascii_digit())
}

fn is_country_code(s: &str) -> bool {
    s.len() == 2 && s.chars().all(|c| c.is_ascii_uppercase())
}

/// Structural + semantic validation mirroring the JS reference's `validate()`.
/// Unlike JS, most "is this the right shape" checks are already guaranteed
/// by successfully constructing an `FpfDocument` (via `decode` or directly) —
/// this only checks constraints the type system cannot express: exact
/// constant values and digit/letter patterns.
pub fn validate(doc: &FpfDocument) -> Vec<String> {
    let mut errors = Vec::new();

    if doc.fpf != "1.1" {
        errors.push(r#"fpf: must be "1.1""#.to_string());
    }
    if doc.kind != "buyer" {
        errors.push(r#"kind: must be "buyer""#.to_string());
    }
    if !is_country_code(&doc.legal.country) {
        errors.push("legal.country: ISO 3166-1 alpha-2 code required".to_string());
    }
    if doc.legal.name.trim().is_empty() {
        errors.push("legal.name: non-empty string required".to_string());
    }
    if let Some(ids) = &doc.legal.ids {
        if ids.is_empty() {
            errors.push("legal.ids: non-empty array required when present".to_string());
        }
        let mut seen: Vec<&str> = Vec::new();
        for (i, id) in ids.iter().enumerate() {
            if !is_ascii_digits(&id.scheme, 4) {
                errors.push(format!("legal.ids[{i}].scheme: 4-digit ICD scheme code required"));
            } else if seen.contains(&id.scheme.as_str()) {
                errors.push(format!("legal.ids[{i}].scheme: duplicate scheme {}", id.scheme));
            } else {
                seen.push(&id.scheme);
            }
            if id.value.trim().is_empty() {
                errors.push(format!("legal.ids[{i}].value: non-empty string required"));
            }
        }
    }
    if !is_ascii_digits(&doc.einvoice.eas, 4) {
        errors.push("einvoice.eas: 4-digit EAS scheme code required".to_string());
    }
    if doc.einvoice.address.trim().is_empty() {
        errors.push("einvoice.address: non-empty string required".to_string());
    }

    if let Some(contact) = &doc.contact {
        // The withdrawn 1.0 spelled this contact.ref; naming the rename beats
        // letting the schema call it an unknown property.
        if contact.r#ref.is_some() {
            errors.push("contact.ref: renamed to contact.buyerReference in FPF 1.1".to_string());
        }
    }

    errors
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_doc() -> FpfDocument {
        FpfDocument {
            fpf: "1.1".to_string(),
            kind: "buyer".to_string(),
            legal: Legal {
                country: "FR".to_string(),
                name: "ACME SAS".to_string(),
                form: None,
                ids: None,
                vat: None,
            },
            einvoice: Einvoice {
                eas: "0225".to_string(),
                address: "542051180".to_string(),
                platform: None,
            },
            billing: None,
            contact: None,
        }
    }

    #[test]
    fn round_trip_raw() {
        let doc = sample_doc();
        let payload = encode(&doc, false);
        assert!(payload.starts_with("1."));
        assert_eq!(decode(&payload).unwrap(), doc);
    }

    #[test]
    fn round_trip_deflate() {
        let doc = sample_doc();
        let payload = encode(&doc, true);
        assert!(payload.starts_with("2."));
        assert_eq!(decode(&payload).unwrap(), doc);
    }

    #[test]
    fn optional_fields_are_omitted_when_none() {
        let doc = sample_doc();
        let payload = encode(&doc, false);
        let body = payload.strip_prefix("1.").unwrap();
        let json_bytes = base64::Engine::decode(&base64::engine::general_purpose::URL_SAFE_NO_PAD, body).unwrap();
        let json_str = String::from_utf8(json_bytes).unwrap();
        assert!(!json_str.contains("billing"));
        assert!(!json_str.contains("contact"));
        assert!(!json_str.contains("\"form\""));
    }

    #[test]
    fn unknown_prefix_rejected() {
        assert!(matches!(decode("9.abcdef"), Err(FpfError::UnknownPrefix)));
    }

    #[test]
    fn canonical_key_order_for_raw_prefix() {
        let doc = sample_doc();
        let payload = encode(&doc, false);
        let body = payload.strip_prefix("1.").unwrap();
        let json_bytes = base64::Engine::decode(&base64::engine::general_purpose::URL_SAFE_NO_PAD, body).unwrap();
        let json_str = String::from_utf8(json_bytes).unwrap();
        assert_eq!(
            json_str,
            r#"{"fpf":"1.1","kind":"buyer","legal":{"country":"FR","name":"ACME SAS"},"einvoice":{"eas":"0225","address":"542051180"}}"#
        );
    }
}

#[cfg(test)]
mod validate_tests {
    use super::*;

    fn valid_doc() -> FpfDocument {
        FpfDocument {
            fpf: "1.1".to_string(),
            kind: "buyer".to_string(),
            legal: Legal {
                country: "FR".to_string(),
                name: "ACME SAS".to_string(),
                form: None,
                ids: None,
                vat: None,
            },
            einvoice: Einvoice {
                eas: "0225".to_string(),
                address: "542051180".to_string(),
                platform: None,
            },
            billing: None,
            contact: None,
        }
    }

    #[test]
    fn minimal_valid_doc_has_no_errors() {
        assert_eq!(validate(&valid_doc()), Vec::<String>::new());
    }

    #[test]
    fn wrong_fpf_version() {
        let mut doc = valid_doc();
        doc.fpf = "2.0".to_string();
        assert!(validate(&doc).iter().any(|e| e.starts_with("fpf:")));
    }

    #[test]
    fn wrong_kind() {
        let mut doc = valid_doc();
        doc.kind = "seller".to_string();
        assert!(validate(&doc).iter().any(|e| e.starts_with("kind:")));
    }

    #[test]
    fn bad_country_and_empty_name() {
        let mut doc = valid_doc();
        doc.legal.country = "France".to_string();
        doc.legal.name = "  ".to_string();
        let errors = validate(&doc);
        assert!(errors.iter().any(|e| e.starts_with("legal.country:")));
        assert!(errors.iter().any(|e| e.starts_with("legal.name:")));
    }

    #[test]
    fn well_formed_legal_ids_pass() {
        let mut doc = valid_doc();
        doc.legal.ids = Some(vec![
            LegalId { scheme: "0002".to_string(), value: "542051180".to_string() },
            LegalId { scheme: "0009".to_string(), value: "73282932000074".to_string() },
        ]);
        assert_eq!(validate(&doc), Vec::<String>::new());
    }

    #[test]
    fn legal_id_scheme_must_be_four_digits() {
        let mut doc = valid_doc();
        doc.legal.ids = Some(vec![LegalId { scheme: "2".to_string(), value: "542051180".to_string() }]);
        let errors = validate(&doc);
        assert!(errors.iter().any(|e| e.starts_with("legal.ids[0].scheme:")), "{errors:?}");
    }

    #[test]
    fn duplicate_legal_id_scheme_is_rejected() {
        let mut doc = valid_doc();
        doc.legal.ids = Some(vec![
            LegalId { scheme: "0002".to_string(), value: "542051180".to_string() },
            LegalId { scheme: "0002".to_string(), value: "999999999".to_string() },
        ]);
        let errors = validate(&doc);
        assert!(errors.iter().any(|e| e.contains("duplicate scheme 0002")), "{errors:?}");
    }

    #[test]
    fn the_core_knows_nothing_about_siren_lengths() {
        // "12345" is not a SIREN, but that is PROFILE-FR's business, not the core's.
        let mut doc = valid_doc();
        doc.legal.ids = Some(vec![LegalId { scheme: "0002".to_string(), value: "12345".to_string() }]);
        assert_eq!(validate(&doc), Vec::<String>::new());
    }

    #[test]
    fn bad_eas_and_empty_address() {
        let mut doc = valid_doc();
        doc.einvoice.eas = "22".to_string();
        doc.einvoice.address = "".to_string();
        let errors = validate(&doc);
        assert!(errors.iter().any(|e| e.starts_with("einvoice.eas:")));
        assert!(errors.iter().any(|e| e.starts_with("einvoice.address:")));
    }

    #[test]
    fn version_1_0_is_rejected() {
        let mut doc = valid_doc();
        doc.fpf = "1.0".to_string();
        assert_eq!(validate(&doc), vec![r#"fpf: must be "1.1""#.to_string()]);
    }

    #[test]
    fn legacy_contact_ref_is_named_as_a_rename() {
        let mut doc = valid_doc();
        doc.contact = Some(Contact {
            r#ref: Some("EMP-042".to_string()),
            ..Default::default()
        });
        assert_eq!(
            validate(&doc),
            vec!["contact.ref: renamed to contact.buyerReference in FPF 1.1".to_string()]
        );
    }
}
