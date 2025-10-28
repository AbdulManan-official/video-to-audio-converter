import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:shimmer/shimmer.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import '../controllers/video_controller.dart';
import 'video_palyer_screen.dart';

class VideoListScreen extends StatelessWidget {
  final List<File> videosInFolder;
  final String folderName;

  const VideoListScreen({
    super.key,
    required this.videosInFolder,
    required this.folderName,
  });

  @override
  Widget build(BuildContext context) {
    final VideoController videoController = Get.put(VideoController());

    return Scaffold(
      appBar: AppBar(
        title: Text("Videos in ${path.basename(folderName)}"),
        // Theme from main.dart automatically applies:
        // - centered title
        // - bold white text
        // - consistent color (secondaryColor or primaryColor)
      ),
      body: ListView.builder(
        itemCount: videosInFolder.length,
        itemBuilder: (context, index) {
          File videoFile = videosInFolder[index];
          var mbSize = videoController.getFileSizeInMB(videoFile.path);

          return ListTile(
            leading: FutureBuilder<String?>(
              future: videoController.generateThumbnail(videoFile.path),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 150,
                      height: 250,
                      color: Colors.white,
                    ),
                  );
                } else if (snapshot.hasData) {
                  return Image.file(
                    File(snapshot.data!),
                    height: 250,
                    width: 150,
                    fit: BoxFit.cover,
                  );
                } else {
                  return const Icon(Icons.videocam);
                }
              },
            ),
            title: Text(
              path.basename(videoFile.path),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '$mbSize MB',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
            onTap: () {
              Get.to(
                    () => VideoPlayerScreen(videoPath: videoFile.path),
                transition: Transition.fade,
              );
            },
          ).paddingSymmetric(vertical: 6);
        },
      ),
    );
  }
}

class VideoDetailsScreen extends StatefulWidget {
  final File videoFile;

  const VideoDetailsScreen({super.key, required this.videoFile});

  @override
  State<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends State<VideoDetailsScreen> {
  String fileName = '';
  String selectedFormat = 'MP3(Fast)';
  String selectedBitrate = '128kb/s';

  @override
  void initState() {
    super.initState();
    fileName = path.basenameWithoutExtension(widget.videoFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Extract Audio"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            const Text("File Name"),
            TextFormField(
              initialValue: fileName,
              onChanged: (value) {
                setState(() {
                  fileName = value;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
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
                      items: <String>['MP3(Fast)', 'WAV', 'AAC']
                          .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                          .toList(),
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
                          .map((String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ))
                          .toList(),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => print("Trim pressed"),
                  child: const Text("TRIM"),
                ),
                ElevatedButton(
                  onPressed: () => print("Edit Tag pressed"),
                  child: const Text("EDIT TAG"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                ),
                onPressed: () {
                  print("Extracting audio from ${widget.videoFile.path}");
                },
                child: const Text("EXTRACT AUDIO"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
