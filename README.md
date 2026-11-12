# VIVIENNE : L'Odyssée Blossom (`v1.3.0`) — UI Cartoon Pop (Angry Birds / Candy Crush), Physique de Particules par Plateforme & Leaderboard par Seed

**VIVIENNE : L'Odyssée Blossom (`v1.3.0` — `cloud.orbital8.vivienne_jump`)** est un jeu Android d'ascension verticale (*Doodle Jump clone*) développé en Flutter, mettant en scène l'asset 3D Blender officiel **[`models/vivienne_speedy_v03.blend`](https://github.com/orbitalstorm/BLENDER_LAB/blob/main/models/vivienne_speedy_v03.blend)** au cœur d'un **paysage naturel en parallaxe**, avec une **interface Cartoon Pop ultra-juteuse façon *Angry Birds / Candy Crush***, **5 physiques de particules de rebond dédiées par type de plateforme**, la **disparition immédiate des plateformes sortant par le bas de l'écran** et un **Tableau des Scores par Seed**.

## 📦 Téléchargement APK Android (`v1.3.0`)

- **Release GitHub `v1.3.0`** : [`https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.3.0`](https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.3.0)
- **Téléchargement direct APK (`vivienne-jump-v1.3.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.3.0/vivienne-jump-v1.3.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.3.0/vivienne-jump-v1.3.0.apk)
- **Lien alternatif (`vivijump-v1.3.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.3.0/vivijump-v1.3.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.3.0/vivijump-v1.3.0.apk)

---

## ✨ Nouveautés `v1.3.0` (`ORB-54` / `ORB-56` / `ORB-57`)

1. **Gameplay — Disparition Immédiate des Plateformes Sortant par le Bas de l'Écran** :
   - Dès qu'une plateforme franchit le bas de l'écran (`plat.y >= cameraY + worldHeight`), elle disparaît immédiatement (`isPlatformBelowScreen`) et il est strictement impossible de rebondir dessus.
2. **UI Épurée (Descriptions de Plateformes Masquées) & 5 Physiques de Particules de Rebond Dédiées** :
   - Suppression des descriptions textuelles des plateformes sur le Canvas, dans le HUD et dans les menus.
   - Chaque rebond déclenche un effet de particules léger (`8..12` particules) doté d'une physique propre au type de plateforme :
     - **Malle Monogram Ébène (`brassSpark`)** : étincelles losanges or/laiton à gravité parabolique franche (`gravityScale: 1.25`).
     - **Malle Ressort Or 24K (`springUpdraftStar`)** : colonne ascendante d'étoiles 24K à gravité inversée (`gravityScale: -0.35`).
     - **Nuage Damier Amorti (`cloudCushionPuff`)** : bouffées vaporeuses bleu/blanc s'écrasant latéralement avec fort amortissement visqueux (`drag: 5.2`).
     - **Pétale de Soie Éphémère (`silkPetalFlutter`)** : pétales de soie flottant en feuille morte avec oscillation sinusoïdale (`swirlAmplitude: 62.0`).
     - **Lanière Vachetta Mobile (`kineticStrapTrail`)** : sillage cinétique fuselé couplé à l'inertie du rail (`-plat.vx * 1.35`).
3. **Refonte Radicale du Menu en Style Cartoon (*Angry Birds / Candy Crush*)** :
   - Emblèmes vectoriels Cartoon haute précision (`assets/cartoon/*.svg` & `CartoonEmblemBadge` : Trophée Or, Couronne Royale, Étoile Blossom, Cube 3D, Triangle Play).
   - Gros boutons 3D glossy à contours épais `#2B1105`, modales rebondissantes `CartoonBouncyModal` (`Curves.elasticOut`), accès rapide aux sous-menus (`ÉDITIONS`, `PLATEFORMES/HERBIER`, `STUDIO 3D`, `SCORES`) et classement par Seed étoilé.

## 🛠️ Développement & Compilation

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
