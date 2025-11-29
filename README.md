# 🎧 Video to Audio Converter Max (Flutter)

A modern and powerful **Flutter media converter app** that allows users to extract, convert, merge, and manage audio files directly from their videos. Built using **FFmpegKit**, optimized for Android, and designed with a clean and responsive interface.

## 🚀 Features

### 🎬 Video to Audio Conversion

Convert any video into high-quality audio formats like **MP3, AAC, M4A, WAV**, and more.

### 🔊 Audio Format Converter

Convert audio between multiple formats with customizable **bitrate, codec, and quality**.

### 🎵 Ringtone Maker & Setter

Trim audio and set it as:

* Default ringtone
* Notification tone
* Alarm tone

### 🎚️ Merge Multiple Audio Files

Combine multiple audio tracks into a single file using FFmpeg merge commands.

### 📂 Media Picker

Pick videos or audio directly from **Gallery** or **File Manager**.

### 🧠 Smart Local File Management

* Auto-saving converted files
* Rename, delete, and share
* Organized sorting

### 📱 Modern UI

* Responsive design
* Smooth animations
* Progress & error handling

### 🧩 Plugins Used

* `ffmpeg_kit_flutter_new`
* `permission_handler`
* `file_picker`
* `video_player`
* `path_provider`
* `ringtone_set_mul`

## 🛠️ Tech Stack

| Component        | Technology                       |
| ---------------- | -------------------------------- |
| Framework        | Flutter (Dart)                   |
| Media Processing | FFmpegKit Flutter                |
| File Management  | path_provider, file_picker       |
| UI               | Material Design + Custom Widgets |
| Platform         | Android (SDK 21+)                |

## ⚙️ Installation & Setup

### 1. Clone Repository

```
git clone https://github.com/AbdulManan-official/video-to-audio-converter
cd video-to-audio-converter
```

### 2. Install Dependencies

```
flutter pub get
```

### 3. Run App

```
flutter run
```

### 4. Build Release APK

```
flutter build apk --release
```

## 📂 Project Structure

```
video_to_audio_converter/
├─ lib/
│  ├─ controllers/
│  ├─ models/
│  ├─ utils/
│  ├─ views/
│  │   ├─ Format_Converter/
│  │   ├─ Merge_Audio/
│  │   └─ Ringtone/
│  └─ main.dart
├─ plugins/
├─ android/
├─ ios/
└─ pubspec.yaml
```

## 🧩 FFmpeg Commands

### Extract Audio from Video

```
-i input_video.mp4 -vn -acodec mp3 output_audio.mp3
```

### Convert Audio Format

```
-i input.wav -acodec mp3 output.mp3
```

### Merge Audio Files

```
-i "concat:track1.mp3|track2.mp3|track3.mp3" -acodec copy output.mp3
```

### Set Ringtone

```
RingtoneSet.setRingtone(path);
```

## 🔐 Permissions Required

* READ_EXTERNAL_STORAGE
* WRITE_EXTERNAL_STORAGE
* MANAGE_EXTERNAL_STORAGE (Android 11+)
* SET_RINGTONE

## 💡 Future Enhancements

* Waveform visualizer
* Playback preview
* Background conversion

## 👤 Author

**Abdul Manan**
Sialkot, Pakistan
[abdullmanan7777@gmail.com](mailto:abdullmanan7777@gmail.com)
