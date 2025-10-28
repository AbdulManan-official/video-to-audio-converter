import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ringtone_set_mul/ringtone_set_mul.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_to_audio_converter/controllers/network_controller.dart';
import 'package:video_to_audio_converter/views/home_page.dart';
import '../controllers/audio_controller.dart';
import '../main.dart';
import '../utils/prefs.dart';
import '../utils/resources.dart';
import '../utils/utils.dart';

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

class _AudioSavedScreenState extends State<AudioSavedScreen> {
  final AudioController audioController = Get.put(AudioController());

  @override
  void dispose() {
    audioController.audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioFile = File(widget.audioPath);
    final fileSize = _formatFileSize(audioFile);

    audioController.initAudio(widget.audioPath); // Initialize the audio

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Saved'), // main.dart theme will handle color + style
        centerTitle: true, // optional if not already globally set
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Get.offAll(() => HomeScreen());
            },
          ),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Information Section
          ListTile(
            leading:
                const Icon(Icons.music_note, size: 50, color: Colors.purple),
            title: Text(widget.fileName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$fileSize | ${widget.bitrate} kbps'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),

          // Audio Player Section with Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Audio Slider
                Row(
                  children: [
                    Obx(() => IconButton(
                          icon: Icon(
                            audioController.isPlaying.value
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 35,
                            color: Colors.purple,
                          ),
                          onPressed: () => audioController.togglePlayback(),
                        )),
                    Expanded(
                      child: Obx(() => Slider(
                            value: audioController.position.value.inSeconds
                                .toDouble(),
                            min: 0.0,
                            max: audioController.duration.value.inSeconds
                                .toDouble(),
                            onChanged: (double value) {
                              audioController.seek(value);
                            },
                          )),
                    ),
                  ],
                ),
                // Display current position and total duration
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            '${_formatDuration(audioController.position.value)}/${_formatDuration(audioController.duration.value)}'),
                      ],
                    )),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // Action Buttons for the Audio
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(Icons.folder, 'File location', () {
                    Get.to(() => const OutputScreen(),
                        transition: Transition.fade);
                    audioController.audioPlayer.dispose();
                  }),
                  _actionButton(Icons.share, 'Share', () {
                    // Share audio file logic
                    shareContent(
                        text: widget.fileName, filePath: widget.audioPath);
                    audioController.audioPlayer.dispose();
                  }),
                  _actionButton(Icons.notifications, 'Set as', () async {
                    audioController.audioPlayer.dispose();
                    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                    AndroidDeviceInfo androidInfo =
                        await deviceInfo.androidInfo;
                    int sdkInt = androidInfo.version.sdkInt;

                    if ((sdkInt) >= 29) {
                      RingtoneSetter.setRingtone(widget.audioPath).then(
                        (value) {
                          // log(true.toString());
                          Prefs.setBool('rintone_set', true);
                          Prefs.setString('ringtone_string', widget.fileName);
                          toastFlutter(
                              toastmessage: '${widget.fileName} ringtone set',
                              color: Colors.green[700]);
                        },
                      );
                    } else {
                      RingtoneSet.setRingtoneFromFile(File(widget.audioPath))
                          .then(
                        (value) {
                          // log(true.toString());
                          Prefs.setBool('rintone_set', true);
                          Prefs.setString('ringtone_string', widget.fileName);
                          toastFlutter(
                              toastmessage: '${widget.fileName} ringtone set',
                              color: Colors.green[700]);
                          // Get.back();
                        },
                      );
                    }
                  }),
                ],
              ).paddingAll(16),
            ),
          ),
        ],
      ),
    );
  }

  void shareContent({required String text, String? filePath}) async {
    try {
      if (filePath != null) {
        // Sharing text and file
        await Share.shareXFiles([XFile(filePath)], text: text);
      } else {
        // Sharing only text
        await Share.share(text);
      }
    } catch (e) {
      debugPrint('Error sharing content: $e');
    }
  }

  // Helper function to format file size
  String _formatFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  // Helper method for action buttons
  Widget _actionButton(IconData icon, String label, Function onPressed) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 30),
          onPressed: () => onPressed(),
        ),
        Text(label),
      ],
    );
  }

  // Open file location
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
