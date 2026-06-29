# Story 01 - Logs, debug, tests et fixtures

## Objectif

Rendre le comportement observable et tester les parties non dépendantes du jeu.

## Checklist des choses à faire

- [ ] Créer niveaux log : error, warn, info, debug, trace.
- [ ] Ajouter flags debug par domaine : combat, cast, heals, buffs, pull, mez, pet.
- [ ] Afficher un panneau UI de logs récents.
- [ ] Créer fixtures INI par classe/rôle.
- [ ] Tester parser, schéma, listes, conditions et parsing DPS/Buffs/Heals.

## Résultats attendus

- [ ] Un problème terrain peut être compris sans modifier le code.
- [ ] Les régressions config/listes/conditions sont détectées tôt.
- [ ] Les fixtures servent aussi d'exemples utilisateur.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
