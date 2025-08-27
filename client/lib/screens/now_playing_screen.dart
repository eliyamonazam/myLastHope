import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'dart:ui';

class NowPlayingScreen extends StatefulWidget {
  final Song song;
  final AudioPlayer audioPlayer;

  const NowPlayingScreen({
    super.key,
    required this.song,
    required this.audioPlayer,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  @override
  void initState() {
    super.initState();
    // Start playing the song as soon as the screen opens
    _playSong();
  }

  void _playSong() async {
    try {
      // Set the URL and play. The player instance is passed from the previous screen.
      await widget.audioPlayer.setUrl(widget.song.songUrl);
      widget.audioPlayer.play();
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            widget.song.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.black),
          ),
          // Frosted Glass Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Main Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                const Spacer(),
                // Album Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    widget.song.thumbnailUrl,
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 80),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Song Title and Artist
                Text(
                  widget.song.songName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.song.artist,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                // Seek Bar
                _buildSeekBar(),
                const SizedBox(height: 16),
                // Play/Pause Controls
                _buildControls(),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the seek bar
  Widget _buildSeekBar() {
    return StreamBuilder<Duration?>(
      stream: widget.audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: widget.audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            var position = positionSnapshot.data ?? Duration.zero;
            if (position > duration) {
              position = duration;
            }
            return Slider(
              value: position.inSeconds.toDouble(),
              max: duration.inSeconds.toDouble(),
              min: 0.0,
              activeColor: Colors.white,
              inactiveColor: Colors.white38,
              onChanged: (value) {
                widget.audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            );
          },
        );
      },
    );
  }

  // Widget for the play/pause button
  Widget _buildControls() {
    return StreamBuilder<PlayerState>(
      stream: widget.audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          return const CircularProgressIndicator(color: Colors.white);
        } else if (playing != true) {
          return IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 64),
            onPressed: widget.audioPlayer.play,
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: const Icon(Icons.pause, color: Colors.white, size: 64),
            onPressed: widget.audioPlayer.pause,
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.replay, color: Colors.white, size: 64),
            onPressed: () => widget.audioPlayer.seek(Duration.zero),
          );
        }
      },
    );
  }
}
