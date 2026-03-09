#!/bin/bash

# Vérification des droits administrateur
if [ "$EUID" -ne 0 ]; then
    zenity --error --text="Ce script doit être exécuté avec les droits root (sudo)." --title="Erreur de privilèges"
    exit 1
fi

# Se placer dans le répertoire du script pour gérer les chemins relatifs
cd "$(dirname "$0")"

# Lancement de l'authentification
USER_LOGGED=$(./login.sh)

if [ $? -eq 0 ] && [ -n "$USER_LOGGED" ]; then
    # Passage du nom de l'utilisateur au menu principal
    export CURRENT_USER="$USER_LOGGED"
    ./choix_menu.sh
else
    exit 1
fi
