import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_to_audio_converter/main.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import '../../controllers/fromate_audio_controller.dart';
import '../../controllers/merge_controller.dart';

class ConversionProgressPage extends StatefulWidget {
  const ConversionProgressPage({super.key});

  @override
  State<ConversionProgressPage> createState() => _ConversionProgressPageState();
}

class _ConversionProgressPageState extends State<ConversionProgressPage> {
  final FormateAudioController formateController =
      Get.find<FormateAudioController>();

  final MergeAudioController mergeController = Get.put(MergeAudioController());

  // In your FormateAudioController:
  String getFormattedFileName(String filePath) {
    final fileName =
        filePath.split('/').last; // Extract file name with extension
    final extension = formateController.selectedFormat.value.toLowerCase();

    // Return file name with the selected extension
    return '${fileName.split('.').first}_converted.$extension';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Conversion Progress',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),

      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: formateController.selectedFiles.length,
                itemBuilder: (context, index) {
                  final fileName = getFormattedFileName(
                      formateController.selectedFiles[index]);
                  final progress = formateController.fileProgress[index];
                  final isPlaying =
                      mergeController.currentlyPlayingIndex.value == index &&
                          mergeController.isPlaying.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 12.0),
                    child: Row(
                      children: [
                        _buildAudioThumbnail(
                          isPlaying: isPlaying,
                          onTap: () {
                            mergeController.toggleAudio(
                                formateController.selectedFiles[index], index);
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildFileDetails(fileName, progress),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (!formateController.isConverting.value) _buildDoneButton(),
          ],
        );
      }),
    );
  }

  Widget _buildAudioThumbnail({
    required bool isPlaying,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
          if (isPlaying)
            Container(
              width: 50,
              height: 50,
              color: Colors.black.withOpacity(0.5),
              child: const Icon(Icons.pause, color: Colors.white),
            )
          else
            const Icon(Icons.play_arrow, size: 30, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildFileDetails(String fileName, RxDouble progress) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Wrap the Column inside an Expanded widget to ensure space for the text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // File name with ellipsis to handle long text
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                // Show progress indicator only if the progress is less than 100%
                if (progress.value < 1.0)
                  Obx(() {
                    return LinearProgressIndicator(
                      value: progress.value,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue,
                    );
                  }),
                const SizedBox(height: 5),
                // Show percentage only if the progress is less than 100%
                if (progress.value < 1.0)
                  Obx(() {
                    return Text(
                      '${(progress.value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14),
                    );
                  }),
                // // Show checkmark once the conversion is complete
                // if (progress.value == 1.0)
                //   const Icon(
                //     Icons.done,
                //     color: Colors.green,
                //   ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),
          // Add the done icon at the end, in case the file is complete
          if (progress.value == 1.0)
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.green[800]),
              child: const Icon(
                Icons.done,
                color: Colors.white,
                size: 12,
              ).paddingAll(5),
            ).paddingOnly(bottom: 5.0),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Successful',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Get.offAll(() => const OutputScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              // onPrimary: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.folder, color: Colors.blue),
            label: const Text('Go To Folder',
                style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
