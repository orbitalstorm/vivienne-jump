import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'engine/vivienne_jump_engine.dart';
import 'models/vivienne_models.dart';
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
      systemNavigationBarColor: Color(0xFF0E1D14),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VivienneJumpApp());
}

enum VivienneNavTab {
  ascension,
  editionsAndBiomes,
  blossomHerbarium,
  blenderAtelier,
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

/// Reusable tactile 3D game button implementing `mobile-game-ui` (Mode B Flutter):
/// - Immediate Squash & Stretch on contact (`AnimatedScale` 0.93, `Curves.easeOutCubic`, 75ms)
/// - Tactile 3D bottom lip (`BoxShadow` with `blurRadius: 0` reduced on press + vertical translation)
/// - Native Haptic Feedback (`HapticFeedback`)
/// - Enforced minimum touch target constraints (`ConstrainedBox`).
class Juicy3DGameButton extends StatefulWidget {
  const Juicy3DGameButton({
    super.key,
    required this.onTap,
    required this.child,
    this.backgroundColor = const Color(0xFFFFD700),
    this.lipColor = const Color(0xFF9E6B14),
    this.borderColor = const Color(0xFFFFFFFF),
    this.borderRadius = 16.0,
    this.lipDepth = 4.0,
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
          scale: _isPressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 75),
          curve: Curves.easeOutCubic,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.borderColor,
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  if (currentLip > 0)
                    BoxShadow(
                      color: widget.lipColor,
                      blurRadius: 0,
                      offset: Offset(0, currentLip),
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
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
    this.autoStartTicker = true,
  });

  final VivienneJumpEngine? engine;
  final Map<VivienneBlenderPose, ui.Image>? initialSprites;
  final bool autoStartTicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIVIENNE : L\'Odyssée Blossom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF1A4B6E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFE3A17B),
          surface: Color(0xFF12241B),
        ),
        useMaterial3: true,
      ),
      home: VivienneJumpHomeScreen(
        engine: engine,
        initialSprites: initialSprites,
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
    this.autoStartTicker = true,
  });

  final VivienneJumpEngine? engine;
  final Map<VivienneBlenderPose, ui.Image>? initialSprites;
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

  VivienneNavTab _activeTab = VivienneNavTab.ascension;
  double _atelierFrameScrubber = 60.0;
  VivienneBlenderPose _selectedAtelierPose =
      VivienneBlenderPose.pose5GrandApex;

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
    if (_activeTab == VivienneNavTab.ascension && !_engine.isInMenu) {
      _engine.update(dt);
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
      backgroundColor: const Color(0xFF1A4B6E),
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

                // 2. Minimalist Floating Top HUD
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: _buildMinimalFloatingTopHud(),
                ),

                // 3. Secondary Minimalist Modal Panels
                if (_activeTab == VivienneNavTab.editionsAndBiomes)
                  Positioned.fill(
                    top: 94,
                    bottom: 62,
                    child: _buildEditionsAndBiomesPanel(),
                  ),
                if (_activeTab == VivienneNavTab.blossomHerbarium)
                  Positioned.fill(
                    top: 94,
                    bottom: 62,
                    child: _buildBlossomHerbariumPanel(),
                  ),
                if (_activeTab == VivienneNavTab.blenderAtelier)
                  Positioned.fill(
                    top: 94,
                    bottom: 62,
                    child: _buildBlenderAtelierPanel(),
                  ),

                // 4. Pre-Game Store Menu & Seed Leaderboard Overlay (`engine.isInMenu`)
                if (_engine.isInMenu &&
                    _activeTab == VivienneNavTab.ascension)
                  Positioned.fill(
                    child: _buildMainMenuOverlay(),
                  ),

                // 5. Enriched Game Over & Seed Leaderboard Overlay (`engine.isGameOver`)
                if (_engine.isGameOver &&
                    !_engine.isInMenu &&
                    _activeTab == VivienneNavTab.ascension)
                  Positioned.fill(
                    child: _buildGameOverOverlay(),
                  ),

                // 6. Thumb-Zone Bottom Control Bar & Navigation Bar
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_activeTab == VivienneNavTab.ascension &&
                          !_engine.isInMenu &&
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

  Widget _buildMinimalFloatingTopHud() {
    final double normTilt = _engine.effectiveTiltX.clamp(-1.0, 1.0);
    final double deg = _engine.tiltAngleDegrees;
    final String tiltLabel =
        '${deg >= 0 ? '+' : ''}${deg.toStringAsFixed(0)}°';
    final LvPlatformType activePlat = _engine.lastBouncedPlatformType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Top Floating Row: Score/Altitude Pill (left) + Seed, Menu/Scores & Combo Pills (right)
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xAA0D1F2D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 1.2,
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
                                color: Color(0xFFFFD700),
                                size: 14,
                              ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    InterpolatedHudTicker(
                      value: _engine.altitudeMeters,
                      formatter: (double v) => '${v.toStringAsFixed(0)} m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.local_florist,
                      size: 12,
                      color: Color(0xFFF8BBD0),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: InterpolatedHudTicker(
                        value: _engine.score.toDouble(),
                        formatter: (double v) =>
                            '${_engine.runBlossomsCollected} • ${v.round()} pts • VIVIENNE',
                        style: const TextStyle(
                          color: Color(0xFFFFF59D),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 5),
            // Deterministic Seed Pill (Tappable)
            GestureDetector(
              key: const Key('seed_cycle_button'),
              onTap: () {
                triggerGameHaptic(GameHapticKind.selection);
                _engine.cycleNextSeed();
                _customSeedController.text = _engine.seed.toString();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xAA0D1F2D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xAAFFD700),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.tag,
                      size: 11,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'SEED ${_engine.seed}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 5),
            // Store Menu & Seed Leaderboard Button
            GestureDetector(
              key: const Key('open_menu_leaderboard_button'),
              onTap: () {
                triggerGameHaptic(GameHapticKind.medium);
                _customSeedController.text = _engine.seed.toString();
                _engine.openMainMenu();
                setState(() {
                  _activeTab = VivienneNavTab.ascension;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xDD162E22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.emoji_events,
                      size: 12,
                      color: Color(0xFFFFD700),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'SCORES',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 9.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_engine.comboCount > 1) ...<Widget>[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC8B1E24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Text(
                  '×${_engine.comboCount}',
                  style: const TextStyle(
                    color: Color(0xFFFFF59D),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        // Second Compact Row: Minimalist Inclinometer & 0° Calibration Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x780D1F2D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 0.8,
            ),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.screen_rotation_alt,
                size: 12,
                color: Color(0xFFFFE082),
              ),
              const SizedBox(width: 5),
              Text(
                'INCLINAISON $tiltLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double barW = constraints.maxWidth;
                    final double knobX =
                        ((normTilt + 1.0) * 0.5 * (barW - 14.0)).clamp(
                          0.0,
                          math.max(0.0, barW - 14.0),
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
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0x55000000),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Container(
                              width: 1.5,
                              height: 8,
                              color: Colors.white38,
                            ),
                            Positioned(
                              left: knobX,
                              child: Container(
                                width: 14,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(4),
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
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CALIBRER 0°',
                    style: TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Third Compact Row: Instant 5-Platform Visual Legend & Active Bounce Status
        if (_activeTab == VivienneNavTab.ascension && !_engine.isInMenu)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0x8809151E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: activePlat.accentColor.withValues(alpha: 0.55),
                  width: 0.9,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: activePlat.accentColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: activePlat.accentColor,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      activePlat.badgeText,
                      style: TextStyle(
                        color: activePlat.accentColor,
                        fontSize: 8.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _engine.perfectBounceStreak > 0
                          ? 'PARFAIT ×${_engine.perfectBounceStreak} • ${activePlat.shortEffectLabel}'
                          : 'RECORD SEED #${_engine.seed}: ${_engine.currentSeedHighScore} pts • ${activePlat.shortEffectLabel}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
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
                    const Color(0xFFFFE082),
                  ),
                if (_engine.magnetTimer > 0)
                  _buildBuffChip(
                    'AIMANT ${_engine.magnetTimer.toStringAsFixed(1)}s',
                    const Color(0xFFF8BBD0),
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
        color: const Color(0xAA0D1F2D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.85)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
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
                ? const Color(0xFFFFD700)
                : const Color(0xCC0D1F2D),
            lipColor: ready
                ? const Color(0xFF9E6B14)
                : const Color(0xFF061018),
            borderColor: ready
                ? const Color(0xFFFFFFFF)
                : Colors.white.withValues(alpha: 0.28),
            borderRadius: 18.0,
            lipDepth: 4.5,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      Icon(
                        Icons.bolt,
                        size: 15,
                        color: ready
                            ? const Color(0xFF102419)
                            : const Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'ÉCLAT BLOSSOM ${(animGauge * 100).round()}%',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ready
                                ? const Color(0xFF102419)
                                : Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
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
      minWidth: 68.0,
      minHeight: 48.0,
      backgroundColor: const Color(0xCC0D1F2D),
      lipColor: const Color(0xFF050E15),
      borderColor: Colors.white.withValues(alpha: 0.28),
      borderRadius: 16.0,
      lipDepth: 4.0,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
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
        color: const Color(0xCC0B1912),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
      ),
      child: Row(
        children: <Widget>[
          _buildNavTabButton(
            tab: VivienneNavTab.ascension,
            icon: Icons.north,
            label: 'ASCENSION',
          ),
          _buildNavTabButton(
            tab: VivienneNavTab.editionsAndBiomes,
            icon: Icons.wb_sunny_outlined,
            label: 'MAISON LV',
          ),
          _buildNavTabButton(
            tab: VivienneNavTab.blossomHerbarium,
            icon: Icons.local_florist_outlined,
            label: 'HERBIER',
          ),
          _buildNavTabButton(
            tab: VivienneNavTab.blenderAtelier,
            icon: Icons.view_in_ar,
            label: 'BLENDER 3D',
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabButton({
    required VivienneNavTab tab,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(tab),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0x33FFD700)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFD700)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 13,
                color: selected
                    ? const Color(0xFFFFD700)
                    : Colors.white70,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFFFD700)
                        : Colors.white70,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Store Launch Menu Overlay (`engine.isInMenu`) featuring:
  /// - Seed Selector + Custom Seed Input
  /// - Full Seed Leaderboard ("TABLEAU DES SCORES PAR SEED") with "REJOUER CE SEED"
  /// - 5 Differentiated Platforms Guide
  /// - 3D Tactile "LANCER L'ASCENSION" CTA
  Widget _buildMainMenuOverlay() {
    return Container(
      key: const Key('main_menu_overlay'),
      color: const Color(0xCC07120D),
      padding: const EdgeInsets.fromLTRB(12, 82, 12, 64),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xF410231A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
        ),
        child: ListView(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1610),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: _blenderSprites[VivienneBlenderPose.pose5GrandApex] !=
                          null
                      ? RawImage(
                          image: _blenderSprites[
                              VivienneBlenderPose.pose5GrandApex],
                          fit: BoxFit.contain,
                        )
                      : const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFD700),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'VIVIENNE JUMP — SALON DES SCORES & SEEDS',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 13.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Seed Actif #${_engine.seed} • Record à battre : ${_engine.currentSeedHighScore} pts (${_engine.bestAltitudeForSeed(_engine.seed)} m)',
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Primary 3D CTA to start/resume on current seed
            Juicy3DGameButton(
              key: const Key('start_run_from_menu_button'),
              minHeight: 48.0,
              haptic: GameHapticKind.heavy,
              backgroundColor: const Color(0xFFFFD700),
              lipColor: const Color(0xFF9E6B14),
              borderColor: const Color(0xFFFFFFFF),
              borderRadius: 16.0,
              lipDepth: 5.0,
              onTap: () => _engine.startRunFromMenu(targetSeed: _engine.seed),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF0E1E16),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'JOUER SUR SEED #${_engine.seed} (OBJECTIF ${_engine.currentSeedHighScore} PTS)',
                    style: const TextStyle(
                      color: Color(0xFF0E1E16),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Seed Leaderboard Table ("TABLEAU DES SCORES PAR SEED") immediately visible at top
            _buildSeedLeaderboardSection(contextPrefix: 'menu'),
            const SizedBox(height: 10),
            // Curated & Custom Seed Selector Card
            _buildSeedPickerAndCustomInputCard(),
            const SizedBox(height: 10),
            // Compact 5-Platform Visual Reference in Menu
            _buildFivePlatformsQuickGuide(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedPickerAndCustomInputCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF162D21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66FFD700)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'CHOISIR OU SAISIR UN SEED DÉTERMINISTE',
            style: TextStyle(
              color: Color(0xFFFFE082),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final int s in VivienneJumpEngine.curatedSeeds)
                ChoiceChip(
                  label: Text(
                    'Seed #$s (${_engine.bestScoreForSeed(s)} pts)',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: _engine.seed == s
                          ? const Color(0xFF0E1E16)
                          : Colors.white,
                    ),
                  ),
                  selected: _engine.seed == s,
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF0E1E16),
                  onSelected: (_) {
                    triggerGameHaptic(GameHapticKind.selection);
                    _customSeedController.text = s.toString();
                    _engine.replaySeed(s);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    key: const Key('custom_seed_input'),
                    controller: _customSeedController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      hintText: 'Numéro de Seed (ex: 777)',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10.5,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0B1811),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Juicy3DGameButton(
                key: const Key('apply_custom_seed_button'),
                minWidth: 110,
                minHeight: 40,
                lipDepth: 3.5,
                borderRadius: 12,
                backgroundColor: const Color(0xFFE3A17B),
                lipColor: const Color(0xFF8B1E24),
                borderColor: const Color(0xFFFFE082),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                onTap: () => _applyCustomSeedInput(launchImmediately: true),
                child: const Text(
                  'LANCER SEED',
                  style: TextStyle(
                    color: Color(0xFF1A0D0A),
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

  /// Shared Leaderboard Widget displayed in both the Store Main Menu AND the Game Over screen.
  /// Displays rank (#1, #2, #3...), score, altitude, seed number, seed highscore, and a direct
  /// 3D tactile "REJOUER CE SEED" button for every entry.
  Widget _buildSeedLeaderboardSection({required String contextPrefix}) {
    final List<SeedScoreEntry> entries = _engine.bestEntriesBySeed;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF13271D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x88FFD700)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.leaderboard, color: Color(0xFFFFD700), size: 15),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'TABLEAU DES SCORES PAR SEED (HIGHSCORES)',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Chaque Seed génère exactement le même parcours. Appuyez sur « REJOUER CE SEED » pour battre son Highscore !',
            style: TextStyle(color: Colors.white70, fontSize: 9.2),
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
    final Color rankColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFE0E0E0),
      3 => const Color(0xFFCD7F32),
      _ => const Color(0xFF80D8FF),
    };
    final int seedBest = _engine.bestScoreForSeed(entry.seed);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isCurrentSeed
            ? const Color(0xFF1D3A2B)
            : const Color(0xFF0D1B14),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isCurrentSeed ? const Color(0xFFFFD700) : Colors.white24,
          width: isCurrentSeed ? 1.4 : 0.9,
        ),
      ),
      child: Row(
        children: <Widget>[
          // Rank Badge (#1, #2, #3...)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 1.3),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankColor,
                fontSize: 10.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Score, Altitude, Seed & Player Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFD700),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xAAFFD700),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'SEED #${entry.seed}',
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${entry.score} pts • ${entry.altitudeMeters} m',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Highscore Seed: $seedBest pts • ${entry.playerTag}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: entry.isPlayerRun
                        ? const Color(0xFF80D8FF)
                        : Colors.white70,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Direct 3D Action Button: "REJOUER CE SEED"
          Juicy3DGameButton(
            key: Key('${contextPrefix}_replay_seed_${entry.seed}'),
            minWidth: 96,
            minHeight: 36,
            lipDepth: 3.0,
            borderRadius: 10,
            haptic: GameHapticKind.medium,
            backgroundColor: isCurrentSeed
                ? const Color(0xFFFFD700)
                : const Color(0xFF234432),
            lipColor: isCurrentSeed
                ? const Color(0xFF9E6B14)
                : const Color(0xFF0E1E16),
            borderColor: const Color(0xFFFFD700),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            onTap: () {
              _customSeedController.text = entry.seed.toString();
              _engine.replaySeed(entry.seed);
            },
            child: Text(
              'REJOUER CE SEED',
              style: TextStyle(
                color: isCurrentSeed
                    ? const Color(0xFF0E1E16)
                    : const Color(0xFFFFD700),
                fontSize: 8.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFivePlatformsQuickGuide() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF13271D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'LES 5 TYPES DE PLATEFORMES & EFFETS DE SAUT',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          for (final LvPlatformType p in LvPlatformType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: p.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.accentColor, width: 1.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.badgeText,
                      style: TextStyle(
                        color: p.accentColor,
                        fontSize: 8.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.title} — ${p.shortEffectLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditionsAndBiomesPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEE0E1E16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: ListView(
        children: <Widget>[
          const Text(
            'MAISON LOUIS VUITTON — 4 ÉDITIONS VIVIENNE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Parcours déterministe par Seed (max 3 plateformes à portée de saut) et paysages naturels en parallaxe.',
            style: TextStyle(color: Colors.white70, fontSize: 11.0),
          ),
          const SizedBox(height: 10),
          // Deterministic Seed Selector Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF162C21),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x55FFD700)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SEED DU PARCOURS DÉTERMINISTE : #${_engine.seed} (HIGHSCORE : ${_engine.currentSeedHighScore} PTS)',
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final int s in VivienneJumpEngine.curatedSeeds)
                      ChoiceChip(
                        label: Text(
                          'Seed #$s (${_engine.bestScoreForSeed(s)} pts)',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: _engine.seed == s
                                ? const Color(0xFF0E1E16)
                                : Colors.white,
                          ),
                        ),
                        selected: _engine.seed == s,
                        selectedColor: const Color(0xFFFFD700),
                        backgroundColor: const Color(0xFF0E1E16),
                        onSelected: (_) {
                          triggerGameHaptic(GameHapticKind.selection);
                          _customSeedController.text = s.toString();
                          _engine.setSeed(s);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final VivienneEdition ed in VivienneEdition.values)
            _buildEditionCard(ed),
          const SizedBox(height: 12),
          const Text(
            'ACCÈS DIRECT AUX 4 PAYSAGES NATURELS EN PARALLAXE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
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
                    width: 155,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: b.topColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: b.horizonGlowColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          b.name,
                          style: TextStyle(
                            color: b.horizonGlowColor,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dès ${b.minAltitudeMeters} m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
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
    );
  }

  Widget _buildEditionCard(VivienneEdition ed) {
    final bool isSelected = _engine.selectedEdition == ed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1C3528) : const Color(0xFF14271D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1A13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ed.accentColor),
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
                  style: TextStyle(
                    color: ed.accentColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ed.subtitle,
                  style: const TextStyle(
                    color: Color(0xFFE3A17B),
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ed.perkLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Juicy3DGameButton(
            minWidth: 72,
            minHeight: 38,
            lipDepth: 3.0,
            borderRadius: 12,
            backgroundColor: isSelected
                ? const Color(0xFFFFD700)
                : const Color(0xFF244232),
            lipColor: isSelected
                ? const Color(0xFF9E6B14)
                : const Color(0xFF0D1A13),
            borderColor: const Color(0xFFFFD700),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            onTap: () {
              _engine.selectEdition(ed);
              _selectTab(VivienneNavTab.ascension);
            },
            child: Text(
              isSelected ? 'ACTIF' : 'CHOISIR',
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF0E1E16)
                    : const Color(0xFFFFD700),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlossomHerbariumPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEE0E1E16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: ListView(
        children: <Widget>[
          const Text(
            'HERBIER BLOSSOM & 5 ARCHITECTURES DE PLATEFORMES',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chaque plateforme possède un multiplicateur d\'impulsion et un comportement physique distinct.',
            style: TextStyle(color: Colors.white70, fontSize: 10.5),
          ),
          const SizedBox(height: 8),
          for (final LvPlatformType p in LvPlatformType.values)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF14271D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: p.accentColor.withValues(alpha: 0.65),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: p.accentColor.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: p.accentColor),
                        ),
                        child: Text(
                          p.badgeText,
                          style: TextStyle(
                            color: p.accentColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${p.title} (×${p.impulseMultiplier.toStringAsFixed(2)})',
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    p.shortEffectLabel,
                    style: TextStyle(
                      color: p.accentColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.2,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'TRÉSORS & FLEURS BLOSSOM LOUIS VUITTON',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 12.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final BlossomItemType item in BlossomItemType.values)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF14271D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.primaryColor.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0D1A13),
                      border: Border.all(color: item.primaryColor, width: 1.4),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item == BlossomItemType.speedyBagBoost
                          ? Icons.shopping_bag
                          : item == BlossomItemType.goldenPadlockShield
                          ? Icons.lock
                          : Icons.local_florist,
                      color: item.primaryColor,
                      size: 17,
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
                                style: TextStyle(
                                  color: item.primaryColor,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '+${item.points} pts',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 10.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE3A17B),
                            fontSize: 9.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9.0,
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
    );
  }

  Widget _buildBlenderAtelierPanel() {
    final VivienneBlenderKinematics kin =
        VivienneBlenderKinematics.evaluateAtFrame(_atelierFrameScrubber);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEE0E1E16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: ListView(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'ATELIER BLENDER 3D — vivienne_speedy_v03.blend',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Source : orbitalstorm/BLENDER_LAB/models/vivienne_speedy_v03.blend (Rig 22 Os • 72 Frames @ 24 FPS)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _engine.showBlenderRigOverlay,
                activeThumbColor: const Color(0xFFFFD700),
                onChanged: (_) => _engine.toggleBlenderRigOverlay(),
              ),
              const Text(
                'Rig 22 Os',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 195,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF09140E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Transform.scale(
                      scaleX: kin.sxBody,
                      scaleY: kin.szBody,
                      child: _blenderSprites[_selectedAtelierPose] != null
                          ? RawImage(
                              image: _blenderSprites[_selectedAtelierPose],
                              fit: BoxFit.contain,
                            )
                          : Image.asset(
                              _selectedAtelierPose.assetPath,
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _selectedAtelierPose.label,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildKinematicMetric(
                        'Frame Hermite (1..72)',
                        'F${_atelierFrameScrubber.round()} (Saut ${kin.jumpIndex + 1}/3)',
                      ),
                      _buildKinematicMetric(
                        'Squash/Stretch Corps',
                        'sz=${kin.szBody.toStringAsFixed(3)} • sx=${kin.sxBody.toStringAsFixed(3)}',
                      ),
                      _buildKinematicMetric(
                        'Volume (sx·sy·sz)',
                        (kin.sxBody * kin.sxBody * kin.szBody).toStringAsFixed(
                          4,
                        ),
                      ),
                      _buildKinematicMetric(
                        'Élévation Bras en V',
                        '${(kin.armRaise * 100).round()} %',
                      ),
                      _buildKinematicMetric(
                        'Onde Pétales Vachetta',
                        kin.petalBloomWave.toStringAsFixed(2),
                      ),
                      _buildKinematicMetric(
                        'Oscillation Sac Speedy',
                        '${kin.speedyBagSwingDeg.toStringAsFixed(1)}°',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Text(
                'Timeline 72f :',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Slider(
                    value: _atelierFrameScrubber,
                    min: 1.0,
                    max: 72.0,
                    activeColor: const Color(0xFFFFD700),
                    onChanged: (double v) {
                      setState(() {
                        _atelierFrameScrubber = v;
                        _selectedAtelierPose =
                            VivienneBlenderKinematics.evaluateAtFrame(
                              v,
                            ).recommendedPose;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final VivienneBlenderPose p in VivienneBlenderPose.values)
                ChoiceChip(
                  label: Text(
                    'Pose ${p.index + 1} (F${p.frameNumber})',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: _selectedAtelierPose == p
                          ? const Color(0xFF0E1E16)
                          : const Color(0xFFFFD700),
                    ),
                  ),
                  selected: _selectedAtelierPose == p,
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF14271D),
                  onSelected: (_) {
                    setState(() {
                      _selectedAtelierPose = p;
                      _atelierFrameScrubber = p.frameNumber.toDouble();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '5 MATÉRIAUX PBR OFFICIELS (Principled BSDF • Cycles AgX)',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final BlenderPbrMaterialSpec m
              in BlenderPbrMaterialSpec.officialMaterials)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF14271D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: m.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${m.shaderName} (${m.hexColor}) — ${m.title}',
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 10.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Roughness ${m.roughness} • Metallic ${m.metallic} • ${m.assignedParts}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9.0,
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
    );
  }

  Widget _buildKinematicMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 9.0),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 9.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Enriched Game Over Overlay (`engine.isGameOver`) featuring:
  /// - Run Score, Altitude, Seed Record comparison & New Seed Record Banner
  /// - Full Seed Leaderboard ("TABLEAU DES SCORES PAR SEED") with "REJOUER CE SEED"
  /// - Primary 3D Tactile "REJOUER CE SEED" & "SALON DES SEEDS" buttons
  Widget _buildGameOverOverlay() {
    final int seedBest = _engine.bestScoreForSeed(_engine.seed);
    final int seedBestAlt = _engine.bestAltitudeForSeed(_engine.seed);

    return Container(
      key: const Key('game_over_overlay'),
      color: const Color(0xCC07120D),
      padding: const EdgeInsets.fromLTRB(12, 82, 12, 64),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xF412261C),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
        ),
        child: ListView(
          children: <Widget>[
            const Text(
              'FIN D\'ASCENSION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            if (_engine.lastRunBeatSeedRecord) ...<Widget>[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x33FFD700),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Text(
                  'NOUVEAU RECORD SUR LE SEED #${_engine.seed} !',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFF59D),
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
                color: const Color(0xFF0C1A13),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    'Score : ${_engine.score} pts • Altitude : ${_engine.altitudeMeters.toStringAsFixed(0)} m',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Seed #${_engine.seed} • Record du Seed : $seedBest pts ($seedBestAlt m)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fleurs Blossom : ${_engine.runBlossomsCollected} • Rebonds Parfaits : ${_engine.totalPerfectBouncesInRun}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
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
                    minHeight: 48.0,
                    haptic: GameHapticKind.heavy,
                    backgroundColor: const Color(0xFFFFD700),
                    lipColor: const Color(0xFF9E6B14),
                    borderColor: const Color(0xFFFFFFFF),
                    borderRadius: 16.0,
                    lipDepth: 4.5,
                    onTap: () => _engine.replaySeed(_engine.seed),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.replay,
                          color: Color(0xFF0E1E16),
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'REJOUER SEED #${_engine.seed}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0E1E16),
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
                    minHeight: 48.0,
                    haptic: GameHapticKind.medium,
                    backgroundColor: const Color(0xFF214030),
                    lipColor: const Color(0xFF0B1811),
                    borderColor: const Color(0xFFFFD700),
                    borderRadius: 16.0,
                    lipDepth: 4.5,
                    onTap: () => _engine.openMainMenu(),
                    child: const Text(
                      'CHANGER SEED',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
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
