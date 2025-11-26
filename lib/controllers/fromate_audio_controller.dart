import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

import '../models/fromate_model.dart';

class FormateAudioController extends GetxController {
  var selectedFile = ''.obs;
  var selectedFormat = ''.obs;
  var isConverting = false.obs;
  var isCancelled = false.obs;

  void cancelConversion() {
    isCancelled.value = true;
    isConverting.value = false;
  }

  final FormatModel model = FormatModel();

  String get selectedFormatValue => model.selectedFormat;
  List<String> get formats => model.formats;

  void updateSelectedFormat(String format) {
    model.setSelectedFormat(format);
    selectedFormat.value = format;
  }

  var selectedFiles = <String>[].obs;
  var fileProgress = <RxDouble>[].obs;
  var outputFileNames = <String>[].obs;

  var shouldReplaceExisting = true.obs;

  void addFile(String filePath) {
    if (!selectedFiles.contains(filePath)) {
      selectedFiles.add(filePath);
      fileProgress.add(0.0.obs);
      outputFileNames.add('');
    }
  }

  void removeFile(String filePath) {
    final index = selectedFiles.indexOf(filePath);
    if (index != -1) {
      selectedFiles.removeAt(index);
      fileProgress.removeAt(index);
      outputFileNames.removeAt(index);
    }
  }

  void clearSelectedFiles() {
    selectedFiles.clear();
    fileProgress.clear();
    outputFileNames.clear();
  }

  Future<List<String>> checkForDuplicates() async {
    List<String> duplicateFiles = [];
    Directory musicDir = Directory('/storage/emulated/0/Music/Format Converter');

    for (String filePath in selectedFiles) {
      String outputPath =
          "${musicDir.path}/${filePath.split('/').last.split('.').first}.${selectedFormat.value.toLowerCase()}";

      if (await File(outputPath).exists()) {
        duplicateFiles.add(outputPath.split('/').last);
      }
    }

    return duplicateFiles;
  }

  String _getUniqueOutputPath(String outputPath) {
    if (shouldReplaceExisting.value) {
      return outputPath;
    }

    File file = File(outputPath);
    if (!file.existsSync()) {
      return outputPath;
    }

    String directory = file.parent.path;
    String fullFileName = file.path.split('/').last;
    String extension = fullFileName.split('.').last;
    String baseNameWithoutExt = fullFileName.substring(0, fullFileName.length - extension.length - 1);

    int counter = 1;
    String newPath;
    do {
      newPath = '$directory/$baseNameWithoutExt ($counter).$extension';
      counter++;
    } while (File(newPath).existsSync());

    return newPath;
  }

  Future<void> convertAllFiles() async {
    if (selectedFiles.isEmpty || selectedFormat.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select files and a format",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.redAccent,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    isConverting.value = true;
    isCancelled.value = false;

    for (int i = 0; i < selectedFiles.length; i++) {
      if (isCancelled.value) {
        isConverting.value = false;
        final stats = getConversionStats();
        Fluttertoast.showToast(
          msg:
          "Conversion failed: ${stats['completed']} files converted, ${stats['pending']} files not converted",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      final filePath = selectedFiles[i];
      final progress = fileProgress[i];
      try {
        Directory musicDir = Directory('/storage/emulated/0/Music/Format Converter');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }

        String outputPath =
            "${musicDir.path}/${filePath.split('/').last.split('.').first}.${selectedFormat.value.toLowerCase()}";
        outputPath = _getUniqueOutputPath(outputPath);

        // ✅ NEW: Store the actual output file name (with (1) if renamed)
        outputFileNames[i] = outputPath.split('/').last;

        progress.value = 0.0;

        for (int j = 0; j <= 100; j++) {
          if (isCancelled.value) {
            isConverting.value = false;
            final stats = getConversionStats();
            Fluttertoast.showToast(
              msg:
              "Conversion failed: ${stats['completed']} files converted, ${stats['pending']} files not converted",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            return;
          }
          await Future.delayed(const Duration(milliseconds: 50));
          progress.value = j / 100.0;
        }

        await FFmpegKit.execute('-i "$filePath" "$outputPath"');
      } catch (e) {
        Fluttertoast.showToast(
          msg: "An error occurred: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }

    isConverting.value = false;
    if (!isCancelled.value) {
      Fluttertoast.showToast(
        msg: "All files converted successfully",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Map<String, int> getConversionStats() {
    int completed = fileProgress.where((p) => p.value >= 1.0).length;
    int pending = selectedFiles.length - completed;
    return {
      'completed': completed,
      'pending': pending,
    };
  }

  void reset() {
    selectedFiles.clear();
    fileProgress.clear();
    outputFileNames.clear();
    selectedFormat.value = '';
    isConverting.value = false;
    shouldReplaceExisting.value = true;
    isCancelled.value = false;

  }
}
