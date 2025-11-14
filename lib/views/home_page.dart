
//responsive done

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:video_to_audio_converter/main.dart';
import '../controllers/controllers.dart';
import '../controllers/video_controller.dart';
import 'Formate Converter/fromate_converter.dart';
import 'Merge_Audio/merge_audio_main.dart';
import 'Ringtone/ringtone_main.dart';
import 'videos_screen.dart';


// --- Enhanced Animation Widgets ---
// 1. InteractiveCard with Ripple Effect
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color baseColor;
  final double scaleFactor;
  final Duration animationDuration;
  final double? minHeight; // Add this line

  const InteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.baseColor,
    this.scaleFactor = 0.96,
    this.animationDuration = const Duration(milliseconds: 120),
    this.minHeight, // Add this line
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _colorAnimation = ColorTween(
      begin: widget.baseColor,
      end: widget.baseColor.withOpacity(0.85),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) async {
    await _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              // Changed: Use constraints instead of fixed height
              constraints: BoxConstraints(
                minHeight: widget.minHeight ?? 140,
              ),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.baseColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}


// 2. PressScaleBox
class PressScaleBox extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final Duration animationDuration;

  const PressScaleBox({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.98,
    this.animationDuration = const Duration(milliseconds: 120),
  });

  @override
  State<PressScaleBox> createState() => _PressScaleBoxState();
}

class _PressScaleBoxState extends State<PressScaleBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) async {
    await _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// 3. Staggered Animation Card - For Feature Cards
class StaggeredCard extends StatelessWidget {
  final Widget child;
  final int index;
  final Animation<double> animation;

  const StaggeredCard({
    super.key,
    required this.child,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.1;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(
            delay,
            delay + 0.3,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(
              delay,
              delay + 0.3,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ConversionController controller = Get.put(ConversionController());
  final videcontroller = Get.put(VideoController());
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12)
        .animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _staggerController.forward();
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
    _fadeController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    const Color startColor = Color(0xFF4A7EFF);
    const Color endColor = Color(0xFF8A2BE2);

    return Container(
      height: 110 * scaleFactorHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.only(left: 35 * scaleFactor,
          right: 20 * scaleFactor,
          top: 30 * scaleFactorHeight,
          bottom: 8 * scaleFactorHeight),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: Colors.white,
                  size: 25 * scaleFactor,
                ),
                SizedBox(width: 12 * scaleFactor),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audio Converter',
                        style: TextStyle(
                          fontSize: 21 * scaleFactor * textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Professional audio tools',
                        style: TextStyle(
                          fontSize: 11 * scaleFactor * textScaleFactor,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    const double overlapHeight = 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Transform.translate(
                offset: Offset(0.0, -overlapHeight * scaleFactorHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        child: _buildHeroCard(
                            scaleFactor, scaleFactorHeight, textScaleFactor),
                      ),

                      SizedBox(height: 20 * scaleFactorHeight),

                      Text(
                        'More Tools',
                        style: TextStyle(
                          fontSize: 18 * scaleFactor * textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: 16 * scaleFactorHeight),

                      // First Row with Staggered Animation
                      Row(
                        children: [
                          Expanded(
                            child: StaggeredCard(
                              index: 0,
                              animation: _staggerController,
                              child: _buildFeatureCard(
                                title: 'My Library',
                                subtitle: 'View converted files',
                                icon: Icons.folder_open_rounded,
                                color: const Color(0xff0498e1),
                                scaleFactor: scaleFactor,
                                scaleFactorHeight: scaleFactorHeight,
                                textScaleFactor: textScaleFactor,
                                onTap: () {
                                  Get.to(() => const OutputScreen(),
                                      transition: Transition.fadeIn);
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scaleFactor),
                          Expanded(
                            child: StaggeredCard(
                              index: 1,
                              animation: _staggerController,
                              child: _buildFeatureCard(
                                title: 'Merge Audio',
                                subtitle: 'Combine multiple files',
                                icon: Icons.merge_outlined,
                                color: const Color(0xFF7736DE),
                                scaleFactor: scaleFactor,
                                scaleFactorHeight: scaleFactorHeight,
                                textScaleFactor: textScaleFactor,
                                onTap: () {
                                  Get.to(() => const MergeAudioScreen(),
                                      transition: Transition.fadeIn);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10 * scaleFactorHeight),

                      // Second Row with Staggered Animation
                      Row(
                        children: [
                          Expanded(
                            child: StaggeredCard(
                              index: 2,
                              animation: _staggerController,
                              child: _buildFeatureCard(
                                title: 'Convert Format',
                                subtitle: 'Change audio format',
                                icon: Icons.audio_file_outlined,
                                color: const Color(0xFF3BBEA6),
                                scaleFactor: scaleFactor,
                                scaleFactorHeight: scaleFactorHeight,
                                textScaleFactor: textScaleFactor,
                                onTap: () {
                                  Get.to(() => const FormateMain(),
                                      transition: Transition.fadeIn);
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scaleFactor),
                          Expanded(
                            child: StaggeredCard(
                              index: 3,
                              animation: _staggerController,
                              child: _buildFeatureCard(
                                title: 'Set Ringtone',
                                subtitle: 'Custom Ringtones',
                                icon: Icons.notifications_outlined,
                                color: const Color(0xFFE68A00),
                                scaleFactor: scaleFactor,
                                scaleFactorHeight: scaleFactorHeight,
                                textScaleFactor: textScaleFactor,
                                onTap: () {
                                  Get.to(() => const SetRingtonePage(),
                                      transition: Transition.fadeIn);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20 * scaleFactorHeight),
                    ],
                  ),
                ),
              ),

              SizedBox(height: overlapHeight * scaleFactorHeight),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isAdLoaded
          ? SafeArea(
        child: Container(
          margin: EdgeInsets.all(8 * scaleFactor),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10 * scaleFactor,
                offset: Offset(0, -2 * scaleFactorHeight),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            child: SizedBox(
              height: _bannerAd!.size.height.toDouble() * scaleFactorHeight,
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildHeroCard(double scaleFactor, double scaleFactorHeight,
      double textScaleFactor) {
    const Color _primaryColor = Color(0xFF6C63FF);

    return PressScaleBox(
      onTap: () {
        Get.to(() => const VideoView(), transition: Transition.fadeIn);
      },
      scaleFactor: 0.98,
      child: Container(
        height: 185 * scaleFactorHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: 20 * scaleFactor,
              offset: Offset(0, 10 * scaleFactorHeight),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(24 * scaleFactor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10 * scaleFactor,
                            vertical: 4 * scaleFactorHeight),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(20 * scaleFactor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3 * scaleFactor,
                                backgroundColor: Colors.white),
                            SizedBox(width: 8 * scaleFactor),
                            Text(
                              'Quick Convert',
                              style: TextStyle(
                                fontSize: 14 * scaleFactor * textScaleFactor,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 22 * scaleFactorHeight),
                  Text(
                    'Video to Audio',
                    style: TextStyle(
                      fontSize: 25 * scaleFactor * textScaleFactor,
                      fontWeight: FontWeight.w900,
                      color: _primaryColor,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6 * scaleFactorHeight),
                  Text(
                    'Tap to get started',
                    style: TextStyle(
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 25 * scaleFactor,
              top: 0,
              bottom: 0,
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 60 * scaleFactor,
                    height: 60 * scaleFactor,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _primaryColor.withOpacity(0.4)),
                      color: _primaryColor.withOpacity(1),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 45 * scaleFactor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double scaleFactor,
    required double scaleFactorHeight,
    required double textScaleFactor,
  }) {
    return InteractiveCard(
      onTap: onTap,
      baseColor: color,
      minHeight: 140 * scaleFactorHeight, // Add this parameter
      child: Padding(
        padding: EdgeInsets.all(16.0 * scaleFactor),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Changed from mainAxisAlignment
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon at top
            Container(
              width: 48 * scaleFactor,
              height: 48 * scaleFactor,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28 * scaleFactor,
                ),
              ),
            ),

            SizedBox(height: 12 * scaleFactorHeight), // Add spacing

            // Title - expandable
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.visible, // Changed from ellipsis
              style: TextStyle(
                fontSize: 15 * scaleFactor * textScaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),

            SizedBox(height: 4 * scaleFactorHeight),

            // Subtitle - expandable
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.visible, // Changed from ellipsis
              style: TextStyle(
                fontSize: 11 * scaleFactor * textScaleFactor,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}