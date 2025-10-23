import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/resources.dart';
import '../utils/utils.dart';

class OutputScreenTrimmerView extends StatefulWidget {
  const OutputScreenTrimmerView({super.key});

  @override
  _OutputScreenTrimmerViewState createState() =>
      _OutputScreenTrimmerViewState();
}

class _OutputScreenTrimmerViewState extends State<OutputScreenTrimmerView> {
  List<File> mp3Files = [];
  Map<String, String> fileSizes = {};
  Map<String, Duration> fileDurations = {};

  @override
  void initState() {
    super.initState();
    fetchMp3Files();
  }

  // Fetch all MP3 files from the 'VideoMusic' folder
  Future<void> fetchMp3Files() async {
    Directory musicDir = Directory('/storage/emulated/0/Music/VideoMusic');
    if (await musicDir.exists()) {
      List<File> files = musicDir
          .listSync()
          .where((item) =>
              item.path.endsWith(".mp3") && !item.path.contains(".pending-"))
          .map((item) => File(item.path))
          .toList();

      setState(() {
        mp3Files = files;
      });

      // Load file size and duration for each file
      for (File mp3File in files) {
        String fileName = mp3File.path.split('/').last;
        await _loadFileInfo(mp3File, fileName);
      }
    }
  }

  // Load file size and duration for a given MP3 file
  Future<void> _loadFileInfo(File file, String fileName) async {
    int bytes = await file.length();
    fileSizes[fileName] = _formatBytes(bytes);

    // Load audio duration using just_audio
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.setFilePath(file.path);
    Duration? duration = audioPlayer.duration;
    if (duration != null) {
      fileDurations[fileName] = duration;
    }
    audioPlayer.dispose();

    setState(() {});
  }

  // Format bytes to KB, MB, etc.
  String _formatBytes(int bytes, [int decimals = 2]) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Converted MP3 Files',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: mp3Files.isEmpty
          ? const Center(child: Text('No MP3 files found.'))
          : ListView.builder(
              itemCount: mp3Files.length,
              itemBuilder: (context, index) {
                File mp3File = mp3Files[index];
                String fileName = mp3File.path.split('/').last;

                String fileSize = fileSizes[fileName] ?? 'Calculating...';
                String duration =
                    fileDurations[fileName]?.toString().split('.').first ??
                        'Loading...';

                return ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(08),
                      gradient: const LinearGradient(
                        colors: [Colors.deepPurple, Colors.blue],
                      ),
                    ),
                    child: const Icon(Icons.music_note, color: secondaryColor)
                        .paddingAll(20),
                  ),
                  title: Text(fileName),
                  subtitle: Text('Size: $fileSize\nDuration: $duration'),
                  onTap: () {
                    toastFlutter(
                        toastmessage: 'This feature is comming soon.',
                        color: Colors.greenAccent);
                    // Get.to(() => AudioTrimmerView(
                    //       mp3File,
                    //     ));
                  },
                ).paddingOnly(top: 10);
              },
            ),
    );
  }
}
