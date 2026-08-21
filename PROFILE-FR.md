# FPF 1.0 / 1.1 — Profil France

Règles supplémentaires pour un FacturPass français (`legal.country: "FR"`),
alignées sur la réforme de la facturation électronique B2B et la norme
AFNOR XP Z12-014.

## Adressage (annuaire)

- `einvoice.eas` : `"0225"` (schéma français, ISO 6523).
- `einvoice.address` : l'**identifiant d'adressage** de l'annuaire central,
  obtenu en concaténant les composants avec `_`. Quatre formes possibles :

  | Forme | Maille visée |
  |---|---|
  | `SIREN` | toute l'entité légale (défaut) |
  | `SIREN_SIRET` | un établissement |
  | `SIREN_SIRET_CODEROUTAGE` | un service au sein d'un établissement |
  | `SIREN_SUFFIXE` | une maille interne non rattachée à un établissement |

  Contraintes : 125 caractères au total au maximum ; caractères autorisés dans
  le code routage — chiffres, lettres latines non accentuées, `-` et `_` ; dans
  le suffixe, les mêmes plus `.`. Un code routage impose un SIRET ; un suffixe
  est au contraire exclusif d'un SIRET.

  Le séparateur `_` étant lui-même autorisé à l'intérieur d'un code routage ou
  d'un suffixe, **un découpage naïf est faux**. Algorithme correct : les
  9 premiers caractères sont le SIREN ; si le segment suivant compte
  14 chiffres et commence par ce SIREN, c'est un SIRET et *tout le reste* est
  le code routage ; sinon *tout le reste* est un suffixe.

  Par défaut, le SIREN seul — l'annuaire central résout la plateforme de
  réception.
- `einvoice.platform` est purement informatif : seule l'adresse fait foi. C'est
  de plus une donnée volatile, qui change dès que l'entreprise change de
  plateforme, alors qu'un lien FacturPass est permanent : préférez l'omettre.
  La plateforme de réception ne se transmet pas, elle se résout — la
  plateforme d'émission du vendeur l'obtient de l'annuaire, dont c'est la
  fonction.

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

C'est l'acheteur, et lui seul, qui sait à quelle maille cet achat doit être
facturé : l'annuaire répond « où router », jamais « quelle maille pour cette
transaction ». D'où l'intérêt de transporter l'identifiant d'adressage
complet plutôt que le seul SIREN lorsque l'acheteur a organisé sa réception
par établissement ou par service.
