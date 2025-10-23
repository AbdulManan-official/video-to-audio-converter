import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:get/get.dart';

import '../models/fromate_model.dart';

class FormateAudioController extends GetxController {
  var selectedFile = ''.obs;
  var selectedFormat = ''.obs;
  var isConverting = false.obs;

  final FormatModel model = FormatModel();

  String get selectedFormatValue => model.selectedFormat;
  List<String> get formats => model.formats;

  void updateSelectedFormat(String format) {
    model.setSelectedFormat(format);
    selectedFormat.value = format;
  }

  var selectedFiles = <String>[].obs;
  var fileProgress = <RxDouble>[].obs;

  void addFile(String filePath) {
    if (!selectedFiles.contains(filePath)) {
      selectedFiles.add(filePath);
      fileProgress.add(0.0.obs);
    }
  }

  void removeFile(String filePath) {
    final index = selectedFiles.indexOf(filePath);
    if (index != -1) {
      selectedFiles.removeAt(index);
      fileProgress.removeAt(index);
    }
  }

  void clearSelectedFiles() {
    selectedFiles.clear();
    fileProgress.clear();
  }

  Future<void> convertAllFiles() async {
    if (selectedFiles.isEmpty || selectedFormat.isEmpty) {
      Get.snackbar("Error", "Please select files and a format");
      return;
    }

    isConverting.value = true;

    for (int i = 0; i < selectedFiles.length; i++) {
      final filePath = selectedFiles[i];
      final progress = fileProgress[i];
      try {
        Directory musicDir = Directory('/storage/emulated/0/Music/Format Converter');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }

        final outputPath =
            "${musicDir.path}/${filePath.split('/').last.split('.').first}_converted.${selectedFormat.value.toLowerCase()}";

        progress.value = 0.0;
        for (int j = 0; j <= 100; j++) {
          await Future.delayed(const Duration(milliseconds: 50));
          progress.value = j / 100.0;
        }

        await FFmpegKit.execute('-i "$filePath" "$outputPath"');
      } catch (e) {
        Get.snackbar("Error", "An error occurred: $e");
      }
    }

    isConverting.value = false;
    Get.snackbar("Success", "All files converted successfully");
  }
}
