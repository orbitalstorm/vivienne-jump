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
    _engine = widget.engine ?? VivienneJumpEngine();
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
    if (_activeTab == VivienneNavTab.ascension) {
      _engine.update(dt);
    }
  }

  @override
  void dispose() {
    _tiltSubscription?.cancel();
    _ticker?.dispose();
    if (_ownsEngine) {
      _engine.dispose();
    }
    super.dispose();
  }

  void _selectTab(VivienneNavTab tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A4B6E),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _engine,
          builder: (BuildContext context, _) {
            return Stack(
              children: <Widget>[
                // 1. Full-screen immersive Natural Parallax Arena
                Positioned.fill(
                  child: _buildPlayfieldArena(),
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
                    top: 76,
                    bottom: 58,
                    child: _buildEditionsAndBiomesPanel(),
                  ),
                if (_activeTab == VivienneNavTab.blossomHerbarium)
                  Positioned.fill(
                    top: 76,
                    bottom: 58,
                    child: _buildBlossomHerbariumPanel(),
                  ),
                if (_activeTab == VivienneNavTab.blenderAtelier)
                  Positioned.fill(
                    top: 76,
                    bottom: 58,
                    child: _buildBlenderAtelierPanel(),
                  ),

                // 4. Game Over Overlay
                if (_engine.isGameOver &&
                    _activeTab == VivienneNavTab.ascension)
                  Positioned.fill(
                    child: _buildGameOverOverlay(),
                  ),

                // 5. Minimalist Floating Bottom Dock & Action Pill
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_activeTab == VivienneNavTab.ascension)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Top Floating Row: Score/Altitude Pill (left) + Seed & Combo Pills (right)
        Row(
          children: <Widget>[
            // Left: Minimalist Score & Altitude Pill
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x990D1F2D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
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
                    const SizedBox(width: 8),
                    Text(
                      '${_engine.altitudeMeters.toStringAsFixed(0)} m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: Colors.white24,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.local_florist,
                      size: 12,
                      color: Color(0xFFF8BBD0),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${_engine.runBlossomsCollected} • ${_engine.score} pts • VIVIENNE',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFF59D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Right: Deterministic Seed Pill (Tappable)
            InkWell(
              key: const Key('seed_cycle_button'),
              onTap: _engine.cycleNextSeed,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x990D1F2D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0x88FFD700),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.tag,
                      size: 12,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'SEED ${_engine.seed}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_engine.comboCount > 1) ...<Widget>[
              const SizedBox(width: 5),
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
                    fontSize: 10.0,
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
              InkWell(
                onTap: _engine.calibrateTiltZero,
                borderRadius: BorderRadius.circular(8),
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
        // Active power-up chips (only shown on main Ascension playfield)
        if (_activeTab == VivienneNavTab.ascension &&
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
          child: InkWell(
            key: const Key('grand_blossom_leap_button'),
            onTap: _engine.triggerGrandBlossomLeap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: ready
                    ? const Color(0xDDFFD700)
                    : const Color(0x990D1F2D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: ready
                      ? const Color(0xFFFFFFFF)
                      : Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.bolt,
                    size: 14,
                    color: ready
                        ? const Color(0xFF102419)
                        : const Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'ÉCLAT BLOSSOM ${(gauge * 100).round()}%',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x990D1F2D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
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
      ),
    );
  }

  Widget _buildMinimalFloatingNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xB80B1912),
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
      child: InkWell(
        onTap: () => _selectTab(tab),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 5),
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
                  'SEED DU PARCOURS DÉTERMINISTE : #${_engine.seed}',
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 11.0,
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
                          'Seed #$s',
                          style: TextStyle(
                            fontSize: 10.0,
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
                InkWell(
                  onTap: () {
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected
                  ? const Color(0xFFFFD700)
                  : const Color(0xFF244232),
              foregroundColor: isSelected
                  ? const Color(0xFF0E1E16)
                  : const Color(0xFFFFD700),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            ),
            onPressed: () {
              _engine.selectEdition(ed);
              _selectTab(VivienneNavTab.ascension);
            },
            child: Text(
              isSelected ? 'ACTIF' : 'CHOISIR',
              style: const TextStyle(
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
            'HERBIER BLOSSOM & TRÉSORS LOUIS VUITTON',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Collectez les fleurs Blossom et utilisez les plateformes à ressort doré pour franchir les grands écarts d\'altitude.',
            style: TextStyle(color: Colors.white70, fontSize: 11.0),
          ),
          const SizedBox(height: 10),
          for (final BlossomItemType item in BlossomItemType.values)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
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
                    width: 36,
                    height: 36,
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
                                style: TextStyle(
                                  color: item.primaryColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '+${item.points} pts',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE3A17B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'ARCHITECTURES DE PLATEFORMES (MAX 3 À PORTÉE DE SAUT)',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final LvPlatformType p in LvPlatformType.values)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF14271D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${p.title} (Impulsion ×${p.impulseMultiplier.toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    p.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
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

  Widget _buildGameOverOverlay() {
    return Container(
      color: const Color(0xBB09140E),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF12261C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),
            Text(
              'Altitude : ${_engine.altitudeMeters.toStringAsFixed(0)} m • Record : ${_engine.bestAltitudeMeters.toStringAsFixed(0)} m',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Score : ${_engine.score} pts • Seed #${_engine.seed}',
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0E1E16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () => _engine.resetRun(seed: _engine.seed),
              icon: const Icon(Icons.replay),
              label: const Text(
                'REJOUER CE SEED',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
