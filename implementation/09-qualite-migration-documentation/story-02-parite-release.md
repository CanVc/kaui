# Story 02 - Parité macro, migration et release progressive

## Objectif

Organiser le remplacement progressif de `kissassist.mac` sans rupture utilisateur.

## Checklist des choses à faire

- [ ] Définir une matrice de parité macro vs Lua par module.
- [ ] Marquer chaque module : non commencé, expérimental, utilisable, stable.
- [ ] Prévoir un mode coexistence : UI + macro, puis UI + moteur Lua partiel.
- [ ] Documenter commandes, limitations et plugins requis.
- [ ] Préparer changelog et procédure de rollback.

## Résultats attendus

- [ ] L'utilisateur sait quelles fonctionnalités Lua sont fiables.
- [ ] On peut revenir à `kissassist.mac` si un module Lua pose problème.
- [ ] Les releases progressives sont compréhensibles et traçables.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
