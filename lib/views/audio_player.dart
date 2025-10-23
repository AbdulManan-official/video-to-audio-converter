// ignore_for_file: use_build_context_synchronously, must_be_immutable , library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_to_audio_converter/utils/resources.dart';

class MusicPlayerScreen extends StatefulWidget {
  final String audiopath;
  final String fileName;
  Directory? directory;

  MusicPlayerScreen(
      {super.key,
      required this.audiopath,
      required this.fileName,
      this.directory});
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isLooping = false;
  bool _isFullScreen = false; // Full-screen state
  double _logoSize = 200; // Initial size for the logo
  List<File> mp3Files = [];
  String fileName = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadAudio(widget.audiopath);

    // Listen to the position updates
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position;
      });
    });

    // Set looping mode based on _isLooping
    _audioPlayer.setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
    fileName = widget.fileName;
  }

  Future<void> _loadAudio(String path) async {
    await _audioPlayer.setUrl(path);
    setState(() {
      _duration = _audioPlayer.duration!;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}'
        : '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  void _playPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _seek(Duration position) {
    final newPosition = position < Duration.zero
        ? Duration.zero
        : (position > _duration ? _duration : position);
    _audioPlayer.seek(newPosition);
  }

  void _muteUnmute() {
    _isMuted = !_isMuted;
    _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    setState(() {});
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping; // Toggle loop state
    });
    _audioPlayer.setLoopMode(
      _isLooping ? LoopMode.one : LoopMode.off,
    );
    toastFlutter(
        toastmessage: _isLooping ? 'Loop initiate' : 'Loop Remove',
        color: _isLooping ? Colors.green[800] : Colors.red);
  }

  void _showFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _logoSize =
          _isFullScreen ? 300 : 200; // Animate logo size for full screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            Expanded(
              child: Text(
                fileName,
                style: const TextStyle(color: Colors.white, fontSize: 22),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: _isFullScreen ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: ListView(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 130),
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: _logoSize,
                    width: _logoSize,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/music.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        size: 30,
                      ),
                      color: Colors.white,
                      onPressed: _muteUnmute,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cut,
                        size: 30,
                      ),
                      color: Colors.white,
                      onPressed: () {},
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    IconButton(
                      icon: Icon(
                        _isLooping ? Icons.loop : Icons.loop_outlined,
                        size: 30,
                      ),
                      color: Colors.white,
                      onPressed: _toggleLoop,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Slider(
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                        value: _position.inSeconds.toDouble(),
                        min: 0.0,
                        max: _duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          _seek(Duration(seconds: value.toInt()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.fullscreen_rounded,
                        size: 30,
                      ),
                      color: Colors.white,
                      onPressed: _showFullScreen,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.replay_10,
                            size: 30,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            final newPosition =
                                _position - const Duration(seconds: 10);
                            _seek(newPosition < Duration.zero
                                ? Duration.zero
                                : newPosition);
                          },
                        ),
                        IconButton(
                          icon: Icon(_isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled),
                          color: Colors.white,
                          iconSize: 64,
                          onPressed: _playPause,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.forward_10,
                            size: 30,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            final newPosition =
                                _position + const Duration(seconds: 10);
                            _seek(newPosition > _duration
                                ? _duration
                                : newPosition);
                          },
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 30,
                      ),
                      color: Colors.white,
                      onPressed: () {
                        _showDownloadedFilesBottomSheet();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Center(
            child: _isFullScreen
                ? GestureDetector(
                    onTap: () {
                      _isFullScreen = !_isFullScreen;
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: _logoSize,
                      width: _logoSize,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/music.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ).paddingOnly(bottom: 15.0),
    );
  }

  void _showDownloadedFilesBottomSheet() async {
    await _listDownloadedFiles();
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: mp3Files.length,
          itemBuilder: (context, index) {
            File file = mp3Files[index];
            String newfileName = file.path.split('/').last;
            return ListTile(
              leading: const Icon(Icons.music_note, size: 40),
              title: Text(newfileName,
                  style: const TextStyle(color: Colors.black)),
              subtitle: const Text("Tap to play",
                  style: TextStyle(color: Colors.grey)),
              onTap: () {
                Navigator.pop(context);
                _loadAudio(file.path);
                setState(() {
                  fileName =
                      newfileName; // Update fileName when a new file is selected
                });
                _playPause();
              },
            );
          },
        );
      },
    );
  }

  Future<List<File>> _listDownloadedFiles() async {
    Directory musicDir =
        widget.directory ?? Directory('/storage/emulated/0/Music/VideoMusic');

    if (await musicDir.exists()) {
      setState(() {
        mp3Files = musicDir
            .listSync()
            .where((item) => !item.path.contains(".pending-"))
            .map((item) => File(item.path))
            .toList();
      });
    }
    return mp3Files;
  }
}
