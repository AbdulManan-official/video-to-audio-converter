import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/video_controller.dart';
import 'video_palyer_screen.dart';
import 'package:path/path.dart' as path;


// 1. REFINED InteractiveBox Widget (Scale + Color Animation) - USED FOR LIST ITEMS
class InteractiveBox extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color backgroundColor;
  final double scaleFactor;
  final Duration animationDuration;
  final Color pressedColor;

  const InteractiveBox({
    super.key,
    required this.child,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.pressedColor = const Color(0xFFE5E7EB),
    this.scaleFactor = 0.98,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  @override
  State<InteractiveBox> createState() => _InteractiveBoxState();
}

class _InteractiveBoxState extends State<InteractiveBox> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _colorAnimation = ColorTween(
      begin: widget.backgroundColor,
      end: widget.pressedColor,
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
    await Future.value(_controller.reverse());
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;

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
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(12 * scaleFactor),
                border: Border.all(color: Colors.grey[300]!, width: 1.0 * scaleFactor),
              ),
              child: widget.child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// 2. NEW PressScaleBox Widget (Scale Only Animation) - USED FOR PICKER BOX
class PressScaleBox extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;
  final Duration animationDuration;

  const PressScaleBox({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.99,
    this.animationDuration = const Duration(milliseconds: 100),
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
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
    await Future.value(_controller.reverse());
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

class VideoView extends StatelessWidget {
  const VideoView({super.key});

  Future<void> _pickVideo(VideoController videoController) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v', '3gp'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        String videoPath = result.files.single.path!;
        Get.to(() => VideoPlayerScreen(videoPath: videoPath),
            transition: Transition.fade);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final VideoController videoController = Get.put(VideoController());
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24 * scaleFactor),
          onPressed: () => Get.back(),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Video',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18 * scaleFactor * textScaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Choose a video to convert',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13 * scaleFactor * textScaleFactor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (videoController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6366F1),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // Upload Section with NEW PressScaleBox
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0 * scaleFactor),
                child: PressScaleBox(
                  onTap: () => _pickVideo(videoController),
                  scaleFactor: 0.99,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 40 * scaleFactorHeight, horizontal: 20 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12 * scaleFactor),
                    ),
                    child: CustomPaint(
                      painter: DashedBorderPainter(
                        color: Colors.grey[400]!,
                        strokeWidth: 2.0 * scaleFactor,
                        dashWidth: 8.0 * scaleFactor,
                        dashSpace: 4.0 * scaleFactor,
                        borderRadius: 12 * scaleFactor,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(20 * scaleFactor),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(16 * scaleFactor),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.upload_outlined,
                                color: const Color(0xFF6366F1),
                                size: 32 * scaleFactor,
                              ),
                            ),
                            SizedBox(height: 16 * scaleFactorHeight),
                            Text(
                              'Upload Video',
                              style: TextStyle(
                                fontSize: 16 * scaleFactor * textScaleFactor,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6 * scaleFactorHeight),
                            Text(
                              'Tap to browse',
                              style: TextStyle(
                                fontSize: 13 * scaleFactor * textScaleFactor,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8 * scaleFactorHeight),
                            Text(
                              'Supported formats: MP4, AVI, MOV, MKV',
                              style: TextStyle(
                                fontSize: 12 * scaleFactor * textScaleFactor,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Access Header
            if (videoController.videos.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0 * scaleFactor, vertical: 8 * scaleFactorHeight),
                  child: Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 16 * scaleFactor * textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

            // Video List - Using the InteractiveBox (Scale + Color)
            if (videoController.videos.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final video = videoController.videos[index];
                      var mbSize = videoController.getFileSizeInMB(video.path);

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12 * scaleFactorHeight),
                        child: InteractiveBox(
                          onTap: () {
                            Get.to(() => VideoPlayerScreen(videoPath: video.path),
                                transition: Transition.fade);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(12 * scaleFactor),
                            child: Row(
                              children: [
                                // Thumbnail with shimmer loading
                                FutureBuilder<String?>(
                                  future: videoController.generateThumbnail(video.path),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          width: 60 * scaleFactor,
                                          height: 60 * scaleFactor,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8 * scaleFactor),
                                          ),
                                        ),
                                      );
                                    } else if (snapshot.hasData) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8 * scaleFactor),
                                        child: Image.file(
                                          File(snapshot.data!),
                                          height: 60 * scaleFactor,
                                          width: 60 * scaleFactor,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    } else {
                                      return Container(
                                        width: 60 * scaleFactor,
                                        height: 60 * scaleFactor,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8 * scaleFactor),
                                        ),
                                        child: Icon(
                                          Icons.videocam,
                                          size: 30 * scaleFactor,
                                          color: Colors.grey,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                SizedBox(width: 12 * scaleFactor),

                                // Video Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        path.basenameWithoutExtension(video.path),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15 * scaleFactor * textScaleFactor,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4 * scaleFactorHeight),
                                      Text(
                                        '$mbSize MB',
                                        style: TextStyle(
                                          fontSize: 13 * scaleFactor * textScaleFactor,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: videoController.videos.length,
                  ),
                ),
              ),

            // Empty State
            if (videoController.videos.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0 * scaleFactor),
                    child: Column(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: 64 * scaleFactor,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16 * scaleFactorHeight),
                        Text(
                          'No videos found',
                          style: TextStyle(
                            fontSize: 16 * scaleFactor * textScaleFactor,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8 * scaleFactorHeight),
                        Text(
                          'Upload a video to get started',
                          style: TextStyle(
                            fontSize: 14 * scaleFactor * textScaleFactor,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom Spacing
            SliverToBoxAdapter(
              child: SizedBox(height: 20 * scaleFactorHeight),
            ),
          ],
        );
      }),
    );
  }
}

// Custom Dashed Border Painter (Modified to accept borderRadius for scaling)
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius; // New parameter for responsive border radius

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(
              distance,
              distance + length > metric.length ? metric.length : distance + length,
            ),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}