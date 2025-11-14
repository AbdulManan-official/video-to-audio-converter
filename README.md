Video to Audio Converter (Flutter)

A modern Flutter media converter app that allows you to extract, convert, merge, and manage audio from your videos. Built with FFmpegKit and optimized for modern Android devices, the app combines powerful audio processing with a clean, responsive, and user-friendly interface.

🚀 Key Features
🎬 Video to Audio Conversion

Convert any video on your device into high-quality audio formats such as MP3, AAC, M4A, WAV, and more.

🔊 Audio Format Conversion

Convert audio files between multiple formats with customizable bitrate and quality.

🎵 Ringtone Maker & Setter

Trim and set converted audio files as default ringtone, notification tone, or alarm tone directly within the app.

🎚️ Merge Audio Files

Combine multiple audio files into a single track using FFmpeg merge commands.

📂 Media Picker Support

Pick videos or audio files directly from your gallery or file manager.

🧠 Smart Local File Management

All converted, merged, or trimmed files are stored locally with organized naming, sorting, and sharing options.

📱 Modern & Responsive UI

Fully responsive Flutter UI for all device sizes.

Clean design with progress indicators, animations, and error handling.

🧩 Plugin Integration

ffmpeg_kit_flutter_new – for media conversion

permission_handler – for runtime permissions

file_picker / video_player – for media selection

path_provider – for local storage

ringtone_set_mul – for setting ringtones

🛠️ Tech Stack
Component	Technology
Framework	Flutter (Dart)
Audio/Video Processing	FFmpegKit Flutter
File Management	path_provider, file_picker
UI	Material Design, Custom Widgets
Platform	Android (SDK 21+)
⚙️ Setup & Installation

Clone the repository

git clone https://github.com/AbdulManan-official/video-to-audio-converter
cd video-to-audio-converter


Install dependencies

flutter pub get


Run in debug mode

flutter run


Build release APK

flutter build apk --release


⚠️ If using minification, configure proguard-rules.pro to prevent FFmpeg and plugin stripping.

📂 Project Structure
video_to_audio_converter/
├─ lib/
│  ├─ controllers/       # State management & logic
│  ├─ models/            # Data models
│  ├─ utils/             # Helper functions & utilities
│  ├─ views/             # Screens & UI
│  │  ├─ Formate Converter/
│  │  ├─ Merge_Audio/
│  │  └─ Ringtone/
│  └─ main.dart          # App entry point
├─ ios/
├─ android/
├─ plugins/              # Custom ringtone plugin
└─ pubspec.yaml

🧩 Core Functionalities Explained
🎬 Extract Audio from Video

FFmpeg command:

-i input_video.mp4 -vn -acodec mp3 output_audio.mp3

🔊 Convert Audio Format
-i input.wav -acodec mp3 output.mp3

🎚️ Merge Multiple Audio Files
-i "concat:track1.mp3|track2.mp3|track3.mp3" -acodec copy output.mp3

🎵 Set Ringtone

After conversion:

RingtoneSet.setRingtone(path);

🧠 Permissions Required

READ_EXTERNAL_STORAGE

WRITE_EXTERNAL_STORAGE

MANAGE_EXTERNAL_STORAGE (Android 11+)

SET_RINGTONE

Handle permissions using permission_handler and declare them in AndroidManifest.xml.

💡 Future Improvements

Waveform visualization during audio trimming

Playback preview before saving

Background conversion tasks



Abdul Manan
📍 Sialkot, Pakistan
📧 abdullmanan7777@gmail.com
