import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:video_to_audio_converter/main.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import '../controllers/controllers.dart';
import '../controllers/video_controller.dart';
import 'Formate Converter/fromate_converter.dart';
import 'Merge_Audio/merge_audio_main.dart';
import 'Ringtone/ringtone_main.dart';
import 'videos_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ConversionController controller = Get.put(ConversionController());
  final videcontroller = Get.put(VideoController());

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/video.png',
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Video to Audio Converter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        // **REMOVED ListView, replaced with Padding and Column**
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card - Video to Audio Converter
              _buildHeroCard(),

              const SizedBox(height: 24),

              // Section Title
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // First Row of Cards
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Output',
                      icon: Icons.folder_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B9AFF), Color(0xFF4A7EFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Get.to(() => const OutputScreen(),
                            transition: Transition.fadeIn);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Merge Audio',
                      icon: Icons.audio_file_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9A6B), Color(0xFFFF7A4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Get.to(() => const MergeAudioScreen(),
                            transition: Transition.fadeIn);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Second Row of Cards
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Format Converter',
                      icon: Icons.swap_horiz_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B6BFF), Color(0xFF7A4AFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Get.to(() => const FormateMain(),
                            transition: Transition.fadeIn);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFeatureCard(
                      title: 'Set Ringtone',
                      icon: Icons.notifications_active_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6BFFB4), Color(0xFF4AFFAA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        Get.to(() => const SetRingtonePage(),
                            transition: Transition.fadeIn);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // If the layout still overflows on small screens, you can wrap the content (from _buildHeroCard down) in an Expanded widget
              // and wrap the entire Column in a Flexible widget, but since you are aiming for no scroll,
              // this current structure is the correct non-scrolling solution for this content size.
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isAdLoaded
          ? SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildHeroCard() {
    return InkWell(
      onTap: () {
        Get.to(() => const VideoView(), transition: Transition.fadeIn);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              secondaryColor,
              secondaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.video_library_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          // Reduced font size from 24 to 23 for a bit more safety
                          'Video to Audio',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Reduced spacing from 12 to 10
                  Text(
                    'Convert your videos to audio files', // Slightly shortened text
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start Converting',
                          style: TextStyle(
                            color: secondaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: secondaryColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
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