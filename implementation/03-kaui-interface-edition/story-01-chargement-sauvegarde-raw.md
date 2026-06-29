# Story 01 - Écran chargement/sauvegarde et raw INI

## Objectif

Créer le premier écran fonctionnel de sélection, chargement, sauvegarde et édition brute.

## Checklist des choses à faire

- [x] Créer la fenêtre principale KAUI.
- [x] Afficher personnage, serveur, fichier détecté et statut.
- [x] Ajouter Charger, Sauvegarder, Recharger, Backup.
- [x] Afficher les erreurs de lecture/écriture dans l'UI.
- [x] Ajouter un onglet raw INI éditable.

## Résultats attendus

- [x] Un utilisateur peut charger et sauvegarder un INI depuis l'UI.
- [x] Les erreurs sont visibles sans consulter uniquement la console MQ.
- [x] Le raw INI permet de corriger les cas non couverts par l'UI.

## Notes

- Garder la compatibilité avec les INI KissAssist quand la story touche à la configuration.
- Ajouter des logs utiles pour faciliter les tests terrain.
