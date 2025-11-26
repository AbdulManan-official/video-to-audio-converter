import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:video_to_audio_converter/main.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import 'package:video_to_audio_converter/views/home_page.dart';
import '../../controllers/fromate_audio_controller.dart';
import '../../controllers/merge_controller.dart';
import '../../utils/responsive_helper.dart';
import 'dart:math';
import 'dart:io';

class ConversionProgressPage extends StatefulWidget {
  const ConversionProgressPage({super.key});


  @override
  State<ConversionProgressPage> createState() => _ConversionProgressPageState();

}

class _ConversionProgressPageState extends State<ConversionProgressPage> {
  final FormateAudioController formateController = Get.find<
      FormateAudioController>();
  bool isCancelDialogOpen = false;

  final MergeAudioController mergeController = Get.put(MergeAudioController());

  @override
  void initState() {
    super.initState();
    // Check for duplicates before starting conversion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDuplicatesAndConvert();
    });
    ever(formateController.isConverting, (bool converting) {
      if (!converting && isCancelDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop(); // Auto close cancel dialog
      }
    });


  }

  // Check if any output files already exist
  Future<void> _checkForDuplicatesAndConvert() async {
    // Use the controller's checkForDuplicates method
    List<String> duplicateFiles = await formateController.checkForDuplicates();

    if (duplicateFiles.isNotEmpty) {
      // Show duplicate handling dialog
      bool? userChoice = await _showDuplicateDialog(duplicateFiles);

      if (userChoice == null) {
        // User cancelled - replace existing files by default
        formateController.shouldReplaceExisting.value = true;
        Get.back();
        return;
      }

      // Store the user's choice in the controller
      formateController.shouldReplaceExisting.value = userChoice;
    } else {
      // No duplicates, proceed normally with replace mode
      formateController.shouldReplaceExisting.value = true;
    }

    // Set converting flag and start conversion
    formateController.isConverting.value = true;
    formateController.convertAllFiles();
  }

  // Show duplicate file handling dialog
  Future<bool?> _showDuplicateDialog(List<String> duplicateFiles) async {
    final r = ResponsiveHelper(context);

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.w(20)),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(r.w(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(r.w(10)),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(r.w(10)),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: r.w(24),
                        ),
                      ),
                      SizedBox(width: r.w(12)),
                      Expanded(
                        child: Text(
                          "Duplicate Files",
                          style: TextStyle(
                            fontSize: r.fs(18),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.h(16)),

                  // Description
                  Text(
                    "${duplicateFiles.length} ${duplicateFiles.length == 1
                        ? 'file'
                        : 'files'} already exist. Choose an option:",
                    style: TextStyle(
                      fontSize: r.fs(13),
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: r.h(16)),

                  // Option 1: Replace All
                  _buildOptionButton(
                    icon: Icons.sync,
                    title: "Replace Existing",
                    description: "Overwrite all files",
                    color: Colors.red,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                  SizedBox(height: r.h(10)),

                  // Option 2: Keep & Rename
                  _buildOptionButton(
                    icon: Icons.content_copy,
                    title: "Keep & Rename",
                    description: "Rename as file (1).mp3, file (2).mp3...",
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                  SizedBox(height: r.h(12)),

                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      minimumSize: Size(double.infinity, r.h(40)),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: r.fs(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final r = ResponsiveHelper(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(r.w(12)),
      child: Container(
        padding: EdgeInsets.all(r.w(14)),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: r.w(1)),
          borderRadius: BorderRadius.circular(r.w(12)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(r.w(8)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(r.w(8)),
              ),
              child: Icon(icon, color: color, size: r.w(20)),
            ),
            SizedBox(width: r.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: r.fs(14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: r.h(2)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: r.fs(11),
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: r.w(14),
                color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

// Show cancel confirmation dialog
  // Simple cancel confirmation dialog
  Future<bool?> _showCancelDialog() async {
    isCancelDialogOpen = true; // Mark dialog as open
    final r = ResponsiveHelper(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r.w(16)),
          ),
          title: Text(
            "Cancel Conversion?",
            style: TextStyle(
              fontSize: r.fs(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Do you want to cancel the ongoing conversion? Progress will be lost.",
            style: TextStyle(
              fontSize: r.fs(14),
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Continue",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: r.fs(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(r.w(8)),
                ),
                elevation: 0,
              ),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: r.fs(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    isCancelDialogOpen = false; // Mark dialog as closed
    return result;
  }



  // Utility function to format file size in bytes (KB, MB, etc.)
  String formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = (log(bytes) / log(1024)).floor();
    if (i >= suffixes.length) {
      i = suffixes.length - 1;
    }
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  String getFormattedFileName(String filePath) {
    final fileName = filePath
        .split('/')
        .last;
    final extension = formateController.selectedFormat.value.toLowerCase();
    final baseName = fileName
        .split('.')
        .first;
    final newFileName = '${baseName}_converted.$extension';

    const maxLength = 18;

    if (newFileName.length > maxLength) {
      return '${newFileName.substring(0, maxLength)}...';
    }
    return newFileName;
  }

  int getCompletedCount() {
    return formateController.fileProgress
        .where((progress) => progress.value >= 1.0)
        .length;
  }

  double getTotalProgress() {
    final totalFiles = formateController.fileProgress.length;
    if (totalFiles == 0) return 0.0;

    double totalProgressSum = 0.0;
    for (var progress in formateController.fileProgress) {
      totalProgressSum += progress.value;
    }

    return totalProgressSum / totalFiles;
  }

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper(context);

    return WillPopScope(
      onWillPop: () async {
        if (formateController.isConverting.value) {
          bool? shouldCancel = await _showCancelDialog();
          if (shouldCancel == true) {
            // Cancel conversion
            formateController.cancelConversion();

            // Get stats
            final stats = formateController.getConversionStats();

            Fluttertoast.showToast(
              msg: "Conversion failed: ${stats['completed']} files converted, ${stats['pending']} files not converted",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
              fontSize: 16.0,
            );


            return true; // Allow back navigation
          }
          return false; // Stay on current screen
        }
        return true; // If conversion is complete, allow back navigation
      },


    child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black, size: r.w(24)),
            onPressed: () async {
              if (formateController.isConverting.value) {
                bool? shouldCancel = await _showCancelDialog();
                if (shouldCancel == true) {
                  formateController.cancelConversion();
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Padding(
            padding: EdgeInsets.only(left: r.isTablet() ? r.w(16) : r.w(4)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Conversion Progress",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: r.fs(18),
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: r.h(2)),
                Obx(() {
                  int completed = getCompletedCount();
                  int total = formateController.selectedFiles.length;
                  return Text(
                    formateController.isConverting.value
                        ? "Converting files..."
                        : "$completed of $total completed",
                    style: TextStyle(
                      fontSize: r.fs(13),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ],
            ),
          ),
          toolbarHeight: r.h(70),
          actions: [
            Obx(() {
              bool allDone = getCompletedCount() ==
                  formateController.selectedFiles.length;
              return allDone
                  ? IconButton(
                icon: Icon(Icons.home, color: Colors.black, size: r.w(24)),
                onPressed: () {
                  Get.offAll(() => HomeScreen());
                },
              )
                  : const SizedBox.shrink();
            }),
          ],
        ),
        body: Obx(() {
          return Column(
            children: [
              // Progress Summary Card
              if (formateController.selectedFiles.isNotEmpty)
                Obx(() {
                  final totalFiles = formateController.selectedFiles.length;
                  final completedFiles = getCompletedCount();
                  final progressValue = getTotalProgress();

                  return Container(
                    margin: EdgeInsets.all(r.w(16)),
                    padding: EdgeInsets.symmetric(
                      horizontal: r.w(20),
                      vertical: r.h(20),
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF6C63FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(r.w(16)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                          blurRadius: r.w(12),
                          offset: Offset(0, r.h(4)),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Overall Conversion Status",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.fs(15),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: r.w(8)),
                            Text(
                              "${(progressValue * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: r.fs(20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: r.h(12)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(r.w(8)),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: r.h(12),
                          ),
                        ),
                        SizedBox(height: r.h(20)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Completed",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: r.fs(12),
                                    ),
                                  ),
                                  SizedBox(height: r.h(2)),
                                  Text(
                                    "$completedFiles",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.fs(24),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Total Files",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: r.fs(12),
                                    ),
                                  ),
                                  SizedBox(height: r.h(2)),
                                  Text(
                                    "$totalFiles",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.fs(24),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Format",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: r.fs(12),
                                    ),
                                  ),
                                  SizedBox(height: r.h(2)),
                                  Text(
                                    formateController.selectedFormat.value,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: r.fs(24),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

              // Files List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: r.w(16)),
                  itemCount: formateController.selectedFiles.length,
                  itemBuilder: (context, index) {
                    final fileName = getFormattedFileName(
                        formateController.selectedFiles[index]);
                    final progress = formateController.fileProgress[index];
                    final isCompleted = progress.value >= 1.0;

                    return Container(
                      margin: EdgeInsets.only(bottom: r.h(12)),
                      padding: EdgeInsets.all(r.w(16)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(r.w(16)),
                        border: Border.all(
                          color: isCompleted
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey[200]!,
                          width: r.w(1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: r.w(8),
                            offset: Offset(0, r.h(2)),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: r.w(50),
                            height: r.w(50),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF),
                              borderRadius: BorderRadius.circular(r.w(12)),
                            ),
                            child: isCompleted
                                ? Icon(
                              Icons.audio_file,
                              color: Colors.white,
                              size: r.w(32),
                            )
                                : Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.audio_file,
                                  color: Colors.white,
                                  size: r.w(28),
                                ),
                                if (progress.value > 0 && progress.value < 1.0)
                                  SizedBox(
                                    width: r.w(56),
                                    height: r.w(56),
                                    child: CircularProgressIndicator(
                                      value: progress.value,
                                      strokeWidth: r.w(3),
                                      backgroundColor: Colors.transparent,
                                      valueColor: const AlwaysStoppedAnimation<
                                          Color>(
                                        Color(0xFF6C63FF),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: r.w(16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: r.fs(14),
                                    color: isCompleted ? Colors.black : Colors
                                        .black,
                                  ),
                                ),
                                SizedBox(height: r.h(8)),
                                if (isCompleted) ...[
                                  Text(
                                    'Size: ${formatBytes(1500000, 2)}',
                                    style: TextStyle(
                                      fontSize: r.fs(12),
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: r.h(4)),
                                  Text(
                                    "Conversion complete",
                                    style: TextStyle(
                                      fontSize: r.fs(12),
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else
                                  ...[
                                    Obx(() {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            r.w(8)),
                                        child: LinearProgressIndicator(
                                          value: progress.value,
                                          backgroundColor: Colors.grey[200],
                                          valueColor: const AlwaysStoppedAnimation<
                                              Color>(
                                            Color(0xFF6C63FF),
                                          ),
                                          minHeight: r.h(6),
                                        ),
                                      );
                                    }),
                                    SizedBox(height: r.h(6)),
                                    Obx(() {
                                      return Text(
                                        '${(progress.value * 100)
                                            .toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: r.fs(12),
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    }),
                                  ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Success Button
              if (!formateController.isConverting.value)
                Container(
                  padding: EdgeInsets.all(r.w(16)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: r.w(10),
                        offset: Offset(0, -r.h(2)),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // ✅ Navigate to OutputScreen with Converted tab (index 3)
                            Get.to(
                                  () => OutputScreen(),
                              arguments: 3, // Open Converted tab
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            minimumSize: Size(double.infinity, r.h(54)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r.w(12)),
                            ),
                            elevation: 0,
                          ),
                          icon: Icon(Icons.folder_open, color: Colors.white, size: r.w(22)),
                          label: Text(
                            'Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.fs(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}