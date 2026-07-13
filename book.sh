#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ==============================================================================
# CONFIGURATION (À modifier selon votre installation)
# ==============================================================================
# REMOTE_HOST doit correspondre au hostname défini sur le Pi à l'installation
# de l'OS (raspi-config / Raspberry Pi Imager) + avahi (./book.sh setup-mdns).
# Un hostname est stable ; une IP DHCP peut changer à chaque redémarrage.
REMOTE_USER="julien"
REMOTE_HOST="livre-dor"
REMOTE_DIR="/home/julien/livre-dor"
SERVICE_NAME="livre-dor"
HOTSPOT_SSID="livre-dor"
HOTSPOT_PASSWORD="metapixl"
HOTSPOT_CHANNEL="11"
# ==============================================================================

log_info()    { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

show_help() {
    echo "Usage: ./book.sh [commande]"
    echo ""
    echo "Commandes disponibles :"
    echo "  deploy      - Build frontend, synchronise, compile -p server sur le Pi et redémarre"
    echo "  rsync       - Synchronise uniquement les sources vers le Pi"
    echo "  build       - Compile -p server en local"
    echo "  restart     - Redémarre le service systemd sur le Pi"
    echo "  status      - Vérifie l'état du service systemd"
    echo "  logs        - Affiche les logs en direct (journalctl)"
    echo "  hotspot     - Configure le hotspot WiFi standalone sur le Pi"
    echo "  setup-mdns  - Configure avahi (livre-dor.local) sur le Pi (à faire une seule fois)"
    echo "  help        - Affiche cette aide"
}

cmd_rsync() {
    log_info "Synchronisation des sources vers le Pi..."
    rsync -avz --delete \
        --exclude 'target/' --exclude '.git/' --exclude '.github/' \
        --exclude 'frontend/node_modules/' \
        ./ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}
    if [ $? -eq 0 ]; then
        log_success "Synchronisation terminée."
    else
        log_error "Erreur rsync."
        exit 1
    fi
}

cmd_build_frontend() {
    log_info "Build du frontend React..."
    (cd frontend && npm run build)
    if [ $? -ne 0 ]; then
        log_error "Build frontend échoué."
        exit 1
    fi
    log_success "Frontend buildé dans frontend/dist/."
}

cmd_restart() {
    log_info "Redémarrage du service ${SERVICE_NAME}..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo systemctl restart ${SERVICE_NAME}"
    if [ $? -eq 0 ]; then
        log_success "Service redémarré."
    else
        log_error "Impossible de redémarrer le service."
        exit 1
    fi
}

case "$1" in

    deploy)
        log_info "Déploiement complet..."
        cmd_build_frontend
        cmd_rsync

        log_info "Compilation -p server sur le Pi..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} \
            "source \$HOME/.cargo/env && cd ${REMOTE_DIR} && cargo build --release -p server"
        if [ $? -ne 0 ]; then
            log_error "Compilation distante échouée."
            exit 1
        fi

        cmd_restart
        log_success "Déploiement terminé. Accessible sur http://livre-dor.local"
        ;;

    rsync)
        cmd_rsync
        ;;

    build)
        log_info "Compilation locale -p server..."
        cargo build --release -p server
        ;;

    restart)
        cmd_restart
        ;;

    status)
        log_info "Statut de ${SERVICE_NAME}..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo systemctl status ${SERVICE_NAME}"
        ;;

    logs)
        log_info "Logs en direct (Ctrl+C pour quitter)..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo journalctl -u ${SERVICE_NAME} -f -n 50"
        ;;

    hotspot)
        log_info "Configuration du hotspot WiFi standalone sur le Pi..."
        rsync -q scripts/setup-hotspot.sh ${REMOTE_USER}@${REMOTE_HOST}:/tmp/setup-hotspot.sh
        ssh ${REMOTE_USER}@${REMOTE_HOST} \
            "HOTSPOT_SSID='${HOTSPOT_SSID}' HOTSPOT_PASSWORD='${HOTSPOT_PASSWORD}' HOTSPOT_CHANNEL='${HOTSPOT_CHANNEL}' bash /tmp/setup-hotspot.sh"
        if [ $? -eq 0 ]; then
            log_success "Hotspot configuré."
        else
            log_error "Échec de la configuration du hotspot."
            exit 1
        fi
        ;;

    setup-mdns)
        log_info "Configuration mDNS (livre-dor.local) sur le Pi..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "bash -s" << 'EOF'
set -e
sudo apt-get install -y avahi-daemon
sudo hostnamectl set-hostname livre-dor
if ! grep -q "127.0.1.1.*livre-dor" /etc/hosts; then
    sudo sed -i "s/^127.0.1.1.*/127.0.1.1\tlivre-dor/" /etc/hosts
fi
sudo systemctl enable avahi-daemon
sudo systemctl restart avahi-daemon
echo "mDNS configuré. Le Pi sera accessible sur http://livre-dor.local"
EOF
        if [ $? -eq 0 ]; then
            log_success "mDNS configuré. Accessible sur http://livre-dor.local"
        else
            log_error "Échec configuration mDNS."
            exit 1
        fi
        ;;

    help|--help|-h|"")
        show_help
        ;;

    *)
        log_error "Commande inconnue : '$1'"
        show_help
        exit 1
        ;;
esac
