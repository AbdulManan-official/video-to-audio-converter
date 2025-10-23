import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import '../controllers/video_controller.dart';
import 'video_list_screen.dart';
import 'video_palyer_screen.dart';
import 'package:path/path.dart' as path;

class VideoView extends StatelessWidget {
  const VideoView({super.key});

  @override
  Widget build(BuildContext context) {
    final VideoController videoController = Get.put(VideoController());

    return Scaffold(
      appBar: AppBar(
        actions: [
          Obx(
            () => IconButton(
                onPressed: () {
                  videoController.isFolder.value =
                      !videoController.isFolder.value;
                },
                icon: videoController.isFolder.value == false
                    ? const Icon(
                        Icons.folder,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.folder_off,
                        color: Colors.white,
                      )),
          )
        ],
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        title: const Text(
          'Recent Videos',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      body: Obx(() {
        if (videoController.videos.isEmpty &&
            videoController.videoFolders.isEmpty) {
          return const Center(child: Text('No videos found.'));
        } else {
          return ListView.builder(
            itemCount: videoController.isFolder.value
                ? videoController.videoFolders.length
                : videoController.videos.length,
            itemBuilder: (context, index) {
              if (videoController.isFolder.value) {
                // Folder mode
                String folderName =
                    videoController.videoFolders.keys.elementAt(index);
                List<File> videosInFolder =
                    videoController.videoFolders[folderName]!;

                return ListTile(
                  title: Text(path.basename(folderName)), // Show folder name
                  subtitle: Text("${videosInFolder.length} videos"),
                  trailing: const Icon(Icons.folder),
                  onTap: () {
                    // Navigate to the video list screen for this folder
                    Get.to(
                        () => VideoListScreen(
                            videosInFolder: videosInFolder,
                            folderName: folderName),
                        transition: Transition.fade);
                  },
                );
              } else {
                // Single video mode
                final video = videoController.videos[index];
                var mbSize = videoController.getFileSizeInMB(video.path);

                return ListTile(
                  leading: FutureBuilder<String?>(
                    future: videoController.generateThumbnail(
                        video.path), // Load thumbnail asynchronously
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
                        // Show a loading indicator while the thumbnail is being generated
                      } else if (snapshot.hasData) {
                        return Image.file(
                            height: 250,
                            width: 150,
                            fit: BoxFit.cover,
                            File(snapshot
                                .data!)); // Show the thumbnail once it's loaded
                      } else {
                        return const Icon(
                            Icons.videocam); // Fallback if no thumbnail
                      }
                    },
                  ),
                  title: Text(
                    path.basename(video.path),
                    overflow: TextOverflow.ellipsis,
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
                    Get.to(() => VideoPlayerScreen(videoPath: video.path),
                        transition:
                            Transition.fade); // Navigate to video player
                  },
                );
              }
            },
          );
        }
      }),
    );
  }
}
