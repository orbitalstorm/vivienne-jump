import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../engine/vivienne_jump_engine.dart';
import '../models/vivienne_models.dart';

/// High-precision 60 FPS Canvas Renderer for `VIVIENNE : L'Odyssée Blossom`
/// featuring a multi-layer natural parallax landscape (Sun, Clouds, Mountains,
/// 3 Receding Forest/Hill Ridges, Trees, and Drifting Leaves) and a clean minimalist aesthetic.
class VivienneGamePainter extends CustomPainter {
  VivienneGamePainter({
    required this.engine,
    required this.blenderSprites,
  }) : super(repaint: engine);

  final VivienneJumpEngine engine;
  final Map<VivienneBlenderPose, ui.Image> blenderSprites;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / VivienneJumpEngine.worldWidth;
    final double scaleY = size.height / VivienneJumpEngine.worldHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    const Size logicalSize = Size(
      VivienneJumpEngine.worldWidth,
      VivienneJumpEngine.worldHeight,
    );

    canvas.clipRect(Offset.zero & logicalSize);

    _paintNaturalParallaxBackground(canvas, logicalSize);
    _paintAltitudeMilestones(canvas, logicalSize);
    _paintPlatforms(canvas);
    _paintCollectibles(canvas);
    _paintHazards(canvas);
    _paintParticles(canvas);
    _paintViviennePlayer(canvas);
    _paintCallouts(canvas);

    canvas.restore();
  }

  /// Renders the 6-layer Natural Landscape with multi-plane horizontal & vertical parallax:
  /// 0. Sky dome gradient (daylight azure -> golden sunset -> sakura -> starry alpine)
  /// 1. Radiant Sun (`Soleil`) with atmospheric halos & crepuscular sunbeams (`parallax 0.04`)
  /// 2. Multi-depth volumetric Clouds (`Nuages`) & distant birds (`parallax 0.12 / 0.25 / 0.38`)
  /// 3. Distant Alpine Mountain Range & Valley Mist (`parallax 0.14`)
  /// 4. Far Forest Ridge & Conifer Woods (`parallax 0.22`)
  /// 5. Midground Rolling Hills & Oak/Cypress Trees (`parallax 0.34`)
  /// 6. Foreground Meadow, Detailed Pine & Blossom Trees & Drifting Leaves (`parallax 0.50`)
  void _paintNaturalParallaxBackground(Canvas canvas, Size size) {
    final LvBiome biome = engine.currentBiome;
    final Rect fullRect = Offset.zero & size;

    // Layer 0: Crisp natural sky dome gradient
    final Paint skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        <Color>[
          biome.topColor,
          biome.midSkyColor,
          biome.bottomColor,
        ],
        const <double>[0.0, 0.58, 1.0],
      );
    canvas.drawRect(fullRect, skyPaint);

    // Subtle stars at high altitude
    if (engine.altitudeMeters >= 3000) {
      _paintHighAltitudeStars(canvas, size);
    }

    // Horizontal camera/tilt parallax input centered around middle of screen
    final double horizInput =
        (engine.playerX - size.width * 0.5) + engine.effectiveTiltX * 44.0;
    final double camAltitudePx = -engine.cameraY;

    // Layer 1: Radiant Sun & Sunbeams (Parallax 0.04)
    _paintParallaxSun(canvas, size, biome, horizInput, camAltitudePx);

    // Layer 2A: Far Clouds (Parallax ky = 0.12, kx = 0.07)
    _paintCloudLayer(
      canvas,
      size,
      camAltitudePx: camAltitudePx,
      horizInput: horizInput,
      parallaxY: 0.12,
      parallaxX: 0.07,
      windSpeed: 5.5,
      scale: 0.78,
      opacity: 0.62,
      seedOffset: 11,
      sunColor: biome.sunColor,
    );

    // Layer 3: Distant Mountain Range & Valley Mist (Parallax ky = 0.14, kx = 0.08)
    _paintParallaxMountains(canvas, size, biome, horizInput, camAltitudePx);

    // Layer 2B: Mid-Sky Puffy Clouds (Parallax ky = 0.25, kx = 0.14)
    _paintCloudLayer(
      canvas,
      size,
      camAltitudePx: camAltitudePx,
      horizInput: horizInput,
      parallaxY: 0.25,
      parallaxX: 0.14,
      windSpeed: 10.5,
      scale: 1.0,
      opacity: 0.88,
      seedOffset: 37,
      sunColor: biome.sunColor,
    );

    // Layer 4A: Far Conifer Ridge (Parallax ky = 0.22, kx = 0.12)
    _paintParallaxFarForestRidge(
      canvas,
      size,
      biome,
      horizInput,
      camAltitudePx,
    );

    // Layer 4B: Midground Rolling Hills & Woodland Trees (Parallax ky = 0.34, kx = 0.18)
    _paintParallaxMidgroundHillsAndWoods(
      canvas,
      size,
      biome,
      horizInput,
      camAltitudePx,
    );

    // Layer 2C: Near Passing Cloud Wisps (Parallax ky = 0.38, kx = 0.20)
    _paintCloudLayer(
      canvas,
      size,
      camAltitudePx: camAltitudePx,
      horizInput: horizInput,
      parallaxY: 0.38,
      parallaxX: 0.20,
      windSpeed: 15.0,
      scale: 1.12,
      opacity: 0.45,
      seedOffset: 73,
      sunColor: biome.sunColor,
    );

    // Layer 5A: Ambient Drifting Nature Leaves & Petals in Parallax (ky = 0.44, kx = 0.24)
    _paintParallaxDriftingFoliage(
      canvas,
      size,
      biome,
      horizInput,
      camAltitudePx,
    );

    // Layer 5B: Foreground Meadow Ridge & Detailed Trees (Parallax ky = 0.50, kx = 0.28)
    _paintParallaxForegroundTrees(
      canvas,
      size,
      biome,
      horizInput,
      camAltitudePx,
    );
  }

  void _paintHighAltitudeStars(Canvas canvas, Size size) {
    final double starAlpha =
        ((engine.altitudeMeters - 3000.0) / 3000.0).clamp(0.15, 0.85);
    final Paint starPaint = Paint()
      ..color = Colors.white.withValues(alpha: starAlpha);
    final double py = (-engine.cameraY * 0.05) % 400.0;
    for (int i = 0; i < 24; i++) {
      final double sx = ((i * 73.0 + 29.0) % (size.width - 20.0)) + 10.0;
      final double sy = ((i * 59.0 + py) % 420.0) + 16.0;
      final double r = (i % 3 == 0) ? 1.6 : 1.0;
      canvas.drawCircle(Offset(sx, sy), r, starPaint);
    }
  }

  void _paintParallaxSun(
    Canvas canvas,
    Size size,
    LvBiome biome,
    double horizInput,
    double camAltitudePx,
  ) {
    final double sunX = size.width * 0.76 - horizInput * 0.05;
    final double cyclicShiftY =
        math.sin(camAltitudePx * 0.0008) * 20.0 +
        ((camAltitudePx * 0.04) % 70.0) * 0.32;
    final double sunY = 148.0 + cyclicShiftY;
    final Offset sunCenter = Offset(sunX, sunY);

    // Crepuscular Sunbeams fanning gently across the sky
    canvas.save();
    canvas.translate(sunCenter.dx, sunCenter.dy);
    canvas.rotate(engine.elapsedTime * 0.03);
    for (int i = 0; i < 8; i++) {
      final double angle = i * (math.pi / 4.0);
      canvas.save();
      canvas.rotate(angle);
      final Path ray = Path()
        ..moveTo(0, -8)
        ..lineTo(260, -34)
        ..lineTo(260, 34)
        ..lineTo(0, 8)
        ..close();
      canvas.drawPath(
        ray,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(260, 0),
            <Color>[
              biome.sunColor.withValues(alpha: 0.13),
              biome.sunColor.withValues(alpha: 0.0),
            ],
          ),
      );
      canvas.restore();
    }
    canvas.restore();

    // Outer & inner atmospheric halos
    canvas.drawCircle(
      sunCenter,
      118.0,
      Paint()
        ..shader = ui.Gradient.radial(
          sunCenter,
          118.0,
          <Color>[
            biome.sunColor.withValues(alpha: 0.36),
            biome.horizonGlowColor.withValues(alpha: 0.12),
            Colors.transparent,
          ],
          const <double>[0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      sunCenter,
      56.0,
      Paint()..color = biome.sunColor.withValues(alpha: 0.30),
    );

    // Crisp luminous sun core
    canvas.drawCircle(
      sunCenter,
      34.0,
      Paint()
        ..shader = ui.Gradient.radial(
          sunCenter - const Offset(6, 6),
          38.0,
          <Color>[
            const Color(0xFFFFFFFF),
            biome.sunColor,
            biome.accentColor,
          ],
          const <double>[0.0, 0.65, 1.0],
        ),
    );
  }

  void _paintCloudLayer(
    Canvas canvas,
    Size size, {
    required double camAltitudePx,
    required double horizInput,
    required double parallaxY,
    required double parallaxX,
    required double windSpeed,
    required double scale,
    required double opacity,
    required int seedOffset,
    required Color sunColor,
  }) {
    const double verticalPeriod = 760.0;
    final double scrollY = (camAltitudePx * parallaxY) % verticalPeriod;
    final double scrollX =
        -horizInput * parallaxX + engine.elapsedTime * windSpeed;

    for (int i = 0; i < 4; i++) {
      final double baseX =
          ((i * 145.0 + seedOffset * 29.0 + scrollX) % (size.width + 180.0)) -
          90.0;
      final double rawY =
          (i * 185.0 + seedOffset * 43.0 + scrollY) % verticalPeriod;
      final double cloudY = 82.0 + rawY * 0.65;
      final double cloudW = (84.0 + (i % 3) * 24.0) * scale;
      final double cloudH = (27.0 + (i % 2) * 8.0) * scale;

      _drawStylizedCloud(
        canvas,
        Offset(baseX, cloudY),
        cloudW,
        cloudH,
        opacity: opacity,
        sunTint: sunColor,
      );
    }

    // Subtle distant birds in the mid-sky layer
    if (seedOffset == 37) {
      final Paint birdPaint = Paint()
        ..color = const Color(0xFF264653).withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (int b = 0; b < 3; b++) {
        final double bx =
            ((b * 48.0 + 120.0 + scrollX * 1.2) % (size.width + 80.0)) - 40.0;
        final double by =
            ((190.0 + b * 22.0 + scrollY * 0.5) % 340.0) + 95.0;
        final double wingY = math.sin(engine.elapsedTime * 5.0 + b) * 3.0;
        final Path wing = Path()
          ..moveTo(bx - 7, by + wingY)
          ..quadraticBezierTo(bx - 3, by - 4, bx, by)
          ..quadraticBezierTo(bx + 3, by - 4, bx + 7, by + wingY);
        canvas.drawPath(wing, birdPaint);
      }
    }
  }

  void _drawStylizedCloud(
    Canvas canvas,
    Offset center,
    double width,
    double height, {
    required double opacity,
    required Color sunTint,
  }) {
    final Rect baseRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + height * 0.18),
      width: width,
      height: height * 0.62,
    );
    final RRect baseRRect = RRect.fromRectAndRadius(
      baseRect,
      Radius.circular(height * 0.31),
    );

    canvas.drawRRect(
      baseRRect.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0xFF5C82A6).withValues(alpha: opacity * 0.25),
    );

    final Paint cloudFill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - height * 0.6),
        Offset(center.dx, center.dy + height * 0.5),
        <Color>[
          Colors.white.withValues(alpha: opacity),
          Color.lerp(Colors.white, sunTint, 0.25)!.withValues(
            alpha: opacity * 0.94,
          ),
        ],
      );

    canvas.drawRRect(baseRRect, cloudFill);
    canvas.drawCircle(
      Offset(center.dx - width * 0.22, center.dy - height * 0.04),
      height * 0.42,
      cloudFill,
    );
    canvas.drawCircle(
      Offset(center.dx + width * 0.02, center.dy - height * 0.20),
      height * 0.54,
      cloudFill,
    );
    canvas.drawCircle(
      Offset(center.dx + width * 0.24, center.dy - height * 0.02),
      height * 0.38,
      cloudFill,
    );
  }

  void _paintParallaxMountains(
    Canvas canvas,
    Size size,
    LvBiome biome,
    double horizInput,
    double camAltitudePx,
  ) {
    final double shiftX = -(horizInput * 0.08) % size.width;
    final double verticalBob =
        math.sin(camAltitudePx * 0.0022) * 18.0 +
        ((camAltitudePx * 0.14) % 120.0) * 0.32;
    final double baseHorizonY = size.height - 235.0 + verticalBob;

    final Color mountainBase = biome.mountainColor;
    final Color mountainLight =
        Color.lerp(mountainBase, biome.sunColor, 0.26)!;
    final Color mountainShadow =
        Color.lerp(mountainBase, const Color(0xFF1A2634), 0.26)!;

    for (int tile = -1; tile <= 1; tile++) {
      final double ox = tile * size.width + shiftX;
      final List<(double, double, double)> peaks = <(double, double, double)>[
        (ox + 72.0, baseHorizonY - 122.0, 148.0),
        (ox + 215.0, baseHorizonY - 158.0, 180.0),
        (ox + 355.0, baseHorizonY - 114.0, 142.0),
      ];

      for (final (double px, double py, double halfSpan) in peaks) {
        final Path leftSlope = Path()
          ..moveTo(px, py)
          ..lineTo(px - halfSpan, size.height)
          ..lineTo(px + 12.0, size.height)
          ..close();
        canvas.drawPath(leftSlope, Paint()..color = mountainShadow);

        final Path rightSlope = Path()
          ..moveTo(px, py)
          ..lineTo(px + halfSpan, size.height)
          ..lineTo(px + 12.0, size.height)
          ..close();
        canvas.drawPath(rightSlope, Paint()..color = mountainLight);

        final Path snowCap = Path()
          ..moveTo(px, py)
          ..lineTo(px - halfSpan * 0.21, py + 30.0)
          ..lineTo(px - halfSpan * 0.05, py + 23.0)
          ..lineTo(px + halfSpan * 0.07, py + 32.0)
          ..lineTo(px + halfSpan * 0.22, py + 28.0)
          ..close();
        canvas.drawPath(
          snowCap,
          Paint()..color = Colors.white.withValues(alpha: 0.48),
        );
      }
    }

    // Soft valley mist separating mountains from hills
    final Rect mistRect = Rect.fromLTWH(
      0,
      baseHorizonY - 35.0,
      size.width,
      130.0,
    );
    canvas.drawRect(
      mistRect,
      Paint()
        ..shader = ui.Gradient.linear(
          mistRect.topCenter,
          mistRect.bottomCenter,
          <Color>[
            Colors.transparent,
            biome.bottomColor.withValues(alpha: 0.38),
            Colors.transparent,
          ],
          const <double>[0.0, 0.55, 1.0],
        ),
    );
  }

  /// Far Conifer Forest Ridge (`ky = 0.22, kx = 0.12`) between mountains and midground hills.
  void _paintParallaxFarForestRidge(
    Canvas canvas,
    Size size,
    LvBiome biome,
    double horizInput,
    double camAltitudePx,
  ) {
    final double shiftX = -(horizInput * 0.12) % size.width;
    final double verticalBob =
        ((camAltitudePx * 0.22) % 130.0) * 0.38;
    final double ridgeBaseY = size.height - 190.0 + verticalBob;

    final Color ridgeColor =
        Color.lerp(biome.hillColor, biome.mountainColor, 0.45)!;

    final Path ridgePath = Path()..moveTo(-size.width, size.height);
    for (int tile = -1; tile <= 1; tile++) {
      final double ox = tile * size.width + shiftX;
      ridgePath.lineTo(ox, ridgeBaseY);
      ridgePath.cubicTo(
        ox + size.width * 0.32,
        ridgeBaseY + 22.0,
        ox + size.width * 0.68,
        ridgeBaseY - 34.0,
        ox + size.width,
        ridgeBaseY,
      );
    }
    ridgePath.lineTo(size.width * 2, size.height);
    ridgePath.close();

    canvas.drawPath(ridgePath, Paint()..color = ridgeColor);

    // Distant conifer silhouettes along the far ridge
    for (int tile = -1; tile <= 1; tile++) {
      final double ox = tile * size.width + shiftX;
      for (int t = 0; t < 9; t++) {
        final double u = (t + 0.25) / 9.0;
        final double tx = ox + u * size.width;
        if (tx < -30.0 || tx > size.width + 30.0) continue;
        final double ty =
            ridgeBaseY + math.sin(u * math.pi * 2.0 + 1.2) * 14.0 - 2.0;
        _drawStylizedPineTree(
          canvas,
          Offset(tx, ty),
          scale: 0.54 + (t % 3) * 0.08,
          canopyColor: ridgeColor,
          highlightColor: Color.lerp(ridgeColor, biome.sunColor, 0.18)!,
        );
      }
    }
  }

  void _paintParallaxMidgroundHillsAndWoods(
    Canvas canvas,
    Size size,
    LvBiome biome,
    double horizInput,
    double camAltitudePx,
  ) {
    final double shiftX = -(horizInput * 0.18) % size.width;
    final double verticalBob =
        ((camAltitudePx * 0.34) % 140.0) * 0.42;
    final double hillBaseY = size.height - 148.0 + verticalBob;

    final Color hillTop = Color.lerp(biome.hillColor, biome.sunColor, 0.16)!;
    final Color hillBottom =
        Color.lerp(biome.hillColor, const Color(0xFF14281D), 0.32)!;

    final Path hillPath = Path()..moveTo(-size.width, size.height);
    for (int tile = -1; tile <= 1; tile++) {
      final double ox = tile * size.width + shiftX;
      hillPath.lineTo(ox, hillBaseY);
      hillPath.cubicTo(
        ox + size.width * 0.28,
        hillBaseY - 46.0,
        ox + size.width * 0.62,
        hillBaseY + 24.0,
        ox + size.width,
        hillBaseY,
      );
    }
    hillPath.lineTo(size.width * 2, size.height);
    hillPath.close();

    canvas.drawPath(
      hillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, hillBaseY - 50.0),
          Offset(0, size.height),
          <Color>[hillTop, hillBottom],
        ),
    );

    final Color midTreeColor =
        Color.lerp(biome.treeCanopyColor, biome.hillColor, 0.32)!;
    final Color midTreeHighlight =
        Color.lerp(biome.treeHighlightColor, biome.sunColor, 0.25)!;

    for (int tile = -1; tile <= 1; tile++) {
      final double ox = tile * size.width + shiftX;
      for (int t = 0; t < 7; t++) {
        final double u = (t + 0.4) / 7.0;
        final double tx = ox + u * size.width;
        if (tx < -40.0 || tx > size.width + 40.0) continue;

        final double crestOffset = math.sin(u * math.pi * 2.0) * -20.0;
        final double ty = hillBaseY + crestOffset + 4.0;
        final double treeScale = 0.74 + (t % 3) * 0.12;

        if (t.isEven) {
          _drawStylizedPineTree(
            canvas,
            Offset(tx, ty),
            scale: treeScale,
            canopyColor: midTreeColor,
            highlightColor: midTreeHighlight,
          );
        } else {
          _drawStylizedOakOrBlossomTree(
            canvas,
            Offset(tx, ty),
            scale: treeScale,
            canopyColor: midTreeColor,
            highlightColor: midTreeHighlight,
            hasBlossoms: false,
          );
        }
      }
    }
  }

  /// Gentle parallax leaves and blossom petals drifting in the wind across the sky.
  void _paintParallaxDriftingFoliage(
    Canvas canvas,
    Size size,
    LvBiome biome,
    double horizInput,
    double camAltitudePx,
  ) {
    const double verticalPeriod = 860.0;
    final double scrollY = (camAltitudePx * 0.44) % verticalPeriod;
    final double scrollX =
        -horizInput * 0.24 + engine.elapsedTime * 18.0;

    for (int i = 0; i < 10; i++) {
      final double lx =
          ((i * 89.0 + scrollX) % (size.width + 40.0)) - 20.0;
      final double ly =
          (i * 97.0 + scrollY) % verticalPeriod;
      final double angle = engine.elapsedTime * 1.8 + i * 0.9;
      final Color leafColor = i.isEven
          ? biome.treeHighlightColor.withValues(alpha: 0.45)
          : const Color(0xFFF8BBD0).withValues(alpha: 0.50);

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(angle);
      canvas.drawOval(
        const Rect.fromLTWH(-4.0, -2.0, 8.0, 4.0),
        Paint()..color = leafColor,
      );
      canvas.restore();
    }
  }

  void _paintParallaxForegroundTrees(
    Canvas canvas,
    Size size,
    LvBiome biome,
    double horizInput,
    double camAltitudePx,
  ) {
    final double shiftX = -(horizInput * 0.28) % size.width;
    final double verticalBob =
        ((camAltitudePx * 0.50) % 130.0) * 0.44;
    final double fgBaseY = size.height - 76.0 + verticalBob;

    final Color fgHillTop = biome.treeCanopyColor;
    final Color fgHillBottom =
        Color.lerp(biome.treeCanopyColor, const Color(0xFF0A1810), 0.48)!;

    final Path fgPath = Path()..moveTo(-size.width, size.height);
    for (int tile = -1; tile <= 1; tile++) {
      final double ox = tile * size.width + shiftX;
      fgPath.lineTo(ox, fgBaseY);
      fgPath.cubicTo(
        ox + size.width * 0.35,
        fgBaseY - 32.0,
        ox + size.width * 0.70,
        fgBaseY + 18.0,
        ox + size.width,
        fgBaseY,
      );
    }
    fgPath.lineTo(size.width * 2, size.height);
    fgPath.close();

    canvas.drawPath(
      fgPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, fgBaseY - 35.0),
          Offset(0, size.height),
          <Color>[fgHillTop, fgHillBottom],
        ),
    );

    // Detailed foreground trees (Pins, Chênes & Cerisiers Blossom)
    for (int tile = -1; tile <= 1; tile++) {
      final double ox = tile * size.width + shiftX;
      const List<(double, double, bool)> treeSpecs = <(double, double, bool)>[
        (0.08, 1.18, false),
        (0.24, 0.96, true),
        (0.46, 1.08, false),
        (0.68, 0.92, true),
        (0.88, 1.22, false),
      ];

      for (final (double u, double scale, bool isOakBlossom) in treeSpecs) {
        final double tx = ox + u * size.width;
        if (tx < -50.0 || tx > size.width + 50.0) continue;
        final double ridgeY =
            fgBaseY + math.sin(u * math.pi * 2.0) * -14.0 + 4.0;

        if (isOakBlossom) {
          _drawStylizedOakOrBlossomTree(
            canvas,
            Offset(tx, ridgeY),
            scale: scale,
            canopyColor: biome.treeCanopyColor,
            highlightColor: biome.treeHighlightColor,
            hasBlossoms: true,
          );
        } else {
          _drawStylizedPineTree(
            canvas,
            Offset(tx, ridgeY),
            scale: scale,
            canopyColor: biome.treeCanopyColor,
            highlightColor: biome.treeHighlightColor,
          );
        }
      }
    }
  }

  void _drawStylizedPineTree(
    Canvas canvas,
    Offset baseCenter, {
    required double scale,
    required Color canopyColor,
    required Color highlightColor,
  }) {
    final Rect trunk = Rect.fromCenter(
      center: Offset(baseCenter.dx, baseCenter.dy - 9.0 * scale),
      width: 6.0 * scale,
      height: 20.0 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(trunk, Radius.circular(2.0 * scale)),
      Paint()..color = const Color(0xFF4E342E),
    );

    for (int tier = 0; tier < 3; tier++) {
      final double tierY = baseCenter.dy - (16.0 + tier * 15.0) * scale;
      final double halfW = (22.0 - tier * 4.5) * scale;
      final double h = (24.0 - tier * 3.0) * scale;

      final Path fullCone = Path()
        ..moveTo(baseCenter.dx, tierY - h)
        ..lineTo(baseCenter.dx - halfW, tierY)
        ..lineTo(baseCenter.dx + halfW, tierY)
        ..close();
      canvas.drawPath(fullCone, Paint()..color = canopyColor);

      final Path sunlitHalf = Path()
        ..moveTo(baseCenter.dx, tierY - h)
        ..lineTo(baseCenter.dx + halfW, tierY)
        ..lineTo(baseCenter.dx, tierY)
        ..close();
      canvas.drawPath(
        sunlitHalf,
        Paint()..color = highlightColor.withValues(alpha: 0.55),
      );
    }
  }

  void _drawStylizedOakOrBlossomTree(
    Canvas canvas,
    Offset baseCenter, {
    required double scale,
    required Color canopyColor,
    required Color highlightColor,
    required bool hasBlossoms,
  }) {
    final Paint trunkPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 5.5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      baseCenter,
      Offset(baseCenter.dx, baseCenter.dy - 24.0 * scale),
      trunkPaint,
    );
    final Paint branchPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3.0 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(baseCenter.dx, baseCenter.dy - 16.0 * scale),
      Offset(baseCenter.dx - 10.0 * scale, baseCenter.dy - 26.0 * scale),
      branchPaint,
    );
    canvas.drawLine(
      Offset(baseCenter.dx, baseCenter.dy - 18.0 * scale),
      Offset(baseCenter.dx + 11.0 * scale, baseCenter.dy - 28.0 * scale),
      branchPaint,
    );

    final Offset crownCenter = Offset(
      baseCenter.dx,
      baseCenter.dy - 34.0 * scale,
    );
    final Paint darkCrown = Paint()..color = canopyColor;
    final Paint lightCrown = Paint()..color = highlightColor;

    canvas.drawCircle(
      crownCenter + Offset(-12.0 * scale, 4.0 * scale),
      14.0 * scale,
      darkCrown,
    );
    canvas.drawCircle(
      crownCenter + Offset(12.0 * scale, 4.0 * scale),
      14.0 * scale,
      lightCrown,
    );
    canvas.drawCircle(
      crownCenter + Offset(0.0, -6.0 * scale),
      16.5 * scale,
      darkCrown,
    );
    canvas.drawCircle(
      crownCenter + Offset(5.0 * scale, -8.0 * scale),
      12.5 * scale,
      lightCrown,
    );

    if (hasBlossoms) {
      final Paint blossomDot = Paint()..color = const Color(0xFFF8BBD0);
      canvas.drawCircle(
        crownCenter + Offset(-6.0 * scale, -6.0 * scale),
        2.6 * scale,
        blossomDot,
      );
      canvas.drawCircle(
        crownCenter + Offset(7.0 * scale, -2.0 * scale),
        2.4 * scale,
        blossomDot,
      );
      canvas.drawCircle(
        crownCenter + Offset(2.0 * scale, -11.0 * scale),
        2.2 * scale,
        Paint()..color = const Color(0xFFFFE082),
      );
    }
  }

  void _paintAltitudeMilestones(Canvas canvas, Size size) {
    final int minAlt =
        ((VivienneJumpEngine.worldHeight * 0.72 -
                    (engine.cameraY + size.height)) /
                14.0)
            .floor();
    final int maxAlt =
        ((VivienneJumpEngine.worldHeight * 0.72 - engine.cameraY) / 14.0)
            .ceil();

    final int firstStep = (math.max(250, minAlt) ~/ 250) * 250;
    for (int alt = firstStep; alt <= maxAlt; alt += 250) {
      if (alt <= 0) continue;
      final double worldY =
          VivienneJumpEngine.worldHeight * 0.72 - alt * 14.0;
      final double screenY = worldY - engine.cameraY;
      if (screenY < 80.0 || screenY > size.height - 90.0) continue;

      final Paint tickPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(size.width - 48.0, screenY),
        Offset(size.width - 12.0, screenY),
        tickPaint,
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '$alt m',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 14.0, screenY - 13.0));
    }

    // Horizontal Record Line for the active Seed ("RECORD SEED #...")
    final int seedRecordAlt = engine.bestAltitudeForSeed(engine.seed);
    if (seedRecordAlt > 0) {
      final double recordWorldY =
          VivienneJumpEngine.worldHeight * 0.72 - seedRecordAlt * 14.0;
      final double recordScreenY = recordWorldY - engine.cameraY;
      if (recordScreenY >= 56.0 && recordScreenY <= size.height - 70.0) {
        final Paint glowPaint = Paint()
          ..color = const Color(0x44FFD700)
          ..strokeWidth = 5.0;
        canvas.drawLine(
          Offset(14.0, recordScreenY),
          Offset(size.width - 14.0, recordScreenY),
          glowPaint,
        );

        final Paint dashPaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        for (double dx = 16.0; dx < size.width - 20.0; dx += 12.0) {
          canvas.drawLine(
            Offset(dx, recordScreenY),
            Offset(math.min(dx + 6.5, size.width - 16.0), recordScreenY),
            dashPaint,
          );
        }

        final String recordLabel =
            'RECORD SEED #${engine.seed} • $seedRecordAlt m (${engine.bestScoreForSeed(engine.seed)} pts)';
        final TextPainter recordTp = TextPainter(
          text: TextSpan(
            text: recordLabel,
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF0E1E16),
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final RRect badgeRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            16.0,
            recordScreenY - 16.0,
            recordTp.width + 12.0,
            14.0,
          ),
          const Radius.circular(7),
        );
        canvas.drawRRect(
          badgeRRect,
          Paint()..color = const Color(0xEEFFD700),
        );
        recordTp.paint(canvas, Offset(22.0, recordScreenY - 14.0));
      }
    }
  }

  void _paintPlatforms(Canvas canvas) {
    for (final LvPlatform plat in engine.platforms) {
      if (plat.broken) continue;
      final double sy =
          plat.y - engine.cameraY + plat.bounceCompress * 5.0;
      if (sy < -50.0 || sy > VivienneJumpEngine.worldHeight + 50.0) continue;

      final Rect rect = Rect.fromCenter(
        center: Offset(plat.x, sy),
        width: plat.width,
        height: plat.height,
      );

      if (plat.type.movesHorizontally && plat.patrolRadius > 0) {
        _paintPatrolRail(canvas, plat, sy);
      }

      switch (plat.type) {
        case LvPlatformType.monogramTrunk:
          _paintMonogramTrunkPlatform(canvas, rect, hasSpring: false);
        case LvPlatformType.springLockGold:
          _paintMonogramTrunkPlatform(
            canvas,
            rect,
            hasSpring: true,
            springExtended: plat.hasSpringTriggered || plat.bounceCompress > 0,
          );
        case LvPlatformType.vachettaStrapMoving:
          _paintVachettaStrapPlatform(canvas, rect);
        case LvPlatformType.silkBlossomFragile:
          _paintSilkBlossomPlatform(canvas, rect);
        case LvPlatformType.damierCloud:
          _paintDamierCloudPlatform(
            canvas,
            rect,
            compress: plat.bounceCompress,
          );
      }
    }
  }

  void _paintPatrolRail(Canvas canvas, LvPlatform plat, double sy) {
    final double leftX = plat.anchorX - plat.patrolRadius - 12.0;
    final double rightX = plat.anchorX + plat.patrolRadius + 12.0;
    final Color railColor = plat.type == LvPlatformType.damierCloud
        ? const Color(0xFF80D8FF)
        : const Color(0xFFFFD700);

    final Paint railGlow = Paint()
      ..color = railColor.withValues(alpha: 0.20)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(leftX, sy), Offset(rightX, sy), railGlow);

    final Paint trackPaint = Paint()
      ..color = railColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (double dx = leftX + 6.0; dx < rightX - 6.0; dx += 9.0) {
      canvas.drawLine(
        Offset(dx, sy),
        Offset(math.min(dx + 4.5, rightX - 6.0), sy),
        trackPaint,
      );
    }

    // Directional patrol arrows ◄ and ► at rail bounds
    final Paint arrowPaint = Paint()
      ..color = railColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final Path leftArrow = Path()
      ..moveTo(leftX - 3.0, sy)
      ..lineTo(leftX + 3.5, sy - 3.8)
      ..lineTo(leftX + 3.5, sy + 3.8)
      ..close();
    final Path rightArrow = Path()
      ..moveTo(rightX + 3.0, sy)
      ..lineTo(rightX - 3.5, sy - 3.8)
      ..lineTo(rightX - 3.5, sy + 3.8)
      ..close();
    canvas.drawPath(leftArrow, arrowPaint);
    canvas.drawPath(rightArrow, arrowPaint);
  }

  void _paintMonogramTrunkPlatform(
    Canvas canvas,
    Rect rect, {
    required bool hasSpring,
    bool springExtended = false,
  }) {
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3.8)),
      Paint()..color = const Color(0x52000000),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomLeft,
          hasSpring
              ? const <Color>[Color(0xFF7B5318), Color(0xFF3E260A)]
              : const <Color>[Color(0xFF4A3222), Color(0xFF2B1D14)],
        ),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = hasSpring ? const Color(0xFFFFD700) : const Color(0xFFFFE082)
        ..style = PaintingStyle.stroke
        ..strokeWidth = hasSpring ? 2.0 : 1.6,
    );

    final Paint brassFill = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 3, rect.top + 3, 6, rect.height - 6),
        const Radius.circular(3),
      ),
      brassFill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.right - 9, rect.top + 3, 6, rect.height - 6),
        const Radius.circular(3),
      ),
      brassFill,
    );

    // Perfect Center Bounce target zone (±24% of platform width) on top edge
    final double perfWidth = rect.width * 0.42;
    final RRect perfZone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.top + 2.2),
        width: perfWidth,
        height: 3.2,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      perfZone,
      Paint()..color = const Color(0xDDFFD700),
    );

    if (hasSpring) {
      // Double helical 24K gold spring + luminous upward chevrons ▲▲ + SUPER ×1.45 badge
      final double springH = springExtended ? 18.0 : 10.5;
      final double springTopY = rect.top - springH;

      final Paint coilPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      for (final double coilOffsetX in <double>[-7.0, 7.0]) {
        final double cx = rect.center.dx + coilOffsetX;
        final Path coil = Path()
          ..moveTo(cx - 4.0, rect.top)
          ..lineTo(cx + 4.0, rect.top - springH * 0.33)
          ..lineTo(cx - 4.0, rect.top - springH * 0.66)
          ..lineTo(cx + 4.0, springTopY);
        canvas.drawPath(coil, coilPaint);
      }

      // Golden spring launch pad
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(rect.center.dx, springTopY),
            width: 32.0,
            height: 5.0,
          ),
          const Radius.circular(2.5),
        ),
        Paint()..color = const Color(0xFFFFF59D),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(rect.center.dx, springTopY),
            width: 32.0,
            height: 5.0,
          ),
          const Radius.circular(2.5),
        ),
        Paint()
          ..color = const Color(0xFFFFA000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Animated floating upward chevrons ▲▲ above the spring
      final double bob = math.sin(engine.elapsedTime * 7.5) * 2.2;
      final Paint chevronPaint = Paint()
        ..color = const Color(0xFFFFEA00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (int c = 0; c < 2; c++) {
        final double cy = springTopY - 6.0 - c * 4.8 + bob;
        final Path chev = Path()
          ..moveTo(rect.center.dx - 5.5, cy + 3.0)
          ..lineTo(rect.center.dx, cy - 1.5)
          ..lineTo(rect.center.dx + 5.5, cy + 3.0);
        canvas.drawPath(chev, chevronPaint);
      }
    }
  }

  void _paintVachettaStrapPlatform(Canvas canvas, Rect rect) {
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3.5)),
      Paint()..color = const Color(0x38000000),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomLeft,
          const <Color>[Color(0xFFF3BFA1), Color(0xFFD9926C)],
        ),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF8B1E24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Saddle stitches along top and bottom edges
    final Paint stitchPaint = Paint()
      ..color = const Color(0xFFFFE082)
      ..strokeWidth = 1.1;
    for (double sx = rect.left + 12.0; sx < rect.right - 12.0; sx += 7.0) {
      canvas.drawLine(
        Offset(sx, rect.top + 2.8),
        Offset(sx + 3.2, rect.top + 2.8),
        stitchPaint,
      );
    }

    // Center golden saddle buckle & rivets
    final Paint goldDot = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(rect.left + 7.0, rect.center.dy), 3.0, goldDot);
    canvas.drawCircle(Offset(rect.right - 7.0, rect.center.dy), 3.0, goldDot);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rect.center, width: 12.0, height: 9.0),
        const Radius.circular(2.5),
      ),
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _paintSilkBlossomPlatform(Canvas canvas, Rect rect) {
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3.0)),
      Paint()..color = const Color(0x28000000),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          const <Color>[Color(0xFFFFF0F5), Color(0xFFF8BBD0)],
        ),
    );

    // Dashed fragile border indicating single-use ephemeral platform
    final Paint dashBorder = Paint()
      ..color = const Color(0xFFD81B60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(rrect, dashBorder);

    // Kintsugi gold & crimson cracks across the silk petal platform
    final Path crackMain = Path()
      ..moveTo(rect.center.dx - 12, rect.top + 2)
      ..lineTo(rect.center.dx - 3, rect.center.dy)
      ..lineTo(rect.center.dx + 6, rect.center.dy - 2)
      ..lineTo(rect.center.dx + 12, rect.bottom - 2);
    final Path crackBranch = Path()
      ..moveTo(rect.center.dx - 3, rect.center.dy)
      ..lineTo(rect.center.dx - 9, rect.bottom - 2);
    canvas.drawPath(
      crackMain,
      Paint()
        ..color = const Color(0xFFAD1457)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawPath(
      crackBranch,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintDamierCloudPlatform(
    Canvas canvas,
    Rect rect, {
    double compress = 0.0,
  }) {
    final double squashH = rect.height * (1.0 - compress * 0.25);
    final double stretchW = rect.width * (1.0 + compress * 0.12);
    final Rect cloudRect = Rect.fromCenter(
      center: rect.center,
      width: stretchW,
      height: squashH,
    );
    final RRect rrect = RRect.fromRectAndRadius(
      cloudRect,
      const Radius.circular(11),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 3.5)),
      Paint()..color = const Color(0x33005B9F),
    );

    final Paint cloudFill = Paint()
      ..shader = ui.Gradient.linear(
        cloudRect.topLeft,
        cloudRect.bottomRight,
        const <Color>[Color(0xFFFFFFFF), Color(0xFFB3E5FC)],
      );
    canvas.drawRRect(rrect, cloudFill);

    // Puffy cushioned cloud lobes along the top
    for (final double lobeFactor in <double>[-0.26, 0.0, 0.26]) {
      canvas.drawCircle(
        Offset(
          cloudRect.center.dx + cloudRect.width * lobeFactor,
          cloudRect.top + 2.0,
        ),
        squashH * 0.45,
        cloudFill,
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF00B0FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Downward damped-bounce chevron ▼ above/inside the cloud
    final Path downArrow = Path()
      ..moveTo(cloudRect.center.dx - 4.5, cloudRect.top - 5.0)
      ..lineTo(cloudRect.center.dx + 4.5, cloudRect.top - 5.0)
      ..lineTo(cloudRect.center.dx, cloudRect.top - 0.5)
      ..close();
    canvas.drawPath(
      downArrow,
      Paint()..color = const Color(0xFF00E5FF),
    );
  }

  void _paintCollectibles(Canvas canvas) {
    for (final BlossomCollectible item in engine.collectibles) {
      if (item.collected) continue;
      final double sy =
          item.y - engine.cameraY + math.sin(item.phase) * 3.5;
      if (sy < -40.0 || sy > VivienneJumpEngine.worldHeight + 40.0) continue;

      final Offset center = Offset(item.x, sy);
      canvas.drawCircle(
        center,
        item.radius * 1.25,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            item.radius * 1.25,
            <Color>[
              item.type.primaryColor.withValues(alpha: 0.32),
              Colors.transparent,
            ],
          ),
      );

      switch (item.type) {
        case BlossomItemType.starBlossomGold:
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(math.sin(item.phase * 0.7) * 0.16);
          _drawStarBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.92,
            Paint()..color = const Color(0xFFFFD700),
            Paint()
              ..color = const Color(0xFFFFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4,
          );
          canvas.drawCircle(
            Offset.zero,
            3.0,
            Paint()..color = const Color(0xFF3E2723),
          );
          canvas.restore();

        case BlossomItemType.sunBlossomCorolla:
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(-math.sin(item.phase * 0.6) * 0.14);
          _drawRoundedBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.86,
            Paint()..color = const Color(0xFFE3A17B),
            strokePaint: Paint()
              ..color = const Color(0xFF8B1E24)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
          canvas.drawCircle(
            Offset.zero,
            3.8,
            Paint()..color = const Color(0xFFFFD700),
          );
          canvas.restore();

        case BlossomItemType.neoBlossomDiamond:
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(item.phase * 0.35);
          _drawRoundedBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.92,
            Paint()..color = const Color(0xFFF8BBD0),
            strokePaint: Paint()
              ..color = const Color(0xFFFFD700)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
          _drawStarBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.58,
            Paint()..color = Colors.white,
            null,
          );
          canvas.restore();

        case BlossomItemType.speedyBagBoost:
          _paintMiniSpeedyCollectible(canvas, center, item.radius);

        case BlossomItemType.goldenPadlockShield:
          _paintGoldenPadlockCollectible(canvas, center, item.radius);

        case BlossomItemType.monogramMagnet:
          _paintMonogramMagnetCollectible(canvas, center, item.radius);
      }
    }
  }

  void _paintMiniSpeedyCollectible(Canvas canvas, Offset center, double r) {
    final Paint handlePaint = Paint()
      ..color = const Color(0xFFE3A17B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - r * 0.35),
        width: r * 0.9,
        height: r * 0.9,
      ),
      math.pi,
      math.pi,
      false,
      handlePaint,
    );
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.15),
        width: r * 1.45,
        height: r * 1.05,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2B1D14));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    _drawStarBlossomMotif(
      canvas,
      Offset(center.dx, center.dy + r * 0.15),
      r * 0.36,
      Paint()..color = const Color(0xFFFFD700),
      null,
    );
  }

  void _paintGoldenPadlockCollectible(Canvas canvas, Offset center, double r) {
    final Paint shackle = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - r * 0.25),
        width: r * 0.85,
        height: r * 0.95,
      ),
      math.pi,
      math.pi,
      false,
      shackle,
    );
    final RRect lockBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.2),
        width: r * 1.25,
        height: r * 1.0,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(lockBody, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(
      Offset(center.dx, center.dy + r * 0.2),
      2.4,
      Paint()..color = const Color(0xFF2B1D14),
    );
  }

  void _paintMonogramMagnetCollectible(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r * 0.92,
      Paint()
        ..color = const Color(0xFF8B1E24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      r * 0.92,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    _drawStarBlossomMotif(
      canvas,
      center,
      r * 0.62,
      Paint()..color = const Color(0xFFFFD700),
      null,
    );
  }

  void _paintHazards(Canvas canvas) {
    for (final LvAtelierHazard hazard in engine.hazards) {
      final double sy = hazard.y - engine.cameraY;
      if (sy < -50.0 || sy > VivienneJumpEngine.worldHeight + 50.0) continue;

      final Offset center = Offset(hazard.x, sy);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(hazard.phase);

      for (int i = 0; i < 4; i++) {
        canvas.rotate(math.pi / 2);
        final Path blade = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(
            hazard.radius * 0.5,
            -hazard.radius * 0.35,
            hazard.radius,
            0,
          )
          ..quadraticBezierTo(
            hazard.radius * 0.5,
            hazard.radius * 0.2,
            0,
            0,
          );
        canvas.drawPath(
          blade,
          Paint()..color = const Color(0xFFD32F2F),
        );
      }
      canvas.drawCircle(
        Offset.zero,
        5.5,
        Paint()..color = const Color(0xFFFFD700),
      );
      canvas.restore();
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final BlossomParticle p in engine.particles) {
      final double sy = p.y - engine.cameraY;
      if (sy < -24.0 || sy > VivienneJumpEngine.worldHeight + 24.0) continue;

      final double alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final Paint paint = Paint()..color = p.color.withValues(alpha: alpha);

      switch (p.shape) {
        case PlatformParticleShape.springUpdraftStar:
          canvas.save();
          canvas.translate(p.x, sy);
          canvas.rotate(p.rotation * 0.6);
          canvas.scale(1.0, p.stretchFactor);
          _drawStarBlossomMotif(
            canvas,
            Offset.zero,
            p.size * (0.45 + 0.45 * alpha),
            paint,
            Paint()
              ..color = Colors.white.withValues(alpha: alpha * 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.9,
          );
          canvas.restore();

        case PlatformParticleShape.cloudCushionPuff:
          final double puffRadius = p.size * (0.55 + (1.0 - alpha) * 0.45);
          canvas.drawCircle(
            Offset(p.x, sy),
            puffRadius,
            Paint()..color = p.color.withValues(alpha: alpha * 0.72),
          );
          canvas.drawCircle(
            Offset(p.x - puffRadius * 0.35, sy - puffRadius * 0.2),
            puffRadius * 0.55,
            Paint()..color = Colors.white.withValues(alpha: alpha * 0.80),
          );

        case PlatformParticleShape.silkPetalFlutter:
          canvas.save();
          canvas.translate(p.x, sy);
          canvas.rotate(p.rotation);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 1.45,
              height: p.size * 0.78,
            ),
            paint,
          );
          canvas.restore();

        case PlatformParticleShape.kineticStrapTrail:
          canvas.save();
          canvas.translate(p.x, sy);
          final double velAngle = math.atan2(p.vy, p.vx);
          canvas.rotate(velAngle);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * p.stretchFactor,
                height: p.size * 0.48,
              ),
              Radius.circular(p.size * 0.24),
            ),
            paint,
          );
          canvas.restore();

        case PlatformParticleShape.brassSpark:
          if (p.isPetal) {
            canvas.save();
            canvas.translate(p.x, sy);
            canvas.rotate(p.rotation);
            canvas.drawOval(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 1.35,
                height: p.size * 0.80,
              ),
              paint,
            );
            canvas.restore();
          } else {
            canvas.save();
            canvas.translate(p.x, sy);
            canvas.rotate(p.rotation);
            final double r = p.size * 0.62;
            final Path diamond = Path()
              ..moveTo(0, -r)
              ..lineTo(r * 0.65, 0)
              ..lineTo(0, r)
              ..lineTo(-r * 0.65, 0)
              ..close();
            canvas.drawPath(diamond, paint);
            canvas.restore();
          }
      }
    }
  }

  void _paintViviennePlayer(Canvas canvas) {
    final double sx = engine.playerX;
    final double sy = engine.playerY - engine.cameraY;
    final (
      VivienneBlenderPose pose,
      double squashScaleX,
      double squashScaleY,
    ) = engine.currentBlenderRenderState;

    canvas.save();
    canvas.translate(sx, sy);

    if (engine.padlockShieldTimer > 0.0) {
      final Paint shieldFill = Paint()
        ..color = const Color(0x22FFD700)
        ..style = PaintingStyle.fill;
      final Paint shieldStroke = Paint()
        ..color = const Color(0xBBFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, 52.0, shieldFill);
      canvas.drawCircle(Offset.zero, 52.0, shieldStroke);
    }

    if (engine.magnetTimer > 0.0) {
      final double pulseR = 44.0 + (engine.elapsedTime * 40.0) % 24.0;
      canvas.drawCircle(
        Offset.zero,
        pulseR,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawCircle(
      Offset.zero,
      42.0,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          42.0,
          <Color>[
            Colors.white.withValues(alpha: 0.28),
            Colors.transparent,
          ],
        ),
    );

    final double tiltBankRad = (engine.effectiveTiltX * 0.24).clamp(
      -0.36,
      0.36,
    );
    canvas.rotate(tiltBankRad);
    canvas.scale(squashScaleX, squashScaleY);

    final ui.Image? spriteImg = blenderSprites[pose] ??
        blenderSprites[VivienneBlenderPose.pose5GrandApex];

    if (spriteImg != null) {
      const double drawW = 98.0;
      const double drawH = 102.0;
      final Rect src = Rect.fromLTWH(
        0,
        0,
        spriteImg.width.toDouble(),
        spriteImg.height.toDouble(),
      );
      final Rect dst = Rect.fromCenter(
        center: const Offset(0, -10.0),
        width: drawW,
        height: drawH,
      );
      canvas.drawImageRect(
        spriteImg,
        src,
        dst,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      _paintVivienneVectorFallback(canvas, pose);
    }

    canvas.restore();
  }

  void _paintVivienneVectorFallback(
    Canvas canvas,
    VivienneBlenderPose pose,
  ) {
    final Color petalColor = engine.selectedEdition.primaryColor;
    final Color edgeColor = engine.selectedEdition.edgeColor;
    const Color woodColor = Color(0xFFC89D7C);
    const Color monogramDark = Color(0xFF2B1D14);
    const Color goldColor = Color(0xFFFFD700);

    final RRect leftLeg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-15, 10, 12, 22),
      const Radius.circular(6),
    );
    final RRect rightLeg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 10, 12, 22),
      const Radius.circular(6),
    );
    canvas.drawRRect(leftLeg, Paint()..color = woodColor);
    canvas.drawRRect(rightLeg, Paint()..color = woodColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -4, 32, 18),
        const Radius.circular(7),
      ),
      Paint()..color = woodColor,
    );

    const List<Offset> petalOffsets = <Offset>[
      Offset(0, -34),
      Offset(0, 2),
      Offset(-24, -16),
      Offset(24, -16),
    ];
    for (final Offset po in petalOffsets) {
      canvas.drawCircle(po, 17.5, Paint()..color = edgeColor);
      canvas.drawCircle(po, 16.0, Paint()..color = petalColor);
      canvas.drawCircle(
        po,
        13.8,
        Paint()
          ..color = const Color(0xFFE5B842)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    canvas.drawCircle(
      const Offset(0, -16),
      18.0,
      Paint()..color = woodColor,
    );

    _drawStarBlossomMotif(
      canvas,
      const Offset(-7, -17),
      7.5,
      Paint()..color = monogramDark,
      null,
    );
    canvas.drawCircle(
      const Offset(-7, -17),
      2.0,
      Paint()..color = goldColor,
    );
    canvas.drawCircle(
      const Offset(7, -16),
      2.4,
      Paint()..color = goldColor,
    );

    final bool armsRaised =
        pose == VivienneBlenderPose.pose3Apex ||
        pose == VivienneBlenderPose.pose5GrandApex;
    final Offset leftHand = armsRaised
        ? const Offset(-32, -30)
        : const Offset(-30, -2);
    final Offset rightHand = armsRaised
        ? const Offset(32, -30)
        : const Offset(30, -2);

    final Paint armPaint = Paint()
      ..color = monogramDark
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-14, -10), leftHand, armPaint);
    canvas.drawLine(const Offset(14, -10), rightHand, armPaint);

    final Rect speedyRect = Rect.fromCenter(
      center: Offset(rightHand.dx + 2, rightHand.dy + 12),
      width: 16,
      height: 12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(speedyRect, const Radius.circular(3)),
      Paint()..color = monogramDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(speedyRect, const Radius.circular(3)),
      Paint()
        ..color = goldColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintCallouts(Canvas canvas) {
    for (final FloatingCallout c in engine.callouts) {
      final double sy = c.y - engine.cameraY;
      if (sy < -30.0 || sy > VivienneJumpEngine.worldHeight + 30.0) continue;

      final double alpha = c.life.clamp(0.0, 1.0);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: c.text,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white.withValues(alpha: alpha),
            fontSize: 11.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: alpha * 0.55),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(c.x - tp.width * 0.5, sy));
    }
  }

  void _drawStarBlossomMotif(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fillPaint,
    Paint? strokePaint,
  ) {
    final Path path = Path();
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2.0;
      final Offset tip = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final double aLeft = angle - math.pi / 4.0;
      final double aRight = angle + math.pi / 4.0;
      final Offset ctrlLeft = Offset(
        center.dx + math.cos(aLeft) * (radius * 0.34),
        center.dy + math.sin(aLeft) * (radius * 0.34),
      );
      final Offset ctrlRight = Offset(
        center.dx + math.cos(aRight) * (radius * 0.34),
        center.dy + math.sin(aRight) * (radius * 0.34),
      );
      if (i == 0) {
        path.moveTo(ctrlLeft.dx, ctrlLeft.dy);
      }
      path.quadraticBezierTo(tip.dx, tip.dy, ctrlRight.dx, ctrlRight.dy);
    }
    path.close();
    canvas.drawPath(path, fillPaint);
    if (strokePaint != null) {
      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawRoundedBlossomMotif(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fillPaint, {
    Paint? strokePaint,
  }) {
    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2.0;
      final Offset petalCenter = Offset(
        center.dx + math.cos(angle) * (radius * 0.48),
        center.dy + math.sin(angle) * (radius * 0.48),
      );
      if (strokePaint != null) {
        canvas.drawCircle(petalCenter, radius * 0.52, strokePaint);
      }
      canvas.drawCircle(petalCenter, radius * 0.48, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant VivienneGamePainter oldDelegate) => true;
}
