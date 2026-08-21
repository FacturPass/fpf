# FPF — FacturPass Format 1.0 / 1.1

Format JSON ouvert (licence AGPL-3.0-or-later) portant l'identité de facturation
électronique d'un acheteur, conçu pour tenir dans un QR code ou une URL.

## Document

Le document canonique est un objet JSON validé par
[`fpf-1.0.schema.json`](fpf-1.0.schema.json). Exemples :
[minimal](examples/minimal.json), [complet](examples/complete.json).

| Champ | Oblig. | EN 16931 | Description |
|---|---|---|---|
| `fpf` | oui | — | Version du format, `"1.0"` ou `"1.1"`. |
| `kind` | oui | — | `"buyer"`. (`"seller"` réservé, non défini à ce jour.) |
| `legal.country` | oui | — | Pays d'immatriculation, ISO 3166-1 alpha-2. Détermine le profil applicable (`FR` → profil France). EN 16931 n'a pas de terme dédié : BT-55 désigne le pays de l'adresse postale (voir `billing.country`). |
| `legal.name` | oui | BT-44 | Raison sociale. |
| `legal.form` | non | — | Forme juridique, texte libre. |
| `legal.siren` | non | BT-47 | 9 chiffres. |
| `legal.siret` | non | — | 14 chiffres. EN 16931 n'a pas de terme dédié : le SIRET sert de composant d'adressage dans `einvoice.address`. |
| `legal.vat` | non | BT-48 | N° TVA intracommunautaire. |
| `einvoice.eas` | oui | BT-49-1 | Code schéma EAS (4 chiffres). |
| `einvoice.address` | oui | BT-49 | Adresse électronique dans ce schéma. |
| `einvoice.platform` | non | — | Nom de la plateforme de réception. **Informatif et volatile** : il change dès que l'entreprise change de plateforme, alors qu'un lien FacturPass est permanent. L'annuaire central fait foi ; préférez l'omettre. |
| `billing.*` | non | BG-8 | Adresse postale de facturation. |
| `contact.email`, `contact.phone` | non | — | Contact de facturation. |
| `contact.buyerReference` | non | BT-10 | Référence propre à l'acheteur (bon de commande, centre de coût), que le vendeur reporte sur la facture. **Nommée `contact.ref` en 1.0** — voir Versions. |

Les clés optionnelles absentes sont **omises** (jamais `""` ni `null`).

## Versions

| Version | Schéma | Différence |
|---|---|---|
| `1.0` | [`fpf-1.0.schema.json`](fpf-1.0.schema.json) | `contact.ref` |
| `1.1` | [`fpf-1.1.schema.json`](fpf-1.1.schema.json) | `contact.ref` renommé `contact.buyerReference`, mappé BT-10 |

Un lecteur **doit** accepter toutes les versions publiées : un QR code imprimé
il y a des années doit rester décodable. Il se fie au champ `fpf` pour savoir
quelle clé attendre — chaque version n'accepte que la sienne, jamais les deux,
de sorte qu'un document ne peut pas être ambigu. Un producteur écrit dans la
version la plus récente.

## Transport

Le document voyage dans un fragment d'URL ou un QR code :

    https://facturpass.com/#<prefixe><base64url(donnees)>

| Préfixe | Encodage |
|---|---|
| `1.` | JSON minifié UTF-8 → base64url (sans padding). |
| `2.` | JSON minifié UTF-8 → deflate-raw (RFC 1951) → base64url. **Nominal.** |

Pour le transport `1.`, toute implémentation **doit** sérialiser les objets
dans cet ordre exact, pour permettre une comparaison octet-à-octet entre
langages :

    fpf, kind,
    legal { country, name, form, siren, siret, vat },
    einvoice { eas, address, platform },
    billing { street, zip, city, country },
    contact { email, phone, ref }              // 1.0
    contact { email, phone, buyerReference }   // 1.1

Le transport `2.` (compressé) n'a pas cette contrainte : deux
implémentations de deflate peuvent produire des octets différents pour un
même document tout en se décompressant à l'identique. Son contrat
d'interopérabilité repose uniquement sur le **decode**, jamais sur une
correspondance octet-à-octet à l'encodage.

Tout autre préfixe doit être rejeté. Le fragment n'est jamais envoyé au
serveur : les données restent entre l'émetteur et le lecteur.

Implémentations de référence (AGPL-3.0) :
[`js/lib/fpf.js`](js/lib/fpf.js) (navigateur + Node) — `encode`, `decode`, `validate`.

**Autorité : le JSON Schema est normatif.** `validate()` est un pré-contrôle
structurel rapide (pensé pour la saisie interactive) qui n'implémente qu'un
sous-ensemble des règles : il ignore `legal.vat`, `billing`, `contact` et
tolère les propriétés inconnues. Un document accepté par `validate()` peut
donc être refusé par le schéma ; en cas de désaccord, le schéma fait foi.
Un intégrateur qui veut la validation complète utilise le schéma.

## Lecture par un logiciel de caisse

1. Extraire le fragment après `#`.
2. Décoder selon le préfixe (`2.` : base64url → inflate-raw → JSON).
3. Valider (schéma ou `validate()`).
4. Utiliser `einvoice.eas` + `einvoice.address` pour adresser la facture,
   `legal.*` pour les mentions obligatoires.
