# Story 02 - DPS, Burn et file de casting

## Objectif

Exécuter les entrées DPS/Burn depuis l'INI avec seuils HP, conditions et cooldowns.

## Checklist des choses à faire

- [ ] Lire `DPSOn`, `DPSSize`, `DPSSkip`, `DPSInterval`, `DPS1..N`.
- [ ] Parser les entrées DPS/Burn et leurs tags principaux.
- [ ] Évaluer les conditions `|condN` avant action.
- [ ] Créer une file de casting/action avec retry raisonnable.
- [ ] Ajouter BurnAllNamed et déclenchement burn manuel.

## Résultats attendus

- [ ] Les actions DPS partent dans l'ordre attendu.
- [ ] Les conditions fausses n'interrompent pas toute la rotation.
- [ ] Le burn peut être déclenché de façon contrôlée.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
