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
  static const double springJumpVelocity = -1122.0; // 790 * 1.42
  static const double speedyBoostVelocity = -1420.0;
  static const double maxFallVelocity = 980.0;
  static const double maxHorizontalSpeed = 520.0;

  /// Official curated deterministic seeds selectable in the minimalist UI.
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
  double bestAltitudeMeters = 0.0;
  int score = 0;
  int bestScore = 0;
  int totalBlossomsCollected = 0;
  int runBlossomsCollected = 0;
  int comboCount = 1;
  double comboTimer = 0.0;

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

  // Lifecycle State
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
    resetRun(seed: newSeed);
  }

  /// Cycles to the next curated deterministic seed.
  void cycleNextSeed() {
    final int idx = curatedSeeds.indexOf(_seed);
    final int nextSeed =
        curatedSeeds[(idx + 1) % curatedSeeds.length];
    resetRun(seed: nextSeed);
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
    platforms.removeWhere((LvPlatform p) => p.y > cullBottomY);
    collectibles.removeWhere((BlossomCollectible c) => c.y > cullBottomY);
    hazards.removeWhere((LvAtelierHazard h) => h.y > cullBottomY);
    notifyListeners();
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

    if (playerVy >= 0.0) {
      for (final LvPlatform plat in platforms) {
        if (plat.broken) continue;
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

    // 9. Cull entities far below the camera
    final double cullBottomY = cameraY + worldHeight + 150.0;
    platforms.removeWhere((LvPlatform p) => p.y > cullBottomY);
    collectibles.removeWhere(
      (BlossomCollectible c) => c.collected || c.y > cullBottomY,
    );
    hazards.removeWhere((LvAtelierHazard h) => h.y > cullBottomY);

    // 10. Update particles & floating callouts
    for (final BlossomParticle p in particles) {
      p.x += p.vx * step;
      p.y += p.vy * step;
      p.vy += 180.0 * step;
      p.rotation += 2.5 * step;
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
      }
    }

    notifyListeners();
  }

  void _bounceOnPlatform(LvPlatform plat) {
    plat.bounceCompress = 1.0;
    groundSquashTimer = 0.16;
    totalJumpsInRun++;

    final double impulse =
        baseJumpVelocity *
        plat.type.impulseMultiplier *
        selectedEdition.jumpImpulseMultiplier;
    playerVy = impulse;

    if (plat.type == LvPlatformType.springLockGold) {
      plat.hasSpringTriggered = true;
      grandLeapTimer = math.max(grandLeapTimer, 0.70);
      score += (90 * comboCount * selectedEdition.scoreMultiplier).round();
      callouts.add(
        FloatingCallout(
          text: 'RESSORT ×1.42',
          x: plat.x,
          y: plat.y - 22.0,
          color: const Color(0xFFFFD700),
        ),
      );
      _spawnCelebrationBurst(plat.x, plat.y, 14);
    } else {
      _spawnCelebrationBurst(plat.x, plat.y, 5);
    }

    if (plat.type.singleUse) {
      plat.broken = true;
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

      // Vertical gap computation:
      // - Normal jump reaches ~205.3 px (up to ~248 px on highest edition + cloud).
      // - Spring jump (×1.42) reaches ~414 px (up to ~465 px on highest edition).
      // By choosing:
      // - Normal stepY in [124, 168] px (or [144, 170] px right after a spring step)
      // - Spring stepY in [192, 232] px (when prev is a springLockGold/bonus platform)
      // we guarantee:
      // a) P_{i+1} is ALWAYS vertically reachable from P_i.
      // b) Any 3 consecutive steps sum to >= 372 px (normal) or >= 480 px (after spring),
      //    so P_{i+3} is NEVER within single-jump height! Thus at most 2 platforms above P_i
      //    (<= 3 total in jump reach) can ever be reached.
      final double stepY;
      if (prevHasSpringBonus) {
        stepY = 192.0 + _levelRng.nextDouble() * 40.0; // 192..232 px (requires bonus jump)
        _stepsSinceLastSpring = 0;
      } else if (_stepsSinceLastSpring < 2) {
        stepY = 145.0 + _levelRng.nextDouble() * 23.0; // 145..168 px
        _stepsSinceLastSpring++;
      } else {
        stepY = 124.0 + _levelRng.nextDouble() * 44.0; // 124..168 px
        _stepsSinceLastSpring++;
      }

      _highestGeneratedPlatformY -= stepY;
      final double y = _highestGeneratedPlatformY;
      final double altAtY = math.max(0.0, (worldHeight * 0.72 - y) / 14.0);

      final LvPlatformType type = _pickPlatformTypeForAltitude(
        altAtY,
        prevType: prev.type,
        allowSpring: _stepsSinceLastSpring >= 3,
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

      final double patrolRadius = type.movesHorizontally ? 28.0 : 0.0;
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
        158.0,
        255.0 * math.max(0.28, flightTime - 0.14),
      );
      final double maxAnchorDelta = math.max(
        58.0,
        maxSafeHorizontal - prev.patrolRadius - patrolRadius,
      );
      final double minAnchorDelta = math.min(44.0, maxAnchorDelta - 12.0);
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
  }) {
    final double r = _levelRng.nextDouble();
    if (allowSpring && r < 0.15) {
      return LvPlatformType.springLockGold;
    }
    if (altMeters < 600) {
      if (r < 0.32) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.44) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    } else if (altMeters < 2500) {
      if (r < 0.38) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.54 && prevType != LvPlatformType.silkBlossomFragile) {
        return LvPlatformType.silkBlossomFragile;
      }
      if (r < 0.68) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    } else {
      if (r < 0.42) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.62 && prevType != LvPlatformType.silkBlossomFragile) {
        return LvPlatformType.silkBlossomFragile;
      }
      if (r < 0.78) return LvPlatformType.damierCloud;
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
