#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/actions.log"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [Sélecteur] $1 par $CURRENT_USER" >> "$LOG_FILE"
}

while true; do
    CHOICE=$(zenity --list --title="Sélecteur de Module - NETSEC-CAM" \
        --column="Option" --column="Description" \
        "1" "Gestion du Parc Informatique (Zenity)" \
        "2" "Optimisation & Debloat Système (Terminal)" \
        "3" "Quitter" \
        --height=300 --width=450 2>/dev/null)

    if [ $? -ne 0 ] || [ "$CHOICE" == "3" ]; then
        log_action "Utilisateur $CURRENT_USER a quitté l'application."
        exit 0
    fi

    case $CHOICE in
        1) 
            log_action "Accès au menu Gestion du Parc."
            "$SCRIPT_DIR/menu_principal.sh"
            ;;
        2) 
            log_action "Accès au menu Optimisation Système."
            # L'optimisation système est en mode texte, on l'exécute directement
            # On change de répertoire pour que les chemins internes du script fonctionnent
            (cd "$SCRIPT_DIR/systeme/debloat" && ./gestion_debloat.sh)
            ;;
    esac
done
