import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

const primaryColor = Color(0xFF1474a4); //blue
const secondaryColor = Color(0xFFe01f2c); //red
const cardBackground = Color(0xFFF5F5F5);

void navigateWithAnimation(BuildContext context, Widget page) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Define the animation - Here, a slide from the right
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    ),
  );
}

Future<String?> startDownload(
    String url, String saveDir, String fileName) async {
  final taskId = await FlutterDownloader.enqueue(
    url: url,
    savedDir: saveDir,
    fileName: fileName,
    showNotification: true, // Show download notification
    openFileFromNotification: true, // Open file when download completes
  );

  log('Download started with task ID: $taskId');
  return taskId;
}

Future<void> downloadMp3File(String fileUrl, String fileName) async {
  try {
    // Specify the directory to store the file
    Directory musicDir = Directory('/storage/emulated/0/Music/MergedAudio');

    // Create the directory if it doesn't exist
    if (!await musicDir.exists()) {
      await musicDir.create(recursive: true);
    }

    // Define the full path of the file to save
    String filePath = "${musicDir.path}/$fileName";

    // Download the file using Dio
    Dio dio = Dio();
    await dio.download(
      fileUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          log("Progress: ${(received / total * 100).toStringAsFixed(0)}%");
        }
      },
    );

    log("File downloaded successfully: $filePath");
  } catch (e) {
    log("Error downloading file: $e");
  }
}
