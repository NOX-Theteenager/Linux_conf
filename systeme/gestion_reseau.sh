#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils.sh"

while true; do
    ACTION=$(zenity --list --title="Gestion des Cartes Réseau" \
        --column="Option" \
        "1" "Lister les interfaces réseau" \
        "2" "Afficher les détails d'une interface" \
        "3" "Activer/Désactiver une interface" \
        "4" "Renouveler l'adresse IP (DHCP)" \
        "5" "Configuration statique" \
        "6" "Test de connectivité (Ping)" \
        "7" "Afficher la table de routage" \
        "8" "Retour" \
        --height=450 --width=400 2>/dev/null)

    if [ $? -ne 0 ] || [ "$ACTION" == "8" ]; then
        break
    fi

    case $ACTION in
        1)  # Lister les interfaces réseau
            log_action "Liste des interfaces réseau demandée."
            ip -br addr show | zenity --text-info --title="Interfaces Réseau" --width=600 --height=500
            ;;
        2)  # Afficher les détails d'une interface
            IFACES=$(ip -br link show | awk '{print $1}')
            IFACE=$(echo "$IFACES" | zenity --list --title="Détails Interface" --column="Interface" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$IFACE" ]; then
                log_action "Réseau" "Détails de l'interface $IFACE demandés."
                ip addr show "$IFACE" | zenity --text-info --title="Détails de $IFACE" --width=600 --height=500
            fi
            ;;
        3)  # Activer/Désactiver une interface
            IFACE=$(zenity --entry --text="Nom de l'interface à activer/désactiver:" --title="Activer/Désactiver Interface" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$IFACE" ]; then
                CHOICE=$(zenity --list --title="Action sur l'interface $IFACE" \
                    --column="Action" "Activer" "Désactiver" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    if [ "$CHOICE" == "Activer" ]; then
                        sudo ip link set "$IFACE" up 2>/tmp/err
                        if [ $? -eq 0 ]; then
                            log_action "Interface $IFACE activée."
                            zenity --info --text="Interface $IFACE activée avec succès."
                        else
                            zenity --error --text="Erreur lors de l'activation: $(cat /tmp/err)"
                        fi
                    elif [ "$CHOICE" == "Désactiver" ]; then
                        sudo ip link set "$IFACE" down 2>/tmp/err
                        if [ $? -eq 0 ]; then
                            log_action "Interface $IFACE désactivée."
                            zenity --info --text="Interface $IFACE désactivée avec succès."
                        else
                            zenity --error --text="Erreur lors de la désactivation: $(cat /tmp/err)"
                        fi
                    fi
                fi
            fi
            ;;
        4)  # Renouveler l'adresse IP (DHCP)
            IFACE=$(zenity --entry --text="Nom de l'interface pour renouveler l'IP (DHCP):" --title="Renouveler IP" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$IFACE" ]; then
                log_action "Renouvellement DHCP pour $IFACE demandé."
                sudo dhclient -r "$IFACE" && sudo dhclient "$IFACE" 2>/tmp/err
                if [ $? -eq 0 ]; then
                    zenity --info --text="Adresse IP pour $IFACE renouvelée avec succès (DHCP)."
                else
                    zenity --error --text="Erreur lors du renouvellement DHCP: $(cat /tmp/err)"
                fi
            fi
            ;;
        5)  # Configuration statique
            IFACE=$(zenity --entry --text="Nom de l'interface pour configuration statique:" --title="Config Statique" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$IFACE" ]; then
                IP_ADDR=$(zenity --entry --text="Adresse IP/Masque (ex: 192.168.1.10/24):" --title="Config Statique" 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$IP_ADDR" ]; then
                    GATEWAY=$(zenity --entry --text="Passerelle (optionnel):" --title="Config Statique" 2>/dev/null)
                    log_action "Configuration statique pour $IFACE: IP $IP_ADDR, Passerelle $GATEWAY."
                    sudo ip addr flush dev "$IFACE" 2>/tmp/err_flush
                    sudo ip addr add "$IP_ADDR" dev "$IFACE" 2>/tmp/err_ip
                    if [ $? -eq 0 ]; then
                        if [ -n "$GATEWAY" ]; then
                            sudo ip route add default via "$GATEWAY" dev "$IFACE" 2>/tmp/err_gw
                            if [ $? -eq 0 ]; then
                                zenity --info --text="Configuration statique appliquée à $IFACE."
                            else
                                zenity --error --text="Erreur passerelle: $(cat /tmp/err_gw)"
                            fi
                        else
                            zenity --info --text="Configuration statique appliquée à $IFACE."
                        fi
                    else
                        zenity --error --text="Erreur IP: $(cat /tmp/err_ip)"
                    fi
                fi
            fi
            ;;
        6)  # Test de connectivité (Ping)
            DEST=$(zenity --entry --text="Hôte ou IP à pinger:" --title="Test Ping" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$DEST" ]; then
                log_action "Test ping vers $DEST demandé."
                ping -c 4 "$DEST" | zenity --text-info --title="Résultat Ping vers $DEST" --width=600 --height=500
            fi
            ;;
        7)  # Afficher la table de routage
            log_action "Table de routage affichée."
            ip route show | zenity --text-info --title="Table de Routage" --width=600 --height=500
            ;;
    esac
done
