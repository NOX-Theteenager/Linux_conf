#!/bin/bash

LOG_FILE="logs/actions.log"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [Services] $1 par $CURRENT_USER" >> "$LOG_FILE"
}

while true; do
    ACTION=$(zenity --list --title="Gestion des Services" \
        --column="Action" \
        "Lister les services actifs" \
        "Démarrer un service" \
        "Arrêter un service" \
        "Redémarrer un service" \
        "Vérifier l'état" \
        "Retour" \
        --height=400 --width=400 2>/dev/null)

    if [ $? -ne 0 ] || [ "$ACTION" == "Retour" ]; then
        break
    fi

    case "$ACTION" in
        "Lister les services actifs")
            systemctl list-units --type=service --state=running | head -n 30 | zenity --text-info --title="Services Actifs" --width=600 --height=500
            ;;
        "Démarrer un service"|"Arrêter un service"|"Redémarrer un service"|"Vérifier l'état")
            SVC=$(zenity --entry --text="Nom du service :" --title="Service" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$SVC" ]; then
                case "$ACTION" in
                    "Démarrer un service") cmd="start" ;;
                    "Arrêter un service") cmd="stop" ;;
                    "Redémarrer un service") cmd="restart" ;;
                    "Vérifier l'état") cmd="status" ;;
                esac
                
                if [ "$cmd" == "status" ]; then
                    systemctl status "$SVC" | zenity --text-info --title="État de $SVC" --width=600
                else
                    systemctl "$cmd" "$SVC" 2>/tmp/err
                    if [ $? -eq 0 ]; then
                        log_action "Action $cmd sur le service $SVC"
                        zenity --info --text="Action $cmd effectuée sur $SVC."
                    else
                        zenity --error --text="Erreur : $(cat /tmp/err)"
                    fi
                fi
            fi
            ;;
    esac
done
