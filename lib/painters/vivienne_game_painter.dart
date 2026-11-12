import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../engine/vivienne_jump_engine.dart';
import '../models/vivienne_models.dart';

/// High-precision 60 FPS Canvas Renderer for `VIVIENNE : L'Odyssée Blossom`.
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

    _paintBiomeBackground(canvas, logicalSize);
    _paintAltitudeMilestones(canvas, logicalSize);
    _paintPlatforms(canvas);
    _paintCollectibles(canvas);
    _paintHazards(canvas);
    _paintParticles(canvas);
    _paintViviennePlayer(canvas);
    _paintCallouts(canvas);

    canvas.restore();
  }

  void _paintBiomeBackground(Canvas canvas, Size size) {
    final LvBiome biome = engine.currentBiome;
    final Rect fullRect = Offset.zero & size;

    final Paint bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        <Color>[biome.topColor, biome.bottomColor],
      );
    canvas.drawRect(fullRect, bgPaint);

    // Subtle radial studio light glow following Vivienne
    final double playerScreenY = (engine.playerY - engine.cameraY).clamp(
      0.0,
      size.height,
    );
    final Paint studioGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(engine.playerX, playerScreenY),
        290.0,
        <Color>[
          biome.horizonGlowColor.withValues(alpha: 0.16),
          biome.accentColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        const <double>[0.0, 0.55, 1.0],
      );
    canvas.drawRect(fullRect, studioGlow);

    // Parallax Louis Vuitton Monogram wallpaper pattern (Star Blossom & Sun Blossom lattice)
    final double parallaxY = -(engine.cameraY * 0.28) % 120.0;
    const double cell = 60.0;
    final Paint patternStroke = Paint()
      ..color = biome.horizonGlowColor.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final Paint patternFill = Paint()
      ..color = biome.horizonGlowColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    for (double y = parallaxY - cell; y < size.height + cell; y += cell) {
      final int row = ((y - parallaxY) / cell).round();
      for (double x = 30.0; x < size.width; x += cell) {
        final int col = (x / cell).round();
        final Offset c = Offset(x, y);
        if ((row + col).isEven) {
          _drawStarBlossomMotif(canvas, c, 12.0, patternFill, patternStroke);
        } else {
          canvas.drawCircle(c, 11.0, patternStroke);
          _drawRoundedBlossomMotif(canvas, c, 8.5, patternFill);
        }
      }
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

    final int firstStep = (math.max(100, minAlt) ~/ 100) * 100;
    for (int alt = firstStep; alt <= maxAlt; alt += 100) {
      if (alt <= 0) continue;
      final double worldY =
          VivienneJumpEngine.worldHeight * 0.72 - alt * 14.0;
      final double screenY = worldY - engine.cameraY;
      if (screenY < -20.0 || screenY > size.height + 20.0) continue;

      final bool isMajor = alt % 500 == 0;
      final Paint linePaint = Paint()
        ..color = isMajor
            ? const Color(0x55FFD700)
            : const Color(0x22E3A17B)
        ..strokeWidth = isMajor ? 1.4 : 0.8;
      canvas.drawLine(
        Offset(16.0, screenY),
        Offset(size.width - 16.0, screenY),
        linePaint,
      );

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: isMajor ? '— PALIER $alt m —' : '$alt m',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: isMajor
                ? const Color(0xCCFFD700)
                : const Color(0x77E3A17B),
            fontSize: isMajor ? 11.0 : 9.5,
            fontWeight: isMajor ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 18.0, screenY - 14.0));
    }
  }

  void _paintPlatforms(Canvas canvas) {
    for (final LvPlatform plat in engine.platforms) {
      if (plat.broken) continue;
      final double sy =
          plat.y - engine.cameraY + plat.bounceCompress * 5.0;
      if (sy < -40.0 || sy > VivienneJumpEngine.worldHeight + 40.0) continue;

      final Rect rect = Rect.fromCenter(
        center: Offset(plat.x, sy),
        width: plat.width,
        height: plat.height,
      );

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
          _paintDamierCloudPlatform(canvas, rect);
      }
    }
  }

  void _paintMonogramTrunkPlatform(
    Canvas canvas,
    Rect rect, {
    required bool hasSpring,
    bool springExtended = false,
  }) {
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    // Drop shadow
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()..color = const Color(0x88000000),
    );
    // Ebony Monogram trunk body (#2B1D14)
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomLeft,
          const <Color>[Color(0xFF3E291C), Color(0xFF23160E)],
        ),
    );
    // Gold brass border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 2 Brass corner plates + center Monogram motifs
    final Paint brassFill = Paint()..color = const Color(0xFFFFD700);
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 2, rect.top + 2, 8, rect.height - 4),
      brassFill,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 10, rect.top + 2, 8, rect.height - 4),
      brassFill,
    );

    final Paint motifFill = Paint()..color = const Color(0xFFBA9367);
    _drawStarBlossomMotif(
      canvas,
      Offset(rect.center.dx - 18.0, rect.center.dy),
      5.0,
      motifFill,
      null,
    );
    _drawRoundedBlossomMotif(
      canvas,
      Offset(rect.center.dx + 18.0, rect.center.dy),
      4.5,
      motifFill,
    );

    if (hasSpring) {
      // Golden LV Trunk Spring Lock on top of the trunk
      final double springH = springExtended ? 18.0 : 10.0;
      final Rect springRect = Rect.fromCenter(
        center: Offset(rect.center.dx, rect.top - springH * 0.5),
        width: 26.0,
        height: springH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(springRect, const Radius.circular(4)),
        Paint()..color = const Color(0xFFFFD700),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top - springH),
          width: 34.0,
          height: 5.0,
        ),
        Paint()..color = const Color(0xFFFFF59D),
      );
    }
  }

  void _paintVachettaStrapPlatform(Canvas canvas, Rect rect) {
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(10),
    );
    // Carmine red edge dye (#8B1E24) characteristic of Vivienne's petals & straps
    canvas.drawRRect(
      rrect.inflate(1.5),
      Paint()..color = const Color(0xFF8B1E24),
    );
    // Vachetta pink-beige leather (#E3A17B)
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomLeft,
          const <Color>[Color(0xFFECB08E), Color(0xFFD48E68)],
        ),
    );
    // Yellow saddle stitches (#E5B842)
    final Paint stitchPaint = Paint()
      ..color = const Color(0xFFE5B842)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (double x = rect.left + 10.0; x < rect.right - 10.0; x += 8.0) {
      canvas.drawLine(
        Offset(x, rect.top + 3.5),
        Offset(x + 4.0, rect.top + 3.5),
        stitchPaint,
      );
      canvas.drawLine(
        Offset(x, rect.bottom - 3.5),
        Offset(x + 4.0, rect.bottom - 3.5),
        stitchPaint,
      );
    }
    // Golden clasps on both ends
    final Paint goldStroke = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(Offset(rect.left + 5.0, rect.center.dy), 4.5, goldStroke);
    canvas.drawCircle(
      Offset(rect.right - 5.0, rect.center.dy),
      4.5,
      goldStroke,
    );
  }

  void _paintSilkBlossomPlatform(Canvas canvas, Rect rect) {
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xCCFCE4EC),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFF48FB1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Fragile crack/petal line indicator
    final Path crack = Path()
      ..moveTo(rect.center.dx - 8, rect.top + 2)
      ..lineTo(rect.center.dx + 3, rect.center.dy)
      ..lineTo(rect.center.dx - 4, rect.bottom - 2);
    canvas.drawPath(
      crack,
      Paint()
        ..color = const Color(0xFFAD1457)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  void _paintDamierCloudPlatform(Canvas canvas, Rect rect) {
    final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          const <Color>[Color(0xFF4A3728), Color(0xFF2E2016)],
        ),
    );
    // Alternating Damier gold squares
    final Paint goldSquare = Paint()..color = const Color(0x55FFD700);
    const double sqW = 14.0;
    for (double x = rect.left + 6.0; x < rect.right - 14.0; x += sqW * 2) {
      canvas.drawRect(
        Rect.fromLTWH(x, rect.top + 3.0, sqW, rect.height * 0.5 - 3.0),
        goldSquare,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          x + sqW,
          rect.center.dy,
          sqW,
          rect.height * 0.5 - 3.0,
        ),
        goldSquare,
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFFFE082)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintCollectibles(Canvas canvas) {
    for (final BlossomCollectible item in engine.collectibles) {
      if (item.collected) continue;
      final double sy =
          item.y - engine.cameraY + math.sin(item.phase) * 4.5;
      if (sy < -50.0 || sy > VivienneJumpEngine.worldHeight + 50.0) continue;

      final Offset center = Offset(item.x, sy);
      // Glowing halo
      canvas.drawCircle(
        center,
        item.radius * 1.38,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            item.radius * 1.38,
            <Color>[
              item.type.primaryColor.withValues(alpha: 0.42),
              Colors.transparent,
            ],
          ),
      );

      switch (item.type) {
        case BlossomItemType.starBlossomGold:
          // Authentic 4-pointed Star Blossom (lv_neo_star_blossom.blend)
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(math.sin(item.phase * 0.7) * 0.18);
          _drawStarBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.95,
            Paint()..color = const Color(0xFFFFD700),
            Paint()
              ..color = const Color(0xFFFFF9C4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
          canvas.drawCircle(
            Offset.zero,
            3.6,
            Paint()..color = const Color(0xFF3E2723),
          );
          canvas.restore();

        case BlossomItemType.sunBlossomCorolla:
          // Authentic 4-rounded-petal Vachetta & Gold Blossom
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(-math.sin(item.phase * 0.6) * 0.15);
          _drawRoundedBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.88,
            Paint()..color = const Color(0xFFE3A17B),
            strokePaint: Paint()
              ..color = const Color(0xFF8B1E24)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
          canvas.drawCircle(
            Offset.zero,
            4.5,
            Paint()..color = const Color(0xFFFFD700),
          );
          canvas.restore();

        case BlossomItemType.neoBlossomDiamond:
          // High-Jewelry Nacre & Diamond Blossom
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(item.phase * 0.35);
          _drawRoundedBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.95,
            Paint()..color = const Color(0xFFF8BBD0),
            strokePaint: Paint()
              ..color = const Color(0xFFFFD700)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0,
          );
          _drawStarBlossomMotif(
            canvas,
            Offset.zero,
            item.radius * 0.62,
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
    // Handles
    final Paint handlePaint = Paint()
      ..color = const Color(0xFFE3A17B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
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
    // Speedy Barrel Body
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.15),
        width: r * 1.45,
        height: r * 1.05,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF2B1D14));
    canvas.drawRRect(
      body,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    _drawStarBlossomMotif(
      canvas,
      Offset(center.dx, center.dy + r * 0.15),
      r * 0.38,
      Paint()..color = const Color(0xFFFFD700),
      null,
    );
  }

  void _paintGoldenPadlockCollectible(Canvas canvas, Offset center, double r) {
    final Paint shackle = Paint()
      ..color = const Color(0xFFFFE082)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
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
      2.6,
      Paint()..color = const Color(0xFF2B1D14),
    );
  }

  void _paintMonogramMagnetCollectible(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(
      center,
      r * 0.95,
      Paint()
        ..color = const Color(0xFF8B1E24)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      r * 0.95,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    _drawStarBlossomMotif(
      canvas,
      center,
      r * 0.65,
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

      // Whirling crimson-gold shear vortex
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
        6.0,
        Paint()..color = const Color(0xFFFFD700),
      );
      canvas.restore();
    }
  }

  void _paintParticles(Canvas canvas) {
    for (final BlossomParticle p in engine.particles) {
      final double sy = p.y - engine.cameraY;
      if (sy < -20.0 || sy > VivienneJumpEngine.worldHeight + 20.0) continue;

      final double alpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      final Paint paint = Paint()
        ..color = p.color.withValues(alpha: alpha);
      if (p.isPetal) {
        canvas.save();
        canvas.translate(p.x, sy);
        canvas.rotate(p.rotation);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.4,
            height: p.size * 0.85,
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(p.x, sy), p.size * 0.6, paint);
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

    // 1. Active Power-up Auras (Padlock Shield / Speedy Boost / Magnet)
    if (engine.padlockShieldTimer > 0.0) {
      final Paint shieldFill = Paint()
        ..color = const Color(0x28FFD700)
        ..style = PaintingStyle.fill;
      final Paint shieldStroke = Paint()
        ..color = const Color(0xCCFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawCircle(Offset.zero, 56.0, shieldFill);
      canvas.drawCircle(Offset.zero, 56.0, shieldStroke);
    }

    if (engine.magnetTimer > 0.0) {
      final double pulseR = 46.0 + (engine.elapsedTime * 45.0) % 28.0;
      canvas.drawCircle(
        Offset.zero,
        pulseR,
        Paint()
          ..color = const Color(0x66E3A17B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Edition subtle golden/rose halo behind Vivienne
    canvas.drawCircle(
      Offset.zero,
      46.0,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          46.0,
          <Color>[
            engine.selectedEdition.accentColor.withValues(alpha: 0.30),
            Colors.transparent,
          ],
        ),
    );

    // 2. Smooth banking rotation from phone tilt + Squash & Stretch from `vivienne_speedy_v03.blend`
    final double tiltBankRad = (engine.effectiveTiltX * 0.24).clamp(
      -0.36,
      0.36,
    );
    canvas.rotate(tiltBankRad);
    canvas.scale(squashScaleX, squashScaleY);

    final ui.Image? spriteImg = blenderSprites[pose] ??
        blenderSprites[VivienneBlenderPose.pose5GrandApex];

    if (spriteImg != null) {
      // Draw the authentic 3D Cycles-rendered sprite from `models/vivienne_speedy_v03.blend`!
      const double drawW = 104.0;
      const double drawH = 108.0;
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
      // High-precision vector fallback matching `vivienne_speedy_v03.blend`
      _paintVivienneVectorFallback(canvas, pose);
    }

    canvas.restore();
  }

  /// High-precision vector rendering of `vivienne_speedy_v03` used synchronously
  /// before async image decoding completes (or in unit tests).
  void _paintVivienneVectorFallback(
    Canvas canvas,
    VivienneBlenderPose pose,
  ) {
    final Color petalColor = engine.selectedEdition.primaryColor;
    final Color edgeColor = engine.selectedEdition.edgeColor;
    const Color woodColor = Color(0xFFC89D7C);
    const Color monogramDark = Color(0xFF2B1D14);
    const Color goldColor = Color(0xFFFFD700);

    // 1. Wooden Monogram Legs & Body (`Vivienne_Body`)
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

    // 2. 4 Corolla Petals (`Vivienne_Petal_Top/Bottom/Left/Right`) with red carmine edges
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

    // 3. Wooden Head (`Vivienne_Head`)
    canvas.drawCircle(
      const Offset(0, -16),
      18.0,
      Paint()..color = woodColor,
    );

    // 4. Right Flower Eye (`Vivienne_Eye_Right_Flower`) + Left Gold Stud Eye
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

    // 5. Raised V-Arms & Mini Speedy LV Bag (`Speedy_Body`)
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

    // Suspended Mini Speedy Bag on right side of screen
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
            color: c.color.withValues(alpha: alpha),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black.withValues(alpha: alpha * 0.85),
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
