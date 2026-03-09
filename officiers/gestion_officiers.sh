#!/bin/bash

CONF_FILE="data/officiers.conf"
LOG_FILE="logs/actions.log"

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [Officiers] $1 par $CURRENT_USER" >> "$LOG_FILE"
}

while true; do
    ACTION=$(zenity --list --title="Gestion des Officiers IT" \
        --column="Action" \
        "Afficher la liste" \
        "Ajouter un officier" \
        "Supprimer un officier" \
        "Retour" \
        --height=300 --width=300 2>/dev/null)

    if [ $? -ne 0 ] || [ "$ACTION" == "Retour" ]; then
        break
    fi

    case "$ACTION" in
        "Afficher la liste")
            LIST=$(awk -F: '{print $1}' "$CONF_FILE")
            zenity --info --text="Liste des officiers :\n\n$LIST" --title="Officiers"
            ;;
        "Ajouter un officier")
            NEW_USER=$(zenity --forms --title="Ajouter un Officier" \
                --add-entry="Nom d'utilisateur" \
                --add-password="Mot de passe" 2>/dev/null)
            if [ $? -eq 0 ]; then
                u=$(echo "$NEW_USER" | cut -d'|' -f1)
                p=$(echo "$NEW_USER" | cut -d'|' -f2)
                if grep -q "^$u:" "$CONF_FILE"; then
                    zenity --error --text="L'officier $u existe déjà."
                else
                    echo "$u:$p" >> "$CONF_FILE"
                    log_action "Ajout de l'officier $u"
                    zenity --info --text="Officier $u ajouté avec succès."
                fi
            fi
            ;;
        "Supprimer un officier")
            OFFICIER=$(zenity --entry --title="Supprimer un Officier" --text="Nom de l'officier à supprimer :" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$OFFICIER" ]; then
                if [ "$OFFICIER" == "admin" ]; then
                    zenity --error --text="Impossible de supprimer le compte admin principal."
                elif grep -q "^$OFFICIER:" "$CONF_FILE"; then
                    sed -i "/^$OFFICIER:/d" "$CONF_FILE"
                    log_action "Suppression de l'officier $OFFICIER"
                    zenity --info --text="Officier $OFFICIER supprimé."
                else
                    zenity --error --text="Officier introuvable."
                fi
            fi
            ;;
    esac
done
