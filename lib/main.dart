import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'engine/vivienne_jump_engine.dart';
import 'models/vivienne_models.dart';
import 'painters/vivienne_cartoon_assets.dart';
import 'painters/vivienne_game_painter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF2B1105),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VivienneJumpApp());
}

enum VivienneNavTab {
  ascension,
  editionsAndBiomes,
  blossomHerbarium,
  vivienneGallery,
}

enum GameHapticKind {
  light,
  medium,
  heavy,
  selection,
}

void triggerGameHaptic(GameHapticKind kind) {
  switch (kind) {
    case GameHapticKind.light:
      HapticFeedback.lightImpact();
    case GameHapticKind.medium:
      HapticFeedback.mediumImpact();
    case GameHapticKind.heavy:
      HapticFeedback.heavyImpact();
    case GameHapticKind.selection:
      HapticFeedback.selectionClick();
  }
}

/// Reusable tactile 3D Cartoon Candy button implementing `mobile-game-ui` (Mode B Flutter):
/// - Immediate Squash & Stretch on contact (`AnimatedScale` 0.92, elastic release)
/// - Thick cartoon outline (`#2B1105`, `borderWidth: 2.6`)
/// - Top glossy white specular highlight bar (`gloss highlight`)
/// - Tactile 3D bottom lip (`BoxShadow` with `blurRadius: 0` reduced on press + vertical translation)
/// - Native Haptic Feedback (`HapticFeedback`)
/// - Enforced minimum touch target constraints (`ConstrainedBox`).
class Juicy3DGameButton extends StatefulWidget {
  const Juicy3DGameButton({
    super.key,
    required this.onTap,
    required this.child,
    this.backgroundColor = const Color(0xFFFFD700),
    this.lipColor = const Color(0xFFBF6000),
    this.borderColor = const Color(0xFF2B1105),
    this.borderWidth = 2.6,
    this.borderRadius = 22.0,
    this.lipDepth = 5.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.minWidth = 48.0,
    this.minHeight = 48.0,
    this.haptic = GameHapticKind.light,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color backgroundColor;
  final Color lipColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double lipDepth;
  final EdgeInsetsGeometry padding;
  final double minWidth;
  final double minHeight;
  final GameHapticKind haptic;

  @override
  State<Juicy3DGameButton> createState() => _Juicy3DGameButtonState();
}

class _Juicy3DGameButtonState extends State<Juicy3DGameButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!_isPressed) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
    }
    triggerGameHaptic(widget.haptic);
    widget.onTap();
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double currentLip = _isPressed ? 0.0 : widget.lipDepth;
    final double translateY = _isPressed ? widget.lipDepth : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minWidth,
          minHeight: widget.minHeight,
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: Duration(milliseconds: _isPressed ? 70 : 180),
          curve: _isPressed ? Curves.easeOutCubic : Curves.elasticOut,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.borderColor,
                  width: widget.borderWidth,
                ),
                boxShadow: <BoxShadow>[
                  if (currentLip > 0)
                    BoxShadow(
                      color: widget.lipColor,
                      blurRadius: 0,
                      offset: Offset(0, currentLip),
                    ),
                  if (currentLip > 0)
                    BoxShadow(
                      color: const Color(0x552B1105),
                      blurRadius: 4,
                      offset: Offset(0, currentLip + 2.0),
                    ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Top Cartoon Glossy Specular Highlight
                  Positioned(
                    top: 2.5,
                    left: 10,
                    right: 10,
                    height: 5.5,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouncy Cartoon Modal Wrapper (`Curves.elasticOut`) for Angry Birds / Candy Crush feel.
class CartoonBouncyModal extends StatelessWidget {
  const CartoonBouncyModal({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFFFF8E7),
    this.borderColor = const Color(0xFF2B1105),
    this.lipColor = const Color(0xFF4A1800),
    this.borderRadius = 28.0,
    this.lipDepth = 6.5,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final Color lipColor;
  final double borderRadius;
  final double lipDepth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.90, end: 1.0),
        duration: const Duration(milliseconds: 210),
        curve: Curves.elasticOut,
        builder: (BuildContext context, double scale, Widget? content) {
          return Transform.scale(
            scale: scale,
            child: content,
          );
        },
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 3.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: lipColor,
                blurRadius: 0,
                offset: Offset(0, lipDepth),
              ),
              BoxShadow(
                color: const Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, lipDepth + 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Purely visual particle effect pill for the Herbarium platform cards (no text description).
class CartoonParticleEffectVisualPill extends StatelessWidget {
  const CartoonParticleEffectVisualPill({
    super.key,
    required this.platformType,
  });

  final LvPlatformType platformType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF2B1105),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: platformType.accentColor,
          width: 2.0,
        ),
      ),
      child: CustomPaint(
        painter: _PlatformParticlePreviewPainter(platformType: platformType),
      ),
    );
  }
}

class _PlatformParticlePreviewPainter extends CustomPainter {
  const _PlatformParticlePreviewPainter({required this.platformType});

  final LvPlatformType platformType;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width * 0.5, size.height * 0.5);
    switch (platformType) {
      case LvPlatformType.monogramTrunk:
        // Brass 4-point diamond sparks
        for (final Offset offset in <Offset>[
          const Offset(-16, 2),
          const Offset(0, -3),
          const Offset(16, 2),
        ]) {
          _drawDiamondSpark(
            canvas,
            c + offset,
            5.5,
            const Color(0xFFFFD700),
          );
        }
      case LvPlatformType.springLockGold:
        // Ascending 24K gold stars + updraft lines
        final Paint linePaint = Paint()
          ..color = const Color(0xFFFFF59D)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(c + const Offset(-14, 7), c + const Offset(-14, -5), linePaint);
        canvas.drawLine(c + const Offset(14, 7), c + const Offset(14, -5), linePaint);
        _drawDiamondSpark(canvas, c + const Offset(0, -2), 7.0, const Color(0xFFFFD700));
        _drawDiamondSpark(canvas, c + const Offset(-14, -6), 4.5, const Color(0xFFFFF59D));
        _drawDiamondSpark(canvas, c + const Offset(14, -6), 4.5, const Color(0xFFFFF59D));
      case LvPlatformType.damierCloud:
        // Soft cushioned cloud puffs
        final Paint puffPaint = Paint()..color = const Color(0xFFB3E5FC);
        final Paint whitePaint = Paint()..color = Colors.white;
        canvas.drawCircle(c + const Offset(-14, 2), 6.0, puffPaint);
        canvas.drawCircle(c + const Offset(14, 2), 6.0, puffPaint);
        canvas.drawCircle(c + const Offset(0, -1), 7.5, whitePaint);
      case LvPlatformType.silkBlossomFragile:
        // Fluttering silk petals
        final Paint petalPaint = Paint()..color = const Color(0xFFF48FB1);
        for (final Offset offset in <Offset>[
          const Offset(-15, -2),
          const Offset(0, 3),
          const Offset(15, -1),
        ]) {
          canvas.save();
          canvas.translate(c.dx + offset.dx, c.dy + offset.dy);
          canvas.rotate(offset.dx * 0.04);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: 9.0, height: 5.5),
            petalPaint,
          );
          canvas.restore();
        }
      case LvPlatformType.vachettaStrapMoving:
        // Sleek horizontal velocity streaks
        final Paint trailPaint = Paint()
          ..color = const Color(0xFFE3A17B)
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round;
        final Paint goldTrail = Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(c + const Offset(-20, -4), c + const Offset(12, -4), trailPaint);
        canvas.drawLine(c + const Offset(-12, 1), c + const Offset(20, 1), goldTrail);
        canvas.drawLine(c + const Offset(-18, 6), c + const Offset(8, 6), trailPaint);
    }
  }

  void _drawDiamondSpark(Canvas canvas, Offset center, double r, Color color) {
    final Path path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * 0.65, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r * 0.65, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlatformParticlePreviewPainter oldDelegate) =>
      oldDelegate.platformType != platformType;
}

/// Isolated interpolated numerical ticker wrapped in a `RepaintBoundary`
/// so high-frequency score/altitude increments never repaint the entire HUD.
class InterpolatedHudTicker extends StatelessWidget {
  const InterpolatedHudTicker({
    super.key,
    required this.value,
    required this.formatter,
    required this.style,
  });

  final double value;
  final String Function(double interpolatedValue) formatter;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double animatedVal, Widget? _) {
          return Text(
            formatter(animatedVal),
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        },
      ),
    );
  }
}

class VivienneJumpApp extends StatelessWidget {
  const VivienneJumpApp({
    super.key,
    this.engine,
    this.initialSprites,
    this.initialTurntableSprites,
    this.autoStartTicker = true,
  });

  final VivienneJumpEngine? engine;
  final Map<VivienneBlenderPose, ui.Image>? initialSprites;
  final List<ui.Image?>? initialTurntableSprites;
  final bool autoStartTicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIVIENNE : L\'Odyssée Blossom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF29B6F6),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFFF4081),
          surface: Color(0xFFFFF8E7),
        ),
        useMaterial3: true,
      ),
      home: VivienneJumpHomeScreen(
        engine: engine,
        initialSprites: initialSprites,
        initialTurntableSprites: initialTurntableSprites,
        autoStartTicker: autoStartTicker,
      ),
    );
  }
}

class VivienneJumpHomeScreen extends StatefulWidget {
  const VivienneJumpHomeScreen({
    super.key,
    this.engine,
    this.initialSprites,
    this.initialTurntableSprites,
    this.autoStartTicker = true,
  });

  final VivienneJumpEngine? engine;
  final Map<VivienneBlenderPose, ui.Image>? initialSprites;
  final List<ui.Image?>? initialTurntableSprites;
  final bool autoStartTicker;

  @override
  State<VivienneJumpHomeScreen> createState() => _VivienneJumpHomeScreenState();
}

class _VivienneJumpHomeScreenState extends State<VivienneJumpHomeScreen>
    with SingleTickerProviderStateMixin {
  static const EventChannel _tiltEventChannel = EventChannel(
    'cloud.orbital8.vivienne_jump/tilt',
  );

  late final VivienneJumpEngine _engine;
  late final bool _ownsEngine;
  late final TextEditingController _customSeedController;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  StreamSubscription<dynamic>? _tiltSubscription;

  final Map<VivienneBlenderPose, ui.Image> _blenderSprites =
      <VivienneBlenderPose, ui.Image>{};
  final List<ui.Image?> _turntableSprites = List<ui.Image?>.filled(
    VivienneTurntableSpec.frameCount,
    null,
  );

  VivienneNavTab _activeTab = VivienneNavTab.ascension;

  @override
  void initState() {
    super.initState();
    _ownsEngine = widget.engine == null;
    _engine = widget.engine ?? (VivienneJumpEngine()..isInMenu = true);
    _customSeedController = TextEditingController(
      text: _engine.seed.toString(),
    );
    if (widget.initialSprites != null) {
      _blenderSprites.addAll(widget.initialSprites!);
    } else {
      _loadBlenderSprites();
    }
    if (widget.initialTurntableSprites != null) {
      for (
        int i = 0;
        i <
            math.min(
              _turntableSprites.length,
              widget.initialTurntableSprites!.length,
            );
        i++
      ) {
        _turntableSprites[i] = widget.initialTurntableSprites![i];
      }
    } else {
      _loadTurntableSprites();
    }
    if (widget.autoStartTicker) {
      _subscribeToHardwareTiltSensor();
      _ticker = createTicker(_onTick)..start();
    }
  }

  Future<void> _loadBlenderSprites() async {
    for (final VivienneBlenderPose pose in VivienneBlenderPose.values) {
      try {
        final ByteData data = await rootBundle.load(pose.assetPath);
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final ui.FrameInfo frame = await codec.getNextFrame();
        if (!mounted) return;
        setState(() {
          _blenderSprites[pose] = frame.image;
        });
      } catch (_) {
        // Vector fallback remains active if asset load is skipped in minimal tests
      }
    }
  }

  Future<void> _loadTurntableSprites() async {
    for (int i = 0; i < VivienneTurntableSpec.frameCount; i++) {
      try {
        final String assetPath = VivienneTurntableSpec.assetPathForIndex(i);
        final ByteData data = await rootBundle.load(assetPath);
        final ui.Codec codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
        );
        final ui.FrameInfo frame = await codec.getNextFrame();
        if (!mounted) return;
        setState(() {
          _turntableSprites[i] = frame.image;
        });
      } catch (_) {
        // Fallback to Image.asset if preloading is skipped in minimal tests
      }
    }
  }

  void _subscribeToHardwareTiltSensor() {
    try {
      _tiltSubscription = _tiltEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is List && event.isNotEmpty) {
            final double tiltX = (event[0] as num).toDouble();
            final double ax = event.length > 1
                ? (event[1] as num).toDouble()
                : 0.0;
            final double ay = event.length > 2
                ? (event[2] as num).toDouble()
                : 9.81;
            final double az = event.length > 3
                ? (event[3] as num).toDouble()
                : 0.0;
            _engine.updateHardwareSensor(tiltX, ax: ax, ay: ay, az: az);
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      // On desktop/test environments without Android sensor service, manual/simulated tilt is used.
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final double dt =
        (elapsed - _lastTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    if (_activeTab == VivienneNavTab.ascension &&
        !_engine.isInMenu &&
        !_engine.isHighscoresOpen) {
      _engine.update(dt);
    } else if (_activeTab == VivienneNavTab.vivienneGallery) {
      _engine.updateTurntable(dt);
    }
  }

  @override
  void dispose() {
    _tiltSubscription?.cancel();
    _ticker?.dispose();
    _customSeedController.dispose();
    if (_ownsEngine) {
      _engine.dispose();
    }
    super.dispose();
  }

  void _selectTab(VivienneNavTab tab) {
    triggerGameHaptic(GameHapticKind.selection);
    if (_engine.isHighscoresOpen) {
      _engine.closeHighscores();
    }
    setState(() {
      _activeTab = tab;
    });
  }

  void _applyCustomSeedInput({bool launchImmediately = true}) {
    final String raw = _customSeedController.text.trim();
    final int? parsed = int.tryParse(raw);
    final int targetSeed =
        (parsed != null && parsed > 0) ? parsed : _engine.seed;
    _customSeedController.text = targetSeed.toString();
    triggerGameHaptic(GameHapticKind.medium);
    if (launchImmediately) {
      _engine.replaySeed(targetSeed);
      setState(() {
        _activeTab = VivienneNavTab.ascension;
      });
    } else {
      _engine.setSeed(targetSeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF29B6F6),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _engine,
          builder: (BuildContext context, _) {
            return Stack(
              children: <Widget>[
                // 1. Full-screen immersive Natural Parallax Arena isolated in RepaintBoundary
                Positioned.fill(
                  child: RepaintBoundary(
                    child: _buildPlayfieldArena(),
                  ),
                ),

                // 2. Cartoon Floating Top HUD (without platform description banner)
                Positioned(
                  top: 8,
                  left: 10,
                  right: 10,
                  child: _buildMinimalFloatingTopHud(),
                ),

                // 3. Secondary Cartoon Candy Modal Panels
                if (_activeTab == VivienneNavTab.editionsAndBiomes)
                  Positioned.fill(
                    top: 80,
                    bottom: 66,
                    child: _buildEditionsAndBiomesPanel(),
                  ),
                if (_activeTab == VivienneNavTab.blossomHerbarium)
                  Positioned.fill(
                    top: 80,
                    bottom: 66,
                    child: _buildBlossomHerbariumPanel(),
                  ),
                if (_activeTab == VivienneNavTab.vivienneGallery)
                  Positioned.fill(
                    top: 80,
                    bottom: 66,
                    child: _buildVivienneGalleryPanel(),
                  ),

                // 4. Cartoon Home Menu Overlay (`engine.isInMenu && !engine.isHighscoresOpen`)
                if (_engine.isInMenu &&
                    !_engine.isHighscoresOpen &&
                    _activeTab == VivienneNavTab.ascension)
                  Positioned.fill(
                    child: _buildMainMenuOverlay(),
                  ),

                // 5. Dedicated Highscores Modal Overlay (`engine.isHighscoresOpen`)
                if (_engine.isHighscoresOpen)
                  Positioned.fill(
                    child: _buildHighscoresModalOverlay(),
                  ),

                // 6. Enriched Cartoon Game Over & Seed Leaderboard Overlay (`engine.isGameOver`)
                if (_engine.isGameOver &&
                    !_engine.isInMenu &&
                    !_engine.isHighscoresOpen &&
                    _activeTab == VivienneNavTab.ascension)
                  Positioned.fill(
                    child: _buildGameOverOverlay(),
                  ),

                // 7. Thumb-Zone Bottom Control Bar & Cartoon Navigation Bar
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_activeTab == VivienneNavTab.ascension &&
                          !_engine.isInMenu &&
                          !_engine.isHighscoresOpen &&
                          !_engine.isGameOver)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildMinimalBottomControlBar(),
                        ),
                      _buildMinimalFloatingNavigationBar(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Cartoon Top HUD without any platform description banner.
  Widget _buildMinimalFloatingTopHud() {
    final double normTilt = _engine.effectiveTiltX.clamp(-1.0, 1.0);
    final double deg = _engine.tiltAngleDegrees;
    final String tiltLabel =
        '${deg >= 0 ? '+' : ''}${deg.toStringAsFixed(0)}°';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Top Floating Row: Cartoon Score/Altitude Pill (left) + Seed, Scores & Combo Pills (right)
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.5,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0xFF4A1800),
                      blurRadius: 0,
                      offset: Offset(0, 3.5),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2B1105),
                          width: 1.8,
                        ),
                      ),
                      child: ClipOval(
                        child: _blenderSprites[
                                    VivienneBlenderPose.pose5GrandApex] !=
                                null
                            ? RawImage(
                                image: _blenderSprites[
                                    VivienneBlenderPose.pose5GrandApex],
                                fit: BoxFit.contain,
                              )
                            : const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF2B1105),
                                size: 13,
                              ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InterpolatedHudTicker(
                      value: _engine.altitudeMeters,
                      formatter: (double v) => '${v.toStringAsFixed(0)} m',
                      style: const TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 2,
                      height: 12,
                      color: const Color(0x332B1105),
                    ),
                    const SizedBox(width: 4),
                    const CartoonEmblemBadge(
                      kind: CartoonEmblemKind.blossomStar,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: InterpolatedHudTicker(
                        value: _engine.score.toDouble(),
                        formatter: (double v) =>
                            '${_engine.runBlossomsCollected} • ${v.round()} pts',
                        style: const TextStyle(
                          color: Color(0xFFD81B60),
                          fontSize: 9.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 3),
            // Deterministic Seed Pill (Tappable Cartoon Sky Pill)
            GestureDetector(
              key: const Key('seed_cycle_button'),
              onTap: () {
                triggerGameHaptic(GameHapticKind.selection);
                _engine.cycleNextSeed();
                _customSeedController.text = _engine.seed.toString();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF29B6F6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.0,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0xFF0277BD),
                      blurRadius: 0,
                      offset: Offset(0, 3.0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.tag,
                      size: 10,
                      color: Color(0xFFFFF8E7),
                    ),
                    const SizedBox(width: 1),
                    Text(
                      'SEED ${_engine.seed}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 3),
            // Cartoon Home Menu Button (opens Menu d'Accueil Cartoon without Highscores)
            GestureDetector(
              key: const Key('open_cartoon_home_menu_button'),
              onTap: () {
                triggerGameHaptic(GameHapticKind.selection);
                _customSeedController.text = _engine.seed.toString();
                _engine.openMainMenu();
                setState(() {
                  _activeTab = VivienneNavTab.ascension;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF80AB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.0,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0xFF880E4F),
                      blurRadius: 0,
                      offset: Offset(0, 3.0),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.home_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'MENU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 3),
            // Dedicated Highscores Modal Button with Cartoon Trophy Emblem
            GestureDetector(
              key: const Key('open_menu_leaderboard_button'),
              onTap: () {
                triggerGameHaptic(GameHapticKind.medium);
                _customSeedController.text = _engine.seed.toString();
                _engine.openHighscores();
                setState(() {
                  _activeTab = VivienneNavTab.ascension;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.0,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0xFFBF6000),
                      blurRadius: 0,
                      offset: Offset(0, 3.0),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CartoonEmblemBadge(
                      kind: CartoonEmblemKind.trophyCup,
                      size: 13,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'HIGHSCORES',
                      style: TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 7.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_engine.comboCount > 1) ...<Widget>[
              const SizedBox(width: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.0,
                  ),
                ),
                child: Text(
                  '×${_engine.comboCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        // Second Compact Row: Cartoon Inclinometer & 0° Calibration Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xEEFFF8E7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2B1105),
              width: 2.0,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x552B1105),
                blurRadius: 0,
                offset: Offset(0, 2.5),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.screen_rotation_alt,
                size: 13,
                color: Color(0xFFD81B60),
              ),
              const SizedBox(width: 5),
              Text(
                'INCLINAISON $tiltLabel',
                style: const TextStyle(
                  color: Color(0xFF2B1105),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double barW = constraints.maxWidth;
                    final double knobX =
                        ((normTilt + 1.0) * 0.5 * (barW - 16.0)).clamp(
                          0.0,
                          math.max(0.0, barW - 16.0),
                        );
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (DragUpdateDetails details) {
                        final double rel =
                            ((details.localPosition.dx / barW) * 2.0 - 1.0)
                                .clamp(-1.0, 1.0);
                        _engine.setManualTilt(rel);
                      },
                      onTapDown: (TapDownDetails details) {
                        final double rel =
                            ((details.localPosition.dx / barW) * 2.0 - 1.0)
                                .clamp(-1.0, 1.0);
                        _engine.setManualTilt(rel);
                      },
                      child: Container(
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0B2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF2B1105),
                            width: 1.4,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Container(
                              width: 2.0,
                              height: 8,
                              color: const Color(0x662B1105),
                            ),
                            Positioned(
                              left: knobX,
                              child: Container(
                                width: 16,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4081),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: const Color(0xFF2B1105),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  triggerGameHaptic(GameHapticKind.light);
                  _engine.calibrateTiltZero();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2B1105),
                      width: 1.4,
                    ),
                  ),
                  child: const Text(
                    'CALIBRER 0°',
                    style: TextStyle(
                      color: Color(0xFF2B1105),
                      fontSize: 8.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Active power-up chips (only shown on main Ascension playfield)
        if (_activeTab == VivienneNavTab.ascension &&
            !_engine.isInMenu &&
            (_engine.speedyBoostTimer > 0 ||
                _engine.padlockShieldTimer > 0 ||
                _engine.magnetTimer > 0))
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              spacing: 5,
              runSpacing: 4,
              children: <Widget>[
                if (_engine.speedyBoostTimer > 0)
                  _buildBuffChip(
                    'SPEEDY ${_engine.speedyBoostTimer.toStringAsFixed(1)}s',
                    const Color(0xFFFFD700),
                  ),
                if (_engine.padlockShieldTimer > 0)
                  _buildBuffChip(
                    'CADENAS ${_engine.padlockShieldTimer.toStringAsFixed(1)}s',
                    const Color(0xFF76FF03),
                  ),
                if (_engine.magnetTimer > 0)
                  _buildBuffChip(
                    'AIMANT ${_engine.magnetTimer.toStringAsFixed(1)}s',
                    const Color(0xFFFF80AB),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlayfieldArena() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            final double norm =
                ((details.localPosition.dx / constraints.maxWidth) * 2.0 - 1.0)
                    .clamp(-1.05, 1.05);
            _engine.setManualTilt(norm);
          },
          onHorizontalDragEnd: (_) {
            if (_engine.hardwareSensorActive) {
              _engine.setManualTilt(null);
            }
          },
          onTapDown: (TapDownDetails details) {
            final double norm =
                ((details.localPosition.dx / constraints.maxWidth) * 2.0 - 1.0)
                    .clamp(-1.0, 1.0);
            _engine.setManualTilt(norm * 0.75);
          },
          onTapUp: (_) {
            if (_engine.hardwareSensorActive) {
              _engine.setManualTilt(null);
            }
          },
          child: SizedBox.expand(
            child: CustomPaint(
              painter: VivienneGamePainter(
                engine: _engine,
                blenderSprites: _blenderSprites,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBuffChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B1105), width: 2.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2B1105),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMinimalBottomControlBar() {
    final double gauge = _engine.blossomGauge.clamp(0.0, 1.0);
    final bool ready = gauge >= 0.45;

    return Row(
      children: <Widget>[
        _buildTiltStepButton(
          icon: Icons.chevron_left,
          label: 'GAUCHE',
          onTap: () => _engine.setManualTilt(-0.78),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Juicy3DGameButton(
            key: const Key('grand_blossom_leap_button'),
            minHeight: 48.0,
            haptic: ready ? GameHapticKind.heavy : GameHapticKind.light,
            backgroundColor: ready
                ? const Color(0xFF76FF03)
                : const Color(0xFFFFF8E7),
            lipColor: ready
                ? const Color(0xFF33691E)
                : const Color(0xFF8D6E63),
            borderColor: const Color(0xFF2B1105),
            borderRadius: 22.0,
            lipDepth: 5.0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            onTap: _engine.triggerGrandBlossomLeap,
            child: RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: gauge),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double animGauge, Widget? _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const CartoonEmblemBadge(
                        kind: CartoonEmblemKind.blossomStar,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'ÉCLAT BLOSSOM ${(animGauge * 100).round()}%',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2B1105),
                            fontSize: 10.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildTiltStepButton(
          icon: Icons.chevron_right,
          label: 'DROITE',
          onTap: () => _engine.setManualTilt(0.78),
        ),
      ],
    );
  }

  Widget _buildTiltStepButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Juicy3DGameButton(
      minWidth: 70.0,
      minHeight: 48.0,
      backgroundColor: const Color(0xFF29B6F6),
      lipColor: const Color(0xFF0277BD),
      borderColor: const Color(0xFF2B1105),
      borderRadius: 20.0,
      lipDepth: 5.0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalFloatingNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF2B1105),
          width: 3.0,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0xFF4A1800),
            blurRadius: 0,
            offset: Offset(0, 5.0),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _buildNavTabButton(
            tab: VivienneNavTab.ascension,
            emblem: CartoonEmblemKind.playTriangle,
            activeColor: const Color(0xFF76FF03),
            label: 'ASCENSION',
          ),
          _buildNavTabButton(
            tab: VivienneNavTab.editionsAndBiomes,
            emblem: CartoonEmblemKind.crownEdition,
            activeColor: const Color(0xFFFFD700),
            label: 'MAISON LV',
          ),
          _buildNavTabButton(
            tab: VivienneNavTab.blossomHerbarium,
            emblem: CartoonEmblemKind.blossomStar,
            activeColor: const Color(0xFFFF80AB),
            label: 'HERBIER',
          ),
          _buildNavTabButton(
            tab: VivienneNavTab.vivienneGallery,
            emblem: CartoonEmblemKind.turntableGallery,
            activeColor: const Color(0xFF29B6F6),
            label: 'GALERIE VIVIENNE',
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabButton({
    required VivienneNavTab tab,
    required CartoonEmblemKind emblem,
    required Color activeColor,
    required String label,
  }) {
    final bool selected = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(tab),
        child: AnimatedScale(
          scale: selected ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.elasticOut,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? activeColor : const Color(0xFFFFE0B2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF2B1105),
                width: selected ? 2.2 : 1.4,
              ),
              boxShadow: selected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Color(0xFF4A1800),
                        blurRadius: 0,
                        offset: Offset(0, 2.5),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CartoonEmblemBadge(
                  kind: emblem,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cartoon Pop Main Menu Overlay (`engine.isInMenu && !engine.isHighscoresOpen`):
  /// - True Cartoon Home Screen WITHOUT displaying the Highscore Leaderboard directly!
  /// - Ribbon Banner (`VIVIENNE : L'ODYSSÉE BLOSSOM`) + Active Seed & Edition badges
  /// - Illustrated Heroic Vivienne Medallion Stage with Blossom stars & personal seed objective pill
  /// - Huge 3D Cartoon Lime Green Play CTA (`start_run_from_menu_button`, `minHeight: 58`)
  /// - Dedicated 3D Cartoon Gold `HIGHSCORES` Button (`open_highscores_modal_button`, `minHeight: 50`)
  /// - Cartoon Category Quick-Access Buttons (`ÉDITIONS`, `HERBIER`, `GALERIE VIVIENNE`)
  /// - Deterministic Seed Selector & Input (`custom_seed_input`, `apply_custom_seed_button`)
  Widget _buildMainMenuOverlay() {
    return Container(
      key: const Key('main_menu_overlay'),
      color: const Color(0x88102A43),
      padding: const EdgeInsets.fromLTRB(10, 76, 10, 66),
      child: CartoonBouncyModal(
        backgroundColor: const Color(0xFFFFF8E7),
        borderColor: const Color(0xFF2B1105),
        lipColor: const Color(0xFF4A1800),
        borderRadius: 28,
        lipDepth: 7.0,
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: <Widget>[
            // 1. Grande Bannière Ruban Cartoon : VIVIENNE : L'ODYSSÉE BLOSSOM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFFF4081), Color(0xFFFF80AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF2B1105),
                  width: 2.8,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xFF880E4F),
                    blurRadius: 0,
                    offset: Offset(0, 4.0),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CartoonEmblemBadge(
                        kind: CartoonEmblemKind.blossomStar,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'VIVIENNE : L\'ODYSSÉE BLOSSOM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      CartoonEmblemBadge(
                        kind: CartoonEmblemKind.crownEdition,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2B1105),
                            width: 1.6,
                          ),
                        ),
                        child: Text(
                          'SEED #${_engine.seed}',
                          style: const TextStyle(
                            color: Color(0xFF2B1105),
                            fontSize: 9.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2B1105),
                            width: 1.6,
                          ),
                        ),
                        child: Text(
                          _engine.selectedEdition.name,
                          style: const TextStyle(
                            color: Color(0xFF2B1105),
                            fontSize: 9.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Scène Héroïque Cartoon de Vivienne (Médaillon central illustré & animé)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF29B6F6),
                    Color(0xFF81D4FA),
                    Color(0xFFFFF9C4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF2B1105),
                  width: 2.8,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xFF0277BD),
                    blurRadius: 0,
                    offset: Offset(0, 4.5),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      const Column(
                        children: <Widget>[
                          CartoonEmblemBadge(
                            kind: CartoonEmblemKind.blossomStar,
                            size: 28,
                          ),
                          SizedBox(height: 8),
                          CartoonEmblemBadge(
                            kind: CartoonEmblemKind.crownEdition,
                            size: 26,
                          ),
                        ],
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.90, end: 1.0),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.elasticOut,
                        builder:
                            (BuildContext context, double s, Widget? child) {
                          return Transform.scale(scale: s, child: child);
                        },
                        child: Container(
                          width: 108,
                          height: 108,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: <Color>[
                                Color(0xFFFFFFFF),
                                Color(0xFFFFF59D),
                                Color(0xFFFFD700),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFF2B1105),
                              width: 3.2,
                            ),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0xFFBF6000),
                                blurRadius: 0,
                                offset: Offset(0, 4.0),
                              ),
                            ],
                          ),
                          child: _blenderSprites[
                                      VivienneBlenderPose.pose5GrandApex] !=
                                  null
                              ? RawImage(
                                  image: _blenderSprites[
                                      VivienneBlenderPose.pose5GrandApex],
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  VivienneBlenderPose.pose5GrandApex.assetPath,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      const Column(
                        children: <Widget>[
                          CartoonEmblemBadge(
                            kind: CartoonEmblemKind.crownEdition,
                            size: 26,
                          ),
                          SizedBox(height: 8),
                          CartoonEmblemBadge(
                            kind: CartoonEmblemKind.blossomStar,
                            size: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2B1105),
                        width: 2.2,
                      ),
                    ),
                    child: Text(
                      'Objectif Seed #${_engine.seed} : ${_engine.currentSeedHighScore} pts (${_engine.bestAltitudeForSeed(_engine.seed)} m)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Gros Bouton Principal 3D Cartoon Vert Lime "JOUER SUR SEED #..."
            Juicy3DGameButton(
              key: const Key('start_run_from_menu_button'),
              minHeight: 58.0,
              haptic: GameHapticKind.heavy,
              backgroundColor: const Color(0xFF76FF03),
              lipColor: const Color(0xFF33691E),
              borderColor: const Color(0xFF2B1105),
              borderWidth: 3.0,
              borderRadius: 24.0,
              lipDepth: 6.5,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: () => _engine.startRunFromMenu(targetSeed: _engine.seed),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const CartoonEmblemBadge(
                    kind: CartoonEmblemKind.playTriangle,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'JOUER SUR SEED #${_engine.seed}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),

            // 4. Gros Bouton Dédié 3D Cartoon Or "HIGHSCORES"
            Juicy3DGameButton(
              key: const Key('open_highscores_modal_button'),
              minHeight: 50.0,
              haptic: GameHapticKind.medium,
              backgroundColor: const Color(0xFFFFD700),
              lipColor: const Color(0xFFBF6000),
              borderColor: const Color(0xFF2B1105),
              borderWidth: 2.8,
              borderRadius: 22.0,
              lipDepth: 5.5,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              onTap: () => _engine.openHighscores(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CartoonEmblemBadge(
                    kind: CartoonEmblemKind.trophyCup,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'TABLEAU DES HIGHSCORES',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 5. Boutons Cartoon d'Accès aux Catégories (ÉDITIONS, HERBIER, GALERIE VIVIENNE)
            Row(
              children: <Widget>[
                Expanded(
                  child: Juicy3DGameButton(
                    minHeight: 46,
                    backgroundColor: const Color(0xFFFFD700),
                    lipColor: const Color(0xFFBF6000),
                    borderColor: const Color(0xFF2B1105),
                    borderRadius: 18,
                    lipDepth: 4.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    onTap: () => _selectTab(VivienneNavTab.editionsAndBiomes),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CartoonEmblemBadge(
                          kind: CartoonEmblemKind.crownEdition,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'ÉDITIONS',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF2B1105),
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Juicy3DGameButton(
                    minHeight: 46,
                    backgroundColor: const Color(0xFFFF80AB),
                    lipColor: const Color(0xFFC2185B),
                    borderColor: const Color(0xFF2B1105),
                    borderRadius: 18,
                    lipDepth: 4.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    onTap: () => _selectTab(VivienneNavTab.blossomHerbarium),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CartoonEmblemBadge(
                          kind: CartoonEmblemKind.blossomStar,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'HERBIER',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF2B1105),
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Juicy3DGameButton(
                    key: const Key('open_vivienne_gallery_button'),
                    minHeight: 46,
                    backgroundColor: const Color(0xFF29B6F6),
                    lipColor: const Color(0xFF0277BD),
                    borderColor: const Color(0xFF2B1105),
                    borderRadius: 18,
                    lipDepth: 4.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    onTap: () => _selectTab(VivienneNavTab.vivienneGallery),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CartoonEmblemBadge(
                          kind: CartoonEmblemKind.turntableGallery,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'GALERIE VIVIENNE',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 6. Sélecteur Rapide de Seed Déterministe
            _buildSeedPickerAndCustomInputCard(),
          ],
        ),
      ),
    );
  }

  /// Dedicated Highscores Modal Overlay (`engine.isHighscoresOpen` — `Key('highscores_modal_overlay')`)
  /// Only visible when the player taps a Highscores button (`open_highscores_modal_button` or `open_menu_leaderboard_button`).
  Widget _buildHighscoresModalOverlay() {
    return Container(
      key: const Key('highscores_modal_overlay'),
      color: const Color(0x99102A43),
      padding: const EdgeInsets.fromLTRB(10, 76, 10, 66),
      child: CartoonBouncyModal(
        backgroundColor: const Color(0xFFFFF8E7),
        borderColor: const Color(0xFF2B1105),
        lipColor: const Color(0xFF4A1800),
        borderRadius: 28,
        lipDepth: 7.0,
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: <Widget>[
            // En-tête Ruban Cartoon Or/Rose avec Trophée + Bouton 3D RETOUR MENU
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFFFD700), Color(0xFFFF80AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF2B1105),
                  width: 2.8,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xFF880E4F),
                    blurRadius: 0,
                    offset: Offset(0, 4.0),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const CartoonEmblemBadge(
                    kind: CartoonEmblemKind.trophyCup,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'TABLEAU DES HIGHSCORES',
                          style: TextStyle(
                            color: Color(0xFF2B1105),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Records Officiels par Seed Déterministe',
                          style: TextStyle(
                            color: Color(0xFF4A1800),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Juicy3DGameButton(
                    key: const Key('close_highscores_modal_button'),
                    minWidth: 92,
                    minHeight: 38,
                    lipDepth: 4.0,
                    borderRadius: 14,
                    backgroundColor: const Color(0xFFFFF8E7),
                    lipColor: const Color(0xFF8D6E63),
                    borderColor: const Color(0xFF2B1105),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    onTap: () => _engine.closeHighscores(),
                    child: const Text(
                      'RETOUR MENU',
                      style: TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tableau complet des scores par Seed
            _buildSeedLeaderboardSection(contextPrefix: 'menu'),
            const SizedBox(height: 10),

            // Sélecteur de Seed Déterministe
            _buildSeedPickerAndCustomInputCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedPickerAndCustomInputCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2B1105),
          width: 2.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'CHOISIR OU SAISIR UN SEED DÉTERMINISTE',
            style: TextStyle(
              color: Color(0xFF2B1105),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final int s in VivienneJumpEngine.curatedSeeds)
                GestureDetector(
                  onTap: () {
                    triggerGameHaptic(GameHapticKind.selection);
                    _customSeedController.text = s.toString();
                    _engine.replaySeed(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _engine.seed == s
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF2B1105),
                        width: 2.0,
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0xFF4A1800),
                          blurRadius: 0,
                          offset: Offset(0, 2.5),
                        ),
                      ],
                    ),
                    child: Text(
                      'Seed #$s (${_engine.bestScoreForSeed(s)} pts)',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B1105),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    key: const Key('custom_seed_input'),
                    controller: _customSeedController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF2B1105),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      hintText: 'Numéro de Seed (ex: 777)',
                      hintStyle: const TextStyle(
                        color: Color(0x882B1105),
                        fontSize: 10.5,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF2B1105),
                          width: 2.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF4081),
                          width: 2.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Juicy3DGameButton(
                key: const Key('apply_custom_seed_button'),
                minWidth: 112,
                minHeight: 42,
                lipDepth: 4.5,
                borderRadius: 16,
                backgroundColor: const Color(0xFFFF4081),
                lipColor: const Color(0xFF880E4F),
                borderColor: const Color(0xFF2B1105),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                onTap: () => _applyCustomSeedInput(launchImmediately: true),
                child: const Text(
                  'LANCER SEED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shared Cartoon Leaderboard Widget displayed in both the Main Menu AND the Game Over screen.
  /// Styled like a Candy Crush / Angry Birds level-ranking board with cartoon medals (#1, #2, #3),
  /// star ratings, seed tags, and 3D tactile "REJOUER CE SEED" buttons.
  Widget _buildSeedLeaderboardSection({required String contextPrefix}) {
    final List<SeedScoreEntry> entries = _engine.bestEntriesBySeed;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5FE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF2B1105),
          width: 2.6,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0xFF0277BD),
            blurRadius: 0,
            offset: Offset(0, 4.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              CartoonEmblemBadge(
                kind: CartoonEmblemKind.trophyCup,
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TABLEAU DES SCORES PAR SEED (HIGHSCORES)',
                  style: TextStyle(
                    color: Color(0xFF2B1105),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < entries.length; i++)
            _buildLeaderboardRow(
              entry: entries[i],
              rank: i + 1,
              contextPrefix: contextPrefix,
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required SeedScoreEntry entry,
    required int rank,
    required String contextPrefix,
  }) {
    final bool isCurrentSeed = entry.seed == _engine.seed;
    final Color medalColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFE0E0E0),
      3 => const Color(0xFFFFB74D),
      _ => const Color(0xFF29B6F6),
    };
    final int seedBest = _engine.bestScoreForSeed(entry.seed);
    final int stars = entry.score >= 4200
        ? 3
        : entry.score >= 3200
        ? 2
        : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isCurrentSeed
            ? const Color(0xFFFFF59D)
            : const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2B1105),
          width: isCurrentSeed ? 2.6 : 2.0,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x332B1105),
            blurRadius: 0,
            offset: Offset(0, 2.5),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          // Cartoon Medal Badge (#1, #2, #3...)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: medalColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2B1105), width: 2.0),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Color(0xFF2B1105),
                fontSize: 9.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Score, Stars, Altitude & Seed Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF29B6F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF2B1105),
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        'SEED #${entry.seed}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${entry.score} pts • ${entry.altitudeMeters} m',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2B1105),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    for (int s = 0; s < 3; s++)
                      Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: s < stars
                            ? const Color(0xFFFFAB00)
                            : const Color(0x332B1105),
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Record: $seedBest pts • ${entry.playerTag}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5D4037),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Direct 3D Cartoon Action Button: "REJOUER CE SEED"
          Juicy3DGameButton(
            key: Key('${contextPrefix}_replay_seed_${entry.seed}'),
            minWidth: 90,
            minHeight: 36,
            lipDepth: 3.5,
            borderRadius: 14,
            haptic: GameHapticKind.medium,
            backgroundColor: isCurrentSeed
                ? const Color(0xFF76FF03)
                : const Color(0xFFFFD700),
            lipColor: isCurrentSeed
                ? const Color(0xFF33691E)
                : const Color(0xFFBF6000),
            borderColor: const Color(0xFF2B1105),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            onTap: () {
              _customSeedController.text = entry.seed.toString();
              _engine.replaySeed(entry.seed);
            },
            child: const Text(
              'REJOUER CE SEED',
              style: TextStyle(
                color: Color(0xFF2B1105),
                fontSize: 8.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditionsAndBiomesPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CartoonBouncyModal(
        backgroundColor: const Color(0xFFFFF8E7),
        borderColor: const Color(0xFF2B1105),
        lipColor: const Color(0xFF4A1800),
        borderRadius: 28,
        lipDepth: 6.5,
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2B1105), width: 2.5),
              ),
              child: const Row(
                children: <Widget>[
                  CartoonEmblemBadge(
                    kind: CartoonEmblemKind.crownEdition,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MAISON LOUIS VUITTON — 4 ÉDITIONS VIVIENNE',
                      style: TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Deterministic Seed Selector Bar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0B2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2B1105), width: 2.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'SEED DU PARCOURS DÉTERMINISTE : #${_engine.seed} (HIGHSCORE : ${_engine.currentSeedHighScore} PTS)',
                    style: const TextStyle(
                      color: Color(0xFF2B1105),
                      fontSize: 10.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final int s in VivienneJumpEngine.curatedSeeds)
                        GestureDetector(
                          onTap: () {
                            triggerGameHaptic(GameHapticKind.selection);
                            _customSeedController.text = s.toString();
                            _engine.setSeed(s);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _engine.seed == s
                                  ? const Color(0xFF76FF03)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2B1105),
                                width: 1.8,
                              ),
                            ),
                            child: Text(
                              'Seed #$s (${_engine.bestScoreForSeed(s)} pts)',
                              style: const TextStyle(
                                fontSize: 9.2,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2B1105),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final VivienneEdition ed in VivienneEdition.values)
              _buildEditionCard(ed),
            const SizedBox(height: 10),
            const Text(
              'ACCÈS DIRECT AUX 4 PAYSAGES NATURELS EN PARALLAXE',
              style: TextStyle(
                color: Color(0xFF2B1105),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final LvBiome b in LvBiome.values)
                  GestureDetector(
                    onTap: () {
                      triggerGameHaptic(GameHapticKind.medium);
                      _engine.warpToAltitude(
                        b.minAltitudeMeters.toDouble() + 120.0,
                      );
                      _selectTab(VivienneNavTab.ascension);
                    },
                    child: Container(
                      width: 152,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: b.topColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2B1105),
                          width: 2.2,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0xFF4A1800),
                            blurRadius: 0,
                            offset: Offset(0, 3.0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            b.name,
                            style: TextStyle(
                              color: b.horizonGlowColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dès ${b.minAltitudeMeters} m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditionCard(VivienneEdition ed) {
    final bool isSelected = _engine.selectedEdition == ed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFF59D) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2B1105),
          width: isSelected ? 2.8 : 2.0,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x332B1105),
            blurRadius: 0,
            offset: Offset(0, 3.0),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2B1105), width: 2.0),
            ),
            child: _blenderSprites[VivienneBlenderPose.pose5GrandApex] != null
                ? RawImage(
                    image: _blenderSprites[VivienneBlenderPose.pose5GrandApex],
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    'assets/sprites/vivienne_pose_5_grand_apex.png',
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ed.name,
                  style: const TextStyle(
                    color: Color(0xFF2B1105),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ed.subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD81B60),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ed.perkLabel,
                  style: const TextStyle(
                    color: Color(0xFF5D4037),
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Juicy3DGameButton(
            minWidth: 74,
            minHeight: 38,
            lipDepth: 4.0,
            borderRadius: 14,
            backgroundColor: isSelected
                ? const Color(0xFF76FF03)
                : const Color(0xFFFFD700),
            lipColor: isSelected
                ? const Color(0xFF33691E)
                : const Color(0xFFBF6000),
            borderColor: const Color(0xFF2B1105),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            onTap: () {
              _engine.selectEdition(ed);
              _selectTab(VivienneNavTab.ascension);
            },
            child: Text(
              isSelected ? 'ACTIF' : 'CHOISIR',
              style: const TextStyle(
                color: Color(0xFF2B1105),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cartoon Herbarium Panel:
  /// - Platform descriptions (`p.description` and `p.shortEffectLabel`) are STRICTLY HIDDEN!
  /// - Displays ONLY `p.title`, the Cartoon multiplier badge (`×1.00`, `×1.45`, `×0.85`, `1×`, `×1.14`),
  ///   and the visual particle effect pill (`CartoonParticleEffectVisualPill`).
  Widget _buildBlossomHerbariumPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CartoonBouncyModal(
        backgroundColor: const Color(0xFFFFF8E7),
        borderColor: const Color(0xFF2B1105),
        lipColor: const Color(0xFF4A1800),
        borderRadius: 28,
        lipDepth: 6.5,
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF80AB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2B1105), width: 2.5),
              ),
              child: const Row(
                children: <Widget>[
                  CartoonEmblemBadge(
                    kind: CartoonEmblemKind.blossomStar,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'HERBIER BLOSSOM & 5 ARCHITECTURES DE PLATEFORMES',
                      style: TextStyle(
                        color: Color(0xFF2B1105),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final LvPlatformType p in LvPlatformType.values)
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.3,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x332B1105),
                      blurRadius: 0,
                      offset: Offset(0, 3.0),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    // Cartoon Multiplier Badge (`×1.00`, `×1.45`, `×0.85`, `1×`, `×1.14`)
                    Container(
                      width: 56,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: p.accentColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2B1105),
                          width: 2.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.singleUse
                            ? '1×'
                            : '×${p.impulseMultiplier.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF2B1105),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Short platform title ONLY (no description, no shortEffectLabel)
                    Expanded(
                      child: Text(
                        p.title,
                        style: const TextStyle(
                          color: Color(0xFF2B1105),
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Visual particle effect pill
                    CartoonParticleEffectVisualPill(platformType: p),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            const Text(
              'TRÉSORS & FLEURS BLOSSOM LOUIS VUITTON',
              style: TextStyle(
                color: Color(0xFF2B1105),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            for (final BlossomItemType item in BlossomItemType.values)
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.0,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.primaryColor,
                        border: Border.all(
                          color: const Color(0xFF2B1105),
                          width: 2.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item == BlossomItemType.speedyBagBoost
                            ? Icons.shopping_bag
                            : item == BlossomItemType.goldenPadlockShield
                            ? Icons.lock
                            : Icons.local_florist,
                        color: const Color(0xFF2B1105),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Color(0xFF2B1105),
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2B1105),
                                    width: 1.4,
                                  ),
                                ),
                                child: Text(
                                  '+${item.points} pts',
                                  style: const TextStyle(
                                    color: Color(0xFF2B1105),
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Color(0xFFD81B60),
                              fontSize: 9.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Galerie Vivienne Turntable 360° Panel (`VivienneNavTab.vivienneGallery` — `Key('vivienne_gallery_panel')`)
  /// Replaces the old Blender MCP category with an interactive 360° Turntable driven by phone inclination (`effectiveTiltX`)
  /// or horizontal swipe, displaying the 24 Cycles-rendered angles (`0°..345°`) on a 3D Cartoon Louis Vuitton pedestal.
  Widget _buildVivienneGalleryPanel() {
    final int frameIdx = _engine.turntableFrameIndex;
    final ui.Image? frameImage = _turntableSprites[frameIdx];
    final double deg = _engine.tiltAngleDegrees;
    final String tiltSign = deg >= 0 ? '+' : '';

    return Padding(
      key: const Key('vivienne_gallery_panel'),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CartoonBouncyModal(
        backgroundColor: const Color(0xFFFFF8E7),
        borderColor: const Color(0xFF2B1105),
        lipColor: const Color(0xFF4A1800),
        borderRadius: 28,
        lipDepth: 6.5,
        child: ListView(
          children: <Widget>[
            // 1. En-tête Ruban Cartoon : GALERIE VIVIENNE — TURNTABLE 360°
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF29B6F6), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2B1105), width: 2.5),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xFF01579B),
                    blurRadius: 0,
                    offset: Offset(0, 3.5),
                  ),
                ],
              ),
              child: const Row(
                children: <Widget>[
                  CartoonEmblemBadge(
                    kind: CartoonEmblemKind.turntableGallery,
                    size: 26,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'GALERIE VIVIENNE — TURNTABLE 360°',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Inclinez le téléphone pour faire tourner Vivienne à 360°',
                          style: TextStyle(
                            color: Color(0xFFFFF8E7),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Scène Podium Turntable 360° Interactive (Key('vivienne_turntable_stage'))
            GestureDetector(
              key: const Key('vivienne_turntable_stage'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                _engine.rotateTurntableByDelta(details.delta.dx * 1.6);
              },
              child: Container(
                height: 256,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFF14283D),
                      Color(0xFF1F4260),
                      Color(0xFF2D1B14),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.8,
                  ),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0xFF4A1800),
                      blurRadius: 0,
                      offset: Offset(0, 4.5),
                    ),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    // Top status row: Angle & Frame index + Phone Tilt badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2B1105),
                                width: 1.8,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ANGLE : ${_engine.turntableAngleDegrees.round()}° (VUE ${frameIdx + 1}/24)',
                                style: const TextStyle(
                                  color: Color(0xFF2B1105),
                                  fontSize: 8.6,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4081),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2B1105),
                                width: 1.8,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'INCLINAISON TÉLÉPHONE : $tiltSign${deg.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.4,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Center 360° Turntable Podium & Vivienne 3D Sprite
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _VivienneTurntablePodiumPainter(
                                angleDegrees: _engine.turntableAngleDegrees,
                                edition: _engine.selectedEdition,
                                tiltX: _engine.effectiveTiltX,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: frameImage != null
                                ? RawImage(
                                    key: ValueKey<int>(frameIdx),
                                    image: frameImage,
                                    fit: BoxFit.contain,
                                  )
                                : Image.asset(
                                    _engine.turntableFrameAssetPath,
                                    key: ValueKey<int>(frameIdx),
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom view angle label pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF2B1105),
                          width: 2.0,
                        ),
                      ),
                      child: Text(
                        _engine.turntableViewAngleLabel,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF2B1105),
                          fontSize: 9.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 3. Boutons Cartoon de Rotation & Angles Clés
            Row(
              children: <Widget>[
                Expanded(
                  child: Juicy3DGameButton(
                    key: const Key('turntable_rotate_left_button'),
                    minHeight: 42,
                    lipDepth: 4.0,
                    borderRadius: 16,
                    backgroundColor: const Color(0xFF29B6F6),
                    lipColor: const Color(0xFF0277BD),
                    borderColor: const Color(0xFF2B1105),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    onTap: () => _engine.rotateTurntableByDelta(-30.0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.rotate_left_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'TOURNER GAUCHE',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Juicy3DGameButton(
                  key: const Key('turntable_angle_0_button'),
                  minWidth: 66,
                  minHeight: 42,
                  lipDepth: 4.0,
                  borderRadius: 16,
                  backgroundColor: const Color(0xFFFFD700),
                  lipColor: const Color(0xFFBF6000),
                  borderColor: const Color(0xFF2B1105),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  onTap: () => _engine.setTurntableAngle(0.0),
                  child: const Text(
                    'FACE 0°',
                    style: TextStyle(
                      color: Color(0xFF2B1105),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Juicy3DGameButton(
                  key: const Key('turntable_angle_180_button'),
                  minWidth: 66,
                  minHeight: 42,
                  lipDepth: 4.0,
                  borderRadius: 16,
                  backgroundColor: const Color(0xFFFF80AB),
                  lipColor: const Color(0xFFC2185B),
                  borderColor: const Color(0xFF2B1105),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  onTap: () => _engine.setTurntableAngle(180.0),
                  child: const Text(
                    'DOS 180°',
                    style: TextStyle(
                      color: Color(0xFF2B1105),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Juicy3DGameButton(
                    key: const Key('turntable_rotate_right_button'),
                    minHeight: 42,
                    lipDepth: 4.0,
                    borderRadius: 16,
                    backgroundColor: const Color(0xFF29B6F6),
                    lipColor: const Color(0xFF0277BD),
                    borderColor: const Color(0xFF2B1105),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    onTap: () => _engine.rotateTurntableByDelta(30.0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            'TOURNER DROITE',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.rotate_right_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4. Cartes de Collection de la Galerie Vivienne (les 4 Éditions Haute Couture)
            const Text(
              'COLLECTION HAUTE COUTURE — ÉDITIONS DE LA GALERIE',
              style: TextStyle(
                color: Color(0xFF2B1105),
                fontSize: 11.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            for (final VivienneEdition ed in VivienneEdition.values)
              _buildEditionCard(ed),
          ],
        ),
      ),
    );
  }

  /// Cartoon Pop Game Over Overlay (`engine.isGameOver`) inspired by Angry Birds / Candy Crush:
  /// - Bouncy Cartoon Ribbon Header (`FIN D'ASCENSION`) with Star Rating
  /// - Run Score, Altitude, Seed Record comparison & New Seed Record Banner
  /// - Full Seed Leaderboard (`TABLEAU DES SCORES PAR SEED`) with `REJOUER CE SEED`
  /// - Primary 3D Tactile `REJOUER SEED` & `CHANGER SEED` buttons
  Widget _buildGameOverOverlay() {
    final int seedBest = _engine.bestScoreForSeed(_engine.seed);
    final int seedBestAlt = _engine.bestAltitudeForSeed(_engine.seed);

    return Container(
      key: const Key('game_over_overlay'),
      color: const Color(0x88102A43),
      padding: const EdgeInsets.fromLTRB(10, 76, 10, 66),
      child: CartoonBouncyModal(
        backgroundColor: const Color(0xFFFFF8E7),
        borderColor: const Color(0xFF2B1105),
        lipColor: const Color(0xFF4A1800),
        borderRadius: 28,
        lipDepth: 7.0,
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4081),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2B1105),
                  width: 2.8,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0xFF880E4F),
                    blurRadius: 0,
                    offset: Offset(0, 4.0),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CartoonEmblemBadge(
                    kind: CartoonEmblemKind.trophyCup,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'FIN D\'ASCENSION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(width: 8),
                  CartoonEmblemBadge(
                    kind: CartoonEmblemKind.blossomStar,
                    size: 24,
                  ),
                ],
              ),
            ),
            if (_engine.lastRunBeatSeedRecord) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF2B1105),
                    width: 2.2,
                  ),
                ),
                child: Text(
                  'NOUVEAU RECORD SUR LE SEED #${_engine.seed} !',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2B1105),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0B2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF2B1105),
                  width: 2.4,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (int i = 0; i < 3; i++)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFAB00),
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Score : ${_engine.score} pts • Altitude : ${_engine.altitudeMeters.toStringAsFixed(0)} m',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2B1105),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Seed #${_engine.seed} • Record du Seed : $seedBest pts ($seedBestAlt m)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD81B60),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fleurs Blossom : ${_engine.runBlossomsCollected} • Rebonds Parfaits : ${_engine.totalPerfectBouncesInRun}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5D4037),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 6,
                  child: Juicy3DGameButton(
                    key: const Key('gameover_replay_current_seed_button'),
                    minHeight: 50.0,
                    haptic: GameHapticKind.heavy,
                    backgroundColor: const Color(0xFF76FF03),
                    lipColor: const Color(0xFF33691E),
                    borderColor: const Color(0xFF2B1105),
                    borderRadius: 20.0,
                    lipDepth: 5.5,
                    onTap: () => _engine.replaySeed(_engine.seed),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const CartoonEmblemBadge(
                          kind: CartoonEmblemKind.playTriangle,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'REJOUER SEED #${_engine.seed}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2B1105),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Juicy3DGameButton(
                    key: const Key('gameover_open_menu_button'),
                    minHeight: 50.0,
                    haptic: GameHapticKind.medium,
                    backgroundColor: const Color(0xFF29B6F6),
                    lipColor: const Color(0xFF0277BD),
                    borderColor: const Color(0xFF2B1105),
                    borderRadius: 20.0,
                    lipDepth: 5.5,
                    onTap: () => _engine.openMainMenu(),
                    child: const Text(
                      'CHANGER SEED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Seed Leaderboard Table on Game Over
            _buildSeedLeaderboardSection(contextPrefix: 'gameover'),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for the 3D Cartoon Louis Vuitton 360° Turntable Pedestal (`Galerie Vivienne`).
/// Renders:
/// - Edition radial halo spotlight & floating Blossom sparkles
/// - 3D Monogram trunk pedestal base with brass rivets & bold `#2B1105` cartoon outline
/// - Rotating 24K Gold & Oak Wood graduated disc (`0°..360°`, 24 ticks every `15°`)
/// - Tilt direction indicator (`◄ INCLINAISON ►`)
class _VivienneTurntablePodiumPainter extends CustomPainter {
  const _VivienneTurntablePodiumPainter({
    required this.angleDegrees,
    required this.edition,
    required this.tiltX,
  });

  final double angleDegrees;
  final VivienneEdition edition;
  final double tiltX;

  static const Color _kOutlineDark = Color(0xFF2B1105);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);
    final double discCenterY = size.height * 0.81;
    final double discRx = math.min(size.width * 0.42, 128.0);
    final double discRy = 20.0;

    // 1. Edition radial studio spotlight behind Vivienne
    final Offset haloCenter = Offset(center.dx, size.height * 0.42);
    final double haloRadius = math.min(size.width, size.height) * 0.46;
    canvas.drawCircle(
      haloCenter,
      haloRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          haloCenter,
          haloRadius,
          <Color>[
            edition.accentColor.withValues(alpha: 0.42),
            edition.primaryColor.withValues(alpha: 0.22),
            Colors.transparent,
          ],
          const <double>[0.0, 0.58, 1.0],
        ),
    );

    final Paint strokePaint = Paint()
      ..color = _kOutlineDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // 2. Lower 3D Cartoon Pedestal Cylinder (Monogram Ebene & Brass Rim)
    final Rect baseShadowRect = Rect.fromCenter(
      center: Offset(center.dx, discCenterY + 18.0),
      width: discRx * 2.08,
      height: discRy * 2.1,
    );
    canvas.drawOval(
      baseShadowRect,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );

    final Path cylinderBody = Path()
      ..moveTo(center.dx - discRx, discCenterY)
      ..lineTo(center.dx - discRx * 0.96, discCenterY + 15.0)
      ..arcToPoint(
        Offset(center.dx + discRx * 0.96, discCenterY + 15.0),
        radius: Radius.elliptical(discRx * 0.96, discRy * 0.95),
        clockwise: false,
      )
      ..lineTo(center.dx + discRx, discCenterY)
      ..close();

    canvas.drawPath(
      cylinderBody,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx - discRx, discCenterY),
          Offset(center.dx + discRx, discCenterY),
          const <Color>[
            Color(0xFF4E342E),
            Color(0xFF2B1D14),
            Color(0xFF6D4C41),
            Color(0xFF1B0905),
          ],
          const <double>[0.0, 0.35, 0.72, 1.0],
        ),
    );
    canvas.drawPath(cylinderBody, strokePaint);

    // 3. Top Rotating 24K Gold & Oak Turntable Disc
    final Rect outerDiscRect = Rect.fromCenter(
      center: Offset(center.dx, discCenterY),
      width: discRx * 2.0,
      height: discRy * 2.0,
    );
    canvas.drawOval(
      outerDiscRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(center.dx - discRx, discCenterY - discRy),
          Offset(center.dx + discRx, discCenterY + discRy),
          const <Color>[
            Color(0xFFFFF9C4),
            Color(0xFFFFD700),
            Color(0xFFFFA000),
            Color(0xFFFFD54F),
          ],
          const <double>[0.0, 0.35, 0.75, 1.0],
        ),
    );
    canvas.drawOval(outerDiscRect, strokePaint);

    final Rect innerWoodRect = Rect.fromCenter(
      center: Offset(center.dx, discCenterY - 1.5),
      width: discRx * 1.66,
      height: discRy * 1.58,
    );
    canvas.drawOval(
      innerWoodRect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(center.dx, discCenterY - 3.0),
          discRx * 0.85,
          <Color>[
            const Color(0xFFE3A17B),
            const Color(0xFFC89D7C),
            edition.edgeColor.withValues(alpha: 0.85),
          ],
          const <double>[0.0, 0.72, 1.0],
        ),
    );
    canvas.drawOval(
      innerWoodRect,
      Paint()
        ..color = _kOutlineDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 4. 24 Graduated Angle Ticks (every 15°) rotating with `angleDegrees`
    final double radOffset = angleDegrees * math.pi / 180.0;
    for (int i = 0; i < 24; i++) {
      final double a = (i * 15.0) * math.pi / 180.0 + radOffset;
      final bool isCardinal = i % 6 == 0;
      final double innerScale = isCardinal ? 0.68 : 0.78;
      final Offset p1 = Offset(
        center.dx + math.cos(a) * discRx * innerScale,
        discCenterY - 1.0 + math.sin(a) * discRy * innerScale,
      );
      final Offset p2 = Offset(
        center.dx + math.cos(a) * discRx * 0.94,
        discCenterY - 1.0 + math.sin(a) * discRy * 0.94,
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isCardinal ? _kOutlineDark : const Color(0xAA2B1105)
          ..strokeWidth = isCardinal ? 2.4 : 1.3
          ..strokeCap = StrokeCap.round,
      );
      if (i == 0) {
        // Front 0° Reference Gold Gem Marker
        canvas.drawCircle(
          p2,
          4.0,
          Paint()..color = const Color(0xFFFF1744),
        );
        canvas.drawCircle(
          p2,
          4.0,
          Paint()
            ..color = _kOutlineDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }

    // 5. Contact shadow oval directly under Vivienne's feet
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, discCenterY - 3.0),
        width: discRx * 0.72,
        height: discRy * 0.68,
      ),
      Paint()..color = _kOutlineDark.withValues(alpha: 0.32),
    );

    // 6. Front plaque with tilt indicator ("◄ INCLINAISON ►")
    final RRect plaque = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, discCenterY + 13.5),
        width: 124.0,
        height: 15.0,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      plaque,
      Paint()
        ..color = tiltX.abs() > 0.05
            ? const Color(0xFF76FF03)
            : const Color(0xFFFFD700),
    );
    canvas.drawRRect(
      plaque,
      Paint()
        ..color = _kOutlineDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _VivienneTurntablePodiumPainter oldDelegate) =>
      oldDelegate.angleDegrees != angleDegrees ||
      oldDelegate.edition != edition ||
      oldDelegate.tiltX != tiltX;
}
