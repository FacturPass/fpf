# FPF — FacturPass Format 1.1

Format JSON ouvert (licence AGPL-3.0-or-later) portant l'identité de facturation
électronique d'un acheteur, conçu pour tenir dans un QR code ou une URL.

## Document

Le document canonique est un objet JSON validé par
[`fpf-1.1.schema.json`](fpf-1.1.schema.json). Exemples :
[minimal](examples/minimal.json), [complet](examples/complete.json).

| Champ | Oblig. | EN 16931 | Description |
|---|---|---|---|
| `fpf` | oui | — | Version du format, `"1.1"`. |
| `kind` | oui | — | `"buyer"`. (`"seller"` réservé, non défini à ce jour.) |
| `legal.country` | oui | — | Pays d'immatriculation, ISO 3166-1 alpha-2. Détermine le profil applicable (`FR` → profil France). EN 16931 n'a pas de terme dédié : BT-55 désigne le pays de l'adresse postale (voir `billing.country`). |
| `legal.name` | oui | BT-44 | Raison sociale. |
| `legal.form` | non | — | Forme juridique, texte libre. |
| `legal.ids` | non | BT-47 | Identifiants d'immatriculation, chacun qualifié par son schéma. Tableau non vide ; un schéma ne peut pas figurer deux fois. |
| `legal.ids[].scheme` | oui | BT-47-1 | Code ICD à 4 chiffres, **même registre qu'`einvoice.eas`**. La signification d'un code relève du profil pays. |
| `legal.ids[].value` | oui | — | L'identifiant lui-même, **toujours une chaîne** — jamais un nombre, qui perdrait un zéro initial. |
| `legal.vat` | non | BT-48 | N° TVA intracommunautaire. |
| `einvoice.eas` | oui | BT-49-1 | Code schéma EAS (4 chiffres). |
| `einvoice.address` | oui | BT-49 | Adresse électronique dans ce schéma. |
| `einvoice.platform` | non | — | Nom de la plateforme de réception. **Informatif et volatile** : il change dès que l'entreprise change de plateforme, alors qu'un lien FacturPass est permanent. L'annuaire central fait foi ; préférez l'omettre. |
| `billing.*` | non | BG-8 | Adresse postale de facturation. |
| `contact.email`, `contact.phone` | non | — | Contact de facturation. |
| `contact.buyerReference` | non | BT-10 | Référence propre à l'acheteur (bon de commande, centre de coût), que le vendeur reporte sur la facture. |

Les clés optionnelles absentes sont **omises** (jamais `""` ni `null`).

## Versionnement

Le champ `fpf` porte la version du document. Un lecteur **doit** accepter toutes
les versions publiées — un QR code imprimé il y a des années doit rester
décodable — et un producteur écrit toujours dans la plus récente.

Aujourd'hui il n'en existe qu'une, `1.1`, décrite par
[`fpf-1.1.schema.json`](fpf-1.1.schema.json). La `1.0` a été publiée brièvement
puis **retirée avant qu'aucun document ne soit remis à personne**. Un document
portant `"fpf": "1.0"` doit être **refusé**, jamais lu — une lecture approximative
serait pire qu'un refus net.

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
    legal { country, name, form, ids [ { scheme, value } ], vat },
    einvoice { eas, address, platform },
    billing { street, zip, city, country },
    contact { email, phone, buyerReference }

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

## Conformité

« Compatible FPF » n'est pas une mention libre : elle désigne un ou plusieurs
des trois rôles ci-dessous, chacun avec ses obligations. Un logiciel peut n'en
tenir qu'un — la plupart des logiciels de caisse ne seront jamais que lecteurs.

### Lecteur

Décode un pass et en extrait l'identité de l'acheteur. Il **doit** :

- accepter les préfixes `1.` et `2.`, et **rejeter** tout autre préfixe au lieu
  de tenter de deviner ;
- valider le document, par le schéma ou par `validate()` — le schéma faisant foi ;
- accepter toutes les versions publiées, et refuser une version retirée plutôt
  que de la lire approximativement ;
- traiter tout identifiant comme une **chaîne**, jamais comme un nombre ;
- ne jamais découper `einvoice.address` sur `_` par un `split` naïf : ce
  caractère est à la fois séparateur et caractère autorisé (voir
  [`PROFILE-FR.md`](PROFILE-FR.md) pour l'algorithme correct).

### Émetteur

Produit des pass. Il **doit** :

- écrire dans la version la plus récente ;
- omettre toute clé optionnelle vide — jamais `""` ni `null` ;
- qualifier chaque identifiant de `legal.ids` par son code de schéma ;
- respecter l'ordre canonique des clés pour le transport `1.` (voir Transport).

### Récepteur d'API

Accepte un payload FPF **tel quel** en entrée de sa propre API, et en extrait
l'identité sans exiger de son appelant qu'il remappe les champs au préalable.
Ce rôle concerne surtout les plateformes agréées et les API de dépôt de factures.

### Vecteurs de test

Quel que soit le rôle, une implémentation conforme passe
[`test-vectors.json`](test-vectors.json) :

| Bloc | Attendu |
|---|---|
| `vectors[]` | `payload_raw` et `payload_deflate` décodent vers le document `example` ; un émetteur reproduit `payload_raw` **octet pour octet**. |
| `decode_failures[]` | `payload` est **rejeté** au décodage. |
| `validate_failures[]` | le document `example` produit au moins une erreur de validation. |

Le transport `2.` n'est vérifié qu'au décodage : deux implémentations de deflate
peuvent produire des octets différents pour un même document.

### Se déclarer

La déclaration se fait sur l'honneur, par une
[issue de déclaration de compatibilité](https://github.com/FacturPass/fpf/issues/new?template=compatibility-declaration.md).
Rien n'est vérifié — ce que vous déclarez est ce que les intégrateurs croiront.
Les déclarations sont listées sur
[facturpass.com/implementations.html](https://facturpass.com/implementations.html).
