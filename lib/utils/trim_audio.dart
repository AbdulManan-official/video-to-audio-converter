// utils/trim_audio.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;

// Use the colors from ringtone_main.dart (primaryColor: 0xFF6C63FF)
const Color _primaryColor = Color(0xFF6C63FF);
const Color _lightPrimary = Color(0xFF6C63FF);
const Color _darkGrey = Color(0xFF424242);

// Keeping the original name of the callback: onTrimmed
typedef OnTrimmedCallback = void Function(double startMs, double durationMs);

class TrimAudioWidget extends StatefulWidget {
  final File audioFile;
  final OnTrimmedCallback onTrimmed;
  final VoidCallback? onAudioPlayStarted; // NEW: Callback when audio starts playing

  const TrimAudioWidget({
    super.key,
    required this.audioFile,
    required this.onTrimmed,
    this.onAudioPlayStarted, // NEW
  });

  @override
  State<TrimAudioWidget> createState() => TrimAudioWidgetState(); // CHANGED: Made public (removed underscore)
}

// CHANGED: Removed underscore to make it public
class TrimAudioWidgetState extends State<TrimAudioWidget> {
  late AudioPlayer _player;

  double _startMs = 0;
  double _durationMs = 30000; // Default to 30 seconds
  double _maxMs = 30000; // Changed from 1 to 30000 as default
  bool _isLoadingAudio = true;
  bool _hasError = false;

  // Calculated end time based on start and duration
  double get _endMs => (_startMs + _durationMs).clamp(0, _maxMs);

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _loadAudio();
  }

  @override
  void didUpdateWidget(covariant TrimAudioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioFile.path != oldWidget.audioFile.path) {
      _loadAudio();
    }
  }

  Future<void> _loadAudio() async {
    setState(() {
      _isLoadingAudio = true;
      _hasError = false;
    });

    try {
      await _player.stop();
      await _player.setFilePath(widget.audioFile.path);

      // Wait a bit for duration to be available
      await Future.delayed(const Duration(milliseconds: 100));

      final duration = _player.duration;

      if (duration == null || duration.inMilliseconds <= 0) {
        // If duration is not available, set a reasonable default
        setState(() {
          _maxMs = 30000;
          _durationMs = 30000;
          _startMs = 0;
          _isPlaying = false;
          _hasError = true;
          _isLoadingAudio = false;
        });
      } else {
        setState(() {
          _maxMs = duration.inMilliseconds.toDouble();
          // Set duration to minimum of 30 seconds or total duration
          _durationMs = duration.inMilliseconds.toDouble() > 30000
              ? 30000.0
              : duration.inMilliseconds.toDouble();
          _startMs = 0;
          _isPlaying = false;
          _hasError = false;
          _isLoadingAudio = false;
        });
      }

      // Initial parameters send back
      _sendTrimParams();
    } catch (e) {
      debugPrint('Error loading audio: $e');
      setState(() {
        _maxMs = 30000;
        _durationMs = 30000;
        _startMs = 0;
        _hasError = true;
        _isLoadingAudio = false;
      });
      _sendTrimParams();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(double ms) {
    final d = Duration(milliseconds: ms.toInt());
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  void _sendTrimParams() {
    widget.onTrimmed(_startMs, _durationMs);
  }

  // NEW: Public method to stop audio from parent widget
  void stopAudio() {
    if (_isPlaying) {
      _player.stop();
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  _playPreview() {
    if (_isPlaying) {
      _player.stop();
      setState(() => _isPlaying = false);
    } else {
      // NEW: Notify parent that audio is starting
      widget.onAudioPlayStarted?.call();

      _player.seek(Duration(milliseconds: _startMs.toInt()));
      _player.play();
      setState(() => _isPlaying = true);

      _player.positionStream.listen((pos) {
        if (pos.inMilliseconds >= _endMs && _isPlaying) {
          _player.pause();
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      });

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() => _isPlaying = false);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Responsive Scaling Setup ---
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;
    // -------------------------------

    // UI variables
    final fileName = p.basename(widget.audioFile.path);
    final fileDuration = _format(_maxMs); // Full duration
    final startText = _format(_startMs);
    final durationText = '${(_durationMs / 1000).round()}s';
    final previewRangeText = "$startText → ${_format(_endMs)}";

    // Calculate safe max for start slider
    final startSliderMax = (_maxMs - _durationMs).clamp(0.0, _maxMs);

    return Padding( // WRAPPED THE CONTENT WITH PADDING
      padding: EdgeInsets.symmetric(
        horizontal: 18 * scaleFactor, // Added Horizontal Padding
        vertical: 10 * scaleFactorHeight, // Added a small Vertical Padding
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Selected Audio File Card (Top)
          Container(
            padding: EdgeInsets.all(14 * scaleFactor),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14 * scaleFactor),
              border: Border.all(color: _primaryColor.withOpacity(0.8), width: 1.5 * scaleFactor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48 * scaleFactor,
                  height: 48 * scaleFactor,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10 * scaleFactor),
                    gradient: LinearGradient(
                      colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.audio_file, color: Colors.white, size: 26 * scaleFactor),
                ),
                SizedBox(width: 14 * scaleFactor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15 * scaleFactor * textScaleFactor,
                          fontWeight: FontWeight.w600,
                          color: _darkGrey,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3 * scaleFactorHeight),
                      Text(
                        _hasError ? 'Duration unavailable' : fileDuration,
                        style: TextStyle(
                          fontSize: 13 * scaleFactor * textScaleFactor,
                          color: _hasError ? Colors.red[600] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * scaleFactor),
                if (_isLoadingAudio)
                  Container(
                    width: 46 * scaleFactor,
                    height: 46 * scaleFactor,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20 * scaleFactor,
                        height: 20 * scaleFactor,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5 * scaleFactor,
                          valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
                        ),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _hasError ? null : _playPreview,
                    borderRadius: BorderRadius.circular(23 * scaleFactor),
                    child: Container(
                      width: 46 * scaleFactor,
                      height: 46 * scaleFactor,
                      decoration: BoxDecoration(
                        gradient: _hasError
                            ? null
                            : LinearGradient(
                          colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        color: _hasError ? Colors.grey[400] : null,
                        shape: BoxShape.circle,
                        boxShadow: _hasError ? null : [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26 * scaleFactor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 18 * scaleFactorHeight), // REDUCED from 24

          // Show loading or error state
          if (_isLoadingAudio)
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 14 * scaleFactorHeight),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10 * scaleFactor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18 * scaleFactor,
                      height: 18 * scaleFactor,
                      child: CircularProgressIndicator(strokeWidth: 2.5 * scaleFactor),
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Text(
                      'Loading audio...',
                      style: TextStyle(
                        fontSize: 14 * scaleFactor * textScaleFactor,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError)
            Container(
              padding: EdgeInsets.all(14 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10 * scaleFactor),
                border: Border.all(color: Colors.orange.shade300, width: 1.5 * scaleFactor),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 22 * scaleFactor),
                  SizedBox(width: 12 * scaleFactor),
                  Expanded(
                    child: Text(
                      'Could not load audio duration. Using default 30s trim.',
                      style: TextStyle(
                        fontSize: 13 * scaleFactor * textScaleFactor,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
              // 2. Start Time Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.content_cut_rounded, size: 19 * scaleFactor, color: Colors.grey[700]),
                      SizedBox(width: 6 * scaleFactor),
                      Text(
                        "Start Time",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          fontSize: 14 * scaleFactor * textScaleFactor,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor, vertical: 5 * scaleFactorHeight),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6 * scaleFactor),
                    ),
                    child: Text(
                      startText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        fontSize: 13 * scaleFactor * textScaleFactor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2 * scaleFactorHeight), // REDUCED from 4
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.0 * scaleFactorHeight,
                  activeTrackColor: Colors.grey.shade800,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Colors.grey[800],
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10 * scaleFactor),
                  overlayColor: Colors.grey.withOpacity(0.15),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20 * scaleFactor),
                ),
                child: Slider(
                  min: 0,
                  max: startSliderMax > 0 ? startSliderMax : 0,
                  value: _startMs.clamp(0.0, startSliderMax),
                  onChanged: (v) {
                    setState(() => _startMs = v);
                    _sendTrimParams();
                  },
                ),
              ),
              SizedBox(height: 14 * scaleFactorHeight), // REDUCED from 18

              // 3. Duration Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Duration",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor, vertical: 5 * scaleFactorHeight),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6 * scaleFactor),
                      border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1 * scaleFactor),
                    ),
                    child: Text(
                      durationText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                        fontSize: 13 * scaleFactor * textScaleFactor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2 * scaleFactorHeight), // REDUCED from 4
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6.0 * scaleFactorHeight,
                  activeTrackColor: _primaryColor,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: _primaryColor,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10 * scaleFactor),
                  overlayColor: _primaryColor.withOpacity(0.15),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 20 * scaleFactor),
                ),
                child: Slider(
                  min: 500,
                  max: _maxMs > 500 ? _maxMs : 500,
                  value: _durationMs.clamp(500.0, _maxMs),
                  onChanged: (v) {
                    setState(() {
                      _durationMs = v;
                      final maxStart = (_maxMs - _durationMs).clamp(0.0, _maxMs);
                      _startMs = _startMs.clamp(0.0, maxStart);
                    });
                    _sendTrimParams();
                  },
                ),
              ),
              SizedBox(height: 16 * scaleFactorHeight), // REDUCED from 20

              Container(
                padding: EdgeInsets.symmetric(horizontal: 14 * scaleFactor, vertical: 12 * scaleFactorHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10 * scaleFactor),
                  border: Border.all(color:Colors.black, width: 1 * scaleFactor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Preview Range",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 14 * scaleFactor * textScaleFactor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      previewRangeText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                        fontSize: 14 * scaleFactor * textScaleFactor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8 * scaleFactorHeight), // REDUCED from 12

              // Visual progress bar for the range
              LayoutBuilder(
                builder: (context, constraints) {
                  double totalWidth = constraints.maxWidth;
                  double startPixel = _maxMs > 0 ? totalWidth * (_startMs / _maxMs) : 0;
                  double durationPixel = _maxMs > 0 ? totalWidth * (_durationMs / _maxMs) : totalWidth;

                  const double activeBarHeight = 15.0;
                  const double trackHeight = 10.0;
                  const double topOffset = (activeBarHeight - trackHeight) / 2.0;

                  return Container(
                    height: activeBarHeight * scaleFactorHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(activeBarHeight / 2 * scaleFactor),
                    ),
                    child: Stack(
                      children: [
                        // Background Bar
                        Positioned(
                          top: topOffset * scaleFactorHeight,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: trackHeight * scaleFactorHeight,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(trackHeight / 2 * scaleFactor),
                            ),
                          ),
                        ),
                        // Active Range Bar (Draggable)
                        Positioned(
                          left: startPixel,
                          top: 0,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              if (_maxMs <= 0) return;

                              double deltaMs = (details.primaryDelta ?? 0) * (_maxMs / totalWidth);
                              final maxStart = (_maxMs - _durationMs).clamp(0.0, _maxMs);
                              double newStart = (_startMs + deltaMs).clamp(0.0, maxStart);

                              setState(() {
                                _startMs = newStart;
                              });
                              _sendTrimParams();
                            },
                            child: Container(
                              height: activeBarHeight * scaleFactorHeight,
                              width: durationPixel.clamp(0.0, totalWidth - startPixel),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(activeBarHeight / 2 * scaleFactor),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.3),
                                    blurRadius: 6 * scaleFactor,
                                    offset: Offset(0, 2 * scaleFactorHeight),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 4 * scaleFactor,
                                  height: 10 * scaleFactorHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(2 * scaleFactor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          SizedBox(height: 12 * scaleFactorHeight), // REDUCED from 16
        ],
      ),
    );
  }
}