// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class NetworkController extends GetxController {
//   final RxBool isConnected = true.obs;

//   // void listenToNetworkChanges() {
//   //   _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
//   //     if (result == ConnectivityResult.none) {
//   //       isConnected.value = false;
//   //       _showNoInternetDialog();
//   //     } else {
//   //       isConnected.value = true;
//   //     }
//   //   });
//   // }

//   void checkConnectivity() async {
//     final List<ConnectivityResult> connectivityResult =
//         await (Connectivity().checkConnectivity());

//     if (connectivityResult.contains(ConnectivityResult.none)) {
//       isConnected.value = false;
//       _showNoInternetDialog();
//     } else {
//       isConnected.value = true;
//     }
//   }
// }

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ringtone_set_mul/ringtone_set_mul.dart';
import 'package:video_to_audio_converter/utils/resources.dart';

class RingtoneSetter {
  static const MethodChannel _platform =
      MethodChannel('com.example.video_to_audio');

  /// Sets the ringtone from the given file path
  static Future<void> setRingtone(String filePath) async {
    try {
      // Check if WRITE_SETTINGS permission is granted
      bool isGranted = await RingtoneSet.isWriteSettingsGranted();
      if (!isGranted) {
        // Request the necessary permission
        bool permissionGranted = await RingtoneSet.reqSystemPermissions();
        if (!permissionGranted) {
          log("Permission not granted. Cannot set ringtone.");
          toastFlutter(
              toastmessage: "Permission not granted. Cannot set ringtone.",
              color: Colors.red);
          return;
        }
      }

      // Invoke the native method to set the ringtone
      final String result =
          await _platform.invokeMethod('setRingtone', {'filePath': filePath});
      log("Ringtone set successfully: $result");
    } catch (e) {
      log("Failed to set ringtone: $e");
    }
  }
}

class CrunkerAudioMerger {
  static const MethodChannel _channel = MethodChannel('com.example.crunker');

  /// Call the platform channel to merge audio files
  static Future<String> mergeAudioFiles(List<String> filePaths) async {
    try {
      final result = await _channel.invokeMethod('mergeAudioFiles', {
        'filePaths': filePaths,
      });
      return result; // Return the merged file path
    } catch (e) {
      throw Exception('Error merging audio files: $e');
    }
  }
}
