# Story 01 - Bootstrap du projet Lua

## Objectif

Initialiser une structure de projet propre pour KAUI et le moteur KissAssist Lua.

## Checklist des choses à faire

- [x] Créer le dossier Lua cible (`lua/kaui/` ou nom validé).
- [x] Définir `core/`, `config/`, `modules/`, `ui/`, `utils/`.
- [x] Créer un `main.lua` lançable depuis MacroQuest Lua.
- [x] Ajouter constantes/version et message de démarrage.
- [x] Documenter la commande de lancement prévue.

## Résultats attendus

- [x] Le projet Lua démarre sans erreur dans MacroQuest.
- [x] La structure permet d'ajouter des modules sans toucher constamment à `main.lua`.
- [x] Un message de démarrage affiche nom et version.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
