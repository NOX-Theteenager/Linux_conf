#!/bin/bash

# ==============================================================================
# Projet : Pare-feu Linux avec Interface Graphique (Zenity)
# Entreprise : SECURENET SARL
# Auteur : Manus
# Description : Script d'administration d'un pare-feu iptables avec GUI Zenity.
# ==============================================================================

# --- Configuration ---
WAN_IF="eth0"
LAN_IF="eth1"
LAN_NET="192.168.10.0/24"
# Adapté pour le projet Gestion de Parc
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../../logs/actions.log"
RULES_SAVE="$SCRIPT_DIR/../../data/iptables_rules.save"
ADMIN_PASSWORD="admin" # Mot de passe par défaut

# Source des utilitaires si présents
[ -f "$SCRIPT_DIR/../../utils.sh" ] && source "$SCRIPT_DIR/../../utils.sh"

# --- Vérification des privilèges ---
if [[ $EUID -ne 0 ]]; then
   # Note: Dans cet environnement, on peut simuler ou utiliser sudo si nécessaire.
   # Mais pour le script final, c'est important.
   echo "Ce script doit être exécuté en tant que root."
fi

# Créer le fichier de log s'il n'existe pas
touch "$LOG_FILE" 2>/dev/null

# --- Fonctions de Journalisation ---
# Utilise la fonction log_action de utils.sh si disponible, sinon définit une locale
if ! declare -f log_action >/dev/null; then
    log_action() {
        local message=$1
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [Firewall] $message par $CURRENT_USER" >> "$LOG_FILE"
    }
fi

# --- Fonctions de Validation ---
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# --- Fonctions Core Firewall ---

init_firewall() {
    # Réinitialisation avant init
    iptables -F
    iptables -X
    
    # Politique par défaut
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Autoriser loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Autoriser les connexions établies
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Journalisation des paquets bloqués (Bonus/Exigence)
    iptables -N LOGGING 2>/dev/null
    iptables -A INPUT -j LOGGING
    iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
    iptables -A LOGGING -j DROP

    log_action "Initialisation du pare-feu effectuée."
    zenity --info --text="Pare-feu initialisé avec les politiques par défaut (INPUT DROP, FORWARD DROP)." --title="Initialisation"
}

reset_firewall() {
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    log_action "Réinitialisation du pare-feu."
    zenity --info --text="Pare-feu réinitialisé (Toutes les règles supprimées, politiques à ACCEPT)." --title="Reset"
}

manage_ports() {
    local action=$(zenity --list --title="Gestion des Ports" --column="Action" "Ouvrir un port" "Fermer un port" "Voir les règles")
    
    case $action in
        "Ouvrir un port")
            local port=$(zenity --entry --title="Ouvrir un port" --text="Entrez le numéro du port :")
            local proto=$(zenity --list --title="Protocole" --column="Protocole" "tcp" "udp")
            if validate_port "$port"; then
                iptables -A INPUT -p "$proto" --dport "$port" -j ACCEPT
                log_action "Port $port/$proto ouvert."
                zenity --info --text="Port $port/$proto ouvert avec succès."
            else
                zenity --error --text="Port invalide."
            fi
            ;;
        "Fermer un port")
            local port=$(zenity --entry --title="Fermer un port" --text="Entrez le numéro du port :")
            local proto=$(zenity --list --title="Protocole" --column="Protocole" "tcp" "udp")
            if validate_port "$port"; then
                iptables -D INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null
                if [ $? -eq 0 ]; then
                    log_action "Port $port/$proto fermé."
                    zenity --info --text="Port $port/$proto fermé avec succès."
                else
                    zenity --error --text="Règle non trouvée."
                fi
            else
                zenity --error --text="Port invalide."
            fi
            ;;
        "Voir les règles")
            local rules=$(iptables -L INPUT -n --line-numbers)
            zenity --text-info --title="Règles INPUT" --content-text="$rules" --width=600 --height=400
            ;;
    esac
}

manage_ips() {
    local action=$(zenity --list --title="Gestion des IPs" --column="Action" "Bloquer une IP" "Autoriser une IP" "Voir les blocages")
    
    case $action in
        "Bloquer une IP")
            local ip=$(zenity --entry --title="Bloquer IP" --text="Entrez l'adresse IP :")
            if validate_ip "$ip"; then
                iptables -A INPUT -s "$ip" -j DROP
                log_action "IP $ip bloquée."
                zenity --info --text="IP $ip bloquée avec succès."
            else
                zenity --error --text="IP invalide."
            fi
            ;;
        "Autoriser une IP")
            local ip=$(zenity --entry --title="Autoriser IP" --text="Entrez l'adresse IP :")
            if validate_ip "$ip"; then
                iptables -A INPUT -s "$ip" -j ACCEPT
                log_action "IP $ip autorisée."
                zenity --info --text="IP $ip autorisée avec succès."
            else
                zenity --error --text="IP invalide."
            fi
            ;;
        "Voir les blocages")
            local rules=$(iptables -L INPUT -n | grep DROP)
            zenity --text-info --title="IPs Bloquées" --content-text="$rules" --width=600 --height=400
            ;;
    esac
}

manage_nat() {
    local action=$(zenity --list --title="Gestion NAT" --column="Action" "Activer NAT (Masquerading)" "Désactiver NAT" "Statut NAT")
    
    case $action in
        "Activer NAT (Masquerading)")
            echo 1 > /proc/sys/net/ipv4/ip_forward
            iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
            iptables -A FORWARD -i "$LAN_IF" -o "$WAN_IF" -j ACCEPT
            iptables -A FORWARD -i "$WAN_IF" -o "$LAN_IF" -m state --state ESTABLISHED,RELATED -j ACCEPT
            log_action "NAT activé sur $WAN_IF."
            zenity --info --text="NAT et routage IP activés."
            ;;
        "Désactiver NAT")
            echo 0 > /proc/sys/net/ipv4/ip_forward
            iptables -t nat -F POSTROUTING
            log_action "NAT désactivé."
            zenity --info --text="NAT et routage IP désactivés."
            ;;
        "Statut NAT")
            local status=$(iptables -t nat -L -n)
            zenity --text-info --title="Statut NAT" --content-text="$status"
            ;;
    esac
}

view_logs() {
    if [ -f "$LOG_FILE" ]; then
        zenity --text-info --title="Journaux du Pare-feu" --filename="$LOG_FILE" --width=800 --height=500
    else
        zenity --error --text="Fichier de log introuvable."
    fi
}

save_restore() {
    local action=$(zenity --list --title="Sauvegarde / Restauration" --column="Action" "Sauvegarder les règles" "Restaurer les règles")
    
    case $action in
        "Sauvegarder les règles")
            iptables-save > "$RULES_SAVE"
            log_action "Règles sauvegardées dans $RULES_SAVE."
            zenity --info --text="Règles sauvegardées avec succès."
            ;;
        "Restaurer les règles")
            if [ -f "$RULES_SAVE" ]; then
                iptables-restore < "$RULES_SAVE"
                log_action "Règles restaurées depuis $RULES_SAVE."
                zenity --info --text="Règles restaurées avec succès."
            else
                zenity --error --text="Aucun fichier de sauvegarde trouvé."
            fi
            ;;
    esac
}

bonus_features() {
    local action=$(zenity --list --title="Fonctions Bonus" --column="Action" "Protection Brute-force SSH" "Limitation Connexions" "Détection Scan")
    
    case $action in
        "Protection Brute-force SSH")
            iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
            iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
            log_action "Protection brute-force SSH activée."
            zenity --info --text="Protection SSH activée (max 4 tentatives/min)."
            ;;
        "Limitation Connexions")
            local limit=$(zenity --entry --title="Limite" --text="Nombre max de connexions par IP (ex: 10) :")
            iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above "$limit" -j REJECT
            log_action "Limitation de connexions à $limit activée."
            zenity --info --text="Limitation activée."
            ;;
        "Détection Scan")
            iptables -N SCAN_DETECTION
            iptables -A INPUT -p tcp --tcp-flags ALL NONE -j SCAN_DETECTION
            iptables -A INPUT -p tcp --tcp-flags ALL ALL -j SCAN_DETECTION
            iptables -A SCAN_DETECTION -j LOG --log-prefix "SCAN-DETECTED: "
            iptables -A SCAN_DETECTION -j DROP
            log_action "Détection de scan de ports activée."
            zenity --info --text="Détection de scan activée."
            ;;
    esac
}

# --- Menu Principal (Adapté) ---
main_menu() {
    while true; do
        local choice=$(zenity --list --title="SECURENET Firewall - Menu Principal" \
            --column="Option" --column="Description" \
            "1" "Initialiser le pare-feu (Sécurisé)" \
            "2" "Réinitialiser (Tout autoriser)" \
            "3" "Gérer les Ports (Ouverture/Fermeture)" \
            "4" "Gérer les Adresses IP (Blocage/Autorisation)" \
            "5" "Gérer le NAT et Routage" \
            "6" "Consulter les Journaux (Logs)" \
            "7" "Sauvegarde / Restauration" \
            "8" "Fonctions Bonus (Sécurité avancée)" \
            "9" "Retour")

        case $choice in
            "1") init_firewall ;;
            "2") reset_firewall ;;
            "3") manage_ports ;;
            "4") manage_ips ;;
            "5") manage_nat ;;
            "6") view_logs ;;
            "7") save_restore ;;
            "8") bonus_features ;;
            "9"|*) break ;;
        esac
    done
}

# Exécution directe lors de l'appel depuis le menu principal
main_menu
