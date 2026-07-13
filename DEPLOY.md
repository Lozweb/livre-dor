# Déploiement — Livre d'or

Guide complet pour déployer le projet sur un Raspberry Pi 4 depuis zéro.

---

## Prérequis

### Sur le Pi (une seule fois)

```bash
sudo apt update
sudo apt install -y libasound2-dev pkg-config build-essential

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

### Sur le laptop de déploiement

- `ssh` et `rsync`
- `npm` (Node.js ≥ 18) pour builder le frontend
- Clé SSH configurée : `ssh-copy-id PI_USER@PI_HOST`

> **Hostname du Pi** : à l'installation de l'OS (Raspberry Pi Imager, options avancées, ou `sudo raspi-config` → *System Options* → *Hostname*), donnez au Pi le hostname `livre-dor` (ou adaptez `REMOTE_HOST`, `HOTSPOT_SSID`, etc. dans `book.sh` en conséquence). Les scripts (`book.sh`, `setup-mdns`) s'appuient sur ce hostname pour se connecter de façon stable — une IP DHCP peut changer à chaque redémarrage, un hostname résolu par avahi/mDNS non.

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

## Première installation

### 1. Configurer le service systemd

Adaptez le chemin utilisateur dans `livre-dor.service` si votre user Pi n'est pas `julien`, puis :

```bash
./book.sh rsync
ssh PI_USER@PI_HOST "sudo cp ~/livre-dor/livre-dor.service /etc/systemd/system/ && \
  sudo systemctl daemon-reload && \
  sudo systemctl enable livre-dor"
```

> À répéter uniquement si `livre-dor.service` est modifié. Pour les mises à jour de code, `./book.sh deploy` suffit.

### 2. Configurer le hotspot WiFi

Le Pi fonctionne en **standalone** : `wlan0` diffuse uniquement le point d'accès `livre-dor`, il n'est connecté à aucune box. Aucune connexion Internet n'est nécessaire ni utilisée — l'interface de gestion et le SSH sont accessibles uniquement via ce hotspot (ou par câble Ethernet en secours).

Le canal WiFi (`HOTSPOT_CHANNEL` dans `book.sh`) est libre — aucune contrainte de le faire correspondre à une box, puisqu'il n'y en a plus.

```bash
./book.sh hotspot
```

Le script `scripts/setup-hotspot.sh` :
- Supprime l'ancien mode dual s'il existe (`uap0.service`, connexions WiFi client type STA)
- Configure NetworkManager pour un hotspot directement sur `wlan0`
- Est idempotent : relancez-le sans risque pour modifier la config

> **Migration depuis l'ancien mode dual** : si votre Pi a été configuré avant ce changement (interface virtuelle `uap0` + connexion à une box), relancer `./book.sh hotspot` nettoie automatiquement l'ancienne configuration et bascule en standalone.

### 3. Configurer mDNS (accès par nom)

```bash
./book.sh setup-mdns
```

Installe `avahi-daemon` et configure le hostname `livre-dor` sur le Pi. Après cette étape, le Pi est accessible sur `http://livre-dor.local` depuis tous les appareils (macOS, Linux, Windows 10+, iOS, Android).

À faire **une seule fois**.

### 4. Premier déploiement

```bash
./book.sh deploy
```

Cette commande :
1. Build le frontend React (`npm run build` dans `frontend/`)
2. Synchronise les sources vers le Pi (`rsync`)
3. Compile `server` en mode release sur le Pi (`cargo build --release -p server`)
4. Redémarre le service systemd

---

## Déploiements suivants

```bash
./book.sh deploy
```

Suffit pour tout mettre à jour — frontend et backend.

---

## Commandes disponibles

| Commande | Description |
|---|---|
| `./book.sh deploy` | Build frontend + sync + compile sur Pi + restart |
| `./book.sh rsync` | Sync les sources uniquement (sans build ni restart) |
| `./book.sh build` | Compile `-p server` en local (vérification) |
| `./book.sh restart` | Redémarre le service sur le Pi |
| `./book.sh status` | État du service systemd |
| `./book.sh logs` | Logs en direct (`journalctl -f`) |
| `./book.sh hotspot` | Configure le hotspot WiFi standalone |
| `./book.sh setup-mdns` | Configure `livre-dor.local` via avahi (une seule fois) |

---

## Accès à l'interface web

| Situation | URL |
|---|---|
| Connecté au hotspot WiFi du Pi | `http://livre-dor.local` |
| IP directe (fallback) | `http://192.168.4.1` |
| Câble Ethernet direct (secours) | `http://livre-dor.local` |

---

## Développement local

```bash
# Terminal 1 — serveur Rust (API uniquement)
cargo run -p server

# Terminal 2 — frontend avec hot-reload
cd frontend && npm run dev
```

Le proxy Vite redirige `/api` vers le serveur Rust. L'adresse cible est configurable :

```bash
VITE_API_TARGET=http://livre-dor.local npm run dev
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
├── frontend/dist/      ← build React (servi par axum)
├── scripts/
│   └── setup-hotspot.sh
├── Cargo.toml          ← workspace [phone, server]
├── intro.wav           ← message d'accueil
└── target/release/
    └── server          ← binaire de production

/home/PI_USER/recordings/           ← enregistrements (<hex>.wav)
/etc/systemd/system/livre-dor.service   ← ExecStart → server
```

---

## Dépannage

**`livre-dor.local` ne répond pas**
- Vérifier que `avahi-daemon` tourne : `ssh pi "systemctl status avahi-daemon"`
- Android peut mettre quelques secondes à résoudre le nom mDNS — normal.
- Fallback : utiliser l'IP directe.

**Hotspot non visible**
- Vérifier que `wlan0` est bien en mode AP : `ssh pi "nmcli dev status"` (device `wlan0`, connexion `livre-dor-hotspot`)
- Si le Pi a été configuré avant le passage en standalone, relancer `./book.sh hotspot` pour nettoyer l'ancien mode dual (`uap0`).

**Erreur de compilation sur le Pi**
- Vérifier les dépendances audio : `sudo apt install -y libasound2-dev`
- Si `cargo` n'est pas dans le PATH via SSH : géré automatiquement par `book.sh deploy`.

**Service qui ne démarre pas**
```bash
./book.sh logs
./book.sh status
```

**Frontend pas mis à jour après deploy**
- Vider le cache navigateur (Ctrl+Shift+R) — le navigateur peut avoir mis en cache l'ancienne version.
