import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/video_controller.dart';
import 'video_palyer_screen.dart';
import 'package:path/path.dart' as path;
import '../utils/responsive_helper.dart';

// InteractiveBox Widget (Scale + Color Animation)
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

  void _handleTapDown(TapDownDetails details) => _controller.forward();
  void _handleTapUp(TapUpDetails details) async {
    await _controller.reverse();
    widget.onTap();
  }
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

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
                borderRadius: BorderRadius.circular(r.w(12)),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: r.w(1),
                ),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

// PressScaleBox Widget (Scale Only Animation)
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

  void _handleTapDown(TapDownDetails details) => _controller.forward();
  void _handleTapUp(TapUpDetails details) async {
    await _controller.reverse();
    widget.onTap();
  }
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// Custom Dashed Border Painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

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

// ==========================================
// MAIN VIDEO VIEW SCREEN
// ==========================================
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
    final r = ResponsiveHelper(context); // Initialize responsive helper

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: r.w(24),
          ),
          onPressed: () => Get.back(),
        ),
        centerTitle: false,
        title: Padding(
          padding: EdgeInsets.only(left: r.isTablet() ? r.w(16) : 0), // extra space for iPad
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Video',
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
                'Choose a video to convert',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: r.fs(13),
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        toolbarHeight: r.h(70), // Responsive toolbar height
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
            // Upload Section with PressScaleBox
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(r.w(16)),
                child: PressScaleBox(
                  onTap: () => _pickVideo(videoController),
                  scaleFactor: 0.99,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: r.h(40),
                      horizontal: r.w(20),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(r.w(12)),
                    ),
                    child: CustomPaint(
                      painter: DashedBorderPainter(
                        color: Colors.grey[400]!,
                        strokeWidth: r.w(2),
                        dashWidth: r.w(8),
                        dashSpace: r.w(4),
                        borderRadius: r.w(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(r.w(20)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(r.w(16)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.upload_outlined,
                                color: const Color(0xFF6366F1),
                                size: r.w(32),
                              ),
                            ),
                            SizedBox(height: r.h(16)),
                            Text(
                              'Upload Video',
                              style: TextStyle(
                                fontSize: r.fs(16),
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: r.h(6)),
                            Text(
                              'Tap to browse',
                              style: TextStyle(
                                fontSize: r.fs(13),
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: r.h(8)),
                            Text(
                              'Supported formats: MP4, AVI, MOV, MKV',
                              style: TextStyle(
                                fontSize: r.fs(12),
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: r.w(16),
                    vertical: r.h(8),
                  ),
                  child: Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: r.fs(16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

            // Video List - Using InteractiveBox
            if (videoController.videos.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: r.w(16)),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final video = videoController.videos[index];
                      var mbSize = videoController.getFileSizeInMB(video.path);

                      return Padding(
                        padding: EdgeInsets.only(bottom: r.h(12)),
                        child: InteractiveBox(
                          onTap: () {
                            Get.to(
                                  () => VideoPlayerScreen(videoPath: video.path),
                              transition: Transition.fade,
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(r.w(12)),
                            child: Row(
                              children: [
                                // Thumbnail with shimmer loading
                                FutureBuilder<String?>(
                                  future: videoController.generateThumbnail(video.path),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          width: r.w(60),
                                          height: r.w(60),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(r.w(8)),
                                          ),
                                        ),
                                      );
                                    } else if (snapshot.hasData) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(r.w(8)),
                                        child: Image.file(
                                          File(snapshot.data!),
                                          height: r.w(60),
                                          width: r.w(60),
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    } else {
                                      return Container(
                                        width: r.w(60),
                                        height: r.w(60),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(r.w(8)),
                                        ),
                                        child: Icon(
                                          Icons.videocam,
                                          size: r.w(30),
                                          color: Colors.grey,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                SizedBox(width: r.w(12)),

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
                                          fontSize: r.fs(15),
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: r.h(4)),
                                      Text(
                                        '$mbSize MB',
                                        style: TextStyle(
                                          fontSize: r.fs(13),
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
                    padding: EdgeInsets.all(r.w(32)),
                    child: Column(
                      children: [
                        Icon(
                          Icons.video_library_outlined,
                          size: r.w(64),
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: r.h(16)),
                        Text(
                          'No videos found',
                          style: TextStyle(
                            fontSize: r.fs(16),
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: r.h(8)),
                        Text(
                          'Upload a video to get started',
                          style: TextStyle(
                            fontSize: r.fs(14),
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
              child: SizedBox(height: r.h(20)),
            ),
          ],
        );
      }),
    );
  }
}