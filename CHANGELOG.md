## [1.2.0](https://github.com/FacturPass/fpf/compare/v1.1.0...v1.2.0) (2026-08-22)

### ⚠ BREAKING CHANGES

* add a Free Pascal reference implementation and drop the contact.ref diagnostic (#26)
* carry legal identifiers as scheme-qualified ids (#23)
* withdraw FPF 1.0 (#21)

### Features

* add a Free Pascal reference implementation and drop the contact.ref diagnostic ([#26](https://github.com/FacturPass/fpf/issues/26)) ([e7c6f33](https://github.com/FacturPass/fpf/commit/e7c6f33c859364b50c5c30ddfe29d2beb33700b5))
* add a Java reference implementation ([#28](https://github.com/FacturPass/fpf/issues/28)) ([f51088e](https://github.com/FacturPass/fpf/commit/f51088ed538c1e9fb12c3c8c5ae178369685ca52))
* carry legal identifiers as scheme-qualified ids ([#23](https://github.com/FacturPass/fpf/issues/23)) ([210aaac](https://github.com/FacturPass/fpf/commit/210aaaccef3be176bd712d5d754bc7e3a615462b))
* withdraw FPF 1.0 ([#21](https://github.com/FacturPass/fpf/issues/21)) ([d048641](https://github.com/FacturPass/fpf/commit/d048641d68c0874433f75a470861f72427598f40))

### Bug Fixes

* correct package metadata left behind by the format and the repository ([#29](https://github.com/FacturPass/fpf/issues/29)) ([acc58f9](https://github.com/FacturPass/fpf/commit/acc58f9d30290025f7fe8b406f9afa8e43d13090))
* drop ignoreCommits, which broke every changelog run ([#13](https://github.com/FacturPass/fpf/issues/13)) ([f3d51c9](https://github.com/FacturPass/fpf/commit/f3d51c950aa7dbdc80778941dccf18c67f1412ef))
* keep the changelog from narrating its own upkeep ([#15](https://github.com/FacturPass/fpf/issues/15)) ([d1b61d7](https://github.com/FacturPass/fpf/commit/d1b61d751461710d8f421dda31ace1c437f5ae6c)), closes [#20](https://github.com/FacturPass/fpf/issues/20)
* stop dropping commits made after the latest tag from the changelog ([#9](https://github.com/FacturPass/fpf/issues/9)) ([b7a78c4](https://github.com/FacturPass/fpf/commit/b7a78c4bb031aaede64b25a5ba9d95c07fe18600))
* stop the changelog workflow from looping on its own commits ([#12](https://github.com/FacturPass/fpf/issues/12)) ([46c02ee](https://github.com/FacturPass/fpf/commit/46c02ee7cb2cc45aee1b61e486f64902f151c13b))

### Documentation

* bring the READMEs up to FPF 1.1 ([#19](https://github.com/FacturPass/fpf/issues/19)) ([e968a3f](https://github.com/FacturPass/fpf/commit/e968a3f6bbcf4ac80859db353799d78ebc77e527))
* define what claiming FPF conformance requires ([#24](https://github.com/FacturPass/fpf/issues/24)) ([286f8dc](https://github.com/FacturPass/fpf/commit/286f8dc939e4b6a17f41a053cec0ab9a74944181))
* point the documentation at facturpass.com ([#17](https://github.com/FacturPass/fpf/issues/17)) ([e0b83f3](https://github.com/FacturPass/fpf/commit/e0b83f386881903509e611ffd54c47db543fb6e3))

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
