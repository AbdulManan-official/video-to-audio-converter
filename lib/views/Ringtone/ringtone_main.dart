import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ringtone_set_mul/ringtone_set_mul.dart';
import 'package:video_to_audio_converter/utils/prefs.dart';
import 'package:video_to_audio_converter/utils/resources.dart';
import 'package:video_to_audio_converter/utils/utils.dart';

import '../../controllers/merge_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/video_controller.dart';

class SetRingtonePage extends StatefulWidget {
  const SetRingtonePage({super.key});

  @override
  _SetRingtonePageState createState() => _SetRingtonePageState();
}

class _SetRingtonePageState extends State<SetRingtonePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        title: const Text(
          "Set Ringtone",
          style: TextStyle(color: Colors.white),
        ),
        // bottom: TabBar(
        //   labelColor: Colors.white,
        //   unselectedLabelColor: Colors.grey,
        //   controller: _tabController,
        //   tabs: const [
        //     Tab(
        //       text: "SONGS",
        //     ),
        //     Tab(text: "OTHERS"),
        //   ],
        // ),
      ),
      body: const Center(child: SetRingtoneButtonWidget()),

      //  TabBarView(
      //   controller: _tabController,
      //   children: const [
      //     // SongsTab(),
      //     Center(child: SetRingtoneButtonWidget()),
      //     Center(child: Text("Others Content")),
      //   ],
      // ),
    );
  }
}

class SetRingtoneButtonWidget extends StatefulWidget {
  const SetRingtoneButtonWidget({super.key});

  @override
  State<SetRingtoneButtonWidget> createState() =>
      _SetRingtoneButtonWidgetState();
}

class _SetRingtoneButtonWidgetState extends State<SetRingtoneButtonWidget>
    with RouteAware {
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  var setRingtone = false;
  var setRingtoneString = '';

  @override
  void initState() {
    setRingtone = Prefs.getBool('rintone_set') ?? false;
    setRingtoneString = Prefs.getString('ringtone_string') ?? '';
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setRingtone = Prefs.getBool('rintone_set') ?? false;
    setRingtoneString = Prefs.getString('ringtone_string') ?? '';
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ////set ringtone ui section
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                height: 200,
                width: 250,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    setRingtone == true
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${setRingtoneString.length >= 12 ? setRingtoneString.substring(0, 12) : setRingtoneString}...',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              InkWell(
                                onTap: () {
                                  Get.to(() => const SongsTab(),
                                      transition: Transition.fade);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.white),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.change_circle_rounded,
                                        color: primaryColor,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        'Change',
                                        style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ).paddingAll(10),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () {
                              Get.to(() => const SongsTab(),
                                  transition: Transition.fade);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.white),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1,
                                    color: primaryColor,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Set Ringtone',
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ).paddingAll(10),
                            ),
                          )
                  ],
                ).paddingOnly(bottom: 18),
              ).paddingOnly(top: 50),
              Image.asset(
                'assets/images/phone.png',
                height: 120,
                width: 150,
                fit: BoxFit.contain,
                // color: Colors.transparent,
              ),
            ],
          ),

          const SizedBox(height: 20),

          ///special contacts
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Special Contacts",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Select your preferred content to set as your ringtone according to your personal preference",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ).paddingSymmetric(horizontal: 15.0),
        ],
      ),
    );
  }
}

class SongsTab extends StatefulWidget {
  const SongsTab({super.key});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> fileSizes = {};
  Map<String, Duration> fileDurations = {};
  final MergeAudioController mergeController = Get.put(MergeAudioController());
  final VideoController videoController = Get.put(VideoController());
  List<File> videoMusicFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    mergeController.fetchMp3Files();
    fetchFiles(
        directoryPath: '/storage/emulated/0/Music/VideoMusic',
        targetList: videoMusicFiles);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch files from a given directory
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
        videoMusicFiles.addAll(files);
      });

      // Load file size and duration for each file
      for (File file in files) {
        String fileName = file.path.split('/').last;
        await _loadFileInfo(file, fileName);
      }
    }
  }

  // Load file size and duration for a given MP3 file
  Future<void> _loadFileInfo(File file, String fileName) async {
    int bytes = await file.length();
    fileSizes[fileName] = _formatBytes(bytes);

    // Load audio duration using just_audio
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.setFilePath(file.path);
    Duration? duration = audioPlayer.duration;
    if (duration != null) {
      fileDurations[fileName] = duration;
    }
    audioPlayer.dispose();

    setState(() {});
  }

  // Format bytes to KB, MB, etc.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        title: const Text(
          "Set Ringtone",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          controller: _tabController,
          tabs: const [
            Tab(
              text: "Converted Audios",
            ),
            Tab(text: "Local Music"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          videoMusicFiles.isEmpty
              ? const Center(child: Text("Empty Files"))
              : ListView.builder(
                  itemCount: videoMusicFiles.length,
                  itemBuilder: (context, index) {
                    File mp3File = videoMusicFiles[index];
                    String fileName = mp3File.path.split('/').last;

                    double fileSize =
                        videoController.getFileSizeInMB(mp3File.path);
                    // String duration = mergeController.fileDurations[fileName]
                    //         ?.toString()
                    //         .split('.')
                    //         .first ??
                    //     'Loading...';

                    return ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple, Colors.blue],
                          ),
                        ),
                        child:
                            const Icon(Icons.music_note, color: Colors.white),
                      ),
                      title: Text(fileName, maxLines: 1),
                      subtitle: Text(" $fileSize MB"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        onPressed: () {
                          _showRingtoneOptions(context, fileName, mp3File);
                        },
                        child: const Text(
                          "Set",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
          // SongsTab(),
          Obx(
            () => ListView.builder(
              itemCount: mergeController.mp3Files.length,
              itemBuilder: (context, index) {
                File mp3File = mergeController.mp3Files[index];
                String fileName = mp3File.path.split('/').last;

                double fileSize = videoController.getFileSizeInMB(mp3File.path);
                // String duration = mergeController.fileDurations[fileName]
                //         ?.toString()
                //         .split('.')
                //         .first ??
                //     'Loading...';

                return ListTile(
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.blue],
                      ),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                  title: Text(fileName, maxLines: 1),
                  subtitle: Text(" $fileSize MB"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: () {
                      _showRingtoneOptions(context, fileName, mp3File);
                    },
                    child: const Text(
                      "Set",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRingtoneOptions(
    BuildContext context,
    String songTitle,
    File file,
  ) {
    showModalBottomSheet(
      backgroundColor: Colors.deepPurple,
      showDragHandle: true,
      context: context,
      builder: (context) {
        return Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // const Text(
                  //   "Set Ringtone",
                  //   style: TextStyle(
                  //       fontSize: 18,
                  //       fontWeight: FontWeight.bold,
                  //       color: Colors.white),
                  // ),
                  Container(
                    width: 120,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.blue],
                      ),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Text(
                    songTitle,
                    maxLines: 1,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  InkWell(
                    onTap: () async {
                      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                      AndroidDeviceInfo androidInfo =
                          await deviceInfo.androidInfo;
                      int sdkInt = androidInfo.version.sdkInt;

                      if ((sdkInt) >= 29) {
                        RingtoneSetter.setRingtone(file.path).then(
                          (value) {
                            // log(true.toString());
                            Prefs.setBool('rintone_set', true);
                            Prefs.setString('ringtone_string', songTitle);
                            toastFlutter(
                                toastmessage: '$songTitle ringtone set',
                                color: Colors.green[700]);
                            Get.back();
                          },
                        );
                      } else {
                        RingtoneSet.setRingtoneFromFile(file).then(
                          (value) {
                            log(true.toString());
                            Prefs.setBool('rintone_set', true);
                            Prefs.setString('ringtone_string', songTitle);

                            toastFlutter(
                                toastmessage: '$songTitle ringtone set',
                                color: Colors.green[700]);
                            Get.back();
                          },
                        );
                      }
                    },
                    child: Container(
                      width: 180,
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(12))),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_in_talk_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            "Set as it is",
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ).paddingAll(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
