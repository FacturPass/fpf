# FPF — FacturPass Format

**An open, portable format for carrying a buyer's e-invoicing identity in a QR code or a link.**

FPF (FacturPass Format) is a small JSON document — SIREN/company registration number,
legal name, e-invoicing address (EAS scheme + BT-49 address), VAT number, billing
address — designed to fit in a QR code or a URL fragment, so a business can hand its
e-invoicing identity to a counterparty without either side needing an account, a
server, or a shared integration.

It was created for the French B2B e-invoicing reform (2026-2027), where a seller
needs the buyer's billing identity for in-person / point-of-sale purchases and no
standard defines how that identity should be physically transmitted — the "last
meter" of the reform. The format itself is generic (EN 16931-aligned, any EAS
scheme); a [France-specific profile](PROFILE-FR.md) documents the additional rules
for that reform.

[**FacturPass**](https://facturpass.com) is the reference site that generates FPF QR
codes; this repository is the format itself, kept independent of it so any
point-of-sale or accounting software can implement FPF directly — read the format,
generate the format — without depending on FacturPass at all.

**🇫🇷 Version française : [README.fr.md](README.fr.md)**

## Contents

- [`SPEC.md`](SPEC.md) — the FPF 1.0 specification.
- [`fpf-1.0.schema.json`](fpf-1.0.schema.json) — JSON Schema for structural validation.
- [`PROFILE-FR.md`](PROFILE-FR.md) — additional rules for `legal.country: "FR"`.
- [`examples/`](examples/) — example documents (minimal, complete, invalid).
- [`test-vectors.json`](test-vectors.json) — shared encode/decode vectors used to keep
  every language implementation in sync.
- Reference implementations (`encode` / `decode` / `validate`), one per language:
  - [`js/`](js/README.md) — JavaScript (Node ≥ 22, zero dependencies at runtime).
  - [`rust/`](rust/README.md) — Rust.
  - [`csharp/`](csharp/README.md) — C#.

## Transport

```
https://example.com/#2.<base64url(deflate-raw(JSON))>
```

Prefix `1.` = base64url of the raw JSON (uncompressed); `2.` = base64url of
deflate-raw-compressed JSON (the nominal, compact form). Any other prefix is a
decode error. See [`SPEC.md`](SPEC.md) for the full document schema and field list.

## Example

```json
{
  "fpf": "1.0",
  "kind": "buyer",
  "legal": { "country": "FR", "name": "ACME SAS", "siren": "542051180" },
  "einvoice": { "eas": "0225", "address": "542051180" }
}
```

## Status

FPF 1.0 is the current, stable version. Changes are tracked in
[`CHANGELOG.md`](CHANGELOG.md).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for how to propose changes to the spec or
to a reference implementation, and [`SECURITY.md`](SECURITY.md) to report a
vulnerability.

## License

AGPL-3.0-or-later for the spec, schema, and reference implementations in this
repository — see [`LICENSE`](LICENSE). The license covers this code; it does not
cover the FPF format itself, which anyone is free to reimplement independently.
