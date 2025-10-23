import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_to_audio_converter/controllers/merge_controller.dart';
import 'package:video_to_audio_converter/utils/utils.dart';

import '../../utils/resources.dart';
import '../audio_saved_screen.dart';

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  _MergeScreenState createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  late List<Map<String, dynamic>> files;
  final MergeAudioController mergeController = Get.put(MergeAudioController());

  late AudioPlayer _audioPlayer;
  int? _currentlyPlayingIndex; // Track currently playing file
  bool isPlaying = false; // Track play/pause state
  String fileName = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    List<File> selectedFiles = List<File>.from(Get.arguments ?? []);
    files = selectedFiles.map((file) {
      return {
        "file": file,
        "name": file.path.split('/').last,
        "duration": "Unknown",
        "size": "${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB",
        "icon": Icons.music_note,
      };
    }).toList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String filePath, int index) async {
    if (_currentlyPlayingIndex == index && isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        isPlaying = false;
        _currentlyPlayingIndex = null;
      });
    } else {
      try {
        await _audioPlayer.setFilePath(filePath);
        await _audioPlayer.play();
        setState(() {
          isPlaying = true;
          _currentlyPlayingIndex = index;
        });
        _audioPlayer.playerStateStream.listen((state) {
          if (!state.playing &&
              state.processingState == ProcessingState.completed) {
            setState(() {
              isPlaying = false;
              _currentlyPlayingIndex = null;
            });
          }
        });
      } catch (e) {
        print("Error playing audio: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        title: Text(
          "${files.length} files to be merged",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(
            () => ElevatedButton(
          style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(
              const Size(double.infinity, 50),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            backgroundColor: MaterialStateProperty.all(
              files.length < 2 ? Colors.grey : Colors.black,
            ),
          ),
          onPressed: files.length < 2 || mergeController.isMerging.value
              ? null
              : () async {
            final connectivity = await Connectivity().checkConnectivity();
            if (connectivity == ConnectivityResult.none) {
              _showNoInternetDialog();
            } else {
              _showRenameDialog(context);
            }
          },
          child: mergeController.isMerging.value
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            "Merge",
            style: TextStyle(color: Colors.white),
          ),
        ).paddingSymmetric(horizontal: 10),
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = files.removeAt(oldIndex);
            files.insert(newIndex, item);
          });
        },
        children: List.generate(files.length, (index) {
          final file = files[index];
          return Padding(
            key: ValueKey(file['file']),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            child: Card(
              child: Obx(() {
                final isPlaying =
                    mergeController.currentlyPlayingIndex.value == index &&
                        mergeController.isPlaying.value;
                return ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: InkWell(
                    onTap: () => _toggleAudio(file['file'].path, index),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.blue,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.music_note,
                                color: Colors.white),
                          ),
                        ),
                        if (isPlaying)
                          Container(
                            width: 50,
                            height: 50,
                            color: Colors.black.withOpacity(0.5),
                            child:
                            const Icon(Icons.pause, color: Colors.white),
                          )
                        else
                          const Icon(Icons.play_arrow,
                              size: 30, color: Colors.white),
                      ],
                    ),
                  ),
                  title: Text(
                    file['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "${file['duration']} | ${file['size']}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      files.removeAt(index);
                      setState(() {});
                    },
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  void _showNoInternetDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text(
            'It seems you are not connected to the internet. Please check your network settings.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showRenameDialog(BuildContext context) {
    String defaultName =
    files.map((e) => e['name'].split('.').first).join('_');
    fileName = defaultName;

    final TextEditingController textController =
    TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Merge Files"),
          content: TextField(
            autofocus: true,
            controller: textController,
            decoration: const InputDecoration(
              labelText: "File Name",
              hintText: "Enter new file name",
            ),
            onChanged: (value) {
              fileName =
                  value.trim().replaceAll(RegExp(r'[^\w\d_-]'), '');
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Cancel")),
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black)),
              onPressed: () async {
                fileName = fileName.endsWith('.mp3') ? fileName : '$fileName.mp3';
                Navigator.of(ctx).pop();

                try {
                  mergeController.isMerging.value = true;

                  // Merge locally
                  final mergedPath = await mergeController.mergeAudioFiles(
                    files.map((e) => (e['file'] as File).path).toList(),
                    fileName,
                  );

                  if (mergedPath.isNotEmpty) {
                    // Move the merged file to Music/MergedAudio
                    final Directory musicDir = Directory('/storage/emulated/0/Music/MergedAudio');
                    if (!await musicDir.exists()) {
                      await musicDir.create(recursive: true);
                    }
                    final String newPath = '${musicDir.path}/$fileName';
                    final File newFile = await File(mergedPath).copy(newPath);

                    mergeController.isMerging.value = false;

                    toastFlutter(
                        toastmessage: 'Audio merged and saved to Music folder!',
                        color: Colors.green);

                    Get.to(() => AudioSavedScreen(
                      fileName: fileName,
                      audioPath: newFile.path,
                      bitrate: '',
                    ));
                  } else {
                    mergeController.isMerging.value = false;
                    toastFlutter(
                        toastmessage: 'Merging failed, try again.',
                        color: Colors.red);
                  }
                } catch (e) {
                  mergeController.isMerging.value = false;
                  toastFlutter(
                      toastmessage: 'An error occurred: $e', color: Colors.red);
                }
              },
              child: const Text(
                "Merge",
                style: TextStyle(color: Colors.white),
              ),
            ),

          ],
        );
      },
    );
  }
}
