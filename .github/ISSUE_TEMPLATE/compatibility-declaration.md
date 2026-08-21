---
name: Compatibility declaration
about: Declare that your software reads, writes, or accepts FPF — to be listed publicly
title: 'Compatible FPF: '
labels: compatibility
assignees: ''
---

<!--
This is a self-declaration, on your honour. Nobody verifies it, and nothing is
checked on your behalf: what you write here is what readers will believe.

"Conformance" in SPEC.md defines what each role requires. Please read it before
filling this in — declaring a role you do not fully implement is worse for you
than declaring none, because integrators will build on it.
-->

**Product**
Name of the software, as you want it listed.

**Vendor**
Who publishes it.

**Category**
<!-- Tick one. -->
- [ ] Point of sale / cash register
- [ ] ERP
- [ ] Invoicing / accounting
- [ ] Accredited platform (plateforme agréée)
- [ ] Library / SDK
- [ ] Other:

**Roles**
<!-- Tick every role you implement. Each is defined in SPEC.md, "Conformance". -->
- [ ] **Reader** — decodes an FPF payload and validates it
- [ ] **Writer** — produces FPF payloads
- [ ] **API receiver** — accepts an FPF payload as input to your own API

**Versions covered**
Which FPF versions your implementation handles (currently only `1.1` exists).

**Test vectors**
- [ ] My implementation passes `test-vectors.json` for the roles declared above.

<!-- If it does not, say which vectors fail and why. An honest partial
     declaration is more useful than a silent one. -->

**Link**
Public URL — product page, documentation, or repository.

**Anything else**
Optional. Known limitations, country profiles supported, contact for integrators.
