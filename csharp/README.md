# FPF — C# reference implementation

`Encode` / `Decode` / `Validate` for the [FPF format](../SPEC.md), targeting
.NET 8.

## Development

```bash
dotnet test csharp/Fpf.sln
```

Tests include the shared [`test-vectors.json`](../test-vectors.json) also used by
the JS and Rust implementations — keep it in sync via
[`js/scripts/generate-test-vectors.mjs`](../js/README.md) if you change
`examples/*.json`.

Being a typed implementation, it departs from the untyped JS reference on a few
checks that a type makes impossible to represent — see
[Where the typed implementations legitimately differ](../CONTRIBUTING.md#where-the-typed-implementations-legitimately-differ).
