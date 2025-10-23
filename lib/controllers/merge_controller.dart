import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import '../utils/audio_merge_util.dart'; // <- New import

class MergeAudioController extends GetxController {
  var mp3Files = <File>[].obs; // Observable list of MP3 files
  var selectedItems = <bool>[].obs; // Observable list of selected items
  var mp3FilesOfMusic = <File>[].obs; // Observable list of MP3 files
  var selectedItemsOfMusic = <bool>[].obs; // Observable list of selected items
  var fileSizes = <String, String>{}.obs; // File sizes
  var fileDurations = <String, String>{}.obs; // File durations
  var fileThumbnails = <String, Uint8List?>{}.obs; // Thumbnails
  static const platform = MethodChannel('com.example.video_to_audio');
  var isLoading = true.obs; // Loading state
  Rx<DownloadTaskStatus> currentStatus = DownloadTaskStatus.undefined.obs;
  var downloadProgress = 0.0.obs; // Tracks progress percentage (0 to 100)
  var isMerging = false.obs;

  void updateSelection({
    required int index,
    required bool value,
    required bool isRecentMerged,
  }) {
    if (isRecentMerged) {
      selectedItemsOfMusic[index] = value;
      selectedItemsOfMusic.refresh();
    } else {
      selectedItems[index] = value;
      selectedItems.refresh();
    }
  }

  /// Merge audio files locally using FFmpeg utils
  Future<String> mergeAudioFiles(
      List<String> filePaths, String outputFileName) async {
    if (filePaths.length < 2) {
      print("[MergeAudio] Error: Need at least 2 files");
      return '';
    }

    try {
      isMerging.value = true;
      print("[MergeAudio] Starting local merge...");

      // Call local merge utility
      final mergedPath = await AudioMergeUtils.mergeTwoFiles(
          filePaths[0], filePaths[1], outputFileName);

      if (mergedPath.isEmpty) {
        print("[MergeAudio] Error: Merging failed");
        return '';
      }

      print("[MergeAudio] Merged file created at: $mergedPath");
      return mergedPath;
    } catch (e) {
      print("[MergeAudio] Exception during merge: $e");
      return '';
    } finally {
      isMerging.value = false;
    }
  }

  void checkFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      log('File size: ${await file.length()} bytes');
    } else {
      log('Error: File does not exist at $path');
    }
  }

  // Load MP3 files (Mock method for demonstration)
  Future<void> loadMp3Files(List<File> files) async {
    mp3Files.assignAll(files);
    selectedItems.assignAll(List.generate(files.length, (_) => false));
  }

  Future<void> fetchMp3Files() async {
    isLoading(true);
    try {
      final List<dynamic> mp3Paths =
      await platform.invokeMethod('getAllAudioFiles');

      List<File> files = [];
      for (var uriPath in mp3Paths) {
        String uri = uriPath.toString();
        files.add(File(uri));
      }

      mp3Files.assignAll(files);
      selectedItems.assignAll(List<bool>.filled(files.length, false));
    } catch (e) {
      log("Error fetching MP3 files: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchMp3FilesofMusic() async {
    isLoading(true);
    try {
      Directory musicDir = Directory('/storage/emulated/0/Music/VideoMusic');
      if (!await musicDir.exists()) {
        log("Directory does not exist: ${musicDir.path}");
        return;
      }

      List<File> files = [];
      await for (var entity in musicDir.list()) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          files.add(entity);
        }
      }

      mp3FilesOfMusic.assignAll(files);
      selectedItemsOfMusic.assignAll(List<bool>.filled(files.length, false));
      selectedItems.assignAll(List.filled(mp3FilesOfMusic.length, false));
    } catch (e) {
      log("Error fetching MP3 files: $e");
    } finally {
      isLoading(false);
    }
  }

  final RxBool isPlaying = false.obs;
  final RxInt currentlyPlayingIndex = RxInt(0);
  final AudioPlayer audioPlayer = AudioPlayer();

  void toggleAudio(String filePath, int index) async {
    if (currentlyPlayingIndex.value == index && isPlaying.value) {
      isPlaying.value = false;
      currentlyPlayingIndex.value = 0;
      await audioPlayer.stop();
    } else {
      try {
        isPlaying.value = true;
        currentlyPlayingIndex.value = index;

        await audioPlayer.setFilePath(filePath);
        await audioPlayer.play();

        audioPlayer.playerStateStream.listen((state) {
          if (!state.playing &&
              state.processingState == ProcessingState.completed) {
            isPlaying.value = false;
            currentlyPlayingIndex.value = 0;
          }
        });
      } catch (e) {
        print("Error playing audio: $e");
        isPlaying.value = false;
        currentlyPlayingIndex.value = 0;
      }
    }
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int index = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && index < units.length - 1) {
      size /= 1024;
      index++;
    }
    return '${size.toStringAsFixed(2)} ${units[index]}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds";
  }

  void selectAll() {
    selectedItems.assignAll(List.filled(selectedItems.length, true));
  }

  void removeAll() {
    selectedItems.assignAll(List.filled(selectedItems.length, false));
  }

  int get selectedCount => selectedItems.where((selected) => selected).length;
  int get selectedCountOFMusic =>
      selectedItemsOfMusic.where((selected) => selected).length;

  Future<bool> downloadCompleteFuture(String taskId) async {
    final completer = Completer<bool>();
    Timer? timeoutTimer;

    Future<void> checkStatus() async {
      final tasks = await FlutterDownloader.loadTasksWithRawQuery(
          query: "SELECT * FROM task WHERE task_id='$taskId'");
      if (tasks == null || tasks.isEmpty) return;

      final task = tasks.first;
      final status = task.status;

      if (status == DownloadTaskStatus.complete) {
        if (!completer.isCompleted) completer.complete(true);
      } else if (status == DownloadTaskStatus.failed) {
        if (!completer.isCompleted) completer.complete(false);
      }
    }

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (completer.isCompleted) {
        timer.cancel();
      } else {
        checkStatus();
      }
    });

    timeoutTimer = Timer(const Duration(seconds: 60), () {
      if (!completer.isCompleted) completer.complete(false);
    });

    final result = await completer.future;
    timeoutTimer.cancel();
    return result;
  }
}
