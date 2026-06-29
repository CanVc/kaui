# Story 01 - Camp, chase et positionnement

## Objectif

Reproduire les bases de camp radius, return to camp et chase assist.

## Checklist des choses à faire

- [ ] Lire `CampRadius`, `CampRadiusExceed`, `ReturnToCamp`.
- [ ] Lire `ChaseAssist`, `ChaseDistance`, `ScatterOn`.
- [ ] Enregistrer la position de camp au démarrage ou via commande.
- [ ] Revenir au camp si les conditions sont réunies.
- [ ] Bloquer les mouvements pendant cast/pause/situation critique.

## Résultats attendus

- [ ] Le personnage connaît son camp et peut y revenir.
- [ ] Le chase suit l'assist sans oscillations excessives.
- [ ] Les mouvements sont désactivables et loggés.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
