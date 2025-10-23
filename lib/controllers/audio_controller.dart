import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class AudioController extends GetxController {
  late AudioPlayer audioPlayer;
  var duration = Duration.zero.obs; // Total duration of the audio
  var position = Duration.zero.obs; // Current position of the audio
  var isPlaying = false.obs; // Track if audio is playing
  var audioPath = ''.obs;

  @override
  void onInit() {
    audioPlayer = AudioPlayer();
    super.onInit();
  }

  // Initialize the audio file and listen to position updates
  Future<void> initAudio(String path) async {
    try {
      await audioPlayer.setFilePath(path);
      duration.value = audioPlayer.duration ?? Duration.zero;

      // Listen to position updates
      audioPlayer.positionStream.listen((pos) {
        position.value = pos;
      });
    } catch (e) {
      // Handle errors
      print("Error loading audio: $e");
    }
  }

  // Toggle play/pause
  void togglePlayback() {
    if (isPlaying.value) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
    isPlaying.value = !isPlaying.value;
  }

  // Seek to a specific position
  void seek(double value) {
    audioPlayer.seek(Duration(seconds: value.toInt()));
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }
}
