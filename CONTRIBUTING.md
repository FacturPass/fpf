# Contributing to FPF

Thanks for considering a contribution. FPF is a small, deliberately boring format —
changes should keep it that way.

## Repository structure

- [`SPEC.md`](SPEC.md), [`fpf-1.1.schema.json`](fpf-1.1.schema.json),
  [`PROFILE-FR.md`](PROFILE-FR.md) — the format itself.
- [`examples/`](examples/) and [`test-vectors.json`](test-vectors.json) — shared
  fixtures used by every language implementation.
- [`js/`](js/README.md), [`rust/`](rust/README.md), [`csharp/`](csharp/README.md) —
  one reference implementation per language, each with its own tests and CI
  workflow (only the workflow for the directory you touched runs on your PR).

## Changing the format (spec or schema)

This is the highest-bar kind of change, since it affects every existing FPF reader
and writer. Open an issue first to discuss the change before writing code — spec
changes need to keep every reference implementation and `PROFILE-FR.md` consistent,
and backward compatibility with documents already in the wild is a hard constraint.
A new incompatible field or requirement needs a version bump, not a silent change
to `"1.1"`.

## Changing a reference implementation

1. If you're changing behavior around `examples/*.json`, update the examples first.
2. Regenerate the shared test vectors:
   ```bash
   node js/scripts/generate-test-vectors.mjs
   ```
   Commit the resulting `test-vectors.json` change alongside your code — CI checks
   it hasn't drifted.
3. Add or update tests in the language you're changing (see that language's
   `README.md` for how to run them) and make sure the shared test vectors pass in
   *every* implementation, not just the one you edited.
4. Keep the three implementations behaviorally identical: same validation errors,
   same encode/decode output for the same input. If you find a divergence, treat it
   as a bug in whichever implementation disagrees with `SPEC.md`.

## Pull requests

- Small, focused PRs are easier to review than large ones — one language or one
  concern per PR where possible.
- Describe *why*, not just *what*, especially for anything touching `SPEC.md` or
  `PROFILE-FR.md`.
- CI must be green (only the workflows relevant to the files you changed will run).

## License

By contributing, you agree your contribution is licensed under
AGPL-3.0-or-later, the same license as the rest of this repository (see
[`LICENSE`](LICENSE)). This covers the code in this repository; it does not extend
any license over the FPF format itself, which remains freely reimplementable by
anyone.

## Reporting a security issue

Please don't open a public issue for a security vulnerability — see
[`SECURITY.md`](SECURITY.md).

## Commits and changelog

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) in English.
`commitlint` enforces this locally through the husky `commit-msg` hook, and again in CI over
every commit a pull request adds — a local hook only protects contributors who installed it.
The **pull request title** is checked too, because merges here are squashed: the title becomes
the commit message that lands on `main`.

`CHANGELOG.md` is generated from the history by `conventional-changelog`; run `npm run changelog`
from the repo root when cutting a release. It regenerates the whole file, so never hand-edit it —
anything written there is lost on the next run.

Two commits already on `main` came from squashed pull request titles written before this
convention existed, so they cannot be classified and do not appear in the generated changelog.
They are the reason the title check exists; nothing similar can be lost from now on.

When you tag a release, bump `version` in the root `package.json` to the *next* version at the
same time. `conventional-changelog` treats the package version as the release being prepared, so
leaving it equal to the latest tag makes every commit after that tag vanish from the changelog —
silently, since regeneration then produces an identical file and the workflow reports nothing to do.

**The format version and the changelog are versioned separately.** `"fpf": "1.1"` changes only
when the on-the-wire document schema changes; tooling and implementation improvements that leave
the format untouched are released without a format version bump.
