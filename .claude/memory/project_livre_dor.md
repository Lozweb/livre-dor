---
name: project-livre-dor
description: Description complète du projet livre d'or audio — téléphone vintage sur Raspberry Pi 4
metadata:
  type: project
---

Projet : borne d'enregistrement audio autonome déguisée en téléphone vintage. Les visiteurs décrochent le combiné, entendent une introduction audio, puis laissent un message vocal.

**Why:** Projet personnel/artistique, le téléphone est en production et fonctionne.

**How to apply:** Toutes les décisions techniques doivent rester cohérentes avec l'architecture actuelle (Rust, Raspberry Pi 4, workspace Cargo, déploiement par SSH/rsync). Penser "fiabilité terrain" avant tout — la borne tourne sans surveillance.

---

## Matériel

- **Raspberry Pi 4** — `julien@192.168.1.42` (WiFi), `192.168.1.44` (Ethernet)
- **GPIO 17** : LED témoin (HIGH = prêt/attente, LOW = lecture intro en cours)
- **GPIO 27** : crochet du téléphone (HIGH = raccroché/repos, LOW = décroché)
- **Micro USB** : carte son USB PnP C-Media (premier périphérique d'entrée CPAL)
- **Combiné téléphonique** : vrai téléphone, le décrocher ferme un circuit (High → Low)

## Architecture logicielle

**Cargo workspace** (edition 2021) avec deux membres :

### `phone/` — lib + bin
- `src/lib.rs` : expose `PhoneState` (enum), `run(Arc<RwLock<PhoneState>>) -> Result<()>`, constantes pub
- `src/main.rs` : 4 lignes, appelle `phone::run()` standalone
- `src/audio.rs`, `src/gpio.rs`, `src/files.rs` : modules internes

Machine à états : `Idle → PlayingIntro → Recording → Idle`

### `server/` — bin
- Importe `phone = { path = "../phone" }`
- Lance `phone::run()` dans `tokio::task::spawn_blocking`
- Expose API HTTP via **axum** sur `0.0.0.0:8080`
- `GET /api/health` → `{ "ok": true }` (seul endpoint implémenté pour l'instant)
- État partagé via `Arc<RwLock<PhoneState>>`

**Le service systemd tourne `server` (pas `phone`).**

## Chemins sur le Pi

| Chemin | Contenu |
|---|---|
| `~/livre-dor/` | Sources workspace |
| `~/livre-dor/intro.wav` | Message d'accueil |
| `~/livre-dor/target/release/server` | Binaire de prod |
| `~/recordings/YYYYMMDD_HHMMSS.wav` | Enregistrements des visiteurs |
| `/etc/systemd/system/livre-dor.service` | Service systemd (ExecStart → server) |
| `/etc/systemd/system/uap0.service` | Interface virtuelle AP WiFi |

## Dépendances Cargo

### phone
`rppal 0.18`, `rodio 0.17` (wav+mp3), `cpal 0.15`, `hound 3.5`, `chrono 0.4`, `anyhow 1`

### server
`phone` (path), `axum 0.7`, `tokio 1` (full), `tower-http 0.5` (fs+cors), `serde 1` (derive), `serde_json 1`

## WiFi Pi — standalone (depuis 2026-07-13)

Le mode dual AP+STA (uap0 virtuel + wlan0 client vers la box) a été abandonné : trop instable au reboot (le chipset WiFi du Pi 4 ne tenait pas la concurrence AP+STA de façon fiable au démarrage). Le Pi tourne désormais en **AP seul** :
- `wlan0` → hotspot "livre-dor" directement (plus de `uap0`, plus de connexion à la box)
- IP fixe 192.168.4.1, géré par NetworkManager (profil NM `livre-dor-hotspot`, `ipv4.method shared`)
- Plus de service `uap0.service` (supprimé)
- `eth0` reste disponible en secours (câble direct)
- Config dans `book.sh` : `HOTSPOT_SSID`, `HOTSPOT_PASSWORD`, `HOTSPOT_CHANNEL` (canal libre, plus de contrainte de correspondance avec une box)
- Script `scripts/setup-hotspot.sh` : idempotent, migre automatiquement l'ancien mode dual vers standalone si relancé sur un Pi pas encore migré

**REMOTE_HOST dans `book.sh` = hostname `livre-dor` (pas une IP)** — résolu via avahi/mDNS, stable contrairement à un bail DHCP. Important de fixer ce hostname à l'installation de l'OS (Raspberry Pi Imager / `raspi-config`).

Smartphone/laptop → WiFi "livre-dor" → `http://livre-dor.local` ou `http://192.168.4.1`

**Accès SSH sans mot de passe** : `ssh-copy-id julien@livre-dor` a été fait le 2026-07-13, la clé publique du laptop de Julien est dans `authorized_keys` du Pi.

## Workflow de déploiement

```bash
./book.sh deploy    # rsync + cargo build --release -p server + restart service
./book.sh hotspot   # (re)configure le hotspot WiFi sur le Pi
./book.sh build     # compile -p server en local
./book.sh restart   # redémarre le service
./book.sh status    # état du service
./book.sh logs      # journalctl -f
```

Mise à jour code → `./book.sh deploy` uniquement.
