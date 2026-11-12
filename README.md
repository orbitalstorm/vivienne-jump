# VIVIENNE : L'Odyssée Blossom (`v1.1.0`) — Ascension Naturelle & Minimaliste en Mode Portrait

**VIVIENNE : L'Odyssée Blossom (`v1.1.0` — `cloud.orbital8.vivienne_jump`)** est un jeu Android d'ascension verticale (*Doodle Jump clone*) développé en Flutter, mettant en scène l'asset 3D Blender officiel **[`models/vivienne_speedy_v03.blend`](https://github.com/orbitalstorm/BLENDER_LAB/blob/main/models/vivienne_speedy_v03.blend)** au cœur d'un **paysage naturel en parallaxe** avec une **interface mobile minimaliste** et un **parcours déterministe par Seed**.

## 📦 Téléchargement APK Android (`v1.1.0`)

- **Release GitHub `v1.1.0`** : [`https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.1.0`](https://github.com/orbitalstorm/vivienne-jump/releases/tag/v1.1.0)
- **Téléchargement direct APK (`vivienne-jump-v1.1.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.1.0/vivienne-jump-v1.1.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.1.0/vivienne-jump-v1.1.0.apk)
- **Lien alternatif (`vivijump-v1.1.0.apk`)** : [`https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.1.0/vivijump-v1.1.0.apk`](https://github.com/orbitalstorm/vivienne-jump/releases/download/v1.1.0/vivijump-v1.1.0.apk)

---

## ✨ Nouveautés `v1.1.0` (`ORB-49`)

1. **Interface Mobile Minimaliste & Épurée** :
   - Canevas de jeu 100 % plein écran sans barres opaques intrusives.
   - HUD flottant en pilules translucides (*glassmorphic pills*) affichant l'altitude, le score, le badge de **Seed déterministe (`SEED #...`)**, l'inclinomètre fin (`CALIBRER 0°`) et un dock de navigation flottant épuré.
2. **Challenge Repensé & Génération Procédurale par Seed** :
   - **100 % déterministe par Seed** : un générateur `_levelRng` dédié garantit qu'un même seed produit exactement la même séquence de plateformes à chaque partie (`20261112`, `777`, `42`, `1854`, `90210`).
   - **Densité réduite & précision accrue** : espacement vertical accru et plateformes affinées pour imposer une vraie maîtrise de l'inclinaison du téléphone afin de ne pas tomber.
   - **Maximum 3 plateformes à portée de saut** : invariant physique strict vérifié sur chaque palier (`1 <= getPlatformsInJumpReach(p).length <= 3`).
   - **Atteignabilité garantie à 100 %** : chaque plateforme suivante est mathématiquement atteignable depuis la précédente (avec un saut normal, ou avec le saut bonus/ressort lorsqu'il y en a un).
3. **Paysage Thème Naturel avec Effet de Parallaxe (6 Plans)** :
   - **Soleil radieux (`Soleil`)** avec rayons crépusculaires et halos lumineux (`parallaxe 0.04`).
   - **Nuages volumétriques (`Nuages`)** sur 3 plans de profondeur et oiseaux en vol (`parallaxe 0.12 / 0.25 / 0.38`).
   - **Montagnes alpines & brume de vallée (`parallaxe 0.16`)**, **collines verdoyantes boisées (`parallaxe 0.30`)** et **arbres détaillés au premier plan (`Arbres` : pins étagés, chênes et cerisiers en fleurs Blossom, `parallaxe 0.44 / 0.48`)**.

## 🛠️ Développement & Compilation

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
