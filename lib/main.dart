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
      systemNavigationBarColor: Color(0xFF140C08),
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
        scaffoldBackgroundColor: const Color(0xFF140C08),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFE3A17B),
          surface: Color(0xFF23160E),
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
        // Fallback vector renderer remains active if asset load is skipped in minimal tests
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
      backgroundColor: const Color(0xFF140C08),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _engine,
          builder: (BuildContext context, _) {
            return Column(
              children: <Widget>[
                _buildMaisonHeaderHud(),
                _buildTiltInclinometerBar(),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      _buildPlayfieldArena(),
                      if (_activeTab == VivienneNavTab.editionsAndBiomes)
                        _buildEditionsAndBiomesPanel(),
                      if (_activeTab == VivienneNavTab.blossomHerbarium)
                        _buildBlossomHerbariumPanel(),
                      if (_activeTab == VivienneNavTab.blenderAtelier)
                        _buildBlenderAtelierPanel(),
                      if (_engine.isGameOver &&
                          _activeTab == VivienneNavTab.ascension)
                        _buildGameOverOverlay(),
                    ],
                  ),
                ),
                _buildBottomControlDeck(),
                _buildMaisonNavigationBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMaisonHeaderHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFF1E130C),
        border: Border(
          bottom: BorderSide(color: Color(0x66D4AF37), width: 1.0),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.3,
                  ),
                  gradient: const RadialGradient(
                    colors: <Color>[Color(0xFF4A2E1B), Color(0xFF1B1009)],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child:
                      _blenderSprites[VivienneBlenderPose.pose5GrandApex] !=
                          null
                      ? RawImage(
                          image:
                              _blenderSprites[VivienneBlenderPose
                                  .pose5GrandApex],
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          'assets/sprites/app_icon_512.png',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (
                                BuildContext context,
                                Object error,
                                StackTrace? stackTrace,
                              ) => const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFFFD700),
                                size: 18,
                              ),
                        ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'VIVIENNE : L\'ODYSSÉE BLOSSOM',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${_engine.currentBiome.name} • ${_engine.selectedEdition.name}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE3A17B),
                        fontSize: 10.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E24),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFE5B842),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'COMBO ×${_engine.comboCount}',
                  style: const TextStyle(
                    color: Color(0xFFFFF59D),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildStatPill(
                  label: 'ALTITUDE',
                  value: '${_engine.altitudeMeters.toStringAsFixed(0)} m',
                  color: const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatPill(
                  label: 'FLEURS BLOSSOM',
                  value: '${_engine.runBlossomsCollected} fleurs',
                  color: const Color(0xFFF8BBD0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatPill(
                  label: 'SCORE MAISON',
                  value: '${_engine.score}',
                  color: const Color(0xFFE3A17B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2B1B12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.78),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiltInclinometerBar() {
    final double normTilt = _engine.effectiveTiltX.clamp(-1.0, 1.0);
    final double deg = _engine.tiltAngleDegrees;
    final String tiltLabel =
        '${deg >= 0 ? '+' : ''}${deg.toStringAsFixed(0)}°';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF170E09),
        border: Border(
          bottom: BorderSide(color: Color(0x33D4AF37), width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.screen_rotation_alt,
            size: 14,
            color: Color(0xFFFFD700),
          ),
          const SizedBox(width: 5),
          Text(
            'INCLINAISON $tiltLabel',
            style: const TextStyle(
              color: Color(0xFFE3A17B),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double barW = constraints.maxWidth;
                final double knobX =
                    ((normTilt + 1.0) * 0.5 * (barW - 18.0)).clamp(
                      0.0,
                      math.max(0.0, barW - 18.0),
                    );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    final double rel =
                        ((details.localPosition.dx / barW) * 2.0 - 1.0).clamp(
                          -1.0,
                          1.0,
                        );
                    _engine.setManualTilt(rel);
                  },
                  onTapDown: (TapDownDetails details) {
                    final double rel =
                        ((details.localPosition.dx / barW) * 2.0 - 1.0).clamp(
                          -1.0,
                          1.0,
                        );
                    _engine.setManualTilt(rel);
                  },
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B1D14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0x77D4AF37),
                        width: 1.0,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        // Center 0° tick
                        Container(
                          width: 1.5,
                          height: 12,
                          color: const Color(0x66FFFFFF),
                        ),
                        Positioned(
                          left: knobX,
                          child: Container(
                            width: 18,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(6),
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
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF3A2416),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0x99FFD700)),
              ),
              child: const Text(
                'CALIBRER 0°',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
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
          child: Stack(
            children: <Widget>[
              SizedBox.expand(
                child: CustomPaint(
                  painter: VivienneGamePainter(
                    engine: _engine,
                    blenderSprites: _blenderSprites,
                  ),
                ),
              ),
              // Floating Pose & Active Buffs Badge in top-left of arena
              Positioned(
                top: 8,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC1B110B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0x88D4AF37),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        _engine.currentBlenderRenderState.$1.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_engine.speedyBoostTimer > 0 ||
                        _engine.padlockShieldTimer > 0 ||
                        _engine.magnetTimer > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
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
                                const Color(0xFFFFB74D),
                              ),
                            if (_engine.magnetTimer > 0)
                              _buildBuffChip(
                                'AIMANT ${_engine.magnetTimer.toStringAsFixed(1)}s',
                                const Color(0xFFF48FB1),
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
      },
    );
  }

  Widget _buildBuffChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xDD2B1D14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.0,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildBottomControlDeck() {
    final double gauge = _engine.blossomGauge.clamp(0.0, 1.0);
    final bool ready = gauge >= 0.45;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1D120B),
        border: Border(
          top: BorderSide(color: Color(0x66D4AF37), width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          // Left Quick Tilt Button (Accessibility & Emulator Control)
          _buildTiltStepButton(
            icon: Icons.rotate_left,
            label: 'GAUCHE',
            onTap: () => _engine.setManualTilt(-0.78),
          ),
          const SizedBox(width: 8),
          // Center Grand Saut Blossom Activation Button
          Expanded(
            child: InkWell(
              key: const Key('grand_blossom_leap_button'),
              onTap: () {
                _engine.triggerGrandBlossomLeap();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: ready
                        ? const <Color>[
                            Color(0xFFD4AF37),
                            Color(0xFF9E6B14),
                          ]
                        : const <Color>[
                            Color(0xFF3A2618),
                            Color(0xFF26180F),
                          ],
                  ),
                  border: Border.all(
                    color: ready
                        ? const Color(0xFFFFF59D)
                        : const Color(0x77D4AF37),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.rocket_launch,
                          size: 14,
                          color: ready
                              ? const Color(0xFF1E130C)
                              : const Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'ÉCLAT BLOSSOM (${(gauge * 100).round()}%)',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ready
                                  ? const Color(0xFF140C08)
                                  : const Color(0xFFFFD700),
                              fontSize: 11.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: gauge,
                        minHeight: 5,
                        backgroundColor: const Color(0x55000000),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ready
                              ? const Color(0xFF140C08)
                              : const Color(0xFFFFD700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Right Quick Tilt Button
          _buildTiltStepButton(
            icon: Icons.rotate_right,
            label: 'DROITE',
            onTap: () => _engine.setManualTilt(0.78),
          ),
        ],
      ),
    );
  }

  Widget _buildTiltStepButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1D14),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0x88E3A17B)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 16, color: const Color(0xFFE3A17B)),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE3A17B),
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaisonNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF140C08),
        border: Border(
          top: BorderSide(color: Color(0x44D4AF37), width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          _buildNavTabButton(
            tab: VivienneNavTab.ascension,
            icon: Icons.vertical_align_top,
            label: 'ASCENSION',
          ),
          _buildNavTabButton(
            tab: VivienneNavTab.editionsAndBiomes,
            icon: Icons.diamond_outlined,
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF3A2416)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFD700)
                  : const Color(0x33E3A17B),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFE3A17B),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFFFD700)
                      : const Color(0xFFE3A17B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
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
      color: const Color(0xF2160E09),
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: <Widget>[
          const Text(
            'MAISON LOUIS VUITTON — 4 ÉDITIONS VIVIENNE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sélectionnez votre figurine Vivienne et explorez les 4 paliers d\'altitude verticaux.',
            style: TextStyle(color: Color(0xFFE3A17B), fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          for (final VivienneEdition ed in VivienneEdition.values)
            _buildEditionCard(ed),
          const SizedBox(height: 14),
          const Text(
            'ACCÈS DIRECT AUX 4 PALIERS D\'ALTITUDE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
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
                    width: 170,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: b.topColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: b.horizonGlowColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          b.name,
                          style: TextStyle(
                            color: b.horizonGlowColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dès ${b.minAltitudeMeters} m',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.0,
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF332014) : const Color(0xFF22150D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFD700) : const Color(0x55E3A17B),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF140C08),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ed.subtitle,
                  style: const TextStyle(
                    color: Color(0xFFE3A17B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ed.perkLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.0,
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
                  : const Color(0xFF3E291C),
              foregroundColor: isSelected
                  ? const Color(0xFF140C08)
                  : const Color(0xFFFFD700),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: () {
              _engine.selectEdition(ed);
              _selectTab(VivienneNavTab.ascension);
            },
            child: Text(
              isSelected ? 'ACTIF' : 'CHOISIR',
              style: const TextStyle(
                fontSize: 10.0,
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
      color: const Color(0xF2160E09),
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: <Widget>[
          const Text(
            'HERBIER BLOSSOM & TRÉSORS LOUIS VUITTON',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Collectez les fleurs Star Blossom, Sun Blossom et Neo Blossom en inclinant votre téléphone pour propulser Vivienne vers les étoiles.',
            style: TextStyle(color: Color(0xFFE3A17B), fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          for (final BlossomItemType item in BlossomItemType.values)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF23160E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item.primaryColor.withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF140C08),
                      border: Border.all(color: item.primaryColor, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      item == BlossomItemType.speedyBagBoost
                          ? Icons.shopping_bag
                          : item == BlossomItemType.goldenPadlockShield
                          ? Icons.lock
                          : Icons.local_florist,
                      color: item.primaryColor,
                      size: 20,
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
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '+${item.points} pts',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE3A17B),
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'ARCHITECTURES DE PLATEFORMES HAUTE MAROQUINERIE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final LvPlatformType p in LvPlatformType.values)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF1E130C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x44D4AF37)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${p.title} (Impulsion ×${p.impulseMultiplier.toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    p.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.0,
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
      color: const Color(0xF4120B07),
      padding: const EdgeInsets.all(14),
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                    Text(
                      'Source : orbitalstorm/BLENDER_LAB/models/vivienne_speedy_v03.blend (Rig 22 Os • 72 Frames @ 24 FPS)',
                      style: TextStyle(
                        color: Color(0xFFE3A17B),
                        fontSize: 10.0,
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
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Interactive Cycles Sprite Preview Box
          Container(
            height: 210,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF080504),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.4),
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
                          fontSize: 11.5,
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
          // 72-frame Scrubber
          Row(
            children: <Widget>[
              const Text(
                'Timeline 72f :',
                style: TextStyle(
                  color: Color(0xFFE3A17B),
                  fontSize: 10.5,
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
          // 6 Storyboard Pose Selector Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final VivienneBlenderPose p in VivienneBlenderPose.values)
                ChoiceChip(
                  label: Text(
                    'Pose ${p.index + 1} (F${p.frameNumber})',
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w800,
                      color: _selectedAtelierPose == p
                          ? const Color(0xFF140C08)
                          : const Color(0xFFFFD700),
                    ),
                  ),
                  selected: _selectedAtelierPose == p,
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF281910),
                  onSelected: (_) {
                    setState(() {
                      _selectedAtelierPose = p;
                      _atelierFrameScrubber = p.frameNumber.toDouble();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '5 MATÉRIAUX PBR OFFICIELS (Principled BSDF • Cycles AgX)',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 12.0,
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
                color: const Color(0xFF22150D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x44D4AF37)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Roughness ${m.roughness} • Metallic ${m.metallic} • ${m.assignedParts}',
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
                color: Color(0xFFE3A17B),
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
      color: const Color(0xDD120B07),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF23160E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700), width: 2.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'FIN D\'ASCENSION HAUTE COUTURE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Altitude atteinte : ${_engine.altitudeMeters.toStringAsFixed(0)} m (Record : ${_engine.bestAltitudeMeters.toStringAsFixed(0)} m)',
              style: const TextStyle(
                color: Color(0xFFE3A17B),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Score : ${_engine.score} pts • Fleurs Blossom : ${_engine.runBlossomsCollected}',
              style: const TextStyle(color: Colors.white, fontSize: 12.0),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF140C08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: _engine.resetRun,
              icon: const Icon(Icons.replay),
              label: const Text(
                'NOUVELLE ASCENSION VIVIENNE',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
