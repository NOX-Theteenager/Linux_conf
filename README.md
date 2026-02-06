# 🚀 Auto-Debloat & Post-Install Script (Linux)

Ce projet est un outil d'automatisation **"Tout-en-un"** destiné aux développeurs et administrateurs système sur Linux. Il permet de configurer une machine fraîchement installée en quelques minutes via une interface graphique terminal (TUI) interactive et élégante.

Compatible avec : **Ubuntu, Debian, Fedora, Arch Linux, Manjaro, Pop!_OS**.

## ✨ Fonctionnalités Principales

### 🛠️ 1. Setup de Base Intelligent
- Mise à jour complète du système.
- Installation des indispensables : `git`, `docker`, `docker-compose`, `gh` (GitHub CLI), `curl`.
- **Smart Check** : Détecte si Git et Docker sont déjà configurés pour ne pas redemander vos identifiants inutilement.
- Configuration automatique des groupes Docker (plus besoin de `sudo`).

### 📦 2. Gestion Logiciels & Stores
- **Stores Alternatifs** : Installation en un clic de **Snap Store**, **Flathub**, et **Bauh** (gestionnaire universel).
- **Catalogue Modifiable** : Installation de logiciels définis dans `software.json` (VS Code, Chrome, Flutter, VirtualBox, VMWare deps, etc.).
- Gestion automatique des commandes d'installation selon votre distribution (`apt`, `dnf`, `pacman`).

### 🎨 3. Personnalisation & UI
- **Nerd Fonts** : Téléchargement et installation automatique de **JetBrains Mono** et **FiraCode** (indispensable pour les terminaux modernes type Starship/P10k).
- **Thèmes & Icônes** : Copie automatique de vos dossiers `.themes` et `.icons`.
- **Extensions GNOME** : Installation automatique d'extensions via `gnome-extensions-cli` (contourne les restrictions navigateur).

### 🧹 4. Debloat & Maintenance
- **Nettoyage Profond** : Suppression des orphelins, cache paquets et **vieux Kernels Linux**.
- **Anti-Télémétrie** : Désactivation des services de tracking (Whoopsie, Apport, GNOME report).
- **Flatpak Cleaner** : Suppression des runtimes inutilisés.

### 🛡️ 5. Sécurité & Backup
- **Health Check** : Vérification de l'espace disque et d'Internet avant lancement.
- **SSH Cloud Upload** : Envoi automatique de votre clé publique vers **GitHub** ou **GitLab**.
- **Backup/Restore** : Sauvegarde et restauration complète de la configuration de bureau GNOME (`dconf`).

---

## 📂 Structure du Projet

```text
.
├── setup.sh          # Le script principal (Lancez-moi !)
├── software.json        # Liste configurable de vos logiciels
├── my_extensions.txt    # Liste des IDs d'extensions GNOME
├── README.md            # Ce fichier
├── .themes/             # (Optionnel) Vos thèmes GTK
└── .icons/              # (Optionnel) Vos packs d'icônes
