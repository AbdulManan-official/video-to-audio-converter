import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_to_audio_converter/views/home_page.dart';
import '../controllers/audio_controller.dart';
import '../main.dart';
import '../utils/responsive_helper.dart';

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

    // ✅ Always initialize audio when screen loads
    audioController.initAudio(widget.audioPath);

    // Listen to player state changes to detect when audio completes
    audioController.audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // When audio completes:
        audioController.audioPlayer.stop();
        audioController.audioPlayer.seek(Duration.zero);
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
    // ✅ DON'T dispose audio player here - let it persist when navigating
    // Only dispose when explicitly needed (e.g., going home)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);
    final audioFile = File(widget.audioPath);
    final fileSize = _formatFileSize(audioFile);

    return WillPopScope(
      // ✅ Handle back button - don't dispose audio
      onWillPop: () async {
        return true; // Allow back navigation without disposing
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: r.fs(28),
            ),
            onPressed: () {
              // ✅ Just navigate back, don't dispose audio
              Get.back();
            },
          ),
          title: Padding(
            padding: EdgeInsets.only(left: r.isTablet() ? r.w(16) : 0),
            child: Text(
              'Audio Saved',
              style: TextStyle(
                fontSize: r.fs(18),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.home,
                size: r.fs(26),
                color: Colors.black,
              ),
              onPressed: () {
                // ✅ Dispose audio only when going home
                audioController.audioPlayer.dispose();
                Get.offAll(() => const HomeScreen());
              },
            ),
          ],
          toolbarHeight: r.h(60),
        ),
        body: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(r.w(16)),
                child: Column(
                  children: [
                    _AudioInfoCard(
                      accentColor: accentColor,
                      fileName: widget.fileName,
                      fileSize: fileSize,
                      bitrate: widget.bitrate,
                      r: r,
                    ),
                    SizedBox(height: r.h(30)),
                    _AudioPlayerCard(
                      audioController: audioController,
                      accentColor: accentColor,
                      formatDuration: _formatDuration,
                      r: r,
                    ),
                    SizedBox(height: r.h(30)),
                    _ActionButtonsRow(
                      accentColor: accentColor,
                      audioController: audioController,
                      audioPath: widget.audioPath,
                      fileName: widget.fileName,
                      r: r,
                    ),
                  ],
                ),
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
  final ResponsiveHelper r;

  const _AudioInfoCard({
    required this.accentColor,
    required this.fileName,
    required this.fileSize,
    required this.bitrate,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.w(20)),
      ),
      padding: EdgeInsets.all(r.w(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r.w(12)),
              color: Colors.grey.withOpacity(0.1),
            ),
            padding: EdgeInsets.all(r.w(12)),
            child: Icon(Icons.audio_file, size: r.w(30), color: accentColor),
          ),
          SizedBox(width: r.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversion Successful',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                    fontSize: r.fs(12),
                  ),
                ),
                SizedBox(height: r.h(4)),
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: r.fs(17),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: r.h(8)),
                Text(
                  'Size: $fileSize',
                  style: TextStyle(color: Colors.grey[600], fontSize: r.fs(13)),
                ),
                SizedBox(height: r.h(2)),
                Text(
                  'Bitrate: $bitrate kbps',
                  style: TextStyle(color: Colors.grey[600], fontSize: r.fs(13)),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: Colors.green, size: r.w(36)),
        ],
      ),
    );
  }
}

class _AudioPlayerCard extends StatelessWidget {
  final AudioController audioController;
  final Color accentColor;
  final Function(Duration) formatDuration;
  final ResponsiveHelper r;

  const _AudioPlayerCard({
    required this.audioController,
    required this.accentColor,
    required this.formatDuration,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.w(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: r.w(10),
            offset: Offset(0, r.h(5)),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: r.w(20), vertical: r.h(24)),
      child: Column(
        children: [
          Obx(() {
            final isPlaying = audioController.isPlaying.value;
            final position = audioController.position.value;
            final duration = audioController.duration.value;

            final shouldPulse = isPlaying && position < duration;

            return _PulsatingPlayButton(
              isPlaying: isPlaying,
              shouldPulse: shouldPulse,
              accentColor: accentColor,
              onPressed: () => audioController.togglePlayback(),
              r: r,
            );
          }),
          SizedBox(height: r.h(20)),
          Obx(() => SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: r.h(4),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: r.w(8)),
              overlayShape: RoundSliderOverlayShape(overlayRadius: r.w(16)),
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
            padding: EdgeInsets.symmetric(horizontal: r.w(4)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(audioController.position.value),
                  style: TextStyle(color: Colors.grey[700], fontSize: r.fs(13)),
                ),
                Text(
                  formatDuration(audioController.duration.value),
                  style: TextStyle(color: Colors.grey[700], fontSize: r.fs(13)),
                ),
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
  final ResponsiveHelper r;

  const _PulsatingPlayButton({
    required this.isPlaying,
    required this.shouldPulse,
    required this.accentColor,
    required this.onPressed,
    required this.r,
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
        _animationController.value = 0.0;
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

        final baseSize = widget.r.w(80);
        final iconSize = widget.r.w(72);

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
  final ResponsiveHelper r;

  const _ActionButtonsRow({
    required this.accentColor,
    required this.audioController,
    required this.audioPath,
    required this.fileName,
    required this.r,
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
          r: r,
          onPressed: () {
            // 🔥 STOP audio before going to next screen
            audioController.audioPlayer.stop();
            audioController.isPlaying.value = false;

            // Now navigate
            Get.to(() => const OutputScreen(), transition: Transition.fade);
          },

        ),
        _ActionButtonTile(
          icon: Icons.share_rounded,
          label: 'Share',
          accentColor: accentColor,
          r: r,
          onPressed: () {
            // ✅ Share WITHOUT disposing audio
            shareContent(text: fileName, filePath: audioPath);
            // Audio keeps playing!
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
  final ResponsiveHelper r;

  const _ActionButtonTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onPressed,
    required this.r,
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
                  width: widget.r.w(65),
                  height: widget.r.w(65),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(widget.r.w(16)),
                  ),
                  child: Icon(
                    widget.icon,
                    size: widget.r.w(32),
                    color: widget.accentColor,
                  ),
                ),
                SizedBox(height: widget.r.h(8)),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: widget.r.fs(14),
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