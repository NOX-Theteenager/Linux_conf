#!/bin/bash

# Fichier de configuration des officiers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/data/officiers.conf"
LOG_FILE="$SCRIPT_DIR/logs/actions.log"
MAX_ATTEMPTS=3

# Fonction de journalisation
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

authenticate() {
    attempts=0
    while [ $attempts -lt $MAX_ATTEMPTS ]; do
        # Formulaire de connexion Zenity
        auth_data=$(zenity --forms --title="Authentification - NETSEC-CAM" \
            --text="Veuillez vous identifier" \
            --add-entry="Nom d'utilisateur" \
            --add-password="Mot de passe" 2>/dev/null)

        if [ $? -ne 0 ]; then
            log_action "Tentative de connexion annulée."
            exit 1
        fi

        username=$(echo "$auth_data" | cut -d'|' -f1)
        password=$(echo "$auth_data" | cut -d'|' -f2)

        # Vérification des identifiants
        if grep -q "^$username:$password$" "$CONF_FILE"; then
            log_action "Connexion réussie : $username"
            zenity --info --text="Bienvenue, $username !" --title="Succès"
            echo "$username" # Retourne le nom de l'utilisateur connecté
            return 0
        else
            attempts=$((attempts + 1))
            remaining=$((MAX_ATTEMPTS - attempts))
            log_action "Échec de connexion pour : $username (Tentative $attempts/$MAX_ATTEMPTS)"
            zenity --error --text="Identifiants incorrects. Tentatives restantes : $remaining" --title="Erreur"
        fi
    done

    zenity --error --text="Nombre maximal de tentatives atteint. Accès refusé." --title="Accès Refusé"
    log_action "Accès bloqué après $MAX_ATTEMPTS échecs."
    exit 1
}

# Appel de la fonction
authenticate
