# Changelog

All notable changes to the FPF format and its reference implementations are
documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

The format version (`"fpf": "1.0"`) and this changelog are versioned separately:
the format version only changes when the on-the-wire document schema changes;
tooling and implementation improvements that don't affect the format itself are
listed here without a format version bump.

## [Unreleased]

### Added
- C# reference implementation (`csharp/`), matching the JS and Rust
  implementations against the shared `test-vectors.json`.
- `README.md` (English) as the primary entry point, with `README.fr.md` for the
  French version.
- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, issue/PR templates.

## 1.0 — 2026-08-05

Initial public format and reference implementations.

### Added
- FPF 1.0 specification (`SPEC.md`) and JSON Schema (`fpf-1.0.schema.json`).
- France profile (`PROFILE-FR.md`): EAS 0225 addressing, SIREN/SIRET/VAT
  consistency rules.
- JavaScript reference implementation (`js/`): `encode`, `decode`, `validate`.
- Rust reference implementation (`rust/`): `encode`, `decode`, `validate`.
- Multi-language repository structure, with a shared `test-vectors.json`
  generated from `examples/*.json` and checked against every language
  implementation in CI.
- AGPL-3.0-or-later license for this repository's code (the FPF format itself
  remains freely reimplementable).
