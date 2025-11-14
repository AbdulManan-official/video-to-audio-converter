// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:path/path.dart' as path;
// import 'package:shimmer/shimmer.dart';
// import 'package:video_to_audio_converter/utils/utils.dart';
// import '../controllers/video_controller.dart';
// import 'video_palyer_screen.dart';
//
// class VideoListScreen extends StatelessWidget {
//   final List<File> videosInFolder;
//   final String folderName;
//
//   const VideoListScreen({
//     super.key,
//     required this.videosInFolder,
//     required this.folderName,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final VideoController videoController = Get.put(VideoController());
//
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () {
//             Get.back();
//           },
//           icon: const Icon(
//             Icons.arrow_back,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         title: Text(
//           "Videos in ${path.basename(folderName)}",
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body: ListView.separated(
//         padding: EdgeInsets.zero,
//         itemCount: videosInFolder.length,
//         separatorBuilder: (context, index) => Container(
//           height: 1,
//           color: Colors.grey[300],
//         ),
//         itemBuilder: (context, index) {
//           File videoFile = videosInFolder[index];
//           var mbSize = videoController.getFileSizeInMB(videoFile.path);
//
//           return InkWell(
//             onTap: () {
//               Get.to(
//                     () => VideoPlayerScreen(videoPath: videoFile.path),
//                 transition: Transition.fade,
//               );
//             },
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               child: Row(
//                 children: [
//                   // Thumbnail with shimmer loading
//                   FutureBuilder<String?>(
//                     future: videoController.generateThumbnail(videoFile.path),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return Shimmer.fromColors(
//                           baseColor: Colors.grey.shade300,
//                           highlightColor: Colors.grey.shade100,
//                           child: Container(
//                             width: 100,
//                             height: 75,
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         );
//                       } else if (snapshot.hasData) {
//                         return ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.file(
//                             File(snapshot.data!),
//                             height: 75,
//                             width: 100,
//                             fit: BoxFit.cover,
//                           ),
//                         );
//                       } else {
//                         return Container(
//                           width: 100,
//                           height: 75,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: const Icon(
//                             Icons.videocam,
//                             size: 40,
//                             color: Colors.grey,
//                           ),
//                         );
//                       }
//                     },
//                   ),
//                   const SizedBox(width: 12),
//                   // Video details
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           path.basename(videoFile.path),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             color: Colors.black87,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.storage,
//                               size: 14,
//                               color: Colors.grey[600],
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               '$mbSize MB',
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: Colors.grey[600],
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             Icon(
//                               Icons.video_library,
//                               size: 14,
//                               color: Colors.grey[600],
//                             ),
//                             const SizedBox(width: 4),
//                             Expanded(
//                               child: Text(
//                                 path.dirname(videoFile.path).split('/').last,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[500],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   // Play icon - centered vertically
//                   Center(
//
//                     child: Icon(
//                       Icons.chevron_right_sharp,
//                       color: Colors.grey,
//                       size: 26,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class VideoDetailsScreen extends StatefulWidget {
//   final File videoFile;
//
//   const VideoDetailsScreen({super.key, required this.videoFile});
//
//   @override
//   State<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
// }
//
// class _VideoDetailsScreenState extends State<VideoDetailsScreen> {
//   String fileName = '';
//   String selectedFormat = 'MP3(Fast)';
//   String selectedBitrate = '128kb/s';
//
//   @override
//   void initState() {
//     super.initState();
//     fileName = path.basenameWithoutExtension(widget.videoFile.path);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Extract Audio"),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 200,
//               color: Colors.black,
//               child: const Center(
//                 child: Icon(Icons.play_arrow, color: Colors.white),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             const Text("File Name"),
//             TextFormField(
//               initialValue: fileName,
//               onChanged: (value) {
//                 setState(() {
//                   fileName = value;
//                 });
//               },
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Format"),
//                     DropdownButton<String>(
//                       value: selectedFormat,
//                       items: <String>['MP3(Fast)', 'WAV', 'AAC']
//                           .map((String value) => DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       ))
//                           .toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedFormat = newValue!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text("Bitrate"),
//                     DropdownButton<String>(
//                       value: selectedBitrate,
//                       items: <String>['128kb/s', '256kb/s', '320kb/s']
//                           .map((String value) => DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value),
//                       ))
//                           .toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedBitrate = newValue!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => print("Trim pressed"),
//                   child: const Text("TRIM"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => print("Edit Tag pressed"),
//                   child: const Text("EDIT TAG"),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             Center(
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   padding:
//                   const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
//                 ),
//                 onPressed: () {
//                   print("Extracting audio from ${widget.videoFile.path}");
//                 },
//                 child: const Text("EXTRACT AUDIO"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }