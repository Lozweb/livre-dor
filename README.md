# Livre d'or audio

Borne d'enregistrement audio autonome sur Raspberry Pi 4. Un appui sur le bouton lance une introduction audio, puis enregistre le message du visiteur jusqu'au prochain appui.

---

## Matériel nécessaire

| Composant | Détail |
|---|---|
| Raspberry Pi 4 | N'importe quel modèle avec GPIO 40 broches |
| Micro USB | Carte son USB (ex. USB PnP Sound Device C-Media) |
| LED | 5 mm, n'importe quelle couleur |
| Résistance | 330 Ω (pour la LED) |
| Bouton poussoir | Momentané, normalement ouvert |
| Résistance | 10 kΩ (optionnelle, pull-up interne GPIO utilisé) |
| Carte SD | 16 Go minimum recommandé |
| Câbles Dupont | Mâle-femelle pour GPIO |

---

## Câblage GPIO

```
Raspberry Pi 4 — Vue broche GPIO (header 40 pins)

       3.3V  [ 1] [ 2]  5V
      GPIO2  [ 3] [ 4]  5V
      GPIO3  [ 5] [ 6]  GND ──────────────────┐
      GPIO4  [ 7] [ 8]  GPIO14                │
        GND  [ 9] [10]  GPIO15                │
     GPIO17  [11] [12]  GPIO18                │  ← LED : GPIO17 [11]
     GPIO27  [13] [14]  GND                   │  ← Bouton : GPIO27 [13]
     ...                                      │
```

### LED témoin (GPIO 17)

```
GPIO17 [pin 11] ──── résistance 330Ω ──── LED (+) ──── LED (-) ──── GND [pin 6]
```

- LED allumée = système prêt / en attente
- LED éteinte = lecture de l'introduction en cours

### Bouton poussoir (GPIO 27)

```
GPIO27 [pin 13] ──── bouton ──── GND [pin 14]
```

Le pull-up interne du Pi est activé par le code (`into_input_pullup`). Aucune résistance externe nécessaire.

- GPIO27 = HIGH (3.3V) au repos
- GPIO27 = LOW (0V) quand le bouton est appuyé

---

## Fonctionnement

1. Démarrage → LED allumée, système en attente
2. **Appui bouton** → lecture du fichier `intro.wav`
3. Fin de l'intro → enregistrement démarre automatiquement
4. **Appui bouton** → enregistrement arrêté, fichier `.wav` sauvegardé
5. Retour en attente (étape 1)

> Appuyer sur le bouton **pendant** la lecture de l'intro interrompt l'intro et revient en attente sans enregistrer.

Les enregistrements sont sauvegardés dans `/home/julien/recordings/` au format `YYYYMMDD_HHMMSS.wav`.

---

## Déploiement

Voir [DEPLOY.md](DEPLOY.md) pour les instructions complètes : installation des dépendances, compilation sur le Pi, et activation du service systemd.
