import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/vivienne_models.dart';

/// Core 60 FPS Deterministic Seeded Ascent Engine for `VIVIENNE : L'Odyssée Blossom`.
class VivienneJumpEngine extends ChangeNotifier {
  VivienneJumpEngine({int seed = 20261112})
    : _seed = seed,
      _levelRng = math.Random(seed) {
    resetRun(seed: seed);
  }

  static const double worldWidth = 420.0;
  static const double worldHeight = 860.0;

  static const double gravity = 1520.0;
  static const double baseJumpVelocity = -790.0;
  static const double springJumpVelocity = -1145.5; // 790 * 1.45
  static const double speedyBoostVelocity = -1420.0;
  static const double maxFallVelocity = 980.0;
  static const double maxHorizontalSpeed = 520.0;

  /// Official curated deterministic seeds selectable in the UI & Leaderboard.
  static const List<int> curatedSeeds = <int>[
    20261112,
    777,
    42,
    1854,
    90210,
  ];

  int _seed;
  int get seed => _seed;

  /// Dedicated PRNG used EXCLUSIVELY for deterministic platform/world generation.
  /// Never touched by visual particles or frame-dependent effects.
  late math.Random _levelRng;

  /// Separate PRNG used exclusively for visual-only particle bursts.
  final math.Random _fxRng = math.Random(10802400);

  int _nextEntityId = 1;
  int _generatedStepCount = 0;
  int _stepsSinceLastSpring = 10;
  int _stepsSinceLastDamped = 10;
  LvPlatform? _lastGeneratedPlatform;

  // Player & Edition State
  VivienneEdition selectedEdition = VivienneEdition.speedyMonogramV03;
  double playerX = worldWidth * 0.5;
  double playerY = worldHeight * 0.72;
  double playerVx = 0.0;
  double playerVy = 0.0;
  bool facingRight = true;

  // Camera & Altitude Progression (Y decreases as Vivienne climbs higher)
  double cameraY = 0.0;
  double highestWorldY = worldHeight * 0.72;
  double altitudeMeters = 0.0;
  double bestAltitudeMeters = 312.0;
  int score = 0;
  int bestScore = 3840;
  int totalBlossomsCollected = 0;
  int runBlossomsCollected = 0;
  int comboCount = 1;
  double comboTimer = 0.0;
  int perfectBounceStreak = 0;
  int totalPerfectBouncesInRun = 0;
  LvPlatformType lastBouncedPlatformType = LvPlatformType.monogramTrunk;

  // Seeded Leaderboard & Per-Seed Highscores ("Tableau des Scores par Seed")
  final Map<int, int> _seedHighScores = <int, int>{
    777: 3840,
    20261112: 3420,
    1854: 2950,
    42: 2480,
    90210: 2190,
  };

  final Map<int, int> _seedBestAltitudes = <int, int>{
    777: 312,
    20261112: 278,
    1854: 245,
    42: 204,
    90210: 182,
  };

  final List<SeedScoreEntry> _leaderboard = <SeedScoreEntry>[
    const SeedScoreEntry(
      seed: 777,
      score: 3840,
      altitudeMeters: 312,
      blossomsCollected: 28,
      edition: VivienneEdition.malleImperialeOr,
      playerTag: 'Maison LV • Record #777',
    ),
    const SeedScoreEntry(
      seed: 20261112,
      score: 3420,
      altitudeMeters: 278,
      blossomsCollected: 24,
      edition: VivienneEdition.speedyMonogramV03,
      playerTag: 'Atelier Asnières',
    ),
    const SeedScoreEntry(
      seed: 1854,
      score: 2950,
      altitudeMeters: 245,
      blossomsCollected: 21,
      edition: VivienneEdition.nuitAsnieres,
      playerTag: 'Vendôme Or',
    ),
    const SeedScoreEntry(
      seed: 42,
      score: 2480,
      altitudeMeters: 204,
      blossomsCollected: 18,
      edition: VivienneEdition.neoBlossomRose,
      playerTag: 'Jardin Sakura',
    ),
    const SeedScoreEntry(
      seed: 90210,
      score: 2190,
      altitudeMeters: 182,
      blossomsCollected: 15,
      edition: VivienneEdition.speedyMonogramV03,
      playerTag: 'Étoile Blossom',
    ),
  ];

  bool lastRunBeatSeedRecord = false;
  bool _currentRunRecorded = false;

  /// Returns all recorded score entries sorted by highest score first.
  List<SeedScoreEntry> get leaderboardEntries {
    final List<SeedScoreEntry> copy = List<SeedScoreEntry>.of(_leaderboard);
    copy.sort((SeedScoreEntry a, SeedScoreEntry b) => b.score.compareTo(a.score));
    return copy;
  }

  /// Returns the Highscore table with one best entry per Seed (sorted by highest score).
  List<SeedScoreEntry> get bestEntriesBySeed {
    final Map<int, SeedScoreEntry> bestPerSeed = <int, SeedScoreEntry>{};
    for (final SeedScoreEntry entry in _leaderboard) {
      final SeedScoreEntry? existing = bestPerSeed[entry.seed];
      if (existing == null || entry.score > existing.score) {
        bestPerSeed[entry.seed] = entry;
      }
    }
    final List<SeedScoreEntry> list = bestPerSeed.values.toList();
    list.sort((SeedScoreEntry a, SeedScoreEntry b) => b.score.compareTo(a.score));
    return list;
  }

  /// Returns the current Highscore to beat for `targetSeed`.
  int bestScoreForSeed(int targetSeed) => _seedHighScores[targetSeed] ?? 0;

  /// Returns the best altitude (in meters) recorded on `targetSeed`.
  int bestAltitudeForSeed(int targetSeed) => _seedBestAltitudes[targetSeed] ?? 0;

  /// Highscore of the currently active seed.
  int get currentSeedHighScore => bestScoreForSeed(_seed);

  /// Records a completed or manual score entry into the Seed Leaderboard and updates Seed Highscores.
  void recordRunScore({
    int? customScore,
    int? customAltitudeMeters,
    int? customSeed,
    String playerTag = 'VOUS • Vivienne',
  }) {
    final int targetSeed = customSeed ?? _seed;
    final int finalScore = customScore ?? score;
    final int finalAlt = customAltitudeMeters ?? altitudeMeters.round();
    if (finalScore <= 0) return;

    final int prevBestForSeed = _seedHighScores[targetSeed] ?? 0;
    if (finalScore >= prevBestForSeed) {
      _seedHighScores[targetSeed] = finalScore;
      lastRunBeatSeedRecord = finalScore > prevBestForSeed || prevBestForSeed == 0;
    }
    final int prevAltForSeed = _seedBestAltitudes[targetSeed] ?? 0;
    if (finalAlt > prevAltForSeed) {
      _seedBestAltitudes[targetSeed] = finalAlt;
    }
    if (finalScore > bestScore) {
      bestScore = finalScore;
    }
    if (finalAlt > bestAltitudeMeters) {
      bestAltitudeMeters = finalAlt.toDouble();
    }

    _leaderboard.add(
      SeedScoreEntry(
        seed: targetSeed,
        score: finalScore,
        altitudeMeters: finalAlt,
        blossomsCollected: runBlossomsCollected,
        edition: selectedEdition,
        playerTag: playerTag,
        isPlayerRun: true,
      ),
    );
    _currentRunRecorded = true;
    notifyListeners();
  }

  // Collectible Breakdown for the current run
  final Map<BlossomItemType, int> collectedByType = <BlossomItemType, int>{
    for (final BlossomItemType t in BlossomItemType.values) t: 0,
  };

  // Tilt Sensor & Calibration State (Portrait mode)
  double rawHardwareTiltX = 0.0;
  double tiltCalibrationOffset = 0.0;
  double? manualTiltOverride;
  double tiltSensitivity = 1.15;
  bool hardwareSensorActive = false;
  double lastSensorAx = 0.0;
  double lastSensorAy = 9.81;
  double lastSensorAz = 0.0;

  // Active Power-up Timers & Blossom Gauge
  double blossomGauge = 0.45; // 0.0 -> 1.0 ("Jauge Éclat Blossom")
  double speedyBoostTimer = 0.0;
  double padlockShieldTimer = 0.0;
  double magnetTimer = 0.0;
  double groundSquashTimer = 0.0; // > 0 right after bouncing on a platform
  double grandLeapTimer = 0.0;

  // Blender 3D Rig & Animation Inspector State
  bool showBlenderRigOverlay = false;
  double elapsedTime = 0.0;
  int totalJumpsInRun = 0;

  // Lifecycle & Menu State
  bool isInMenu = false;
  bool isPaused = false;
  bool isGameOver = false;

  // World Entities
  final List<LvPlatform> platforms = <LvPlatform>[];
  final List<BlossomCollectible> collectibles = <BlossomCollectible>[];
  final List<LvAtelierHazard> hazards = <LvAtelierHazard>[];
  final List<BlossomParticle> particles = <BlossomParticle>[];
  final List<FloatingCallout> callouts = <FloatingCallout>[];

  double _highestGeneratedPlatformY = worldHeight;

  /// Effective normalized horizontal tilt in `[-1.25, +1.25]`.
  double get effectiveTiltX {
    if (manualTiltOverride != null) {
      return (manualTiltOverride! * tiltSensitivity).clamp(-1.25, 1.25);
    }
    return ((rawHardwareTiltX - tiltCalibrationOffset) * tiltSensitivity).clamp(
      -1.25,
      1.25,
    );
  }

  /// Effective phone roll angle in degrees (for the Portrait inclinometer HUD).
  double get tiltAngleDegrees => (effectiveTiltX * 32.0).clamp(-45.0, 45.0);

  /// Current vertical biome based on Vivienne's altitude.
  LvBiome get currentBiome => LvBiome.forAltitude(altitudeMeters);

  /// Current Blender Cycles sprite pose & Squash/Stretch factors for Vivienne.
  (VivienneBlenderPose pose, double scaleX, double scaleY)
  get currentBlenderRenderState {
    if (showBlenderRigOverlay) {
      return (VivienneBlenderPose.pose6RigOverlay, 1.0, 1.0);
    }
    if (speedyBoostTimer > 0.0 || grandLeapTimer > 0.0) {
      final double pulse = 1.0 + 0.04 * math.sin(elapsedTime * 18.0);
      return (
        VivienneBlenderPose.pose5GrandApex,
        1.0 / math.sqrt(pulse),
        pulse,
      );
    }
    if (groundSquashTimer > 0.0) {
      final double t = 1.0 - (groundSquashTimer / 0.16).clamp(0.0, 1.0);
      if (t < 0.55) {
        const double sz = 0.82;
        return (
          VivienneBlenderPose.pose1Squash,
          1.0 / math.sqrt(sz),
          sz,
        );
      } else {
        const double sz = 1.15;
        return (
          VivienneBlenderPose.pose2Launch,
          1.0 / math.sqrt(sz),
          sz,
        );
      }
    }

    if (playerVy < -440.0) {
      const double sz = 1.12;
      return (
        VivienneBlenderPose.pose2Launch,
        1.0 / math.sqrt(sz),
        sz,
      );
    } else if (playerVy < 160.0) {
      final bool isGrandThirdJump = (totalJumpsInRun % 3 == 0);
      return (
        isGrandThirdJump
            ? VivienneBlenderPose.pose5GrandApex
            : VivienneBlenderPose.pose3Apex,
        1.0,
        1.01,
      );
    } else if (playerVy < 520.0) {
      return (VivienneBlenderPose.pose3Apex, 0.98, 1.04);
    } else {
      const double sz = 1.08;
      return (
        VivienneBlenderPose.pose4Landing,
        1.0 / math.sqrt(sz),
        sz,
      );
    }
  }

  void selectEdition(VivienneEdition edition) {
    selectedEdition = edition;
    resetRun(seed: _seed);
  }

  /// Sets a new deterministic world seed and restarts the ascent.
  void setSeed(int newSeed) {
    if (score > 0 && !_currentRunRecorded) {
      recordRunScore();
    }
    isInMenu = false;
    resetRun(seed: newSeed);
  }

  /// Launches or replays a specific deterministic seed from the Menu or Game Over Leaderboard
  /// with the explicit goal of beating that seed's Highscore.
  void replaySeed(int targetSeed) {
    if (score > 0 && !_currentRunRecorded) {
      recordRunScore();
    }
    isInMenu = false;
    resetRun(seed: targetSeed);
  }

  /// Opens the pre-game / store launch menu overlay (with Seed Leaderboard).
  void openMainMenu() {
    if (score > 0 && !_currentRunRecorded) {
      recordRunScore();
    }
    isInMenu = true;
    notifyListeners();
  }

  /// Starts a fresh run from the main menu on `targetSeed` (or current `_seed`).
  void startRunFromMenu({int? targetSeed}) {
    isInMenu = false;
    resetRun(seed: targetSeed ?? _seed);
  }

  /// Cycles to the next curated deterministic seed.
  void cycleNextSeed() {
    final int idx = curatedSeeds.indexOf(_seed);
    final int nextSeed =
        curatedSeeds[(idx + 1) % curatedSeeds.length];
    setSeed(nextSeed);
  }

  void togglePause() {
    if (isGameOver) return;
    isPaused = !isPaused;
    notifyListeners();
  }

  void toggleBlenderRigOverlay() {
    showBlenderRigOverlay = !showBlenderRigOverlay;
    notifyListeners();
  }

  /// Updates tilt from the Android hardware `Sensor.TYPE_ACCELEROMETER` EventChannel.
  void updateHardwareSensor(
    double normalizedTiltX, {
    double ax = 0.0,
    double ay = 9.81,
    double az = 0.0,
  }) {
    hardwareSensorActive = true;
    rawHardwareTiltX = normalizedTiltX;
    lastSensorAx = ax;
    lastSensorAy = ay;
    lastSensorAz = az;
  }

  /// Calibrates the current phone inclination as 0° neutral center.
  void calibrateTiltZero() {
    tiltCalibrationOffset = rawHardwareTiltX;
    manualTiltOverride = null;
    notifyListeners();
  }

  /// Sets or clears manual/simulated tilt in `[-1.0, +1.0]` (used for touch assist or testing).
  void setManualTilt(double? tiltX) {
    manualTiltOverride = tiltX?.clamp(-1.15, 1.15);
    notifyListeners();
  }

  /// Maximum vertical jump height (in world pixels) achievable when bouncing from `source`
  /// (accounting for normal bounce vs spring/bonus bounce on `source`).
  double maxJumpHeightFrom(LvPlatform source, {bool useEditionBonus = true}) {
    final double editionMult = useEditionBonus
        ? selectedEdition.jumpImpulseMultiplier
        : 1.0;
    final double bonusMult = source.hasBonusItem
        ? math.max(source.type.impulseMultiplier, 1.42)
        : source.type.impulseMultiplier;
    final double vy = baseJumpVelocity.abs() * bonusMult * editionMult;
    return (vy * vy) / (2.0 * gravity);
  }

  /// Returns `true` if `target` can be reached in a single jump from `source`
  /// (using a normal jump, or `source`'s spring/bonus jump if `source` has one).
  bool canReachPlatform(LvPlatform source, LvPlatform target) {
    final double dy = source.y - target.y;
    if (dy <= 0.0) return false;

    final double maxH = maxJumpHeightFrom(source, useEditionBonus: true);
    if (dy > maxH - 8.0) return false;

    final double bonusMult = source.hasBonusItem
        ? math.max(source.type.impulseMultiplier, 1.42)
        : source.type.impulseMultiplier;
    final double vy0 =
        baseJumpVelocity.abs() *
        bonusMult *
        selectedEdition.jumpImpulseMultiplier;
    final double disc = math.max(0.0, vy0 * vy0 - 2.0 * gravity * dy);
    final double flightTime = (vy0 + math.sqrt(disc)) / gravity;

    // Worst-case horizontal distance between source and target anchors
    final double directDist = (target.anchorX - source.anchorX).abs();
    final double wrappedDist = worldWidth - directDist;
    final double minCenterDist = math.min(directDist, wrappedDist);
    final double effectiveEdgeDist = math.max(
      0.0,
      minCenterDist +
          source.patrolRadius +
          target.patrolRadius -
          (source.width * 0.5 + target.width * 0.5),
    );
    final double maxHorizontalReach = maxHorizontalSpeed * flightTime;
    return effectiveEdgeDist <= maxHorizontalReach;
  }

  /// Returns all platforms above `source` that are within jump reach of `source`.
  /// By design of the seeded generator, this list always has between 1 and 3 platforms.
  List<LvPlatform> getPlatformsInJumpReach(LvPlatform source) {
    final double maxH = maxJumpHeightFrom(source, useEditionBonus: true);
    return platforms
        .where(
          (LvPlatform p) =>
              p.id != source.id &&
              !p.broken &&
              (source.y - p.y) > 1.0 &&
              (source.y - p.y) <= maxH &&
              canReachPlatform(source, p),
        )
        .toList();
  }

  /// Jumps directly to a target altitude biome by deterministically advancing the seeded
  /// platform chain up to `targetMeters`.
  void warpToAltitude(double targetMeters) {
    resetRun(seed: _seed);
    final double targetWorldY = worldHeight * 0.72 - targetMeters * 14.0;
    _populatePlatformsUpTo(targetWorldY - worldHeight * 1.25);

    // Find the deterministic platform closest to targetWorldY + 45
    LvPlatform? landingPlat;
    double bestDist = double.infinity;
    for (final LvPlatform p in platforms) {
      final double d = (p.y - (targetWorldY + 45.0)).abs();
      if (d < bestDist && !p.type.singleUse) {
        bestDist = d;
        landingPlat = p;
      }
    }

    if (landingPlat != null) {
      playerX = landingPlat.x;
      playerY = landingPlat.y - 45.0;
    } else {
      playerY = targetWorldY;
    }

    highestWorldY = playerY;
    cameraY = playerY - worldHeight * 0.45;
    altitudeMeters = targetMeters;
    if (altitudeMeters > bestAltitudeMeters) {
      bestAltitudeMeters = altitudeMeters;
    }
    score = math.max(score, (targetMeters * 12).round());
    if (score > bestScore) {
      bestScore = score;
    }

    final double cullBottomY = cameraY + worldHeight + 160.0;
    platforms.removeWhere(isPlatformBelowScreen);
    collectibles.removeWhere((BlossomCollectible c) => c.y > cullBottomY);
    hazards.removeWhere((LvAtelierHazard h) => h.y > cullBottomY);
    notifyListeners();
  }

  /// Returns `true` as soon as `plat` exits the bottom of the visible screen (`cameraY + worldHeight`).
  /// Once a platform exits the bottom of the screen, it disappears and cannot be bounced on.
  bool isPlatformBelowScreen(LvPlatform plat) {
    final double screenBottomY = cameraY + worldHeight;
    return plat.y >= screenBottomY ||
        (plat.y - plat.height * 0.5) >= screenBottomY;
  }

  /// Resets and starts a fresh deterministic ascent run from `seed`.
  void resetRun({int? seed}) {
    if (seed != null) {
      _seed = seed;
    }
    _levelRng = math.Random(_seed);
    _nextEntityId = 1;
    _generatedStepCount = 0;
    _stepsSinceLastSpring = 10;
    _stepsSinceLastDamped = 10;
    _lastGeneratedPlatform = null;

    platforms.clear();
    collectibles.clear();
    hazards.clear();
    particles.clear();
    callouts.clear();
    for (final BlossomItemType t in BlossomItemType.values) {
      collectedByType[t] = 0;
    }

    playerX = worldWidth * 0.5;
    playerY = worldHeight * 0.72;
    playerVx = 0.0;
    playerVy = baseJumpVelocity * selectedEdition.jumpImpulseMultiplier;
    facingRight = true;

    cameraY = 0.0;
    highestWorldY = playerY;
    altitudeMeters = 0.0;
    score = 0;
    runBlossomsCollected = 0;
    comboCount = 1;
    comboTimer = 0.0;
    perfectBounceStreak = 0;
    totalPerfectBouncesInRun = 0;
    lastBouncedPlatformType = LvPlatformType.monogramTrunk;
    lastRunBeatSeedRecord = false;
    _currentRunRecorded = false;

    blossomGauge = 0.50;
    speedyBoostTimer = 0.0;
    padlockShieldTimer =
        selectedEdition == VivienneEdition.malleImperialeOr ? 8.0 : 0.0;
    magnetTimer = 0.0;
    groundSquashTimer = 0.14;
    grandLeapTimer = 0.0;
    totalJumpsInRun = 1;
    isPaused = false;
    isGameOver = false;

    // Step 0: Single deterministic starting platform directly beneath Vivienne.
    // (No extra side platforms at the bottom so the challenge starts immediately!)
    final double baseY = worldHeight * 0.78;
    final LvPlatform startPlat = LvPlatform(
      id: _nextEntityId++,
      stepIndex: 0,
      x: worldWidth * 0.5,
      anchorX: worldWidth * 0.5,
      y: baseY,
      width: 90.0,
      height: 18.0,
      type: LvPlatformType.monogramTrunk,
    );
    platforms.add(startPlat);
    _lastGeneratedPlatform = startPlat;
    _generatedStepCount = 1;
    _highestGeneratedPlatformY = baseY;

    _populatePlatformsUpTo(cameraY - worldHeight * 1.25);

    notifyListeners();
  }

  /// Triggers the active "Éclat Blossom — Grand Saut Célébration (Frame 60)" power!
  bool triggerGrandBlossomLeap() {
    if (isGameOver || isPaused) return false;
    if (blossomGauge < 1.0 && speedyBoostTimer <= 0.0) {
      if (blossomGauge < 0.45) return false;
    }
    blossomGauge = 0.0;
    grandLeapTimer = 1.65;
    padlockShieldTimer = math.max(padlockShieldTimer, 4.0);
    magnetTimer = math.max(magnetTimer, 5.0);
    playerVy = speedyBoostVelocity * 0.96;
    totalJumpsInRun = ((totalJumpsInRun ~/ 3) + 1) * 3; // Align to Jump 3 (Frame 60)

    callouts.add(
      FloatingCallout(
        text: 'GRAND SAUT BLOSSOM !',
        x: playerX,
        y: playerY - 48.0,
        color: const Color(0xFFFFD700),
      ),
    );
    _spawnCelebrationBurst(playerX, playerY, 22);
    notifyListeners();
    return true;
  }

  /// Advances the game world by `dt` seconds (clamped for stability).
  void update(double dt) {
    if (isPaused || isGameOver) return;
    final double step = dt.clamp(0.001, 0.05);
    elapsedTime += step;

    // 1. Update timers
    if (speedyBoostTimer > 0.0) {
      speedyBoostTimer = math.max(0.0, speedyBoostTimer - step);
    }
    if (padlockShieldTimer > 0.0) {
      padlockShieldTimer = math.max(0.0, padlockShieldTimer - step);
    }
    if (magnetTimer > 0.0) {
      magnetTimer = math.max(0.0, magnetTimer - step);
    }
    if (groundSquashTimer > 0.0) {
      groundSquashTimer = math.max(0.0, groundSquashTimer - step);
    }
    if (grandLeapTimer > 0.0) {
      grandLeapTimer = math.max(0.0, grandLeapTimer - step);
    }
    if (comboTimer > 0.0) {
      comboTimer = math.max(0.0, comboTimer - step);
      if (comboTimer == 0.0) {
        comboCount = 1;
      }
    }

    // 2. Horizontal velocity driven by phone tilt in Portrait mode
    final double tilt = effectiveTiltX;
    final double responsiveness =
        selectedEdition == VivienneEdition.nuitAsnieres ? 14.5 : 11.5;
    final double targetVx = (tilt * maxHorizontalSpeed).clamp(
      -maxHorizontalSpeed,
      maxHorizontalSpeed,
    );
    playerVx += (targetVx - playerVx) * (responsiveness * step).clamp(0.0, 1.0);
    if (playerVx.abs() > 14.0) {
      facingRight = playerVx >= 0.0;
    }

    final double prevBottomY = playerY + 34.0;
    playerX += playerVx * step;

    // Classic Doodle Jump horizontal screen wrap-around
    if (playerX < 0.0) {
      playerX += worldWidth;
    } else if (playerX > worldWidth) {
      playerX -= worldWidth;
    }

    // 3. Vertical velocity & Speedy Boost / Grand Leap override
    if (speedyBoostTimer > 0.0) {
      playerVy = speedyBoostVelocity;
      if (_fxRng.nextDouble() < 0.55) {
        particles.add(
          BlossomParticle(
            x: playerX + (_fxRng.nextDouble() - 0.5) * 30.0,
            y: playerY + 28.0,
            vx: (_fxRng.nextDouble() - 0.5) * 50.0,
            vy: 130.0 + _fxRng.nextDouble() * 110.0,
            size: 5.0 + _fxRng.nextDouble() * 4.0,
            color: const Color(0xFFFFD700),
            life: 0.40,
            maxLife: 0.40,
            isPetal: true,
          ),
        );
      }
    } else if (grandLeapTimer > 0.95) {
      playerVy = speedyBoostVelocity * 0.92;
    } else {
      playerVy = (playerVy + gravity * step).clamp(
        speedyBoostVelocity * 1.2,
        maxFallVelocity,
      );
    }

    playerY += playerVy * step;
    final double newBottomY = playerY + 34.0;

    // 4. Update moving platforms within their bounded patrol zone & check landing
    for (final LvPlatform plat in platforms) {
      if (plat.bounceCompress > 0.0) {
        plat.bounceCompress = math.max(0.0, plat.bounceCompress - step * 4.5);
      }
      if (plat.type.movesHorizontally && !plat.broken && plat.patrolRadius > 0) {
        plat.x += plat.vx * step;
        final double minX = plat.anchorX - plat.patrolRadius;
        final double maxX = plat.anchorX + plat.patrolRadius;
        if (plat.x <= minX) {
          plat.x = minX;
          plat.vx = plat.vx.abs();
        } else if (plat.x >= maxX) {
          plat.x = maxX;
          plat.vx = -plat.vx.abs();
        }
      }
    }

    // Immediately discard any platform that has already exited the bottom of the screen
    platforms.removeWhere(isPlatformBelowScreen);

    if (playerVy >= 0.0) {
      for (final LvPlatform plat in platforms) {
        if (plat.broken || isPlatformBelowScreen(plat)) continue;
        final double platTop = plat.y - plat.height * 0.5;
        final bool crossedTop =
            prevBottomY <= platTop + 12.0 && newBottomY >= platTop - 4.0;
        final double horizontalDist = (playerX - plat.x).abs();
        final double hitHalfWidth = plat.width * 0.5 + 18.0;

        if (crossedTop && horizontalDist <= hitHalfWidth) {
          _bounceOnPlatform(plat);
          break;
        }
      }
    }

    // 5. Update & collect Blossom Flowers and LV Maison items
    final double baseCollectRadius =
        44.0 + selectedEdition.magnetRadiusBonus;
    final double activeMagnetRadius = magnetTimer > 0.0 ||
            speedyBoostTimer > 0.0 ||
            grandLeapTimer > 0.0
        ? 220.0
        : baseCollectRadius;

    for (final BlossomCollectible item in collectibles) {
      if (item.collected) continue;
      item.phase += step * 3.2;

      final double dx = playerX - item.x;
      final double dy = playerY - item.y;
      final double dist = math.sqrt(dx * dx + dy * dy);

      if (dist <= activeMagnetRadius && dist > 1.0) {
        final double pullSpeed = dist <= baseCollectRadius ? 410.0 : 540.0;
        item.x += (dx / dist) * pullSpeed * step;
        item.y += (dy / dist) * pullSpeed * step;
      }

      if (dist <= 40.0) {
        _collectBlossomItem(item);
      }
    }

    // 6. Update high-altitude hazards
    for (final LvAtelierHazard hazard in hazards) {
      hazard.phase += step * 4.0;
      hazard.x += hazard.vx * step;
      if (hazard.x < 36.0) {
        hazard.x = 36.0;
        hazard.vx = hazard.vx.abs();
      } else if (hazard.x > worldWidth - 36.0) {
        hazard.x = worldWidth - 36.0;
        hazard.vx = -hazard.vx.abs();
      }

      final double dx = playerX - hazard.x;
      final double dy = playerY - hazard.y;
      final double dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= hazard.radius + 22.0) {
        if (speedyBoostTimer > 0.0 ||
            grandLeapTimer > 0.0 ||
            padlockShieldTimer > 0.0 ||
            playerVy < -600.0) {
          hazard.y += worldHeight * 2.0;
          score += 150;
          _spawnCelebrationBurst(hazard.x, hazard.y, 12);
          callouts.add(
            FloatingCallout(
              text: '+150',
              x: playerX,
              y: playerY - 30.0,
              color: const Color(0xFFFFD700),
            ),
          );
        } else {
          if (playerVy > 0.0 && playerY < hazard.y) {
            playerVy = baseJumpVelocity * 1.12;
            hazard.y += worldHeight * 2.0;
            score += 120;
            _spawnCelebrationBurst(playerX, playerY, 10);
          } else {
            padlockShieldTimer = 2.0;
            playerVy = math.max(playerVy, 240.0);
          }
        }
      }
    }

    // 7. Camera follows Vivienne upward only (classic Doodle Jump one-way camera)
    if (playerY < highestWorldY) {
      final double gainedPixels = highestWorldY - playerY;
      highestWorldY = playerY;
      final double newAltitude =
          (worldHeight * 0.72 - highestWorldY) / 14.0;
      if (newAltitude > altitudeMeters) {
        altitudeMeters = newAltitude;
        if (altitudeMeters > bestAltitudeMeters) {
          bestAltitudeMeters = altitudeMeters;
        }
      }
      score += (gainedPixels * 0.85 * selectedEdition.scoreMultiplier).round();
      if (score > bestScore) {
        bestScore = score;
      }
    }

    final double targetCameraY = highestWorldY - worldHeight * 0.42;
    if (targetCameraY < cameraY) {
      cameraY += (targetCameraY - cameraY) * (14.0 * step).clamp(0.0, 1.0);
    }

    // 8. Deterministically generate new platforms above the camera using `_levelRng`
    _populatePlatformsUpTo(cameraY - worldHeight * 1.15);

    // 9. Immediately make platforms disappear as soon as they exit the bottom of the screen
    platforms.removeWhere(isPlatformBelowScreen);
    final double cullBottomY = cameraY + worldHeight + 150.0;
    collectibles.removeWhere(
      (BlossomCollectible c) => c.collected || c.y > cullBottomY,
    );
    hazards.removeWhere((LvAtelierHazard h) => h.y > cullBottomY);

    // 10. Update particles with platform-specific physics (drag, swirl, gravityScale) & callouts
    for (final BlossomParticle p in particles) {
      if (p.drag > 0.0) {
        final double damping = math.max(0.0, 1.0 - p.drag * step);
        p.vx *= damping;
        p.vy *= damping;
      }
      p.swirlPhase += p.swirlFrequency * step;
      final double swirlVx = p.swirlAmplitude != 0.0
          ? math.cos(p.swirlPhase) * p.swirlAmplitude
          : 0.0;
      p.x += (p.vx + swirlVx) * step;
      p.y += p.vy * step;
      p.vy += (gravity * 0.24 * p.gravityScale) * step;
      p.rotation += 3.2 * step;
      p.life -= step;
    }
    particles.removeWhere((BlossomParticle p) => p.life <= 0.0);

    for (final FloatingCallout c in callouts) {
      c.y -= 42.0 * step;
      c.life -= step * 1.25;
    }
    callouts.removeWhere((FloatingCallout c) => c.life <= 0.0);

    // 11. Check fall below bottom of screen (real challenge: falling ends the run unless shielded!)
    if (playerY - cameraY > worldHeight + 65.0) {
      if (padlockShieldTimer > 0.0) {
        padlockShieldTimer = 0.0;
        playerY = cameraY + worldHeight * 0.78;
        playerVy = springJumpVelocity;
        groundSquashTimer = 0.16;
        callouts.add(
          FloatingCallout(
            text: 'BOUCLIER CADENAS !',
            x: playerX,
            y: playerY - 40.0,
            color: const Color(0xFFFFD700),
          ),
        );
        _spawnCelebrationBurst(playerX, playerY, 16);
      } else {
        isGameOver = true;
        if (!_currentRunRecorded) {
          recordRunScore();
        }
      }
    }

    notifyListeners();
  }

  void _bounceOnPlatform(LvPlatform plat) {
    plat.bounceCompress = 1.0;
    groundSquashTimer = 0.16;
    totalJumpsInRun++;
    lastBouncedPlatformType = plat.type;

    final double impulse =
        baseJumpVelocity *
        plat.type.impulseMultiplier *
        selectedEdition.jumpImpulseMultiplier;
    playerVy = impulse;

    final double impactX = playerX.clamp(
      plat.x - plat.width * 0.44,
      plat.x + plat.width * 0.44,
    );

    // Perfect Center Bounce detection: landing within 24% of platform center
    final bool isPerfectCenter =
        (playerX - plat.x).abs() <= plat.width * 0.24;
    if (isPerfectCenter) {
      perfectBounceStreak = (perfectBounceStreak + 1).clamp(1, 15);
      totalPerfectBouncesInRun++;
      comboTimer = math.max(comboTimer, 3.2);
      final int perfBonus =
          (35 * perfectBounceStreak * selectedEdition.scoreMultiplier).round();
      score += perfBonus;
      if (score > bestScore) {
        bestScore = score;
      }
      blossomGauge = (blossomGauge + 0.08).clamp(0.0, 1.0);
      callouts.add(
        FloatingCallout(
          text: 'PARFAIT ×$perfectBounceStreak ! +$perfBonus',
          x: plat.x,
          y: plat.y - 36.0,
          color: const Color(0xFFFFE082),
        ),
      );
    } else {
      perfectBounceStreak = 0;
    }

    // Gameplay effects + lightweight, dynamic per-platform particle physics (no verbose platform callouts)
    switch (plat.type) {
      case LvPlatformType.springLockGold:
        plat.hasSpringTriggered = true;
        grandLeapTimer = math.max(grandLeapTimer, 0.75);
        score += (100 * comboCount * selectedEdition.scoreMultiplier).round();
        if (score > bestScore) {
          bestScore = score;
        }
        _spawnPlatformBounceParticles(plat, impactX: impactX);

      case LvPlatformType.silkBlossomFragile:
        plat.broken = true;
        score += (40 * comboCount * selectedEdition.scoreMultiplier).round();
        if (score > bestScore) {
          bestScore = score;
        }
        _spawnPlatformBounceParticles(plat, impactX: impactX);

      case LvPlatformType.damierCloud:
        blossomGauge = (blossomGauge + 0.12).clamp(0.0, 1.0);
        score += (30 * comboCount * selectedEdition.scoreMultiplier).round();
        if (score > bestScore) {
          bestScore = score;
        }
        _spawnPlatformBounceParticles(plat, impactX: impactX);

      case LvPlatformType.vachettaStrapMoving:
        score += (45 * comboCount * selectedEdition.scoreMultiplier).round();
        if (score > bestScore) {
          bestScore = score;
        }
        _spawnPlatformBounceParticles(plat, impactX: impactX);

      case LvPlatformType.monogramTrunk:
        _spawnPlatformBounceParticles(plat, impactX: impactX);
    }
  }

  void _collectBlossomItem(BlossomCollectible item) {
    item.collected = true;
    runBlossomsCollected += item.type.blossomCountValue;
    totalBlossomsCollected += item.type.blossomCountValue;
    collectedByType[item.type] = (collectedByType[item.type] ?? 0) + 1;

    comboTimer = 4.2;
    comboCount = (comboCount + 1).clamp(1, 12);

    final double gaugeBonus =
        selectedEdition == VivienneEdition.neoBlossomRose ? 1.20 : 1.0;
    blossomGauge = (blossomGauge + item.type.gaugeGain * gaugeBonus).clamp(
      0.0,
      1.0,
    );

    final int pts =
        (item.type.points * comboCount * selectedEdition.scoreMultiplier)
            .round();
    score += pts;
    if (score > bestScore) {
      bestScore = score;
    }

    switch (item.type) {
      case BlossomItemType.starBlossomGold:
      case BlossomItemType.sunBlossomCorolla:
      case BlossomItemType.neoBlossomDiamond:
        callouts.add(
          FloatingCallout(
            text: '+$pts',
            x: item.x,
            y: item.y - 16.0,
            color: item.type.primaryColor,
          ),
        );
      case BlossomItemType.speedyBagBoost:
        speedyBoostTimer = 2.8 * selectedEdition.speedyBoostMultiplier;
        padlockShieldTimer = math.max(
          padlockShieldTimer,
          speedyBoostTimer + 1.2,
        );
        callouts.add(
          FloatingCallout(
            text: 'PROPULSION SPEEDY !',
            x: item.x,
            y: item.y - 24.0,
            color: const Color(0xFFFFD700),
          ),
        );
      case BlossomItemType.goldenPadlockShield:
        padlockShieldTimer = 10.0;
        callouts.add(
          FloatingCallout(
            text: 'BOUCLIER 10s',
            x: item.x,
            y: item.y - 22.0,
            color: const Color(0xFFFFD700),
          ),
        );
      case BlossomItemType.monogramMagnet:
        magnetTimer = 8.0;
        callouts.add(
          FloatingCallout(
            text: 'AIMANT 8s',
            x: item.x,
            y: item.y - 22.0,
            color: const Color(0xFFE3A17B),
          ),
        );
    }

    _spawnCelebrationBurst(item.x, item.y, 9);
  }

  /// Deterministically generates sparse, challenging platforms from `_levelRng` (`_seed`).
  ///
  /// Guarantees:
  /// 1. 100% deterministic from `seed` (independent of frame timing or particles).
  /// 2. Sparser vertical spacing so the player must steer carefully to avoid falling.
  /// 3. At most 3 platforms within jump reach (`1 <= getPlatformsInJumpReach(p).length <= 3`).
  /// 4. Next platform `P_{i+1}` is ALWAYS reachable from `P_i` (via normal jump, or via
  ///    `P_i`'s spring/bonus jump when `P_i` has one).
  void _populatePlatformsUpTo(double minY) {
    while (_highestGeneratedPlatformY > minY) {
      final LvPlatform prev = _lastGeneratedPlatform!;
      final bool prevHasSpringBonus =
          prev.type == LvPlatformType.springLockGold || prev.hasBonusItem;
      final bool prevIsDampedCloud =
          prev.type == LvPlatformType.damierCloud && !prev.hasBonusItem;

      // Vertical gap computation accounting for all 5 platform impulse multipliers:
      // - Normal jump (`×1.00`) reaches ~205.3 px.
      // - Damped Cloud jump (`×0.85`) reaches ~148.3 px -> stepY in [98, 118] px so P_{i+1} is 100% reachable!
      // - Moving Strap (`×1.14`) reaches ~266.8 px.
      // - Spring jump (`×1.45`) reaches ~431.6 px -> stepY in [196, 234] px.
      final double stepY;
      if (prevHasSpringBonus) {
        stepY = 196.0 + _levelRng.nextDouble() * 38.0; // 196..234 px (requires spring/bonus jump)
        _stepsSinceLastSpring = 0;
        _stepsSinceLastDamped++;
      } else if (prevIsDampedCloud) {
        stepY = 98.0 + _levelRng.nextDouble() * 18.0; // 98..116 px (short hop after damped cloud)
        _stepsSinceLastDamped = 0;
        _stepsSinceLastSpring++;
      } else if (_stepsSinceLastSpring < 2 || _stepsSinceLastDamped < 2) {
        stepY = 148.0 + _levelRng.nextDouble() * 20.0; // 148..168 px
        _stepsSinceLastSpring++;
        _stepsSinceLastDamped++;
      } else {
        stepY = 132.0 + _levelRng.nextDouble() * 36.0; // 132..168 px
        _stepsSinceLastSpring++;
        _stepsSinceLastDamped++;
      }

      _highestGeneratedPlatformY -= stepY;
      final double y = _highestGeneratedPlatformY;
      final double altAtY = math.max(0.0, (worldHeight * 0.72 - y) / 14.0);

      final LvPlatformType type = _pickPlatformTypeForAltitude(
        altAtY,
        prevType: prev.type,
        allowSpring: _stepsSinceLastSpring >= 3 && _stepsSinceLastDamped >= 2,
        allowDamped: _stepsSinceLastDamped >= 3 && _stepsSinceLastSpring >= 2,
      );

      // Trimmer platform widths for genuine mobile precision challenge
      final double altitudeShrink = (altAtY / 5000.0).clamp(0.0, 1.0) * 10.0;
      final double width = switch (type) {
        LvPlatformType.monogramTrunk => 82.0 - altitudeShrink,
        LvPlatformType.vachettaStrapMoving => 78.0 - altitudeShrink,
        LvPlatformType.silkBlossomFragile => 74.0 - altitudeShrink,
        LvPlatformType.springLockGold => 80.0 - altitudeShrink,
        LvPlatformType.damierCloud => 76.0 - altitudeShrink,
      };

      final double patrolRadius = type.movesHorizontally ? 26.0 : 0.0;
      final double speed = type.movesHorizontally
          ? (48.0 + _levelRng.nextDouble() * 34.0) *
                (_levelRng.nextBool() ? 1.0 : -1.0)
          : 0.0;

      // Compute exact flight time from `prev` to `y` to bound horizontal distance
      final double prevMult = prevHasSpringBonus
          ? math.max(prev.type.impulseMultiplier, 1.42)
          : prev.type.impulseMultiplier;
      final double vy0 = baseJumpVelocity.abs() * prevMult;
      final double disc = math.max(0.0, vy0 * vy0 - 2.0 * gravity * stepY);
      final double flightTime = (vy0 + math.sqrt(disc)) / gravity;

      // Conservative horizontal reach even accounting for moving platform patrol radii
      final double maxSafeHorizontal = math.min(
        prevIsDampedCloud ? 118.0 : 156.0,
        245.0 * math.max(0.26, flightTime - 0.14),
      );
      final double maxAnchorDelta = math.max(
        52.0,
        maxSafeHorizontal - prev.patrolRadius - patrolRadius,
      );
      final double minAnchorDelta = math.min(40.0, maxAnchorDelta - 10.0);
      final double deltaX =
          minAnchorDelta +
          _levelRng.nextDouble() * (maxAnchorDelta - minAnchorDelta);

      final double margin = 48.0 + patrolRadius;
      double dir = _levelRng.nextBool() ? 1.0 : -1.0;
      double candidateAnchorX = prev.anchorX + dir * deltaX;
      if (candidateAnchorX < margin ||
          candidateAnchorX > worldWidth - margin) {
        dir = -dir;
        candidateAnchorX = (prev.anchorX + dir * deltaX).clamp(
          margin,
          worldWidth - margin,
        );
      }

      // Decide deterministically if a collectible spawns on this platform
      final bool spawnCollectible = _levelRng.nextDouble() < 0.30;
      final BlossomItemType? itemType = spawnCollectible
          ? _pickBlossomCollectibleType(altAtY)
          : null;

      final LvPlatform nextPlat = LvPlatform(
        id: _nextEntityId++,
        stepIndex: _generatedStepCount++,
        x: candidateAnchorX,
        anchorX: candidateAnchorX,
        patrolRadius: patrolRadius,
        y: y,
        width: width,
        height: 17.0,
        type: type,
        vx: speed,
        hasBonusItem: itemType == BlossomItemType.speedyBagBoost,
      );
      platforms.add(nextPlat);
      _lastGeneratedPlatform = nextPlat;

      if (itemType != null) {
        collectibles.add(
          BlossomCollectible(
            id: _nextEntityId++,
            x: candidateAnchorX,
            y: y - 28.0,
            type: itemType,
          ),
        );
      }

      // Spawn occasional deterministic aerial hazard above 1200 m (away from platform center)
      if (altAtY > 1200.0 && _levelRng.nextDouble() < 0.08) {
        final double hazardX = candidateAnchorX < worldWidth * 0.5
            ? (candidateAnchorX + 120.0).clamp(48.0, worldWidth - 48.0)
            : (candidateAnchorX - 120.0).clamp(48.0, worldWidth - 48.0);
        hazards.add(
          LvAtelierHazard(
            id: _nextEntityId++,
            x: hazardX,
            y: y - 56.0,
            vx:
                (_levelRng.nextBool() ? 1.0 : -1.0) *
                (55.0 + _levelRng.nextDouble() * 45.0),
          ),
        );
      }
    }
  }

  LvPlatformType _pickPlatformTypeForAltitude(
    double altMeters, {
    required LvPlatformType prevType,
    required bool allowSpring,
    required bool allowDamped,
  }) {
    final double r = _levelRng.nextDouble();
    if (allowSpring && r < 0.16) {
      return LvPlatformType.springLockGold;
    }
    if (altMeters < 600) {
      if (r < 0.32) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.44 && prevType != LvPlatformType.silkBlossomFragile) {
        return LvPlatformType.silkBlossomFragile;
      }
      if (allowDamped && r < 0.56) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    } else if (altMeters < 2500) {
      if (r < 0.36) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.54 && prevType != LvPlatformType.silkBlossomFragile) {
        return LvPlatformType.silkBlossomFragile;
      }
      if (allowDamped && r < 0.68) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    } else {
      if (r < 0.40) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.62 && prevType != LvPlatformType.silkBlossomFragile) {
        return LvPlatformType.silkBlossomFragile;
      }
      if (allowDamped && r < 0.78) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    }
  }

  BlossomItemType _pickBlossomCollectibleType(double altMeters) {
    final double r = _levelRng.nextDouble();
    if (r < 0.48) return BlossomItemType.starBlossomGold;
    if (r < 0.76) return BlossomItemType.sunBlossomCorolla;
    if (r < 0.90) return BlossomItemType.neoBlossomDiamond;
    if (r < 0.94) return BlossomItemType.monogramMagnet;
    if (r < 0.98) return BlossomItemType.goldenPadlockShield;
    return BlossomItemType.speedyBagBoost;
  }

  /// Spawns a lightweight, dynamic particle burst at `impactX` whose physics
  /// (`gravityScale`, `drag`, `swirlAmplitude`, `stretchFactor`, `shape`) are
  /// specifically tailored to the platform's physical archetype.
  void _spawnPlatformBounceParticles(
    LvPlatform plat, {
    required double impactX,
  }) {
    final double topY = plat.y - plat.height * 0.5;
    switch (plat.type) {
      case LvPlatformType.monogramTrunk:
        // 1. Malle Monogram Ébène: Crisp brass/gold sparks fanning out with heavy parabolic gravity
        const List<Color> sparkColors = <Color>[
          Color(0xFFFFD700),
          Color(0xFFFFE082),
          Color(0xFFE3A17B),
        ];
        for (int i = 0; i < 8; i++) {
          final double side = i.isEven ? 1.0 : -1.0;
          final double vx = side * (62.0 + _fxRng.nextDouble() * 68.0);
          final double vy = -(65.0 + _fxRng.nextDouble() * 60.0);
          final double life = 0.34 + _fxRng.nextDouble() * 0.14;
          particles.add(
            BlossomParticle(
              x: impactX + (_fxRng.nextDouble() - 0.5) * 18.0,
              y: topY,
              vx: vx,
              vy: vy,
              size: 4.2 + _fxRng.nextDouble() * 2.6,
              color: sparkColors[i % sparkColors.length],
              life: life,
              maxLife: life,
              shape: PlatformParticleShape.brassSpark,
              gravityScale: 1.25,
              drag: 1.8,
              rotation: _fxRng.nextDouble() * math.pi,
            ),
          );
        }

      case LvPlatformType.springLockGold:
        // 2. Malle Ressort Or 24K: High-velocity ascending 24K gold stars with upward anti-gravity jet
        const List<Color> springColors = <Color>[
          Color(0xFFFFD700),
          Color(0xFFFFF59D),
          Color(0xFFFFFFFF),
          Color(0xFFFFA000),
        ];
        for (int i = 0; i < 12; i++) {
          final double vx = (_fxRng.nextDouble() - 0.5) * 84.0;
          final double vy = -(185.0 + _fxRng.nextDouble() * 125.0);
          final double life = 0.42 + _fxRng.nextDouble() * 0.16;
          particles.add(
            BlossomParticle(
              x: impactX + (_fxRng.nextDouble() - 0.5) * 28.0,
              y: topY - 4.0,
              vx: vx,
              vy: vy,
              size: 5.5 + _fxRng.nextDouble() * 3.5,
              color: springColors[i % springColors.length],
              life: life,
              maxLife: life,
              shape: PlatformParticleShape.springUpdraftStar,
              gravityScale: -0.35,
              drag: 0.8,
              swirlAmplitude: 22.0,
              swirlFrequency: 10.5,
              swirlPhase: _fxRng.nextDouble() * math.pi * 2.0,
              stretchFactor: 1.65,
              rotation: _fxRng.nextDouble() * math.pi,
            ),
          );
        }

      case LvPlatformType.damierCloud:
        // 3. Nuage Damier Amorti: Cushioned cloud puffs expanding outward with strong viscous drag & buoyant float
        const List<Color> cloudColors = <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFE1F5FE),
          Color(0xFF80D8FF),
        ];
        for (int i = 0; i < 10; i++) {
          final double side = i.isEven ? 1.0 : -1.0;
          final double vx = side * (55.0 + _fxRng.nextDouble() * 75.0);
          final double vy = 8.0 + _fxRng.nextDouble() * 36.0;
          final double life = 0.44 + _fxRng.nextDouble() * 0.16;
          particles.add(
            BlossomParticle(
              x: impactX + (_fxRng.nextDouble() - 0.5) * 24.0,
              y: plat.y,
              vx: vx,
              vy: vy,
              size: 6.5 + _fxRng.nextDouble() * 4.0,
              color: cloudColors[i % cloudColors.length],
              life: life,
              maxLife: life,
              shape: PlatformParticleShape.cloudCushionPuff,
              gravityScale: -0.20,
              drag: 5.2,
              rotation: _fxRng.nextDouble() * math.pi,
            ),
          );
        }

      case LvPlatformType.silkBlossomFragile:
        // 4. Pétale de Soie Éphémère: Fluttering silk petals with feather-light gravity & sinusoidal sway
        const List<Color> petalPalette = <Color>[
          Color(0xFFF48FB1),
          Color(0xFFF8BBD0),
          Color(0xFFFFF0F5),
          Color(0xFFFFD700),
        ];
        for (int i = 0; i < 12; i++) {
          final double angle =
              (i / 12.0) * math.pi * 2.0 + _fxRng.nextDouble() * 0.35;
          final double speed = 48.0 + _fxRng.nextDouble() * 78.0;
          final double life = 0.50 + _fxRng.nextDouble() * 0.18;
          particles.add(
            BlossomParticle(
              x: plat.x + (_fxRng.nextDouble() - 0.5) * 34.0,
              y: plat.y,
              vx: math.cos(angle) * speed,
              vy: math.sin(angle) * speed * 0.55 - 24.0,
              size: 5.5 + _fxRng.nextDouble() * 3.8,
              color: petalPalette[i % petalPalette.length],
              life: life,
              maxLife: life,
              isPetal: true,
              shape: PlatformParticleShape.silkPetalFlutter,
              gravityScale: 0.28,
              drag: 1.4,
              swirlAmplitude: 62.0,
              swirlFrequency: 8.8,
              swirlPhase: _fxRng.nextDouble() * math.pi * 2.0,
              rotation: _fxRng.nextDouble() * math.pi,
            ),
          );
        }

      case LvPlatformType.vachettaStrapMoving:
        // 5. Lanière Cuir Vachetta Mobile: Sleek directional velocity streaks coupled to rail momentum
        const List<Color> strapColors = <Color>[
          Color(0xFFE3A17B),
          Color(0xFFFFD700),
          Color(0xFF8B1E24),
        ];
        final double railSlipVx =
            plat.vx.abs() > 1.0 ? -plat.vx * 1.35 : 75.0;
        for (int i = 0; i < 9; i++) {
          final double vx =
              railSlipVx + (_fxRng.nextDouble() - 0.5) * 90.0;
          final double vy = -(52.0 + _fxRng.nextDouble() * 58.0);
          final double life = 0.32 + _fxRng.nextDouble() * 0.14;
          particles.add(
            BlossomParticle(
              x: impactX + (_fxRng.nextDouble() - 0.5) * 22.0,
              y: topY,
              vx: vx,
              vy: vy,
              size: 4.6 + _fxRng.nextDouble() * 2.8,
              color: strapColors[i % strapColors.length],
              life: life,
              maxLife: life,
              shape: PlatformParticleShape.kineticStrapTrail,
              gravityScale: 0.65,
              drag: 2.2,
              stretchFactor: 1.90,
              rotation: math.atan2(vy, vx),
            ),
          );
        }
    }
  }

  void _spawnCelebrationBurst(double cx, double cy, int count) {
    const List<Color> palette = <Color>[
      Color(0xFFFFD700),
      Color(0xFFE3A17B),
      Color(0xFFE5B842),
      Color(0xFFF8BBD0),
    ];
    for (int i = 0; i < count; i++) {
      final double angle = _fxRng.nextDouble() * math.pi * 2.0;
      final double speed = 45.0 + _fxRng.nextDouble() * 160.0;
      particles.add(
        BlossomParticle(
          x: cx,
          y: cy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 55.0,
          size: 4.0 + _fxRng.nextDouble() * 4.0,
          color: palette[i % palette.length],
          life: 0.40 + _fxRng.nextDouble() * 0.30,
          maxLife: 0.70,
          isPetal: i.isEven,
          rotation: _fxRng.nextDouble() * math.pi,
        ),
      );
    }
  }
}
