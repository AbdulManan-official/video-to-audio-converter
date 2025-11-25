import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:video_to_audio_converter/utils/utils.dart';
import '../../utils/resources.dart';
import '../../utils/responsive_helper.dart';
import '../../controllers/merge_controller.dart';
import '../../controllers/video_controller.dart';
import '../audio_saved_screen.dart';
import '../../utils/search_filter_bar.dart';

class MergeAudioScreen extends StatefulWidget {
  const MergeAudioScreen({super.key});

  @override
  State<MergeAudioScreen> createState() => _MergeAudioScreenState();
}

class _MergeAudioScreenState extends State<MergeAudioScreen> {
  final MergeAudioController controller = Get.put(MergeAudioController());
  final VideoController videoController = Get.put(VideoController());
  final TextEditingController outputNameController = TextEditingController(
      text: 'merged-audio');
  String fileName = 'merged-audio';
  bool isDragging = false;
  bool isDraggingFromSelected = false;

  List<File> localMusicFiles = [];
  bool _isFetchingAllFiles = true;
  bool _isFetchingLocalFiles = false;
  bool _localMusicPermissionGranted = false;

  List<File> selectedFiles = [];
  Set<String> selectedFilePaths = {};

  String _searchQuery = '';
  int _selectedTabIndex = 0;

  List<File> videoMusicFiles = [];
  List<File> mergedAudioFiles = [];
  List<File> formatConverterAudioFiles = [];

  static const int maxSelectionLimit = 5;

  Future<bool> _requestStoragePermission() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  void initState() {
    super.initState();
    _fetchAllInitialFiles();
  }

  Future<void> _fetchAllInitialFiles() async {
    setState(() {
      _isFetchingAllFiles = true;
    });

    await _fetchFilesByCategory();
    controller.isLoading.value = false;

    setState(() {
      _isFetchingAllFiles = false;
    });
  }

  Future<void> _fetchFilesByCategory() async {
    videoMusicFiles.clear();
    mergedAudioFiles.clear();
    formatConverterAudioFiles.clear();

    await _fetchFilesFromDirectory(
        '/storage/emulated/0/Music/VideoMusic', videoMusicFiles);
    await _fetchFilesFromDirectory(
        '/storage/emulated/0/Music/MergedAudio', mergedAudioFiles);
    await _fetchFilesFromDirectory('/storage/emulated/0/Music/Format Converter',
        formatConverterAudioFiles);
  }

  Future<void> _fetchFilesFromDirectory(String directoryPath,
      List<File> targetList) async {
    targetList.clear();
    Directory dir = Directory(directoryPath);
    if (await dir.exists()) {
      List<File> files = dir
          .listSync()
          .where((item) => !item.path.contains(".pending-"))
          .map((item) => File(item.path))
          .where((file) => file.existsSync() && file.lengthSync() > 0)
          .toList();

      // ✅ Sort by modification time (newest first)
      files.sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      targetList.addAll(files);
    }
  }

  Future<bool?> _showExitConfirmationDialog() async {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16 * scaleFactor),
            ),
            contentPadding: EdgeInsets.all(20 * scaleFactor),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 28 * scaleFactor,
                ),
                SizedBox(width: 12 * scaleFactor),
                Expanded(
                  child: Text(
                    'Merging in Progress',
                    style: TextStyle(
                      fontSize: 18 * scaleFactor * textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your audio files are currently being merged.',
                    style: TextStyle(
                      fontSize: 15 * scaleFactor * textScaleFactor,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  Text(
                    'If you exit now, the merge will be cancelled and your progress will be lost.',
                    style: TextStyle(
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12 * scaleFactor),
                  Text(
                    'Do you want to cancel the merge and exit?',
                    style: TextStyle(
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scaleFactor,
                    vertical: 12 * scaleFactor,
                  ),
                ),
                child: Text(
                  'CONTINUE MERGING',
                  style: TextStyle(
                    fontSize: 14 * scaleFactor * textScaleFactor,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * scaleFactor,
                    vertical: 12 * scaleFactor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scaleFactor),
                  ),
                ),
                onPressed: () async {
                  // ✅ Cancel the merge operation
                  await controller.cancelMerge();
                  Navigator.of(context).pop(true); // Allow exit
                },
                child: Text(
                  'CANCEL & EXIT',
                  style: TextStyle(
                    fontSize: 14 * scaleFactor * textScaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _fetchLocalAudioFiles(
      {bool forcePermissionCheck = false}) async {
    setState(() {
      _isFetchingLocalFiles = true;
    });

    if (!_localMusicPermissionGranted || forcePermissionCheck) {
      final isGranted = await _requestStoragePermission();

      if (mounted) {
        setState(() {
          _localMusicPermissionGranted = isGranted;
        });
      }

      if (!isGranted) {
        localMusicFiles = [];
        if (mounted) {
          setState(() {
            _isFetchingLocalFiles = false;
          });
        }
        return;
      }
    }

    if (!_localMusicPermissionGranted) {
      if (mounted) {
        setState(() {
          _isFetchingLocalFiles = false;
        });
      }
      return;
    }

    final appDirs = [
      '/storage/emulated/0/Music/VideoMusic',
      '/storage/emulated/0/Music/MergedAudio',
      '/storage/emulated/0/Music/Format Converter',
    ].map((path) => path.toLowerCase()).toSet();

    final directoriesToSearch = [
      Directory('/storage/emulated/0/Music'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Audio'),
    ];

    List<File> files = [];
    for (var searchDir in directoriesToSearch) {
      if (await searchDir.exists()) {
        await for (var entity in searchDir.list(
            recursive: true, followLinks: false)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if ((path.endsWith('.mp3') || path.endsWith('.m4a') ||
                path.endsWith('.wav') || path.endsWith('.aac') ||
                path.endsWith('.flac') || path.endsWith('.ogg')) &&
                !appDirs.any((appDir) => path.contains(appDir)) &&
                entity.existsSync() &&
                entity.lengthSync() > 0) { // <-- filter here
              files.add(entity);
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        // ✅ Safe sort - only sort files that still exist
        try {
          files.sort((a, b) {
            try {
              return b.lastModifiedSync().compareTo(a.lastModifiedSync());
            } catch (e) {
              return 0; // If comparison fails, keep original order
            }
          });
        } catch (e) {
          // If sorting fails entirely, just use unsorted list
        }
        localMusicFiles = files;
        _isFetchingLocalFiles = false;
      });
    }
  }

  List<File> _getAllFiles() {
    return [
      ...videoMusicFiles,
      ...mergedAudioFiles,
      ...formatConverterAudioFiles
    ];
  }

  List<File> _getCurrentFiles() {
    List<File> files;
    switch (_selectedTabIndex) {
      case 0:
        files = [
          ...videoMusicFiles,
          ...mergedAudioFiles,
          ...formatConverterAudioFiles
        ];
        // ✅ Safe sort for combined list
        try {
          files.sort((a, b) {
            try {
              return b.lastModifiedSync().compareTo(a.lastModifiedSync());
            } catch (e) {
              return 0;
            }
          });
        } catch (e) {
          // If sorting fails, use unsorted list
        }
        break;
      case 1:
        files = videoMusicFiles;
        break;
      case 2:
        files = mergedAudioFiles;
        break;
      case 3:
        files = formatConverterAudioFiles;
        break;
      case 4:
        files = localMusicFiles;
        break;
      default:
        files = [];
    }
    return files.where((f) => f.existsSync() && f.lengthSync() > 0).toList();
  }


  void _handleTabSelected(int index) {
    if (index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = index;
      });
    }

    if (index == 4) {
      _fetchLocalAudioFiles(forcePermissionCheck: true);
    }
  }

  bool _isFileSelected(File file) => selectedFilePaths.contains(file.path);

  void _addFileToSelection(File file) {
    if (selectedFiles.length < maxSelectionLimit && !_isFileSelected(file)) {
      setState(() {
        selectedFiles.add(file);
        selectedFilePaths.add(file.path);
      });
    } else if (selectedFiles.length >= maxSelectionLimit) {
      toastFlutter(
        toastmessage: 'Only $maxSelectionLimit files can be selected for merging.',
        color: Colors.red,
      );
    }
  }

  void _removeFileFromSelection(File file) {
    setState(() {
      selectedFiles.removeWhere((f) => f.path == file.path);
      selectedFilePaths.remove(file.path);
    });
  }

  void _clearAllSelections() {
    setState(() {
      selectedFiles.clear();
      selectedFilePaths.clear();
    });
  }

  String shortenFileName(String name, {int max = 20}) {
    if (name.length <= max) return name;

    final dotIndex = name.lastIndexOf('.');
    final baseName = dotIndex != -1 ? name.substring(0, dotIndex) : name;
    final extension = dotIndex != -1 ? name.substring(dotIndex) : '';

    if (extension.length >= max) return '...$extension';

    final allowedBaseLength = max - 3;
    if (allowedBaseLength <= 0) return '...';

    return '${baseName.substring(0, allowedBaseLength)}...';
  }

  @override
  void dispose() {
    outputNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;
    final double keyboardHeight = mediaQuery.viewInsets.bottom;
    Color primaryColor = const Color(0xFF6C63FF);

    return WillPopScope(
        onWillPop: () async {
          if (controller.isMerging.value) {
            final shouldExit = await _showExitConfirmationDialog();
            return shouldExit ?? false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: responsive.w(24),
              ),
              onPressed: () async {
                // ✅ Check if merging before allowing back navigation
                if (controller.isMerging.value) {
                  final shouldExit = await _showExitConfirmationDialog();
                  if (shouldExit == true) {
                    Navigator.of(context).pop();
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            centerTitle: false,
            title: Padding(
              padding: EdgeInsets.only(
                  left: responsive.isTablet() ? responsive.w(16) : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Merge Audio',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: responsive.fs(18),
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.h(2)),
                  Text(
                    'Combine multiple files into one',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: responsive.fs(13),
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            toolbarHeight: responsive.h(70),
          ),
          body: Obx(() {
            if (controller.isLoading.value || _isFetchingAllFiles) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _buildSelectedFilesSection(
                    scaleFactor, scaleFactorHeight, textScaleFactor),

                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: buildGenericSearchBar(
                          scaleFactor: scaleFactor,
                          textScaleFactor: textScaleFactor,
                          context: context,
                          onSearchQueryChanged: (value) {
                            setState(() => _searchQuery = value.toLowerCase());
                          },
                          hintText: 'Search audio files...',
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: buildGenericFilterTabs(
                          scaleFactor: scaleFactor,
                          scaleFactorHeight: scaleFactorHeight,
                          textScaleFactor: textScaleFactor,
                          context: context,
                          selectedTabIndex: _selectedTabIndex,
                          onTabSelected: _handleTabSelected,
                          tabLabels: const [
                            'All',
                            'Extracted',
                            'Merged',
                            'Converted',
                            'Local'
                          ],
                        ),
                      ),

                      if (!(_selectedTabIndex == 4 &&
                          !_localMusicPermissionGranted))
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              responsive.w(16),
                              responsive.h(4),
                              responsive.w(16),
                              responsive.h(12),
                            ),
                            child: Text(
                              'Available Files',
                              style: TextStyle(
                                fontSize: responsive.fs(14),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),

                      _buildAvailableFilesList(
                          primaryColor, scaleFactor, scaleFactorHeight,
                          textScaleFactor),

                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: selectedFiles.length >= 2
                              ? (keyboardHeight > 0 ? keyboardHeight +
                              80 * scaleFactorHeight : 80 * scaleFactorHeight)
                              : (keyboardHeight > 0 ? keyboardHeight : 0),
                        ),
                      ),
                    ],
                  ),
                ),

                if (keyboardHeight == 0)
                  if (isDraggingFromSelected)
                    _buildDeleteBin(
                        scaleFactor, scaleFactorHeight, textScaleFactor)
                  else
                    if (selectedFiles.length >= 2)
                      _buildMergeButton(
                          primaryColor, scaleFactor, scaleFactorHeight,
                          textScaleFactor),
              ],
            );
          }),
        ));
  }

  Widget _buildAvailableFilesList(Color primaryColor, double scaleFactor,
      double scaleFactorHeight, double textScaleFactor) {
    if (_selectedTabIndex == 4 && _isFetchingLocalFiles) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32 * scaleFactor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2 * scaleFactor),
                SizedBox(height: 16 * scaleFactorHeight),
                Text('Scanning local audio files...', style: TextStyle(
                    fontSize: 14 * scaleFactor * textScaleFactor,
                    color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      );
    }

    if (_selectedTabIndex == 4 && !_localMusicPermissionGranted) {
      return SliverToBoxAdapter(
        child: _buildPermissionDeniedState(
            primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
      );
    }

    final currentFiles = _getCurrentFiles();
    final lowerCaseQuery = _searchQuery.toLowerCase();

    final filteredFiles = currentFiles.where((file) {
      if (_isFileSelected(file)) return false;
      final fileName = file.path
          .split('/')
          .last
          .toLowerCase();
      return fileName.contains(lowerCaseQuery);
    }).toList();

    if (filteredFiles.isEmpty && lowerCaseQuery.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24 * scaleFactor),
            child: Text('No matching unselected files found.', style: TextStyle(
                fontSize: 14 * scaleFactor * textScaleFactor,
                color: Colors.grey[500])),
          ),
        ),
      );
    } else if (filteredFiles.isEmpty && currentFiles.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24 * scaleFactor),
            child: Text('All files in this category are currently selected.',
                style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor,
                    color: Colors.grey[500])),
          ),
        ),
      );
    } else if (filteredFiles.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24 * scaleFactor),
            child: Column(
              children: [
                Icon(Icons.music_off, size: 64 * scaleFactor,
                    color: Colors.grey[400]),
                SizedBox(height: 16 * scaleFactorHeight),
                Text('No audio files found in this category.', style: TextStyle(
                    fontSize: 14 * scaleFactor * textScaleFactor,
                    color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
          16 * scaleFactor, 0, 16 * scaleFactor, 16 * scaleFactorHeight),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final file = filteredFiles[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 8 * scaleFactorHeight),
              child: _buildDraggableFileItem(
                  file, primaryColor, scaleFactor, scaleFactorHeight,
                  textScaleFactor),
            );
          },
          childCount: filteredFiles.length,
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState(Color primaryColor, double scaleFactor,
      double scaleFactorHeight, double textScaleFactor) {
    return Container(
      padding: EdgeInsets.all(32 * scaleFactor),
      margin: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scaleFactor),
        border: Border.all(color: Colors.red.shade200, width: 1 * scaleFactor),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 50 * scaleFactor, color: Colors.red),
            SizedBox(height: 16 * scaleFactorHeight),
            Text(
              'Storage Permission Required',
              style: TextStyle(
                fontSize: 16 * scaleFactor * textScaleFactor,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 8 * scaleFactorHeight),
            Text(
              'Please grant storage access to view and merge all local audio files on your device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13 * scaleFactor * textScaleFactor,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24 * scaleFactorHeight),
            ElevatedButton.icon(
              onPressed: () =>
                  _fetchLocalAudioFiles(forcePermissionCheck: true),
              icon: Icon(
                  Icons.security, size: 20 * scaleFactor, color: Colors.white),
              label: Text(
                'Grant Permission',
                style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor,
                    vertical: 12 * scaleFactorHeight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10 * scaleFactor)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFilesSection(double scaleFactor,
      double scaleFactorHeight, double textScaleFactor) {
    final selectedCount = selectedFiles.length;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final maxHeight = (screenHeight * 0.3).clamp(120.0, screenHeight * 0.35);

    return DragTarget<File>(
      onWillAccept: (data) =>
      data != null && !_isFileSelected(data) &&
          selectedCount < maxSelectionLimit,
      onAccept: (draggedFile) {
        _addFileToSelection(draggedFile);
        setState(() => isDragging = false);
      },
      onLeave: (data) => setState(() => isDragging = false),
      onMove: (details) => setState(() => isDragging = true),
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.all(12 * scaleFactor),
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: isDragging ? Colors.purple.shade50 : Colors.grey[200],
            borderRadius: BorderRadius.circular(16 * scaleFactor),
            border: Border.all(
                color: isDragging ? Colors.purple : Colors.grey[300]!,
                width: 1 * scaleFactor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    12 * scaleFactor, 10 * scaleFactorHeight, 12 * scaleFactor,
                    0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Selected Files ($selectedCount/$maxSelectionLimit)',
                        style: TextStyle(
                            fontSize: 13 * scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    if (selectedCount > 0)
                      GestureDetector(
                        onTap: _clearAllSelections,
                        child: Text('Clear All', style: TextStyle(fontSize: 13 *
                            scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 6 * scaleFactorHeight),
              Flexible(
                child: selectedCount == 0
                    ? Padding(
                  padding: EdgeInsets.all(12 * scaleFactor),
                  child: _buildEmptyState(
                      scaleFactor, scaleFactorHeight, textScaleFactor),
                )
                    : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      12 * scaleFactor, 0, 12 * scaleFactor,
                      10 * scaleFactorHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedFiles.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: 4 * scaleFactorHeight),
                    itemBuilder: (context, index) {
                      final file = selectedFiles[index];
                      return _buildDraggableSelectedFileItem(
                          file, index, scaleFactor, scaleFactorHeight,
                          textScaleFactor, key: ValueKey(file.path));
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(double scaleFactor, double scaleFactorHeight,
      double textScaleFactor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12 * scaleFactorHeight),
        child: Column(
          children: [
            Icon(isDragging ? Icons.arrow_downward_rounded : Icons
                .queue_music_outlined, size: 36 * scaleFactor,
                color: isDragging ? Colors.purple : Colors.grey[400]),
            SizedBox(height: 6 * scaleFactorHeight),
            Text(isDragging ? 'Drop file here' : 'No files selected',
                style: TextStyle(fontSize: 13 * scaleFactor * textScaleFactor,
                    fontWeight: FontWeight.w500,
                    color: isDragging ? Colors.purple : Colors.grey[700])),
            SizedBox(height: 3 * scaleFactorHeight),
            Text(isDragging
                ? 'Release to add file'
                : 'Hold to drag/Add files from the list below',
                style: TextStyle(fontSize: 11 * scaleFactor * textScaleFactor,
                    color: isDragging ? Colors.purple.shade300 : Colors
                        .grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileItem(File file, int displayIndex, double scaleFactor,
      double scaleFactorHeight, double textScaleFactor, {required Key key}) {
    final name = file.path
        .split('/')
        .last;
    final size = videoController.getFileSizeInMB(file.path);

    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(6 * scaleFactor),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(10 * scaleFactor)),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, color: Colors.grey[400],
              size: 16 * scaleFactor),
          SizedBox(width: 5 * scaleFactor),
          Container(
            width: 26 * scaleFactor,
            height: 26 * scaleFactor,
            decoration: const BoxDecoration(
                color: Color(0xFF6C63FF), shape: BoxShape.circle),
            child: Center(child: Text('${displayIndex + 1}', style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11 * scaleFactor * textScaleFactor))),
          ),
          SizedBox(width: 8 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortenFileName(name, max: 20), maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12 * scaleFactor * textScaleFactor,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                SizedBox(height: 1 * scaleFactorHeight),
                Text('${size.toStringAsFixed(2)} MB', style: TextStyle(
                    fontSize: 10 * scaleFactor * textScaleFactor,
                    color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
                Icons.close, color: Colors.white, size: 14 * scaleFactor),
            onPressed: () => _removeFileFromSelection(file),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const CircleBorder(),
              minimumSize: Size(22 * scaleFactor, 22 * scaleFactor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableSelectedFileItem(File file, int displayIndex,
      double scaleFactor, double scaleFactorHeight, double textScaleFactor,
      {required Key key}) {
    return LongPressDraggable<File>(
      key: key,
      data: file,
      feedback: Material(
        elevation: 8 * scaleFactor,
        borderRadius: BorderRadius.circular(10 * scaleFactor),
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width - (32 * scaleFactor),
          padding: EdgeInsets.all(6 * scaleFactor),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(10 * scaleFactor),
              border: Border.all(color: Colors.red, width: 1 * scaleFactor)),
          child: Row(
            children: [
              Icon(Icons.drag_indicator, color: Colors.grey[400],
                  size: 16 * scaleFactor),
              SizedBox(width: 5 * scaleFactor),
              Container(
                width: 26 * scaleFactor,
                height: 26 * scaleFactor,
                decoration: const BoxDecoration(
                    color: Color(0xFF6C63FF), shape: BoxShape.circle),
                child: Center(child: Text('${displayIndex + 1}',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11 * scaleFactor * textScaleFactor))),
              ),
              SizedBox(width: 8 * scaleFactor),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(shortenFileName(file.path
                        .split('/')
                        .last, max: 20), maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12 * scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                    SizedBox(height: 1 * scaleFactorHeight),
                    Text('${videoController
                        .getFileSizeInMB(file.path)
                        .toStringAsFixed(2)} MB', style: TextStyle(
                        fontSize: 10 * scaleFactor * textScaleFactor,
                        color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3,
          child: _buildSelectedFileItem(
              file, displayIndex, scaleFactor, scaleFactorHeight,
              textScaleFactor, key: ValueKey('${file.path}_dragging'))),
      onDragStarted: () => setState(() => isDraggingFromSelected = true),
      onDragEnd: (details) => setState(() => isDraggingFromSelected = false),
      child: _buildSelectedFileItem(
          file, displayIndex, scaleFactor, scaleFactorHeight, textScaleFactor,
          key: ValueKey('${file.path}_normal')),
    );
  }

  Widget _buildDraggableFileItem(File mp3File, Color primaryColor,
      double scaleFactor, double scaleFactorHeight, double textScaleFactor) {
    final name = mp3File.path
        .split('/')
        .last;
    final size = videoController.getFileSizeInMB(mp3File.path);

    return LongPressDraggable<File>(
      data: mp3File,
      feedback: Material(
        elevation: 8 * scaleFactor,
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width - (32 * scaleFactor),
          padding: EdgeInsets.all(12 * scaleFactor),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12 * scaleFactor),
              border: Border.all(color: primaryColor, width: 2 * scaleFactor)),
          child: Row(
            children: [
              Container(
                width: 48 * scaleFactor,
                height: 48 * scaleFactor,
                decoration: BoxDecoration(color: primaryColor,
                    borderRadius: BorderRadius.circular(12 * scaleFactor)),
                child: Icon(Icons.audio_file, color: Colors.white,
                    size: 24 * scaleFactor),
              ),
              SizedBox(width: 12 * scaleFactor),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(shortenFileName(name, max: 20), maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14 * scaleFactor * textScaleFactor,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                    SizedBox(height: 4 * scaleFactorHeight),
                    Text('${size.toStringAsFixed(2)} MB', style: TextStyle(
                        fontSize: 12 * scaleFactor * textScaleFactor,
                        color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3,
          child: _buildAvailableFileItem(
              mp3File, primaryColor, scaleFactor, scaleFactorHeight,
              textScaleFactor)),
      onDragStarted: () => setState(() => isDragging = true),
      onDragEnd: (details) => setState(() => isDragging = false),
      child: _buildAvailableFileItem(
          mp3File, primaryColor, scaleFactor, scaleFactorHeight,
          textScaleFactor),
    );
  }

  Widget _buildAvailableFileItem(File mp3File, Color primaryColor,
      double scaleFactor, double scaleFactorHeight, double textScaleFactor) {
    final name = mp3File.path
        .split('/')
        .last;
    final size = videoController.getFileSizeInMB(mp3File.path);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(12 * scaleFactor),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          border: Border.all(color: Colors.grey[300]!, width: 1 * scaleFactor)),
      child: Row(
        children: [
          Container(
            width: 48 * scaleFactor,
            height: 48 * scaleFactor,
            decoration: BoxDecoration(color: primaryColor,
                borderRadius: BorderRadius.circular(12 * scaleFactor)),
            child: Icon(
                Icons.audio_file, color: Colors.white, size: 24 * scaleFactor),
          ),
          SizedBox(width: 12 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortenFileName(name, max: 20), maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14 * scaleFactor * textScaleFactor,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
                SizedBox(height: 4 * scaleFactorHeight),
                Text('${size.toStringAsFixed(2)} MB', style: TextStyle(
                    fontSize: 12 * scaleFactor * textScaleFactor,
                    color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            width: 32 * scaleFactor,
            height: 32 * scaleFactor,
            decoration: const BoxDecoration(
                color: Color(0xFF6C63FF), shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(
                  Icons.add, color: Colors.white, size: 18 * scaleFactor),
              padding: EdgeInsets.zero,
              onPressed: () => _addFileToSelection(mp3File),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergeButton(Color primaryColor, double scaleFactor,
      double scaleFactorHeight, double textScaleFactor) {
    return Obx(() {
      final selectedCount = selectedFiles.length;
      final isProcessing = controller.isMerging.value;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16 * scaleFactor),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 10 * scaleFactor,
                offset: Offset(0, -2 * scaleFactorHeight))
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isProcessing ? Colors.black : primaryColor,
            padding: EdgeInsets.symmetric(vertical: 14 * scaleFactorHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scaleFactor)),
            elevation: 0,
          ),
          onPressed: isProcessing ? null : _handleMerge,
          child: isProcessing
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20 * scaleFactor,
                  width: 20 * scaleFactor,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2 * scaleFactor)),
              SizedBox(width: 12 * scaleFactor),
              Text('Merging $selectedCount Files...', style: TextStyle(
                  fontSize: 16 * scaleFactor * textScaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.merge_type, size: 20 * scaleFactor,
                  color: Colors.white),
              SizedBox(width: 8 * scaleFactor),
              Text('Merge $selectedCount Files', style: TextStyle(
                  fontSize: 16 * scaleFactor * textScaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDeleteBin(double scaleFactor, double scaleFactorHeight,
      double textScaleFactor) {
    return DragTarget<File>(
      onWillAccept: (data) => data != null && _isFileSelected(data),
      onAccept: (draggedFile) {
        _removeFileFromSelection(draggedFile);
        setState(() => isDraggingFromSelected = false);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.all(20 * scaleFactor),
          decoration: BoxDecoration(
            color: isHovering ? Colors.red.shade100 : Colors.red.shade50,
            border: Border(top: BorderSide(
                color: isHovering ? Colors.red : Colors.red.shade200,
                width: 1 * scaleFactor)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isHovering ? Icons.delete : Icons.delete_outline,
                  color: Colors.red, size: 35 * scaleFactor),
              SizedBox(height: 8 * scaleFactorHeight),
              Text(isHovering ? 'Release to Remove' : 'Drag here to remove',
                  style: TextStyle(color: Colors.red.shade700,
                      fontSize: 14 * scaleFactor * textScaleFactor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleMerge() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      _showNoInternetDialog();
    } else {
      _showRenameDialog(context, selectedFiles);
    }
  }

  void _showNoInternetDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text(
            'It seems you are not connected to the internet. Please check your network settings.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK'))
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showRenameDialog(BuildContext context, List<File> filesToMerge) {
    String fullDefaultName = filesToMerge.map((e) =>
    e.path
        .split('/')
        .last
        .split('.')
        .first).join('_');
    String defaultName = fullDefaultName.length > 20 ? fullDefaultName
        .substring(0, 20) : fullDefaultName;

    fileName = defaultName;
    final textController = TextEditingController(text: defaultName);
    final responsive = ResponsiveHelper(context);

    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double textScaleFactor = mediaQuery.textScaleFactor;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scaleFactor),
          ),
          contentPadding: EdgeInsets.all(20 * scaleFactor),
          title: Text(
            "Merge Files",
            style: TextStyle(
              fontSize: 18 * scaleFactor * textScaleFactor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width * 0.8,
            child: TextField(
              autofocus: true,
              controller: textController,
              maxLength: 20,
              style: TextStyle(fontSize: 16 * scaleFactor * textScaleFactor),
              decoration: InputDecoration(
                labelText: "File Name",
                labelStyle: TextStyle(
                    fontSize: 14 * scaleFactor * textScaleFactor),
                hintText: "Enter new file name",
                hintStyle: TextStyle(
                    fontSize: 14 * scaleFactor * textScaleFactor),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12 * scaleFactor,
                  vertical: 12 * scaleFactor,
                ),
              ),
              onChanged: (value) =>
              fileName = value.trim().replaceAll(RegExp(r'[^\w\d_-]'), ''),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scaleFactor,
                  vertical: 12 * scaleFactor,
                ),
              ),
              child: Text(
                  "Cancel", style: TextStyle(fontSize: responsive.fs(14))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scaleFactor,
                  vertical: 12 * scaleFactor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scaleFactor),
                ),
              ),
              onPressed: () => _executeMerge(ctx, filesToMerge),
              child: Text("Merge", style: TextStyle(
                  color: Colors.white, fontSize: responsive.fs(14))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeMerge(BuildContext ctx, List<File> filesToMerge) async {
    fileName = fileName.endsWith('.mp3') ? fileName : '$fileName.mp3';
    Navigator.of(ctx).pop();

    try {
      controller.isMerging.value = true;
      controller.wasCancelled.value = false; // ✅ Reset at start

      final filePaths = filesToMerge.map((e) => e.path).toList();
      final mergedPath = await controller.mergeAudioFiles(filePaths, fileName);

      // ✅ Check if merge was cancelled
      if (controller.wasCancelled.value) {
        print('Merge was cancelled by user');
        toastFlutter(
          toastmessage: 'Merge cancelled',
          color: Colors.red,
        );
        return; // Exit without navigating
      }

      // ✅ Check if merge was successful
      if (mergedPath.isNotEmpty) {
        final musicDir = Directory('/storage/emulated/0/Music/MergedAudio');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        final newPath = '${musicDir.path}/$fileName';
        final newFile = await File(mergedPath).copy(newPath);

        controller.isMerging.value = false;
        toastFlutter(
          toastmessage: 'Audio merged and saved to Music folder!',
          color: Colors.green,
        );

        // ✅ Navigate to AudioSavedScreen on success
        Get.off(() =>
            AudioSavedScreen(
              fileName: fileName,
              audioPath: newFile.path,
              bitrate: '',
            ));
      } else {
        controller.isMerging.value = false;
        toastFlutter(
          toastmessage: 'Merging failed, try again.',
          color: Colors.red,
        );
      }
    } catch (e) {
      controller.isMerging.value = false;
      toastFlutter(
        toastmessage: 'An error occurred: $e',
        color: Colors.red,
      );
    }
  }
}