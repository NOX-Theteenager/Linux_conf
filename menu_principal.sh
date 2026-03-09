#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/actions.log"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [Menu] $1" >> "$LOG_FILE"
}

while true; do
    CHOICE=$(zenity --list --title="Menu Principal - NETSEC-CAM" \
        --column="Option" --column="Description" \
        "1" "Gestion des Officiers IT" \
        "2" "Gestion des Utilisateurs Linux" \
        "3" "Gestion des Groupes" \
        "4" "Gestion des Processus" \
        "5" "Gestion des Services" \
        "6" "Gestion des Cartes Réseau" \
        "7" "Pare-feu SECURENET" \
        "8" "Retour au sélecteur" \
        --height=450 --width=400 2>/dev/null)

    if [ $? -ne 0 ] || [ "$CHOICE" == "8" ]; then
        log_action "Retour au sélecteur de menu."
        break
    fi

    case $CHOICE in
        1) "$SCRIPT_DIR/officiers/gestion_officiers.sh" ;;
        2) "$SCRIPT_DIR/utilisateurs/gestion_utilisateurs.sh" ;;
        3) "$SCRIPT_DIR/groupes/gestion_groupes.sh" ;;
        4) "$SCRIPT_DIR/systeme/gestion_processus.sh" ;;
        5) "$SCRIPT_DIR/systeme/gestion_services.sh" ;;
        6) "$SCRIPT_DIR/systeme/gestion_reseau.sh" ;;
        7) "$SCRIPT_DIR/systeme/firewall/gestion_firewall.sh" ;;
    esac
done
