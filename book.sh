#!/bin/bash

# ==============================================================================
# CLI de Gestion du Projet Livre d'or (book.sh)
# ==============================================================================

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ==============================================================================
# CONFIGURATION (À modifier avec tes propres accès)
# ==============================================================================
REMOTE_USER="julien"
REMOTE_HOST="192.168.1.42"
REMOTE_DIR="/home/julien/livre-dor"
SERVICE_NAME="livre-dor"
# ==============================================================================

log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

show_help() {
    echo "Usage: ./book.sh [commande]"
    echo ""
    echo "Commandes disponibles :"
    echo "  deploy   - Synchronise, compile sur le serveur distant et redémarre"
    echo "  rsync    - Synchronise uniquement les fichiers locaux vers le serveur"
    echo "  restart  - Redémarre le service systemd sur le serveur"
    echo "  status   - Vérifie l'état du service systemd sur le serveur"
    echo "  logs     - Affiche les logs en direct (journalctl) du serveur"
    echo "  build    - Compile le projet localement en mode release"
    echo "  help     - Affiche cette aide"
}

cmd_rsync() {
    log_info "Synchronisation des fichiers vers le serveur distant..."
    # On exclut le dossier target/ local pour ne pas envoyer les builds lourds
    rsync -avz --delete --exclude 'target/' --exclude '.git/' --exclude '.github/' ./ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}
    if [ $? -eq 0 ]; then
        log_success "Synchronisation rsync terminée avec succès !"
    else
        log_error "Erreur lors de la synchronisation rsync."
        exit 1
    fi
}

cmd_restart() {
    log_info "Redémarrage du service systemd : ${SERVICE_NAME}..."
    ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo systemctl restart ${SERVICE_NAME}"
    if [ $? -eq 0 ]; then
        log_success "Le service a été redémarré."
    else
        log_error "Impossible de redémarrer le service."
        exit 1
    fi
}

# Analyse de l'argument reçu
case "$1" in

deploy)
        log_info "🚀 Lancement de la procédure globale de déploiement..."
        cmd_rsync

        log_info "🛠️  Compilation en cours (Cargo build --release) sur le serveur..."
        # Utilisation de source $HOME/.cargo/env pour charger les variables d'environnement de Rust
        ssh ${REMOTE_USER}@${REMOTE_HOST} "source \$HOME/.cargo/env && cd ${REMOTE_DIR} && cargo build --release"
        if [ $? -ne 0 ]; then
            log_error "La compilation distante a échoué. Avortement."
            exit 1
        fi

        cmd_restart
        log_success "🎉 Déploiement terminé avec succès !"
        ;;

    rsync)
        cmd_rsync
        ;;

    restart)
        cmd_restart
        ;;

    status)
        log_info "Vérification du statut de ${SERVICE_NAME}..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo systemctl status ${SERVICE_NAME}"
        ;;

    logs)
        log_info "Affichage des logs en direct (Ctrl+C pour quitter)..."
        ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo journalctl -u ${SERVICE_NAME} -f -n 50"
        ;;

    build)
        log_info "Compilation locale en mode release..."
        cargo build --release
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