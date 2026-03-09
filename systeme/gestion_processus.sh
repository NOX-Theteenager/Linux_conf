#!/bin/bash

LOG_FILE="logs/actions.log"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [Processus] $1 par $CURRENT_USER" >> "$LOG_FILE"
}

while true; do
    ACTION=$(zenity --list --title="Gestion des Processus" \
        --column="Action" \
        "Afficher tous les processus" \
        "Rechercher un processus" \
        "Terminer un processus (PID)" \
        "Surveiller l'activité (Top)" \
        "Retour" \
        --height=350 --width=350 2>/dev/null)

    if [ $? -ne 0 ] || [ "$ACTION" == "Retour" ]; then
        break
    fi

    case "$ACTION" in
        "Afficher tous les processus")
            ps -eo pid,user,comm --sort=-%cpu | head -n 20 | zenity --text-info --title="Processus (Top 20 CPU)" --width=400 --height=500
            ;;
        "Rechercher un processus")
            NAME=$(zenity --entry --text="Nom du processus :" --title="Recherche" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$NAME" ]; then
                RES=$(ps -ef | grep "$NAME" | grep -v grep)
                if [ -n "$RES" ]; then
                    echo "$RES" | zenity --text-info --title="Résultats pour $NAME" --width=600
                else
                    zenity --info --text="Aucun processus trouvé."
                fi
            fi
            ;;
        "Terminer un processus (PID)")
            PID=$(zenity --entry --text="Entrez le PID à terminer :" --title="Kill" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$PID" ]; then
                kill -9 "$PID" 2>/tmp/err
                if [ $? -eq 0 ]; then
                    log_action "Processus $PID terminé"
                    zenity --info --text="Processus $PID arrêté."
                else
                    zenity --error --text="Erreur : $(cat /tmp/err)"
                fi
            fi
            ;;
        "Surveiller l'activité (Top)")
            # Utilisation de zenity pour afficher un instantané de l'activité
            uptime | zenity --text-info --title="Activité Système" --width=400 --height=200
            free -h | zenity --text-info --append --title="Mémoire"
            ;;
    esac
done
