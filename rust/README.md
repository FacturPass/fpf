# FPF — Rust reference implementation

`encode` / `decode` / `validate` for the [FPF format](../SPEC.md).

```toml
[dependencies]
fpf = { path = "../fpf/rust" } # or a published crate, once released
```

## Development

```bash
cargo test --manifest-path rust/Cargo.toml
```

Tests include the shared [`test-vectors.json`](../test-vectors.json) also used by
the JS and C# implementations — keep it in sync via
[`js/scripts/generate-test-vectors.mjs`](../js/README.md) if you change
`examples/*.json`.

Being a typed implementation, it departs from the untyped JS reference on a few
checks that a type makes impossible to represent — see
[Where the typed implementations legitimately differ](../CONTRIBUTING.md#where-the-typed-implementations-legitimately-differ).
