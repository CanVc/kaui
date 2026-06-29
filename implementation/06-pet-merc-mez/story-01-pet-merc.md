# Story 01 - Pet et Mercenaire

## Objectif

Gérer invocation, buffs, attaque du pet et assist mercenaire de base.

## Checklist des choses à faire

- [ ] Lire `PetOn`, `PetSpell`, `PetBuffsOn`, `PetCombatOn`, `PetAssistAt`.
- [ ] Maintenir un pet présent si classe compatible et config activée.
- [ ] Lancer `PetBuffs1..N` avec conditions si présentes.
- [ ] Lire `MercOn` et `MercAssistAt`.
- [ ] Ignorer proprement les options non disponibles pour la classe.

## Résultats attendus

- [ ] Le pet est invoqué/buffé selon configuration simple.
- [ ] Le pet ou merc attaque au bon seuil si activé.
- [ ] L'absence de pet/merc ne produit pas d'erreur bloquante.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
