# Déploiement — Livre d'or

Raspberry Pi 4 · `julien@192.168.1.42`

---

## 1. Préparer le Raspberry Pi (une seule fois)

```bash
ssh julien@192.168.1.42
```

```bash
sudo apt update
sudo apt install -y libasound2-dev pkg-config build-essential

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

---

## 2. Envoyer les sources depuis votre machine

```bash
rsync -avz --exclude target/ \
  /home/julien/workspace/perso/livre-dor/ \
  julien@192.168.1.42:/home/julien/livre-dor/
```

---

## 3. Compiler sur le Pi

```bash
ssh julien@192.168.1.42
cd /home/julien/livre-dor
cargo build --release
```

Le binaire compilé se trouve dans `target/release/livre-dor`.

---

## 4. Déposer le fichier audio d'intro

```bash
scp /chemin/local/intro.wav julien@192.168.1.42:/home/julien/livre-dor/intro.wav
```

---

## 5. Créer le dossier d'enregistrements

```bash
ssh julien@192.168.1.42 "mkdir -p /home/julien/recordings"
```

---

## 6. Installer et activer le service systemd

```bash
ssh julien@192.168.1.42
sudo cp /home/julien/livre-dor/livre-dor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable livre-dor
sudo systemctl start livre-dor
```

---

## 7. Vérifier que le service tourne

```bash
sudo systemctl status livre-dor
```

---

## 8. Suivre les logs en temps réel

```bash
sudo journalctl -u livre-dor -f
```

---

## Commandes utiles

```bash
# Statut du service
sudo systemctl status livre-dor

# Arrêter le service
sudo systemctl stop livre-dor

# Redémarrer après une mise à jour
sudo systemctl restart livre-dor

# Logs depuis le dernier démarrage
sudo journalctl -u livre-dor -b
```

---

## Mise à jour du code

Depuis votre machine, après modification des sources :

```bash
rsync -avz --exclude target/ \
  /home/julien/workspace/perso/livre-dor/ \
  julien@192.168.1.42:/home/julien/livre-dor/

ssh julien@192.168.1.42 "cd /home/julien/livre-dor && cargo build --release && sudo systemctl restart livre-dor"
```

---

## Structure des fichiers sur le Pi

```
/home/julien/livre-dor/
├── src/
├── Cargo.toml
├── intro.wav               ← fichier audio d'introduction
└── target/release/livre-dor

/home/julien/recordings/    ← enregistrements horodatés (YYYYMMDD_HHMMSS.wav)

/etc/systemd/system/livre-dor.service
```
