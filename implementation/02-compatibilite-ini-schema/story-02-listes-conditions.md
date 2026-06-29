# Story 02 - Listes ordonnées et conditions `[KConditions]`

## Objectif

Gérer les tableaux KissAssist (`DPS1..N`, `Buffs1..N`, etc.) et les conditions `|condN`.

## Checklist des choses à faire

- [x] Lire les tailles configurables (`DPSSize`, `BuffsSize`, `HealsSize`, etc.).
- [x] Implémenter ajout, suppression, déplacement et compactage des index.
- [x] Parser les suffixes `|condN` sans casser la valeur originale.
- [x] Lire/écrire `ConOn`, `CondSize`, `Cond1..N`.
- [x] Signaler les références de conditions manquantes.

## Résultats attendus

- [x] Les listes restent dans l'ordre attendu par KissAssist.
- [x] Les conditions sont éditables séparément.
- [x] Aucune entrée n'est perdue lors d'un load/save.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
