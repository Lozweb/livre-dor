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

# --- 1. Interface virtuelle uap0 ---
if systemctl is-enabled uap0.service &>/dev/null; then
    log_info "uap0.service déjà activé — skip"
else
    log_info "Création de uap0.service..."
    printf '[Unit]\nDescription=Virtual AP interface uap0\nAfter=sys-subsystem-net-devices-wlan0.device\nBefore=NetworkManager.service\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/sbin/iw dev wlan0 interface add uap0 type __ap\nExecStop=/sbin/iw dev uap0 del\n\n[Install]\nWantedBy=multi-user.target\n' \
        | sudo tee "$UAP0_SERVICE" > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable uap0.service
    sudo systemctl start uap0.service
    log_ok "uap0.service activé"
fi

if ! ip link show uap0 &>/dev/null; then
    sudo systemctl start uap0.service
fi

# --- 2. Profil NM hotspot ---
if nmcli con show "$CON_NAME" &>/dev/null; then
    log_info "Suppression du profil hotspot existant..."
    sudo nmcli con delete "$CON_NAME"
fi

log_info "Création du profil hotspot (SSID: $SSID, IP: $IP, canal: $CHANNEL)..."
sudo nmcli con add type wifi ifname uap0 con-name "$CON_NAME" \
    ssid "$SSID" \
    802-11-wireless.mode ap \
    802-11-wireless.band bg \
    802-11-wireless.channel "$CHANNEL" \
    ipv4.method shared \
    ipv4.addresses "${IP}/24" \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "$PASSWORD" \
    connection.autoconnect yes \
    connection.autoconnect-priority -10

sudo nmcli con up "$CON_NAME"

log_ok "Hotspot actif — SSID: $SSID | IP: $IP | Canal: $CHANNEL"
echo ""
nmcli dev status
