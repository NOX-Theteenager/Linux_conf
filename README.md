# Application de Gestion de Parc Informatique - NETSEC-CAM SARL

## Description
Cette application est un outil d'administration système développé en Bash avec une interface graphique Zenity. Elle permet de gérer les officiers IT, les utilisateurs système, les groupes, les processus, les services et les cartes réseau.

## Prérequis
- Système Linux (Ubuntu/Debian recommandé)
- Zenity installé (`sudo apt install zenity`)
- Droits administrateur (sudo)

## Installation et Lancement
1. Extraire l'archive `gestion_parc.zip`.
2. Donner les permissions d'exécution (déjà fait dans l'archive, mais au cas où) :
   ```bash
   chmod -R +x gestion_parc/
   ```
3. Lancer l'application :
   ```bash
   sudo ./gestion_parc/main.sh
   ```

## Identifiants par défaut
- **Utilisateur** : `admin`
- **Mot de passe** : `admin123`

## Architecture
- `main.sh` : Point d'entrée, vérifie les droits root.
- `login.sh` : Module d'authentification sécurisé.
- `menu_principal.sh` : Navigation entre les modules.
- `officiers/` : Gestion des accès à l'application.
- `utilisateurs/` & `groupes/` : Administration système.
- `systeme/` : Monitoring et gestion des services, processus, cartes réseau, stores/sources alternatifs et pare-feu SECURENET.
- `data/` : Stockage des configurations.
- `logs/` : Journalisation de toutes les actions.

## Sécurité
- Accès restreint par mot de passe.
- Journalisation horodatée de chaque action sensible.
- Vérification des privilèges root à l'exécution.
