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
  final double? minHeight;

  const InteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.baseColor,
    this.scaleFactor = 0.96,
    this.animationDuration = const Duration(milliseconds: 120),
    this.minHeight,
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
              constraints: BoxConstraints(
                minHeight: widget.minHeight ?? 133,
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
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
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

  Widget _buildHeader(double screenWidth, double screenHeight) {
    const Color startColor = Color(0xFF4A7EFF);
    const Color endColor = Color(0xFF8A2BE2);

    return Container(
      padding: EdgeInsets.only(
        left: screenWidth * 0.09,
        right: screenWidth * 0.053,
        top: screenHeight * 0.021,
        bottom: screenHeight * 0.02,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              color: Colors.white,
              size: screenWidth * 0.067,
            ),
            SizedBox(width: screenWidth * 0.032),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Audio Converter',
                    style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.004),
                  Text(
                    'Professional audio tools',
                    style: TextStyle(
                      fontSize: screenWidth * 0.031,
                      color: Colors.white,
                      height: 1,
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

  @override
  Widget build(BuildContext context) {
    // ✅ GET SCREEN DIMENSIONS - The MediaQuery Way
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(screenWidth, screenHeight),

              // ✅ Hero card overlaps header from below
              Transform.translate(
                offset: Offset(0.0, -screenHeight * 0.015),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.053),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 0),
                        child: _buildHeroCard(screenWidth, screenHeight),
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      Text(
                        'More Tools',
                        style: TextStyle(
                          fontSize: screenWidth * 0.048,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // ✅ First Row - IntrinsicHeight ensures equal heights
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StaggeredCard(
                                index: 0,
                                animation: _staggerController,
                                child: _buildFeatureCard(
                                  title: 'My Library',
                                  subtitle: 'View files',
                                  icon: Icons.folder_open_rounded,
                                  color: const Color(0xff0498e1),
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  onTap: () {
                                    Get.to(() => const OutputScreen(),
                                        transition: Transition.fadeIn);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.027),
                            Expanded(
                              child: StaggeredCard(
                                index: 1,
                                animation: _staggerController,
                                child: _buildFeatureCard(
                                  title: 'Merge Audio',
                                  subtitle: 'Combine files',
                                  icon: Icons.merge_outlined,
                                  color: const Color(0xFF7736DE),
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  onTap: () {
                                    Get.to(() => const MergeAudioScreen(),
                                        transition: Transition.fadeIn);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.012),

                      // ✅ Second Row - IntrinsicHeight ensures equal heights
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StaggeredCard(
                                index: 2,
                                animation: _staggerController,
                                child: _buildFeatureCard(
                                  title: 'Audio format',
                                  subtitle: 'Change Type',
                                  icon: Icons.audio_file_outlined,
                                  color: const Color(0xFF3BBEA6),
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  onTap: () {
                                    Get.to(() => const FormateMain(),
                                        transition: Transition.fadeIn);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.027),
                            Expanded(
                              child: StaggeredCard(
                                index: 3,
                                animation: _staggerController,
                                child: _buildFeatureCard(
                                  title: 'Set Ringtone',
                                  subtitle: 'Custom Ringtones',
                                  icon: Icons.notifications_outlined,
                                  color: const Color(0xFFE68A00),
                                  screenWidth: screenWidth,
                                  screenHeight: screenHeight,
                                  onTap: () {
                                    Get.to(() => const SetRingtonePage(),
                                        transition: Transition.fadeIn);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.025),
                    ],
                  ),
                ),
              ),

              // ✅ Compensate for the overlap
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isAdLoaded
          ? SafeArea(
        child: Container(
          margin: EdgeInsets.all(screenWidth * 0.021),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.032),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: screenWidth * 0.027,
                offset: Offset(0, -screenHeight * 0.0025),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.032),
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

  Widget _buildHeroCard(double screenWidth, double screenHeight) {
    const Color _primaryColor = Color(0xFF6C63FF);

    return PressScaleBox(
      onTap: () {
        Get.to(() => const VideoView(), transition: Transition.fadeIn);
      },
      scaleFactor: 0.98,
      child: Container(
        constraints: BoxConstraints(
          minHeight: screenHeight * 0.25,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.064),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: screenWidth * 0.053,
              offset: Offset(0, screenHeight * 0.012),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.053),
          child: Row(
            children: [
              // Left side - Text content
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.027,
                        vertical: screenHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.053),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.008,
                            backgroundColor: Colors.white,
                          ),
                          SizedBox(width: screenWidth * 0.021),
                          Text(
                            'Quick Convert',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    Text(
                      'Video to Audio',
                      style: TextStyle(
                        fontSize: screenWidth * 0.062,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                        height: 1.1,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.008),

                    Text(
                      'Tap to get started',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: _primaryColor,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: screenWidth * 0.04),

              // Right side - Play button
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryColor.withOpacity(0.4)),
                    color: _primaryColor.withOpacity(1),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.11,
                  ),
                ),
              ),
            ],
          ),
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
    required double screenWidth,
    required double screenHeight,
  }) {
    return InteractiveCard(
      onTap: onTap,
      baseColor: color,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth * 0.043),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon at top
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: screenWidth * 0.07,
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.012),

            // Title - flexible, wraps naturally
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.040,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.5,
              ),
            ),

            SizedBox(height: screenHeight * 0.004),

            // Subtitle - flexible, wraps naturally
            Text(
              subtitle,
              style: TextStyle(
                fontSize: screenWidth * 0.029,
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