#!/bin/bash

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Configuration ---
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$UTILS_DIR/logs/actions.log"
DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

# --- Gestion des Erreurs et Logs ---
log_action() {
    local module=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$module] $message par $CURRENT_USER" >> "$LOG_FILE"
}

notify_user() {
    local title=$1
    local message=$2
    local type=${3:-info} # info, error, warning, question
    
    case $type in
        "info") zenity --info --title="$title" --text="$message" --width=300 2>/dev/null ;;
        "error") zenity --error --title="$title" --text="$message" --width=300 2>/dev/null ;;
        "warning") zenity --warning --title="$title" --text="$message" --width=300 2>/dev/null ;;
        "notify") zenity --notification --text="$message" 2>/dev/null ;;
    esac
}

# --- Gestion des Paquets Unifiée ---
install_package() {
    local pkg=$1
    log_action "System" "Tentative d'installation de $pkg"
    
    case $DISTRO in
        ubuntu|debian) sudo apt update && sudo apt install -y "$pkg" ;;
        fedora) sudo dnf install -y "$pkg" ;;
        arch) sudo pacman -S --noconfirm "$pkg" ;;
        *) return 1 ;;
    esac
}

# --- Validation des Entrées ---
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_username() {
    local user=$1
    if [[ $user =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- Barre de Progression ---
run_with_progress() {
    local title=$1
    local text=$2
    local cmd=$3
    
    (
        eval "$cmd"
        echo "100"
    ) | zenity --progress --title="$title" --text="$text" --percentage=0 --auto-close --pulsate 2>/dev/null
}
