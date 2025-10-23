import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

class AudioMergeUtils {
  /// Merge 2 MP3 audio files locally using FFmpeg
  /// Returns the path of the merged file or empty string on error
  static Future<String> mergeTwoFiles(String file1, String file2, String outputFileName) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String outputPath = "${appDocDir.path}/$outputFileName";

      final String ffmpegCommand =
          '-y -i "$file1" -i "$file2" -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1[out]" -map "[out]" "$outputPath"';

      print("[AudioMergeUtils] FFmpeg Command: $ffmpegCommand");

      await FFmpegKit.execute(ffmpegCommand);

      final mergedFile = File(outputPath);
      if (mergedFile.existsSync()) {
        print("[AudioMergeUtils] Merged file created at: $outputPath");
        return outputPath;
      } else {
        print("[AudioMergeUtils] Error: Merged file not created");
        return '';
      }
    } catch (e) {
      print("[AudioMergeUtils] Exception: $e");
      return '';
    }
  }
}
