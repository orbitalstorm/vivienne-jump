import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The 4 Haute Couture playable editions of Vivienne in the Louis Vuitton universe.
enum VivienneEdition {
  speedyMonogramV03(
    id: 'speedy_v03',
    name: 'Vivienne Speedy v03',
    subtitle: 'Édition Atelier • Chêne, Vachetta & Mini Speedy',
    description:
        'La figurine officielle issue de models/vivienne_speedy_v03.blend : tête en bois de chêne clair, corolle à 4 pétales en cuir Vachetta à tranches rouge carmin, œil fleur Monogram et mini sac Speedy suspendu.',
    perkLabel: 'Durée Ascension Speedy +25 % & Impulsion Ressort +4 %',
    primaryColor: Color(0xFFE3A17B),
    accentColor: Color(0xFFFFD700),
    edgeColor: Color(0xFF8B1E24),
    speedyBoostMultiplier: 1.25,
    magnetRadiusBonus: 0.0,
    scoreMultiplier: 1.0,
    jumpImpulseMultiplier: 1.02,
  ),
  neoBlossomRose(
    id: 'neo_blossom',
    name: 'Vivienne Neo Blossom',
    subtitle: 'Édition Joaillerie • Rose Poudré & Nacre',
    description:
        'Inspirée de vivienne_lv_neo_blossom.blend : corolle nacrée rose poudré et aura magnétique attirant naturellement les fleurs Blossom en plein vol.',
    perkLabel: 'Rayon de collecte Blossom +45 % & Jauge Éclat +20 %',
    primaryColor: Color(0xFFF3B7C3),
    accentColor: Color(0xFFFFE082),
    edgeColor: Color(0xFFA8243C),
    speedyBoostMultiplier: 1.0,
    magnetRadiusBonus: 42.0,
    scoreMultiplier: 1.10,
    jumpImpulseMultiplier: 1.01,
  ),
  malleImperialeOr(
    id: 'imperiale_or',
    name: 'Vivienne Malle Impériale',
    subtitle: 'Édition Place Vendôme • Or 24 Carats',
    description:
        'Habillage haute joaillerie doré 24K aux reflets studio AgX : chaque fleur Star Blossom et Sun Blossom récoltée octroie un bonus de prestige.',
    perkLabel: 'Score Fleurs Blossom ×1.35 & Bouclier Cadenas initial',
    primaryColor: Color(0xFFFFD700),
    accentColor: Color(0xFFFFF3B0),
    edgeColor: Color(0xFF9E6B14),
    speedyBoostMultiplier: 1.10,
    magnetRadiusBonus: 18.0,
    scoreMultiplier: 1.35,
    jumpImpulseMultiplier: 1.02,
  ),
  nuitAsnieres(
    id: 'nuit_asnieres',
    name: 'Vivienne Nuit d\'Asnières',
    subtitle: 'Édition Céleste • Ébène & Constellation Or',
    description:
        'Toile Monogram nuit profonde et surpiqûres sellier lumineuses : maîtrise aérodynamique supérieure lors des fortes inclinaisons du téléphone.',
    perkLabel: 'Impulsion de saut +6 % & Réactivité Inclinaison +20 %',
    primaryColor: Color(0xFFC89D7C),
    accentColor: Color(0xFF80D8FF),
    edgeColor: Color(0xFF6A1B9A),
    speedyBoostMultiplier: 1.15,
    magnetRadiusBonus: 24.0,
    scoreMultiplier: 1.15,
    jumpImpulseMultiplier: 1.06,
  );

  const VivienneEdition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.perkLabel,
    required this.primaryColor,
    required this.accentColor,
    required this.edgeColor,
    required this.speedyBoostMultiplier,
    required this.magnetRadiusBonus,
    required this.scoreMultiplier,
    required this.jumpImpulseMultiplier,
  });

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String perkLabel;
  final Color primaryColor;
  final Color accentColor;
  final Color edgeColor;
  final double speedyBoostMultiplier;
  final double magnetRadiusBonus;
  final double scoreMultiplier;
  final double jumpImpulseMultiplier;
}

/// Vertical altitude realms with natural sky, sun, cloud, mountain, hill, and tree palettes.
enum LvBiome {
  atelierAsnieres(
    name: 'Atelier d\'Asnières — Clairière Ensoleillée',
    subtitle: '0 m – 1 500 m • Ciel Azur, Soleil, Nuages & Forêt Verdoyante',
    minAltitudeMeters: 0,
    topColor: Color(0xFF3A94D8),
    midSkyColor: Color(0xFF8BD0F6),
    bottomColor: Color(0xFFFDF3D7),
    horizonGlowColor: Color(0xFFFFE082),
    accentColor: Color(0xFFFFD54F),
    sunColor: Color(0xFFFFF9C4),
    mountainColor: Color(0xFF6D9AB9),
    hillColor: Color(0xFF4C8E58),
    treeCanopyColor: Color(0xFF2D6A3E),
    treeHighlightColor: Color(0xFF72B856),
  ),
  placeVendome(
    name: 'Place Vendôme — Soleil d\'Or',
    subtitle: '1 500 m – 3 500 m • Vallée Dorée, Soleil Couchant & Cyprès',
    minAltitudeMeters: 1500,
    topColor: Color(0xFF395B9E),
    midSkyColor: Color(0xFFE68A66),
    bottomColor: Color(0xFFFFE39F),
    horizonGlowColor: Color(0xFFFFB74D),
    accentColor: Color(0xFFFFD700),
    sunColor: Color(0xFFFFE082),
    mountainColor: Color(0xFF73628A),
    hillColor: Color(0xFF5D7242),
    treeCanopyColor: Color(0xFF354B29),
    treeHighlightColor: Color(0xFFDCA642),
  ),
  jardinBlossom(
    name: 'Jardin Céleste Blossom — Vallée Sakura',
    subtitle: '3 500 m – 6 000 m • Brume Rosée, Cerisiers en Fleurs & Cimes',
    minAltitudeMeters: 3500,
    topColor: Color(0xFF46528E),
    midSkyColor: Color(0xFFC785AE),
    bottomColor: Color(0xFFFCE2E6),
    horizonGlowColor: Color(0xFFF48FB1),
    accentColor: Color(0xFFFFC1E3),
    sunColor: Color(0xFFFFF0F5),
    mountainColor: Color(0xFF6E6796),
    hillColor: Color(0xFF47695E),
    treeCanopyColor: Color(0xFF2B4840),
    treeHighlightColor: Color(0xFFF48FB1),
  ),
  stratosphereStudio(
    name: 'Stratosphère Studio Cycles — Cimes Étoilées',
    subtitle: '6 000 m+ • Nuit Alpine, Aurore Boréale & Pins Argentés',
    minAltitudeMeters: 6000,
    topColor: Color(0xFF102536),
    midSkyColor: Color(0xFF224B63),
    bottomColor: Color(0xFF70BBA9),
    horizonGlowColor: Color(0xFFFFD700),
    accentColor: Color(0xFFFFE57F),
    sunColor: Color(0xFFFFF9C4),
    mountainColor: Color(0xFF2B4B61),
    hillColor: Color(0xFF1E3F3B),
    treeCanopyColor: Color(0xFF132A28),
    treeHighlightColor: Color(0xFF64DFDF),
  );

  const LvBiome({
    required this.name,
    required this.subtitle,
    required this.minAltitudeMeters,
    required this.topColor,
    required this.midSkyColor,
    required this.bottomColor,
    required this.horizonGlowColor,
    required this.accentColor,
    required this.sunColor,
    required this.mountainColor,
    required this.hillColor,
    required this.treeCanopyColor,
    required this.treeHighlightColor,
  });

  final String name;
  final String subtitle;
  final int minAltitudeMeters;
  final Color topColor;
  final Color midSkyColor;
  final Color bottomColor;
  final Color horizonGlowColor;
  final Color accentColor;
  final Color sunColor;
  final Color mountainColor;
  final Color hillColor;
  final Color treeCanopyColor;
  final Color treeHighlightColor;

  static LvBiome forAltitude(double meters) {
    if (meters >= 6000) return LvBiome.stratosphereStudio;
    if (meters >= 3500) return LvBiome.jardinBlossom;
    if (meters >= 1500) return LvBiome.placeVendome;
    return LvBiome.atelierAsnieres;
  }
}

/// Platform types inspired by Louis Vuitton trunks, leather straps, and Blossom petals.
enum LvPlatformType {
  monogramTrunk(
    title: 'Malle Monogram Ébène',
    description: 'Malle de voyage rigide à coins et rivets en laiton doré.',
    impulseMultiplier: 1.0,
    singleUse: false,
    movesHorizontally: false,
  ),
  vachettaStrapMoving(
    title: 'Lanière Cuir Vachetta Mobile',
    description:
        'Lanière en cuir beige rosé à tranche rouge carmin (#8B1E24) et surpiqûre jaune sellier oscillant autour de son point d\'ancrage.',
    impulseMultiplier: 1.04,
    singleUse: false,
    movesHorizontally: true,
  ),
  silkBlossomFragile(
    title: 'Pétale de Soie Blossom Éphémère',
    description:
        'Plateforme délicate ivoire et rose qui s\'effeuille en pétales après un rebond.',
    impulseMultiplier: 1.0,
    singleUse: true,
    movesHorizontally: false,
  ),
  springLockGold(
    title: 'Malle à Serrure Ressort Or 24K',
    description:
        'Équipée d\'un fermoir à ressort doré propulsant Vivienne en Grand Saut (×1.42 vitesse verticale).',
    impulseMultiplier: 1.42,
    singleUse: false,
    movesHorizontally: false,
  ),
  damierCloud(
    title: 'Nuage Damier Céleste',
    description:
        'Plateforme flottante nacrée qui oscille doucement et offre un rebond aérien.',
    impulseMultiplier: 1.08,
    singleUse: false,
    movesHorizontally: true,
  );

  const LvPlatformType({
    required this.title,
    required this.description,
    required this.impulseMultiplier,
    required this.singleUse,
    required this.movesHorizontally,
  });

  final String title;
  final String description;
  final double impulseMultiplier;
  final bool singleUse;
  final bool movesHorizontally;
}

/// Collectible items in the Louis Vuitton Blossom universe.
enum BlossomItemType {
  starBlossomGold(
    title: 'Fleur Star Blossom Or 24K',
    subtitle: 'Icône Monogram Étoilée (lv_neo_star_blossom.blend)',
    description:
        'Fleur de Monogramme à 4 pétales pointus en or poli. Augmente le score et charge la jauge Éclat Blossom.',
    points: 75,
    blossomCountValue: 1,
    gaugeGain: 0.14,
    primaryColor: Color(0xFFFFD700),
    secondaryColor: Color(0xFFFFF59D),
  ),
  sunBlossomCorolla(
    title: 'Fleur Sun Blossom Corolle',
    subtitle: 'Fleur Ronde Signature à 4 Pétales',
    description:
        'Fleur ronde emblématique de la corolle de Vivienne en cuir Vachetta rosé et clou central doré.',
    points: 140,
    blossomCountValue: 2,
    gaugeGain: 0.22,
    primaryColor: Color(0xFFE3A17B),
    secondaryColor: Color(0xFFFFD700),
  ),
  neoBlossomDiamond(
    title: 'Fleur Neo Blossom Nacre & Diamant',
    subtitle: 'Haute Joaillerie Louis Vuitton',
    description:
        'Fleur précieuse de haute altitude en nacre rose et or blanc. Augmente le multiplicateur de combo.',
    points: 280,
    blossomCountValue: 3,
    gaugeGain: 0.34,
    primaryColor: Color(0xFFF8BBD0),
    secondaryColor: Color(0xFFFFFFFF),
  ),
  speedyBagBoost(
    title: 'Mini Sac Speedy Monogram (Ascension)',
    subtitle: 'Propulsion Haute Couture (vivienne_speedy_v03.blend)',
    description:
        'L\'accessoire fétiche de Vivienne ! Déclenche une ascension supersonique invulnérable en pose Grand Saut (Frame 60).',
    points: 350,
    blossomCountValue: 3,
    gaugeGain: 0.45,
    primaryColor: Color(0xFFC89D7C),
    secondaryColor: Color(0xFFFFD700),
  ),
  goldenPadlockShield(
    title: 'Cadenas & Clé LV Or 24K',
    subtitle: 'Bouclier Protecteur Maison (10 s)',
    description:
        'Entoure Vivienne d\'une sphère dorée Monogram qui repousse tous les obstacles pendant 10 secondes.',
    points: 200,
    blossomCountValue: 2,
    gaugeGain: 0.25,
    primaryColor: Color(0xFFFFD700),
    secondaryColor: Color(0xFFFFA000),
  ),
  monogramMagnet(
    title: 'Aimant Fleur de Monogramme',
    subtitle: 'Attraction Blossom 360° (8 s)',
    description:
        'Aimante automatiquement toutes les fleurs Blossom environnantes vers Vivienne pendant 8 secondes.',
    points: 180,
    blossomCountValue: 2,
    gaugeGain: 0.25,
    primaryColor: Color(0xFFE5B842),
    secondaryColor: Color(0xFF8B1E24),
  );

  const BlossomItemType({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.points,
    required this.blossomCountValue,
    required this.gaugeGain,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String title;
  final String subtitle;
  final String description;
  final int points;
  final int blossomCountValue;
  final double gaugeGain;
  final Color primaryColor;
  final Color secondaryColor;
}

/// Active platform instance in the deterministic seeded vertical world.
class LvPlatform {
  LvPlatform({
    required this.id,
    required this.stepIndex,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    double? anchorX,
    this.patrolRadius = 0.0,
    this.vx = 0.0,
    this.broken = false,
    this.bounceCompress = 0.0,
    this.hasSpringTriggered = false,
    this.hasBonusItem = false,
  }) : anchorX = anchorX ?? x;

  final int id;
  final int stepIndex;
  final double anchorX;
  final double patrolRadius;
  double x;
  double y;
  final double width;
  final double height;
  final LvPlatformType type;
  double vx;
  bool broken;
  double bounceCompress;
  bool hasSpringTriggered;
  final bool hasBonusItem;
}

/// Collectible Blossom Flower or LV Maison power-up floating above platforms.
class BlossomCollectible {
  BlossomCollectible({
    required this.id,
    required this.x,
    required this.y,
    required this.type,
    this.radius = 15.0,
    this.phase = 0.0,
    this.collected = false,
  });

  final int id;
  double x;
  double y;
  final BlossomItemType type;
  final double radius;
  double phase;
  bool collected;
}

/// Aerial obstacle in high altitudes that Vivienne dodges by tilting the phone.
class LvAtelierHazard {
  LvAtelierHazard({
    required this.id,
    required this.x,
    required this.y,
    required this.vx,
    this.radius = 22.0,
    this.phase = 0.0,
  });

  final int id;
  double x;
  double y;
  double vx;
  final double radius;
  double phase;
}

/// Visual particle (golden sparkles, Vachetta petals, Monogram stars).
class BlossomParticle {
  BlossomParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.maxLife,
    this.isPetal = false,
    this.rotation = 0.0,
  });

  double x;
  double y;
  double vx;
  double vy;
  final double size;
  final Color color;
  double life;
  final double maxLife;
  final bool isPetal;
  double rotation;
}

/// Floating score/combo callout text in the arena.
class FloatingCallout {
  FloatingCallout({
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    this.life = 1.0,
  });

  final String text;
  double x;
  double y;
  final Color color;
  double life;
}

/// Which of the 6 Cycles-rendered Blender sprites from `vivienne_speedy_v03.blend` is active.
enum VivienneBlenderPose {
  pose1Squash(
    frameNumber: 4,
    label: 'Frame 04 • Anticipation Squash (sz = 0.82)',
    assetPath: 'assets/sprites/vivienne_pose_1_squash.png',
  ),
  pose2Launch(
    frameNumber: 6,
    label: 'Frame 06 • Décollage Stretch & Bras Montants (sz = 1.16)',
    assetPath: 'assets/sprites/vivienne_pose_2_launch.png',
  ),
  pose3Apex(
    frameNumber: 12,
    label: 'Frame 12 • Apex Saut 1 Bras en V & Corolle Bloom',
    assetPath: 'assets/sprites/vivienne_pose_3_apex.png',
  ),
  pose4Landing(
    frameNumber: 21,
    label: 'Frame 21 • Réception Squash Impact & Whip Pétales',
    assetPath: 'assets/sprites/vivienne_pose_4_landing.png',
  ),
  pose5GrandApex(
    frameNumber: 60,
    label: 'Frame 60 • Grand Saut 3 Célébration (Hero Render)',
    assetPath: 'assets/sprites/vivienne_pose_5_grand_apex.png',
  ),
  pose6RigOverlay(
    frameNumber: 6,
    label: 'Frame 06 • Rig 22 Os (Vivienne_Rig) & Vecteurs Squash/Stretch',
    assetPath: 'assets/sprites/vivienne_pose_6_rig.png',
  );

  const VivienneBlenderPose({
    required this.frameNumber,
    required this.label,
    required this.assetPath,
  });

  final int frameNumber;
  final String label;
  final String assetPath;
}

/// Exact Periodic Cubic Hermite Kinematics ported from `scripts/generate_vivienne_speedy_v03.py`
/// (`models/vivienne_speedy_v03.blend`).
class VivienneBlenderKinematics {
  const VivienneBlenderKinematics({
    required this.frameFloat,
    required this.jumpIndex,
    required this.phaseU,
    required this.tzJumpMeters,
    required this.szBody,
    required this.sxBody,
    required this.szHead,
    required this.armRaise,
    required this.petalBloomWave,
    required this.speedyBagSwingDeg,
    required this.recommendedPose,
  });

  final double frameFloat;
  final int jumpIndex;
  final double phaseU;
  final double tzJumpMeters;
  final double szBody;
  final double sxBody;
  final double szHead;
  final double armRaise;
  final double petalBloomWave;
  final double speedyBagSwingDeg;
  final VivienneBlenderPose recommendedPose;

  static double smoothstep(double edge0, double edge1, double x) {
    if ((edge1 - edge0).abs() < 1e-8) {
      return x >= edge1 ? 1.0 : 0.0;
    }
    final double t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  static double evalPeriodicHermite(
    double u,
    List<(double, double, double)> knots,
  ) {
    final double uMod = ((u % 1.0) + 1.0) % 1.0;
    final List<(double, double, double)> ext = <(double, double, double)>[
      ...knots,
      (1.0, knots.first.$2, knots.first.$3),
    ];
    for (int i = 0; i < ext.length - 1; i++) {
      final (double u0, double y0, double m0) = ext[i];
      final (double u1, double y1, double m1) = ext[i + 1];
      if (uMod >= u0 && uMod <= u1 + 1e-9) {
        final double h = math.max(1e-8, u1 - u0);
        final double s = ((uMod - u0) / h).clamp(0.0, 1.0);
        final double s2 = s * s;
        final double s3 = s2 * s;
        final double h00 = 2.0 * s3 - 3.0 * s2 + 1.0;
        final double h10 = s3 - 2.0 * s2 + s;
        final double h01 = -2.0 * s3 + 3.0 * s2;
        final double h11 = s3 - s2;
        return h00 * y0 + h10 * h * m0 + h01 * y1 + h11 * h * m1;
      }
    }
    return knots.first.$2;
  }

  /// Evaluates the exact 72-frame (`3 jumps × 24 frames @ 24 FPS`) animation state
  /// from `models/vivienne_speedy_v03.blend`.
  static VivienneBlenderKinematics evaluateAtFrame(double frameFloat) {
    final double fZero = ((frameFloat - 1.0) % 72.0 + 72.0) % 72.0;
    final int jumpIdx = (fZero ~/ 24.0) % 3;
    final double u = (fZero % 24.0) / 24.0;

    const List<double> apexHeights = <double>[0.34, 0.40, 0.48];
    const List<double> squashDepths = <double>[0.82, 0.81, 0.80];
    const List<double> stretchPeaks = <double>[1.16, 1.17, 1.18];
    const List<double> descentStretches = <double>[1.13, 1.14, 1.15];
    const List<double> impactSquashes = <double>[0.81, 0.80, 0.81];
    const List<double> armVPeaks = <double>[0.92, 0.98, 1.06];

    final double hApex = apexHeights[jumpIdx];
    final double sqAnt = squashDepths[jumpIdx];
    final double stLaunch = stretchPeaks[jumpIdx];
    final double stDesc = descentStretches[jumpIdx];
    final double sqImp = impactSquashes[jumpIdx];
    final double armPeak = armVPeaks[jumpIdx];

    double tzJump = 0.0;
    if (u > 0.165 && u < 0.785) {
      final double sAir = u <= 0.465
          ? (u - 0.465) / (0.465 - 0.165)
          : (u - 0.465) / (0.785 - 0.465);
      final double parabola = math.max(0.0, 1.0 - sAir * sAir);
      final double liftoffEase =
          smoothstep(0.165, 0.225, u) * (1.0 - smoothstep(0.725, 0.785, u));
      tzJump =
          hApex *
          (0.82 * parabola + 0.18 * math.pow(parabola, 1.35)) *
          (0.25 + 0.75 * liftoffEase);
    }

    final List<(double, double, double)> szBodyKnots =
        <(double, double, double)>[
          (0.000, 0.945, -1.10),
          (0.125, sqAnt, 0.00),
          (0.208, stLaunch, 0.00),
          (0.340, 1.035, -0.35),
          (0.458, 1.010, 0.00),
          (0.580, 1.035, 0.45),
          (0.708, stDesc, 0.00),
          (0.833, sqImp, 0.00),
          (0.958, 0.975, 0.35),
        ];
    final double szBody = evalPeriodicHermite(u, szBodyKnots);
    // Volume conservation: sx * sy * sz == 1.0 -> sx = 1 / sqrt(sz)
    final double sxBody = 1.0 / math.sqrt(math.max(0.5, szBody));
    final double szHeadRaw = evalPeriodicHermite((u - 0.014) % 1.0, szBodyKnots);
    final double szHead = 1.0 + 0.46 * (szHeadRaw - 1.0);

    const List<(double, double, double)> petalBloomKnots =
        <(double, double, double)>[
          (0.000, -0.10, -2.5),
          (0.130, -0.45, -2.0),
          (0.215, -0.95, 0.0),
          (0.465, 1.00, 0.0),
          (0.710, 0.55, -3.5),
          (0.850, -1.05, 0.0),
          (0.955, 0.22, 0.0),
        ];
    final double petalWave = evalPeriodicHermite(u, petalBloomKnots);

    const List<(double, double, double)> armRaiseKnots =
        <(double, double, double)>[
          (0.000, -0.05, -1.8),
          (0.125, -0.24, 0.0),
          (0.208, 0.58, 7.2),
          (0.350, 0.94, 1.2),
          (0.465, 1.00, 0.0),
          (0.600, 0.86, -2.5),
          (0.720, 0.42, -5.0),
          (0.845, -0.18, 0.0),
          (0.955, 0.02, -0.5),
        ];
    final double armRaise = evalPeriodicHermite(u, armRaiseKnots) * armPeak;
    final double bagFollow =
        evalPeriodicHermite((u - 0.055) % 1.0, armRaiseKnots) * armPeak;
    final double bagSwingDeg =
        -18.0 * math.max(0.0, bagFollow) + 8.0 * math.min(0.0, bagFollow);

    final VivienneBlenderPose pose;
    if (u < 0.165) {
      pose = VivienneBlenderPose.pose1Squash;
    } else if (u < 0.30) {
      pose = VivienneBlenderPose.pose2Launch;
    } else if (u < 0.64) {
      pose = jumpIdx == 2
          ? VivienneBlenderPose.pose5GrandApex
          : VivienneBlenderPose.pose3Apex;
    } else if (u < 0.78) {
      pose = VivienneBlenderPose.pose2Launch;
    } else {
      pose = VivienneBlenderPose.pose4Landing;
    }

    return VivienneBlenderKinematics(
      frameFloat: frameFloat,
      jumpIndex: jumpIdx,
      phaseU: u,
      tzJumpMeters: tzJump,
      szBody: szBody,
      sxBody: sxBody,
      szHead: szHead,
      armRaise: armRaise,
      petalBloomWave: petalWave,
      speedyBagSwingDeg: bagSwingDeg,
      recommendedPose: pose,
    );
  }
}

/// Summary of the 5 PBR materials defined in `models/vivienne_speedy_v03.blend`.
class BlenderPbrMaterialSpec {
  const BlenderPbrMaterialSpec({
    required this.shaderName,
    required this.title,
    required this.hexColor,
    required this.color,
    required this.roughness,
    required this.metallic,
    required this.assignedParts,
  });

  final String shaderName;
  final String title;
  final String hexColor;
  final Color color;
  final double roughness;
  final double metallic;
  final String assignedParts;

  static const List<BlenderPbrMaterialSpec> officialMaterials =
      <BlenderPbrMaterialSpec>[
        BlenderPbrMaterialSpec(
          shaderName: 'Mat_Bois_Clair',
          title: 'Bois de Chêne Clair & Monogram',
          hexColor: '#C89D7C',
          color: Color(0xFFC89D7C),
          roughness: 0.45,
          metallic: 0.0,
          assignedParts: 'Vivienne_Head, Vivienne_Body (veines verticales + LV)',
        ),
        BlenderPbrMaterialSpec(
          shaderName: 'Mat_Cuir_Vachetta',
          title: 'Cuir Vachetta Naturel & Tranche Carmin',
          hexColor: '#E3A17B',
          color: Color(0xFFE3A17B),
          roughness: 0.38,
          metallic: 0.0,
          assignedParts:
              'Vivienne_Petal_Top/Bottom/Left/Right, Speedy_Handles (#8B1E24)',
        ),
        BlenderPbrMaterialSpec(
          shaderName: 'Mat_Couture_Jaune',
          title: 'Fil de Sellier Jaune d\'Or',
          hexColor: '#E5B842',
          color: Color(0xFFE5B842),
          roughness: 0.60,
          metallic: 0.0,
          assignedParts: 'Vivienne_Stitches_Top/Bottom/Left/Right, Speedy_Chapes',
        ),
        BlenderPbrMaterialSpec(
          shaderName: 'Mat_Toile_Monogram',
          title: 'Toile Monogram Ébène Enduite',
          hexColor: '#2B1D14',
          color: Color(0xFF2B1D14),
          roughness: 0.35,
          metallic: 0.0,
          assignedParts: 'Vivienne_Eye_Right_Flower, Vivienne_Arm_L/R, Speedy_Body',
        ),
        BlenderPbrMaterialSpec(
          shaderName: 'Mat_Or_Brillant',
          title: 'Laiton & Or Brillant 24 Carats',
          hexColor: '#FFD700',
          color: Color(0xFFFFD700),
          roughness: 0.12,
          metallic: 1.0,
          assignedParts:
              'Vivienne_Eye_Studs, Vivienne_Clasp_L/R, Speedy_Hardware_Gold',
        ),
      ];
}
