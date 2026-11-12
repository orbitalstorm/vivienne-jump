# VIVIENNE : L'Odyssée Blossom (`v1.2.0`) — UI Mobile Store Pro, 5 Plateformes Différenciées & Leaderboard par Seed

**VIVIENNE : L'Odyssée Blossom (`v1.2.0` — `cloud.orbital8.vivienne_jump`)** est un jeu Android d'ascension verticale (*Doodle Jump clone*) développé en Flutter, mettant en scène l'asset 3D Blender officiel **[`models/vivienne_speedy_v03.blend`](https://github.com/orbitalstorm/BLENDER_LAB/blob/main/models/vivienne_speedy_v03.blend)** au cœur d'un **paysage naturel en parallaxe**, avec une **interface Mobile Store Pro ("Game Juice")**, **5 types de plateformes aux effets physiques francs** et un **Tableau des Scores par Seed** permettant de rejouer n'importe quel Seed pour battre son Highscore.

## 📦 Téléchargement APK Android (`v1.2.0`)

- **Release GitHub `v1.2.0`** : [`https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.2.0`](https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.2.0)
- **Téléchargement direct APK (`vivienne-jump-v1.2.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.2.0/vivienne-jump-v1.2.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.2.0/vivienne-jump-v1.2.0.apk)
- **Lien alternatif (`vivijump-v1.2.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.2.0/vivijump-v1.2.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.2.0/vivijump-v1.2.0.apk)

---

## ✨ Nouveautés `v1.2.0` (`ORB-52` / `ORB-53`)

1. **5 Types de Plateformes aux Effets Physiques & Visuels Francs (< 100 ms)** :
   - **Malle Monogram Ébène (`STABLE ×1.0`)** : Appui de référence franc (`~205 px`) avec zone cible centrale dorée de *Rebond Parfait* (`±24 %`).
   - **Malle Ressort Or 24K (`SUPER ×1.45` — Saut Plus Haut)** : Propulse Vivienne **>2.1× plus haut** (`~432 px`) avec double ressort hélicoïdal doré, chevrons `▲▲`, pose *Grand Saut (Frame 60)* et bonus `+100 × combo` pts.
   - **Nuage Damier Amorti (`AMORTI ×0.85` — Saut Moins Haut & Éclat +12 %)** : Absorbe l'impact et réduit la hauteur du saut (`~148 px`), imposant un saut court et nerveux vers le palier suivant (garanti atteignable à `98..116 px`) tout en rechargeant **+12 % de la jauge Éclat Blossom**.
   - **Pétale de Soie Blossom Éphémère (`1× REBOND` — Disparaît après 1 rebond)** : Offre une impulsion vive (`×1.06`) mais **se brise et disparaît en 14 pétales de soie tourbillonnants dès le 1er rebond** (`singleUse: true`).
   - **Lanière Cuir Vachetta Mobile (`MOBILE ×1.14` — Rail Mobile)** : Patrouille horizontale sur rail pointillé lumineux avec flèches directionnelles, rebond tonique (`×1.14`, `~267 px`) et bonus `+45 × combo` pts.
2. **Tableau des Scores par Seed & Rejouabilité Ciblée (« REJOUER CE SEED »)** :
   - Présent sur le **Menu d'Accueil Store (avant de lancer une partie)** et sur l'**Écran Game Over (après une partie)**.
   - Indique le **Rang (`#1`, `#2`, `#3`...)**, le **Score (`pts`)**, l'**Altitude (`m`)**, le **Seed (`SEED #...`)** et le **Highscore du Seed**, avec un bouton 3D direct **« REJOUER CE SEED »** pour relancer ce parcours exact et battre son record.
   - Ligne horizontale dorée **`RECORD SEED #...`** peinte directement dans l'arène à l'altitude du record à battre.
3. **Refonte UI Mobile Store Pro & "Game Juice" (`mobile-game-ui` Mode B)** :
   - Boutons tactiles 3D `Juicy3DGameButton` (*Squash & Stretch* `0.93`, lèvre 3D réactive, retours haptiques natifs `HapticFeedback`, cibles `>= 48×48dp` en *Thumb Zone*), compteurs interpolés `InterpolatedHudTicker` isolés par `RepaintBoundary`.

## 🛠️ Développement & Compilation

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
