# Rapport Technique : Développement d'un Pare-feu Linux avec Interface Graphique

**Projet :** Administration Système Linux & Sécurité Réseau
**Entreprise :** SECURENET SARL
**Auteur :** Manus
**Date :** 6 Février 2026

---

## 1. Introduction
Dans le cadre de la sécurisation du réseau interne de l'entreprise **SECURENET SARL** (192.168.10.0/24), ce projet vise à mettre en œuvre une solution de pare-feu administrable via une interface graphique simple et intuitive. L'objectif est de fournir aux administrateurs un outil permettant de gérer les flux réseaux sans nécessiter une maîtrise approfondie de la syntaxe complexe de `iptables`.

## 2. Analyse du Besoin
L'entreprise nécessite une passerelle Internet sécurisée capable de :
- Filtrer les accès entrants et sortants par défaut.
- Gérer dynamiquement l'ouverture et la fermeture des ports TCP/UDP.
- Bloquer ou autoriser des adresses IP spécifiques.
- Partager la connexion Internet via le NAT (Masquerading).
- Journaliser les tentatives d'intrusion et les paquets bloqués.
- Assurer une protection contre les attaques courantes (Brute-force SSH, Scans).

## 3. Architecture Réseau
Le serveur pare-feu est positionné comme passerelle entre le réseau local (LAN) et le réseau externe (WAN).

| Interface | Zone | Réseau / IP |
| :--- | :--- | :--- |
| `eth0` | WAN (Internet) | IP Publique / DHCP |
| `eth1` | LAN (Interne) | 192.168.10.0/24 |

**Politique de sécurité appliquée :**
- **INPUT :** DROP (Tout bloquer par défaut)
- **FORWARD :** DROP (Pas de routage par défaut)
- **OUTPUT :** ACCEPT (Autoriser les sorties du serveur)

## 4. Explication du Code
Le script `securenet_firewall.sh` est structuré de manière modulaire :

### A. Initialisation et Sécurité
Le script commence par vérifier les privilèges root. Une fonction `authenticate` demande un mot de passe administrateur via Zenity avant d'accéder au menu principal.

### B. Fonctions de Gestion
- `init_firewall` : Configure les politiques par défaut et autorise le trafic indispensable (loopback, connexions établies).
- `manage_ports` : Permet d'ajouter ou supprimer des règles de filtrage par port.
- `manage_ips` : Gère le bannissement ou l'autorisation d'hôtes spécifiques.
- `manage_nat` : Active le routage IP (`ip_forward`) et configure le masquerading sur l'interface WAN.

### C. Journalisation et Maintenance
- `view_logs` : Affiche le contenu de `/var/log/securenet.log` dans une fenêtre Zenity.
- `save_restore` : Utilise `iptables-save` et `iptables-restore` pour la persistance des règles.

### D. Fonctions Bonus
- **Anti Brute-force :** Utilise le module `recent` d'iptables pour limiter les tentatives de connexion SSH.
- **Détection de Scan :** Identifie et bloque les paquets avec des combinaisons de flags TCP suspectes.

## 5. Guide d'Utilisation
1. Exécuter le script : `sudo ./securenet_firewall.sh`
2. Saisir le mot de passe administrateur (par défaut : `admin`).
3. Utiliser le menu interactif pour configurer les règles.
4. Consulter les logs régulièrement pour surveiller l'activité.

## 6. Conclusion
Cette solution combine la puissance de `iptables` avec la simplicité de `Zenity`. Elle répond aux exigences de sécurité de SECURENET SARL tout en offrant une interface d'administration accessible. Le système est évolutif et permet d'ajouter facilement de nouvelles fonctionnalités de sécurité.
