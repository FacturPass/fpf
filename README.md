# FacturPass

**Votre identité de facturation électronique, dans votre poche.**

Un QR code / lien permanent qui porte les informations dont un vendeur a
besoin pour vous adresser une facture électronique (réforme française
2026-2027, cas « achat en magasin ») : SIREN, raison sociale, adresse
électronique BT-49, TVA…

- 🌐 Site : https://facturpass.fr — 100 % statique, aucune donnée stockée.
- 📄 Format ouvert **FPF 1.0** : [SPEC.md](SPEC.md),
  [schéma JSON](fpf-1.0.schema.json),
  [profil France](PROFILE-FR.md).
- 🔧 Implémentation de référence :
  [lib/fpf.js](lib/fpf.js) (`encode` / `decode` / `validate`).
- 📱 Les identités générées restent dans le fragment d'URL : jamais envoyées au serveur.

## Développement

Aucun build. Tests (Node ≥ 22) :

    npm install && npm test

## Licence

AGPL-3.0-or-later — voir [LICENSE](LICENSE).
