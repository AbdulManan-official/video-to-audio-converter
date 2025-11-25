import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_to_audio_converter/utils/prefs.dart';
import 'views/home_page.dart';
import 'package:share_plus/share_plus.dart';
import './utils/waveform_audio_utils.dart';
import 'dart:developer';
// import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';



const Color secondaryColor = Color(0xFF6C63FF);

String trimFileName(String name) {
  if (name.length <= 14) return name;
  return name.substring(0, 14) + "...";
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializePlugins();
  await clearOldFilesOnFirstLaunch();

  runApp(const MyApp());
}


Future<void> _initializePlugins() async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await MobileAds.instance.initialize();
      print('✅ Mobile Ads initialized');
    } catch (e) {
      print('⚠️ Mobile Ads initialization failed: $e');
    }
  }

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await FlutterDownloader.initialize(debug: true);
      print('✅ Flutter Downloader initialized');
    } catch (e) {
      print('⚠️ Flutter Downloader initialization failed: $e');
    }
  }

  if (Platform.isAndroid) {
    await _requestPermissions();
  }

  await Prefs.init();
}

Future<void> _requestPermissions() async {
  List<Permission> permissions = [Permission.storage];

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  int sdkInt = androidInfo.version.sdkInt;

  if (sdkInt >= 30) {
    permissions.add(Permission.audio);
    permissions.add(Permission.videos);
  }

  await permissions.request();
  log('Permissions requested. SDK: $sdkInt');
}

Future<void> clearOldFilesOnFirstLaunch() async {
  final prefs = await SharedPreferences.getInstance();
  bool firstLaunch = prefs.getBool('first_launch') ?? true;

  if (!firstLaunch) return;

  if (await Permission.storage.request().isGranted) {
    final List<String> dirsToClear = [
      '/storage/emulated/0/Music/VideoMusic',
      '/storage/emulated/0/Music/MergedAudio',
      '/storage/emulated/0/Music/Format Converter',
      '/storage/emulated/0/Download/Converted_Audios',
    ];

    for (var path in dirsToClear) {
      final dir = Directory(path);
      if (await dir.exists()) {
        for (var file in dir.listSync()) {
          try {
            await File(file.path).delete();
            print('Deleted: ${file.path}');
          } catch (e) {
            print('Failed to delete ${file.path}: $e');
          }
        }
      }
    }

    print('✅ Old files cleared from all directories');
  } else {
    print('⚠️ Storage permission not granted');
  }

  await prefs.setBool('first_launch', false);
}

Future<void> _deleteDirectoryContents(Directory dir) async {
  await for (FileSystemEntity entity in dir.list(recursive: true, followLinks: false)) {
    try {
      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }
    } catch (e) {
      print('Failed to delete ${entity.path}: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video to Audio Converter',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: secondaryColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: secondaryColor,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          dragHandleColor: Colors.grey,
        ),
      ),

      /// System font scaling disabled (safe to keep)
      builder: (context, child) {
        final mq = MediaQuery.of(context);

        return MediaQuery(
          data: mq.copyWith(textScaleFactor: 1.0), // Prevent system font changes
          child: child!,
        );
      },

      home: const HomeScreen(),
    );
  }
}


class OutputScreen extends StatefulWidget {
  const OutputScreen({super.key});

  @override
  _OutputScreenState createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  List<File> videoMusicFiles = [];
  List<File> mergedAudioFiles = [];
  List<File> formatConverterAudioFiles = [];
  Map<String, String> fileSizes = {};
  Map<String, Duration> fileDurations = {};
  int _selectedTabIndex = 0;
  String _searchQuery = '';

  final WaveformAudioManager _audioManager = WaveformAudioManager();
  String? _playingFile;

  bool _isSelectionMode = false;
  Set<String> _selectedFiles = {};

  @override
  void initState() {
    super.initState();
    fetchFiles(
        directoryPath: '/storage/emulated/0/Music/VideoMusic',
        targetList: videoMusicFiles);
    fetchFiles(
        directoryPath: '/storage/emulated/0/Music/MergedAudio',
        targetList: mergedAudioFiles);
    fetchFiles(
        directoryPath: '/storage/emulated/0/Music/Format Converter',
        targetList: formatConverterAudioFiles);
  }

  @override
  void dispose() {
    _audioManager.disposeAll();
    super.dispose();
  }

  Future<void> fetchFiles(
      {required String directoryPath, required List<File> targetList}) async {
    Directory dir = Directory(directoryPath);
    if (await dir.exists()) {
      List<File> files = dir
          .listSync()
          .where((item) => !item.path.contains(".pending-"))
          .map((item) => File(item.path))
          .toList();

      // ✅ Sort by modification time (newest first)
      try {
        files.sort((a, b) {
          try {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          } catch (e) {
            return 0;
          }
        });
      } catch (e) {
        log('OutputScreen: Sorting failed for $directoryPath: $e');
      }

      setState(() {
        targetList.addAll(files);
      });

      log('OutputScreen: Found ${files.length} files in $directoryPath');

      for (File file in files) {
        String fileName = file.path.split('/').last;
        await _loadFileInfo(file, fileName);
      }
    } else {
      log('OutputScreen: Directory not found: $directoryPath');
    }
  }

  Future<void> _loadFileInfo(File file, String fileName) async {
    int bytes = await file.length();
    fileSizes[fileName] = _formatBytes(bytes);

    String? savedDurationString = Prefs.getString(fileName);

    if (savedDurationString != null && savedDurationString.isNotEmpty) {
      try {
        int totalSeconds = int.parse(savedDurationString);
        fileDurations[fileName] = Duration(seconds: totalSeconds);
        log('OutputScreen: Loaded duration for $fileName from Prefs.');
        setState(() {});
        return;
      } catch (e) {
        log('OutputScreen: Failed to parse saved duration for $fileName: $e. Recalculating.');
      }
    }

    log('OutputScreen: Calculating duration for $fileName using AudioPlayer (Slow).');
    AudioPlayer audioPlayer = AudioPlayer();
    try {
      await audioPlayer.setFilePath(file.path);
      Duration? duration = audioPlayer.duration;
      if (duration != null) {
        fileDurations[fileName] = duration;
        await Prefs.setString(fileName, duration.inSeconds.toString());
        log('OutputScreen: Saved duration for $fileName to Prefs.');
      } else {
        fileDurations[fileName] = Duration.zero;
      }
    } catch (e) {
      log('OutputScreen: Error loading duration for $fileName: $e');
      fileDurations[fileName] = Duration.zero;
    } finally {
      audioPlayer.dispose();
    }

    setState(() {});
  }

  String _formatBytes(int bytes, [int decimals = 1]) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  int _getTotalFiles() {
    if (_selectedTabIndex == 0) {
      return videoMusicFiles.length +
          mergedAudioFiles.length +
          formatConverterAudioFiles.length;
    } else if (_selectedTabIndex == 1) {
      return videoMusicFiles.length;
    } else if (_selectedTabIndex == 2) {
      return mergedAudioFiles.length;
    } else {
      return formatConverterAudioFiles.length;
    }
  }

  List<File> _getFilteredFiles(List<File> files) {
    if (_searchQuery.isEmpty) return files;
    return files.where((file) {
      String fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<File> _getAllFiles() {
    return [...videoMusicFiles, ...mergedAudioFiles, ...formatConverterAudioFiles];
  }

  List<File> _getCurrentFiles() {
    List<File> files;

    if (_selectedTabIndex == 0) {
      files = _getAllFiles();

      // ✅ Re-sort combined list (newest first)
      try {
        files.sort((a, b) {
          try {
            return b.lastModifiedSync().compareTo(a.lastModifiedSync());
          } catch (e) {
            return 0;
          }
        });
      } catch (e) {
        log('OutputScreen: Sorting failed for combined files: $e');
      }
    } else if (_selectedTabIndex == 1) {
      files = videoMusicFiles;
    } else if (_selectedTabIndex == 2) {
      files = mergedAudioFiles;
    } else {
      files = formatConverterAudioFiles;
    }

    return files;
  }
  Directory? _getCurrentDirectory() {
    if (_selectedTabIndex == 1) {
      return Directory('/storage/emulated/0/Music/VideoMusic');
    } else if (_selectedTabIndex == 2) {
      return Directory('/storage/emulated/0/Music/MergedAudio');
    } else if (_selectedTabIndex == 3) {
      return Directory('/storage/emulated/0/Music/Format Converter');
    }
    return null;
  }

  Future<void> _togglePlayPause(String filePath, String fileName) async {
    await _audioManager.togglePlayPause(
      fileName,
      filePath,
          (playing) {
        setState(() {
          _playingFile = playing;
          log('OutputScreen: State updated. New playing file: $_playingFile');
        });
      },
    );
  }

  void _toggleFileSelection(String fileName) {
    setState(() {
      if (_selectedFiles.contains(fileName)) {
        _selectedFiles.remove(fileName);
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFiles.add(fileName);
        _isSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(String fileName) {
    setState(() {
      _isSelectionMode = true;
      _selectedFiles.add(fileName);
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });
  }

  void _showDeleteMultipleConfirmation() {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scaleFactor),
        ),
        contentPadding: EdgeInsets.all(20 * scaleFactor),
        title: Text(
          'Delete Files',
          style: TextStyle(
            fontSize: 18 * scaleFactor * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Text(
            'Are you sure you want to delete ${_selectedFiles.length} file(s)? This action cannot be undone.',
            style: TextStyle(fontSize: 15 * scaleFactor * textScaleFactor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSelectedFiles();
            },
            child: Text(
              'DELETE',
              style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedFiles() async {
    int deletedCount = 0;
    List<String> filesToDelete = _selectedFiles.toList();

    for (String fileName in filesToDelete) {
      File? fileToDelete;

      for (var file in _getAllFiles()) {
        if (file.path.split('/').last == fileName) {
          fileToDelete = file;
          break;
        }
      }

      if (fileToDelete != null && await fileToDelete.exists()) {
        try {
          await fileToDelete.delete();
          log('✅ Deleted file: ${fileToDelete.path}');
          deletedCount++;

          setState(() {
            videoMusicFiles.removeWhere((f) => f.path == fileToDelete!.path);
            mergedAudioFiles.removeWhere((f) => f.path == fileToDelete!.path);
            formatConverterAudioFiles.removeWhere((f) => f.path == fileToDelete!.path);
            fileSizes.remove(fileName);
            fileDurations.remove(fileName);
            Prefs.remove(fileName);

            if (_playingFile == fileName) {
              _audioManager.removeFile(fileName);
              _playingFile = null;
            }
          });
        } catch (e) {
          log('❌ Error deleting $fileName: $e');
        }
      }
    }

    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });

    if (deletedCount == 1) {
      _showSuccessOverlay('1 file deleted');
    } else {
      _showSuccessOverlay('$deletedCount files deleted');
    }
  }

  void _showRenameDialog(File file, String oldFileName) {
    String extension = '';
    String baseName = oldFileName;
    int lastDot = oldFileName.lastIndexOf('.');
    if (lastDot != -1) {
      extension = oldFileName.substring(lastDot + 1);
      baseName = oldFileName.substring(0, lastDot);
    }

    TextEditingController _controller = TextEditingController(text: baseName);

    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scaleFactor),
        ),
        contentPadding: EdgeInsets.all(20 * scaleFactor),
        title: Text(
          'Rename File',
          style: TextStyle(
            fontSize: 18 * scaleFactor * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: TextField(
            controller: _controller,
            style: TextStyle(fontSize: 16 * scaleFactor * textScaleFactor),
            decoration: InputDecoration(
              hintText: 'Enter new file name',
              hintStyle: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
            ),
            onPressed: () async {
              String newBaseName = _controller.text.trim();
              if (newBaseName.isEmpty) {
                _showSuccessOverlay('File name cannot be empty');
                return;
              }

              if (newBaseName == baseName) {
                Navigator.pop(context);
                return;
              }

              String newFullName = extension.isEmpty ? newBaseName : '$newBaseName.$extension';
              String newPath = file.parent.path + '/$newFullName';

              try {
                String? oldDuration = Prefs.getString(oldFileName);
                if (oldDuration != null) {
                  await Prefs.setString(newFullName, oldDuration);
                  await Prefs.remove(oldFileName);
                  log('OutputScreen: Transferred duration in Prefs from $oldFileName to $newFullName');
                }

                final newFile = await file.rename(newPath);
                log('✅ File renamed: ${file.path} -> $newPath');

                setState(() {
                  videoMusicFiles = videoMusicFiles.map((f) => f.path == file.path ? newFile : f).toList();
                  mergedAudioFiles = mergedAudioFiles.map((f) => f.path == file.path ? newFile : f).toList();
                  formatConverterAudioFiles = formatConverterAudioFiles.map((f) => f.path == file.path ? newFile : f).toList();

                  fileSizes.remove(oldFileName);
                  fileDurations.remove(oldFileName);

                  if (_playingFile == oldFileName) {
                    _playingFile = newFullName;
                  }
                });

                await _loadFileInfo(newFile, newFullName);

                Navigator.pop(context);
                _showSuccessOverlay('Renamed to $newFullName');
              } catch (e) {
                log('❌ Rename failed: $e');
                _showSuccessOverlay('Failed to rename file');
              }
            },
            child: Text(
              'RENAME',
              style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
            ),
          ),
        ],
      ),
    );
  }



  void _showSuccessOverlay(String message) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 40 * scaleFactor,
        left: 20 * scaleFactor,
        right: 20 * scaleFactor,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 18 * scaleFactor, vertical: 14 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.25),
                          blurRadius: 12 * scaleFactor,
                          offset: Offset(0, 4 * scaleFactor),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 22 * scaleFactor,
                        ),
                        SizedBox(width: 10 * scaleFactor),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14 * scaleFactor * textScaleFactor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              Future.delayed(const Duration(milliseconds: 1500), () {
                overlayEntry.remove();
              });
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }


  void _showOptionsMenu(BuildContext context, File file, Directory? directory) {
    String fileName = file.path.split('/').last;
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);

    // Calculate menu width based on screen size
    final double menuWidth = 180 * scaleFactor;

    // Ensure menu doesn't go off screen
    final double rightPosition = mediaQuery.size.width - position.dx;
    final double leftPosition = position.dx;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        leftPosition > menuWidth ? position.dx - menuWidth : leftPosition,
        position.dy + (button.size.height),
        rightPosition > menuWidth ? rightPosition : position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * scaleFactor)),
      constraints: BoxConstraints(
        minWidth: 160 * scaleFactor,
        maxWidth: 200 * scaleFactor,
      ),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(file, fileName);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 12 * scaleFactor),
              child: Row(
                children: [
                  Icon(Icons.drive_file_rename_outline, color: const Color(0xFF6C63FF), size: 20 * scaleFactor),
                  SizedBox(width: 12 * scaleFactor),
                  Text('Rename', style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor)),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () async {
              Navigator.pop(context);
              await Share.shareXFiles([XFile(file.path)],
                  text: 'Check out this audio file!');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 12 * scaleFactor),
              child: Row(
                children: [
                  Icon(Icons.share, color: const Color(0xFF6C63FF), size: 20 * scaleFactor),
                  SizedBox(width: 12 * scaleFactor),
                  Text('Share', style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor)),
                ],
              ),
            ),
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, file, directory);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 12 * scaleFactor),
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20 * scaleFactor),
                  SizedBox(width: 12 * scaleFactor),
                  Text('Delete', style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor, color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, File file, Directory? directory) {
    String fileName = file.path.split('/').last;

    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scaleFactor),
        ),
        contentPadding: EdgeInsets.all(20 * scaleFactor),
        title: Text(
          'Delete File',
          style: TextStyle(
            fontSize: 18 * scaleFactor * textScaleFactor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Text(
            'Are you sure you want to delete "$fileName"? This action cannot be undone.',
            style: TextStyle(fontSize: 15 * scaleFactor * textScaleFactor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
            ),
            child: Text(
              'CANCEL',
              style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 20 * scaleFactor,
                vertical: 12 * scaleFactor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final filePath = file.path;
                final fileToDelete = File(filePath);

                if (await fileToDelete.exists()) {
                  await fileToDelete.delete();
                  log('✅ Deleted file from: $filePath');
                } else {
                  log('⚠️ File not found at: $filePath');
                  _showSuccessOverlay('The file "$fileName" does not exist.');
                  return;
                }

                setState(() {
                  videoMusicFiles.removeWhere((f) => f.path == filePath);
                  mergedAudioFiles.removeWhere((f) => f.path == filePath);
                  formatConverterAudioFiles.removeWhere((f) => f.path == filePath);
                  fileSizes.remove(fileName);
                  fileDurations.remove(fileName);
                  Prefs.remove(fileName);

                  if (_playingFile == fileName) {
                    _audioManager.removeFile(fileName);
                    _playingFile = null;
                  }
                });

                String shortName = trimFileName(fileName);
                _showSuccessOverlay('$shortName deleted');
              } catch (e) {
                log('❌ Error deleting $fileName: $e');
                _showSuccessOverlay('Failed to delete $fileName');
              }
            },
            child: Text(
              'DELETE',
              style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = duration.inHours > 0 ? '${duration.inHours}:' : '';
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours$minutes:$seconds';
  }

  List<Widget> _buildFileListItems({required List<File> files, Directory? directory}) {
    List<File> filteredFiles = _getFilteredFiles(files);
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    if (filteredFiles.isEmpty) {
      return [
        SizedBox(
          height: mediaQuery.size.height * 0.4,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_off, size: 64 * scaleFactor, color: Colors.grey[400]),
                SizedBox(height: 16 * scaleFactorHeight),
                Text(
                  _searchQuery.isEmpty ? 'No files found' : 'No matching files',
                  style: TextStyle(fontSize: 16 * scaleFactor * textScaleFactor, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return filteredFiles.map((file) {
      String fileName = file.path.split('/').last;
      String fileSize = fileSizes[fileName] ?? '...';
      String duration = fileDurations[fileName] != null
          ? _formatDuration(fileDurations[fileName]!)
          : '...';
      bool isPlaying = _playingFile == fileName;
      bool isSelected = _selectedFiles.contains(fileName);

      return GestureDetector(
        onLongPress: () {
          if (!_isSelectionMode) {
            _enterSelectionMode(fileName);
          }
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleFileSelection(fileName);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 12 * scaleFactorHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            border: Border.all(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[300]!,
              width: isSelected ? 1.5 * scaleFactor : 1 * scaleFactor,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                    : Colors.black.withOpacity(0.03),
                blurRadius: isSelected ? 12 * scaleFactor : 8 * scaleFactor,
                offset: Offset(0, 2 * scaleFactorHeight),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(12 * scaleFactor),
                child: Row(
                  children: [
                    Container(
                      width: 50 * scaleFactor,
                      height: 50 * scaleFactor,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF6C63FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 28 * scaleFactor,
                      )
                          : Icon(
                        Icons.audio_file,
                        color: Colors.white,
                        size: 28 * scaleFactor,
                      ),
                    ),
                    SizedBox(width: 12 * scaleFactor),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 14 * scaleFactor * textScaleFactor,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4 * scaleFactorHeight),
                          Text(
                            '$fileSize  •  $duration',
                            style: TextStyle(
                              fontSize: 12 * scaleFactor * textScaleFactor,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isSelectionMode)
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: const Color(0xFF6C63FF),
                          size: 32 * scaleFactor,
                        ),
                        onPressed: () => _togglePlayPause(file.path, fileName),
                      ),
                    if (!_isSelectionMode)
                      Builder(
                        builder: (BuildContext buttonContext) {
                          return IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey[700],
                              size: 24 * scaleFactor,
                            ),
                            onPressed: () =>
                                _showOptionsMenu(buttonContext, file, directory),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (isPlaying && !_isSelectionMode)
                Builder(
                  builder: (context) {
                    final controller = _audioManager.getWaveformController(fileName);
                    final amplitudeStream = _audioManager.getAmplitudeStream(fileName);
                    if (controller != null) {
                      return AudioWaveformWidget(
                        controller: controller,
                        amplitudeStream: amplitudeStream,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTabButton(String label, int index, double scaleFactor, double textScaleFactor) {
    bool isActive = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.all(2 * scaleFactor),
        // Added horizontal padding to support scrolling without squishing text
        padding: EdgeInsets.symmetric(vertical: 10 * scaleFactor, horizontal: 16 * scaleFactor),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10 * scaleFactor),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13 * scaleFactor * textScaleFactor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    List<Widget> fileListItems = _buildFileListItems(
      files: _getCurrentFiles(),
      directory: _getCurrentDirectory(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16 * scaleFactor, 16 * scaleFactorHeight, 16 * scaleFactor, 8 * scaleFactorHeight),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isSelectionMode ? Icons.close : Icons.arrow_back,
                      color: Colors.black87,
                      size: 24 * scaleFactor,
                    ),
                    onPressed: () {
                      if (_isSelectionMode) {
                        _cancelSelectionMode();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: 12 * scaleFactor),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSelectionMode
                              ? '${_selectedFiles.length} selected'
                              : 'My Library',
                          style: TextStyle(
                            fontSize: 17 * scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (!_isSelectionMode)
                          Padding(
                            padding: EdgeInsets.only(top: 2 * scaleFactorHeight),
                            child: Text(
                              '${_getTotalFiles()} files',
                              style: TextStyle(
                                fontSize: 13 * scaleFactor * textScaleFactor,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isSelectionMode && _selectedFiles.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 28 * scaleFactor,
                      ),
                      onPressed: _showDeleteMultipleConfirmation,
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 8 * scaleFactorHeight),
                children: [
                  if (!_isSelectionMode)
                    Container(
                      // Search Bar: Responsive logic
                      margin: EdgeInsets.only(bottom: 12 * scaleFactorHeight),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 1 * scaleFactor,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor),
                        decoration: InputDecoration(
                          hintText: 'Search files...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14 * scaleFactor * textScaleFactor),
                          border: InputBorder.none,
                          icon: Padding(
                            padding: EdgeInsets.only(left: 16 * scaleFactor),
                            child: Icon(Icons.search, color: Colors.grey[500], size: 20 * scaleFactor),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10 * scaleFactorHeight),
                        ),
                      ),
                    ),

                  if (!_isSelectionMode)
                    Container(
                      // Filter Bar: Scrollable logic applied here
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 16 * scaleFactorHeight),
                      padding: EdgeInsets.all(4 * scaleFactor),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12 * scaleFactor),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTabButton('All', 0, scaleFactor, textScaleFactor),
                            _buildTabButton('Extracted', 1, scaleFactor, textScaleFactor),
                            _buildTabButton('Merged', 2, scaleFactor, textScaleFactor),
                            _buildTabButton('Converted', 3, scaleFactor, textScaleFactor),
                          ],
                        ),
                      ),
                    ),

                  ...fileListItems,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}