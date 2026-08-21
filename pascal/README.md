# FPF — Free Pascal reference implementation

`FpfEncode` / `FpfDecode` / `FpfValidate` for the [FPF format](../SPEC.md),
targeting Free Pascal 3.2 or later. No external dependency: everything it uses
ships with the compiler.

```pascal
uses fpf;
```

## Development

Run from the repository root:

```bash
fpc -Fupascal/src -opascal/tests/fpftests pascal/tests/fpftests.lpr
pascal/tests/fpftests --format=plain --all
```

The runner exits non-zero when a test fails. Tests include the shared
[`test-vectors.json`](../test-vectors.json) also used by the JS, Rust and C#
implementations — keep it in sync via
[`js/scripts/generate-test-vectors.mjs`](../js/README.md) if you change
`examples/*.json`.

## Porting to Delphi

`fpf.pas` is portable Object Pascal and needs no change. Everything specific to
Free Pascal lives in two units: `fpfjson.pas` (JSON, via `fpjson`) and
`fpfbytes.pas` (base64url and raw deflate, via `base64` and `zstream`). A Delphi
port rewrites those two against `System.JSON`, `System.NetEncoding` and
`System.ZLib`.
