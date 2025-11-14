import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ringtone_set_mul/ringtone_set_mul.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_to_audio_converter/controllers/network_controller.dart';
import 'package:video_to_audio_converter/views/home_page.dart';
import '../controllers/audio_controller.dart';
import '../main.dart';
import '../utils/prefs.dart';
import '../utils/resources.dart';

// Assuming OutputScreen is defined elsewhere and imported via video_to_audio_converter/views/home_page.dart or similar
// For this single file's context, I'll add a minimal placeholder for OutputScreen
class OutputScreen extends StatelessWidget {
  const OutputScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Output Screen')),
      body: const Center(child: Text('Placeholder Output Screen')),
    );
  }
}


class AudioSavedScreen extends StatefulWidget {
  final String fileName;
  final String audioPath;
  final String bitrate;

  const AudioSavedScreen({
    super.key,
    required this.fileName,
    required this.audioPath,
    required this.bitrate,
  });

  @override
  State<AudioSavedScreen> createState() => _AudioSavedScreenState();
}

class _AudioSavedScreenState extends State<AudioSavedScreen> with SingleTickerProviderStateMixin {
  final AudioController audioController = Get.isRegistered<AudioController>() ? Get.find<AudioController>() : Get.put(AudioController());
  final Color accentColor = const Color(0xFF6C63FF);

  late AnimationController _bodyAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    audioController.initAudio(widget.audioPath);

    // Listen to player state changes to detect when audio completes
    audioController.audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // When audio completes:

        // 1. Explicitly stop playback
        audioController.audioPlayer.stop();

        // 2. Seek to beginning
        audioController.audioPlayer.seek(Duration.zero);

        // 3. ✅ FIX: Update the GetX reactive variable to reflect not playing.
        audioController.isPlaying.value = false;

        if (mounted) {
          setState(() {});
        }
      }
    });

    _bodyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _bodyAnimationController, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bodyAnimationController, curve: Curves.easeIn),
    );

    _bodyAnimationController.forward();
  }

  @override
  void dispose() {
    _bodyAnimationController.dispose();
    audioController.audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    final audioFile = File(widget.audioPath);
    final fileSize = _formatFileSize(audioFile);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Audio Saved',
          style: TextStyle(
            fontSize: 18 * scaleFactor * textScaleFactor,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home, size: 24 * scaleFactor),
            onPressed: () {
              Get.offAll(() => const HomeScreen());
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0 * scaleFactor),
              child: Column(
                children: [
                  _AudioInfoCard(
                    accentColor: accentColor,
                    fileName: widget.fileName,
                    fileSize: fileSize,
                    bitrate: widget.bitrate,
                    scaleFactor: scaleFactor,
                    scaleFactorHeight: scaleFactorHeight,
                    textScaleFactor: textScaleFactor,
                  ),
                  SizedBox(height: 30 * scaleFactorHeight),
                  _AudioPlayerCard(
                    audioController: audioController,
                    accentColor: accentColor,
                    formatDuration: _formatDuration,
                    scaleFactor: scaleFactor,
                    scaleFactorHeight: scaleFactorHeight,
                    textScaleFactor: textScaleFactor,
                  ),
                  SizedBox(height: 30 * scaleFactorHeight),
                  _ActionButtonsRow(
                    accentColor: accentColor,
                    audioController: audioController,
                    audioPath: widget.audioPath,
                    fileName: widget.fileName,
                    scaleFactor: scaleFactor,
                    scaleFactorHeight: scaleFactorHeight,
                    textScaleFactor: textScaleFactor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class _AudioInfoCard extends StatelessWidget {
  final Color accentColor;
  final String fileName;
  final String fileSize;
  final String bitrate;
  final double scaleFactor;
  final double scaleFactorHeight;
  final double textScaleFactor;

  const _AudioInfoCard({
    required this.accentColor,
    required this.fileName,
    required this.fileSize,
    required this.bitrate,
    required this.scaleFactor,
    required this.scaleFactorHeight,
    required this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scaleFactor),
      ),
      padding: EdgeInsets.all(20 * scaleFactor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12 * scaleFactor),
              color: Colors.grey.withOpacity(0.1),
            ),
            padding: EdgeInsets.all(12 * scaleFactor),
            child: Icon(Icons.audio_file, size: 30 * scaleFactor, color: accentColor),
          ),
          SizedBox(width: 16 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversion Successful',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 12 * scaleFactor * textScaleFactor,
                  ),
                ),
                SizedBox(height: 4 * scaleFactorHeight),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17 * scaleFactor * textScaleFactor,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8 * scaleFactorHeight),
                Text(
                  'Size: $fileSize',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13 * scaleFactor * textScaleFactor),
                ),
                SizedBox(height: 2 * scaleFactorHeight),
                Text(
                  'Bitrate: $bitrate kbps',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13 * scaleFactor * textScaleFactor),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 36 * scaleFactor),
        ],
      ),
    );
  }
}

class _AudioPlayerCard extends StatelessWidget {
  final AudioController audioController;
  final Color accentColor;
  final Function(Duration) formatDuration;
  final double scaleFactor;
  final double scaleFactorHeight;
  final double textScaleFactor;

  const _AudioPlayerCard({
    required this.audioController,
    required this.accentColor,
    required this.formatDuration,
    required this.scaleFactor,
    required this.scaleFactorHeight,
    required this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 10 * scaleFactor,
            offset: Offset(0, 5 * scaleFactorHeight),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor, vertical: 24 * scaleFactorHeight),
      child: Column(
        children: [
          Obx(() {
            final isPlaying = audioController.isPlaying.value;
            final position = audioController.position.value;
            final duration = audioController.duration.value;

            // shouldPulse is FALSE when the audio is complete (position == duration)
            // OR when isPlaying is false (which is set on completion now)
            final shouldPulse = isPlaying && position < duration;

            return _PulsatingPlayButton(
              isPlaying: isPlaying,
              shouldPulse: shouldPulse,
              accentColor: accentColor,
              onPressed: () => audioController.togglePlayback(),
              scaleFactor: scaleFactor,
            );
          }),
          SizedBox(height: 20 * scaleFactorHeight),
          Obx(() => SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0 * scaleFactorHeight,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0 * scaleFactor),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16.0 * scaleFactor),
            ),
            child: Slider(
              value: audioController.position.value.inSeconds.toDouble(),
              min: 0.0,
              max: audioController.duration.value.inSeconds.toDouble(),
              activeColor: accentColor,
              inactiveColor: accentColor.withOpacity(0.3),
              onChanged: (value) => audioController.seek(value),
            ),
          )),
          Obx(() => Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0 * scaleFactor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(audioController.position.value),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13 * scaleFactor * textScaleFactor)),
                Text(formatDuration(audioController.duration.value),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13 * scaleFactor * textScaleFactor)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _PulsatingPlayButton extends StatefulWidget {
  final bool isPlaying;
  final bool shouldPulse;
  final Color accentColor;
  final VoidCallback onPressed;
  final double scaleFactor;

  const _PulsatingPlayButton({
    required this.isPlaying,
    required this.shouldPulse,
    required this.accentColor,
    required this.onPressed,
    required this.scaleFactor,
  });

  @override
  State<_PulsatingPlayButton> createState() => _PulsatingPlayButtonState();
}

class _PulsatingPlayButtonState extends State<_PulsatingPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.shouldPulse) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsatingPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse != oldWidget.shouldPulse) {
      if (widget.shouldPulse) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.value = 0.0; // Reset scale to 1.0
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final double pulseValue = widget.shouldPulse ? _scaleAnimation.value : 1.0;
        final double opacityValue = widget.shouldPulse
            ? (1.0 - _animationController.value) * 0.5
            : 0.0;

        final baseSize = 80.0 * widget.scaleFactor;
        final iconSize = 72.0 * widget.scaleFactor;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.shouldPulse)
              Container(
                width: baseSize * pulseValue,
                height: baseSize * pulseValue,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withOpacity(opacityValue),
                ),
              ),
            IconButton(
              icon: Icon(
                widget.isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                size: iconSize,
                color: widget.accentColor,
              ),
              onPressed: widget.onPressed,
            ),
          ],
        );
      },
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  final Color accentColor;
  final AudioController audioController;
  final String audioPath;
  final String fileName;
  final double scaleFactor;
  final double scaleFactorHeight;
  final double textScaleFactor;

  const _ActionButtonsRow({
    required this.accentColor,
    required this.audioController,
    required this.audioPath,
    required this.fileName,
    required this.scaleFactor,
    required this.scaleFactorHeight,
    required this.textScaleFactor,
  });

  void shareContent({required String text, String? filePath}) async {
    try {
      if (filePath != null) {
        await Share.shareXFiles([XFile(filePath)], text: text);
      } else {
        await Share.share(text);
      }
    } catch (e) {
      debugPrint('Error sharing content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButtonTile(
          icon: Icons.folder,
          label: 'Location',
          accentColor: accentColor,
          scaleFactor: scaleFactor,
          scaleFactorHeight: scaleFactorHeight,
          textScaleFactor: textScaleFactor,
          onPressed: () {
            // Correctly navigate to OutputScreen (assuming it's your library screen)
            Get.to(() => const OutputScreen(), transition: Transition.fade);
            audioController.audioPlayer.dispose();
          },
        ),
        _ActionButtonTile(
          icon: Icons.share_rounded,
          label: 'Share',
          accentColor: accentColor,
          scaleFactor: scaleFactor,
          scaleFactorHeight: scaleFactorHeight,
          textScaleFactor: textScaleFactor,
          onPressed: () {
            shareContent(text: fileName, filePath: audioPath);
            audioController.audioPlayer.dispose();
          },
        ),
      ],
    );
  }
}

class _ActionButtonTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onPressed;
  final double scaleFactor;
  final double scaleFactorHeight;
  final double textScaleFactor;

  const _ActionButtonTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onPressed,
    required this.scaleFactor,
    required this.scaleFactorHeight,
    required this.textScaleFactor,
  });

  @override
  State<_ActionButtonTile> createState() => _ActionButtonTileState();
}

class _ActionButtonTileState extends State<_ActionButtonTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    _controller.reverse();
  }

  void _onTapUp(_) {
    _controller.forward();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            child: Column(
              children: [
                Container(
                  width: 65 * widget.scaleFactor,
                  height: 65 * widget.scaleFactor,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16 * widget.scaleFactor),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 32 * widget.scaleFactor,
                    color: widget.accentColor,
                  ),
                ),
                SizedBox(height: 8 * widget.scaleFactorHeight),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 14 * widget.scaleFactor * widget.textScaleFactor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}