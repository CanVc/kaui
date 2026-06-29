# Story 01 - Moteurs Buffs et Heals

## Objectif

Maintenir les buffs et lancer les soins configurés selon les seuils.

## Checklist des choses à faire

- [ ] Lire `BuffsOn`, `BuffsSize`, `RebuffOn`, `CheckBuffsTimer`.
- [ ] Lire `HealsOn`, `HealInterval`, `HealsSize`, `Heals1..N`.
- [ ] Détecter buffs manquants sur soi/groupe/pet selon format.
- [ ] Surveiller HP groupe, tank et XTarget selon config.
- [ ] Donner priorité aux heals sur DPS si nécessaire.

## Résultats attendus

- [ ] Les buffs simples sont maintenus sans spam.
- [ ] Les soins partent aux seuils configurés.
- [ ] Les erreurs de sort/cible sont visibles dans les logs.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
