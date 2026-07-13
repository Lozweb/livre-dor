# Livre d'or audio

Borne d'enregistrement audio autonome sur Raspberry Pi 4. Les visiteurs décrochent le combiné, écoutent une introduction, puis laissent un message vocal.

---

## Matériel nécessaire

| Composant | Détail |
|---|---|
| Raspberry Pi 4 | N'importe quel modèle avec GPIO 40 broches |
| Micro USB | Carte son USB (ex. USB PnP Sound Device C-Media) |
| LED | 5 mm, n'importe quelle couleur |
| Résistance | 330 Ω (pour la LED) |
| Bouton / combiné | Bouton momentané ou vrai combiné téléphonique |
| Carte SD | 16 Go minimum recommandé |
| Câbles Dupont | Mâle-femelle pour GPIO |

---

## Câblage GPIO

```
Raspberry Pi 4 — Vue broche GPIO (header 40 pins)

       3.3V  [ 1] [ 2]  5V
      GPIO2  [ 3] [ 4]  5V
      GPIO3  [ 5] [ 6]  GND
      GPIO4  [ 7] [ 8]  GPIO14
        GND  [ 9] [10]  GPIO15
     GPIO17  [11] [12]  GPIO18    ← LED témoin
     GPIO27  [13] [14]  GND       ← Bouton / crochet téléphonique
```

### LED témoin (GPIO 17)

```
GPIO17 [pin 11] ──── résistance 330Ω ──── LED (+) ──── LED (-) ──── GND [pin 6]
```

- LED allumée = système prêt / en attente
- LED éteinte = lecture de l'introduction en cours

### Bouton / crochet téléphonique (GPIO 27)

```
GPIO27 [pin 13] ──── bouton ──── GND [pin 14]
```

Pull-up interne activé par le code — aucune résistance externe nécessaire.

- HIGH (3.3V) au repos = raccroché
- LOW (0V) = décroché / bouton appuyé

---

## Fonctionnement

1. Démarrage → LED allumée, système en attente
2. **Décroché** → lecture de `intro.wav`
3. Fin de l'intro → enregistrement démarre automatiquement
4. **Raccroché** → enregistrement arrêté, fichier `.wav` sauvegardé
5. Retour en attente

> Raccrocher pendant l'intro interrompt sans enregistrer.

Les enregistrements sont sauvegardés dans `~/recordings/` avec un nom aléatoire (`<hex>.wav`). L'ordre chronologique est déterminé par la date de modification du fichier.

---

## Interface web

Le serveur expose une interface de gestion accessible depuis un navigateur.

**Fonctionnalités :**
- Lister, écouter et télécharger les enregistrements

**Accès :**
- `http://livre-dor.local` (depuis n'importe quel appareil sur le même réseau)

### Hotspot WiFi intégré (standalone)

Le Pi fonctionne en standalone : il diffuse uniquement son propre réseau WiFi (`livre-dor` par défaut), sans connexion à une box ni à Internet. Connectez votre smartphone ou laptop à ce réseau, puis ouvrez `http://livre-dor.local` dans le navigateur.

> Voir [DEPLOY.md](DEPLOY.md) pour la configuration du hotspot et du hostname.

---

## Déploiement

Voir [DEPLOY.md](DEPLOY.md) pour les instructions complètes.

```bash
./book.sh deploy       # build frontend + compiler + déployer sur le Pi
./book.sh hotspot      # configurer le hotspot WiFi standalone (une seule fois)
./book.sh setup-mdns   # configurer livre-dor.local via avahi (une seule fois)
./book.sh logs         # suivre les logs en direct
```

---

## Architecture

Cargo workspace avec deux membres :

- **`phone`** — lib + bin : machine à états GPIO/audio (Raspberry Pi)
- **`server`** — bin : serveur web axum, embarque `phone` comme librairie

Le service systemd tourne le binaire `server` qui gère à la fois le téléphone et l'API HTTP.
