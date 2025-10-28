

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_to_audio_converter/utils/utils.dart';

import '../../controllers/merge_controller.dart';
import '../../controllers/video_controller.dart';
import 'merge_second_screen.dart';

class MergeAudioScreen extends StatefulWidget {
  const MergeAudioScreen({super.key});

  @override
  State<MergeAudioScreen> createState() => _MergeAudioScreenState();
}

class _MergeAudioScreenState extends State<MergeAudioScreen> {
  final MergeAudioController controller = Get.put(MergeAudioController());
  final VideoController videoController = Get.put(VideoController());

  @override
  void initState() {
    controller.fetchMp3FilesofMusic();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recent Added",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter MP3 files once
        List<File> mp3Files = controller.mp3FilesOfMusic;

        if (mp3Files.isEmpty) {
          return const Center(
            child: Text('No MP3 files found.'),
          );
        }

        return ListView.builder(
          itemCount: mp3Files.length, // Use the filtered list's length
          itemBuilder: (context, index) {
            File mp3File = mp3Files[index];
            String fileName = mp3File.path.split('/').last;
            double fileSize = videoController.getFileSizeInMB(mp3File.path);

            return ListTile(
              leading: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.blue],
                  ),
                ),
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
              title: Text(fileName, maxLines: 1),
              subtitle: Text("${fileSize.toStringAsFixed(2)} MB"),
              trailing: Obx(() => Checkbox(
                value: controller.selectedItemsOfMusic[index],
                onChanged: (value) {
                  controller.selectedItemsOfMusic[index] = value ?? false;
                  controller.update();
                },
              )),
            );
          },
        );
      }),
      floatingActionButton: Obx(() {
        int selectedCount = controller.selectedCountOFMusic;

        return Container(
          padding: const EdgeInsets.only(left: 30.0, right: 10.0),
          width: double.infinity,
          height: 70,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selected files: $selectedCount'),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    selectedCount >= 2 && selectedCount < 3
                        ? primaryColor
                        : Colors.grey,
                  ),
                ),
                onPressed: selectedCount >= 2 && selectedCount < 3
                    ? () {
                  var mp3Files = controller.mp3FilesOfMusic;
                  var selectedFiles = mp3Files
                      .asMap()
                      .entries
                      .where((entry) => controller.selectedItemsOfMusic[entry.key])
                      .map((entry) => entry.value)
                      .toList();

                  // Debug logs
                  print("Selected files for merging:");
                  selectedFiles.forEach((file) => print(file.path));

                  // Navigate to MergeScreen
                  Get.to(() => const MergeScreen(), arguments: selectedFiles);
                }
                    : null,

                child: Text(
                  'Next',
                  style: TextStyle(
                    color: selectedCount >= 2 && selectedCount < 3
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}