# Story 01 - Parser, sauvegarde et schéma des sections

## Objectif

Fournir une base de configuration fiable pour l'UI et le moteur Lua.

## Checklist des choses à faire

- [x] Étudier `LIP.lua` utilisé par MAUI.
- [x] Charger un INI KissAssist existant sans perdre les clés inconnues.
- [x] Créer un fichier absent `KissAssist_<Personnage>.ini`.
- [x] Respecter la priorité `KissAssist_<Server>_<Personnage>.ini` si présent.
- [x] Définir les sections et defaults issus de `LoadIni` / `Bind_Settings`.

## Résultats attendus

- [x] Un INI existant peut faire un aller-retour load/save sans perte importante.
- [x] Les clés principales ont type, default et description courte.
- [x] Les sauvegardes sont lisibles et récupérables.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
