import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../controllers/video_controller.dart';

class VideoFolderView extends StatelessWidget {
  const VideoFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final VideoController videoController = Get.put(VideoController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Folders'),
        backgroundColor: Colors.deepPurple,
        actions: [
          Obx(() => IconButton(
                onPressed: () {
                  videoController.isFolder.value =
                      !videoController.isFolder.value;
                },
                icon: videoController.isFolder.value
                    ? const Icon(Icons.folder_open)
                    : const Icon(Icons.folder),
              ))
        ],
      ),
      body: Obx(() {
        if (videoController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (videoController.videos.isEmpty &&
            videoController.videoFolders.isEmpty) {
          return const Center(child: Text('No videos found.'));
        }

        // Display folders or single videos depending on the isFolder flag
        return videoController.isFolder.value
            ? FolderListView(videoController: videoController)
            : VideoListView(videoController: videoController);
      }),
    );
  }
}


class FolderListView extends StatelessWidget {
  const FolderListView({super.key, required this.videoController});

  final VideoController videoController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: videoController.videoFolders.length,
      itemBuilder: (context, index) {
        String folderName = videoController.videoFolders.keys.elementAt(index);
        List<File> videosInFolder = videoController.videoFolders[folderName]!;

        return ListTile(
          leading: const Icon(Icons.folder, color: Colors.deepPurple),
          title: Text(path.basename(folderName)),
          subtitle: Text('${videosInFolder.length} videos'),
          onTap: () {
            Get.to(
                () => FolderVideoListScreen(
                      folderName: folderName,
                      videos: videosInFolder,
                    ),
                transition: Transition.fade);
          },
        );
      },
    );
  }
}

class VideoListView extends StatelessWidget {
  const VideoListView({super.key, required this.videoController});

  final VideoController videoController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: videoController.videos.length,
      itemBuilder: (context, index) {
        final video = videoController.videos[index];
        var mbSize = videoController.getFileSizeInMB(video.path);

        return ListTile(
          leading: FutureBuilder<String?>(
            future: videoController.generateThumbnail(video.path),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 64,
                    height: 64,
                    color: Colors.white,
                  ),
                );
              } else if (snapshot.hasData) {
                return Image.file(
                  File(snapshot.data!),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                );
              } else {
                return const Icon(Icons.videocam);
              }
            },
          ),
          title: Text(
            path.basename(video.path),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$mbSize MB',
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
          onTap: () {
            Get.to(() => VideoPlayerScreen(videoPath: video.path),
                transition: Transition.fade);
          },
        );
      },
    );
  }
}

class FolderVideoListScreen extends StatelessWidget {
  final String folderName;
  final List<File> videos;

  const FolderVideoListScreen({
    super.key,
    required this.folderName,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Videos in ${path.basename(folderName)}',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),

      // body: ...
    body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];

          return ListTile(
            leading: const Icon(Icons.videocam, color: Colors.deepPurple),
            title: Text(path.basename(video.path)),
            onTap: () {
              Get.to(() => VideoPlayerScreen(videoPath: video.path),
                  transition: Transition.fade);
            },
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Playing Video',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),

      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}





// ignore_for_file: library_private_types_in_public_api

// import 'dart:developer';
// import 'dart:io';
// import 'package:appinio_video_player/appinio_video_player.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_to_audio_converter/controllers/controllers.dart';
// import 'package:path/path.dart' as path;
// import 'package:video_to_audio_converter/utils/resources.dart';
// import 'package:video_to_audio_converter/utils/utils.dart';

// import 'audio_saved_screen.dart';

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoPath;

//   const VideoPlayerScreen({super.key, required this.videoPath});

//   @override
//   _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _controller;
//   final ConversionController conversionController =
//       Get.put(ConversionController());

//   String fileName = '';
//   String selectedFormat = 'MP3(Fast)';
//   String selectedBitrate = '128kb/s';

//   late CachedVideoPlayerController _videoPlayerController;
//   late CustomVideoPlayerController _customVideoPlayerController;

//   final CustomVideoPlayerSettings _customVideoPlayerSettings =
//       const CustomVideoPlayerSettings(
//           showSeekButtons: true,
//           alwaysShowThumbnailOnVideoPaused: true,
//           settingsButton: Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Icon(
//               CupertinoIcons.settings,
//               color: Colors.white,
//               size: 25,
//             ),
//           ));

//   @override
//   void initState() {
//     super.initState();
//     _videoPlayerController =
//         CachedVideoPlayerController.file(File(widget.videoPath))
//           ..initialize().then((_) {
//             setState(() {});
//             // _videoPlayerController.play();
//           });

//     fileName = path.basenameWithoutExtension(widget.videoPath);
//   }

//   @override
//   void dispose() {
//     _customVideoPlayerController.dispose();
//     _videoPlayerController.pause();
//     super.dispose();
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }

//   @override
//   Widget build(BuildContext context) {
//     _customVideoPlayerController = CustomVideoPlayerController(
//       context: context,
//       videoPlayerController: _videoPlayerController,
//       customVideoPlayerSettings: _customVideoPlayerSettings,
//       additionalVideoSources: {
//         "720p": _videoPlayerController,
//       },
//     );

//     return Scaffold(
//       appBar: AppBar(
//         iconTheme: const IconThemeData(color: Colors.white),
//         backgroundColor: primaryColor,
//         title: const Text(
//           'Video Player',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Video player preview
//               (_videoPlayerController.value.isInitialized)
//                   ? Container(
//                       height: 200,
//                       color: Colors.grey,
//                       width: double.infinity,
//                       child: Center(
//                         child: SizedBox(
//                           width: double.infinity,
//                           child: CustomVideoPlayer(
//                             customVideoPlayerController:
//                                 _customVideoPlayerController,
//                           ),
//                         ),
//                       ),
//                     )
//                   : const Center(
//                       child: CircularProgressIndicator(),
//                     ),

//               const SizedBox(height: 20),

//               // File Name input
//               const Text(
//                 "File Name",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(
//                 height: 10,
//               ),
//               TextFormField(
//                 initialValue: fileName,
//                 onChanged: (value) {
//                   setState(() {
//                     fileName = value;
//                   });
//                 },
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(
//                       borderSide: BorderSide(color: primaryColor, width: 10)),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Format and Bitrate dropdowns
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Format
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Format"),
//                       DropdownButton<String>(
//                         value: selectedFormat,
//                         items: <String>['MP3(Fast)', 'WAV', 'AAC']
//                             .map((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Text(value),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             selectedFormat = newValue!;
//                           });
//                         },
//                       ),
//                     ],
//                   ),

//                   // Bitrate
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Bitrate"),
//                       DropdownButton<String>(
//                         value: selectedBitrate,
//                         items: <String>['128kb/s', '256kb/s', '320kb/s']
//                             .map((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Text(value),
//                           );
//                         }).toList(),
//                         onChanged: (String? newValue) {
//                           setState(() {
//                             selectedBitrate = newValue!;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // Trim and Edit Tag buttons
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   ElevatedButton(
//                     style: ButtonStyle(
//                         backgroundColor:
//                             WidgetStateProperty.all<Color>(primaryColor)),
//                     onPressed: () {
//                       // Implement Trim functionality
//                       log("Trim pressed");
//                     },
//                     child: const Text(
//                       "TRIM",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                   ElevatedButton(
//                     style: ButtonStyle(
//                         backgroundColor:
//                             WidgetStateProperty.all<Color>(primaryColor)),
//                     onPressed: () {
//                       toastFlutter(
//                           toastmessage: 'This feature is comming soon.',
//                           color: Colors.greenAccent);
//                       log("Edit Tag pressed");
//                     },
//                     child: const Text(
//                       "EDIT TAG",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                   ElevatedButton(
//                     style: ButtonStyle(
//                         backgroundColor:
//                             WidgetStateProperty.all<Color>(primaryColor)),
//                     onPressed: () {
//                       // Future advanced features
//                       toastFlutter(
//                           toastmessage: 'This feature is comming soon.',
//                           color: Colors.greenAccent);
//                       log("Advanced pressed");
//                     },
//                     child: const Text(
//                       "ADVANCED",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 20),

//               // Extract Audio button
//               Center(
//                 child: Obx(
//                   () => ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: secondaryColor,
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 14, horizontal: 50),
//                     ),
//                     onPressed: () async {
//                       await conversionController
//                           .convertVideoToAudio(widget.videoPath);

//                       // Navigate to AudioSavedScreen after conversion is complete
//                       if (conversionController.conversionResult.value != null) {
//                         final audioPath = conversionController
//                             .conversionResult.value!.audioPath;
//                         Get.to(() => AudioSavedScreen(
//                               fileName: fileName,
//                               bitrate: '', // Pass the selected bitrate
//                               audioPath: audioPath,
//                             ));
//                       }
//                     },
//                     child: conversionController.isLoading.value
//                         ? const CircularProgressIndicator(
//                             color: Colors.white,
//                           )
//                         : const Text(
//                             "EXTRACT AUDIO",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
