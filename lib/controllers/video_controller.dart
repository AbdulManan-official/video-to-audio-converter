import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../models/video_model.dart';

class VideoController extends GetxController {
  var videoFolders =
      <String, List<File>>{}.obs; // Folder name -> List of videos
  var isLoading = true.obs;
  var videos = <VideoModel>[].obs; // Observable list of VideoModel
  static const platform = MethodChannel('com.example.video_to_audio');
  var thumbnails =
      <String, String>{}.obs; // Map to store video path -> thumbnail path

  RxBool isFolder = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVideos(); // Fetch videos when the controller is initialized
  }

  Future<void> fetchVideos() async {
    try {
      isLoading(true);
      await requestPermissions();

      List<dynamic>? videoPaths =
      await platform.invokeMethod<List<dynamic>>('getVideosFromMediaStore');
      if (videoPaths != null) {
        Map<String, List<File>> folders = {};
        List<VideoModel> videoList = [];

        for (String videoPath in videoPaths) {
          File videoFile = File(videoPath);
          String folderName = path.dirname(videoPath);
          DateTime fileDate = await _getFileCreationDate(videoFile);

          videoList.add(
            VideoModel(path: videoPath, dateAdded: fileDate, title: ''),
          );

          folders[folderName] = [...folders[folderName] ?? [], videoFile];
        }

        // Sort videos by dateAdded in descending order
        videoList.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

        videoFolders.value = folders;
        videos.assignAll(videoList);
      }
    } catch (e) {
      log("Error fetching videos: $e");
    } finally {
      isLoading(false);
    }
  }


  // Asynchronous method to load thumbnail for a specific video
  Future<String?> generateThumbnail(String videoPath) async {
    if (thumbnails.containsKey(videoPath)) {
      return thumbnails[videoPath]; // Return cached thumbnail if exists
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 150,
        quality: 75,
      );
      if (thumbnailPath != null) {
        thumbnails[videoPath] = thumbnailPath; // Cache thumbnail
        return thumbnailPath;
      }
    } catch (e) {
      log("Error generating thumbnail: $e");
    }
    return null;
  }

  double getFileSizeInMB(String filePath, {int precision = 2}) {
    try {
      final file = File(filePath);

      if (!file.existsSync()) {
        throw FileSystemException("File does not exist", filePath);
      }

      final bytes = file.lengthSync();
      final mb = bytes / (1024 * 1024); // Convert bytes to MB

      return double.parse(mb.toStringAsFixed(precision)); // Precision
    } catch (e) {
      print("Error getting file size: $e");
      return 0.0; // Return 0.0 on error
    }
  }

  // Request storage permission
  Future<bool> requestPermissions() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 30) {
        // SAF requires folder picker; permissions aren't enough
        log('Requesting folder access for Android 13+');
        var permissions = await [Permission.manageExternalStorage].request();
        return permissions[Permission.manageExternalStorage]!.isGranted;
      } else {
        // For SDK below 30, request storage permission
        var permissions = await [Permission.storage].request();
        return permissions[Permission.storage]!.isGranted;
      }
    } catch (e) {
      log('Error requesting permissions: $e');
      return false;
    }
  }

  // Helper to get the creation date of a file
  Future<DateTime> _getFileCreationDate(File file) async {
    return (await file.stat()).changed;
  }
}
