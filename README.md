# VIVIENNE : L'Odyssée Blossom (`v1.4.0`) — Menu d'Accueil Cartoon, Bouton Highscores & Galerie Vivienne Turntable 360° Gyroscopique

**VIVIENNE : L'Odyssée Blossom (`v1.4.0` — `cloud.orbital8.vivienne_jump`)** est un jeu Android d'ascension verticale (*Doodle Jump clone*) développé en Flutter, mettant en scène le modèle 3D de Vivienne au cœur d'un **paysage naturel en parallaxe**, avec un **Menu d'Accueil Cartoon** (sans arriver directement sur le tableau des Highscores), un **bouton et une modale dédiés au Tableau Highscores**, et une **Galerie Vivienne en Turntable 360°** pilotée par l'inclinaison du téléphone.

## 📦 Téléchargement APK Android (`v1.4.0`)

- **Release GitHub `v1.4.0`** : [`https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.4.0`](https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.4.0)
- **Téléchargement direct APK (`vivienne-jump-v1.4.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.4.0/vivienne-jump-v1.4.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.4.0/vivienne-jump-v1.4.0.apk)
- **Lien alternatif (`vivijump-v1.4.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.4.0/vivijump-v1.4.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.4.0/vivijump-v1.4.0.apk)

---

## ✨ Nouveautés `v1.4.0` (`ORB-58` / `ORB-61` / `ORB-62`)

1. **Menu d'Accueil Cartoon Épuré (Sans Tableau Highscores Direct)** :
   - Au lancement du jeu, l'écran d'accueil affiche un vrai **Menu d'Accueil Cartoon** (*Angry Birds / Candy Crush*) mettant en valeur la scène héroïque de Vivienne, le gros bouton 3D vert lime **`JOUER SUR SEED #...`**, les boutons d'accès aux catégories (`ÉDITIONS`, `HERBIER`, `GALERIE VIVIENNE`) et le sélecteur de Seed, sans afficher directement le tableau des Highscores.
2. **Tableau Highscores Accessible via un Bouton Dédié (`TABLEAU DES HIGHSCORES` / `HIGHSCORES`)** :
   - Le **`TABLEAU DES SCORES PAR SEED (HIGHSCORES)`** s'ouvre à la demande dans une modale rebondissante dédiée (`Key('highscores_modal_overlay')`) via le bouton **`TABLEAU DES HIGHSCORES`** du menu d'accueil ou le bouton **`HIGHSCORES`** du HUD supérieur.
3. **Galerie Vivienne en Turntable 360° Pilotée par l'Inclinaison du Téléphone** :
   - Suppression complète de la catégorie technique Blender MCP (`BLENDER 3D` / `STUDIO 3D`) au profit de la **`GALERIE VIVIENNE — TURNTABLE 360°`**.
   - Permet de faire tourner le modèle 3D de Vivienne à **360° (24 angles Cycles détourés de `0°` à `345°`)** en temps réel en inclinant le téléphone à gauche ou à droite (accéléromètre 60 Hz), au glisser tactile ou via les boutons d'angles rapides (`FACE 0°`, `DOS 180°`, `TOURNER G.`, `TOURNER D.`).

## 🛠️ Développement & Compilation

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
