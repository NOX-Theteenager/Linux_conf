#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils.sh"

while true; do
    ACTION=$(zenity --list --title="Gestion des Utilisateurs Linux" \
        --column="Action" \
        "Lister les utilisateurs" \
        "Créer un utilisateur" \
        "Supprimer un utilisateur" \
        "Changer mot de passe" \
        "Gérer les droits SUDO" \
        "Retour" \
        --height=400 --width=350 2>/dev/null)

    if [ $? -ne 0 ] || [ "$ACTION" == "Retour" ]; then
        break
    fi

    case "$ACTION" in
        "Lister les utilisateurs")
            LIST=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd)
            zenity --info --text="Utilisateurs (UID >= 1000) :\n\n$LIST" --title="Système"
            ;;
        "Créer un utilisateur")
            USER=$(zenity --entry --title="Créer" --text="Nom du nouvel utilisateur :" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$USER" ]; then
                if validate_username "$USER"; then
                    run_with_progress "Création" "Création de l'utilisateur $USER..." "useradd -m $USER 2>/tmp/err"
                    if [ $? -eq 0 ]; then
                        log_action "Utilisateurs" "Création de l'utilisateur Linux $USER"
                        notify_user "Succès" "Utilisateur $USER créé." "notify"
                    else
                        notify_user "Erreur" "Erreur : $(cat /tmp/err)" "error"
                    fi
                else
                    notify_user "Erreur" "Nom d'utilisateur invalide." "error"
                fi
            fi
            ;;
        "Supprimer un utilisateur")
            USER=$(zenity --entry --title="Supprimer" --text="Nom de l'utilisateur à supprimer :" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$USER" ]; then
                userdel -r "$USER" 2>/tmp/err
                if [ $? -eq 0 ]; then
                    log_action "Suppression de l'utilisateur Linux $USER"
                    zenity --info --text="Utilisateur $USER supprimé."
                else
                    zenity --error --text="Erreur : $(cat /tmp/err)"
                fi
            fi
            ;;
        "Changer mot de passe")
            DATA=$(zenity --forms --title="Mot de passe" \
                --add-entry="Utilisateur" \
                --add-password="Nouveau mot de passe" 2>/dev/null)
            if [ $? -eq 0 ]; then
                u=$(echo "$DATA" | cut -d'|' -f1)
                p=$(echo "$DATA" | cut -d'|' -f2)
                echo "$u:$p" | chpasswd 2>/tmp/err
                if [ $? -eq 0 ]; then
                    log_action "Changement de mot de passe pour $u"
                    zenity --info --text="Mot de passe mis à jour pour $u."
                else
                    zenity --error --text="Erreur : $(cat /tmp/err)"
                fi
            fi
            ;;
        "Gérer les droits SUDO")
            USER=$(zenity --entry --title="Droits SUDO" --text="Nom de l'utilisateur :" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$USER" ]; then
                ACTION_SUDO=$(zenity --list --title="Action SUDO pour $USER" \
                    --column="Action" "Ajouter aux SUDOERS" "Retirer des SUDOERS" 2>/dev/null)
                
                if [ $? -eq 0 ]; then
                    if [ "$ACTION_SUDO" == "Ajouter aux SUDOERS" ]; then
                        usermod -aG sudo "$USER" 2>/tmp/err
                        if [ $? -eq 0 ]; then
                            log_action "Droits SUDO accordés à $USER"
                            zenity --info --text="L'utilisateur $USER a maintenant les droits SUDO."
                        else
                            zenity --error --text="Erreur : $(cat /tmp/err)"
                        fi
                    else
                        gpasswd -d "$USER" sudo 2>/tmp/err
                        if [ $? -eq 0 ]; then
                            log_action "Droits SUDO retirés à $USER"
                            zenity --info --text="Les droits SUDO ont été retirés à $USER."
                        else
                            zenity --error --text="Erreur : $(cat /tmp/err)"
                        fi
                    fi
                fi
            fi
            ;;
    esac
done
