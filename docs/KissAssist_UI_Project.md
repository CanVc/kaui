# Projet : KissAssist UI

Objectif : créer une interface graphique en Lua/MacroQuest pour générer et modifier des fichiers de configuration KissAssist (`KissAssist_<Personnage>.ini`), puis porter progressivement les fonctionnalités de KissAssist vers un moteur Lua compatible.

## Contexte

- Jeu : EverQuest
- Environnement : RedGuides MacroQuest
- Langage : Lua MQ
- Macro cible : KissAssist
- Inspiration UI : `lua/maui`, qui sert actuellement d'exemple pour MuleAssist

Documentation utile :

- KissAssist : https://www.redguides.com/docs/projects/kissassist/
- Lua MacroQuest : https://docs.macroquest.org/lua/
- MAUI local : `C:\Users\Cabail\AppData\Local\RedGuides\redfetch\Downloads\VanillaMQ_LIVE\lua\maui`
- Macro KissAssist locale : `C:\Users\Cabail\AppData\Local\RedGuides\redfetch\Downloads\VanillaMQ_LIVE\macros\kissassist.mac`

## Idée générale

S'inspirer de MAUI, mais créer un projet séparé pour KissAssist afin d'éviter de modifier directement les fichiers MuleAssist.

Le projet a maintenant deux axes complémentaires :

1. **KAUI** : une UI Lua/MacroQuest pour lire, créer, éditer et sauvegarder les INI KissAssist.
2. **KissAssist Lua** : une réécriture progressive du comportement de `kissassist.mac` en Lua.

Le port Lua ne doit pas être vu comme une conversion ligne à ligne de la macro, mais comme une réimplémentation modulaire et testable, compatible avec les fichiers INI KissAssist existants.

Nom possible du futur dossier :

```text
lua/kaui/
```

ou :

```text
lua/kissui/
```

## Fonctionnalités visées

### Vision élargie

- Garder la compatibilité avec les fichiers `KissAssist_<Personnage>.ini` et, si présent, `KissAssist_<Server>_<Personnage>.ini`.
- Fournir une UI sûre pour éditer ces fichiers.
- Construire un moteur Lua capable de remplacer progressivement `kissassist.mac`.
- Organiser le moteur par modules : core, config, conditions, combat, DPS, heals, buffs, pull, mez, pet, commandes, intégrations.
- Pouvoir activer les fonctionnalités progressivement, sans devoir porter toute la macro d'un seul coup.

### MVP UI

- Charger un fichier `KissAssist_<Nom>.ini`
- Créer un nouveau fichier si absent
- Modifier les sections principales via UI
- Sauvegarder proprement le fichier INI
- Garder un onglet d'édition brute du fichier INI

### Sections importantes

Sections principales à gérer en priorité :

- `[General]`
- `[Spells]` / `[SpellS]` selon les clés historiques utilisées par la macro
- `[Melee]`
- `[DPS]`
- `[Heals]`
- `[Buffs]`
- `[Burn]`
- `[Mez]`
- `[Pet]`
- `[Pull]`
- `[Aggro]`
- `[Cures]`

Sections supplémentaires relevées dans `kissassist.mac` :

- `[GoM]`
- `[AE]`
- `[Merc]`
- `[PullAdvanced]`
- `[AFKTools]`
- `[KConditions]`

KissAssist utilise aussi `KissAssist_Info.ini` avec des sections par zone pour certaines données de pull/mez (`MobsToPull`, `MobsToIgnore`, `MobsToBurn`, `MezImmune`, `PullLocs`, etc.).

### Points importants

KissAssist utilise beaucoup de listes ordonnées :

```ini
DPS1=...
DPS2=...
Buffs1=...
Heals1=...
```

Dans la macro locale v12.002, les conditions sont principalement gérées via `[KConditions]` (`Cond1`, `Cond2`, etc.) et référencées dans les entrées avec un suffixe `|condN`.

Il faudra donc une UI adaptée pour :

- ajouter une entrée
- supprimer une entrée
- réordonner les entrées
- éditer les conditions
- activer/désactiver rapidement certains éléments

## Architecture envisagée

### Notes relevées dans `kissassist.mac`

- Version macro locale lue : `12.002`.
- Nom de macro déclaré : `KissAssist`.
- Fichier INI chargé : `KissAssist_<Server>_<Personnage>.ini` si présent, sinon `KissAssist_<Personnage>.ini`.
- Chargement des paramètres : `Bind_Settings load ...`.
- Fonction centrale de lecture/création des clés : `LoadIni(...)`, qui crée les valeurs manquantes avec des defaults et charge les tableaux ordonnés (`DPS1..N`, `Buffs1..N`, etc.).
- Les sections chargeables par la macro : `general`, `spells`, `buffs`, `melee`, `gom`, `ae`, `dps`, `aggro`, `heals`, `cures`, `pet`, `merc`, `mez`, `burn`, `pull`, `pulladvanced`, `afktools`, `conditions`, `all`.

Reprendre les bons morceaux de MAUI :

- parser/sauvegarde INI `LIP.lua`
- système de schémas
- composants ImGui existants
- éditeur raw INI
- file dialog si utile

Puis créer un schéma KissAssist complet basé sur la documentation officielle.

## Étapes proposées

1. Créer le nouveau dossier projet.
2. Copier une base minimale depuis `maui`.
3. Forcer le mode KissAssist uniquement.
4. Nettoyer les références MuleAssist.
5. Compléter le schéma KA.
6. Faire un premier écran fonctionnel : chargement/sauvegarde INI.
7. Ajouter les éditeurs graphiques section par section.
8. Créer un moteur Lua minimal compatible INI KissAssist.
9. Porter progressivement les modules de `kissassist.mac` vers Lua.
10. Comparer le comportement Lua avec la macro originale avant de remplacer une fonctionnalité.

## Plan de port Lua proposé

1. **Socle Lua** : bootstrap du projet, boucle principale, état runtime, accès `mq.TLO`, logs.
2. **Compatibilité configuration** : parser/sauvegarde INI, schéma KissAssist, conditions `[KConditions]`, listes ordonnées.
3. **UI KAUI** : chargement/sauvegarde, éditeurs de sections, éditeur raw, édition des listes et conditions.
4. **Combat minimal** : assist, sélection de cible, melee basique, DPS simple.
5. **Support groupe** : buffs, heals, cures, rez.
6. **Modules avancés** : burn, pet, merc, mez, pull, camp/chase/navigation.
7. **Intégrations** : commandes, events, DanNet/EQBC, plugins optionnels.
8. **Migration/parité** : tests terrain, logs comparatifs, documentation utilisateur.

Le détail d'implémentation est découpé dans le dossier `implementation/`, avec un dossier par epic et des stories contenant les checklists et résultats attendus.

## Notes

Priorité : commencer simple, fonctionnel, puis améliorer progressivement.

Le but n'est pas de réécrire tout KissAssist d'un seul coup : l'UI de configuration reste le premier jalon, puis le moteur Lua remplacera progressivement les comportements de la macro module par module.
