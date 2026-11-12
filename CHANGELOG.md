# Changelog — VIVIENNE : L'Odyssée Blossom

## `v1.0.0` (2026-11-12)

- **Jeu d'ascension verticale Android (Doodle Jump clone) en mode Portrait strict (`portraitUp`)** :
  - Acquisition 60 Hz de l'accéléromètre Android (`Sensor.TYPE_ACCELEROMETER`) via `EventChannel('cloud.orbital8.vivienne_jump/tilt')` dans `MainActivity.kt` avec calibration `0°` en direct et traversée latérale continue (*wrap-around*).
- **Intégration de l'asset Blender `models/vivienne_speedy_v03.blend`** :
  - Extraction alpha haute précision des 6 poses Cycles (`Frame 04 Squash`, `Frame 06 Stretch`, `Frame 12 Apex`, `Frame 21 Landing`, `Frame 60 Grand Jump 3 Célébration`, `Rig 22 Os Vivienne_Rig`).
  - Portage mathématique de la spline cubique d'Hermite périodique (`72 frames @ 24 FPS`) avec conservation du volume (`sx * sy * sz = 1.0`).
  - Inspecteur interactif **Atelier Blender 3D** intégré à l'application (scrubber 72 frames, bascule Rig 22 Os et nomenclature des 5 matériaux PBR).
- **Univers Louis Vuitton & Collectibles Blossom Flowers** :
  - 6 items à collecter : *Fleur Star Blossom Or 24K*, *Fleur Sun Blossom Corolle*, *Fleur Neo Blossom Nacre & Diamant*, *Mini Sac Speedy Propulsion*, *Cadenas LV Or 24K*, *Aimant Fleur de Monogramme*.
  - 5 architectures de plateformes (*Malle Monogram Ébène*, *Lanière Cuir Vachetta Mobile*, *Pétale de Soie Éphémère*, *Malle à Serrure Ressort Or*, *Nuage Damier Céleste*).
  - 4 Éditions de Vivienne jouables et 4 paliers d'altitude verticaux.
- **Habillage Complet, Naming & Icônes Android** :
  - Naming officiel : **VIVIENNE : L'Odyssée Blossom** (`Vivienne Jump` / `cloud.orbital8.vivienne_jump`).
  - Génération des icônes Android `ic_launcher.png` (`mdpi` à `xxxhdpi`) et `app_icon_512.png` à partir du rendu 3D Cycles de Vivienne Speedy v03.
