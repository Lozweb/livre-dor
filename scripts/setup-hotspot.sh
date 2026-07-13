#!/bin/bash
set -e

SSID="${HOTSPOT_SSID:-livre-dor}"
PASSWORD="${HOTSPOT_PASSWORD:-changeme}"
IP="${HOTSPOT_IP:-192.168.4.1}"
CHANNEL="${HOTSPOT_CHANNEL:-6}"
CON_NAME="livre-dor-hotspot"
UAP0_SERVICE="/etc/systemd/system/uap0.service"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; RESET='\033[0m'
log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }

# --- 1. Nettoyage de l'ancien mode dual (uap0 + connexion WiFi vers la box) ---
if [ -f "$UAP0_SERVICE" ]; then
    log_info "Suppression de l'ancien mode dual (uap0.service)..."
    sudo systemctl stop uap0.service 2>/dev/null || true
    sudo systemctl disable uap0.service 2>/dev/null || true
    sudo rm -f "$UAP0_SERVICE"
    sudo systemctl daemon-reload
    sudo iw dev uap0 del 2>/dev/null || true
    log_ok "uap0.service supprimé"
fi

log_info "Suppression des connexions WiFi client (STA) — le Pi fonctionne en standalone..."
while read -r name; do
    [ -z "$name" ] && continue
    [ "$name" = "$CON_NAME" ] && continue
    mode=$(nmcli -g 802-11-wireless.mode con show "$name" 2>/dev/null)
    if [ "$mode" != "ap" ]; then
        log_info "Suppression du profil client '$name'..."
        sudo nmcli con delete "$name"
    fi
done < <(nmcli -t -f NAME,TYPE con show | awk -F: '$2=="802-11-wireless"{print $1}')

# --- 2. Profil AP directement sur wlan0 (interface physique) ---
if nmcli con show "$CON_NAME" &>/dev/null; then
    log_info "Suppression du profil hotspot existant..."
    sudo nmcli con delete "$CON_NAME"
fi

log_info "Création du profil hotspot standalone (SSID: $SSID, IP: $IP, canal: $CHANNEL, interface: wlan0)..."
sudo nmcli con add type wifi ifname wlan0 con-name "$CON_NAME" \
    ssid "$SSID" \
    802-11-wireless.mode ap \
    802-11-wireless.band bg \
    802-11-wireless.channel "$CHANNEL" \
    ipv4.method shared \
    ipv4.addresses "${IP}/24" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$PASSWORD" \
    connection.autoconnect yes

sudo nmcli con up "$CON_NAME"

log_ok "Hotspot standalone actif — SSID: $SSID | IP: $IP | Canal: $CHANNEL | Interface: wlan0"
echo ""
nmcli dev status
