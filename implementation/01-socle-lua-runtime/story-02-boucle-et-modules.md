# Story 02 - Boucle principale, état runtime et modules

## Objectif

Mettre en place une boucle principale contrôlable et un état runtime partagé.

## Checklist des choses à faire

- [x] Créer une boucle principale avec arrêt propre.
- [x] Définir un state : running, paused, mode, role, target, timers.
- [x] Ajouter une cadence de pulse configurable.
- [x] Prévoir hooks `onInit`, `onPulse`, `onShutdown` pour les modules.
- [x] Centraliser les helpers MQ/TLO de base (`Me`, `Target`, `Spawn`, `mq.cmd`).

## Résultats attendus

- [x] Le script tourne en continu et peut être arrêté proprement.
- [x] Les modules reçoivent un pulse régulier.
- [x] Le runtime expose un état central utilisable par l'UI et les modules.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
