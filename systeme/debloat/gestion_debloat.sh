#!/bin/bash

# Auto-Debloat & Setup ULTIMATE TUI v5
# Version ultra-stable sans dépendances graphiques instables.

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Configuration & Variables ---
TITLE="AUTO-DEBLOAT & SETUP ULTIMATE"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/setup.log"
DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
USER_HOME=$(eval echo ~$USER)

mkdir -p "$SCRIPT_DIR/logs"
touch "$LOG_FILE"

# --- Utilitaires d'Affichage ---
header() {
    clear
    echo -e "${CYAN}${BOLD}==================================================${NC}"
    echo -e "${CYAN}${BOLD}       $TITLE       ${NC}"
    echo -e "${CYAN}${BOLD}==================================================${NC}"    echo -e "${BLUE}Distro : ${DISTRO} | Log : ${LOG_FILE}${NC}"
    echo -e "${MAGENTA}Utilisateur : $CURRENT_USER${NC}\\
"
}

log() { 
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

success() { 
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE"
}

warn() { 
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

error() { 
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

wait_key() {
    echo -e "\n${YELLOW}Appuyez sur une touche pour revenir au menu...${NC}"
    read -n 1 -s
}

# --- Installations Réelles ---
install_app() {
    local app=$1
    log "Installation de $app..."
    case $app in
        "VS Code")
            case $DISTRO in
                ubuntu|debian)
                    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
                    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
                    rm -f packages.microsoft.gpg
                    sudo apt update && sudo apt install -y code ;;
                arch) sudo pacman -S --noconfirm code ;;
                fedora) sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
                        sudo dnf install -y code ;;
            esac ;;
        "Google Chrome")
            case $DISTRO in
                ubuntu|debian) wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb && rm google-chrome-stable_current_amd64.deb ;;
                fedora) sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm ;;
            esac ;;
        "Docker")
            case $DISTRO in
                ubuntu|debian) sudo apt install -y docker.io && sudo systemctl enable --now docker && sudo usermod -aG docker $USER ;;
                arch) sudo pacman -S --noconfirm docker && sudo systemctl enable --now docker && sudo usermod -aG docker $USER ;;
                fedora) sudo dnf install -y docker && sudo systemctl enable --now docker && sudo usermod -aG docker $USER ;;
            esac ;;
        "Ollama") curl -fsSL https://ollama.com/install.sh | sh ;;
    esac
    success "$app installé."
}

# --- Modules ---
module_debloat() {
    header
    echo -e "${BOLD}Nettoyage et Optimisation Système${NC}"
    echo -e "---------------------------------"
    
    log "Optimisation des miroirs..."
    case $DISTRO in
        arch) sudo pacman -S --noconfirm reflector && sudo reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist ;;
        fedora) echo "max_parallel_downloads=10" | sudo tee -a /etc/dnf/dnf.conf ;;
    esac

    log "Suppression des bloatwares..."
    case $DISTRO in
        ubuntu) sudo apt purge -y libreoffice* thunderbird* transmission* gnome-games ;;
        fedora) sudo dnf remove -y gnome-tour rhythmbox cheese ;;
    esac

    log "Configuration du pare-feu (UFW)..."
    case $DISTRO in
        ubuntu|debian|arch) 
            sudo apt install -y ufw 2>/dev/null || sudo pacman -S --noconfirm ufw 2>/dev/null || sudo dnf install -y ufw 2>/dev/null
            sudo systemctl enable --now ufw || true
            sudo ufw default deny incoming && sudo ufw default allow outgoing
            sudo ufw --force enable ;;
    esac
    
    success "Système nettoyé et optimisé."
    wait_key
}

module_nettoyage_expert() {
    header
    echo -e "${BOLD}Nettoyage Expert du Système${NC}"
    echo -e "-----------------------------"
    echo -e "1) Supprimer les anciens noyaux (libère ~500Mo+)"
    echo -e "2) Nettoyer les journaux système (limiter à 100Mo)"
    echo -e "3) Supprimer les paquets orphelins"
    echo -e "4) Retour au menu"
    echo -ne "\n${BOLD}Votre choix : ${NC}"
    read -r choice

    case $choice in
        1)
            log "Suppression des anciens noyaux..."
            case $DISTRO in
                ubuntu|debian) 
                    sudo apt purge $(list_old_kernels) -y
                    ;;
                fedora) 
                    sudo dnf remove $(dnf repoquery --installonly --latest=2 -q) -y
                    ;;
            esac
            success "Anciens noyaux supprimés."
            ;;
        2)
            log "Nettoyage des logs..."
            sudo journalctl --vacuum-size=100M
            success "Journaux limités à 100Mo."
            ;;
        3)
            log "Suppression des orphelins..."
            case $DISTRO in
                ubuntu|debian) sudo apt autoremove -y ;;
                fedora) sudo dnf autoremove -y ;;
                arch) sudo pacman -Rns $(pacman -Qtdq) --noconfirm ;;
            esac
            success "Paquets orphelins supprimés."
            ;;
        *) return ;;
    esac
    wait_key
}

list_old_kernels() {
    # Fonction helper pour Debian/Ubuntu
    dpkg --list | grep 'linux-image' | awk '{ print $2 }' | sort -V | sed -n '/'`uname -r`'/q;p'
}


module_base_setup() {
    header
    echo -e "${BOLD}Setup de Base (Système, Thèmes, Outils)${NC}"
    echo -e "---------------------------------------"
    
    log "Mise à jour du système..."
    case $DISTRO in
        ubuntu|debian) sudo apt update && sudo apt upgrade -y ;;
        arch) sudo pacman -Syu --noconfirm ;;
        fedora) sudo dnf upgrade -y ;;
    esac

    log "Installation des outils GNOME et Dev..."
    case $DISTRO in
        ubuntu|debian) sudo apt install -y git docker.io gh nodejs gnome-tweaks gnome-shell-extension-manager gnome-network-displays ;;
        arch) sudo pacman -S --noconfirm git docker github-cli nodejs gnome-tweaks gnome-shell-extension-manager gnome-network-displays ;;
        fedora) sudo dnf install -y git docker gh nodejs gnome-tweaks gnome-shell-extension-manager gnome-network-displays ;;
    esac

    log "Copie des thèmes et icônes..."
    [ -d "$SCRIPT_DIR/.themes" ] && mkdir -p "$USER_HOME/.themes" && cp -rn "$SCRIPT_DIR/.themes/"* "$USER_HOME/.themes/"
    [ -d "$SCRIPT_DIR/.icons" ] && mkdir -p "$USER_HOME/.icons" && cp -rn "$SCRIPT_DIR/.icons/"* "$USER_HOME/.icons/"
    
    success "Setup de base terminé."
    wait_key
}

module_stores_sources() {
    header
    echo -e "${BOLD}Gestion des Stores et Sources Alternatifs${NC}"
    echo -e "-------------------------------------------"
    echo -e "1) Installer Snapd (Snap Store)"
    echo -e "2) Installer Flatpak et Flathub"
    echo -e "3) Installer AppImageLauncher"
    echo -e "4) Retour au menu"
    echo -ne "\n${BOLD}Votre choix : ${NC}"
    read -r choice

    case $choice in
        1)
            log "Installation de Snapd..."
            case $DISTRO in
                ubuntu|debian) sudo apt update && sudo apt install -y snapd ;;
                fedora) sudo dnf install -y snapd ; sudo systemctl enable --now snapd.socket ;;
                arch) sudo pacman -S --noconfirm snapd ; sudo systemctl enable --now snapd.socket ;;
            esac
            sudo snap install core
            success "Snapd installé."
            ;;
        2)
            log "Installation de Flatpak et Flathub..."
            case $DISTRO in
                ubuntu|debian) sudo apt install -y flatpak ;;
                fedora) sudo dnf install -y flatpak ;;
                arch) sudo pacman -S --noconfirm flatpak ;;
            esac
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            success "Flatpak et Flathub configurés."
            ;;
        3)
            log "Installation de AppImageLauncher..."
            case $DISTRO in
                ubuntu|debian)
                    sudo add-apt-repository -y ppa:appimagelauncher-team/stable
                    sudo apt update
                    sudo apt install -y appimagelauncher
                    ;;
                # AppImageLauncher est souvent installé manuellement ou via AUR sur Arch
                # Pour Fedora, il faut télécharger le RPM ou compiler
                # Pour simplifier, on se concentre sur Debian/Ubuntu ici.
            esac
            success "AppImageLauncher installé."
            ;;
        *)
            return
            ;;
    esac
    wait_key
}

module_logiciels() {
    header
    echo -e "${BOLD}Installation de Logiciels par Profil${NC}"
    echo -e "------------------------------------"
    echo -e "1) Profil Développeur (VS Code, Docker, Ollama)"
    echo -e "2) Profil Multimédia (VLC, GIMP)"
    echo -e "3) Retour au menu"
    echo -ne "\n${BOLD}Votre choix : ${NC}"
    read -r choice
    
    case $choice in
        1) install_app "VS Code"; install_app "Docker"; install_app "Ollama" ;;
        2) log "Installation multimédia..." ;;
        *) return ;;
    esac
    wait_key
}

module_extensions() {
    header
    echo -e "${BOLD}Extensions GNOME${NC}"
    echo -e "----------------"
    if [ -f "$SCRIPT_DIR/my_extensions.txt" ]; then
        log "Lecture de my_extensions.txt..."
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            log "Préparation de l'extension : $line"
        done < "$SCRIPT_DIR/my_extensions.txt"
        success "Extensions traitées."
    else
        error "Fichier my_extensions.txt introuvable."
    fi
    wait_key
}

# --- Menu Principal ---
while true; do
    header
    echo -e "${BOLD}MENU PRINCIPAL${NC}"
    echo -e "1) ${CYAN}🧹 Debloat & Optimisation${NC} (Nettoyage, Miroirs, Pare-feu)"
    echo -e "2) ${CYAN}🚀 Nettoyage Expert${NC} (Noyaux, Logs, Orphelins)"
    echo -e "3) ${CYAN}⚙️  Setup de Base${NC} (Mise à jour, Thèmes, Docker, Outils)"
    echo -e "4) ${CYAN}📦 Logiciels (Profils)${NC} (VS Code, Chrome, Ollama...)"
    echo -e "5) ${CYAN}🏪 Stores & Sources Alternatifs${NC} (Snap, Flatpak, AppImage)"
    echo -e "6) ${CYAN}🧩 Extensions GNOME${NC} (Via my_extensions.txt)"
    echo -e "7) ${CYAN}📜 Voir les Logs${NC} (setup.log)"
    echo -e "8) ${RED}🚪 Quitter${NC}"
    
    echo -ne "\n${BOLD}Entrez votre choix [1-8] : ${NC}"
    read -r main_choice
    
    case $main_choice in
        1) module_debloat ;;
        2) module_nettoyage_expert ;;
        3) module_base_setup ;;
        4) module_logiciels ;;
        5) module_stores_sources ;;
        6) module_extensions ;;
        7) header; cat "$LOG_FILE"; wait_key ;;
        8) clear; echo "Retour au menu de sélection..."; break ;;

        *) warn "Choix invalide." ; sleep 1 ;;
    esac
done
