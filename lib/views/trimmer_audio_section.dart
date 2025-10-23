// import 'dart:io';

// import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
// import 'package:flutter/material.dart';

// class AudioTrimmerView extends StatefulWidget {
//   final File file;

//   const AudioTrimmerView(this.file, {Key? key}) : super(key: key);
//   @override
//   State<AudioTrimmerView> createState() => _AudioTrimmerViewState();
// }

// class _AudioTrimmerViewState extends State<AudioTrimmerView> {
//   final Trimmer _trimmer = Trimmer();

//   double _startValue = 0.0;
//   double _endValue = 0.0;

//   bool _isPlaying = false;
//   bool _progressVisibility = false;
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadAudio();
//   }

//   void _loadAudio() async {
//     setState(() {
//       isLoading = true;
//     });
//     await _trimmer.loadAudio(audioFile: widget.file);
//     setState(() {
//       isLoading = false;
//     });
//   }

//   _saveAudio() {
//     setState(() {
//       _progressVisibility = true;
//     });

//     _trimmer.saveTrimmedAudio(
//       startValue: _startValue,
//       endValue: _endValue,
//       audioFileName: DateTime.now().millisecondsSinceEpoch.toString(),
//       onSave: (outputPath) {
//         setState(() {
//           _progressVisibility = false;
//         });
//         debugPrint('OUTPUT PATH: $outputPath');
//       },
//     );
//   }

//   @override
//   void dispose() {
//     if (mounted) {
//       _trimmer.dispose();
//     }

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (Navigator.of(context).userGestureInProgress) {
//           return false;
//         } else {
//           return true;
//         }
//       },
//       child: Scaffold(
//         backgroundColor: Colors.grey[200],
//         appBar: AppBar(
//           title: const Text("Audio Trimmer"),
//           backgroundColor: Colors.teal,
//           centerTitle: true,
//           elevation: 0,
//         ),
//         body: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 20.0, vertical: 20.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     mainAxisSize: MainAxisSize.max,
//                     children: <Widget>[
//                       Visibility(
//                         visible: _progressVisibility,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8.0),
//                           child: LinearProgressIndicator(
//                             backgroundColor: Colors.teal.withOpacity(0.5),
//                             color: Colors.teal,
//                           ),
//                         ),
//                       ),
//                       Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: TrimViewer(
//                             trimmer: _trimmer,
//                             viewerHeight: 100,
//                             maxAudioLength: const Duration(seconds: 50),
//                             viewerWidth: MediaQuery.of(context).size.width,
//                             durationStyle: DurationStyle.FORMAT_MM_SS,
//                             backgroundColor: Colors.teal,
//                             barColor: Colors.white,
//                             durationTextStyle: TextStyle(color: Colors.white),
//                             allowAudioSelection: true,
//                             editorProperties: TrimEditorProperties(
//                               circleSize: 12,
//                               borderPaintColor: Colors.deepOrange,
//                               borderWidth: 4,
//                               borderRadius: 8,
//                               circlePaintColor: Colors.orangeAccent,
//                             ),
//                             areaProperties:
//                                 TrimAreaProperties.edgeBlur(blurEdges: true),
//                             onChangeStart: (value) => _startValue = value,
//                             onChangeEnd: (value) => _endValue = value,
//                             onChangePlaybackState: (value) {
//                               if (mounted) {
//                                 setState(() => _isPlaying = value);
//                               }
//                             },
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 20.0),
//                       TextButton(
//                         onPressed: () async {
//                           bool playbackState =
//                               await _trimmer.audioPlaybackControl(
//                             startValue: _startValue,
//                             endValue: _endValue,
//                           );
//                           setState(() => _isPlaying = playbackState);
//                         },
//                         style: TextButton.styleFrom(
//                           shape: CircleBorder(),
//                           padding: EdgeInsets.all(20),
//                           backgroundColor: Colors.teal,
//                         ),
//                         child: Icon(
//                           _isPlaying ? Icons.pause : Icons.play_arrow,
//                           size: 60.0,
//                           color: Colors.white,
//                         ),
//                       ),
//                       SizedBox(height: 20.0),
//                       ElevatedButton(
//                         onPressed:
//                             _progressVisibility ? null : () => _saveAudio(),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 40, vertical: 15),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                         child: const Text(
//                           "SAVE",
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }
// }
