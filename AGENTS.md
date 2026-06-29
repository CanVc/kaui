# Instructions agent KAUI

- Tout texte visible dans l'application KAUI (UI, commandes, logs, erreurs, statuts, tooltips, descriptions de schéma destinées à l'UI) doit être en anglais pour faciliter le partage public.

- Quand un fichier sous `lua/kaui/` est créé ou modifié, déployer immédiatement la version à jour dans :

```text
C:\Users\Cabail\AppData\Local\RedGuides\redfetch\Downloads\VanillaMQ_LIVE\lua\kaui
```

- Le déploiement doit conserver la même arborescence que `lua/kaui/`.
- Après modification Lua, copier les fichiers avant de demander un test MacroQuest.
- Commande de lancement en jeu :

```mq
/lua run kaui/main.lua
```

- Commande d'arrêt propre runtime :

```mq
/kaui stop
```
