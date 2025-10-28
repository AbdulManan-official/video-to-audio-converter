// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:video_to_audio_converter/controllers/controllers.dart';
import 'package:path/path.dart' as path;
import 'package:video_to_audio_converter/utils/utils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'audio_saved_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  final ConversionController conversionController =
  Get.put(ConversionController());
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

    fileName = path.basenameWithoutExtension(widget.videoPath);
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ad unit ID
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
              _loadInterstitialAd(); // Preload next ad
              _handleConversionAndNavigation();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _isAdLoaded = false;
              _loadInterstitialAd(); // Preload next ad
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

  void _handleConversionAndNavigation() async {
    await conversionController.convertVideoToAudio(widget.videoPath, fileName);
    if (conversionController.conversionResult.value != null) {
      final audioPath = conversionController.conversionResult.value!.audioPath;
      _controller.dispose();
      Get.to(
            () => AudioSavedScreen(
          fileName: fileName,
          bitrate: selectedBitrate,
          audioPath: audioPath,
        ),
        transition: Transition.fade,
      );
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Video Player',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_controller.value.isInitialized)
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_controller),
                      Positioned(
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: secondaryColor,
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
              const Text(
                "File Name",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: fileName,
                onChanged: (value) {
                  setState(() {
                    fileName = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Format"),
                      DropdownButton<String>(
                        value: selectedFormat,
                        items: <String>['MP3(Fast)'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedFormat = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bitrate"),
                      DropdownButton<String>(
                        value: selectedBitrate,
                        items: <String>['128kb/s', '256kb/s', '320kb/s']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedBitrate = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Obx(
                      () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 50),
                    ),
                    onPressed: () async {
                      if (_isAdLoaded && _interstitialAd != null) {
                        _interstitialAd!.show();
                        // Conversion happens after ad dismissal via callback
                      } else {
                        print('No ad loaded, proceeding with conversion');
                        _handleConversionAndNavigation();
                      }
                    },
                    child: conversionController.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "EXTRACT AUDIO",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}