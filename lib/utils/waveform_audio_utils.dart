// ignore_for_file: library_private_types_in_public_api
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:async';

/// Waveform Audio Manager
class WaveformAudioManager {
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, PlayerController> _waveformControllers = {};
  final Map<String, StreamController<double>> _amplitudeControllers = {};
  final Map<String, List<double>> _precomputedAmplitudes = {};
  final Map<String, Timer> _amplitudeTimers = {};
  String? _currentlyPlaying;

  String? get currentlyPlaying => _currentlyPlaying;

  void _disposeFileResources(String fileName) {
    _audioPlayers[fileName]?.stop();
    _audioPlayers[fileName]?.dispose();
    _audioPlayers.remove(fileName);

    _waveformControllers[fileName]?.stopPlayer();
    _waveformControllers[fileName]?.dispose();
    _waveformControllers.remove(fileName);

    _amplitudeTimers[fileName]?.cancel();
    _amplitudeTimers.remove(fileName);

    _amplitudeControllers[fileName]?.close();
    _amplitudeControllers.remove(fileName);

    if (_currentlyPlaying == fileName) _currentlyPlaying = null;
    log('WaveformAudioManager: Disposed resources for $fileName');
  }

  Future<List<double>> _extractAmplitudeData(
      String filePath, PlayerController controller) async {
    try {
      final fileName = filePath.split('/').last;

      if (_precomputedAmplitudes.containsKey(fileName)) {
        return _precomputedAmplitudes[fileName]!;
      }

      final waveData = controller.waveformData;
      List<double> amplitudes = [];

      if (waveData.isNotEmpty) {
        // Adjust sample rate based on device's size or keep it fixed for complexity
        // Keeping it fixed here as it relates to internal data structure, not UI
        final sampleRate = math.max(1, (waveData.length / 120).ceil());

        for (int i = 0; i < waveData.length; i += sampleRate) {
          final normalized = waveData[i] / 255.0;
          amplitudes.add(0.3 + (normalized * 1.2));
        }

        log('✅ Extracted ${amplitudes.length} amplitude points for $fileName');
      } else {
        final random = math.Random();
        amplitudes = List.generate(100, (i) => 0.4 + random.nextDouble() * 0.7);
        log('⚠️ Using fallback amplitude data for $fileName');
      }

      _precomputedAmplitudes[fileName] = amplitudes;
      return amplitudes;
    } catch (e) {
      log('❌ Error extracting amplitude: $e');
      final random = math.Random();
      return List.generate(100, (i) => 0.4 + random.nextDouble() * 0.7);
    }
  }

  Future<bool> _ensureControllersInitialized(
      String fileName, String filePath, Function(String?) onPlayingChanged) async {
    if (_audioPlayers.containsKey(fileName) &&
        _waveformControllers.containsKey(fileName) &&
        _amplitudeControllers.containsKey(fileName)) {
      log('WaveformAudioManager: Controllers already exist for $fileName');
      return true;
    }

    log('WaveformAudioManager: Initializing NEW controllers for $fileName');

    final controller = PlayerController();
    final player = AudioPlayer();
    final amplitudeController = StreamController<double>.broadcast();

    _audioPlayers[fileName] = player;
    _waveformControllers[fileName] = controller;
    _amplitudeControllers[fileName] = amplitudeController;

    try {
      await controller.preparePlayer(path: filePath, shouldExtractWaveform: true);
      await player.setFilePath(filePath);

      final amplitudes = await _extractAmplitudeData(filePath, controller);

      _amplitudeTimers[fileName] =
          Timer.periodic(const Duration(milliseconds: 50), (timer) {
            if (_currentlyPlaying == fileName && player.playing) {
              final position = player.position.inMilliseconds;
              final duration = player.duration?.inMilliseconds ?? 1;

              if (duration > 0 && amplitudes.isNotEmpty) {
                final progress = (position / duration).clamp(0.0, 1.0);
                final index =
                (progress * (amplitudes.length - 1)).floor().clamp(0, amplitudes.length - 1);
                final amplitude = amplitudes[index];
                amplitudeController.add(amplitude);
              }
            }
          });

      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_currentlyPlaying == fileName) {
            Future.delayed(const Duration(milliseconds: 150), () {
              onPlayingChanged(null);
              _disposeFileResources(fileName);
            });
          }
        }
      });

      return true;
    } catch (e) {
      log('❌ Error preparing controllers for $fileName: $e');
      _disposeFileResources(fileName);
      return false;
    }
  }

  Future<void> togglePlayPause(
      String fileName, String filePath, Function(String?) onPlayingChanged) async {
    final previouslyPlaying = _currentlyPlaying;

    if (previouslyPlaying == fileName) {
      _disposeFileResources(fileName);
      onPlayingChanged(null);
      return;
    }

    if (previouslyPlaying != null) {
      _disposeFileResources(previouslyPlaying);
      onPlayingChanged(null);
    }

    if (!await _ensureControllersInitialized(fileName, filePath, onPlayingChanged)) return;

    final player = _audioPlayers[fileName];
    final controller = _waveformControllers[fileName];
    if (player == null || controller == null) return;

    try {
      _currentlyPlaying = fileName;
      onPlayingChanged(fileName);

      await player.seek(Duration.zero);
      await controller.seekTo(0);

      await player.play();
      await controller.startPlayer();
      log('WaveformAudioManager: ▶️ Started playback for $fileName');
    } catch (e) {
      log('❌ Error playing $fileName: $e');
      _disposeFileResources(fileName);
      onPlayingChanged(null);
    }
  }

  PlayerController? getWaveformController(String fileName) =>
      _waveformControllers[fileName];
  AudioPlayer? getAudioPlayer(String fileName) => _audioPlayers[fileName];
  Stream<double>? getAmplitudeStream(String fileName) =>
      _amplitudeControllers[fileName]?.stream;

  void removeFile(String fileName) => _disposeFileResources(fileName);

  void disposeAll() {
    for (var fileName in _audioPlayers.keys.toList()) {
      _disposeFileResources(fileName);
    }
    _audioPlayers.clear();
    _waveformControllers.clear();
    _amplitudeControllers.clear();
    _amplitudeTimers.clear();
    _precomputedAmplitudes.clear();
    _currentlyPlaying = null;
  }
}

/// Smooth, amplitude-responsive waveform widget
class AudioWaveformWidget extends StatefulWidget {
  final PlayerController controller;
  final Stream<double>? amplitudeStream;
  final Color waveColor;
  final Color backgroundColor;
  // Dimensions that need scaling
  final int barCount;
  final double barWidth;
  final double spacing;
  final double horizontalPadding;
  final double height; // New dimension to scale

  const AudioWaveformWidget({
    Key? key,
    required this.controller,
    this.amplitudeStream,
    this.waveColor = const Color(0xFF6C63FF),
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.barCount = 40,
    this.barWidth = 3.0,
    this.spacing = 4.0,
    this.horizontalPadding = 16.0,
    this.height = 90.0, // Default fixed height
  }) : super(key: key);

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<double> _randomFactors;
  double _displayedAmplitude = 0.5;
  double _targetAmplitude = 0.5;
  Timer? _smoothTimer;

  // --- Responsive Scaling Setup ---
  double _scaleFactor = 1.0;
  double _scaleFactorHeight = 1.0;
  // -------------------------------

  @override
  void initState() {
    super.initState();
    _randomFactors =
        List.generate(widget.barCount, (index) => math.Random().nextDouble());
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Smooth amplitude interpolation
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if ((_displayedAmplitude - _targetAmplitude).abs() > 0.001) {
        // No need to scale factor in the logic/interval
        setState(() {
          _displayedAmplitude =
              _displayedAmplitude + (_targetAmplitude - _displayedAmplitude) * 0.1;
        });
      }
    });

    widget.amplitudeStream?.listen((amp) {
      _targetAmplitude = amp.clamp(0.4, 1.3);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;

    final mediaQuery = MediaQuery.of(context);
    _scaleFactor = mediaQuery.size.width / referenceWidth;
    _scaleFactorHeight = mediaQuery.size.height / referenceHeight;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _smoothTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding * _scaleFactor,
          vertical: 12 * _scaleFactorHeight), // Scaled Padding
      height: widget.height * _scaleFactorHeight, // Scaled Height
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12 * _scaleFactor), // Scaled Radius
          bottomRight: Radius.circular(12 * _scaleFactor), // Scaled Radius
        ),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return CustomPaint(
            painter: SmoothAmplitudeWaveformPainter(
              animationValue: _animationController.value,
              waveColor: widget.waveColor,
              barCount: widget.barCount,
              barWidth: widget.barWidth * _scaleFactor, // Scaled Bar Width
              spacing: widget.spacing * _scaleFactor, // Scaled Spacing
              randomFactors: _randomFactors,
              amplitude: _displayedAmplitude,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Painter for smooth, real-time amplitude waveform
class SmoothAmplitudeWaveformPainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;
  final int barCount;
  final double barWidth; // Now scaled in widget
  final double spacing; // Now scaled in widget
  final List<double> randomFactors;
  final double amplitude;

  SmoothAmplitudeWaveformPainter({
    required this.animationValue,
    required this.waveColor,
    required this.barCount,
    required this.barWidth,
    required this.spacing,
    required this.randomFactors,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final maxHeight = size.height * 0.8;
    final totalWidth = size.width;

    // Use scaled barWidth and spacing for calculation
    final totalBarsWidth = (barCount * barWidth) + ((barCount - 1) * spacing);
    final startX = (totalWidth - totalBarsWidth) / 2;

    final Color topColor = waveColor;
    final Color bottomColor = Colors.blue.shade700;

    for (int i = 0; i < barCount; i++) {
      final x = startX + i * (barWidth + spacing);

      final phase = (animationValue * 5 * math.pi);
      final spatialWave = (math.sin(i * 1.0) + 1) / 2;
      final amplitudeModulation = (math.sin(phase + i * 0.5) + 1) / 2;
      final baseHeightFactor = 0.1 + (0.9 * spatialWave * amplitudeModulation);

      final heightFactor = baseHeightFactor * amplitude;
      final barHeight = maxHeight * heightFactor;

      final top = centerY - barHeight / 2;
      final bottom = centerY + barHeight / 2;

      final rect = Rect.fromLTRB(x, top, x + barWidth, bottom);
      final gradient = LinearGradient(
        colors: [bottomColor, topColor],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(rect);

      final paint = Paint()
        ..shader = gradient
        ..strokeWidth = barWidth // Scaled Bar Width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + barWidth / 2, top),
        Offset(x + barWidth / 2, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SmoothAmplitudeWaveformPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
          oldDelegate.amplitude != amplitude ||
          oldDelegate.barWidth != barWidth ||
          oldDelegate.spacing != spacing;
}