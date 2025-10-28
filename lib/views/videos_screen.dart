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
        backgroundColor: secondaryColor,
        title: const Text(
          'Recent Videos',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (videoController.videos.isEmpty &&
            videoController.videoFolders.isEmpty) {
          return const Center(child: Text('No videos found.'));
        } else {
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: videoController.isFolder.value
                ? videoController.videoFolders.length
                : videoController.videos.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              if (videoController.isFolder.value) {
                // Folder mode
                String folderName =
                videoController.videoFolders.keys.elementAt(index);
                List<File> videosInFolder =
                videoController.videoFolders[folderName]!;

                return InkWell(
                  onTap: () {
                    Get.to(
                            () => VideoListScreen(
                            videosInFolder: videosInFolder,
                            folderName: folderName),
                        transition: Transition.fade);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.folder,
                            color: secondaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                path.basename(folderName),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${videosInFolder.length} videos",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                // Single video mode
                final video = videoController.videos[index];
                var mbSize = videoController.getFileSizeInMB(video.path);

                return InkWell(
                  onTap: () {
                    Get.to(() => VideoPlayerScreen(videoPath: video.path),
                        transition: Transition.fade);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Thumbnail with shimmer loading
                        FutureBuilder<String?>(
                          future: videoController.generateThumbnail(video.path),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  width: 100,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            } else if (snapshot.hasData) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(snapshot.data!),
                                  height: 75,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              return Container(
                                width: 100,
                                height: 75,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.videocam,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        // Video details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                path.basename(video.path),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.storage,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$mbSize MB',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.video_library,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      path.dirname(video.path).split('/').last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Play icon - centered vertically
                        Center(

                            child: Icon(
                              Icons.chevron_right_sharp,
                              color: Colors.grey,
                              size: 26,
                            ),
                          ),

                      ],
                    ),
                  ),
                );
              }
            },
          );
        }
      }),
    );
  }
}