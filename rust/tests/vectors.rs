use std::fs;
use std::path::PathBuf;

use fpf::{decode, encode, validate, FpfDocument};
use serde::Deserialize;

#[derive(Deserialize)]
struct VectorFile {
    vectors: Vec<Vector>,
    decode_failures: Vec<DecodeFailure>,
    validate_failures: Vec<ValidateFailure>,
}

#[derive(Deserialize)]
struct Vector {
    name: String,
    example: String,
    payload_raw: String,
    payload_deflate: String,
}

#[derive(Deserialize)]
struct DecodeFailure {
    name: String,
    payload: String,
}

#[derive(Deserialize)]
struct ValidateFailure {
    name: String,
    example: String,
}

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("..")
}

fn load_vector_file() -> VectorFile {
    let path = repo_root().join("test-vectors.json");
    let content = fs::read_to_string(&path).unwrap_or_else(|e| panic!("cannot read {path:?}: {e}"));
    serde_json::from_str(&content).unwrap()
}

fn load_example(name: &str) -> FpfDocument {
    let path = repo_root().join("examples").join(name);
    let content = fs::read_to_string(&path).unwrap_or_else(|e| panic!("cannot read {path:?}: {e}"));
    serde_json::from_str(&content).unwrap()
}

#[test]
fn vectors_decode_to_expected_document() {
    let file = load_vector_file();
    for vector in &file.vectors {
        let expected = load_example(&vector.example);
        assert_eq!(decode(&vector.payload_raw).unwrap(), expected, "raw payload for {}", vector.name);
        assert_eq!(decode(&vector.payload_deflate).unwrap(), expected, "deflate payload for {}", vector.name);
    }
}

#[test]
fn encode_raw_matches_vector_exactly() {
    let file = load_vector_file();
    for vector in &file.vectors {
        let document = load_example(&vector.example);
        assert_eq!(encode(&document, false), vector.payload_raw, "raw encode for {}", vector.name);
    }
}

#[test]
fn encode_deflate_round_trips() {
    let file = load_vector_file();
    for vector in &file.vectors {
        let document = load_example(&vector.example);
        let payload = encode(&document, true);
        assert_eq!(decode(&payload).unwrap(), document, "deflate round-trip for {}", vector.name);
    }
}

#[test]
fn decode_failures_are_rejected() {
    let file = load_vector_file();
    for failure in &file.decode_failures {
        assert!(decode(&failure.payload).is_err(), "expected failure: {}", failure.name);
    }
}

#[test]
fn validate_failures_produce_errors() {
    let file = load_vector_file();
    for failure in &file.validate_failures {
        let path = repo_root().join("examples").join(&failure.example);
        let content = fs::read_to_string(&path).unwrap_or_else(|e| panic!("cannot read {path:?}: {e}"));
        // A document that fails to even deserialize into a typed `FpfDocument`
        // (e.g. a missing required field) is a fortiori invalid: Rust's type
        // system enforces the same "shape" checks the untyped JS reference
        // performs explicitly inside `validate()`. Either outcome satisfies
        // this vector — this mirrors the same typed-language nuance already
        // applied to `validate()` itself (see its doc comment).
        match serde_json::from_str::<FpfDocument>(&content) {
            Ok(document) => assert!(!validate(&document).is_empty(), "expected validate errors: {}", failure.name),
            Err(_) => {}
        }
    }
}
