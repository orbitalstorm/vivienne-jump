# Changelog — VIVIENNE : L'Odyssée Blossom

## `v1.2.0` (2026-11-12) — Refonte UI Mobile Store Pro, 5 Plateformes à Effets Physiques Francs & Tableau des Scores par Seed (`ORB-52`, `ORB-53`)

- **Analyse Game Design & 5 Archétypes de Plateformes à Effets Clairs (< 100 ms)** :
  1. **Malle Monogram Ébène (`STABLE ×1.0` — Appui de Référence)** : Rebond franc (`~205 px`) avec mise en évidence dorée de la zone cible centrale de *Rebond Parfait* (`±24 %`).
  2. **Malle à Serrure Ressort Or 24K (`SUPER ×1.45` — Saut Plus Haut)** : Propulse Vivienne **>2.1× plus haut** (`~432 px`) avec double ressort hélicoïdal doré animé, chevrons ascendants `▲▲`, pose *Grand Saut (Frame 60)*, callout `SUPER RESSORT ×1.45 !` et bonus `+100 × combo` pts.
  3. **Nuage Damier Amorti (`AMORTI ×0.85` — Saut Moins Haut & Éclat +12 %)** : Nuage bleu glacier/nacre qui absorbe l'impact et réduit la hauteur du saut (`~148 px`), imposant un saut court et nerveux (écart suivant garanti atteignable à `98..116 px`) tout en rechargeant **+12 % de la jauge Éclat Blossom**.
  4. **Pétale de Soie Blossom Éphémère (`1× REBOND` — Disparaît après 1 rebond)** : Pétale ivoire/carmin fissuré d'or (*Kintsugi*) qui offre une impulsion vive (`×1.06`) puis **éclate en 14 pétales de soie tourbillonnants dès le 1er rebond** (`singleUse: true`).
  5. **Lanière Cuir Vachetta Mobile (`MOBILE ×1.14` — Rail Mobile)** : Patrouille horizontale sur rail pointillé avec flèches directionnelles, rebond tonique (`×1.14`, `~267 px`) et bonus `+45 × combo` pts.
  - **Mécanique de *Rebond Parfait au Centre* (`PARFAIT ×N !`)** : Atterrir à `±24 %` du centre prolonge le combo, octroie `+35 × streak` pts et recharge `+8 %` de jauge Blossom.
- **Tableau des Scores par Seed (`SeedScoreEntry`) & Rejouabilité Ciblée** :
  - Intégration du **Tableau des Scores par Seed (`TABLEAU DES SCORES PAR SEED — HIGHSCORES`)** sur le **Menu d'Accueil Store (avant de lancer une partie)** et sur l'**Écran Game Over (après une partie)**.
  - Affichage du Rang (`#1`, `#2`, `#3`...), du **Score (`pts`)**, de l'**Altitude (`m`)**, du **Seed (`SEED #...`)** et du **Highscore du Seed**.
  - Bouton tactile 3D direct **« REJOUER CE SEED »** sur chaque ligne du classement (`replaySeed(seed)`) ainsi qu'une ligne horizontale dorée `RECORD SEED #...` peinte directement dans l'arène à l'altitude du record à battre.
- **Refonte UI Mobile Store Pro & "Game Juice" (`mobile-game-ui` Mode B Flutter)** :
  - Composants tactiles `Juicy3DGameButton` (*Squash & Stretch* `0.93` en `75 ms`, lèvre 3D inférieure dynamique, cibles `>= 48×48dp` en *Thumb Zone*), compteurs interpolés `InterpolatedHudTicker` isolés par `RepaintBoundary` et retours haptiques natifs (`HapticFeedback`).

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
