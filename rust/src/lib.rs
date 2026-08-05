//! FPF 1.0 reference implementation — encode/decode of the transport payload.
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
    pub siren: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub siret: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub vat: Option<String>,
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

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_doc() -> FpfDocument {
        FpfDocument {
            fpf: "1.0".to_string(),
            kind: "buyer".to_string(),
            legal: Legal {
                country: "FR".to_string(),
                name: "ACME SAS".to_string(),
                form: None,
                siren: None,
                siret: None,
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
            r#"{"fpf":"1.0","kind":"buyer","legal":{"country":"FR","name":"ACME SAS"},"einvoice":{"eas":"0225","address":"542051180"}}"#
        );
    }
}
