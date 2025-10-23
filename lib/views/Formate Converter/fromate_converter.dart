import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:video_to_audio_converter/utils/utils.dart';
import '../../controllers/merge_controller.dart';
import '../../controllers/video_controller.dart';
import 'formate_second_page.dart';

class FormateMain extends StatefulWidget {
  const FormateMain({super.key});

  @override
  State<FormateMain> createState() => _FormateMainState();
}

class _FormateMainState extends State<FormateMain> {
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
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        title: const Text(
          "Recent Added",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_box),
            tooltip: "Select All",
            onPressed: controller.selectAll,
          ),
          IconButton(
            icon: const Icon(Icons.indeterminate_check_box),
            tooltip: "Remove All",
            onPressed: controller.removeAll,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.mp3FilesOfMusic.isEmpty) {
          return const Center(child: Text("No audio files found"));
        }

        // Ensure selectedItems has the same length as mp3FilesOfMusic
        if (controller.selectedItems.length != controller.mp3FilesOfMusic.length) {
          controller.selectedItems.value = List<bool>.filled(controller.mp3FilesOfMusic.length, false);
        }

        return ListView.builder(
          itemCount: controller.mp3FilesOfMusic.length,
          itemBuilder: (context, index) {
            File mp3File = controller.mp3FilesOfMusic[index];
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
              subtitle: Text("$fileSize MB"),
              trailing: Obx(() => Checkbox(
                value: controller.selectedItems[index],
                onChanged: (value) {
                  controller.selectedItems[index] = value ?? false;
                  // controller.update();
                },
              )),
            );
          },
        );
      }),
      floatingActionButton: Obx(() {
        int selectedCount = controller.selectedItems.where((item) => item).length;

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
                        selectedCount > 0 ? primaryColor : Colors.grey)),
                onPressed: selectedCount > 0
                    ? () {
                  // Navigate to MergeScreen with selected files
                  Get.to(
                        () => const FormateSecondPage(),
                    arguments: controller.mp3FilesOfMusic
                        .asMap()
                        .entries
                        .where((entry) =>
                    controller.selectedItems[entry.key])
                        .map((entry) => entry.value)
                        .toList(),
                  );
                }
                    : null,
                child: Text(
                  'Next',
                  style: TextStyle(
                      color: selectedCount > 0 ? Colors.white : Colors.black),
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