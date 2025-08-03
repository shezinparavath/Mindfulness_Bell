import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../../domain/entities/timer_settings.dart';
import '../../domain/repositories/timer_repository.dart';
import '../../../../core/audio/audio_handler.dart';
import '../../../../core/utils/util_functions.dart';
import '../../../../core/services/notification_service.dart';

class TimerRepositoryImpl implements TimerRepository {
  Timer? _timer;
  TimerSettings? _currentSettings;
  final StreamController<Duration> _bellController =
      StreamController<Duration>.broadcast();
  final AudioPlayerHandler _audioHandler;

  TimerRepositoryImpl(this._audioHandler);

  @override
  Future<void> saveTimerSettings(TimerSettings settings) async {
    _currentSettings = settings;
    final now = DateTime.now();
    final nextTime = now.add(settings.repeatInterval);

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timer_settings', jsonEncode(settings.toJson()));
    await prefs.setInt('nextBellTime', nextTime.millisecondsSinceEpoch);
    // Restart the timer with new settings
    if (isTimerActive()) {
      stopTimer();
      _startPeriodicTimer();
    }
  }

  @override
  Future<TimerSettings> getTimerSettings() async {
    if (_currentSettings != null) {
      return _currentSettings!;
    }

    // Load from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('timer_settings');

    if (settingsJson != null) {
      try {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = TimerSettings.fromJson(settingsMap);
        return _currentSettings!;
      } catch (e) {
        print('Error loading settings: $e');
      }
    }

    return TimerSettings();
  }

  @override
  Stream<Duration> startTimer(TimerSettings settings) async* {
    await saveTimerSettings(settings);
    _startPeriodicTimer();
    yield* _bellController.stream;
  }

  void _startPeriodicTimer() async {
    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();

    _timer = Timer.periodic(_currentSettings!.repeatInterval, (timer) async {
      final now = DateTime.now();
      final currentTime = TimeOfDay.fromDateTime(now);

      if (_isWithinTimeRange(
        currentTime,
        _currentSettings!.startTime,
        _currentSettings!.endTime,
      )) {
        // Check silent mode if enabled
        final isSilent = await isSilentMode();
        if (!_currentSettings!.muteInSilentMode || !isSilent) {
          await _playBellSound();
          _bellController.add(const Duration(seconds: 1));
          // Save the next bell time
          final nextTime = now.add(_currentSettings!.repeatInterval);
          await prefs.setInt('nextBellTime', nextTime.millisecondsSinceEpoch);
        }
      }
    });
  }

  @override
  Future<void> scheduleNextAlarm(Duration interval) async {
    final nextAlarmTime = DateTime.now().add(interval);
    await Workmanager().registerOneOffTask(
      'nextBellTask',
      'bellTask',
      initialDelay: interval,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Save the next alarm time for reference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nextAlarmTime', nextAlarmTime.millisecondsSinceEpoch);
  }

  bool _isWithinTimeRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return currentMinutes >= startMinutes && currentMinutes < endMinutes;
  }

  Future<void> _playBellSound() async {
    if (_currentSettings == null) return;

    final bellOptions = [
      'assets/sounds/singing_bowl.mp3',
      'assets/sounds/tibetan_bell.mp3',
      'assets/sounds/gong.mp3',
    ];

    if (_currentSettings!.selectedBellIndex < bellOptions.length) {
      try {
        await _audioHandler.setVolume(_currentSettings!.volume);
        await _audioHandler.playSound(
          bellOptions[_currentSettings!.selectedBellIndex],
        );

        // Show notification with stop button
        final notificationService = NotificationService();
        await notificationService.showBellPlayingNotification(
          title: 'Mindfulness Bell',
          body: 'Time to be present and mindful',
          onStopPressed: () async {
            await _audioHandler.stop();
            await notificationService.cancelBellPlayingNotification();
          },
        );
      } catch (e) {
        print('Error playing bell sound: $e');
      }
    }
  }

  @override
  Future<void> stopTimer() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  bool isTimerActive() {
    return _timer?.isActive == true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bellController.close();
  }
}
