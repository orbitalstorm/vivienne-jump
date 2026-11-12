# VIVIENNE : L'Odyssée Blossom (`v1.0.0`) — Ascension Haute Couture en Mode Portrait

**VIVIENNE : L'Odyssée Blossom (`v1.0.0` — `cloud.orbital8.vivienne_jump`)** est un jeu Android d'ascension verticale (*Doodle Jump clone*) développé en Flutter, mettant en scène l'asset 3D Blender officiel **[`models/vivienne_speedy_v03.blend`](https://github.com/orbitalstorm/BLENDER_LAB/blob/main/models/vivienne_speedy_v03.blend)** dans l'univers **Louis Vuitton & Blossom Flowers**.

## 📦 Téléchargement APK Android (`v1.0.0`)

- **Release GitHub `v1.0.0`** : [`https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.0.0`](https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.0.0)
- **Téléchargement direct APK (`vivienne-jump-v1.0.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.0.0/vivienne-jump-v1.0.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.0.0/vivienne-jump-v1.0.0.apk)
- **Lien alternatif (`vivijump-v1.0.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.0.0/vivijump-v1.0.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.0.0/vivijump-v1.0.0.apk)

---

## ✨ Fonctionnalités & Habillage Louis Vuitton

1. **Intégration 3D Blender (`models/vivienne_speedy_v03.blend`)** :
   - Sprites Cycles 3D haute définition détourés sans perte à partir des rendus studio de `vivienne_speedy_v03.blend` (Frames `04`, `06`, `12`, `21`, `60` + Overlay Rig 22 Os `Vivienne_Rig`).
   - Cinématique Hermite périodique exacte (`72 frames @ 24 FPS` — 3 sauts consécutifs) avec **Squash & Stretch à volume constant (`sx * sy * sz = 1.0`)**, élévation des bras en V de célébration et oscillation pendulaire du mini sac Speedy LV.
2. **Contrôle par Inclinaison du Téléphone (Mode Portrait Uniquement)** :
   - Pont capteur matériel Android natif (`Sensor.TYPE_ACCELEROMETER` via `EventChannel('cloud.orbital8.vivienne_jump/tilt')` à 60 Hz `SENSOR_DELAY_GAME`).
   - Inclinomètre en temps réel intégré au HUD avec bouton **`CALIBRER 0°`**, traversée horizontale des bords d'écran (*screen wrap-around* Doodle Jump) et assistance tactile.
3. **Collectibles Blossom Flowers & Objets Maison Louis Vuitton** :
   - **Fleur Star Blossom Or 24K** (`lv_neo_star_blossom.blend`), **Fleur Sun Blossom Corolle**, **Fleur Neo Blossom Nacre & Diamant**.
   - **Mini Sac Speedy Monogram (Ascension Supersonique)**, **Cadenas & Clé LV Or 24K (Bouclier Protecteur 10s)**, **Aimant Fleur de Monogramme (Attraction 360°)** et bouton actif **`ÉCLAT BLOSSOM`** (*Grand Saut Célébration Frame 60*).
4. **5 Types de Plateformes & 4 Paliers d'Altitude Verticaux** :
   - *Malle Monogram Ébène*, *Lanière Cuir Vachetta Mobile* (tranche rouge carmin `#8B1E24` & surpiqûre jaune `#E5B842`), *Pétale de Soie Éphémère*, *Malle à Serrure Ressort Or 24K* (`×1.75`) et *Nuage Damier Céleste*.
   - *Atelier d'Asnières (0 m+)*, *Place Vendôme (1 500 m+)*, *Jardin Céleste Blossom (3 500 m+)* et *Stratosphère Studio Cycles (6 000 m+)*.

## 🛠️ Développement & Compilation

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
