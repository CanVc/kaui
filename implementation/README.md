# Plan d'implémentation KAUI / KissAssist Lua

Ce dossier découpe le projet en epics par grande thématique.
Chaque epic a son dossier, un `epic.md`, puis des stories avec checklist et résultats attendus.

## Ordre recommandé

1. Socle Lua Runtime
2. Compatibilité INI et schéma KissAssist
3. KAUI Interface d'édition
4. Combat, Assist, DPS et Burn
5. Buffs, Heals, Cures et Rez
6. Pet, Merc et Mez
7. Pull, Camp et Navigation
8. Commandes, Events et Communications
9. Qualité, Migration et Documentation

## Principes

- Compatibilité INI KissAssist avant réécriture complète.
- Port Lua progressif, module par module.
- Pas de conversion ligne à ligne de `kissassist.mac`.
- Les modules doivent être désactivables individuellement.
- Toute fonctionnalité critique doit avoir logs, fallback ou rollback.
