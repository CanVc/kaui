# Story 02 - Pull et navigation

## Objectif

Implémenter une première version du pull compatible INI KissAssist.

## Checklist des choses à faire

- [ ] Lire `PullWith`, `PullWait`, `MaxRadius`, `MaxZRange`, `PullRadiusToUse`.
- [ ] Lire `MobsToPull`, `MobsToIgnore`, `MobsToBurn` dans `KissAssist_Info.ini`.
- [ ] Sélectionner une cible pull valide selon distance, Z et listes.
- [ ] Créer un adaptateur mouvement pour MQ2Nav/MQ2MoveUtils/fallback.
- [ ] Gérer timeouts, stuck detection et stop mouvement.

## Résultats attendus

- [ ] Un puller peut choisir et ramener une cible simple.
- [ ] Les listes de zone sont respectées.
- [ ] Un plugin absent produit un fallback ou message clair.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
