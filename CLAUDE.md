# Livre d'or — Contexte projet

Borne d'enregistrement audio autonome sur **Raspberry Pi 4**, déguisée en téléphone vintage. Les visiteurs décrochent le combiné → intro audio → enregistrement du message → raccrochage. Projet en production, fonctionne bien.

Voir `.claude/memory/` pour le détail complet (architecture, matériel, workflow).

---

## Infos essentielles

- **Langage** : Rust (edition 2021)
- **GPIO 17** : LED (HIGH = attente, LOW = lecture intro)
- **GPIO 27** : crochet téléphone (HIGH = raccroché, LOW = décroché)
- **Enregistrements** : `~/recordings/YYYYMMDD_HHMMSS.wav`
- **Intro audio** : `~/livre-dor/intro.wav`
- **Service** : `livre-dor.service` (systemd, restart=always)
- **Pi** : IP et user définis dans `book.sh` (`REMOTE_HOST`, `REMOTE_USER`)

## Déploiement

```bash
./book.sh deploy   # rsync + cargo build --release sur Pi + restart
./book.sh logs     # journalctl -f
./book.sh status   # état du service
```

## Machine à états

```
Idle → PlayingIntro → Recording → Idle
```

Si raccroché pendant l'intro : retour Idle sans enregistrer.

---

## Règles de collaboration

**Code**
- Zéro commentaire. Les noms de fonctions et variables doivent se documenter eux-mêmes.
- Clean code : si un nom a besoin d'un commentaire, le nom est mauvais.

**Dépendances**
- Toute nouvelle crate nécessite une comparaison de plusieurs options (avantages/inconvénients).
- C'est le mainteneur qui choisit. Ne jamais modifier `Cargo.toml` sans validation explicite.

**Droits**
- Autorisé : modifier les sources, `cargo build` en local.
- Interdit : déployer sur le Pi (`./book.sh deploy`, rsync, restart service).
- SSH Pi : lecture seule, uniquement si explicitement autorisé pour un diagnostic.

**Frontend (React TypeScript)**
- Paradigme fonctionnel exclusivement — pas de classes.
- Pattern API en trois fichiers dans `frontend/src/api/` :
  - `<resource>.type.ts` — types TypeScript des requêtes/réponses
  - `<resource>.api.ts` — factory functions pour les appels fetch (pas de side effects)
  - `<resource>.service.ts` — hooks React utilisant les fonctions api
- Toute nouvelle lib npm nécessite une comparaison d'options avant ajout au `package.json`.

**Communication**
- Bref, technique, direct. Pas de formules de politesse ni de récapitulatifs inutiles.
- Critiquer si nécessaire.
