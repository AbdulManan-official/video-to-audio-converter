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

  const VideoListScreen(
      {super.key, required this.videosInFolder, required this.folderName});

  @override
  Widget build(BuildContext context) {
    final VideoController videoController = Get.put(VideoController());

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Videos in ${path.basename(folderName)}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
      ),
      body: ListView.builder(
        itemCount: videosInFolder.length,
        itemBuilder: (context, index) {
          File videoFile = videosInFolder[index];
          var mbSize = videoController.getFileSizeInMB(videoFile.path);

          return ListTile(
            leading: FutureBuilder<String?>(
              future: videoController.generateThumbnail(
                  videoFile.path), // Load thumbnail asynchronously
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
                  ); // Show a loading indicator while the thumbnail is being generated
                } else if (snapshot.hasData) {
                  return Image.file(
                      height: 250,
                      width: 150,
                      fit: BoxFit.cover,
                      File(snapshot
                          .data!)); // Show the thumbnail once it's loaded
                } else {
                  return const Icon(Icons.videocam); // Fallback if no thumbnail
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
                  fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$mbSize MB',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
            onTap: () {
              Get.to(() => VideoPlayerScreen(videoPath: videoFile.path),
                  transition: Transition.fade); // Navigate to video player
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
    // Initialize file name from video file
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
            // Video player placeholder
            Container(
              height: 200,
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // File Name input
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

            // Format and Bitrate dropdowns
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Format
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Format"),
                    DropdownButton<String>(
                      value: selectedFormat,
                      items: <String>['MP3(Fast)', 'WAV', 'AAC']
                          .map((String value) {
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

                // Bitrate
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

            // Trim and Edit Tag buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Implement Trim functionality
                    print("Trim pressed");
                  },
                  child: const Text("TRIM"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implement Edit Tag functionality
                    print("Edit Tag pressed");
                  },
                  child: const Text("EDIT TAG"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Extract Audio button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                ),
                onPressed: () {
                  // Call extraction method here
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
