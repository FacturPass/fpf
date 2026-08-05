# FPF 1.0 — Profil France

Règles supplémentaires pour un FacturPass français (`legal.country: "FR"`),
alignées sur la réforme de la facturation électronique B2B et la norme
AFNOR XP Z12-014.

## Adressage (annuaire)

- `einvoice.eas` : `"0225"` (schéma français, ISO 6523).
- `einvoice.address` : `SIREN`, `SIREN_SIRET` ou `SIREN_SIRET_CODEROUTAGE`
  (séparateur `_`). Par défaut : le SIREN seul — l'annuaire central résout
  la plateforme de réception.
- `einvoice.platform` est purement informatif : seule l'adresse fait foi.

## Cohérences attendues

- `legal.siren` : 9 chiffres, clé de Luhn valide.
- `legal.siret` : 14 chiffres, clé de Luhn valide, commence par `legal.siren`.
- `legal.vat` : `FR` + clé 2 chiffres + SIREN, avec
  `clé = (12 + 3 × (SIREN mod 97)) mod 97`.
- Le premier segment d'`einvoice.address` est `legal.siren` s'il est présent.

Un lecteur peut signaler ces incohérences mais ne doit pas refuser le
document pour autant (la validation structurelle du schéma fait foi) —
sauf pour émettre une facture, où les règles fiscales s'appliquent.

## Usage type (cas AFNOR n°6)

L'acheteur présente son FacturPass en caisse ; le vendeur y lit le SIREN,
la raison sociale et l'adresse électronique nécessaires pour émettre la
facture B2B via sa plateforme.
