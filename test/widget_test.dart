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

Future<void> _capturePortraitScreenshot(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outputPath,
) async {
  await tester.pump(const Duration(milliseconds: 32));
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

      // Frame 4 = Anticipation Squash, Frame 6 = Launch Stretch, Frame 60 = Grand Jump 3 Apex
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
    'VivienneJumpEngine handles phone tilt, horizontal wrap-around, platforms & Blossom collection',
    () {
      final VivienneJumpEngine engine = VivienneJumpEngine(seed: 42);
      expect(engine.platforms, isNotEmpty);
      expect(engine.collectibles, isNotEmpty);

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
    'Portrait 1080x2400 UI workflow & 6 high-res screenshots generation',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final Map<VivienneBlenderPose, ui.Image> sprites =
          await tester.runAsync(_loadTestBlenderSprites) ??
          <VivienneBlenderPose, ui.Image>{};

      final VivienneJumpEngine engine = VivienneJumpEngine(seed: 777);
      final GlobalKey repaintKey = GlobalKey();

      await tester.pumpWidget(
        RepaintBoundary(
          key: repaintKey,
          child: VivienneJumpApp(
            engine: engine,
            initialSprites: sprites,
            autoStartTicker: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('VIVIENNE'), findsWidgets);
      expect(find.textContaining('INCLINAISON'), findsOneWidget);

      // Screenshot 1: Atelier d'Asnières Ascent with Star Blossom & Sun Blossom flowers
      for (int i = 0; i < 18; i++) {
        engine.update(1 / 60);
      }
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/01_ascension_atelier_asnieres_blossom.png',
        ),
      );

      // Screenshot 2: Place Vendôme + Grand Saut Blossom (Frame 60) & Speedy Boost + Phone Tilt (+19°)
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

      // Screenshot 3: Jardin Céleste Blossom (3 920 m) with Padlock Shield & Magnet
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

      // Screenshot 4: Maison LV — 4 Éditions de Vivienne & 4 Paliers d'Altitude
      await tester.tap(find.text('MAISON LV'));
      await tester.pump(const Duration(milliseconds: 50));
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

      // Screenshot 5: Herbier Blossom & Trésors Louis Vuitton
      await tester.tap(find.text('HERBIER'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.textContaining('HERBIER BLOSSOM'),
        findsOneWidget,
      );
      await tester.runAsync(
        () => _capturePortraitScreenshot(
          tester,
          repaintKey,
          'screenshots/05_herbier_blossom_et_malles.png',
        ),
      );

      // Screenshot 6: Atelier Blender 3D (vivienne_speedy_v03.blend) & Rig 22 Os
      await tester.tap(find.text('BLENDER 3D'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.textContaining('vivienne_speedy_v03.blend'),
        findsWidgets,
      );
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
