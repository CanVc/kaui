# Story 01 - Commandes slash et events jeu

## Objectif

Créer les commandes utilisateur et transposer les événements importants vers `mq.event`.

## Checklist des choses à faire

- [ ] Lister les binds critiques : pause, burn, kisscheck, kissedit, makecamphere, reload.
- [ ] Créer un routeur de commandes Lua et une aide `/kaui help`.
- [ ] Identifier events prioritaires : cast fail, resisted, zoned, death, tells.
- [ ] Créer des handlers par domaine sans bloquer la boucle.
- [ ] Ajouter feedback console/UI pour commandes et events critiques.

## Résultats attendus

- [ ] L'utilisateur peut piloter les fonctions de base sans UI.
- [ ] Les événements critiques mettent à jour le runtime state.
- [ ] Les commandes inconnues affichent une aide claire.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
