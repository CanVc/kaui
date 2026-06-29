# Story 02 - Éditeurs de sections, listes et conditions

## Objectif

Créer les formulaires graphiques pour les sections simples et les listes ordonnées.

## Checklist des choses à faire

- [x] Créer une structure visuelle inspirée de RGMercs : header compact, gros statut/action principal, barre d'état cible/config, tabs et panneaux repliables.
- [x] Créer des onglets/panneaux par section.
- [x] Gérer bool/int/string avec composants ImGui adaptés.
- [x] Commencer par General, Spells, Melee, DPS, Buffs, Heals.
- [x] Créer un composant liste : Ajouter, Supprimer, Monter, Descendre.
- [x] Ajouter une UI pour associer ou créer une condition `CondN`.

## Résultats attendus

- [x] Les sections principales sont éditables sans toucher au raw INI.
- [x] Les listes DPS/Buffs/Heals restent cohérentes.
- [x] L'utilisateur voit clairement les modifications non sauvegardées.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
- L'inspiration RGMercs doit rester adaptée à KAUI : configuration KissAssist d'abord, moteur runtime ensuite. Les textes visibles de l'app doivent rester en anglais.
