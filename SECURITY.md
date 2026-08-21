# Security Policy

## Reporting a vulnerability

Please **do not** open a public GitHub issue for a security vulnerability.

Instead, use
[GitHub Security Advisories](https://github.com/FacturPass/fpf/security/advisories/new)
for this repository to report it privately. Include:

- The affected component (`js`, `rust`, `csharp`, or the spec/schema itself).
- Steps to reproduce, or a minimal example FPF document that triggers the issue.
- The potential impact as you understand it (e.g. malformed input causing a crash,
  a decode/validate bypass, a denial-of-service via crafted input).

We'll acknowledge reports and work with you on a fix and coordinated disclosure
timeline before any public details are published.

## Scope

FPF documents are untrusted input by design — they're decoded from a QR code or a
URL fragment supplied by whoever presents them. The reference implementations
(`js/`, `rust/`, `csharp/`) are expected to handle malformed, oversized, or
adversarial input without crashing or misbehaving; reports about that are
particularly welcome. Issues in the format specification itself (e.g. an ambiguity
that could lead to two conforming implementations disagreeing) are also in scope.

## Supported versions

FPF 1.1 is the only published version of the format; all three reference
implementations track it. The withdrawn 1.0 is refused rather than read, and
there are no older versions receiving security fixes.
