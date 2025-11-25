import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_to_audio_converter/utils/prefs.dart';
import 'package:video_to_audio_converter/utils/resources.dart';
import 'package:video_to_audio_converter/utils/ringtone_set_mul.dart';
import 'package:video_to_audio_converter/views/home_page.dart';
import '../../controllers/network_controller.dart';
import '../../utils/trim_audio.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import '../../controllers/merge_controller.dart';
import '../../controllers/video_controller.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path/path.dart' as p;
import '../../utils/search_filter_bar.dart';
import '../../utils/responsive_helper.dart';

const Color secondaryColor = Color(0xFF6C63FF);
const Color primaryColor = Color(0xFF6C63FF);

class SetRingtonePage extends StatefulWidget {
  const SetRingtonePage({super.key});
  @override
  _SetRingtonePageState createState() => _SetRingtonePageState();
}

class _SetRingtonePageState extends State<SetRingtonePage> {
  // --- STATE MANAGEMENT ---
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  bool _isFetchingFiles = false;
  bool _isFetchingLocalFiles = false;
  File? _appSelectedRingtone;
  String? _appSelectedRingtoneName;
  bool _localMusicPermissionGranted = false;

  // Selection tracking
  File? _selectedFile;
  String? _selectedFileName;
  bool _ringtoneSetSuccessfully = false;

  // Trim parameters
  double _trimStartMs = 0.0;
  double _trimDurationMs = 30000.0;
  bool _isProcessing = false;

  // Permission state
  bool _hasWritePermission = false;
  int _androidSdkVersion = 0;

  // Controllers
  final VideoController videoController = Get.put(VideoController());
  final MergeAudioController mergeController = Get.put(MergeAudioController());

  // App-specific file lists
  List<File> extractedAudiosFiles = [];
  List<File> mergedAudiosFiles = [];
  List<File> convertedAudiosFiles = [];

  Map<String, String> appAudiosFileSizes = {};
  Map<String, Duration> appAudiosFileDurations = {};

  // Local Music data
  List<File> localMusicFiles = [];
  Map<String, String> localMusicFileSizes = {};
  Map<String, Duration> localMusicFileDurations = {};

  // Audio players
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _listAudioPlayer = AudioPlayer();

  // GlobalKey to access TrimAudioWidget's audio player
  final GlobalKey<TrimAudioWidgetState> _trimAudioKey =
  GlobalKey<TrimAudioWidgetState>();

  @override
  void initState() {
    super.initState();
    _initializePermissionsAndRingtone();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllAppAudioFiles();
    });
    _setupAudioPlayerListeners();
  }

  Future<void> _initializePermissionsAndRingtone() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _androidSdkVersion = androidInfo.version.sdkInt;

      log('[Init] Android SDK Version: $_androidSdkVersion');

      await _requestRingtonePermission();
      await _loadAppSelectedRingtone();
    } catch (e) {
      log('[Init] Error during initialization: $e');
    }
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _audioPlayer.stop();
        if (mounted) setState(() {});
      }
    });

    _listAudioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _listAudioPlayer.stop();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _listAudioPlayer.dispose();
    super.dispose();
  }

  String formatFileName(String? name, {int maxLength = 15}) {
    if (name == null) return '';
    return name.length > maxLength
        ? '${name.substring(0, maxLength)}...'
        : name;
  }

  Future<void> _requestRingtonePermission() async {
    try {
      log('[Permission] Checking write permission...');
      _hasWritePermission = await RingtoneSetMul.isWriteGranted;
      log('[Permission] Write permission status: $_hasWritePermission');

      if (!_hasWritePermission) {
        log('[Permission] Requesting system permissions...');
        _hasWritePermission = await RingtoneSetMul.requestSystemPermissions();
        log('[Permission] Permission request result: $_hasWritePermission');
      }

      if (!_hasWritePermission) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      log('[Permission] Error checking/requesting permissions: $e');
      _hasWritePermission = false;
    }
  }

  void _showPermissionDeniedDialog() {
    final r = ResponsiveHelper(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Permission Required',
          style: TextStyle(fontSize: r.fs(16)),
        ),
        content: Text(
          'This app needs permission to modify system settings to set ringtones. '
              'Please grant the permission in the next screen.',
          style: TextStyle(fontSize: r.fs(14)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Cancel', style: TextStyle(fontSize: r.fs(14))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestRingtonePermission();
            },
            child: Text('Grant Permission', style: TextStyle(fontSize: r.fs(14))),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAppSelectedRingtone() async {
    final path = Prefs.getString('ringtone_path') ?? '';
    final name = Prefs.getString('ringtone_string') ?? '';

    log('[LoadRingtone] Retrieved path: $path');
    log('[LoadRingtone] Retrieved name: $name');

    if (path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        setState(() {
          _appSelectedRingtone = file;
          _appSelectedRingtoneName = name;
        });
        log('[LoadRingtone] Ringtone loaded: $_appSelectedRingtoneName');
      } else {
        log('[LoadRingtone] File does not exist, clearing preferences');
        await _clearRingtonePreferences();
      }
    } else {
      log('[LoadRingtone] No ringtone path found');
    }
  }

  Future<void> _clearRingtonePreferences() async {
    Prefs.remove('rintone_set');
    Prefs.remove('ringtone_string');
    Prefs.remove('ringtone_path');
    setState(() {
      _appSelectedRingtone = null;
      _appSelectedRingtoneName = null;
    });
    log('[ClearPrefs] All ringtone preferences cleared');
  }

  Future<void> _deletePreviousRingtoneFromDevice() async {
    if (_appSelectedRingtone == null) return;

    try {
      final path = _appSelectedRingtone!.path;
      final file = File(path);

      if (path.contains('/Music/Ringtones/') && path.contains('_ringtone_')) {
        if (await file.exists()) {
          await file.delete();
          log('[DeleteRingtone] Deleted previous ringtone: $path');
        }
      } else {
        log('[DeleteRingtone] Skipped deletion (not our created file): $path');
      }
    } catch (e) {
      log('[DeleteRingtone] Error: $e');
    }
  }

  void _stopAllAudio() {
    _audioPlayer.stop();
    _listAudioPlayer.stop();
    _trimAudioKey.currentState?.stopAudio();
  }

  Future<void> _playAudio(File audioFile) async {
    final isPlayingThisFile = _listAudioPlayer.playing &&
        _listAudioPlayer.audioSource?.sequence.first.tag == audioFile.path;

    if (isPlayingThisFile) {
      await _listAudioPlayer.stop();
    } else {
      _stopAllAudio();

      try {
        await _listAudioPlayer.setFilePath(audioFile.path, tag: audioFile.path);
        await _listAudioPlayer.play();
      } catch (e) {
        log('[PlayAudio] Error: $e');
      }
    }
    setState(() {});
  }

  Future<void> _fetchAllAppAudioFiles() async {
    if (mounted) {
      setState(() {
        _isFetchingFiles = true;
      });
    }

    await Future.wait([
      _fetchFilesFromDirectory(
          '/storage/emulated/0/Music/VideoMusic', extractedAudiosFiles),
      _fetchFilesFromDirectory(
          '/storage/emulated/0/Music/MergedAudio', mergedAudiosFiles),
      _fetchFilesFromDirectory(
          '/storage/emulated/0/Music/Format Converter', convertedAudiosFiles),
    ]);

    List<File> allAppFiles = [
      ...extractedAudiosFiles,
      ...mergedAudiosFiles,
      ...convertedAudiosFiles
    ];

    _loadFileInfoInBackground(
        allAppFiles, appAudiosFileSizes, appAudiosFileDurations);

    if (mounted) {
      setState(() {
        _isFetchingFiles = false;
      });
    }
  }

  Future<void> _fetchFilesFromDirectory(
      String directoryPath, List<File> targetList) async {
    targetList.clear();
    Directory dir = Directory(directoryPath);
    if (await dir.exists()) {
      List<File> files = dir
          .listSync()
          .where((item) => !item.path.contains(".pending-"))
          .map((item) => File(item.path))
          .toList();

// ✅ Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      targetList.addAll(files);
    }
  }

  // COMPLETELY REWRITTEN: Simplified local file fetching
  Future<void> _fetchLocalAudioFiles({bool forcePermissionCheck = false}) async {
    log('[LOCAL FETCH] STARTING LOCAL FILE SCAN');

    setState(() {
      _isFetchingLocalFiles = true;
      _localMusicPermissionGranted = true; // Always set to true
    });

    try {
      // Clear previous data
      localMusicFiles.clear();
      localMusicFileSizes.clear();
      localMusicFileDurations.clear();

      log('[LOCAL FETCH] Cleared previous local file data');

      // Define EXACT paths to exclude (case-insensitive comparison)
      final List<String> excludePaths = [
        '/storage/emulated/0/music/videomusic',
        '/storage/emulated/0/music/mergedaudio',
        '/storage/emulated/0/music/format converter',
        '/storage/emulated/0/music/ringtones',
      ];

      log('[LOCAL FETCH] Excluded paths: $excludePaths');

      // Define directories to search
      final List<Directory> searchDirs = [
        Directory('/storage/emulated/0/Music'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Audio'),
      ];

      int totalFilesFound = 0;
      List<File> allFoundFiles = [];

      // Scan each directory
      for (Directory searchDir in searchDirs) {
        log('[LOCAL FETCH] ───────────────────────────────────────');
        log('[LOCAL FETCH] Scanning: ${searchDir.path}');

        if (!await searchDir.exists()) {
          log('[LOCAL FETCH] ✗ Directory does not exist');
          continue;
        }

        log('[LOCAL FETCH] ✓ Directory exists, starting recursive scan...');

        try {
          await for (FileSystemEntity entity in searchDir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              String filePath = entity.path;
              String filePathLower = filePath.toLowerCase();

              // Check if it's an audio file
              if (filePathLower.endsWith('.mp3') ||
                  filePathLower.endsWith('.m4a') ||
                  filePathLower.endsWith('.wav') ||
                  filePathLower.endsWith('.aac') ||
                  filePathLower.endsWith('.flac') ||
                  filePathLower.endsWith('.ogg')) {

                // Check if file is in excluded directory
                bool isExcluded = false;
                for (String excludePath in excludePaths) {
                  if (filePathLower.contains(excludePath)) {
                    isExcluded = true;
                    break;
                  }
                }

                if (!isExcluded) {
                  allFoundFiles.add(entity);
                  totalFilesFound++;
                  log('[LOCAL FETCH] ✓ Found: $filePath');
                }
              }
            }
          }
        } catch (e) {
          log('[LOCAL FETCH] ✗ Error scanning ${searchDir.path}: $e');
        }
      }

      log('[LOCAL FETCH] ───────────────────────────────────────');
      log('[LOCAL FETCH] SCAN COMPLETE');
      log('[LOCAL FETCH] Total audio files found: $totalFilesFound');
      log('[LOCAL FETCH] ───────────────────────────────────────');

      // Update state with found files
      try {
        allFoundFiles.sort((a, b) {
          try {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          } catch (e) {
            return 0;
          }
        });
        log('[LOCAL FETCH] Files sorted by modification time');
      } catch (e) {
        log('[LOCAL FETCH] Sorting failed: $e');
      }

      // Update state with found files
      setState(() {
        localMusicFiles = allFoundFiles;
        _isFetchingLocalFiles = false;
      });

      log('[LOCAL FETCH] State updated with ${allFoundFiles.length} files');

      // Load metadata for found files
      if (allFoundFiles.isNotEmpty) {
        log('[LOCAL FETCH] Loading metadata...');
        _loadFileInfoInBackground(
          allFoundFiles,
          localMusicFileSizes,
          localMusicFileDurations,
        );
      }

    } catch (e, stackTrace) {
      log('[LOCAL FETCH] ✗✗✗ CRITICAL ERROR ✗✗✗');
      log('[LOCAL FETCH] Error: $e');
      log('[LOCAL FETCH] Stack trace: $stackTrace');

      setState(() {
        localMusicFiles.clear();
        _isFetchingLocalFiles = false;
      });
    }

    log('═══════════════════════════════════════════════════');
    log('[LOCAL FETCH] LOCAL FILE SCAN FINISHED');
    log('═══════════════════════════════════════════════════');
  }

  void _loadFileInfoInBackground(List<File> files, Map<String, String> sizesMap,
      Map<String, Duration> durationsMap) {
    for (File file in files) {
      String fileName = file.path.split('/').last;

      // Load file size
      file.length().then((bytes) {
        sizesMap[fileName] = _formatBytes(bytes);
        if (mounted) setState(() {});
      }).catchError((e) {
        log('[LoadFileInfo] Error loading size for $fileName: $e');
        sizesMap[fileName] = 'Unknown';
      });

      // Load duration if not already loaded
      if (durationsMap[fileName] == null) {
        _loadDurationAsync(file, fileName, durationsMap);
      }
    }
  }

  Future<void> _loadDurationAsync(File file, String fileName,
      Map<String, Duration> durationsMap) async {
    AudioPlayer audioPlayer = AudioPlayer();
    try {
      await audioPlayer.setFilePath(file.path);
      Duration? duration = audioPlayer.duration;
      durationsMap[fileName] = duration ?? Duration.zero;
      if (mounted) setState(() {});
    } catch (e) {
      log('[LoadDuration] Error for ${file.path}: $e');
      durationsMap[fileName] = Duration.zero;
    } finally {
      audioPlayer.dispose();
    }
  }

  String _formatBytes(int bytes, [int decimals = 2]) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = duration.inHours > 0 ? '${duration.inHours}:' : '';
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours$minutes:$seconds';
  }

  Future<File> _trimAudioFile(
      File sourceFile, double startMs, double durationMs) async {
    final start = startMs / 1000;
    final duration = durationMs / 1000;

    final externalDir = Directory('/storage/emulated/0/Music/Ringtones');

    if (!await externalDir.exists()) {
      await externalDir.create(recursive: true);
      log('[TrimAudio] Created Ringtones directory');
    }

    final name = p.basenameWithoutExtension(sourceFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = "${externalDir.path}/${name}_ringtone_$timestamp.mp3";

    final cmd =
        "-i \"${sourceFile.path}\" -ss $start -t $duration -acodec libmp3lame -b:a 192k \"$newPath\"";

    log('[TrimAudio] FFmpeg command: $cmd');
    log('[TrimAudio] Output path: $newPath');

    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (!returnCode!.isValueSuccess()) {
      final output = await session.getOutput();
      log('[TrimAudio] FFmpeg failed: ${returnCode.getValue()}');
      log('[TrimAudio] Output: $output');
      throw Exception('Failed to trim audio file');
    }

    final trimmedFile = File(newPath);
    if (!await trimmedFile.exists()) {
      throw Exception('Trimmed file was not created');
    }

    final fileSize = await trimmedFile.length();
    if (fileSize == 0) {
      throw Exception('Trimmed file is empty');
    }

    log('[TrimAudio] Success: $newPath (${_formatBytes(fileSize)})');
    return trimmedFile;
  }

  Future<bool> _verifyFileForRingtone(File file) async {
    try {
      if (!await file.exists()) {
        log('[VerifyFile] File does not exist: ${file.path}');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        log('[VerifyFile] File is empty');
        return false;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        log('[VerifyFile] Cannot read file');
        return false;
      }

      log('[VerifyFile] File verified: ${_formatBytes(fileSize)}');
      return true;
    } catch (e) {
      log('[VerifyFile] Error: $e');
      return false;
    }
  }

  Future<void> _setRingtone(String songTitle, File file) async {
    log('[SetRingtone] Starting process for: $songTitle');
    log('[SetRingtone] File path: ${file.path}');

    if (!file.path.startsWith('/storage/emulated/0/')) {
      log('[SetRingtone] Error: File not in external storage');
      toastFlutter(
        toastmessage: "File must be in external storage",
        color: Colors.red[700],
      );
      return;
    }

    final isValid = await _verifyFileForRingtone(file);
    if (!isValid) {
      toastFlutter(
        toastmessage: "Invalid audio file",
        color: Colors.red[700],
      );
      return;
    }

    if (!_hasWritePermission) {
      log('[SetRingtone] No write permission');
      toastFlutter(
        toastmessage: "Permission required to set ringtone",
        color: Colors.red[700],
      );
      await _requestRingtonePermission();
      return;
    }

    try {
      log('[SetRingtone] Calling RingtoneSetMul.setRingtone()...');

      bool success = await RingtoneSetMul.setRingtone(
        file.path,
        mimeType: 'audio/mpeg',
      );

      log('[SetRingtone] Result: $success');

      if (success) {
        log('[SetRingtone] Clearing all previous ringtone preferences');
        await _clearRingtonePreferences();

        await Future.delayed(const Duration(milliseconds: 100));

        await Prefs.setBool('rintone_set', true);
        await Prefs.setString('ringtone_string', songTitle);
        await Prefs.setString('ringtone_path', file.path);

        log('[SetRingtone] New preferences saved - Path: ${file.path}');
        log('[SetRingtone] New preferences saved - Name: $songTitle');

        toastFlutter(
          toastmessage: '$songTitle ringtone set successfully',
          color: Colors.green[700],
        );

        if (mounted) {
          setState(() {
            _ringtoneSetSuccessfully = true;
            _appSelectedRingtone = file;
            _appSelectedRingtoneName = songTitle;
            _selectedFile = null;
            _selectedFileName = null;
            _trimStartMs = 0.0;
            _trimDurationMs = 30000.0;
          });
        }

        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {});
        }
      } else {
        log('[SetRingtone] Failed: setRingtone returned false');
        _showRingtoneErrorDialog();
      }
    } catch (e) {
      log('[SetRingtone] Exception: $e');
      _showRingtoneErrorDialog(error: e.toString());
    }
  }

  void _showRingtoneErrorDialog({String? error}) {
    final r = ResponsiveHelper(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Failed to Set Ringtone',
          style: TextStyle(fontSize: r.fs(16)),
        ),
        content: Text(
          error != null
              ? 'An error occurred: $error\n\nPlease try again or select a different audio file.'
              : 'Could not set the ringtone. Please ensure you have granted the necessary permissions.',
          style: TextStyle(fontSize: r.fs(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(fontSize: r.fs(14))),
          ),
          if (!_hasWritePermission)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _requestRingtonePermission();
              },
              child: Text('Check Permissions', style: TextStyle(fontSize: r.fs(14))),
            ),
        ],
      ),
    );
  }

  void _processAndSetRingtone() async {
    if (_selectedFile == null || _selectedFileName == null) return;

    if (!_hasWritePermission) {
      await _requestRingtonePermission();
      if (!_hasWritePermission) return;
    }

    setState(() => _isProcessing = true);

    File? tempTrimmedFile;

    try {
      log('[Process] Starting trim operation...');

      tempTrimmedFile = await _trimAudioFile(
        _selectedFile!,
        _trimStartMs,
        _trimDurationMs,
      );

      log('[Process] Trim completed: ${tempTrimmedFile.path}');

      await _deletePreviousRingtoneFromDevice();

      await _setRingtone(_selectedFileName!, tempTrimmedFile);
    } catch (e) {
      log('[Process] Error: $e');
      toastFlutter(
        toastmessage: "Failed to process audio: ${e.toString()}",
        color: Colors.red[700],
      );

      if (tempTrimmedFile != null && await tempTrimmedFile.exists()) {
        try {
          await tempTrimmedFile.delete();
          log('[Process] Cleaned up temp file');
        } catch (deleteError) {
          log('[Process] Failed to delete temp file: $deleteError');
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleTabSelected(int index) {
    log('═══════════════════════════════════════════════════');
    log('[TAB CHANGE] User selected tab index: $index');
    log('[TAB CHANGE] Previous tab index: $_selectedTabIndex');
    log('═══════════════════════════════════════════════════');

    if (index != _selectedTabIndex) {
      _stopAllAudio();
      setState(() {
        _selectedTabIndex = index;
        _selectedFile = null;
        _selectedFileName = null;
        _trimStartMs = 0.0;
        _trimDurationMs = 30000.0;
      });
    }

    // When Local tab (index 4) is selected
    if (index == 4) {
      log('[TAB CHANGE] Local tab selected - triggering file fetch');
      log('[TAB CHANGE] Current local files count: ${localMusicFiles.length}');
      _fetchLocalAudioFiles(forcePermissionCheck: true);
    }
  }

  // SIMPLIFIED: Get current filtered data - INCLUDES CURRENT RINGTONE IN LOCAL TAB
  (List<File>, Map<String, String>, Map<String, Duration>)
  _getCurrentFilteredData() {
    List<File> sourceList;
    Map<String, String> sizeMap;
    Map<String, Duration> durationMap;

    log('[GET DATA] Getting data for tab index: $_selectedTabIndex');

    switch (_selectedTabIndex) {
      case 0:
        sourceList = [
          ...extractedAudiosFiles,
          ...mergedAudiosFiles,
          ...convertedAudiosFiles
        ];

        // ✅ Re-sort combined list since it merges multiple sources
        // ✅ Re-sort combined list since it merges multiple sources
        try {
          sourceList.sort((a, b) {
            try {
              return b.lastModifiedSync().compareTo(a.lastModifiedSync());
            } catch (e) {
              return 0;
            }
          });
        } catch (e) {
          // If sorting fails, use unsorted list
        }

        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;
      case 1:
        sourceList = extractedAudiosFiles;
        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;

      case 2:
        sourceList = mergedAudiosFiles;
        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;
      case 3:
        sourceList = convertedAudiosFiles;
        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;
      case 4:
        sourceList = List<File>.from(localMusicFiles); // Create copy
        sizeMap = localMusicFileSizes;
        durationMap = localMusicFileDurations;
        log('[GET DATA] Local tab - Files count: ${sourceList.length}');

        // CRITICAL: For Local tab, ALWAYS include current ringtone if it exists
        if (_appSelectedRingtone != null &&
            _appSelectedRingtoneName != null &&
            _appSelectedRingtone!.path.isNotEmpty) {

          // Check if ringtone file exists
          if (File(_appSelectedRingtone!.path).existsSync()) {
            // Check if it's in Ringtones folder (our created ringtone)
            if (_appSelectedRingtone!.path.toLowerCase().contains('/music/ringtones/')) {
              // Remove duplicate if exists
              sourceList.removeWhere((file) => file.path == _appSelectedRingtone!.path);

              // Add at beginning
              sourceList.insert(0, _appSelectedRingtone!);

              String currentFileName = _appSelectedRingtone!.path.split('/').last;
              if (!sizeMap.containsKey(currentFileName)) {
                sizeMap[currentFileName] = 'Current';
              }
              if (!durationMap.containsKey(currentFileName)) {
                durationMap[currentFileName] = Duration.zero;
              }

              log('[GET DATA] Added current ringtone to Local tab: ${_appSelectedRingtone!.path}');
            } else {
              log('[GET DATA] Current ringtone already in local list (not in Ringtones folder)');
            }
          } else {
            log('[GET DATA] Current ringtone file no longer exists');
            _clearRingtonePreferences();
          }
        }
        break;
      default:
        sourceList = [];
        sizeMap = {};
        durationMap = {};
    }

    // Handle current ringtone pinning for other tabs (not Local)
    if (_selectedTabIndex != 4 &&
        _appSelectedRingtone != null &&
        _appSelectedRingtoneName != null &&
        _appSelectedRingtone!.path.isNotEmpty) {
      if (File(_appSelectedRingtone!.path).existsSync()) {
        sourceList.removeWhere((file) => file.path == _appSelectedRingtone!.path);
        sourceList.insert(0, _appSelectedRingtone!);

        String currentFileName = _appSelectedRingtone!.path.split('/').last;
        if (!sizeMap.containsKey(currentFileName)) {
          sizeMap[currentFileName] = 'Current';
        }
        if (!durationMap.containsKey(currentFileName)) {
          durationMap[currentFileName] = Duration.zero;
        }
      } else {
        _clearRingtonePreferences();
      }
    }

    // Apply search filter
    final lowerCaseQuery = _searchQuery.toLowerCase();
    final filteredList = sourceList.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(lowerCaseQuery);
    }).toList();

    log('[GET DATA] Filtered list count: ${filteredList.length}');

    return (filteredList, sizeMap, durationMap);
  }

  Widget _buildRingtoneList() {
    final r = ResponsiveHelper(context);

    // Handle local files loading state
    if (_selectedTabIndex == 4 && _isFetchingLocalFiles) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(r.w(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: r.w(2)),
                SizedBox(height: r.h(16)),
                Text(
                  'Scanning local audio files...',
                  style: TextStyle(
                    fontSize: r.fs(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final (filteredList, sizeMap, durationMap) = _getCurrentFilteredData();

    final String emptyMessage;
    switch (_selectedTabIndex) {
      case 0:
        emptyMessage = "No App Audios Found";
        break;
      case 1:
        emptyMessage = "No Extracted Audios Found";
        break;
      case 2:
        emptyMessage = "No Merged Audios Found";
        break;
      case 3:
        emptyMessage = "No Converted Audios Found";
        break;
      case 4:
        emptyMessage = "No Local Music Found";
        break;
      default:
        emptyMessage = "No Files Found";
    }

    if (filteredList.isEmpty && !_isFetchingFiles) {
      final String message = _searchQuery.isNotEmpty
          ? "No matching files found for '$_searchQuery'"
          : emptyMessage;

      return SliverToBoxAdapter(
        child: Container(
          color: Colors.grey[100],
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(r.w(40)),
              child: Column(
                children: [
                  Icon(
                    Icons.audio_file_outlined,
                    size: r.w(64),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: r.h(16)),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: r.fs(16),
                      color: Colors.grey[600],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isFetchingFiles && filteredList.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(r.w(32)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: r.w(2)),
                SizedBox(height: r.h(16)),
                Text(
                  'Loading audio files...',
                  style: TextStyle(
                    fontSize: r.fs(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(bottom: r.h(16)),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            File mp3File = filteredList[index];
            String fileName = mp3File.path.split('/').last;

            final bool isCurrentRingtone = _appSelectedRingtone != null &&
                _appSelectedRingtone!.path == mp3File.path;

            final bool isSelected = (_selectedFile?.path == mp3File.path);

            return _buildFileListItem(
              mp3File: mp3File,
              index: index,
              isSelected: isSelected,
              isCurrentRingtone: isCurrentRingtone,
              fileSize: sizeMap[fileName] ?? '...',
              duration: durationMap[fileName] != null
                  ? _formatDuration(durationMap[fileName]!)
                  : '...',
            );
          },
          childCount: filteredList.length,
        ),
      ),
    );
  }

  Widget _buildFileListItem({
    required File mp3File,
    required int index,
    required bool isSelected,
    required bool isCurrentRingtone,
    required String fileSize,
    required String duration,
  }) {
    final r = ResponsiveHelper(context);
    String fileName = mp3File.path.split('/').last;
    String displayName = formatFileName(fileName, maxLength: 25);

    final Color itemColor =
    isCurrentRingtone ? Colors.yellow[50]! : Colors.white;

    final Color borderColor = isCurrentRingtone
        ? Colors.orange[800]!
        : (isSelected ? primaryColor : Colors.grey.withOpacity(0.5));

    return GestureDetector(
      onTap: () {
        _stopAllAudio();
        setState(() {
          _selectedFile = mp3File;
          _selectedFileName = fileName;
        });
      },

      child: Container(
        margin: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(6)),
        padding: EdgeInsets.all(r.w(12)),
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(r.w(12)),
          border: Border.all(
            color: borderColor,
            width: isCurrentRingtone || isSelected ? r.w(1.5) : r.w(1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: r.w(50),
              height: r.w(50),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r.w(10)),
                gradient: LinearGradient(
                  colors: isCurrentRingtone
                      ? [Colors.orange, Colors.deepOrange]
                      : [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                  isCurrentRingtone ? Icons.ring_volume : Icons.audio_file,
                  color: Colors.white,
                  size: r.w(28)),
            ),
            SizedBox(width: r.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCurrentRingtone ? 'Current Ringtone' : displayName,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: r.fs(15),
                            fontWeight: FontWeight.w500,
                            color: isCurrentRingtone
                                ? Colors.deepOrange
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (isCurrentRingtone)
                        Container(
                          margin: EdgeInsets.only(left: r.w(8)),
                          padding: EdgeInsets.symmetric(
                            horizontal: r.w(8),
                            vertical: r.h(2),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(r.w(8)),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Text(
                            'PINNED',
                            style: TextStyle(
                              fontSize: r.fs(10),
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: r.h(4)),
                  Text(
                    isCurrentRingtone
                        ? "File: ${_appSelectedRingtoneName != null && _appSelectedRingtoneName!.length > 20 ? _appSelectedRingtoneName!.substring(0, 20) + '...' : (_appSelectedRingtoneName ?? 'N/A')}"
                        : "$fileSize • $duration",
                    style: TextStyle(
                      fontSize: isCurrentRingtone ? r.fs(13) : r.fs(12),
                      color: isCurrentRingtone
                          ? Colors.orange[700]
                          : Colors.grey[600],
                      fontWeight: isCurrentRingtone
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isCurrentRingtone)
              StreamBuilder<PlayerState>(
                stream: _listAudioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final playing = playerState?.playing ?? false;
                  final processingState = playerState?.processingState;

                  final isPlayingThisFile =
                      _listAudioPlayer.audioSource?.sequence.first.tag ==
                          mp3File.path;

                  final showPause = playing &&
                      processingState != ProcessingState.completed &&
                      isPlayingThisFile;

                  return IconButton(
                    icon: Icon(
                      showPause
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.orange[700],
                      size: r.w(34),
                    ),
                    onPressed: () => _playAudio(mp3File),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedItemWidget() {
    if (_selectedFile == null) {
      return const SizedBox.shrink();
    }

    final r = ResponsiveHelper(context);

    return Container(
      margin: EdgeInsets.fromLTRB(r.w(12), r.h(12), r.w(12), 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.w(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(r.w(16), r.h(12), r.w(16), r.h(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Selected Audio",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: r.fs(16),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: r.h(4)),
                Text(
                  formatFileName(_selectedFileName ?? "", maxLength: 25),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: r.fs(13),
                  ),
                ),
              ],
            ),
          ),
          TrimAudioWidget(
            key: _trimAudioKey,
            audioFile: _selectedFile!,
            onTrimmed: (startMs, durationMs) {
              if (mounted) {
                setState(() {
                  _trimStartMs = startMs;
                  _trimDurationMs = durationMs;
                });
              }
            },
            onAudioPlayStarted: () {
              _audioPlayer.stop();
              _listAudioPlayer.stop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: r.w(24),
          ),
          onPressed: () {
            _stopAllAudio();
            Navigator.pop(context);
          },
        ),
        title: Padding(
          padding: EdgeInsets.only(left: r.isTablet() ? r.w(16) : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Set Ringtone",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: r.fs(18),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: r.h(2)),
              Text(
                'Create custom ringtones',
                style: TextStyle(
                  fontSize: r.fs(13),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        toolbarHeight: r.h(70),
        actions: [
          if (_ringtoneSetSuccessfully)
            IconButton(
              icon: Icon(
                Icons.home,
                color: Colors.black,
                size: r.w(24),
              ),
              onPressed: () {
                _stopAllAudio();
                Get.offAll(() => const HomeScreen());
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: buildGenericSearchBar(
                    scaleFactor: r.scaleWidth,
                    textScaleFactor: r.textScaleFactor,
                    context: context,
                    onSearchQueryChanged: (value) {
                      if (mounted) {
                        _stopAllAudio();
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _selectedFile = null;
                          _selectedFileName = null;
                        });
                      }
                    },
                    hintText: 'Search audio files...',
                  ),
                ),
                SliverToBoxAdapter(
                  child: buildGenericFilterTabs(
                    scaleFactor: r.scaleWidth,
                    scaleFactorHeight: r.scaleHeight,
                    textScaleFactor: r.textScaleFactor,
                    context: context,
                    selectedTabIndex: _selectedTabIndex,
                    onTabSelected: _handleTabSelected,
                    tabLabels: const [
                      'All',
                      'Extracted',
                      'Merged',
                      'Converted',
                      'Local'
                    ],
                  ),
                ),
                if (_selectedFile != null)
                  SliverToBoxAdapter(
                    child: _buildSelectedItemWidget(),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      r.w(16),
                      r.h(16),
                      r.w(16),
                      r.h(16),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedFile == null
                            ? 'Select an Audio File'
                            : 'Audio Files',
                        style: TextStyle(
                          fontSize: r.fs(14),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildRingtoneList(),
              ],
            ),
          ),
          if (_selectedFile != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(r.w(16)),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: r.w(10),
                    offset: Offset(0, -r.h(5)),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: r.h(12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(r.w(12)),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isProcessing ? null : _processAndSetRingtone,
                  icon: _isProcessing
                      ? SizedBox(
                    width: r.w(20),
                    height: r.w(20),
                    child: CircularProgressIndicator(
                      strokeWidth: r.w(2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white),
                    ),
                  )
                      : Icon(Icons.notifications_active, size: r.w(24)),
                  label: Text(
                    _isProcessing ? "Processing..." : "Set as Ringtone",
                    style: TextStyle(
                      fontSize: r.fs(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}