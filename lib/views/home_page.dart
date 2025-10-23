import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import for ads
import 'package:video_to_audio_converter/main.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import '../controllers/controllers.dart';
import '../controllers/video_controller.dart';
import 'Formate Converter/fromate_converter.dart';
import 'Merge_Audio/merge_audio_main.dart';
import 'Ringtone/ringtone_main.dart';
import 'videos_screen.dart';

class HomeScreen extends StatefulWidget { // Change to StatefulWidget for ad loading
  HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ConversionController controller = Get.put(ConversionController());
  final videcontroller = Get.put(VideoController());

  BannerAd? _bannerAd; // Store the banner ad
  bool _isAdLoaded = false; // Track ad loading status

  @override
  void initState() {
    super.initState();
    _loadBannerAd(); // Load the banner ad when the widget initializes
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test banner ad unit ID
      size: AdSize.banner, // Standard banner size (320x50)
      request: const AdRequest(), // Ad request
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true; // Update state when ad is loaded
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose(); // Dispose ad on failure
        },
      ),
    );
    _bannerAd!.load(); // Load the ad
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Dispose the ad when the widget is destroyed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/video.png',
              height: 25,
              fit: BoxFit.cover,
            ),
            const SizedBox(
              width: 15,
            ),
            const Text(
              'Video to Audio Converter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            )
          ],
        ),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.settings))
        ],
      ),
      body: ListView(
        children: [
          /// Video to Audio Converter
          InkWell(
            onTap: () {
              Get.to(() => const VideoView(), transition: Transition.fade);
            },
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(20)),
              child: Stack(
                children: [
                  const Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Video to Audio ',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.arrow_circle_right_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                    ],
                  ).paddingOnly(left: 20, top: 24),
                  Align(
                      alignment: Alignment.topRight,
                      child: Image.asset('assets/images/icon-3.png'))
                ],
              ),
            ).paddingAll(16),
          ),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Get.to(() => const OutputScreen(),
                        transition: Transition.fade);
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Output',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Get.to(() => const MergeAudioScreen(),
                        transition: Transition.fade);
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.merge,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Merge Audio',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: 16).paddingOnly(top: 15),

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Get.to(() => const FormateMain(),
                        transition: Transition.fade);
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.loop,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Format Converter',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Get.to(() => const SetRingtonePage(),
                        transition: Transition.fade);
                  },
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 40,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Set Ringtone',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: 16).paddingOnly(top: 15),
        ],
      ),
      // Add the banner ad at the bottom of the screen
      bottomNavigationBar: _isAdLoaded
          ? SafeArea(
            child: SizedBox(
                    height: _bannerAd!.size.height.toDouble(), // Match ad height
                    child: AdWidget(ad: _bannerAd!), // Display the ad
                  ).paddingOnly(bottom: 10),
          )
          : const SizedBox.shrink(), // Show nothing until ad loads
    );
  }
}

Widget buildOptionCard(
    BuildContext context, {
      required String title,
      required IconData icon,
      required VoidCallback onTap,
    }) {
  return Card(
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 5),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    ),
  );
}

class VoiceChangeScreen extends StatelessWidget {
  const VoiceChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voice Change")),
      body: const Center(child: Text("Voice Change Screen")),
    );
  }
}