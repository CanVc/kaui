# Story 01 - Assist, acquisition de cible et melee

## Objectif

Déterminer la cible de combat et gérer l'engagement melee de base.

## Checklist des choses à faire

- [ ] Lire `Role`, `AssistAt`, `MeleeOn`, `MeleeDistance`, `StickHow`.
- [ ] Déterminer le main assist depuis commande, target ou INI.
- [ ] Attendre le seuil HP avant engagement.
- [ ] Activer/désactiver `/attack` proprement.
- [ ] Gérer cible morte, invalide, mezzée ou hors range.

## Résultats attendus

- [ ] Le moteur sait quand entrer et sortir du combat.
- [ ] Un personnage melee peut assister et attaquer une cible simple.
- [ ] Le stop combat est propre et sans spam.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
