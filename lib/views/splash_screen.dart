import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ringtone_set_mul/ringtone_set_mul.dart';
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
// Assuming this imports buildGenericSearchBar, buildGenericFilterTabs, and filterAndSortWithPinnedItem

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
  bool _hasLoadedOnce = false;
  File? _appSelectedRingtone;
  String? _appSelectedRingtoneName;

  // Selection tracking
  File? _selectedFile;
  String? _selectedFileName;
  bool _ringtoneSetSuccessfully = false;

  // Trim parameters
  double _trimStartMs = 0.0;
  double _trimDurationMs = 30000.0;
  bool _isProcessing = false;

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

  // SINGLE SHARED AUDIO PLAYER for the entire screen
  final AudioPlayer _audioPlayer = AudioPlayer();

  // New audio player dedicated to the file list
  final AudioPlayer _listAudioPlayer = AudioPlayer();

  // GlobalKey to access TrimAudioWidget's audio player
  final GlobalKey<TrimAudioWidgetState> _trimAudioKey =
  GlobalKey<TrimAudioWidgetState>();

  @override
  void initState() {
    super.initState();
    _requestRingtonePermission().then((_) {
      _loadAppSelectedRingtone();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllAppAudioFiles();
    });
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        // Stop playback and reset so play icon shows again
        _audioPlayer.stop();
        if (mounted) {
          setState(() {});
        }
      }
    });

    _listAudioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        // Stop playback and reset so play icon shows again
        _listAudioPlayer.stop();
        if (mounted) {
          setState(() {});
        }
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
    bool granted = await RingtoneSetMul.isWriteGranted;
    if (!granted) {
      granted = await RingtoneSetMul.requestSystemPermissions();
    }

    if (!granted) {
      toastFlutter(
        toastmessage: "Cannot set ringtone without permission",
        color: Colors.red[700],
      );
    }
  }

  void _loadAppSelectedRingtone() {
    final path = Prefs.getString('ringtone_path') ?? '';
    final name = Prefs.getString('ringtone_string') ?? '';

    log('[_loadAppSelectedRingtone] Called');
    log('[_loadAppSelectedRingtone] Retrieved path: $path');
    log('[_loadAppSelectedRingtone] Retrieved name: $name');

    if (path.isNotEmpty && File(path).existsSync()) {
      setState(() {
        _appSelectedRingtone = File(path);
        _appSelectedRingtoneName = name;
      });
      log('[_loadAppSelectedRingtone] Ringtone loaded successfully: $_appSelectedRingtoneName');
    } else {
      setState(() {
        _appSelectedRingtone = null;
        _appSelectedRingtoneName = null;
      });
      log('[_loadAppSelectedRingtone] No ringtone found or file does not exist at path: $path');
    }
  }

  Future<void> _deletePreviousRingtoneFromDevice() async {
    if (_appSelectedRingtone == null) return;

    try {
      final path = _appSelectedRingtone!.path;
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
        log('Previous ringtone deleted from device: $path');
      }

      Prefs.remove('rintone_set');
      Prefs.remove('ringtone_string');
      Prefs.remove('ringtone_path');
    } catch (e) {
      log('Failed to delete previous ringtone: $e');
    }
  }

  // --- STOP ALL AUDIO PLAYBACK ---
  void _stopAllAudio() {
    // Stop the main audio player
    _audioPlayer.stop();

    // Stop the list audio player
    _listAudioPlayer.stop();

    // Stop the trim widget's audio player if it exists
    _trimAudioKey.currentState?.stopAudio();
  }

  Future<void> _playAudio(File audioFile) async {
    _stopAllAudio();

    if (_listAudioPlayer.playing &&
        _listAudioPlayer.audioSource?.sequence.first.tag == audioFile.path) {
      await _listAudioPlayer.stop();
    } else {
      try {
        await _listAudioPlayer.setFilePath(audioFile.path,
            tag: audioFile.path);
        await _listAudioPlayer.play();
      } catch (e) {
        log('Error playing audio: $e');
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
        _hasLoadedOnce = true;
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
      targetList.addAll(files);
    }
  }

  Future<void> _fetchLocalAudioFiles() async {
    if (localMusicFiles.isNotEmpty) return;

    if (mounted) {
      setState(() {
        _isFetchingLocalFiles = true;
      });
    }

    try {
      await mergeController.fetchMp3Files();
      localMusicFiles = mergeController.mp3Files;
      _loadFileInfoInBackground(
          localMusicFiles, localMusicFileSizes, localMusicFileDurations);

      if (mounted) {
        setState(() {
          _isFetchingLocalFiles = false;
        });
      }
    } catch (e) {
      log('Error fetching local music: $e');
      if (mounted) {
        setState(() {
          _isFetchingLocalFiles = false;
        });
      }
    }
  }

  void _loadFileInfoInBackground(List<File> files, Map<String, String> sizesMap,
      Map<String, Duration> durationsMap) {
    for (File file in files) {
      String fileName = file.path.split('/').last;

      file.length().then((bytes) {
        sizesMap[fileName] = _formatBytes(bytes);
        if (mounted) setState(() {});
      });

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
      log('Error loading duration for ${file.path}: $e');
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
    final tempDir = Directory.systemTemp;
    final name = p.basenameWithoutExtension(sourceFile.path);
    final newPath =
        "${tempDir.path}/${name}_temp_${DateTime.now().millisecondsSinceEpoch}.mp3";
    final cmd =
        "-i \"${sourceFile.path}\" -ss $start -t $duration -acodec libmp3lame -b:a 192k \"$newPath\"";
    log('FFmpeg command: $cmd');
    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (!returnCode!.isValueSuccess()) {
      log('FFmpeg command failed with return code: ${returnCode.getValue()}');
      final output = await session.getOutput();
      log('FFmpeg output: $output');
      throw Exception('Failed to trim audio file');
    }

    final trimmedFile = File(newPath);
    if (!await trimmedFile.exists() || await trimmedFile.length() == 0) {
      log('Trimmed file check failed. Exists: ${await trimmedFile.exists()}, Length: ${await trimmedFile.length()}');
      throw Exception('Trimmed file was not created or is empty');
    }
    return trimmedFile;
  }

  void _setRingtone(String songTitle, File file) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    int sdkInt = androidInfo.version.sdkInt;

    Function setRingtoneFunc = (sdkInt >= 29)
        ? RingtoneSetter.setRingtone
        : RingtoneSet.setRingtoneFromFile;

    log('Attempting to set ringtone with path: ${file.path}');

    setRingtoneFunc(file.path).then(
          (value) {
        Prefs.setBool('rintone_set', true);
        Prefs.setString('ringtone_string', songTitle);
        Prefs.setString('ringtone_path', file.path);
        toastFlutter(
            toastmessage: '$songTitle ringtone set', color: Colors.green[700]);

        log('Ringtone set successfully: $songTitle at ${file.path}');

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
      },
      onError: (e) {
        log('Ringtone setting failed: $e');
        toastFlutter(
            toastmessage: "Failed to set ringtone: $e",
            color: Colors.red[700]);
      },
    );
  }

  void _processAndSetRingtone() async {
    if (_selectedFile == null || _selectedFileName == null) return;

    setState(() => _isProcessing = true);

    File? tempTrimmedFile;

    try {
      tempTrimmedFile =
      await _trimAudioFile(_selectedFile!, _trimStartMs, _trimDurationMs);
      log('Temporary trimmed file created at: ${tempTrimmedFile.path}');

      await _deletePreviousRingtoneFromDevice();
      _setRingtone(_selectedFileName!, tempTrimmedFile);
    } catch (e) {
      log('Error during trim or set ringtone: $e');
      toastFlutter(
          toastmessage: "Failed to set ringtone.", color: Colors.red[700]);

      if (tempTrimmedFile != null && await tempTrimmedFile.exists()) {
        try {
          await tempTrimmedFile.delete();
          log('Cleaned up temporary trimmed file.');
        } catch (deleteError) {
          log('Failed to delete temp file: $deleteError');
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleTabSelected(int index) {
    if (index != _selectedTabIndex) {
      _stopAllAudio(); // Stop all audio when changing tabs
      log('Tab changed from $_selectedTabIndex to $index');
      setState(() {
        _selectedTabIndex = index;
        _selectedFile = null;
        _selectedFileName = null;
        _trimStartMs = 0.0;
        _trimDurationMs = 30000.0;
      });
    }

    if (index == 4 && localMusicFiles.isEmpty) {
      _fetchLocalAudioFiles();
    }
  }

  (List<File>, Map<String, String>, Map<String, Duration>)
  _getCurrentFilteredData() {
    List<File> sourceList;
    Map<String, String> sizeMap;
    Map<String, Duration> durationMap;

    switch (_selectedTabIndex) {
      case 0: // All
        sourceList = [
          ...extractedAudiosFiles,
          ...mergedAudiosFiles,
          ...convertedAudiosFiles
        ];
        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;
      case 1: // Extracted
        sourceList = extractedAudiosFiles;
        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;
      case 2: // Merged
        sourceList = mergedAudiosFiles;
        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;
      case 3: // Converted
        sourceList = convertedAudiosFiles;
        sizeMap = appAudiosFileSizes;
        durationMap = appAudiosFileDurations;
        break;
      case 4: // Local
        sourceList = localMusicFiles;
        sizeMap = localMusicFileSizes;
        durationMap = localMusicFileDurations;
        break;
      default:
        sourceList = [];
        sizeMap = {};
        durationMap = {};
    }

    // ✅ CRITICAL FIX: Add the currently set ringtone to the source list if it exists
    // and is not already in the list. This ensures it's available for pinning,
    // especially if it's a temporary file outside the scanned directories.
    if (_appSelectedRingtone != null && _appSelectedRingtoneName != null) {
      // Only add if the selected tab is 'All' or a tab that could potentially contain the original file
      // For simplicity and to guarantee visibility, we'll add it to all tabs for now.
      // In a real app, you might restrict this, but for *showing* it, this is safest.
      if (!sourceList.any((file) => file.path == _appSelectedRingtone!.path)) {
        sourceList.insert(0, _appSelectedRingtone!);
        // The size and duration maps rely on the file name being the key.
        // We must add an entry for the temporary file's name.
        String currentFileName = _appSelectedRingtone!.path.split('/').last;
        if (!sizeMap.containsKey(currentFileName)) {
          sizeMap[currentFileName] = 'Current';
        }
        if (!durationMap.containsKey(currentFileName)) {
          durationMap[currentFileName] = Duration.zero;
        }
        log('Injected current ringtone from path into sourceList for display.');
      }
    }

    // Use the generic utility function to filter by search query and pin the selected ringtone.
    final filteredList = filterAndSortWithPinnedItem<File>(
      items: sourceList,
      searchQuery: _searchQuery,
      getItemName: (file) => file.path.split('/').last,
      pinnedItem: _appSelectedRingtone,
      comparePinnedItem: (item, pinnedItem) => item.path == pinnedItem.path,
    );

    log('Filtered List size: ${filteredList.length}');

    return (filteredList, sizeMap, durationMap);
  }

  Widget _buildRingtoneList(double scaleFactor, double scaleFactorHeight,
      double textScaleFactor) {
    if (_selectedTabIndex == 4 && _isFetchingLocalFiles) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32 * scaleFactor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2 * scaleFactor),
                SizedBox(height: 16 * scaleFactorHeight),
                Text(
                  'Scanning local audio files...',
                  style: TextStyle(
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      color: Colors.grey[600]),
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
              padding: EdgeInsets.all(40.0 * scaleFactor),
              child: Column(
                children: [
                  Icon(Icons.audio_file_outlined,
                      size: 64 * scaleFactor, color: Colors.grey[400]),
                  SizedBox(height: 16 * scaleFactorHeight),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16 * scaleFactor * textScaleFactor,
                        color: Colors.grey[600]),
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
            padding: EdgeInsets.all(32 * scaleFactor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2 * scaleFactor),
                SizedBox(height: 16 * scaleFactorHeight),
                Text(
                  'Loading audio files...',
                  style: TextStyle(
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(bottom: 16 * scaleFactorHeight),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            File mp3File = filteredList[index];
            String fileName = mp3File.path.split('/').last;

            final bool isSelected = (_selectedFile?.path == mp3File.path);
            final bool isCurrentRingtone =
            (_appSelectedRingtone?.path == mp3File.path);

            return _buildFileListItem(
              mp3File: mp3File,
              index: index,
              isSelected: isSelected,
              isCurrentRingtone: isCurrentRingtone,
              fileSize: sizeMap[fileName] ?? '...',
              duration: durationMap[fileName] != null
                  ? _formatDuration(durationMap[fileName]!)
                  : '...',
              scaleFactor: scaleFactor,
              scaleFactorHeight: scaleFactorHeight,
              textScaleFactor: textScaleFactor,
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
    required double scaleFactor,
    required double scaleFactorHeight,
    required double textScaleFactor,
  }) {
    String fileName = mp3File.path.split('/').last;
    String displayName = formatFileName(fileName, maxLength: 25);

    // ✅ DEBUG: Print when a file is flagged as the current ringtone
    if (isCurrentRingtone) {
      log('DEBUG: Current Ringtone found and being displayed: $fileName');
    }

    // ✅ EXAGGERATED STYLING: Define unique styling properties for the current ringtone
    final Color itemColor =
    isCurrentRingtone ? Colors.yellow[50]! : Colors.white;

    final Color borderColor = isCurrentRingtone
        ? Colors.orange[800]!
        : (isSelected ? primaryColor : Colors.grey.withOpacity(0.5));

    final List<BoxShadow> boxShadow = isCurrentRingtone
        ? [
      BoxShadow(
        color: Colors.orange.withOpacity(0.4),
        blurRadius: 8 * scaleFactor,
        offset: Offset(0, 4 * scaleFactorHeight),
      ),
    ]
        : [];

    return GestureDetector(
      onTap: () {
        _stopAllAudio();
        setState(() {
          _selectedFile = mp3File;
          _selectedFileName = fileName;
        });
      },
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: 16 * scaleFactor, vertical: 6 * scaleFactorHeight),
        padding: EdgeInsets.all(12 * scaleFactor),
        decoration: BoxDecoration(
          color: itemColor, // APPLIED YELLOW BACKGROUND COLOR
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          // boxShadow: boxShadow, // APPLIED STRONG SHADOW
          border: Border.all(
            color: borderColor,
            width: isCurrentRingtone || isSelected
                ? 1.5 * scaleFactor
                : 1 * scaleFactor, // VERY THICK BORDER
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50 * scaleFactor,
              height: 50 * scaleFactor,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10 * scaleFactor),
                gradient: LinearGradient(
                  colors: isCurrentRingtone
                      ? [Colors.orange, Colors.deepOrange]
                      : [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                  isCurrentRingtone
                      ? Icons.ring_volume
                      : Icons.audio_file, // Star icon instead of checkmark
                  color: Colors.white,
                  size: 28 * scaleFactor),
            ),
            SizedBox(width: 12 * scaleFactor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCurrentRingtone
                              ? 'Current Ringtone'
                              : displayName, // Clear label
                          maxLines: 1,
                          softWrap: false,

                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15 * scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.w900, // VERY BOLD FONT
                            color: isCurrentRingtone
                                ? Colors.deepOrange
                                : Colors.black87, // ORANGE TEXT
                          ),
                        ),
                      ),
                      if (isCurrentRingtone)
                        Container(
                          margin: EdgeInsets.only(left: 8 * scaleFactor),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * scaleFactor,
                            vertical: 2 * scaleFactorHeight,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius:
                            BorderRadius.circular(8 * scaleFactor),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Text(
                            'PINNED', // Unmistakable tag
                            style: TextStyle(
                              fontSize: 10 * scaleFactor * textScaleFactor,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4 * scaleFactorHeight),
                  SizedBox(height: 4 * scaleFactorHeight),
                  Text(
                    isCurrentRingtone
                        ? "File: ${_appSelectedRingtoneName != null && _appSelectedRingtoneName!.length > 20 ? _appSelectedRingtoneName!.substring(0, 20) + '...' : (_appSelectedRingtoneName ?? 'N/A')}"
                        : "$fileSize • $duration",
                    style: TextStyle(
                      fontSize: isCurrentRingtone
                          ? 13 * scaleFactor * textScaleFactor
                          : 12 * scaleFactor * textScaleFactor,
                      color: isCurrentRingtone
                          ? Colors.orange[700]
                          : Colors.grey[600],
                      fontWeight: isCurrentRingtone
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            // Play/Pause button for the current ringtone
            if (isCurrentRingtone)
              StreamBuilder<PlayerState>(
                stream: _listAudioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final playing = playerState?.playing ?? false;
                  final processingState = playerState?.processingState;

                  final isPlayingThisFile = _listAudioPlayer
                      .audioSource?.sequence.first.tag ==
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
                      size: 34 * scaleFactor,
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
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Edit Selected Audio",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatFileName(_selectedFileName, maxLength: 25),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / 812.0;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Colors.black, size: 24 * scaleFactor),
          onPressed: () {
            _stopAllAudio();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Set Ringtone",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18 * scaleFactor * textScaleFactor,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2 * scaleFactorHeight),
            Text(
              'Create custom ringtones',
              style: TextStyle(
                  fontSize: 13 * scaleFactor * textScaleFactor,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.black, size: 24 * scaleFactor),
        actions: [
          if (_ringtoneSetSuccessfully)
            IconButton(
              icon:
              Icon(Icons.home, color: Colors.black, size: 24 * scaleFactor),
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
                    scaleFactor: scaleFactor,
                    textScaleFactor: textScaleFactor,
                    onSearchQueryChanged: (value) {
                      if (mounted) {
                        _stopAllAudio();
                        setState(() {
                          _searchQuery = value.toLowerCase();
                          _selectedFile = null;
                          _selectedFileName = null;
                          log('Search query updated: $_searchQuery');
                        });
                      }
                    },
                    hintText: 'Search audio files...',
                  ),
                ),
                SliverToBoxAdapter(
                  child: buildGenericFilterTabs(
                    scaleFactor: scaleFactor,
                    scaleFactorHeight: scaleFactorHeight,
                    textScaleFactor: textScaleFactor,
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
                if (_selectedFile != null) _buildSelectedItemWidget(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.0 * scaleFactor,
                        vertical: 16.0 * scaleFactorHeight),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedFile == null
                            ? 'Select an Audio File'
                            : 'Audio Files',
                        style: TextStyle(
                          fontSize: 14 * scaleFactor * textScaleFactor,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildRingtoneList(
                    scaleFactor, scaleFactorHeight, textScaleFactor),
              ],
            ),
          ),
          if (_selectedFile != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16 * scaleFactor),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10 * scaleFactor,
                    offset: Offset(0, -5 * scaleFactorHeight),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                  EdgeInsets.symmetric(vertical: 12 * scaleFactorHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                  ),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _processAndSetRingtone,
                icon: _isProcessing
                    ? SizedBox(
                    width: 20 * scaleFactor,
                    height: 20 * scaleFactor,
                    child: CircularProgressIndicator(
                        strokeWidth: 2 * scaleFactor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white)))
                    : Icon(Icons.notifications_active, size: 24 * scaleFactor),
                label: Text(
                  _isProcessing ? "Processing..." : "Set as Ringtone",
                  style: TextStyle(
                    fontSize: 16 * scaleFactor * textScaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}