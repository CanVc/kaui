# Story 01 - Assist, acquisition de cible et melee

## Objectif

Déterminer la cible de combat et gérer l'engagement melee de base.

## Checklist des choses à faire

- [x] Lire `Role`, `AssistAt`, `MeleeOn`, `MeleeDistance`, `StickHow`.
- [x] Déterminer le main assist depuis commande, target ou INI.
- [x] Attendre le seuil HP avant engagement.
- [x] Activer/désactiver `/attack` proprement.
- [x] Gérer cible morte, invalide, mezzée ou hors range.

## Résultats attendus

- [x] Le moteur sait quand entrer et sortir du combat.
- [x] Un personnage melee peut assister et attaquer une cible simple.
- [x] Le stop combat est propre et sans spam.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
