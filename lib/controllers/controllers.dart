import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:video_to_audio_converter/utils/resources.dart';
import 'package:video_to_audio_converter/utils/utils.dart';

class ConversionController extends GetxController {
  static const platform = MethodChannel('com.example.video_to_audio');

  Rx<ConversionModel?> conversionResult = Rx<ConversionModel?>(null);
  RxBool isLoading = false.obs;
  String fileName = ""; // Add a default file name

  // Request storage permissions
  // Future<bool> requestPermissions() async {
  //   try {
  //     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     int sdkInt = androidInfo.version.sdkInt;

  //     if (sdkInt >= 30) {
  //       // SAF requires folder picker; permissions aren't enough
  //       log('Requesting folder access for Android 13+');
  //       var permissions = await [Permission.manageExternalStorage].request();
  //       return permissions[Permission.manageExternalStorage]!.isGranted;
  //     } else {
  //       // For SDK below 30, request storage permission
  //       var permissions = await [Permission.storage].request();
  //       return permissions[Permission.storage]!.isGranted;
  //     }
  //   } catch (e) {
  //     log('Error requesting permissions: $e');
  //     return false;
  //   }
  // }

  // Method to convert video to audio using platform channels
  Future<void> convertVideoToAudio(String videoPath, String fileName) async {
    try {
      isLoading(true);

      // Check if the video file exists
      File videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        throw Exception("Video file does not exist at: $videoPath");
      }

      // Call the native Android code to convert video to audio
      final audioPath = await platform.invokeMethod<String>(
        'convertVideoToAudio',
        {
          "videoPath": videoPath,
          "fileName": fileName, // Pass the file name to the native code
        },
      );

      if (audioPath != null) {
        // Save the conversion result
        conversionResult(
            ConversionModel(videoPath: videoPath, audioPath: audioPath));
        isLoading(false);
        toastFlutter(
            toastmessage: 'Audio Converted successfully',
            color: Colors.green[800] ?? Colors.green);

        log('Audio saved to: $audioPath');
      } else {
        throw Exception("Audio conversion failed");
      }
    } catch (e) {
      if (e.toString().contains('Failed to convert video to audio')) {
        toastFlutter(
            toastmessage: 'Video does not contain sound.../ Rename The file...',
            color: secondaryColor);
      }
      log("Error: $e");
    } finally {
      isLoading(false);
    }
  }

  // Method to play the audio using a third-party player (you can implement it as needed)
  Future<void> playAudio() async {
    if (conversionResult.value != null) {
      // Your audio player implementation here
      log("Playing audio from: ${conversionResult.value?.audioPath}");
      // Example:
      // await player.setFilePath(conversionResult.value!.audioPath);
      // await player.play();
    }
  }

  // Method to stop the audio
  Future<void> stopAudio() async {
    // Stop the player (if implemented)
    log("Audio stopped.");
    // Example:
    // await player.stop();
  }
}

class ConversionModel {
  final String videoPath;
  final String audioPath;

  ConversionModel({required this.videoPath, required this.audioPath});
}
