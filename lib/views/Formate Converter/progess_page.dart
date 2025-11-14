import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_to_audio_converter/main.dart';
import 'package:video_to_audio_converter/utils/utils.dart';
import 'package:video_to_audio_converter/views/home_page.dart';
import '../../controllers/fromate_audio_controller.dart';
import '../../controllers/merge_controller.dart';
import 'dart:math';
import 'dart:io';

class ConversionProgressPage extends StatefulWidget {
  const ConversionProgressPage({super.key});

  @override
  State<ConversionProgressPage> createState() => _ConversionProgressPageState();
}

class _ConversionProgressPageState extends State<ConversionProgressPage> {
  final FormateAudioController formateController = Get.find<FormateAudioController>();
  final MergeAudioController mergeController = Get.put(MergeAudioController());

  @override
  void initState() {
    super.initState();
    // Check for duplicates before starting conversion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDuplicatesAndConvert();
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
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / 812.0;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scaleFactor),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(24 * scaleFactor),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10 * scaleFactor),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: 24 * scaleFactor,
                        ),
                      ),
                      SizedBox(width: 12 * scaleFactor),
                      Expanded(
                        child: Text(
                          "Duplicate Files",
                          style: TextStyle(
                            fontSize: 18 * scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * scaleFactorHeight),

                  // Description
                  Text(
                    "${duplicateFiles.length} ${duplicateFiles.length == 1 ? 'file' : 'files'} already exist. Choose an option:",
                    style: TextStyle(
                      fontSize: 13 * scaleFactor * textScaleFactor,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16 * scaleFactorHeight),

                  // Option 1: Replace All
                  _buildOptionButton(
                    icon: Icons.sync,
                    title: "Replace Existing",
                    description: "Overwrite all files",
                    color: Colors.red,
                    onTap: () => Navigator.of(context).pop(true),
                    scaleFactor: scaleFactor,
                    textScaleFactor: textScaleFactor,
                    scaleFactorHeight: scaleFactorHeight,
                  ),
                  SizedBox(height: 10 * scaleFactorHeight),

                  // Option 2: Keep & Rename
                  _buildOptionButton(
                    icon: Icons.content_copy,
                    title: "Keep & Rename",
                    description: "Rename as file (1).mp3, file (2).mp3...",
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.of(context).pop(false),
                    scaleFactor: scaleFactor,
                    textScaleFactor: textScaleFactor,
                    scaleFactorHeight: scaleFactorHeight,
                  ),
                  SizedBox(height: 12 * scaleFactorHeight),

                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      minimumSize: Size(double.infinity, 40 * scaleFactorHeight),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14 * scaleFactor * textScaleFactor,
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
    required double scaleFactor,
    required double textScaleFactor,
    required double scaleFactorHeight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * scaleFactor),
      child: Container(
        padding: EdgeInsets.all(14 * scaleFactor),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 1 * scaleFactor),
          borderRadius: BorderRadius.circular(12 * scaleFactor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8 * scaleFactor),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8 * scaleFactor),
              ),
              child: Icon(icon, color: color, size: 20 * scaleFactor),
            ),
            SizedBox(width: 12 * scaleFactor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2 * scaleFactorHeight),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11 * scaleFactor * textScaleFactor,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14 * scaleFactor, color: Colors.grey[400]),
          ],
        ),
      ),
    );
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
    final fileName = filePath.split('/').last;
    final extension = formateController.selectedFormat.value.toLowerCase();
    final baseName = fileName.split('.').first;
    final newFileName = '${baseName}_converted.$extension';

    const maxLength = 18;

    if (newFileName.length > maxLength) {
      return '${newFileName.substring(0, maxLength)}...';
    }
    return newFileName;
  }

  int getCompletedCount() {
    return formateController.fileProgress.where((progress) => progress.value >= 1.0).length;
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
    // --- Responsive Scaling Setup ---
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / 812.0;
    final double textScaleFactor = mediaQuery.textScaleFactor;
    // -------------------------------

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24 * scaleFactor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: EdgeInsets.only(left: 4.0 * scaleFactor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Conversion Progress",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 18 * scaleFactor * textScaleFactor,
                ),
              ),
              Obx(() {
                int completed = getCompletedCount();
                int total = formateController.selectedFiles.length;
                return Text(
                  formateController.isConverting.value
                      ? "Converting files..."
                      : "$completed of $total completed",
                  style: TextStyle(
                    fontSize: 12 * scaleFactor * textScaleFactor,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          Obx(() {
            bool allDone = getCompletedCount() == formateController.selectedFiles.length;
            return allDone
                ? IconButton(
              icon: Icon(Icons.home, color: Colors.black, size: 24 * scaleFactor),
              onPressed: () {
                // NOTE: Keeping the original code that navigates to HomeScreen without the import.
                // It is assumed HomeScreen is available in your project scope.
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
                  margin: EdgeInsets.all(16 * scaleFactor),
                  padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor, vertical: 20 * scaleFactorHeight),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF6C63FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16 * scaleFactor),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        blurRadius: 12 * scaleFactor,
                        offset: Offset(0, 4 * scaleFactorHeight),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Overall Conversion Status",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15 * scaleFactor * textScaleFactor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${(progressValue * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20 * scaleFactor * textScaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12 * scaleFactorHeight),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8 * scaleFactor),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 12 * scaleFactorHeight,
                        ),
                      ),
                      SizedBox(height: 20 * scaleFactorHeight),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Completed",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12 * scaleFactor * textScaleFactor,
                                ),
                              ),
                              SizedBox(height: 2 * scaleFactorHeight),
                              Text(
                                "$completedFiles",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24 * scaleFactor * textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Total Files",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12 * scaleFactor * textScaleFactor,
                                ),
                              ),
                              SizedBox(height: 2 * scaleFactorHeight),
                              Text(
                                "$totalFiles",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24 * scaleFactor * textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Format",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12 * scaleFactor * textScaleFactor,
                                ),
                              ),
                              SizedBox(height: 2 * scaleFactorHeight),
                              Text(
                                formateController.selectedFormat.value,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24 * scaleFactor * textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                padding: EdgeInsets.symmetric(horizontal: 16 * scaleFactor),
                itemCount: formateController.selectedFiles.length,
                itemBuilder: (context, index) {
                  final fileName = getFormattedFileName(formateController.selectedFiles[index]);
                  final progress = formateController.fileProgress[index];
                  final isCompleted = progress.value >= 1.0;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12 * scaleFactorHeight),
                    padding: EdgeInsets.all(16 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                      border: Border.all(
                        color: isCompleted ? Colors.black.withOpacity(0.2) : Colors.grey[200]!,
                        width: 1 * scaleFactor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8 * scaleFactor,
                          offset: Offset(0, 2 * scaleFactorHeight),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50 * scaleFactor,
                          height: 50 * scaleFactor,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(12 * scaleFactor),
                          ),
                          child: isCompleted
                              ? Icon(
                            Icons.audio_file,
                            color: Colors.white,
                            size: 32 * scaleFactor,
                          )
                              : Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.audio_file,
                                color: Colors.white,
                                size: 28 * scaleFactor,
                              ),
                              if (progress.value > 0 && progress.value < 1.0)
                                SizedBox(
                                  width: 56 * scaleFactor,
                                  height: 56 * scaleFactor,
                                  child: CircularProgressIndicator(
                                    value: progress.value,
                                    strokeWidth: 3 * scaleFactor,
                                    backgroundColor: Colors.transparent,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6C63FF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16 * scaleFactor),
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
                                  fontSize: 14 * scaleFactor * textScaleFactor,
                                  color: isCompleted ? Colors.black : Colors.black,
                                ),
                              ),
                              SizedBox(height: 8 * scaleFactorHeight),
                              if (isCompleted) ...[
                                Text(
                                  'Size: ${formatBytes(1500000, 2)}',
                                  style: TextStyle(
                                    fontSize: 12 * scaleFactor * textScaleFactor,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4 * scaleFactorHeight),
                                Text(
                                  "Conversion complete",
                                  style: TextStyle(
                                    fontSize: 12 * scaleFactor * textScaleFactor,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else ...[
                                Obx(() {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8 * scaleFactor),
                                    child: LinearProgressIndicator(
                                      value: progress.value,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF6C63FF),
                                      ),
                                      minHeight: 6 * scaleFactorHeight,
                                    ),
                                  );
                                }),
                                SizedBox(height: 6 * scaleFactorHeight),
                                Obx(() {
                                  return Text(
                                    '${(progress.value * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12 * scaleFactor * textScaleFactor,
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
                padding: EdgeInsets.all(16 * scaleFactor),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10 * scaleFactor,
                      offset: Offset(0, -2 * scaleFactorHeight),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // NOTE: Keeping the original code that navigates to OutputScreen.
                          Get.to(() => const OutputScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          minimumSize: Size(double.infinity, 54 * scaleFactorHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scaleFactor),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(Icons.folder_open, color: Colors.white, size: 22 * scaleFactor),
                        label: Text(
                          'Go To Folder',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * scaleFactor * textScaleFactor,
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
    );
  }
}