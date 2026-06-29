# Story 02 - Cures, rez et GroupWatch

## Objectif

Ajouter les fonctions de sécurité : cures, rez accept, auto rez et surveillance groupe.

## Checklist des choses à faire

- [ ] Lire `CuresOn`, `CuresSize`, `Cures1..N`.
- [ ] Lire `AutoRezOn`, `RezMeLast`, `RezAcceptOn`.
- [ ] Lire `GroupWatchOn` et `GroupWatchCheck`.
- [ ] Détecter les situations où cure/rez doit préempter DPS.
- [ ] Ajouter confirmations/logs pour les actions sensibles.

## Résultats attendus

- [ ] Les cures configurées peuvent être déclenchées.
- [ ] Les règles de rez sont respectées.
- [ ] Les situations groupe critiques sont visibles et actionnables.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
