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
import 'audio_saved_screen.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';

// Color constants
const Color primaryColor = Colors.black87;
const Color secondaryColor = Color(0xFF0081EC);
const Color primaryBlue = Color(0xFF6C63FF);
const Color surfaceColor = Color(0xFFFAFAFA);
const Color primaryDark = Color(0xFF0F172A);

// --- VIDEO PLAYER WIDGET (Original Style with Blue Progress) ---

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
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    if (!widget.controller.value.isInitialized) {
      return Center(
        child: SizedBox(
          height: 200 * scaleFactor,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12 * scaleFactor),
      child: AspectRatio(
        aspectRatio: widget.controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(widget.controller),

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
                      size: 64.0 * scaleFactor,
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
                padding: EdgeInsets.symmetric(horizontal: 10 * scaleFactor, vertical: 4 * scaleFactor),
                color: Colors.black.withOpacity(0.5),
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
                        size: 24 * scaleFactor,
                      ),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        widget.controller,
                        allowScrubbing: true,
                        padding: EdgeInsets.symmetric(horizontal: 8 * scaleFactor),
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
                          color: Colors.white, fontSize: 12 * scaleFactor * textScaleFactor),
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

// --- FILE NAME INPUT (New Style) ---

class FileNameInputCard extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const FileNameInputCard({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "File Name",
          style: TextStyle(
            fontSize: 14 * scaleFactor * textScaleFactor,
            fontWeight: FontWeight.w600,
            color: primaryDark,
          ),
        ),
        SizedBox(height: 8 * scaleFactorHeight),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          style: TextStyle(
            color: primaryDark,
            fontSize: 15 * scaleFactor * textScaleFactor,
          ),
          decoration: InputDecoration(
            hintText: 'Enter file name',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15 * scaleFactor * textScaleFactor,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 14 * scaleFactorHeight),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scaleFactor),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scaleFactor),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scaleFactor),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// --- CONVERSION OPTIONS (New Style) ---

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
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;

    return Row(
      children: [
        Expanded(
          child: _buildOption(
              context,
              'Format',
              selectedFormat,
              onFormatChanged,
              ['MP3(Fast)'],
              scaleFactor
          ),
        ),
        SizedBox(width: 12 * scaleFactor),
        Expanded(
          child: _buildOption(
              context,
              'Bitrate',
              selectedBitrate,
              onBitrateChanged,
              ['128kb/s', '256kb/s', '320kb/s'],
              scaleFactor
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
      double scaleFactor,
      ) {
    final double scaleFactorHeight = MediaQuery.of(context).size.height / 812.0;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14 * scaleFactor * textScaleFactor,
            fontWeight: FontWeight.w600,
            color: primaryDark,
          ),
        ),
        SizedBox(height: 8 * scaleFactorHeight),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            border: Border.all(color: Colors.grey.shade200, width: 1.0 * scaleFactor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: primaryDark, size: 24 * scaleFactor),
              style: TextStyle(
                fontSize: 14 * scaleFactor * textScaleFactor,
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
    final mediaQuery = MediaQuery.of(context);
    final double scaleFactor = mediaQuery.size.width / 375.0;
    final double textScaleFactor = mediaQuery.textScaleFactor;

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
            borderRadius: BorderRadius.circular(16 * scaleFactor),
          ),
          title: Row(
            children: [
              Icon(Icons.volume_off_rounded, color: Colors.red, size: 28 * scaleFactor),
              SizedBox(width: 12 * scaleFactor),
              Text(
                'No Audio Found',
                style: TextStyle(
                  fontSize: 18 * scaleFactor * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'This video does not contain any audio. Please select a video with audio to extract.',
            style: TextStyle(fontSize: 15 * scaleFactor * textScaleFactor, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16 * scaleFactor * textScaleFactor,
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
            borderRadius: BorderRadius.circular(16 * scaleFactor),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28 * scaleFactor),
              SizedBox(width: 12 * scaleFactor),
              Text(
                'File Already Exists',
                style: TextStyle(
                  fontSize: 18 * scaleFactor * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'A file with the name "$trimmedFileName.mp3" already exists. Please rename your file.',
            style: TextStyle(fontSize: 15 * scaleFactor * textScaleFactor, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16 * scaleFactor * textScaleFactor,
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
            borderRadius: BorderRadius.circular(16 * scaleFactor),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28 * scaleFactor),
              SizedBox(width: 12 * scaleFactor),
              Text(
                'File Already Exists',
                style: TextStyle(
                  fontSize: 18 * scaleFactor * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'A file with the name "$trimmedFileName.mp3" already exists. Please rename your file.',
            style: TextStyle(fontSize: 15 * scaleFactor * textScaleFactor, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16 * scaleFactor * textScaleFactor,
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
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24 * scaleFactor),
          onPressed: () => Get.back(),
        ),
        centerTitle: false,
        title: Text(
          'Video Player',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18 * scaleFactor * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20 * scaleFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VideoPlaybackWidget(
              controller: _controller,
              formatDuration: _formatDuration,
            ),
            SizedBox(height: 32 * scaleFactorHeight),
            FileNameInputCard(
              initialValue: fileName,
              onChanged: (value) {
                setState(() {
                  fileName = value;
                });
              },
            ),
            SizedBox(height: 24 * scaleFactorHeight),
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
            SizedBox(height: 40 * scaleFactorHeight),
            Obx(
                  () => SizedBox(
                height: 54 * scaleFactorHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
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
                        width: 20 * scaleFactor,
                        height: 20 * scaleFactor,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Text(
                        'Extracting...',
                        style: TextStyle(
                            fontSize: 16 * scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color:Colors.black
                        ),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.audiotrack, color: Colors.white, size: 24 * scaleFactor),
                      SizedBox(width: 8 * scaleFactor),
                      Text(
                        'EXTRACT AUDIO',
                        style: TextStyle(
                          fontSize: 16 * scaleFactor * textScaleFactor,
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