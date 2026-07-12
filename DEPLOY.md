# Déploiement — Livre d'or

Ce document décrit la mise en place complète sur un Raspberry Pi 4 vierge.

---

## Prérequis

### Sur le Pi (une seule fois)

```bash
sudo apt update
sudo apt install -y libasound2-dev pkg-config build-essential

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

### Clé SSH (depuis votre machine)

```bash
ssh-copy-id PI_USER@PI_HOST
```

---

## Configurer book.sh

Éditez la section `CONFIGURATION` en haut de `book.sh` :

```bash
REMOTE_USER="pi"                 # utilisateur SSH sur le Pi
REMOTE_HOST="192.168.1.X"        # IP du Pi sur votre réseau
REMOTE_DIR="/home/pi/livre-dor"  # chemin de déploiement sur le Pi
SERVICE_NAME="livre-dor"
HOTSPOT_SSID="livre-dor"         # SSID du hotspot WiFi
HOTSPOT_PASSWORD="votremotdepasse"
HOTSPOT_CHANNEL="6"              # voir note canal ci-dessous
```

---

## Déployer l'application

```bash
./book.sh deploy
```

Cette commande :
1. Synchronise les sources vers le Pi (`rsync`)
2. Compile `server` en mode release sur le Pi (`cargo build --release -p server`)
3. Redémarre le service systemd

---

## Configurer le service systemd (une seule fois)

Adaptez le chemin utilisateur dans `livre-dor.service` si votre user Pi n'est pas `julien`, puis :

```bash
./book.sh rsync
ssh PI_USER@PI_HOST "sudo cp ~/livre-dor/livre-dor.service /etc/systemd/system/ && \
  sudo systemctl daemon-reload && \
  sudo systemctl enable livre-dor && \
  sudo systemctl start livre-dor"
```

> À répéter uniquement si `livre-dor.service` est modifié. Pour les mises à jour de code, `./book.sh deploy` suffit.

---

## Configurer le hotspot WiFi

Le Pi fonctionne en mode dual WiFi : connecté à votre box **et** point d'accès pour smartphones et laptops.

### Choisir le bon canal

Le canal du hotspot doit correspondre à celui de votre box, sinon le laptop ne verra pas le réseau. Pour trouver le canal de votre box :

```bash
nmcli dev wifi list
# Repérez votre SSID et notez la colonne CHAN
```

Renseignez cette valeur dans `HOTSPOT_CHANNEL` dans `book.sh`, puis :

```bash
./book.sh hotspot
```

Le script `scripts/setup-hotspot.sh` :
- Crée l'interface virtuelle `uap0` (persistante via systemd)
- Configure NetworkManager pour le hotspot sur `uap0`
- Laisse `wlan0` connecté à votre box normalement
- Est idempotent : relancez-le sans risque pour modifier la config

**Variables disponibles dans `book.sh` :**

| Variable | Description |
|---|---|
| `HOTSPOT_SSID` | Nom du réseau WiFi diffusé |
| `HOTSPOT_PASSWORD` | Mot de passe WPA2 (min. 8 caractères) |
| `HOTSPOT_CHANNEL` | Canal WiFi — doit correspondre à votre box |

**Accès une fois connecté au hotspot :**
- `http://192.168.4.1:8080` (IP fixe du Pi sur le hotspot)
- `http://PI_HOST:8080` (IP du Pi sur votre réseau local)

---

## Commandes utiles

```bash
./book.sh deploy   # synchronise + compile + redémarre (mise à jour standard)
./book.sh hotspot  # (re)configure le hotspot WiFi
./book.sh status   # état du service
./book.sh logs     # logs en direct
./book.sh restart  # redémarrage rapide sans recompilation
./book.sh rsync    # synchronisation seule
./book.sh build    # compile -p server en local
```

---

## Structure des fichiers sur le Pi

```
/home/PI_USER/livre-dor/
├── phone/src/          ← machine à états téléphone (GPIO + audio)
│   ├── lib.rs          ← PhoneState, run() — importé par server
│   ├── main.rs         ← binaire standalone (dev/test)
│   ├── audio.rs
│   ├── gpio.rs
│   └── files.rs
├── server/src/         ← serveur web (axum)
│   └── main.rs
├── scripts/
│   └── setup-hotspot.sh
├── Cargo.toml          ← workspace [phone, server]
├── intro.wav           ← message d'accueil
└── target/release/
    └── server          ← binaire de production

/home/PI_USER/recordings/   ← enregistrements (YYYYMMDD_HHMMSS.wav)
/etc/systemd/system/livre-dor.service   ← ExecStart → server
/etc/systemd/system/uap0.service        ← interface virtuelle AP
```
