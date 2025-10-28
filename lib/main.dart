// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_to_audio_converter/utils/prefs.dart';
import 'utils/utils.dart';
import 'views/audio_player.dart';
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Initialize plugins safely
  await _initializePlugins();

  // 2️⃣ Launch the app
  runApp(const MyApp());
}

/// Initialize all required plugins safely
Future<void> _initializePlugins() async {
  // Mobile Ads (Android & iOS)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await MobileAds.instance.initialize();
      print('✅ Mobile Ads initialized');
    } catch (e) {
      print('⚠️ Mobile Ads initialization failed: $e');
    }
  }

  // Flutter Downloader (Android & iOS)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await FlutterDownloader.initialize(debug: true); // false for production
      print('✅ Flutter Downloader initialized');
    } catch (e) {
      print('⚠️ Flutter Downloader initialization failed: $e');
    }
  }

  // Permissions (Android only)
  if (Platform.isAndroid) {
    await _requestPermissions();
  }

  // Shared Preferences
  await Prefs.init();
}

/// Request necessary storage/audio/video permissions (Android only)
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
          centerTitle: true, // ✅ centers all AppBar titles
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // ✅ makes it bold
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),


        // Background & Text
        // scaffoldBackgroundColor: Color(0xFFF2F2F2), // Softer background
        textTheme: GoogleFonts.poppinsTextTheme(),

        // BottomSheet Theme
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          dragHandleColor: Colors.grey,
        ),
      ),
      home: HomeScreen(),
    );

  }
}

// ------------------- OUTPUT SCREEN -------------------
class OutputScreen extends StatefulWidget {
  const OutputScreen({super.key});

  @override
  _OutputScreenState createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen>
    with SingleTickerProviderStateMixin {
  List<File> videoMusicFiles = [];
  List<File> mergedAudioFiles = [];
  List<File> formatConverterAudioFiles = [];
  Map<String, String> fileSizes = {};
  Map<String, Duration> fileDurations = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  Future<void> fetchFiles(
      {required String directoryPath, required List<File> targetList}) async {
    Directory dir = Directory(directoryPath);
    if (await dir.exists()) {
      List<File> files = dir
          .listSync()
          .where((item) => !item.path.contains(".pending-"))
          .map((item) => File(item.path))
          .toList();

      setState(() {
        targetList.addAll(files);
      });

      for (File file in files) {
        String fileName = file.path.split('/').last;
        await _loadFileInfo(file, fileName);
      }
    }
  }

  Future<void> _loadFileInfo(File file, String fileName) async {
    int bytes = await file.length();
    fileSizes[fileName] = _formatBytes(bytes);

    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.setFilePath(file.path);
    Duration? duration = audioPlayer.duration;
    if (duration != null) {
      fileDurations[fileName] = duration;
    }
    audioPlayer.dispose();

    setState(() {});
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

  Widget _buildFileList({required List<File> files, Directory? directory}) {
    return files.isEmpty
        ? const Center(child: Text('No files found.'))
        : ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        File file = files[index];
        String fileName = file.path.split('/').last;

        String fileSize = fileSizes[fileName] ?? 'Calculating...';
        String duration =
            fileDurations[fileName]?.toString().split('.').first ??
                'Loading...';

        return ListTile(
          leading: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.blue],
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white)
                .paddingAll(20),
          ),
          title: Text(
            fileName,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Size: $fileSize\nDuration: $duration'),
          onTap: () {
            Get.to(
                    () => MusicPlayerScreen(
                    audiopath: file.path,
                    fileName: fileName,
                    directory: directory),
                transition: Transition.fade);
          },
        ).paddingOnly(top: 10);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'OutPut Folder',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,           // active tab indicator
          labelColor: Colors.black,               // active tab text
          unselectedLabelColor: Colors.white,     // inactive tab text
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w500,          // bold active tab
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,          // slightly less bold inactive tab
            fontSize: 16,
          ),

            tabs: const [
              Tab(text: "Audios"),
              Tab(text: "Merged "),
              Tab(text: "Converted"),
            ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFileList(
              files: videoMusicFiles,
              directory: Directory('/storage/emulated/0/Music/VideoMusic')),
          _buildFileList(
              files: mergedAudioFiles,
              directory: Directory('/storage/emulated/0/Music/MergedAudio')),
          _buildFileList(
              files: formatConverterAudioFiles,
              directory:
              Directory('/storage/emulated/0/Music/Format Converter')),
        ],
      ),
    );
  }
}
