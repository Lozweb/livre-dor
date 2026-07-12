#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ==============================================================================
# CONFIGURATION (À modifier selon votre installation)
# ==============================================================================
REMOTE_USER="julien"
REMOTE_HOST="192.168.1.42"
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
    echo "  deploy   - Synchronise, compile -p phone sur le Pi et redémarre le service"
    echo "  rsync    - Synchronise uniquement les sources vers le Pi"
    echo "  build    - Compile -p server en local"
    echo "  restart  - Redémarre le service systemd sur le Pi"
    echo "  status   - Vérifie l'état du service systemd"
    echo "  logs     - Affiche les logs en direct (journalctl)"
    echo "  hotspot  - Configure le hotspot WiFi dual-mode sur le Pi"
    echo "  help     - Affiche cette aide"
}

cmd_rsync() {
    log_info "Synchronisation des sources vers le Pi..."
    rsync -avz --delete \
        --exclude 'target/' --exclude '.git/' --exclude '.github/' \
        ./ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}
    if [ $? -eq 0 ]; then
        log_success "Synchronisation terminée."
    else
        log_error "Erreur rsync."
        exit 1
    fi
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
        cmd_rsync

        log_info "Compilation -p server sur le Pi..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} \
            "source \$HOME/.cargo/env && cd ${REMOTE_DIR} && cargo build --release -p server"
        if [ $? -ne 0 ]; then
            log_error "Compilation distante échouée."
            exit 1
        fi

        cmd_restart
        log_success "Déploiement terminé."
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
        log_info "Configuration du hotspot WiFi sur le Pi..."
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

    help|--help|-h|"")
        show_help
        ;;

    *)
        log_error "Commande inconnue : '$1'"
        show_help
        exit 1
        ;;
esac
