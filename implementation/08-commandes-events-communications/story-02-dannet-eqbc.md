# Story 02 - DanNet, EQBC et messages groupe

## Objectif

Préparer les intégrations de communication utilisées par KissAssist.

## Checklist des choses à faire

- [ ] Lire `DanNetOn`, `DanNetDelay`, `EQBCOn`.
- [ ] Créer une interface `broadcast(message, scope)` indépendante du backend.
- [ ] Implémenter DanNet si disponible, EQBC en fallback optionnel.
- [ ] Prévoir réception de commandes depuis peers autorisés.
- [ ] Ajouter protections contre spam et boucles de messages.

## Résultats attendus

- [ ] Le moteur peut annoncer des états importants au groupe de bots.
- [ ] DanNet/EQBC absents ne cassent pas le fonctionnement local.
- [ ] La couche communication reste remplaçable.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
