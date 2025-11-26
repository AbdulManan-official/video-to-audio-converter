// Responsive Done
// ignore_for_file: library_private_types_in_public_api, unnecessary_null_comparison

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:video_to_audio_converter/controllers/controllers.dart';
import 'package:path/path.dart' as path;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/resources.dart';
import '../utils/responsive_helper.dart';
import 'audio_saved_screen.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';

// Color constants
const Color primaryColor = Colors.black87;
const Color secondaryColor = Color(0xFF0081EC);
const Color primaryBlue = Color(0xFF6C63FF);
const Color surfaceColor = Color(0xFFFAFAFA);
const Color primaryDark = Color(0xFF0F172A);

// --- VIDEO PLAYER WIDGET (Responsive) ---

class VideoPlaybackWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final String Function(Duration) formatDuration;

  const VideoPlaybackWidget({
    super.key,
    required this.controller,
    required this.formatDuration,
  });

  @override
  State<VideoPlaybackWidget> createState() => _VideoPlaybackWidgetState();
}

class _VideoPlaybackWidgetState extends State<VideoPlaybackWidget> {
  bool _isFullScreen = false;

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _FullScreenVideoPlayer(
            controller: widget.controller,
            formatDuration: widget.formatDuration,
            onExit: () {
              setState(() {
                _isFullScreen = false;
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    if (!widget.controller.value.isInitialized) {
      return Center(
        child: SizedBox(
          height: r.h(200),
          child: const CircularProgressIndicator(),
        ),
      );
    }

    // Set specific height and width for video container
    final videoHeight = r.isTablet() ? r.h(300) : r.h(220);
    final videoWidth = double.infinity;

    return Container(
      height: videoHeight,
      width: videoWidth,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(r.w(12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r.w(12)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player centered and fitted
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Play/Pause Overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    widget.controller.value.isPlaying
                        ? widget.controller.pause()
                        : widget.controller.play();
                  });
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  reverseDuration: const Duration(milliseconds: 200),
                  child: widget.controller.value.isPlaying
                      ? const SizedBox.shrink()
                      : Container(
                    key: const ValueKey('playback-overlay'),
                    alignment: Alignment.center,
                    color: Colors.black38,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: r.w(64),
                    ),
                  ),
                ),
              ),
            ),

            // Controls Bar with Blue Progress
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.w(10),
                  vertical: r.h(4),
                ),
                color: Colors.black.withOpacity(0.7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          widget.controller.value.isPlaying
                              ? widget.controller.pause()
                              : widget.controller.play();
                        });
                      },
                      icon: Icon(
                        widget.controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: Colors.white,
                        size: r.w(24),
                      ),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        widget.controller,
                        allowScrubbing: true,
                        padding: EdgeInsets.symmetric(horizontal: r.w(8)),
                        colors: const VideoProgressColors(
                          playedColor: primaryBlue,
                          bufferedColor: Colors.grey,
                          backgroundColor: Colors.black26,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.formatDuration(widget.controller.value.position)} / ${widget.formatDuration(widget.controller.value.duration)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: r.fs(11),
                      ),
                    ),
                    SizedBox(width: r.w(4)),
                    IconButton(
                      onPressed: _toggleFullScreen,
                      icon: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: r.w(24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FULLSCREEN VIDEO PLAYER ---

class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String Function(Duration) formatDuration;
  final VoidCallback onExit;

  const _FullScreenVideoPlayer({
    required this.controller,
    required this.formatDuration,
    required this.onExit,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Auto-hide controls after 3 seconds
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Controls Overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  children: [
                    // Top Bar with Back Button
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                widget.onExit();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Center Play/Pause Button
                    if (!widget.controller.value.isPlaying)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            widget.controller.play();
                          });
                          _hideControlsAfterDelay();
                        },
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),

                    const Spacer(),

                    // Bottom Controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          VideoProgressIndicator(
                            widget.controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: primaryBlue,
                              bufferedColor: Colors.grey,
                              backgroundColor: Colors.black26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    widget.controller.value.isPlaying
                                        ? widget.controller.pause()
                                        : widget.controller.play();
                                  });
                                  if (widget.controller.value.isPlaying) {
                                    _hideControlsAfterDelay();
                                  }
                                },
                                icon: Icon(
                                  widget.controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              Text(
                                '${widget.formatDuration(widget.controller.value.position)} / ${widget.formatDuration(widget.controller.value.duration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  widget.onExit();
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(
                                  Icons.fullscreen_exit,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FILE NAME INPUT (Responsive) ---

class FileNameInputCard extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const FileNameInputCard({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<FileNameInputCard> createState() => _FileNameInputCardState();
}

class _FileNameInputCardState extends State<FileNameInputCard> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);

    // Auto-select text when field gains focus
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _textController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _textController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "File Name",
          style: TextStyle(
            fontSize: r.fs(14),
            fontWeight: FontWeight.w600,
            color: primaryDark,
          ),
        ),
        SizedBox(height: r.h(8)),
        TextFormField(
          controller: _textController,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          style: TextStyle(
            color: primaryDark,
            fontSize: r.fs(15),
          ),
          decoration: InputDecoration(
            hintText: 'Enter file name',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: r.fs(15),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: r.w(16),
              vertical: r.h(14),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.w(12)),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.w(12)),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.w(12)),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// --- CONVERSION OPTIONS (Responsive) ---

class ConversionOptionsCard extends StatelessWidget {
  final String selectedFormat;
  final ValueChanged<String?> onFormatChanged;
  final String selectedBitrate;
  final ValueChanged<String?> onBitrateChanged;

  const ConversionOptionsCard({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
    required this.selectedBitrate,
    required this.onBitrateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return Row(
      children: [
        Expanded(
          child: _buildOption(
            context,
            'Format',
            selectedFormat,
            onFormatChanged,
            ['MP3(Fast)'],
            r,
          ),
        ),
        SizedBox(width: r.w(12)),
        Expanded(
          child: _buildOption(
            context,
            'Bitrate',
            selectedBitrate,
            onBitrateChanged,
            ['128kb/s', '256kb/s', '320kb/s'],
            r,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
      BuildContext context,
      String label,
      String value,
      ValueChanged<String?> onChanged,
      List<String> items,
      ResponsiveHelper r,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: r.fs(14),
            fontWeight: FontWeight.w600,
            color: primaryDark,
          ),
        ),
        SizedBox(height: r.h(8)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: r.w(12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.w(12)),
            border: Border.all(
              color: Colors.grey.shade200,
              width: r.w(1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: primaryDark,
                size: r.w(24),
              ),
              style: TextStyle(
                fontSize: r.fs(14),
                color: primaryDark,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              items: items.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// --- MAIN SCREEN ---

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  final ConversionController conversionController = Get.put(ConversionController());
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  String fileName = '';
  String selectedFormat = 'MP3(Fast)';
  String selectedBitrate = '128kb/s';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    fileName = path.basenameWithoutExtension(widget.videoPath);
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              print('Interstitial ad dismissed');
              ad.dispose();
              _isAdLoaded = false;
              _loadInterstitialAd();
              _handleConversionAndNavigation();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _isAdLoaded = false;
              _loadInterstitialAd();
              _handleConversionAndNavigation();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  Future<bool> _checkIfVideoHasAudio() async {
    try {
      final session = await FFprobeKit.getMediaInformation(widget.videoPath);
      final information = session.getMediaInformation();

      if (information == null) {
        return false;
      }

      final streams = information.getStreams();
      if (streams == null || streams.isEmpty) {
        return false;
      }

      for (var stream in streams) {
        final codecType = stream.getType();
        if (codecType != null && codecType.toLowerCase() == 'audio') {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking audio stream: $e');
      return true;
    }
  }

  Future<bool> _validateBeforeConversion() async {
    final r = ResponsiveHelper(context);
    final trimmedFileName = fileName.trim();

    if (trimmedFileName.isEmpty) {
      toastFlutter(
        toastmessage: 'Please enter a file name',
        color: Colors.red[700],
      );
      return false;
    }

    final hasAudio = await _checkIfVideoHasAudio();
    if (!hasAudio) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.w(16)),
          ),
          title: Row(
            children: [
              Icon(Icons.volume_off_rounded, color: Colors.red, size: r.w(28)),
              SizedBox(width: r.w(12)),
              Flexible(
                child: Text(
                  'No Audio Found',
                  style: TextStyle(
                    fontSize: r.fs(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This video does not contain any audio. Please select a video with audio to extract.',
            style: TextStyle(fontSize: r.fs(15), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: r.fs(16),
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      return false;
    }

    final audioDir = Directory('/storage/emulated/0/Download/Converted_Audios');
    final audioPath = '${audioDir.path}/$trimmedFileName.mp3';

    if (await File(audioPath).exists()) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.w(16)),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: r.w(28)),
              SizedBox(width: r.w(12)),
              Flexible(
                child: Text(
                  'File Already Exists',
                  style: TextStyle(
                    fontSize: r.fs(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'A file with the name "$trimmedFileName.mp3" already exists. Please rename your file.',
            style: TextStyle(fontSize: r.fs(15), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: r.fs(16),
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      return false;
    }

    final videoMusicDir = Directory('/storage/emulated/0/Music/VideoMusic');
    final videoMusicPath = '${videoMusicDir.path}/$trimmedFileName.mp3';

    if (await File(videoMusicPath).exists()) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.w(16)),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: r.w(28)),
              SizedBox(width: r.w(12)),
              Flexible(
                child: Text(
                  'File Already Exists',
                  style: TextStyle(
                    fontSize: r.fs(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'A file with the name "$trimmedFileName.mp3" already exists. Please rename your file.',
            style: TextStyle(fontSize: r.fs(15), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: r.fs(16),
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      return false;
    }

    return true;
  }

  void _handleConversionAndNavigation() async {
    await conversionController.convertVideoToAudio(widget.videoPath, fileName);

    if (conversionController.conversionResult.value != null) {
      final resultAudioPath = conversionController.conversionResult.value!.audioPath;

      if (_controller.value.isPlaying) {
        _controller.pause();
      }

      await Get.to(
            () => AudioSavedScreen(
          fileName: fileName,
          bitrate: selectedBitrate,
          audioPath: resultAudioPath,
        ),
        transition: Transition.fade,
      );

      if (mounted) {
        await _controller.seekTo(Duration.zero);
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _controller.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: r.w(24)),
          onPressed: () => Get.back(),
        ),
        centerTitle: false,
        title: Padding(
          padding: EdgeInsets.only(left: r.isTablet() ? r.w(16) : 0),
          child: Text(
            'Video Player',
            style: TextStyle(
              color: Colors.black,
              fontSize: r.fs(18),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        toolbarHeight: r.h(60),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(r.w(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VideoPlaybackWidget(
              controller: _controller,
              formatDuration: _formatDuration,
            ),
            SizedBox(height: r.h(32)),
            FileNameInputCard(
              initialValue: fileName,
              onChanged: (value) {
                setState(() {
                  fileName = value;
                });
              },
            ),
            SizedBox(height: r.h(24)),
            ConversionOptionsCard(
              selectedFormat: selectedFormat,
              onFormatChanged: (newValue) {
                setState(() {
                  selectedFormat = newValue!;
                });
              },
              selectedBitrate: selectedBitrate,
              onBitrateChanged: (newValue) {
                setState(() {
                  selectedBitrate = newValue!;
                });
              },
            ),
            SizedBox(height: r.h(40)),
            Obx(
                  () => SizedBox(
                height: r.h(54),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(r.w(12)),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed: conversionController.isLoading.value
                      ? null
                      : () async {
                    final isValid = await _validateBeforeConversion();

                    if (!isValid) {
                      return;
                    }

                    if (_isAdLoaded && _interstitialAd != null) {
                      _interstitialAd!.show();
                    } else {
                      _handleConversionAndNavigation();
                    }
                  },
                  child: conversionController.isLoading.value
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: r.w(20),
                        height: r.w(20),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: r.w(12)),
                      Text(
                        'Extracting...',
                        style: TextStyle(
                          fontSize: r.fs(16),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.audiotrack, color: Colors.white, size: r.w(24)),
                      SizedBox(width: r.w(8)),
                      Text(
                        'EXTRACT AUDIO',
                        style: TextStyle(
                          fontSize: r.fs(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}