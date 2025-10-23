// ignore_for_file: camel_case_types

import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../models/video_model.dart';

class Videos_Controller extends GetxController {
  var videos = <VideoModel>[].obs;
  RxBool isFolder = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    // Request storage permission
    var status = await Permission.storage.request();
    if (status.isGranted) {
      var videoList = await _getAllVideosFromStorage();
      videoList.sort(
          (a, b) => b.dateAdded.compareTo(a.dateAdded)); // Sort by date added
      videos.assignAll(videoList); // Assign the list to observable
    } else {
      Get.snackbar('Permission Denied',
          'Storage permission is required to access videos.');
    }
  }

  Future<List<VideoModel>> _getAllVideosFromStorage() async {
    List<VideoModel> videoFiles = [];

    // Access external storage and internal storage directories
    List<Directory?> directories = await _getAllStorageDirectories();

    // Iterate through directories to find video files
    for (Directory? directory in directories) {
      if (directory != null) {
        final files = directory.listSync(recursive: true);
        for (var file in files) {
          if (file is File && _isVideoFile(file.path)) {
            String fileName = path.basenameWithoutExtension(file.path);
            videoFiles.add(VideoModel(
              title: fileName,
              path: file.path,
              dateAdded: await _getFileCreationDate(file),
            ));
          }
        }
      }
    }
    return videoFiles;
  }

  Future<List<Directory?>> _getAllStorageDirectories() async {
    // Get both internal and external storage directories
    Directory? externalStorage = await getExternalStorageDirectory();
    // Directory? internalStorage = await getApplicationDocumentsDirectory();

    return [externalStorage];
  }

  bool _isVideoFile(String path) {
    return path.endsWith('.mp4') ||
        path.endsWith('.mkv') ||
        path.endsWith('.avi') ||
        path.endsWith('.mov');
  }

  Future<DateTime> _getFileCreationDate(File file) async {
    var fileStat = await file.stat();
    return fileStat.changed;
  }
}
