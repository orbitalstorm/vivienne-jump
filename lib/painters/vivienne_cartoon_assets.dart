import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Cartoon vector emblems & badges for `VIVIENNE : L'Odyssée Blossom` (`v1.3.0`).
/// Inspired by classic casual mobile games (Angry Birds, Candy Crush) with bold outlines,
/// multi-layered cel-shaded gradients, and sharp specular highlights.
///
/// Each emblem is rendered through a 4-layer high-precision vector protocol:
/// 1. Base drop shadow & thick sticker silhouette (`#2B1105`)
/// 2. Multi-planar material fills (24K gold, crimson velvet, glazed candy, isometric bevels)
/// 3. Sub-assemblies, faceted gems & hierarchical line weights
/// 4. Crisp hard-edged specular highlights (`#FFFFFF`)
enum CartoonEmblemKind {
  trophyCup,
  crownEdition,
  blossomStar,
  cube3DStudio,
  playTriangle,
}

class CartoonEmblemBadge extends StatelessWidget {
  const CartoonEmblemBadge({
    super.key,
    required this.kind,
    this.size = 36.0,
  });

  final CartoonEmblemKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CartoonEmblemPainter(kind: kind),
      ),
    );
  }
}

class _CartoonEmblemPainter extends CustomPainter {
  const _CartoonEmblemPainter({required this.kind});

  final CartoonEmblemKind kind;

  static const Color _kOutlineDark = Color(0xFF2B1105);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    final double r = math.min(size.width, size.height) * 0.44;

    final Paint outerStroke = Paint()
      ..color = _kOutlineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, r * 0.14)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Paint midStroke = Paint()
      ..color = _kOutlineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * 0.095)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final Paint fineStroke = Paint()
      ..color = _kOutlineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, r * 0.065)
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    switch (kind) {
      case CartoonEmblemKind.trophyCup:
        _paintTrophyCup(
          canvas,
          center,
          r,
          outerStroke,
          midStroke,
          fineStroke,
        );
      case CartoonEmblemKind.crownEdition:
        _paintCrownEdition(
          canvas,
          center,
          r,
          outerStroke,
          midStroke,
          fineStroke,
        );
      case CartoonEmblemKind.blossomStar:
        _paintBlossomStar(
          canvas,
          center,
          r,
          outerStroke,
          midStroke,
          fineStroke,
        );
      case CartoonEmblemKind.cube3DStudio:
        _paintCube3DStudio(
          canvas,
          center,
          r,
          outerStroke,
          midStroke,
          fineStroke,
        );
      case CartoonEmblemKind.playTriangle:
        _paintPlayTriangle(
          canvas,
          center,
          r,
          outerStroke,
          midStroke,
        );
    }
  }

  /// 1. TROPHY CUP: 24K Gold Chalice with sculpted volute handles, pedestal,
  /// central embossed star, and hard-edged specular slash.
  void _paintTrophyCup(
    Canvas canvas,
    Offset center,
    double r,
    Paint outerStroke,
    Paint midStroke,
    Paint fineStroke,
  ) {
    final Offset shadowOffset = Offset(0, r * 0.08);

    // Calque 1 : Base shadow & ground ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.88),
        width: r * 1.35,
        height: r * 0.26,
      ),
      Paint()..color = _kOutlineDark.withValues(alpha: 0.32),
    );

    final Path leftHandle = Path()
      ..moveTo(center.dx - r * 0.52, center.dy - r * 0.48)
      ..cubicTo(
        center.dx - r * 1.04,
        center.dy - r * 0.54,
        center.dx - r * 1.08,
        center.dy + r * 0.08,
        center.dx - r * 0.36,
        center.dy + r * 0.06,
      );

    final Path rightHandle = Path()
      ..moveTo(center.dx + r * 0.52, center.dy - r * 0.48)
      ..cubicTo(
        center.dx + r * 1.04,
        center.dy - r * 0.54,
        center.dx + r * 1.08,
        center.dy + r * 0.08,
        center.dx + r * 0.36,
        center.dy + r * 0.06,
      );

    final Path cupBody = Path()
      ..moveTo(center.dx - r * 0.62, center.dy - r * 0.64)
      ..lineTo(center.dx + r * 0.62, center.dy - r * 0.64)
      ..cubicTo(
        center.dx + r * 0.60,
        center.dy + r * 0.06,
        center.dx + r * 0.32,
        center.dy + r * 0.24,
        center.dx,
        center.dy + r * 0.28,
      )
      ..cubicTo(
        center.dx - r * 0.32,
        center.dy + r * 0.24,
        center.dx - r * 0.60,
        center.dy + r * 0.06,
        center.dx - r * 0.62,
        center.dy - r * 0.64,
      )
      ..close();

    // Silhouette drop shadow
    canvas.save();
    canvas.translate(shadowOffset.dx, shadowOffset.dy);
    canvas.drawPath(
      cupBody,
      Paint()..color = _kOutlineDark.withValues(alpha: 0.34),
    );
    canvas.restore();

    final Paint goldMainPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - r * 0.6, center.dy - r * 0.72),
        Offset(center.dx + r * 0.6, center.dy + r * 0.72),
        const <Color>[
          Color(0xFFFFFDE7),
          Color(0xFFFFE57F),
          Color(0xFFFFC107),
          Color(0xFFFF8F00),
        ],
        const <double>[0.0, 0.28, 0.68, 1.0],
      );

    // Calque 2 : Sculpted handles (anses volutes)
    final Paint handleGoldStroke = Paint()
      ..shader = goldMainPaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    final Paint handleOutlineStroke = Paint()
      ..color = _kOutlineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.32
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(leftHandle, handleOutlineStroke);
    canvas.drawPath(rightHandle, handleOutlineStroke);
    canvas.drawPath(leftHandle, handleGoldStroke);
    canvas.drawPath(rightHandle, handleGoldStroke);

    // Stem & collar ring
    final Rect stemRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.42),
      width: r * 0.32,
      height: r * 0.36,
    );
    canvas.drawRect(stemRect, goldMainPaint);
    canvas.drawRect(stemRect, midStroke);

    // Pedestal base (wood + gold step)
    final RRect goldStep = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.58),
        width: r * 0.78,
        height: r * 0.18,
      ),
      Radius.circular(r * 0.08),
    );
    canvas.drawRRect(goldStep, goldMainPaint);
    canvas.drawRRect(goldStep, midStroke);

    final RRect woodPlinth = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.76),
        width: r * 1.04,
        height: r * 0.26,
      ),
      Radius.circular(r * 0.10),
    );
    final Paint plinthGrad = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - r * 0.5, center.dy + r * 0.62),
        Offset(center.dx + r * 0.5, center.dy + r * 0.88),
        const <Color>[
          Color(0xFF6D4C41),
          Color(0xFF3E2723),
          Color(0xFF1B0905),
        ],
        const <double>[0.0, 0.55, 1.0],
      );
    canvas.drawRRect(woodPlinth, plinthGrad);
    canvas.drawRRect(woodPlinth, outerStroke);

    // Gold plaque on pedestal
    final RRect plaque = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.76),
        width: r * 0.54,
        height: r * 0.12,
      ),
      Radius.circular(r * 0.03),
    );
    canvas.drawRRect(plaque, goldMainPaint);
    canvas.drawRRect(plaque, fineStroke);

    // Main chalice bowl with multi-layered shading planes
    canvas.drawPath(cupBody, goldMainPaint);

    canvas.save();
    canvas.clipPath(cupBody);
    // Left sunlit plane
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - r * 0.65,
        center.dy - r * 0.7,
        r * 0.42,
        r * 1.05,
      ),
      Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.48),
    );
    // Right amber shadow plane
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx + r * 0.18,
        center.dy - r * 0.7,
        r * 0.50,
        r * 1.05,
      ),
      Paint()..color = const Color(0xFFD84315).withValues(alpha: 0.35),
    );
    canvas.restore();

    canvas.drawPath(cupBody, outerStroke);

    // Top lip rim
    final RRect lipRim = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - r * 0.64),
        width: r * 1.34,
        height: r * 0.20,
      ),
      Radius.circular(r * 0.10),
    );
    canvas.drawRRect(lipRim, goldMainPaint);
    canvas.drawRRect(lipRim, outerStroke);

    // Calque 3 : Central 5-pointed victory star emblem
    final Path star = _buildStarPath(
      Offset(center.dx, center.dy - r * 0.22),
      5,
      r * 0.28,
      r * 0.13,
    );
    canvas.drawPath(
      star,
      Paint()..color = const Color(0xFFFFFDE7),
    );
    canvas.drawPath(star, fineStroke);

    // Calque 4 : Hard-edged specular highlights
    final Paint specPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * 0.085)
      ..strokeCap = StrokeCap.round;

    final Path cupSpec = Path()
      ..moveTo(center.dx - r * 0.44, center.dy - r * 0.44)
      ..quadraticBezierTo(
        center.dx - r * 0.42,
        center.dy - r * 0.08,
        center.dx - r * 0.24,
        center.dy + r * 0.10,
      );
    canvas.drawPath(cupSpec, specPaint);
    canvas.drawLine(
      Offset(center.dx - r * 0.48, center.dy - r * 0.66),
      Offset(center.dx - r * 0.08, center.dy - r * 0.66),
      specPaint,
    );
  }

  /// 2. CROWN EDITION: Royal Velvet & 24K Gold Crown set with rubies, emeralds,
  /// finial pearls, and central Monogram Blossom crest.
  void _paintCrownEdition(
    Canvas canvas,
    Offset center,
    double r,
    Paint outerStroke,
    Paint midStroke,
    Paint fineStroke,
  ) {
    // Calque 1 : Ground shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.82),
        width: r * 1.54,
        height: r * 0.24,
      ),
      Paint()..color = _kOutlineDark.withValues(alpha: 0.30),
    );

    // Royal crimson velvet cushion inside crown arches
    final Path velvetCap = Path()
      ..moveTo(center.dx - r * 0.66, center.dy + r * 0.34)
      ..cubicTo(
        center.dx - r * 0.76,
        center.dy - r * 0.38,
        center.dx - r * 0.12,
        center.dy - r * 0.52,
        center.dx,
        center.dy - r * 0.18,
      )
      ..cubicTo(
        center.dx + r * 0.12,
        center.dy - r * 0.52,
        center.dx + r * 0.76,
        center.dy - r * 0.38,
        center.dx + r * 0.66,
        center.dy + r * 0.34,
      )
      ..close();

    final Paint velvetGrad = Paint()
      ..shader = ui.Gradient.radial(
        Offset(center.dx - r * 0.15, center.dy - r * 0.22),
        r * 0.95,
        const <Color>[
          Color(0xFFFF5252),
          Color(0xFFD50000),
          Color(0xFF6A001D),
        ],
        const <double>[0.0, 0.58, 1.0],
      );
    canvas.drawPath(velvetCap, velvetGrad);
    canvas.drawPath(velvetCap, midStroke);

    // Calque 2 : Golden 3-peak crown body
    final Path crown = Path()
      ..moveTo(center.dx - r * 0.74, center.dy + r * 0.44)
      ..lineTo(center.dx - r * 0.88, center.dy - r * 0.32)
      ..lineTo(center.dx - r * 0.34, center.dy + r * 0.04)
      ..lineTo(center.dx, center.dy - r * 0.64)
      ..lineTo(center.dx + r * 0.34, center.dy + r * 0.04)
      ..lineTo(center.dx + r * 0.88, center.dy - r * 0.32)
      ..lineTo(center.dx + r * 0.74, center.dy + r * 0.44)
      ..close();

    final Paint crownGrad = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - r * 0.68),
        Offset(center.dx, center.dy + r * 0.58),
        const <Color>[
          Color(0xFFFFFDE7),
          Color(0xFFFFD54F),
          Color(0xFFFF8F00),
          Color(0xFFC65100),
        ],
        const <double>[0.0, 0.35, 0.75, 1.0],
      );

    canvas.drawPath(crown, crownGrad);

    // Multi-planar cel-shaded facets inside crown
    canvas.save();
    canvas.clipPath(crown);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - r * 0.9,
        center.dy - r * 0.7,
        r * 0.65,
        r * 1.2,
      ),
      Paint()..color = const Color(0xFFFFF9C4).withValues(alpha: 0.42),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx + r * 0.22,
        center.dy - r * 0.7,
        r * 0.7,
        r * 1.2,
      ),
      Paint()..color = const Color(0xFFB25900).withValues(alpha: 0.35),
    );
    canvas.restore();

    canvas.drawPath(crown, outerStroke);

    // Jeweled lower circlet band
    final RRect circlet = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + r * 0.48),
        width: r * 1.56,
        height: r * 0.34,
      ),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(circlet, crownGrad);
    canvas.drawRRect(circlet, outerStroke);

    // Calque 3 : Finial gold orbs & precious gems (Ruby + Emeralds + Monogram Flower)
    final List<Offset> orbCenters = <Offset>[
      Offset(center.dx - r * 0.88, center.dy - r * 0.36),
      Offset(center.dx, center.dy - r * 0.68),
      Offset(center.dx + r * 0.88, center.dy - r * 0.36),
    ];
    for (int i = 0; i < orbCenters.length; i++) {
      final double orbRad = i == 1 ? r * 0.13 : r * 0.11;
      canvas.drawCircle(orbCenters[i], orbRad, crownGrad);
      canvas.drawCircle(orbCenters[i], orbRad, midStroke);
    }

    // Center Monogram diamond blossom & ruby core
    final Path centerDiamond = _buildStarPath(
      Offset(center.dx, center.dy + r * 0.04),
      4,
      r * 0.24,
      r * 0.11,
    );
    canvas.drawPath(centerDiamond, Paint()..color = const Color(0xFFFFFDE7));
    canvas.drawPath(centerDiamond, fineStroke);

    // Circlet center Ruby & side Emeralds
    final Offset rubyPos = Offset(center.dx, center.dy + r * 0.48);
    canvas.drawCircle(
      rubyPos,
      r * 0.11,
      Paint()..color = const Color(0xFFFF1744),
    );
    canvas.drawCircle(rubyPos, r * 0.11, fineStroke);

    final Offset leftEmerald = Offset(center.dx - r * 0.42, center.dy + r * 0.48);
    final Offset rightEmerald = Offset(center.dx + r * 0.42, center.dy + r * 0.48);
    final Paint emeraldPaint = Paint()..color = const Color(0xFF00E676);
    canvas.drawCircle(leftEmerald, r * 0.085, emeraldPaint);
    canvas.drawCircle(leftEmerald, r * 0.085, fineStroke);
    canvas.drawCircle(rightEmerald, r * 0.085, emeraldPaint);
    canvas.drawCircle(rightEmerald, r * 0.085, fineStroke);

    // Calque 4 : Hard-edged specular highlights
    final Paint whiteDot = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - r * 0.03, center.dy - r * 0.71),
      r * 0.045,
      whiteDot,
    );
    canvas.drawCircle(
      Offset( rubyPos.dx - r * 0.03, rubyPos.dy - r * 0.03),
      r * 0.035,
      whiteDot,
    );
    canvas.drawLine(
      Offset(center.dx - r * 0.56, center.dy + r * 0.38),
      Offset(center.dx - r * 0.18, center.dy + r * 0.38),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.88)
        ..strokeWidth = math.max(1.1, r * 0.065)
        ..strokeCap = StrokeCap.round,
    );
  }

  /// 3. BLOSSOM STAR: Candy-Crush glazed puffy Monogram Blossom flower-star
  /// with golden calyx rays, pillowed jelly depth, and curved candy glaze highlights.
  void _paintBlossomStar(
    Canvas canvas,
    Offset center,
    double r,
    Paint outerStroke,
    Paint midStroke,
    Paint fineStroke,
  ) {
    // Calque 1 : Drop shadow silhouette
    final Path shadowStar = _buildStarPath(
      Offset(center.dx, center.dy + r * 0.09),
      8,
      r * 0.92,
      r * 0.46,
    );
    canvas.drawPath(
      shadowStar,
      Paint()..color = _kOutlineDark.withValues(alpha: 0.32),
    );

    // Calque 2 : Diagonal golden calyx rays behind the 4 candy petals
    final Path diagonalGoldRays = _buildStarPath(
      center,
      4,
      r * 0.88,
      r * 0.34,
      rotationOffset: math.pi / 4.0,
    );
    final Paint goldRayPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - r * 0.7, center.dy - r * 0.7),
        Offset(center.dx + r * 0.7, center.dy + r * 0.7),
        const <Color>[
          Color(0xFFFFFDE7),
          Color(0xFFFFD54F),
          Color(0xFFFF8F00),
        ],
        const <double>[0.0, 0.5, 1.0],
      );
    canvas.drawPath(diagonalGoldRays, goldRayPaint);
    canvas.drawPath(diagonalGoldRays, outerStroke);

    // 4 Puffy Candy-Glazed Blossom Petals (cardinal axes)
    final Path candyBlossom = Path();
    for (int i = 0; i < 4; i++) {
      final double angle = (i * math.pi / 2.0) - math.pi / 2.0;
      final Offset petalCenter = Offset(
        center.dx + math.cos(angle) * r * 0.40,
        center.dy + math.sin(angle) * r * 0.40,
      );
      candyBlossom.addOval(
        Rect.fromCircle(center: petalCenter, radius: r * 0.44),
      );
    }

    final Paint candyBodyGrad = Paint()
      ..shader = ui.Gradient.radial(
        center - Offset(r * 0.22, r * 0.24),
        r * 1.15,
        const <Color>[
          Color(0xFFFFF0F6),
          Color(0xFFFF80AB),
          Color(0xFFF50057),
          Color(0xFF880E4F),
        ],
        const <double>[0.0, 0.32, 0.72, 1.0],
      );

    canvas.drawPath(candyBlossom, candyBodyGrad);
    canvas.drawPath(candyBlossom, outerStroke);

    // Inner pillowed subsurface candy glow
    for (int i = 0; i < 4; i++) {
      final double angle = (i * math.pi / 2.0) - math.pi / 2.0;
      final Offset petalCenter = Offset(
        center.dx + math.cos(angle) * r * 0.38,
        center.dy + math.sin(angle) * r * 0.38,
      );
      canvas.drawCircle(
        petalCenter,
        r * 0.28,
        Paint()..color = const Color(0xFFFFB2DD).withValues(alpha: 0.45),
      );
    }

    // Calque 3 : Central golden nectar stamen cabochon
    canvas.drawCircle(center, r * 0.32, goldRayPaint);
    canvas.drawCircle(center, r * 0.32, midStroke);

    final Path innerDiamond = _buildStarPath(center, 4, r * 0.22, r * 0.09);
    canvas.drawPath(innerDiamond, Paint()..color = const Color(0xFFFFFDE7));
    canvas.drawPath(innerDiamond, fineStroke);

    // Calque 4 : Hard-edged candy glaze specular arcs
    final Paint glazeArcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.3, r * 0.09)
      ..strokeCap = StrokeCap.round;

    // Top petal glaze arc
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx, center.dy - r * 0.40),
        radius: r * 0.28,
      ),
      -math.pi * 0.85,
      math.pi * 0.55,
      false,
      glazeArcPaint,
    );
    // Left petal glaze arc
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx - r * 0.40, center.dy),
        radius: r * 0.28,
      ),
      -math.pi * 0.85,
      math.pi * 0.55,
      false,
      glazeArcPaint,
    );
    // Center cabochon glint
    canvas.drawCircle(
      Offset(center.dx - r * 0.09, center.dy - r * 0.09),
      r * 0.06,
      Paint()..color = Colors.white,
    );
  }

  /// 4. CUBE 3D STUDIO: Isometric 3D Atelier Cube with three distinct lighting
  /// planes, luminous beveled edges (Y-chamfer), and golden vertex caps.
  void _paintCube3DStudio(
    Canvas canvas,
    Offset center,
    double r,
    Paint outerStroke,
    Paint midStroke,
    Paint fineStroke,
  ) {
    final Offset topVertex = Offset(center.dx, center.dy - r * 0.86);
    final Offset rightTop = Offset(center.dx + r * 0.78, center.dy - r * 0.40);
    final Offset rightBottom = Offset(center.dx + r * 0.78, center.dy + r * 0.44);
    final Offset bottomVertex = Offset(center.dx, center.dy + r * 0.88);
    final Offset leftBottom = Offset(center.dx - r * 0.78, center.dy + r * 0.44);
    final Offset leftTop = Offset(center.dx - r * 0.78, center.dy - r * 0.40);
    final Offset centerVertex = Offset(center.dx, center.dy + r * 0.04);

    // Calque 1 : Isometric cast shadow
    final Path hexOutline = Path()
      ..moveTo(topVertex.dx, topVertex.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(bottomVertex.dx, bottomVertex.dy)
      ..lineTo(leftBottom.dx, leftBottom.dy)
      ..lineTo(leftTop.dx, leftTop.dy)
      ..close();

    canvas.save();
    canvas.translate(0, r * 0.10);
    canvas.drawPath(
      hexOutline,
      Paint()..color = _kOutlineDark.withValues(alpha: 0.34),
    );
    canvas.restore();

    // Calque 2 : Three primary isometric planes
    final Path topFace = Path()
      ..moveTo(topVertex.dx, topVertex.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(centerVertex.dx, centerVertex.dy)
      ..lineTo(leftTop.dx, leftTop.dy)
      ..close();

    final Path leftFace = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..lineTo(centerVertex.dx, centerVertex.dy)
      ..lineTo(bottomVertex.dx, bottomVertex.dy)
      ..lineTo(leftBottom.dx, leftBottom.dy)
      ..close();

    final Path rightFace = Path()
      ..moveTo(centerVertex.dx, centerVertex.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..lineTo(rightBottom.dx, rightBottom.dy)
      ..lineTo(bottomVertex.dx, bottomVertex.dy)
      ..close();

    canvas.drawPath(
      topFace,
      Paint()
        ..shader = ui.Gradient.linear(
          topVertex,
          centerVertex,
          const <Color>[Color(0xFFE0F7FA), Color(0xFF29B6F6)],
        ),
    );
    canvas.drawPath(
      leftFace,
      Paint()
        ..shader = ui.Gradient.linear(
          leftTop,
          bottomVertex,
          const <Color>[Color(0xFF40C4FF), Color(0xFF01579B)],
        ),
    );
    canvas.drawPath(
      rightFace,
      Paint()
        ..shader = ui.Gradient.linear(
          rightTop,
          bottomVertex,
          const <Color>[Color(0xFF7C4DFF), Color(0xFF311B92)],
        ),
    );

    // Calque 3 : Luminous beveled chamfers & internal Y-junction outlines
    final Paint bevelGlow = Paint()
      ..color = const Color(0xFF84FFFF).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, r * 0.16)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path yBevel = Path()
      ..moveTo(leftTop.dx, leftTop.dy)
      ..lineTo(centerVertex.dx, centerVertex.dy)
      ..lineTo(rightTop.dx, rightTop.dy)
      ..moveTo(centerVertex.dx, centerVertex.dy)
      ..lineTo(bottomVertex.dx, bottomVertex.dy);

    canvas.drawPath(yBevel, bevelGlow);
    canvas.drawPath(yBevel, midStroke);
    canvas.drawPath(hexOutline, outerStroke);

    // Golden Studio center vertex node & top star motif
    final Paint goldNode = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(centerVertex, r * 0.14, goldNode);
    canvas.drawCircle(centerVertex, r * 0.14, fineStroke);

    // Calque 4 : Hard-edged specular highlights on beveled edges
    final Paint specStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, r * 0.07)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(
        ui.lerpDouble(leftTop.dx, centerVertex.dx, 0.22)!,
        ui.lerpDouble(leftTop.dy, centerVertex.dy, 0.22)!,
      ),
      Offset(
        ui.lerpDouble(leftTop.dx, centerVertex.dx, 0.78)!,
        ui.lerpDouble(leftTop.dy, centerVertex.dy, 0.78)!,
      ),
      specStroke,
    );
    canvas.drawLine(
      Offset(
        ui.lerpDouble(leftTop.dx, topVertex.dx, 0.20)!,
        ui.lerpDouble(leftTop.dy, topVertex.dy, 0.20)!,
      ),
      Offset(
        ui.lerpDouble(leftTop.dx, topVertex.dx, 0.80)!,
        ui.lerpDouble(leftTop.dy, topVertex.dy, 0.80)!,
      ),
      specStroke,
    );
    canvas.drawCircle(
      Offset(centerVertex.dx - r * 0.03, centerVertex.dy - r * 0.03),
      r * 0.04,
      Paint()..color = Colors.white,
    );
  }

  /// 5. PLAY TRIANGLE: Rounded beveled Cartoon Play arrow with warm ivory-gold
  /// multi-planar shading, bold `#2B1105` outline, and crisp top specular edge.
  void _paintPlayTriangle(
    Canvas canvas,
    Offset center,
    double r,
    Paint outerStroke,
    Paint midStroke,
  ) {
    final Path tri = Path()
      ..moveTo(center.dx - r * 0.44, center.dy - r * 0.68)
      ..lineTo(center.dx + r * 0.72, center.dy)
      ..lineTo(center.dx - r * 0.44, center.dy + r * 0.68)
      ..close();

    // Calque 1 : Drop shadow
    canvas.save();
    canvas.translate(0, r * 0.10);
    canvas.drawPath(
      tri,
      Paint()..color = _kOutlineDark.withValues(alpha: 0.35),
    );
    canvas.restore();

    // Calque 2 : Warm ivory-gold multi-planar fill
    final Paint playGrad = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - r * 0.68),
        Offset(center.dx, center.dy + r * 0.68),
        const <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFFFF9C4),
          Color(0xFFFFD54F),
        ],
        const <double>[0.0, 0.62, 1.0],
      );
    canvas.drawPath(tri, playGrad);

    // Lower bevel shadow plane
    final Path bottomBevel = Path()
      ..moveTo(center.dx - r * 0.44, center.dy + r * 0.68)
      ..lineTo(center.dx + r * 0.72, center.dy)
      ..lineTo(center.dx - r * 0.12, center.dy + r * 0.08)
      ..close();
    canvas.drawPath(
      bottomBevel,
      Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.45),
    );

    // Calque 3 : Heavy cartoon outline
    canvas.drawPath(tri, outerStroke);

    // Calque 4 : Crisp specular highlight along upper edge
    canvas.drawLine(
      Offset(center.dx - r * 0.28, center.dy - r * 0.44),
      Offset(center.dx + r * 0.36, center.dy - r * 0.06),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.3, r * 0.09)
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _buildStarPath(
    Offset center,
    int points,
    double outerRadius,
    double innerRadius, {
    double rotationOffset = 0.0,
  }) {
    final Path path = Path();
    final int totalVertices = points * 2;
    for (int i = 0; i < totalVertices; i++) {
      final double angle =
          (i * math.pi / points) - (math.pi / 2.0) + rotationOffset;
      final double rad = i.isEven ? outerRadius : innerRadius;
      final Offset pt = Offset(
        center.dx + math.cos(angle) * rad,
        center.dy + math.sin(angle) * rad,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _CartoonEmblemPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
