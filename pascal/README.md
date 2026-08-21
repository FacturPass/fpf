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
fpc -Fupascal/src -Fupascal/tests -opascal/tests/fpftests pascal/tests/fpftests.lpr
pascal/tests/fpftests --format=plain --all
```

The runner exits non-zero when a test fails. `fpc` compiles incrementally and
will happily reuse a stale `.ppu`: if a result looks impossible after an edit,
delete the build artifacts and compile again.

```bash
rm -f pascal/src/*.ppu pascal/src/*.o pascal/tests/*.ppu pascal/tests/*.o
```
 Tests include the shared
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

Being a typed implementation, it departs from the untyped JS reference on a few
checks that a type makes impossible to represent — see
[Where the typed implementations legitimately differ](../CONTRIBUTING.md#where-the-typed-implementations-legitimately-differ).
