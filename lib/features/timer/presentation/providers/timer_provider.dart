import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mindfulness_bell/core/audio/audio_handler.dart';
import 'package:mindfulness_bell/core/background/background_service.dart';
import 'package:mindfulness_bell/features/timer/domain/entities/bell_option.dart';
import 'package:mindfulness_bell/features/timer/domain/entities/timer_settings.dart';
import 'package:mindfulness_bell/features/timer/domain/repositories/timer_repository.dart';

class TimerProvider with ChangeNotifier {
  final TimerRepository _timerRepository;
  final AudioPlayerHandler audioHandler;

  TimerSettings? _settings;
  TimerSettings? _originalSettings; // Store original settings for cancel
  bool _isRunning = false;

  // Available bell sounds
  final List<BellOption> _bellOptions = [
    BellOption('Singing Bowl', 'assets/sounds/singing_bowl.mp3'),
    BellOption('Ohm Bell', 'assets/sounds/tibetan_bell.mp3'),
    BellOption('Gong', 'assets/sounds/gong.mp3'),
  ];

  TimerProvider(this._timerRepository, {required this.audioHandler}) {
    _loadSettings();
  }

  // Getters
  TimerSettings? get settings => _settings;
  bool get isRunning => _isRunning;
  List<BellOption> get bellOptions => _bellOptions;
  int get selectedBellIndex => _settings?.selectedBellIndex ?? 0;
  TimeOfDay get startTime =>
      _settings?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay get endTime =>
      _settings?.endTime ?? const TimeOfDay(hour: 17, minute: 0);
  String get repeatInterval =>
      _formatDuration(_settings?.repeatInterval ?? const Duration(minutes: 10));
  bool get muteInSilentMode => _settings?.muteInSilentMode ?? false;

  // Load settings from repository
  Future<void> _loadSettings() async {
    _settings = await _timerRepository.getTimerSettings();
    _originalSettings = _settings; // Store original settings
    // Initialize audio with selected bell sound
    await audioHandler.setVolume(_settings?.volume ?? 0.7);
    notifyListeners();
  }

  // Save current settings
  Future<void> saveSettings() async {
    await _timerRepository.saveTimerSettings(_settings!);
    notifyListeners();
  }

  // Format duration for display (e.g., "10 minutes")
  String _formatDuration(Duration duration) {
    return '${duration.inMinutes} minutes';
  }

  // UI interaction methods
  Future<void> selectBell(int index) async {
    if (index >= 0 && index < _bellOptions.length) {
      _settings =
          _settings?.copyWith(selectedBellIndex: index) ??
          TimerSettings(selectedBellIndex: index);
      await playBellSound(_bellOptions[index].icon);
    }
    notifyListeners();
  }

  void updateStartTime(TimeOfDay time) {
    _settings =
        _settings?.copyWith(startTime: time) ?? TimerSettings(startTime: time);
    notifyListeners();
  }

  void updateEndTime(TimeOfDay time) {
    _settings =
        _settings?.copyWith(endTime: time) ?? TimerSettings(endTime: time);
    notifyListeners();
  }

  void updateRepeatInterval(Duration interval) {
    _settings =
        _settings?.copyWith(repeatInterval: interval) ??
        TimerSettings(repeatInterval: interval);
    notifyListeners();
  }

  void toggleMuteInSilentMode(bool value) {
    _settings =
        _settings?.copyWith(muteInSilentMode: value) ??
        TimerSettings(muteInSilentMode: value);
    notifyListeners();
  }

  // Add this method to play bell sounds
  Future<void> playBellSound(String assetPath) async {
    try {
      // Stop any currently playing sound
      await audioHandler.stop();

      // Play the new sound
      await audioHandler.playSound(assetPath);
    } catch (e) {
      debugPrint('Error playing bell sound: $e');
      rethrow;
    }
  }

  // Add this method to stop audio
  Future<void> stopAudio() async {
    try {
      await audioHandler.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  // Cancel changes and revert to original settings
  void cancelChanges() {
    if (_originalSettings != null) {
      _settings = _originalSettings;
      notifyListeners();
    }
  }

  // Check if bell is currently playing
  bool get isBellPlaying => audioHandler.playerState.playing;

  // Timer control methods
  Future<void> startTimer() async {
    if (_isRunning) return;
    _isRunning = true;

    // Use the repository's simple timer approach
    _timerRepository
        .startTimer(_settings ?? TimerSettings())
        .listen((duration) {});

    // Start background service to keep timer alive when app is closed
    await BackgroundService.startKeepAlive();

    notifyListeners();
  }

  Future<void> stopTimer() async {
    await _timerRepository.stopTimer();
    await BackgroundService.stopKeepAlive();
    _isRunning = false;
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      stopTimer();
    } else {
      startTimer();
    }
  }

  @override
  void dispose() {
    _timerRepository.dispose();
    audioHandler.dispose();
    super.dispose();
  }
}
