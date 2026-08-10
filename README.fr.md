# FPF — FacturPass Format

**Un format ouvert et portable pour transporter l'identité de facturation
électronique d'un acheteur dans un QR code ou un lien.**

FPF (FacturPass Format) est un petit document JSON — SIREN, raison sociale, adresse
d'e-facturation (schéma EAS + adresse BT-49), numéro de TVA, adresse de facturation
— conçu pour tenir dans un QR code ou le fragment d'une URL, afin qu'une entreprise
puisse transmettre son identité de facturation à une contrepartie sans qu'aucune des
deux parties n'ait besoin de compte, de serveur, ni d'intégration partagée.

Il a été créé pour la réforme française de la facturation électronique B2B
(2026-2027), où un vendeur a besoin de l'identité de facturation de l'acheteur pour
les achats en présentiel / point de vente, sans qu'aucune norme ne définisse comment
transmettre physiquement cette identité — le « dernier mètre » de la réforme. Le
format lui-même est générique (aligné EN 16931, tout schéma EAS) ; un
[profil France](PROFILE-FR.md) documente les règles supplémentaires propres à cette
réforme.

[**FacturPass**](https://facturpass.fr) est le site de référence qui génère des QR
codes FPF ; ce dépôt est le format lui-même, maintenu indépendamment afin que
n'importe quel logiciel de caisse ou de comptabilité puisse implémenter FPF
directement — lire le format, générer le format — sans dépendre de FacturPass.

**🇬🇧 English version: [README.md](README.md)**

## Contenu

- [`SPEC.md`](SPEC.md) — la spécification FPF 1.0.
- [`fpf-1.0.schema.json`](fpf-1.0.schema.json) — schéma JSON pour la validation
  structurelle.
- [`PROFILE-FR.md`](PROFILE-FR.md) — règles supplémentaires pour
  `legal.country: "FR"`.
- [`examples/`](examples/) — documents d'exemple (minimal, complet, invalide).
- [`test-vectors.json`](test-vectors.json) — vecteurs de test encode/decode partagés,
  utilisés pour garder chaque implémentation synchronisée.
- Implémentations de référence (`encode` / `decode` / `validate`), une par langage :
  - [`js/`](js/README.md) — JavaScript (Node ≥ 22, aucune dépendance à l'exécution).
  - [`rust/`](rust/README.md) — Rust.
  - [`csharp/`](csharp/README.md) — C#.

## Transport

```
https://exemple.fr/#2.<base64url(deflate-raw(JSON))>
```

Préfixe `1.` = base64url du JSON brut (non compressé) ; `2.` = base64url du JSON
compressé en deflate-raw (forme nominale, compacte). Tout autre préfixe est une
erreur de décodage. Voir [`SPEC.md`](SPEC.md) pour le schéma complet du document et
la liste des champs.

## Exemple

```json
{
  "fpf": "1.0",
  "kind": "buyer",
  "legal": { "country": "FR", "name": "ACME SAS", "siren": "542051180" },
  "einvoice": { "eas": "0225", "address": "542051180" }
}
```

## État

FPF 1.0 est la version actuelle et stable. Les changements sont suivis dans
[`CHANGELOG.md`](CHANGELOG.md).

## Contribuer

Voir [`CONTRIBUTING.md`](CONTRIBUTING.md) pour proposer une évolution de la
spécification ou d'une implémentation de référence, et [`SECURITY.md`](SECURITY.md)
pour signaler une vulnérabilité.

## Licence

AGPL-3.0-or-later pour la spécification, le schéma et les implémentations de
référence de ce dépôt — voir [`LICENSE`](LICENSE). Cette licence couvre ce code ;
elle ne couvre pas le format FPF lui-même, que quiconque peut librement
réimplémenter.
