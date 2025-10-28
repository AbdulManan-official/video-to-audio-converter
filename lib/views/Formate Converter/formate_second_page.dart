import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_to_audio_converter/controllers/merge_controller.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import 'package:video_to_audio_converter/views/Formate%20Converter/progess_page.dart';

import '../../controllers/fromate_audio_controller.dart';

class FormateSecondPage extends StatefulWidget {
  const FormateSecondPage({super.key});

  @override
  _FormateSecondPageState createState() => _FormateSecondPageState();
}

class _FormateSecondPageState extends State<FormateSecondPage> {
  late List<Map<String, dynamic>> files;
  final MergeAudioController mergeController = Get.put(MergeAudioController());
  final FormateAudioController formateController =
      Get.put(FormateAudioController());

  late AudioPlayer _audioPlayer;
  int? _currentlyPlayingIndex; // To track which audio file is being played
  bool isPlaying = false; // To track play/pause state

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Play or Pause audio
  Future<void> _toggleAudio(String filePath, int index) async {
    if (_currentlyPlayingIndex == index && isPlaying) {
      // If the same audio is clicked and already playing, stop it
      await _audioPlayer.stop();
      setState(() {
        isPlaying = false;
        _currentlyPlayingIndex = null;
      });
    } else {
      // Play new audio
      try {
        await _audioPlayer.setFilePath(filePath);
        await _audioPlayer.play();
        setState(() {
          isPlaying = true;
          _currentlyPlayingIndex = index;
        });
        _audioPlayer.playerStateStream.listen((state) {
          if (state.playing == false &&
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
  void initState() {
    super.initState();
    // Retrieve the selected files from Get.arguments

    _audioPlayer = AudioPlayer();
    List<File> selectedFiles = List<File>.from(Get.arguments ?? []);

    // Map files to a list of maps with metadata
    files = selectedFiles.map((file) {
      formateController.addFile(file.path);
      return {
        "file": file,
        "name": file.path.split('/').last, // Extract file name
        "duration": "Unknown", // Placeholder for duration
        "size":
            "${(file.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB", // File size in MB
        "icon": Icons.music_note, // Placeholder icon
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          "${files.length} files to be formatted",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              // onReorder: (int oldIndex, int newIndex) {
              //   setState(() {
              //     if (newIndex > oldIndex) newIndex -= 1;
              //     final item = files.removeAt(oldIndex);
              //     files.insert(newIndex, item);
              //   });
              // },
              children: List.generate(files.length, (index) {
                final file = files[index];
                return Padding(
                  key: ValueKey(file['file']),
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 12.0),
                  child: Card(
                    color: Colors.white,
                    child: Obx(() {
                      final isPlaying =
                          mergeController.currentlyPlayingIndex.value ==
                                  index &&
                              mergeController.isPlaying.value;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        leading: InkWell(
                          onTap: () {
                            mergeController.toggleAudio(
                                file['file'].path, index);
                          },
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
                                  child: const Icon(Icons.pause,
                                      color: Colors.white),
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
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            files.removeAt(index);
                            setState(() {}); // Update the UI after deletion
                          },
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              height: 230,
              width: double.infinity,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Format',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Obx(
                    () => Wrap(
                      spacing: 10.0,
                      children: formateController.formats.map((format) {
                        final isSelected =
                            formateController.selectedFormat.value == format;
                        return ChoiceChip(
                          checkmarkColor: Colors.white,
                          selectedColor: primaryColor,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.black, // Dynamic color
                          ),
                          label: Text(format),
                          selected:
                              formateController.selectedFormat.value == format,
                          onSelected: (isSelected) {
                            if (isSelected) {
                              formateController.updateSelectedFormat(format);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all<OutlinedBorder>(
                            const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(08)))),
                        backgroundColor:
                            WidgetStateProperty.all<Color>(primaryColor),
                        minimumSize: WidgetStateProperty.all<Size>(
                            const Size(double.infinity, 50))),
                    onPressed: () {
                      if (formateController.selectedFiles.isEmpty ||
                          formateController.selectedFormat.isEmpty) {
                        Get.snackbar(
                            "Error", "Please select files and a format");
                        return;
                      }
                      Get.to(() => const ConversionProgressPage());
                      formateController.convertAllFiles();
                    },
                    child: const Text(
                      'DONE',
                      style: TextStyle(color: Colors.white),
                    ),
                  ).paddingSymmetric(horizontal: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
