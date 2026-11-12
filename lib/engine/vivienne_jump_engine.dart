import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../models/vivienne_models.dart';

/// Core 60 FPS Doodle Jump Ascent Engine for `VIVIENNE : L'Odyssée Blossom`.
class VivienneJumpEngine extends ChangeNotifier {
  VivienneJumpEngine({int seed = 20261112}) : _rng = math.Random(seed) {
    resetRun();
  }

  static const double worldWidth = 420.0;
  static const double worldHeight = 860.0;

  static const double gravity = 1520.0;
  static const double baseJumpVelocity = -790.0;
  static const double springJumpVelocity = -1340.0;
  static const double speedyBoostVelocity = -1480.0;
  static const double maxFallVelocity = 980.0;
  static const double maxHorizontalSpeed = 520.0;

  math.Random _rng;
  int _nextEntityId = 1;

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
      // Deep ground anticipation squash -> rapid launch stretch
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
      // Fast upward launch stretch (Frame 6)
      const double sz = 1.12;
      return (
        VivienneBlenderPose.pose2Launch,
        1.0 / math.sqrt(sz),
        sz,
      );
    } else if (playerVy < 160.0) {
      // Near airborne apex (Frame 12 or Frame 60 every 3rd jump!)
      final bool isGrandThirdJump = (totalJumpsInRun % 3 == 0);
      return (
        isGrandThirdJump
            ? VivienneBlenderPose.pose5GrandApex
            : VivienneBlenderPose.pose3Apex,
        1.0,
        1.01,
      );
    } else if (playerVy < 520.0) {
      // Early descent
      return (VivienneBlenderPose.pose3Apex, 0.98, 1.04);
    } else {
      // Fast descent preparing for landing impact (Frame 21)
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
    resetRun();
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

  /// Jumps directly to a target altitude biome (for showcase, testing, or sandbox exploration).
  void warpToAltitude(double targetMeters) {
    resetRun();
    final double deltaPixels = targetMeters * 14.0;
    playerY -= deltaPixels;
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

    platforms.clear();
    collectibles.clear();
    hazards.clear();
    _highestGeneratedPlatformY = playerY + 260.0;

    // Place a guaranteed golden trunk right beneath Vivienne
    platforms.add(
      LvPlatform(
        id: _nextEntityId++,
        x: playerX,
        y: playerY + 45.0,
        width: 106.0,
        height: 20.0,
        type: LvPlatformType.monogramTrunk,
      ),
    );
    _highestGeneratedPlatformY = playerY + 45.0;
    _populatePlatformsUpTo(cameraY - worldHeight * 1.4);
    notifyListeners();
  }

  /// Resets and starts a fresh ascent run.
  void resetRun({int? seed}) {
    if (seed != null) {
      _rng = math.Random(seed);
    }
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

    // 1. Base starting platform right under Vivienne
    final double baseY = worldHeight * 0.78;
    platforms.add(
      LvPlatform(
        id: _nextEntityId++,
        x: worldWidth * 0.5,
        y: baseY,
        width: 118.0,
        height: 20.0,
        type: LvPlatformType.monogramTrunk,
      ),
    );
    // Add 2 side starter trunks so the bottom is welcoming
    platforms.add(
      LvPlatform(
        id: _nextEntityId++,
        x: worldWidth * 0.20,
        y: baseY + 24.0,
        width: 96.0,
        height: 18.0,
        type: LvPlatformType.monogramTrunk,
      ),
    );
    platforms.add(
      LvPlatform(
        id: _nextEntityId++,
        x: worldWidth * 0.80,
        y: baseY + 24.0,
        width: 96.0,
        height: 18.0,
        type: LvPlatformType.monogramTrunk,
      ),
    );

    _highestGeneratedPlatformY = baseY;
    _populatePlatformsUpTo(cameraY - worldHeight * 1.2);

    // Spawn an immediate cluster of Blossom flowers above the start so the player sees collectibles right away
    collectibles.add(
      BlossomCollectible(
        id: _nextEntityId++,
        x: worldWidth * 0.5,
        y: baseY - 120.0,
        type: BlossomItemType.starBlossomGold,
      ),
    );
    collectibles.add(
      BlossomCollectible(
        id: _nextEntityId++,
        x: worldWidth * 0.34,
        y: baseY - 220.0,
        type: BlossomItemType.sunBlossomCorolla,
      ),
    );
    collectibles.add(
      BlossomCollectible(
        id: _nextEntityId++,
        x: worldWidth * 0.68,
        y: baseY - 310.0,
        type: BlossomItemType.neoBlossomDiamond,
      ),
    );

    notifyListeners();
  }

  /// Triggers the active "Éclat Blossom — Grand Saut Célébration (Frame 60)" power!
  bool triggerGrandBlossomLeap() {
    if (isGameOver || isPaused) return false;
    if (blossomGauge < 1.0 && speedyBoostTimer <= 0.0) {
      // Allow activation if gauge >= 0.45 for immediate player fun, scaling intensity
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
    _spawnCelebrationBurst(playerX, playerY, 28);
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

    // Classic Doodle Jump horizontal screen wrap-around!
    if (playerX < 0.0) {
      playerX += worldWidth;
    } else if (playerX > worldWidth) {
      playerX -= worldWidth;
    }

    // 3. Vertical velocity & Speedy Boost / Grand Leap override
    if (speedyBoostTimer > 0.0) {
      playerVy = speedyBoostVelocity;
      if (_rng.nextDouble() < 0.65) {
        particles.add(
          BlossomParticle(
            x: playerX + (_rng.nextDouble() - 0.5) * 34.0,
            y: playerY + 28.0,
            vx: (_rng.nextDouble() - 0.5) * 60.0,
            vy: 140.0 + _rng.nextDouble() * 120.0,
            size: 6.0 + _rng.nextDouble() * 5.0,
            color: const Color(0xFFFFD700),
            life: 0.45,
            maxLife: 0.45,
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

    // 4. Update moving platforms & check one-way downward landing
    for (final LvPlatform plat in platforms) {
      if (plat.bounceCompress > 0.0) {
        plat.bounceCompress = math.max(0.0, plat.bounceCompress - step * 4.5);
      }
      if (plat.type.movesHorizontally && !plat.broken) {
        plat.x += plat.vx * step;
        final double halfW = plat.width * 0.5 + 16.0;
        if (plat.x < halfW) {
          plat.x = halfW;
          plat.vx = plat.vx.abs();
        } else if (plat.x > worldWidth - halfW) {
          plat.x = worldWidth - halfW;
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
        final double hitHalfWidth = plat.width * 0.5 + 22.0;

        if (crossedTop && horizontalDist <= hitHalfWidth) {
          _bounceOnPlatform(plat);
          break;
        }
      }
    }

    // 5. Update & collect Blossom Flowers and LV Maison items
    final double baseCollectRadius =
        48.0 + selectedEdition.magnetRadiusBonus;
    final double activeMagnetRadius = magnetTimer > 0.0 ||
            speedyBoostTimer > 0.0 ||
            grandLeapTimer > 0.0
        ? 235.0
        : baseCollectRadius;

    for (final BlossomCollectible item in collectibles) {
      if (item.collected) continue;
      item.phase += step * 3.4;

      final double dx = playerX - item.x;
      final double dy = playerY - item.y;
      final double dist = math.sqrt(dx * dx + dy * dy);

      if (dist <= activeMagnetRadius && dist > 1.0) {
        final double pullSpeed = dist <= baseCollectRadius ? 420.0 : 560.0;
        item.x += (dx / dist) * pullSpeed * step;
        item.y += (dy / dist) * pullSpeed * step;
      }

      if (dist <= 44.0) {
        _collectBlossomItem(item);
      }
    }

    // 6. Update high-altitude hazards
    for (final LvAtelierHazard hazard in hazards) {
      hazard.phase += step * 4.0;
      hazard.x += hazard.vx * step;
      if (hazard.x < 32.0) {
        hazard.x = 32.0;
        hazard.vx = hazard.vx.abs();
      } else if (hazard.x > worldWidth - 32.0) {
        hazard.x = worldWidth - 32.0;
        hazard.vx = -hazard.vx.abs();
      }

      final double dx = playerX - hazard.x;
      final double dy = playerY - hazard.y;
      final double dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= hazard.radius + 24.0) {
        if (speedyBoostTimer > 0.0 ||
            grandLeapTimer > 0.0 ||
            padlockShieldTimer > 0.0 ||
            playerVy < -600.0) {
          // Neutralize hazard and bounce!
          hazard.y += worldHeight * 2.0;
          score += 150;
          _spawnCelebrationBurst(hazard.x, hazard.y, 14);
          callouts.add(
            FloatingCallout(
              text: 'OBSTACLE DISSIPÉ +150',
              x: playerX,
              y: playerY - 30.0,
              color: const Color(0xFFFFD700),
            ),
          );
        } else {
          // Stomp from above or knockback
          if (playerVy > 0.0 && playerY < hazard.y) {
            playerVy = baseJumpVelocity * 1.15;
            hazard.y += worldHeight * 2.0;
            score += 120;
            _spawnCelebrationBurst(playerX, playerY, 12);
          } else {
            padlockShieldTimer = 2.0;
            playerVy = math.max(playerVy, 240.0);
            callouts.add(
              FloatingCallout(
                text: 'TURBULENCE ! INCLINEZ LE TÉLÉPHONE',
                x: playerX,
                y: playerY - 24.0,
                color: const Color(0xFFFF8A80),
              ),
            );
          }
        }
      }
    }

    // 7. Camera follows Vivienne upward only (classic Doodle Jump one-way camera!)
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

    // 8. Generate new platforms & Blossom flowers above the camera
    _populatePlatformsUpTo(cameraY - worldHeight * 0.95);

    // 9. Cull entities far below the camera
    final double cullBottomY = cameraY + worldHeight + 140.0;
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
      c.life -= step * 1.15;
    }
    callouts.removeWhere((FloatingCallout c) => c.life <= 0.0);

    // 11. Check fall below bottom of screen
    if (playerY - cameraY > worldHeight + 70.0) {
      if (padlockShieldTimer > 0.0 || blossomGauge >= 0.85) {
        // Emergency second-chance Golden Malle rescue!
        padlockShieldTimer = 0.0;
        blossomGauge = math.max(0.0, blossomGauge - 0.85);
        playerY = cameraY + worldHeight * 0.78;
        playerVy = springJumpVelocity;
        groundSquashTimer = 0.16;
        callouts.add(
          FloatingCallout(
            text: 'SAUVETAGE MALLE D\'OR !',
            x: playerX,
            y: playerY - 40.0,
            color: const Color(0xFFFFD700),
          ),
        );
        _spawnCelebrationBurst(playerX, playerY, 22);
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
      grandLeapTimer = math.max(grandLeapTimer, 0.75);
      score += (90 * comboCount * selectedEdition.scoreMultiplier).round();
      callouts.add(
        FloatingCallout(
          text: 'RESSORT SERRURE OR ×1.75 !',
          x: plat.x,
          y: plat.y - 24.0,
          color: const Color(0xFFFFD700),
        ),
      );
      _spawnCelebrationBurst(plat.x, plat.y, 18);
    } else {
      _spawnCelebrationBurst(plat.x, plat.y, 7);
    }

    if (plat.type.singleUse) {
      plat.broken = true;
      callouts.add(
        FloatingCallout(
          text: 'EFFEUILLEMENT SOIE',
          x: plat.x,
          y: plat.y - 14.0,
          color: const Color(0xFFF8BBD0),
        ),
      );
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
            text: '+$pts • ${item.type.title.split(' ').take(3).join(' ')}',
            x: item.x,
            y: item.y - 18.0,
            color: item.type.primaryColor,
          ),
        );
      case BlossomItemType.speedyBagBoost:
        speedyBoostTimer = 3.2 * selectedEdition.speedyBoostMultiplier;
        padlockShieldTimer = math.max(padlockShieldTimer, speedyBoostTimer + 1.5);
        callouts.add(
          FloatingCallout(
            text: 'ASCENSION MINI SPEEDY LV !',
            x: item.x,
            y: item.y - 28.0,
            color: const Color(0xFFFFD700),
          ),
        );
      case BlossomItemType.goldenPadlockShield:
        padlockShieldTimer = 10.0;
        callouts.add(
          FloatingCallout(
            text: 'BOUCLIER CADENAS OR (10s)',
            x: item.x,
            y: item.y - 24.0,
            color: const Color(0xFFFFD700),
          ),
        );
      case BlossomItemType.monogramMagnet:
        magnetTimer = 8.0;
        callouts.add(
          FloatingCallout(
            text: 'AIMANT BLOSSOM 360° (8s)',
            x: item.x,
            y: item.y - 24.0,
            color: const Color(0xFFE3A17B),
          ),
        );
    }

    _spawnCelebrationBurst(item.x, item.y, 12);
  }

  void _populatePlatformsUpTo(double minY) {
    while (_highestGeneratedPlatformY > minY) {
      // Guaranteed reachable vertical spacing (64..108 px < max jump height ~205 px)
      final double stepY = 66.0 + _rng.nextDouble() * 40.0;
      _highestGeneratedPlatformY -= stepY;
      final double y = _highestGeneratedPlatformY;
      final double altAtY = math.max(0.0, (worldHeight * 0.72 - y) / 14.0);

      final double margin = 56.0;
      final double x =
          margin + _rng.nextDouble() * (worldWidth - margin * 2.0);

      final LvPlatformType type = _pickPlatformTypeForAltitude(altAtY);
      final double width = switch (type) {
        LvPlatformType.monogramTrunk => 96.0,
        LvPlatformType.vachettaStrapMoving => 92.0,
        LvPlatformType.silkBlossomFragile => 86.0,
        LvPlatformType.springLockGold => 94.0,
        LvPlatformType.damierCloud => 90.0,
      };
      final double speed = type.movesHorizontally
          ? (68.0 + _rng.nextDouble() * 58.0) * (_rng.nextBool() ? 1.0 : -1.0)
          : 0.0;

      final LvPlatform mainPlat = LvPlatform(
        id: _nextEntityId++,
        x: x,
        y: y,
        width: width,
        height: 19.0,
        type: type,
        vx: speed,
      );
      platforms.add(mainPlat);

      // If we spawned a single-use fragile silk petal platform, also spawn a sturdy companion
      // trunk nearby so the player always has a 100% reliable vertical path!
      if (type.singleUse) {
        final double companionX =
            (x + 135.0 + _rng.nextDouble() * 90.0) % (worldWidth - 96.0) + 48.0;
        platforms.add(
          LvPlatform(
            id: _nextEntityId++,
            x: companionX,
            y: y - 14.0,
            width: 92.0,
            height: 19.0,
            type: LvPlatformType.monogramTrunk,
          ),
        );
      }

      // Spawn collectible Blossom Flowers & LV Maison items generously!
      if (_rng.nextDouble() < 0.68) {
        final BlossomItemType itemType = _pickBlossomCollectibleType(altAtY);
        collectibles.add(
          BlossomCollectible(
            id: _nextEntityId++,
            x: x + (_rng.nextDouble() - 0.5) * 32.0,
            y: y - 38.0 - _rng.nextDouble() * 18.0,
            type: itemType,
          ),
        );
      }

      // Occasionally spawn an aerial arc of 3 Star Blossoms between platforms
      if (_rng.nextDouble() < 0.22) {
        final double arcCenterX =
            70.0 + _rng.nextDouble() * (worldWidth - 140.0);
        for (int i = -1; i <= 1; i++) {
          collectibles.add(
            BlossomCollectible(
              id: _nextEntityId++,
              x: (arcCenterX + i * 38.0).clamp(36.0, worldWidth - 36.0),
              y: y - 52.0 - (1 - i.abs()) * 16.0,
              type: i == 0
                  ? BlossomItemType.sunBlossomCorolla
                  : BlossomItemType.starBlossomGold,
            ),
          );
        }
      }

      // Spawn occasional aerial hazard above 900m
      if (altAtY > 900.0 && _rng.nextDouble() < 0.11) {
        hazards.add(
          LvAtelierHazard(
            id: _nextEntityId++,
            x: 60.0 + _rng.nextDouble() * (worldWidth - 120.0),
            y: y - 48.0,
            vx: (_rng.nextBool() ? 1.0 : -1.0) *
                (65.0 + _rng.nextDouble() * 55.0),
          ),
        );
      }
    }
  }

  LvPlatformType _pickPlatformTypeForAltitude(double altMeters) {
    final double r = _rng.nextDouble();
    if (r < 0.14) {
      return LvPlatformType.springLockGold;
    }
    if (altMeters < 600) {
      if (r < 0.30) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.40) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    } else if (altMeters < 2500) {
      if (r < 0.40) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.54) return LvPlatformType.silkBlossomFragile;
      if (r < 0.68) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    } else {
      if (r < 0.45) return LvPlatformType.vachettaStrapMoving;
      if (r < 0.64) return LvPlatformType.silkBlossomFragile;
      if (r < 0.80) return LvPlatformType.damierCloud;
      return LvPlatformType.monogramTrunk;
    }
  }

  BlossomItemType _pickBlossomCollectibleType(double altMeters) {
    final double r = _rng.nextDouble();
    if (r < 0.46) return BlossomItemType.starBlossomGold;
    if (r < 0.74) return BlossomItemType.sunBlossomCorolla;
    if (r < 0.88) return BlossomItemType.neoBlossomDiamond;
    if (r < 0.93) return BlossomItemType.monogramMagnet;
    if (r < 0.97) return BlossomItemType.goldenPadlockShield;
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
      final double angle = _rng.nextDouble() * math.pi * 2.0;
      final double speed = 50.0 + _rng.nextDouble() * 190.0;
      particles.add(
        BlossomParticle(
          x: cx,
          y: cy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 60.0,
          size: 4.5 + _rng.nextDouble() * 5.0,
          color: palette[i % palette.length],
          life: 0.45 + _rng.nextDouble() * 0.35,
          maxLife: 0.80,
          isPetal: i.isEven,
          rotation: _rng.nextDouble() * math.pi,
        ),
      );
    }
  }
}
