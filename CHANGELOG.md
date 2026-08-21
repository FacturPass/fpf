## [1.2.0](https://github.com/FacturPass/fpf/compare/v1.1.0...v1.2.0) (2026-08-21)

### Bug Fixes

* drop ignoreCommits, which broke every changelog run ([#13](https://github.com/FacturPass/fpf/issues/13)) ([f3d51c9](https://github.com/FacturPass/fpf/commit/f3d51c950aa7dbdc80778941dccf18c67f1412ef))
* stop dropping commits made after the latest tag from the changelog ([#9](https://github.com/FacturPass/fpf/issues/9)) ([b7a78c4](https://github.com/FacturPass/fpf/commit/b7a78c4bb031aaede64b25a5ba9d95c07fe18600))
* stop the changelog workflow from looping on its own commits ([#12](https://github.com/FacturPass/fpf/issues/12)) ([46c02ee](https://github.com/FacturPass/fpf/commit/46c02ee7cb2cc45aee1b61e486f64902f151c13b))

### Documentation

* regenerate CHANGELOG ([#10](https://github.com/FacturPass/fpf/issues/10)) ([a88552a](https://github.com/FacturPass/fpf/commit/a88552a64b7a325baba2e300c34bdfe2e18aa21f))

### Continuous Integration

* open a pull request for the changelog instead of pushing to main ([#8](https://github.com/FacturPass/fpf/issues/8)) ([75b6a25](https://github.com/FacturPass/fpf/commit/75b6a25c2c62c8976e55b49b1026ce891eef1db9))
* regenerate the changelog automatically and tag format versions ([#7](https://github.com/FacturPass/fpf/issues/7)) ([c6bcbd4](https://github.com/FacturPass/fpf/commit/c6bcbd41e98596115f878456e2fc53d33e607ce3))

## [1.1.0](https://github.com/FacturPass/fpf/compare/v1.0.0...v1.1.0) (2026-08-21)

### Features

* add FPF 1.1 renaming contact.ref to contact.buyerReference (BT-10) ([#5](https://github.com/FacturPass/fpf/issues/5)) ([508cae6](https://github.com/FacturPass/fpf/commit/508cae628e0d2ed31e45ddba5daae94841cec79a))

### Chores

* enforce conventional commits and generate the changelog ([#6](https://github.com/FacturPass/fpf/issues/6)) ([ea2d885](https://github.com/FacturPass/fpf/commit/ea2d8853ccc0d99da7a9e0971dd4aa96da81b63b))

## [1.0.0](https://github.com/FacturPass/fpf/compare/8051269748702eb0e6bcca52e6f88dbc763d59b8...v1.0.0) (2026-08-10)

### Features

* FPF 1.0 JSON Schema with examples validated by ajv ([e7d66a5](https://github.com/FacturPass/fpf/commit/e7d66a5a706654300dab2fdda4519c2d11f716c7))
* FPF reference lib (encode/decode) with tests and CI ([8051269](https://github.com/FacturPass/fpf/commit/8051269748702eb0e6bcca52e6f88dbc763d59b8))
* structural validate() in FPF lib ([ddf9f1b](https://github.com/FacturPass/fpf/commit/ddf9f1bde3cfa919608dfb4ec6bd46433f484bcc))

### Documentation

* correct legal.country EN 16931 mapping (BT-55 is the postal address country) ([1432406](https://github.com/FacturPass/fpf/commit/1432406c93c9465de38168eeb9f41b26a0127d71))
* FPF spec, FR profile, README, AGPL license ([d3290f3](https://github.com/FacturPass/fpf/commit/d3290f339e4a517b33cf78b18bf1233b3e45054c))
* prepare repo for public release ([#4](https://github.com/FacturPass/fpf/issues/4)) ([4b7f7d8](https://github.com/FacturPass/fpf/commit/4b7f7d8fd25899b7586ad336e97027ea9f7a6a6c))
