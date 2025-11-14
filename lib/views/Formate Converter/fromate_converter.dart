import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Assuming these imports lead to your respective controllers and pages
import '../../controllers/merge_controller.dart';
import '../../controllers/fromate_audio_controller.dart';
import '../../controllers/video_controller.dart';
import '../../utils/resources.dart';
import 'progess_page.dart';
// Import the reusable utility files
import '../../utils/search_filter_bar.dart';
import 'package:video_to_audio_converter/utils/utils.dart'; // For toastFlutter

// NOTE: In a real app, you would need to import and use a package like 'permission_handler'
// import 'package:permission_handler/permission_handler.dart';

class FormateMain extends StatefulWidget {
  const FormateMain({super.key});

  @override
  State<FormateMain> createState() => _FormateMainState();
}

class _FormateMainState extends State<FormateMain> {
  final MergeAudioController mergeController = Get.put(MergeAudioController());
  final FormateAudioController formateController = Get.put(FormateAudioController());
  final VideoController videoController = Get.put(VideoController());

  // --- STATE FOR SEARCH/FILTER & LOCAL ---
  String _searchQuery = '';
  int _selectedTabIndex = 0; // 0=All, 1=Extracted, 2=Merged, 3=Converted, 4=Local
  bool _isFetchingFiles = true; // For initial app-file load

  // Local File Logic
  bool _isFetchingLocalFiles = false;
  bool _localMusicPermissionGranted = false;
  List<File> localMusicFiles = []; // List for all local files

  // App-specific file lists
  List<File> videoMusicFiles = [];
  List<File> mergedAudioFiles = [];
  List<File> formatConverterAudioFiles = [];

  static const int maxSelectionLimit = 5;

  // --- START NEW LOGIC: Permission Handling (SIMULATED) ---
  Future<bool> _requestStoragePermission() async {
    // ----------------------------------------------------------------------
    // !!! IMPORTANT: Replace this with actual permission handling logic in a real app.
    // E.g., using permission_handler:
    /*
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    // ... logic for permanently denied
    return false;
    */
    // ----------------------------------------------------------------------

    // For this demonstration, we simulate permission being granted after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
  // --- END NEW LOGIC: Permission Handling (SIMULATED) ---

  @override
  void initState() {
    super.initState();
    _fetchAllAppAudioFiles();

    // Set default format to MP3
    if (formateController.selectedFormat.value.isEmpty) {
      formateController.updateSelectedFormat('MP3');
    }
  }

  // File Fetching Logic (App Files ONLY)
  Future<void> _fetchAllAppAudioFiles() async {
    setState(() {
      _isFetchingFiles = true;
    });

    await Future.wait([
      _fetchFilesFromDirectory('/storage/emulated/0/Music/VideoMusic', videoMusicFiles),
      _fetchFilesFromDirectory('/storage/emulated/0/Music/MergedAudio', mergedAudioFiles),
      _fetchFilesFromDirectory('/storage/emulated/0/Music/Format Converter', formatConverterAudioFiles),
    ]);

    // Update the proxy selection list based on the new file set
    _updateSelectionProxyList();

    setState(() {
      _isFetchingFiles = false;
    });
  }

  Future<void> _fetchFilesFromDirectory(String directoryPath, List<File> targetList) async {
    targetList.clear();
    Directory dir = Directory(directoryPath);
    if (await dir.exists()) {
      List<File> files = dir
          .listSync()
          .where(
            (item) => !item.path.contains(".pending-")
      )
          .map((item) => File(item.path))
          .toList();
      targetList.addAll(files);
    }
  }

  // --- NEW LOGIC: Fetching ALL local audio with permission check and exclusion ---
  Future<void> _fetchLocalAudioFiles({bool forcePermissionCheck = false}) async {
    if (mounted) {
      setState(() {
        _isFetchingLocalFiles = true;
      });
    }

    if (!_localMusicPermissionGranted || forcePermissionCheck) {
      final isGranted = await _requestStoragePermission();

      if (mounted) {
        setState(() {
          _localMusicPermissionGranted = isGranted;
        });
      }

      if (!isGranted) {
        localMusicFiles = []; // Clear list if permission denied
        if (mounted) {
          setState(() {
            _isFetchingLocalFiles = false;
          });
        }
        _updateSelectionProxyList();
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

    // Define app directories to exclude (in lower case for case-insensitive check)
    final appDirs = [
      '/storage/emulated/0/Music/VideoMusic',
      '/storage/emulated/0/Music/MergedAudio',
      '/storage/emulated/0/Music/Format Converter',
    ].map((path) => path.toLowerCase()).toSet();

    // Define directories to search for all user audio files
    final directoriesToSearch = [
      Directory('/storage/emulated/0/Music'),
      Directory('/storage/emulated/0/Download'),
      Directory('/storage/emulated/0/Audio'),
    ];

    List<File> files = [];
    for (var searchDir in directoriesToSearch) {
      if (await searchDir.exists()) {
        await for (var entity in searchDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if ((path.endsWith('.mp3') || path.endsWith('.m4a') || path.endsWith('.wav') || path.endsWith('.aac')|| path.endsWith('.flac') ||   // Added
                path.endsWith('.ogg')) &&
                !appDirs.any((appDir) => path.contains(appDir))) { // Use .contains for nested folders
              files.add(entity);
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        localMusicFiles = files;
        _isFetchingLocalFiles = false;
      });
    }
    _updateSelectionProxyList();
  }
  // --- END NEW LOGIC ---

  // Helper to ensure mergeController.selectedItems list matches the combined file list length
  void _updateSelectionProxyList() {
    final allFiles = _getCurrentFiles(index: 0); // Get all app files
    final localFiles = _getCurrentFiles(index: 4); // Get all local files

    // Combine all unique file paths across all possible tabs
    final allPossibleFiles = <File>{...allFiles, ...localFiles}.toList();

    // Create a new selection list, preserving existing selections by checking file path
    final newSelectedItems = List<bool>.generate(allPossibleFiles.length, (index) {
      return formateController.selectedFiles.contains(allPossibleFiles[index].path);
    }).obs;

    // We must use a list that represents the currently visible files for the UI list.
    // This is a proxy list that maps to the filtered list. Since the original implementation
    // used a GetX list in mergeController, we will let that list be managed externally
    // by the selection logic, and only ensure it is initialized once on startup/refetch.
    // For now, we only need to ensure the local list is populated for the tab logic.
  }


  // Helper to get files for the currently selected tab
  List<File> _getCurrentFiles({int? index}) {
    final targetIndex = index ?? _selectedTabIndex;
    switch (targetIndex) {
      case 0: return [...videoMusicFiles, ...mergedAudioFiles, ...formatConverterAudioFiles]; // All (App)
      case 1: return videoMusicFiles; // Extracted
      case 2: return mergedAudioFiles; // Merged
      case 3: return formatConverterAudioFiles; // Converted
      case 4: return localMusicFiles; // Local Music (External)
      default: return [];
    }
  }

  // --- NEW LOGIC: Tab Selection Handler ---
  void _handleTabSelected(int index) {
    if (index != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = index;
      });
    }

    // Check if the newly selected tab is 'Local Music' (index 4)
    if (index == 4) {
      _fetchLocalAudioFiles(forcePermissionCheck: true);
    }
  }
  // --- END NEW LOGIC ---

  int getSelectedCount() {
    return formateController.selectedFiles.length; // Use the actual list for the count
  }

  bool _isFileSelected(File file) => formateController.selectedFiles.contains(file.path);

  void _handleFileSelection(File file, bool? isSelected) {
    int selectedCount = getSelectedCount();

    if (isSelected == true) {
      if (selectedCount < maxSelectionLimit) {
        formateController.addFile(file.path);
      } else {
        toastFlutter(
          toastmessage: "You can only select up to $maxSelectionLimit files at a time",
          color: Colors.orange,
        );
      }
    } else {
      formateController.removeFile(file.path);
    }
  }

  @override
  void dispose() {
    mergeController.removeAll();
    formateController.selectedFiles.clear();
    formateController.fileProgress.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const double referenceWidth = 375.0;
    const double referenceHeight = 812.0;
    final double scaleFactor = mediaQuery.size.width / referenceWidth;
    final double scaleFactorHeight = mediaQuery.size.height / referenceHeight;
    final double textScaleFactor = mediaQuery.textScaleFactor;
    const primaryColor = Color(0xFF6C63FF);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24 * scaleFactor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Format Converter",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 18 * scaleFactor * textScaleFactor,
              ),
            ),
            Obx(() {
              int selectedCount = getSelectedCount();
              return Text(
                selectedCount > 0
                    ? "$selectedCount/$maxSelectionLimit selected"
                    : "Select files to convert (max $maxSelectionLimit)",
                style: TextStyle(
                  fontSize: 12 * scaleFactor * textScaleFactor,
                  color: selectedCount >= maxSelectionLimit
                      ? Colors.orange[700]
                      : Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              );
            }),
          ],
        ),
      ),
      body: _isFetchingFiles
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- START: MOVED OUTPUT FORMAT SECTION ---
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20 * scaleFactor),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Output Format",
                  style: TextStyle(
                    fontSize: 16 * scaleFactor * textScaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16 * scaleFactorHeight),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12 * scaleFactorHeight,
                  crossAxisSpacing: 12 * scaleFactor,
                  childAspectRatio: 1.2,
                  children: [
                    _buildFormatBox('MP3', 'Most compatible', 'MP3', primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
                    _buildFormatBox('WAV', 'Lossless quality', 'WAV', primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
                    _buildFormatBox('AAC', 'High quality', 'AAC', primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
                    _buildFormatBox('M4A', 'Apple devices', 'M4A', primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
                    _buildFormatBox('FLAC', 'Lossless compression', 'FLAC', primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
                    _buildFormatBox('OGG', 'Open format', 'OGG', primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
                  ],
                ),
              ],
            ),
          ),
          // --- END: MOVED OUTPUT FORMAT SECTION ---

          Expanded(
            child: CustomScrollView(
              slivers: [
                // --- REUSABLE SEARCH BAR WIDGET ---
                SliverToBoxAdapter(
                  child: buildGenericSearchBar(
                    scaleFactor: scaleFactor,
                    textScaleFactor: textScaleFactor,
                    onSearchQueryChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                    hintText: 'Search audio files...',
                  ),
                ),

                // --- REUSABLE FILTER TABS WIDGET ---
                SliverToBoxAdapter(
                  child: buildGenericFilterTabs(
                    scaleFactor: scaleFactor,
                    scaleFactorHeight: scaleFactorHeight,
                    textScaleFactor: textScaleFactor,
                    selectedTabIndex: _selectedTabIndex,
                    onTabSelected: _handleTabSelected, // Use the new handler
                    tabLabels: const ['All', 'Extracted', 'Merged', 'Converted', 'Local'],
                  ),
                ),

                // Select Files Section Header
                if (!(_selectedTabIndex == 4 && !_localMusicPermissionGranted))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16 * scaleFactor, 4 * scaleFactorHeight, 16 * scaleFactor, 12 * scaleFactorHeight),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Available Files",
                            style: TextStyle(
                              fontSize: 16 * scaleFactor * textScaleFactor,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Obx(() {
                            int selectedCount = getSelectedCount();
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor, vertical: 6 * scaleFactorHeight),
                              decoration: BoxDecoration(
                                color: selectedCount >= maxSelectionLimit
                                    ? Colors.orange[50]
                                    : primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20 * scaleFactor),
                              ),
                              child: Text(
                                "$selectedCount/$maxSelectionLimit",
                                style: TextStyle(
                                  color: selectedCount >= maxSelectionLimit
                                      ? Colors.orange[700]
                                      : primaryColor,
                                  fontSize: 14 * scaleFactor * textScaleFactor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                // Audio Files List
                _buildFilesList(primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
              ],
            ),
          ),

          // Convert Button
          _buildConvertButton(primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
        ],
      ),
    );
  }

  Widget _buildFilesList(Color primaryColor, double scaleFactor, double scaleFactorHeight, double textScaleFactor) {

    // --- NEW LOGIC: Handle Local Tab Loading and Permission Denied ---
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
                Text('Scanning local audio files...', style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor, color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      );
    }

    if (_selectedTabIndex == 4 && !_localMusicPermissionGranted) {
      return SliverToBoxAdapter(
        child: _buildPermissionDeniedState(primaryColor, scaleFactor, scaleFactorHeight, textScaleFactor),
      );
    }
    // --- END NEW LOGIC ---

    final currentFiles = _getCurrentFiles();
    final lowerCaseQuery = _searchQuery.toLowerCase();

    final filteredFiles = currentFiles.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(lowerCaseQuery);
    }).toList();

    if (filteredFiles.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: Colors.grey[100],
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40.0 * scaleFactor),
              child: Column(
                children: [
                  Icon(Icons.audio_file, size: 64 * scaleFactor, color: Colors.grey[400]),
                  SizedBox(height: 16 * scaleFactorHeight),
                  Text(
                    _searchQuery.isNotEmpty ? "No matching files found" : "No audio files ",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16 * scaleFactor * textScaleFactor),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.only(bottom: 16 * scaleFactorHeight),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            File file = filteredFiles[index];
            String fileName = file.path.split('/').last;
            double fileSize = videoController.getFileSizeInMB(file.path);

            return Obx(() {
              bool isSelected = _isFileSelected(file);
              int selectedCount = getSelectedCount();
              bool isLimitReached = selectedCount >= maxSelectionLimit && !isSelected;

              return Opacity(
                opacity: isLimitReached ? 0.5 : 1.0,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16 * scaleFactor, vertical: 6 * scaleFactorHeight),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[300]!,
                      width: isSelected ? 1.5 * scaleFactor : 1 * scaleFactor,
                    ),
                    borderRadius: BorderRadius.circular(12 * scaleFactor),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor, vertical: 1 * scaleFactorHeight),
                    leading: Container(
                      width: 48 * scaleFactor,
                      height: 48 * scaleFactor,
                      decoration: BoxDecoration(
                        color: isLimitReached ? Colors.grey[400] : primaryColor,
                        borderRadius: BorderRadius.circular(10 * scaleFactor),
                      ),
                      child: Icon(
                        Icons.audio_file,
                        color: Colors.white,
                        size: 28 * scaleFactor,
                      ),
                    ),
                    title: Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14 * scaleFactor * textScaleFactor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isLimitReached ? Colors.grey[500] : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      "${fileSize.toStringAsFixed(2)} MB",
                      style: TextStyle(
                        fontSize: 12 * scaleFactor * textScaleFactor,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Transform.scale(
                      scale: scaleFactor, // Scale the checkbox itself
                      child: Checkbox(
                        value: isSelected,
                        activeColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4 * scaleFactor),
                        ),
                        onChanged: isLimitReached
                            ? null
                            : (value) {
                          _handleFileSelection(file, value);
                        },
                      ),
                    ),
                  ),
                ),
              );
            });
          },
          childCount: filteredFiles.length,
        ),
      ),
    );
  }

  // --- NEW WIDGET: Permission Denied State ---
  Widget _buildPermissionDeniedState(Color primaryColor, double scaleFactor, double scaleFactorHeight, double textScaleFactor) {
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
              'Please grant storage access to view and convert all local audio files on your device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13 * scaleFactor * textScaleFactor,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24 * scaleFactorHeight),
            ElevatedButton.icon(
              onPressed: () => _fetchLocalAudioFiles(forcePermissionCheck: true), // Re-request permission
              icon: Icon(Icons.security, size: 20 * scaleFactor, color: Colors.white),
              label: Text(
                'Grant Permission',
                style: TextStyle(fontSize: 14 * scaleFactor * textScaleFactor, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor, vertical: 12 * scaleFactorHeight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scaleFactor)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- END NEW WIDGET ---

  Widget _buildConvertButton(Color primaryColor, double scaleFactor, double scaleFactorHeight, double textScaleFactor) {
    return Obx(() {
      int selectedCount = getSelectedCount();
      if (selectedCount == 0) return const SizedBox.shrink();

      String formatText = formateController.selectedFormat.value.isNotEmpty
          ? formateController.selectedFormat.value
          : 'MP3';

      return Container(
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: Size(double.infinity, 50 * scaleFactorHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scaleFactor),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              if (formateController.selectedFiles.isEmpty ||
                  formateController.selectedFormat.isEmpty) {
                Get.snackbar(
                  "Error",
                  "Please select at least 1 file & format",
                  backgroundColor: Colors.red[100],
                  colorText: Colors.red[900],
                  snackPosition: SnackPosition.BOTTOM,
                  margin: EdgeInsets.all(16 * scaleFactor),
                );
                return;
              }

              // Reset fileProgress ONLY
              formateController.fileProgress.clear();
              for (int i = 0; i < formateController.selectedFiles.length; i++) {
                formateController.fileProgress.add(0.0.obs);
              }

              // Navigate to progress page
              await Get.to(() => const ConversionProgressPage());

              // Reset after back
              mergeController.removeAll();
              formateController.selectedFiles.clear();
              formateController.selectedFormat.value = 'MP3';
              formateController.fileProgress.clear();
              formateController.isConverting.value = false;
              // Re-fetch files for the active tab only
              if (_selectedTabIndex == 4) {
                await _fetchLocalAudioFiles();
              } else {
                await _fetchAllAppAudioFiles();
              }
            },
            child: Text(
              "Convert $selectedCount ${selectedCount == 1 ? 'file' : 'files'} to $formatText",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16 * scaleFactor * textScaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFormatBox(String format, String description, String value, Color primaryColor, double scaleFactor, double scaleFactorHeight, double textScaleFactor) {
    return Obx(() {
      bool isSelected = formateController.selectedFormat.value == value;

      return InkWell(
        onTap: () {
          formateController.updateSelectedFormat(value);
        },
        borderRadius: BorderRadius.circular(12 * scaleFactor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey[50],
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 * scaleFactor : 1 * scaleFactor,
            ),
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8 * scaleFactor,
                offset: Offset(0, 2 * scaleFactor),
              ),
            ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                format,
                style: TextStyle(
                  fontSize: 16 * scaleFactor * textScaleFactor,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 4 * scaleFactorHeight),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * scaleFactor),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 10 * scaleFactor * textScaleFactor,
                    color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}