import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivienne_jump/engine/vivienne_jump_engine.dart';
import 'package:vivienne_jump/main.dart';
import 'package:vivienne_jump/models/vivienne_models.dart';

Future<void> _loadRealFlutterFonts() async {
  final String flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? '/tmp/flutter-sdk/flutter';
  final String fontDir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final Directory dir = Directory(fontDir);
  if (!dir.existsSync()) {
    return;
  }

  final FontLoader robotoLoader = FontLoader('Roboto');
  for (final String file in <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
    'Roboto-Italic.ttf',
    'Roboto-BoldItalic.ttf',
  ]) {
    final File f = File('$fontDir/$file');
    if (f.existsSync()) {
      final Uint8List bytes = f.readAsBytesSync();
      robotoLoader.addFont(
        Future<ByteData>.value(ByteData.view(bytes.buffer)),
      );
    }
  }
  await robotoLoader.load();

  final File materialIconsFile = File('$fontDir/MaterialIcons-Regular.otf');
  if (materialIconsFile.existsSync()) {
    final FontLoader iconsLoader = FontLoader('MaterialIcons');
    final Uint8List bytes = materialIconsFile.readAsBytesSync();
    iconsLoader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await iconsLoader.load();
  }
}

Future<Map<VivienneBlenderPose, ui.Image>> _loadTestBlenderSprites() async {
  final Map<VivienneBlenderPose, ui.Image> map =
      <VivienneBlenderPose, ui.Image>{};
  for (final VivienneBlenderPose pose in VivienneBlenderPose.values) {
    final File f = File(pose.assetPath);
    if (await f.exists()) {
      final Uint8List bytes = await f.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      map[pose] = frame.image;
    }
  }
  return map;
}

Future<List<ui.Image?>> _loadTestTurntableSprites() async {
  final List<ui.Image?> list = List<ui.Image?>.filled(
    VivienneTurntableSpec.frameCount,
    null,
  );
  for (int i = 0; i < VivienneTurntableSpec.frameCount; i++) {
    final File f = File(VivienneTurntableSpec.assetPathForIndex(i));
    if (await f.exists()) {
      final Uint8List bytes = await f.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      list[i] = frame.image;
    }
  }
  return list;
}

Future<void> _capturePortraitScreenshot(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outputPath,
) async {
  await tester.pump(const Duration(milliseconds: 260));
  final RenderRepaintBoundary boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  final File outFile = File(outputPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(byteData!.buffer.asUint8List());
}

void main() {
  setUpAll(() async {
    await _loadRealFlutterFonts();
  });

  test(
    'Blender Hermite spline kinematics conserve volume and cover 3 jumps (72 frames)',
    () {
      for (int f = 1; f <= 72; f++) {
        final VivienneBlenderKinematics k =
            VivienneBlenderKinematics.evaluateAtFrame(f.toDouble());
        final double volume = k.sxBody * k.sxBody * k.szBody;
        expect(volume, closeTo(1.0, 1e-4));
        expect(k.szBody, inInclusiveRange(0.78, 1.20));
      }

      final VivienneBlenderKinematics f4 =
          VivienneBlenderKinematics.evaluateAtFrame(4.0);
      final VivienneBlenderKinematics f6 =
          VivienneBlenderKinematics.evaluateAtFrame(6.0);
      final VivienneBlenderKinematics f60 =
          VivienneBlenderKinematics.evaluateAtFrame(60.0);

      expect(f4.szBody, lessThan(0.86));
      expect(f6.szBody, greaterThan(1.12));
      expect(f60.jumpIndex, equals(2));
      expect(f60.recommendedPose, equals(VivienneBlenderPose.pose5GrandApex));
      expect(f60.armRaise, greaterThan(0.95));
    },
  );

  test(
    '5 Platform archetypes expose distinct multipliers, single-use shatter, and Seed Leaderboard API',
    () {
      expect(LvPlatformType.monogramTrunk.impulseMultiplier, closeTo(1.00, 1e-6));
      expect(LvPlatformType.springLockGold.impulseMultiplier, closeTo(1.45, 1e-6));
      expect(LvPlatformType.damierCloud.impulseMultiplier, closeTo(0.85, 1e-6));
      expect(LvPlatformType.vachettaStrapMoving.impulseMultiplier, closeTo(1.14, 1e-6));
      expect(LvPlatformType.silkBlossomFragile.singleUse, isTrue);
      expect(LvPlatformType.silkBlossomFragile.impulseMultiplier, closeTo(1.06, 1e-6));

      final VivienneJumpEngine engine = VivienneJumpEngine(seed: 777);
      expect(engine.bestEntriesBySeed.length, greaterThanOrEqualTo(5));
      expect(engine.bestScoreForSeed(777), equals(3840));

      // Verify recording a new highscore on Seed #42 updates Seed Highscore & Leaderboard
      engine.recordRunScore(
        customSeed: 42,
        customScore: 5120,
        customAltitudeMeters: 410,
      );
      expect(engine.bestScoreForSeed(42), equals(5120));
      expect(engine.bestAltitudeForSeed(42), equals(410));
      expect(engine.lastRunBeatSeedRecord, isTrue);

      // Verify replaySeed resets run on the targeted seed
      engine.replaySeed(1854);
      expect(engine.seed, equals(1854));
      expect(engine.isInMenu, isFalse);
      expect(engine.isGameOver, isFalse);

      // Verify a platform exiting the bottom of the screen disappears immediately and cannot be bounced on
      final LvPlatform bottomPlat = engine.platforms.first;
      engine.cameraY = bottomPlat.y - VivienneJumpEngine.worldHeight - 2.0;
      engine.playerX = bottomPlat.x;
      engine.playerY = bottomPlat.y - 40.0;
      engine.playerVy = 420.0; // falling down toward off-screen bottomPlat
      engine.update(1 / 60);
      expect(
        engine.platforms.any((LvPlatform p) => p.id == bottomPlat.id),
        isFalse,
      );
      expect(engine.playerVy, greaterThan(0.0)); // did NOT bounce on off-screen platform

      // Verify each of the 5 platform types spawns its dedicated particle physics shape on bounce
      final Map<LvPlatformType, PlatformParticleShape> expectedShapes =
          <LvPlatformType, PlatformParticleShape>{
            LvPlatformType.monogramTrunk: PlatformParticleShape.brassSpark,
            LvPlatformType.springLockGold:
                PlatformParticleShape.springUpdraftStar,
            LvPlatformType.damierCloud: PlatformParticleShape.cloudCushionPuff,
            LvPlatformType.silkBlossomFragile:
                PlatformParticleShape.silkPetalFlutter,
            LvPlatformType.vachettaStrapMoving:
                PlatformParticleShape.kineticStrapTrail,
          };
      for (final MapEntry<LvPlatformType, PlatformParticleShape> entry
          in expectedShapes.entries) {
        engine.resetRun(seed: 777);
        engine.particles.clear();
        final LvPlatform testPlat = LvPlatform(
          id: 9999,
          stepIndex: 99,
          x: 210.0,
          y: 500.0,
          width: 80.0,
          height: 17.0,
          type: entry.key,
          vx: entry.key.movesHorizontally ? 65.0 : 0.0,
        );
        engine.platforms.insert(0, testPlat);
        engine.playerX = 210.0;
        engine.playerY = 500.0 - 17.0 * 0.5 - 35.0;
        engine.playerVy = 260.0;
        engine.update(1 / 60);
        expect(
          engine.particles.any((BlossomParticle p) => p.shape == entry.value),
          isTrue,
          reason: 'Expected ${entry.value} particle on bounce for ${entry.key}',
        );
      }
    },
  );

  test(
    'Deterministic seed generates identical platforms, <= 3 reachable platforms, and 100% reachable next platform',
    () {
      for (final int testSeed in VivienneJumpEngine.curatedSeeds) {
        final VivienneJumpEngine engineA = VivienneJumpEngine(seed: testSeed);
        final VivienneJumpEngine engineB = VivienneJumpEngine(seed: testSeed);

        // Trigger visual particles on engineA to verify FX RNG never perturbs level RNG
        engineA.blossomGauge = 1.0;
        engineA.triggerGrandBlossomLeap();

        // Warp both to generate a deep vertical chain
        engineA.warpToAltitude(2400);
        engineB.warpToAltitude(2400);

        expect(engineA.platforms.length, equals(engineB.platforms.length));
        for (int i = 0; i < engineA.platforms.length; i++) {
          final LvPlatform pa = engineA.platforms[i];
          final LvPlatform pb = engineB.platforms[i];
          expect(pa.stepIndex, equals(pb.stepIndex));
          expect(pa.anchorX, closeTo(pb.anchorX, 1e-6));
          expect(pa.y, closeTo(pb.y, 1e-6));
          expect(pa.width, closeTo(pb.width, 1e-6));
          expect(pa.type, equals(pb.type));
        }

        // Verify reachability and max-3-platforms-in-reach invariants on fresh run
        engineA.resetRun(seed: testSeed);
        // Visible platforms on initial 860px viewport is sparse (<= 8)
        final int visibleOnScreen = engineA.platforms
            .where((LvPlatform p) => p.y >= 0.0 && p.y <= 860.0)
            .length;
        expect(visibleOnScreen, inInclusiveRange(4, 8));

        // Check every platform in the generated buffer (excluding the top-most generated edge)
        for (int i = 0; i < engineA.platforms.length - 3; i++) {
          final LvPlatform current = engineA.platforms[i];
          final LvPlatform next = engineA.platforms[i + 1];

          // 1. Next platform must ALWAYS be reachable (normal jump or spring/bonus jump)
          expect(
            engineA.canReachPlatform(current, next),
            isTrue,
            reason:
                'Seed $testSeed step ${current.stepIndex} -> ${next.stepIndex} must be reachable',
          );

          // 2. At most 3 platforms within jump reach from any platform
          final List<LvPlatform> reachable = engineA.getPlatformsInJumpReach(
            current,
          );
          expect(
            reachable.length,
            inInclusiveRange(1, 3),
            reason:
                'Seed $testSeed step ${current.stepIndex} has ${reachable.length} reachable platforms (expected 1..3)',
          );
        }
      }
    },
  );

  test(
    'VivienneJumpEngine handles phone tilt, horizontal wrap-around, platforms & Blossom collection',
    () {
      final VivienneJumpEngine engine = VivienneJumpEngine(seed: 42);
      expect(engine.platforms, isNotEmpty);

      // Simulate tilting the Android phone to the right (+0.65)
      engine.updateHardwareSensor(0.65, ax: -3.8, ay: 8.9, az: 1.2);
      expect(engine.hardwareSensorActive, isTrue);
      expect(engine.effectiveTiltX, greaterThan(0.5));

      final double startX = engine.playerX;
      for (int i = 0; i < 15; i++) {
        engine.update(1 / 60);
      }
      expect(engine.playerX, greaterThan(startX));

      // Verify zero-calibration
      engine.calibrateTiltZero();
      expect(engine.effectiveTiltX, closeTo(0.0, 1e-5));

      // Verify horizontal wrap-around across Portrait screen edges
      engine.playerX = VivienneJumpEngine.worldWidth - 2.0;
      engine.setManualTilt(1.0);
      for (int i = 0; i < 10; i++) {
        engine.update(1 / 60);
      }
      expect(
        engine.playerX,
        inInclusiveRange(0.0, VivienneJumpEngine.worldWidth),
      );

      // Verify Grand Blossom Leap activation
      engine.blossomGauge = 1.0;
      final bool triggered = engine.triggerGrandBlossomLeap();
      expect(triggered, isTrue);
      expect(engine.grandLeapTimer, greaterThan(1.0));
      expect(engine.playerVy, lessThan(-1000.0));
    },
  );

  testWidgets(
    'Portrait 1080x2400 Cartoon Home Menu (without direct Highscores), Highscores Button/Modal, Galerie Vivienne Turntable 360° & screenshots',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final Map<VivienneBlenderPose, ui.Image> sprites =
          await tester.runAsync(_loadTestBlenderSprites) ??
          <VivienneBlenderPose, ui.Image>{};
      final List<ui.Image?> turntableSprites =
          await tester.runAsync(_loadTestTurntableSprites) ??
          List<ui.Image?>.filled(VivienneTurntableSpec.frameCount, null);

      final VivienneJumpEngine engine = VivienneJumpEngine(seed: 777)
        ..openMainMenu();
      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: repaintKey,
          child: VivienneJumpApp(
            engine: engine,
            initialSprites: sprites,
            initialTurntableSprites: turntableSprites,
            autoStartTicker: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 80));

      // 1. Verify initial Cartoon Home Menu does NOT show the Highscores table directly
      expect(find.byKey(const Key('main_menu_overlay')), findsOneWidget);
      expect(find.byKey(const Key('highscores_modal_overlay')), findsNothing);
      expect(
        find.textContaining('TABLEAU DES SCORES PAR SEED'),
        findsNothing,
      );
      expect(
        find.byKey(const Key('open_highscores_modal_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('start_run_from_menu_button')),
        findsOneWidget,
      );
      expect(find.text('BLENDER 3D'), findsNothing);
      expect(find.textContaining('vivienne_speedy_v03.blend'), findsNothing);
      expect(
        find.textContaining(LvPlatformType.monogramTrunk.shortEffectLabel),
        findsNothing,
      );

      // Capture Cartoon Home Menu (without Highscores table)
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/07_menu_store_leaderboard_seeds.png',
        ),
      );

      // 2. Verify tapping the Highscores button opens the Highscores modal with the Seed Leaderboard
      await tester.tap(find.byKey(const Key('open_highscores_modal_button')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byKey(const Key('highscores_modal_overlay')), findsOneWidget);
      expect(
        find.textContaining('TABLEAU DES SCORES PAR SEED'),
        findsOneWidget,
      );
      expect(find.text('REJOUER CE SEED'), findsWidgets);

      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/09_highscores_modal_leaderboard.png',
        ),
      );

      // Tap "REJOUER CE SEED" on Seed #42 from the Highscores Modal Leaderboard
      final Finder replaySeed42InMenu = find.byKey(
        const Key('menu_replay_seed_42'),
      );
      await tester.ensureVisible(replaySeed42InMenu);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(replaySeed42InMenu);
      await tester.pump(const Duration(milliseconds: 120));
      expect(engine.isInMenu, isFalse);
      expect(engine.isHighscoresOpen, isFalse);
      expect(engine.seed, equals(42));

      // Verify Top HUD Highscores button also opens Highscores Modal directly
      await tester.tap(find.byKey(const Key('open_menu_leaderboard_button')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byKey(const Key('highscores_modal_overlay')), findsOneWidget);
      await tester.tap(find.byKey(const Key('close_highscores_modal_button')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byKey(const Key('highscores_modal_overlay')), findsNothing);

      // 3. Verify Game Over Seed Leaderboard & "REJOUER CE SEED" action
      engine.score = 4150;
      engine.altitudeMeters = 335;
      engine.recordRunScore();
      engine.isGameOver = true;
      engine.notifyListeners();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.byKey(const Key('game_over_overlay')), findsOneWidget);
      expect(find.text('FIN D\'ASCENSION'), findsOneWidget);
      expect(
        find.textContaining('TABLEAU DES SCORES PAR SEED'),
        findsOneWidget,
      );

      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/08_game_over_leaderboard_rejouer_seed.png',
        ),
      );

      final Finder replaySeed777OnGameOver = find.byKey(
        const Key('gameover_replay_seed_777'),
      );
      await tester.ensureVisible(replaySeed777OnGameOver);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(replaySeed777OnGameOver);
      await tester.pump(const Duration(milliseconds: 120));
      expect(engine.isGameOver, isFalse);
      expect(engine.seed, equals(777));

      // Screenshot 1: Clairière Ensoleillée (5 Differentiated Platforms, Parallax & HUD)
      for (int i = 0; i < 16; i++) {
        engine.update(1 / 60);
      }
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/01_ascension_atelier_asnieres_blossom.png',
        ),
      );

      // Screenshot 2: Soleil d'Or (1850m) + Grand Saut Blossom (Frame 60) & Tilt Parallax
      engine.warpToAltitude(1850);
      engine.setManualTilt(0.58);
      engine.speedyBoostTimer = 2.8;
      engine.blossomGauge = 1.0;
      engine.triggerGrandBlossomLeap();
      for (int i = 0; i < 8; i++) {
        engine.update(1 / 60);
      }
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/02_grand_saut_blossom_speedy_boost.png',
        ),
      );

      // Screenshot 3: Vallée Sakura (3920m) with Cherry Blossom Trees & Parallax Clouds
      engine.warpToAltitude(3920);
      engine.setManualTilt(-0.42);
      engine.padlockShieldTimer = 8.5;
      engine.magnetTimer = 6.4;
      engine.runBlossomsCollected = 48;
      engine.comboCount = 6;
      for (int i = 0; i < 12; i++) {
        engine.update(1 / 60);
      }
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/03_jardin_celeste_blossom_straps.png',
        ),
      );

      // Screenshot 4: Maison LV — Seed Selector, 4 Éditions de Vivienne & 4 Paysages Naturels
      await tester.tap(find.text('MAISON LV'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        find.textContaining('4 ÉDITIONS VIVIENNE'),
        findsOneWidget,
      );
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/04_maison_lv_editions_et_mondes.png',
        ),
      );

      // Screenshot 5: Herbier Blossom & 5 Architectures de Plateformes Différenciées
      await tester.tap(find.text('HERBIER'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        find.textContaining('HERBIER BLOSSOM'),
        findsOneWidget,
      );
      expect(find.text(LvPlatformType.monogramTrunk.title), findsOneWidget);
      expect(
        find.textContaining(LvPlatformType.monogramTrunk.shortEffectLabel),
        findsNothing,
      );
      expect(
        find.textContaining(LvPlatformType.monogramTrunk.description),
        findsNothing,
      );
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/05_herbier_blossom_et_malles.png',
        ),
      );

      // 4. Verify Galerie Vivienne Turntable 360° replaces Blender 3D and rotates with phone tilt
      expect(find.text('BLENDER 3D'), findsNothing);
      await tester.tap(find.text('GALERIE VIVIENNE'));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byKey(const Key('vivienne_gallery_panel')), findsOneWidget);
      expect(find.byKey(const Key('vivienne_turntable_stage')), findsOneWidget);
      expect(
        find.textContaining('GALERIE VIVIENNE — TURNTABLE 360°'),
        findsOneWidget,
      );
      expect(find.textContaining('vivienne_speedy_v03.blend'), findsNothing);

      // Reset turntable to 0° then tilt phone to verify 360° gyroscopic turntable rotation
      engine.calibrateTiltZero();
      engine.setTurntableAngle(0.0);
      await tester.pump(const Duration(milliseconds: 40));
      expect(engine.turntableFrameIndex, equals(0));

      engine.updateHardwareSensor(0.65, ax: -3.8, ay: 8.9, az: 1.2);
      engine.updateTurntable(0.2);
      await tester.pump(const Duration(milliseconds: 80));
      expect(engine.turntableAngleDegrees, greaterThan(0.0));
      expect(engine.turntableFrameIndex, isNot(equals(0)));

      // Position at 330° (3/4 view showcasing Vachetta corolla, Monogram eye & Mini Speedy bag) for Screenshot 6
      engine.setTurntableAngle(330.0);
      await tester.pump(const Duration(milliseconds: 60));

      // Screenshot 6: Galerie Vivienne Turntable 360°
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/06_atelier_blender_3d_vivienne_v03.png',
        ),
      );
    },
  );
}
