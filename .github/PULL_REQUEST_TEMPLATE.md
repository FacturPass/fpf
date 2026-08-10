## What and why

<!-- What does this change, and why. Link any related issue. -->

## Component(s) touched

- [ ] Spec / schema (`SPEC.md`, `fpf-1.0.schema.json`, `PROFILE-FR.md`)
- [ ] `js`
- [ ] `rust`
- [ ] `csharp`
- [ ] `examples/` / `test-vectors.json`

## Checklist

- [ ] If `examples/*.json` or a reference implementation's encode/decode logic
      changed, `test-vectors.json` was regenerated
      (`node js/scripts/generate-test-vectors.mjs`) and committed.
- [ ] Tests added or updated for the change.
- [ ] If this touches `SPEC.md` or `PROFILE-FR.md`, the change was discussed in an
      issue first and existing FPF 1.0 documents remain valid (or the
      compatibility impact is called out explicitly).
- [ ] CI is green.
