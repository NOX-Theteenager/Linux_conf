#!/bin/bash

LOG_FILE="logs/actions.log"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [Groupes] $1 par $CURRENT_USER" >> "$LOG_FILE"
}

while true; do
    ACTION=$(zenity --list --title="Gestion des Groupes" \
        --column="Action" \
        "Lister les groupes" \
        "Créer un groupe" \
        "Supprimer un groupe" \
        "Ajouter un utilisateur au groupe" \
        "Retour" \
        --height=350 --width=350 2>/dev/null)

    if [ $? -ne 0 ] || [ "$ACTION" == "Retour" ]; then
        break
    fi

    case "$ACTION" in
        "Lister les groupes")
            LIST=$(awk -F: '$3 >= 1000 {print $1}' /etc/group)
            zenity --info --text="Groupes (GID >= 1000) :\n\n$LIST" --title="Groupes"
            ;;
        "Créer un groupe")
            GRP=$(zenity --entry --title="Créer" --text="Nom du nouveau groupe :" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$GRP" ]; then
                groupadd "$GRP" 2>/tmp/err
                if [ $? -eq 0 ]; then
                    log_action "Création du groupe $GRP"
                    zenity --info --text="Groupe $GRP créé."
                else
                    zenity --error --text="Erreur : $(cat /tmp/err)"
                fi
            fi
            ;;
        "Supprimer un groupe")
            GRP=$(zenity --entry --title="Supprimer" --text="Nom du groupe à supprimer :" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$GRP" ]; then
                groupdel "$GRP" 2>/tmp/err
                if [ $? -eq 0 ]; then
                    log_action "Suppression du groupe $GRP"
                    zenity --info --text="Groupe $GRP supprimé."
                else
                    zenity --error --text="Erreur : $(cat /tmp/err)"
                fi
            fi
            ;;
        "Ajouter un utilisateur au groupe")
            DATA=$(zenity --forms --title="Ajout au groupe" \
                --add-entry="Utilisateur" \
                --add-entry="Groupe" 2>/dev/null)
            if [ $? -eq 0 ]; then
                u=$(echo "$DATA" | cut -d'|' -f1)
                g=$(echo "$DATA" | cut -d'|' -f2)
                usermod -aG "$g" "$u" 2>/tmp/err
                if [ $? -eq 0 ]; then
                    log_action "Ajout de $u au groupe $g"
                    zenity --info --text="Utilisateur $u ajouté au groupe $g."
                else
                    zenity --error --text="Erreur : $(cat /tmp/err)"
                fi
            fi
            ;;
    esac
done
