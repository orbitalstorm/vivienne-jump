# Changelog — VIVIENNE : L'Odyssée Blossom

## `v1.1.0` (2026-11-12) — Refonte Minimaliste, Challenge Déterministe par Seed & Paysage Naturel en Parallaxe (`ORB-49`)

- **Interface Mobile Minimaliste, Épurée & Plein Écran** :
  - Suppression des bandeaux opaques supérieur/inférieur et du bandeau technique de debug en plein jeu au profit d'un canevas plein écran (`Positioned.fill`) et de pilules flottantes translucides (*glassmorphic pills*).
  - Affichage épuré de l'altitude, du score, du compteur de fleurs Blossom, du **Seed actif (`SEED #...`)** cliquable à la volée, d'un inclinomètre fin (`CALIBRER 0°`) et d'un dock de navigation flottant minimaliste.
- **Refonte du Challenge & Génération Procédurale 100 % Déterministe par Seed** :
  - Séparation stricte du générateur pseudo-aléatoire de niveau (`_levelRng`, piloté exclusivement par `seed`) et du générateur d'effets visuels (`_fxRng`) : un même `seed` génère exactement la même séquence de plateformes au millimètre près.
  - Réduction de la densité de plateformes (suppression des plateformes latérales de départ et des doublons, espacement vertical accru `124..168 px` en saut normal et `192..232 px` sur plateforme ressort/bonus, largeur affinée `66..82 px`) pour exiger une vraie précision d'inclinaison et d'anticipation.
  - Garantie mathématique vérifiée par tests unitaires :
    1. **Au maximum 3 plateformes à portée de saut** (`1 <= getPlatformsInJumpReach(p).length <= 3`) depuis n'importe quelle plateforme et pour toutes les éditions de Vivienne.
    2. **Atteignabilité garantie à 100 %** (`canReachPlatform(p_i, p_{i+1}) == true`) de la plateforme suivante avec un saut normal ou avec le saut bonus/ressort lorsqu'il y en a un, y compris dans le pire déphasage des plateformes mobiles.
- **Paysage Thème Naturel Multi-Plans avec Effet de Parallaxe** :
  - Remplacement de l'ancien fond sombre Monogram par un **paysage naturel vivant à 6 couches de parallaxe** horizontale (inclinaison/déplacement) et verticale (ascension) :
    1. *Dôme céleste & dégradé atmosphérique évolutif* (Clairière Azur, Soleil d'Or, Vallée Sakura, Nuit Alpine).
    2. *Soleil radieux (`Soleil`)* avec halos atmosphériques et rayons crépusculaires tournants (`parallaxe 0.04`).
    3. *Nuages volumétriques sur 3 plans de profondeur (`Nuages`)* et vol d'oiseaux au loin (`parallaxe 0.12 / 0.25 / 0.38`).
    4. *Chaîne de montagnes alpines aux versants éclairés et brume de vallée (`parallaxe 0.16`)*.
    5. *Collines verdoyantes et lisière de forêt (cyprès, pins et chênes) à mi-distance (`parallaxe 0.30`)*.
    6. *Arbres détaillés au premier plan (pins étagés, chênes et cerisiers en fleurs Blossom) et terrasses arborées ascendantes (`parallaxe 0.44 / 0.48`)*.

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
