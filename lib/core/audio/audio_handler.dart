import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// This class handles basic audio playback
class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _player;
  final String _tag = 'AudioPlayerHandler';
  double _volume = 0.7;
  String? _currentAssetPath;

  AudioPlayerHandler() : _player = AudioPlayer() {
    // Set up audio player
    _player.playerStateStream.listen(_onPlayerStateChanged);
    _player.positionStream.listen((position) => _updatePlaybackState());
    _player.bufferedPositionStream.listen((position) => _updatePlaybackState());
    _player.durationStream.listen((duration) => _updatePlaybackState());

    // Initialize with default values
    _updatePlaybackState();
  }

  void _onPlayerStateChanged(PlayerState state) async {
    _updatePlaybackState();

    if (state.processingState == ProcessingState.completed) {
      await stop();
    }
  }

  void _updatePlaybackState() {
    final state = _player.playerState;
    final playing = state.playing;
    final processingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[state.processingState]!;

    playbackState.add(
      PlaybackState(
        controls: [MediaControl.play, MediaControl.pause, MediaControl.stop],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
        updateTime: DateTime.now(),
      ),
    );
  }

  // AudioHandler methods
  @override
  Future<void> play() async {
    await _player.play();
    _updatePlaybackState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _updatePlaybackState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    _updatePlaybackState();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(volume);
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _updatePlaybackState();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    _updatePlaybackState();
  }

  // Play a sound from an asset path
  Future<void> playSound(String assetPath) async {
    try {
      // Only load the sound if it's different from the current one
      if (_currentAssetPath != assetPath) {
        await _player.stop();
        await _player.setAsset(assetPath);
        _currentAssetPath = assetPath;
      }
      await _player.setVolume(_volume);
      await play();
      print('[$_tag] Playing sound: $assetPath at volume $_volume');
    } catch (e, stackTrace) {
      print('[$_tag] Error playing sound: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
      print('[$_tag] Audio player disposed');
    } catch (e, stackTrace) {
      print('[$_tag] Error disposing audio player: $e\n$stackTrace');
      rethrow;
    }
  }

  // Getters
  double get volume => _volume;

  // Streams
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  // Current state
  PlayerState get playerState => _player.playerState;
}
