#!/bin/bash

# ==============================================================================
# CONFIGURATION & VARIABLES
# ==============================================================================

LOG_FILE="/tmp/setup_v7.log"
SUMMARY_FILE="/tmp/setup_summary.txt"
> "$LOG_FILE"
> "$SUMMARY_FILE"

REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
PROJECT_DIR=$(dirname "$(readlink -f "$0")")
JSON_FILE="$PROJECT_DIR/software.json"
EXT_FILE="$PROJECT_DIR/my_extensions.txt"
BACKUP_DIR="$REAL_HOME/.setup_backups"

# ==============================================================================
# DÉTECTION OS
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Erreur : Lancez ce script avec sudo."
  exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi

case "$OS" in
    ubuntu|debian|pop|linuxmint|kali)
        install_cmd="apt-get install -y"
        update_cmd="apt-get update"
        docker_pkgs="docker.io docker-compose-plugin" 
        lock_file="/var/lib/dpkg/lock-frontend"
        distro="debian"
        ;;
    fedora|centos|rhel)
        install_cmd="dnf install -y"
        update_cmd="dnf check-update"
        docker_pkgs="docker docker-compose"
        lock_file="/var/run/dnf.pid"
        distro="fedora"
        ;;
    arch|manjaro|endeavouros)
        install_cmd="pacman -S --noconfirm"
        update_cmd="pacman -Sy"
        docker_pkgs="docker docker-compose"
        lock_file="/var/lib/pacman/db.lck"
        distro="arch"
        ;;
esac

# Pré-requis (ajout de unzip et fontconfig pour les polices)
for cmd in dialog jq pip3 git curl unzip fc-cache; do
    if ! command -v $cmd &> /dev/null; then 
        $install_cmd $cmd > /dev/null 2>&1
    fi
done

# ==============================================================================
# HEALTH CHECK
# ==============================================================================

health_check() {
    dialog --infobox "Vérification de la santé du système..." 3 40
    sleep 1
    errors=""
    if ! ping -c 1 8.8.8.8 &> /dev/null; then errors+="[CRITIQUE] Pas de connexion Internet.\n"; fi
    if [ -f "$lock_file" ]; then errors+="[CRITIQUE] Apt/Dnf est verrouillé ($lock_file).\n"; fi
    if [ -n "$errors" ]; then
        dialog --title "Erreur Health Check" --yesno "Problèmes :\n\n$errors\nContinuer ?" 10 60
        if [ $? -ne 0 ]; then clear; exit 1; fi
    fi
}

# ==============================================================================
# UTILITAIRES
# ==============================================================================

log_success() { echo "[OK] $1" >> "$SUMMARY_FILE"; }
log_fail() { echo "[ERREUR] $1" >> "$SUMMARY_FILE"; }

run_tasks_with_gauge() {
    local title="$1"
    shift
    local tasks=("$@")
    local total=${#tasks[@]}
    local counter=0
    local step=$((100 / total))
    if [ $step -eq 0 ]; then step=1; fi
    (
        for task in "${tasks[@]}"; do
            desc="${task%%|*}"
            cmd="${task#*|}"
            echo $counter
            echo "XXX"; echo "$desc"; echo "XXX"
            eval "$cmd" >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then log_success "$desc"; else log_fail "$desc"; fi
            counter=$((counter + step))
        done
        echo 100
    ) | dialog --gauge "$title" 8 60 0
}

input_box() { dialog --inputbox "$1" 8 50 "$2" 3>&1 1>&2 2>&3; }
pass_box() { dialog --passwordbox "$1" 8 50 3>&1 1>&2 2>&3; }

# ==============================================================================
# SETUP BASE (SMART CHECK)
# ==============================================================================

setup_base() {
    local skip_git=0
    local skip_docker=0
    
    # 1. Vérification Intelligente
    dialog --infobox "Vérification des configurations existantes..." 3 50
    
    # Check Git
    CURRENT_NAME=$(sudo -u "$REAL_USER" git config --global user.name)
    CURRENT_EMAIL=$(sudo -u "$REAL_USER" git config --global user.email)
    if [ -n "$CURRENT_NAME" ] && [ -n "$CURRENT_EMAIL" ]; then
        skip_git=1
    fi

    # Check Docker (Vérifie si le fichier config contient une auth)
    if [ -f "$REAL_HOME/.docker/config.json" ]; then
        if grep -q "auths" "$REAL_HOME/.docker/config.json"; then
            skip_docker=1
        fi
    fi

    # 2. Demande d'infos (seulement si nécessaire)
    GIT_NAME=""
    GIT_EMAIL=""
    DOCKER_USER=""
    DOCKER_PASS=""

    if [ $skip_git -eq 0 ]; then
        GIT_NAME=$(input_box "Nom Git :" "$REAL_USER")
        GIT_EMAIL=$(input_box "Email Git :" "")
    else
        dialog --msgbox "Git est déjà configuré ($CURRENT_NAME).\nOn passe cette étape." 5 50
    fi

    if [ $skip_docker -eq 0 ]; then
        DOCKER_USER=$(input_box "User DockerHub (Optionnel) :" "")
        [ -n "$DOCKER_USER" ] && DOCKER_PASS=$(pass_box "Pass/Token DockerHub :")
    else
        dialog --msgbox "Docker semble déjà authentifié.\nOn passe cette étape." 5 50
    fi

    # 3. Installation et Configuration
    tasks=(
        "Mise à jour système|$update_cmd"
        "Install Outils Base|$install_cmd git gh curl net-tools unzip"
        "Install Docker|$install_cmd $docker_pkgs"
        "Enable Docker|systemctl enable --now docker"
        "Groupe Docker|usermod -aG docker $REAL_USER"
    )
    run_tasks_with_gauge "Installation Base" "${tasks[@]}"

    # Application Config Git
    if [ $skip_git -eq 0 ]; then
        [ -n "$GIT_NAME" ] && sudo -u "$REAL_USER" git config --global user.name "$GIT_NAME"
        [ -n "$GIT_EMAIL" ] && sudo -u "$REAL_USER" git config --global user.email "$GIT_EMAIL"
    fi
    
    # Application Config Docker
    if [ $skip_docker -eq 0 ] && [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_PASS" ]; then
        echo "$DOCKER_PASS" | sudo -u "$REAL_USER" docker login --username "$DOCKER_USER" --password-stdin >> "$LOG_FILE" 2>&1
    fi

    # SSH Check
    KEY="$REAL_HOME/.ssh/id_rsa"
    if [ ! -f "$KEY" ]; then
        sudo -u "$REAL_USER" ssh-keygen -t rsa -b 4096 -f "$KEY" -N "" -q
    fi
}

# ==============================================================================
# MODULE FONTS (NERD FONTS) - CORRIGÉ
# ==============================================================================

install_nerd_fonts() {
    local FONT_DIR="$REAL_HOME/.local/share/fonts"
    sudo -u "$REAL_USER" mkdir -p "$FONT_DIR"

    # Liens directs (Version fixe 3.2.1)
    local URL_JB="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
    local URL_FC="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"

    # Options CURL Explications :
    # -4 : FORCE IPv4 (Règle le problème de blocage à 0%)
    # -L : Suit la redirection 302 (Obligatoire pour GitHub)
    # -f : Échoue silencieusement si erreur serveur (pour que le script le détecte)
    # -o : Fichier de sortie
    local UA="Mozilla/5.0 (X11; Linux x86_64)"

    # Note : Le téléchargement peut prendre du temps. 
    # La barre de progression ne bougera pas PENDANT le téléchargement d'un fichier, 
    # elle ne bouge qu'une fois le fichier fini. C'est normal.
    
    tasks=(
        "Téléchargement JetBrains Mono (Patientez...)|curl -4 -L -A '$UA' -f -o /tmp/jb.zip $URL_JB"
        "Extraction JetBrains Mono|sudo -u $REAL_USER unzip -o /tmp/jb.zip -d $FONT_DIR/JetBrainsMono"
        "Téléchargement FiraCode (Patientez...)|curl -4 -L -A '$UA' -f -o /tmp/fc.zip $URL_FC"
        "Extraction FiraCode|sudo -u $REAL_USER unzip -o /tmp/fc.zip -d $FONT_DIR/FiraCode"
        "Nettoyage temporaire|rm -f /tmp/jb.zip /tmp/fc.zip"
        "Mise à jour du cache|sudo -u $REAL_USER fc-cache -fv"
    )
    
    run_tasks_with_gauge "Installation Nerd Fonts (v3.2.1)" "${tasks[@]}"

    # Vérification
    if [ -d "$FONT_DIR/JetBrainsMono" ] && [ "$(ls -A $FONT_DIR/JetBrainsMono)" ]; then
        dialog --msgbox "Succès ! Polices installées.\n\nConfigurez votre terminal sur 'JetBrainsMono Nerd Font'." 8 60
    else
        # Si curl échoue, on tente wget en mode IPv4 aussi
        dialog --infobox "Curl a échoué. Tentative de secours avec Wget (IPv4)..." 3 55
        sudo -u "$REAL_USER" wget --inet4-only --user-agent="$UA" -q -O /tmp/jb.zip "$URL_JB"
        sudo -u "$REAL_USER" unzip -o /tmp/jb.zip -d "$FONT_DIR/JetBrainsMono" >> "$LOG_FILE" 2>&1
        
        if [ -d "$FONT_DIR/JetBrainsMono" ] && [ "$(ls -A $FONT_DIR/JetBrainsMono)" ]; then
             dialog --msgbox "Installation réussie via Wget (Secours)." 6 50
        else
             dialog --msgbox "Échec critique. Vérifiez votre connexion internet.\nImpossible de joindre GitHub en IPv4." 8 60
        fi
    fi
}
# ==============================================================================
# MODULE DEBLOAT & NETTOYAGE
# ==============================================================================

system_cleanup() {
    dialog --yesno "ATTENTION : Ce module va :\n\n1. Supprimer les paquets orphelins\n2. Supprimer les vieux Kernels\n3. Désactiver la télémétrie (Whoopsie/Ubuntu)\n4. Supprimer les Runtimes Flatpak inutilisés\n\nContinuer ?" 12 60
    if [ $? -ne 0 ]; then return; fi

    tasks=()
    
    # 1. Gestion Kernels & Orphelins
    if [ "$distro" == "debian" ]; then
        tasks+=("Purge Kernels/Orphelins|apt-get autoremove --purge -y && apt-get clean")
        tasks+=("Arrêt Télémétrie (Whoopsie)|systemctl disable --now whoopsie 2>/dev/null || true")
        tasks+=("Arrêt Télémétrie (Apport)|systemctl disable --now apport 2>/dev/null || true")
    elif [ "$distro" == "fedora" ]; then
        tasks+=("Purge DNF|dnf autoremove -y && dnf clean all")
    elif [ "$distro" == "arch" ]; then
        tasks+=("Purge Cache Pacman|pacman -Sc --noconfirm")
    fi

    # 2. Désactivation Trackers GNOME (via gsettings user)
    # On désactive l'envoi de rapports techniques
    tasks+=("GNOME Privacy|sudo -u $REAL_USER gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true")

    # 3. Flatpak Debloat
    if command -v flatpak &>/dev/null; then
        tasks+=("Flatpak Clean Unused|flatpak uninstall --unused -y 2>/dev/null")
    fi
    
    run_tasks_with_gauge "Nettoyage & Optimisation" "${tasks[@]}"
}

# ==============================================================================
# AUTRES MODULES (STORES, SOFTWARE, EXTENSIONS, BACKUP)
# ==============================================================================

setup_stores() {
    local store_opts=("snap" "Snap Store" on "flatpak" "Flathub" on "bauh" "Bauh" off)
    choices=$(dialog --separate-output --checklist "Stores :" 15 60 5 "${store_opts[@]}" 2>&1 >/dev/tty)
    tasks=()
    for c in $choices; do
        case $c in
            "snap") tasks+=("Snap Store|$install_cmd snapd snap-store");;
            "flatpak") tasks+=("Flatpak|$install_cmd flatpak"); tasks+=("Flathub|flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo");;
            "bauh") tasks+=("Bauh Deps|$install_cmd python3-pip python3-venv"); tasks+=("Bauh Install|pip3 install bauh --break-system-packages || pip install bauh");;
        esac
    done
    [ ${#tasks[@]} -gt 0 ] && run_tasks_with_gauge "Stores" "${tasks[@]}"
}

install_softwares_json() {
    [ ! -f "$JSON_FILE" ] && return
    menu_options=$(jq -r '.[] | "\(.id) \"\(.name)\" \(.default)"' "$JSON_FILE")
    eval "local json_opts=($menu_options)"
    choices=$(dialog --separate-output --checklist "Logiciels" 20 60 15 "${json_opts[@]}" 2>&1 >/dev/tty)
    tasks=()
    for id in $choices; do
        cmd=$(jq -r --arg id "$id" --arg distro "cmd_$distro" '.[] | select(.id==$id) | if has($distro) then .[$distro] else .cmd_all end' "$JSON_FILE")
        name=$(jq -r --arg id "$id" '.[] | select(.id==$id) | .name' "$JSON_FILE")
        tasks+=("$name|$cmd")
    done
    [ ${#tasks[@]} -gt 0 ] && run_tasks_with_gauge "Logiciels" "${tasks[@]}"
}

install_extensions_cli() {
    sudo -u "$REAL_USER" pip3 install --break-system-packages gnome-extensions-cli >> "$LOG_FILE" 2>&1
    [ ! -f "$EXT_FILE" ] && return
    mapfile -t extensions < "$EXT_FILE"
    tasks=()
    for ext in "${extensions[@]}"; do
        [ -n "$ext" ] && tasks+=("Ext: $ext|sudo -u $REAL_USER gnome-extensions-cli install $ext")
    done
    run_tasks_with_gauge "Extensions" "${tasks[@]}"
}

backup_restore_modules() {
    action=$(dialog --menu "Backup / Restore" 12 50 2 1 "Sauvegarder Dconf" 2 "Restaurer Dconf" 2>&1 >/dev/tty)
    if [ "$action" == "1" ]; then
        sudo -u "$REAL_USER" mkdir -p "$BACKUP_DIR"
        file="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).ini"
        sudo -u "$REAL_USER" dconf dump / > "$file"
        dialog --msgbox "Sauvegardé : $file" 6 50
    elif [ "$action" == "2" ]; then
        [ ! -d "$BACKUP_DIR" ] && return
        files=$(ls "$BACKUP_DIR"/*.ini 2>/dev/null)
        i=1; declare -A fmap; menu_items=()
        for f in $files; do menu_items+=($i "$(basename "$f")"); fmap[$i]="$f"; ((i++)); done
        choice=$(dialog --menu "Restaurer :" 15 60 5 "${menu_items[@]}" 2>&1 >/dev/tty)
        [ -n "$choice" ] && cat "${fmap[$choice]}" | sudo -u "$REAL_USER" dconf load / && dialog --msgbox "Restauré." 6 40
    fi
}

upload_ssh_keys() {
    key_path="$REAL_HOME/.ssh/id_rsa.pub"
    [ ! -f "$key_path" ] && return
    local opts=("github" "GitHub" off "gitlab" "GitLab" off)
    choices=$(dialog --separate-output --checklist "Envoyer clé SSH :" 12 60 5 "${opts[@]}" 2>&1 >/dev/tty)
    for s in $choices; do
        if [ "$s" == "github" ]; then
            if ! sudo -u "$REAL_USER" gh auth status &>/dev/null; then
                clear; sudo -u "$REAL_USER" gh auth login -p ssh; read -p "Entrée..."
            fi
            sudo -u "$REAL_USER" gh ssh-key add "$key_path" --title "Key_$(date +%Y%m%d)" >> "$LOG_FILE" 2>&1
        elif [ "$s" == "gitlab" ]; then
            TOKEN=$(pass_box "GitLab Token :")
            [ -n "$TOKEN" ] && curl --silent --request POST --header "PRIVATE-TOKEN: $TOKEN" \
                --data-urlencode "key=$(cat $key_path)" --data-urlencode "title=Key_$(date +%Y%m%d)" \
                "https://gitlab.com/api/v4/user/keys" >> "$LOG_FILE" 2>&1
        fi
    done
}

# ==============================================================================
# MENU PRINCIPAL
# ==============================================================================

health_check

while true; do
    main_menu_opts=(
        1 "Setup Base (Smart Check: Git/Docker/SSH)"
        2 "Stores Alternatifs (Snap/Flatpak/Bauh)"
        3 "Logiciels (JSON List)"
        4 "Extensions GNOME (Auto-Install)"
        5 "Polices Nerd Fonts (Icons Terminal)"
        6 "Nettoyage & Debloat (Kernels/Télémétrie)"
        7 "Backup / Restore Config"
        8 "Upload Clés SSH (Cloud)"
        9 "Voir Rapport d'activité"
        0 "Quitter"
    )

    cmd=(dialog --clear --backtitle "DevOps Auto-Setup V7 (Master)" --title "Tableau de Bord" \
                --menu "Sélectionnez une action :" 20 70 12)
    
    choice=$("${cmd[@]}" "${main_menu_opts[@]}" 2>&1 >/dev/tty)
    
    case $choice in
        1) setup_base ;;
        2) setup_stores ;;
        3) install_softwares_json ;;
        4) install_extensions_cli ;;
        5) install_nerd_fonts ;;
        6) system_cleanup ;;
        7) backup_restore_modules ;;
        8) upload_ssh_keys ;;
        9) dialog --textbox "$SUMMARY_FILE" 20 70 ;;
        0) clear; exit 0 ;;
    esac
done
