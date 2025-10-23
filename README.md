🎵 Video to Audio Converter App (Flutter)

A Flutter-powered media converter app that lets you easily extract, convert, and manage audio from your videos.
Built with FFmpegKit and designed for modern Android devices, the app delivers powerful audio processing in a simple and clean interface.

🚀 Features

✅ 🎬 Video to Audio Conversion
Convert any video from your device into high-quality audio files (MP3, AAC, M4A, WAV, etc.).

✅ 🔊 Audio Format Converter
Easily convert audio files between multiple formats with customizable bitrate and quality options.

✅ 🎵 Ringtone Maker & Setter
Trim and set your converted audio as your default ringtone, notification tone, or alarm tone directly from the app.

✅ 🎚️ Merge Audio Files
Combine multiple audio files into one seamlessly using FFmpeg merge commands.

✅ 📂 Media Picker Support
Pick videos or audio files directly from your device gallery or file manager.

✅ 🧠 Smart File Handling
All converted or merged files are stored locally with organized naming and easy sharing options.

✅ 📱 Modern UI
Clean, minimal Flutter UI with responsive design, progress indicators, and error handling.

✅ 🧩 Plugin Integration

ffmpeg_kit_flutter_full for media conversion

permission_handler for runtime permissions

file_picker or image_picker for media selection

path_provider for local storage

ringtone_set_mul for setting ringtones

🛠️ Tech Stack
Component	Technology
Framework	Flutter (Dart)
Video/Audio Processing	FFmpegKit Flutter
File Management	path_provider, file_picker
UI	Material Design, Custom Widgets
Platform	Android (SDK 21+)
⚙️ Setup & Installation
1. Clone the Repository
git clone https://github.com/yourusername/video-to-audio-converter.git
cd video-to-audio-converter

2. Install Dependencies
flutter pub get

3. Run in Debug Mode
flutter run

4. Build Release APK
flutter build apk --release


⚠️ If using minification, make sure to configure proguard-rules.pro properly to prevent FFmpeg and plugin stripping.

📂 Folder Structure
lib/
 ├── main.dart
 ├── screens/
 │    ├── home_screen.dart
 │    ├── converter_screen.dart
 │    ├── merge_screen.dart
 │    ├── ringtone_screen.dart
 ├── widgets/
 │    ├── custom_button.dart
 │    ├── progress_dialog.dart
 ├── utils/
 │    ├── ffmpeg_helper.dart
 │    ├── file_utils.dart
assets/
 ├── icons/
 ├── sounds/
android/
 ├── app/
 │    ├── proguard-rules.pro

🧩 Core Functionalities Explained
🎬 Extract Audio from Video

Uses FFmpeg command:

-i input_video.mp4 -vn -acodec mp3 output_audio.mp3

🔊 Convert Audio Format

Convert from one format to another (e.g. WAV → MP3):

-i input.wav -acodec mp3 output.mp3

🎚️ Merge Multiple Audio Files

Merge two or more files seamlessly:

-i "concat:track1.mp3|track2.mp3" -acodec copy output.mp3

🎵 Set Ringtone

After conversion, user can set ringtone using ringtone_set_mul plugin:

RingtoneSet.setRingtone(path);

🧠 Permissions Required

READ_EXTERNAL_STORAGE

WRITE_EXTERNAL_STORAGE

MANAGE_EXTERNAL_STORAGE (if targeting Android 11+)

SET_RINGTONE

Add these in AndroidManifest.xml and handle them using permission_handler.

💡 Future Improvements

Add waveform visualization during trimming.

Add playback controls for preview before saving.

Add support for background conversion tasks.

Implement theme toggle (light/dark).

🧾 License

This project is open-source and available under the MIT License.
Feel free to modify, enhance, and distribute with proper credit.

👨‍💻 Author

Abdul Manan
📍 Sialkot, Pakistan
📧 abdullmanan7777@gmail.com

💼 LinkedIn

🏷️ Crafted with ❤️ by Unitech Forge — “Crafting Smart Tech & Creative Solutions.”
