# Story 02 - Mez et immunités de zone

## Objectif

Contrôler les adds avec mez single/AE et listes d'immunité.

## Checklist des choses à faire

- [ ] Lire `MezOn`, `MezRadius`, `MezMinLevel`, `MezMaxLevel`, `MezStopHPs`.
- [ ] Lire `MezSpell`, `MezAESpell`, `MezDebuffOnResist`.
- [ ] Lire `MezImmune` depuis `KissAssist_Info.ini` par zone.
- [ ] Sélectionner les adds mezzables sans casser la cible principale.
- [ ] Éviter les mobs immunes ou sous seuil HP.

## Résultats attendus

- [ ] Un add valide peut être mezzé selon configuration.
- [ ] Les immunités de zone sont respectées.
- [ ] Le module peut être désactivé sans impacter DPS/heals.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
