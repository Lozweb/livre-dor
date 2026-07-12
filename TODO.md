# TODO — Livre d'or

## Assets à préparer (avant tout dev)

- [ ] 10 fichiers de musique d'intro (max 10s chacun, WAV)
- [ ] 1 fichier bip sonore type répondeur (WAV)
- [ ] 1 fichier tonalité de téléphone (WAV)

---

## Nouveau workflow audio (à implémenter)

Remplace le workflow actuel (intro.wav seul) :

1. Décroché → jouer **tonalité**
2. Jouer **message vocal d'intro** + **musique d'intro** en simultané
3. Fin → jouer **bip**
4. Enregistrement démarre

---

## Mode configuration

### Concept

- Accessible depuis l'interface web uniquement si `state = idle`
- Bouton "Entrer en mode configuration"
- En mode config : LED verte **clignote** (au lieu de fixe)
- Quitter le mode config remet le téléphone en attente normale

### Enregistrement du message vocal d'intro (depuis le téléphone physique)

1. Utilisateur clique "Enregistrer le message" dans l'interface
2. Décrocher le combiné → tonalité → bip → enregistrement démarre
3. Durée max 10s — fin automatique à l'expiration (pas besoin de raccrocher)
4. Message sauvegardé en attente de validation

### Sélection de la musique d'intro

- Liste des 10 musiques disponibles dans l'interface
- Bouton écouter pour preview avant de choisir
- Sélection persistée jusqu'à validation

### Preview du message complet

- Bouton "Écouter l'intro complète"
- Joue : tonalité + message vocal + musique sélectionnée (simultané) + bip

### Validation

- Bouton "Valider et activer"
- La nouvelle config (message + musique) devient active
- Retour au mode normal

---

## Backend à implémenter

- [ ] `GET  /api/intros` — liste des musiques disponibles
- [ ] `GET  /api/intros/:name` — stream d'une musique (preview)
- [ ] `POST /api/config/enter` — passer en mode configuration (si idle)
- [ ] `POST /api/config/exit` — quitter le mode configuration
- [ ] `POST /api/config/record` — déclencher l'enregistrement du message (combiné)
- [ ] `GET  /api/config/message` — stream du message enregistré
- [ ] `POST /api/config/validate` — valider et activer la config (message + musique)

## Frontend à implémenter

- [ ] Bouton "Mode configuration" (visible si state = idle)
- [ ] Page / panneau configuration :
  - Liste des musiques avec bouton preview
  - Sélection musique active
  - Bouton "Enregistrer le message"
  - Lecteur du message enregistré
  - Bouton "Écouter l'intro complète"
  - Bouton "Valider et activer"
  - Bouton "Annuler / quitter"

## Phone (Rust) à implémenter

- [ ] Nouveau `PhoneState::Config` — LED clignote
- [ ] Lecture simultanée de deux fichiers audio (message + musique)
- [ ] Workflow enregistrement message config (tonalité → bip → 10s max → auto-stop)
- [ ] Lecture du workflow complet en preview (tonalité + message + musique + bip)
