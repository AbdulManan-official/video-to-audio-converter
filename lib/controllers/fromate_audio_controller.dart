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

  // NEW: Flag to determine duplicate handling strategy
  var shouldReplaceExisting = true.obs;

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

  // NEW: Helper method to check if any output files already exist
  Future<List<String>> checkForDuplicates() async {
    List<String> duplicateFiles = [];

    Directory musicDir = Directory('/storage/emulated/0/Music/Format Converter');

    for (String filePath in selectedFiles) {
      String outputPath =
          "${musicDir.path}/${filePath.split('/').last.split('.').first}_converted.${selectedFormat.value.toLowerCase()}";

      if (await File(outputPath).exists()) {
        duplicateFiles.add(outputPath.split('/').last);
      }
    }

    return duplicateFiles;
  }

  // NEW: Generate unique filename if file exists
  String _getUniqueOutputPath(String outputPath) {
    if (shouldReplaceExisting.value) {
      // Replace mode: return original path (will overwrite)
      return outputPath;
    }

    // Keep & Rename mode: generate unique filename
    File file = File(outputPath);
    if (!file.existsSync()) {
      return outputPath;
    }

    // Extract components
    String directory = file.parent.path;
    String fullFileName = file.path.split('/').last;
    String extension = fullFileName.split('.').last;
    String baseNameWithSuffix = fullFileName.substring(0, fullFileName.length - extension.length - 1);

    // Remove existing "_converted" suffix if present
    String baseName = baseNameWithSuffix;
    if (baseName.endsWith('_converted')) {
      baseName = baseName.substring(0, baseName.length - 10); // Remove "_converted"
    }

    // Find unique filename
    int counter = 1;
    String newPath;
    do {
      newPath = '$directory/${baseName}_converted ($counter).$extension';
      counter++;
    } while (File(newPath).existsSync());

    return newPath;
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

        // Initial output path
        String outputPath =
            "${musicDir.path}/${filePath.split('/').last.split('.').first}_converted.${selectedFormat.value.toLowerCase()}";

        // NEW: Get unique path based on duplicate handling strategy
        outputPath = _getUniqueOutputPath(outputPath);

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

  // Reset controller
  void reset() {
    selectedFiles.clear();
    fileProgress.clear();
    selectedFormat.value = '';
    isConverting.value = false;
    shouldReplaceExisting.value = true;
  }
}