import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindfulness_bell/features/timer/domain/entities/timer_settings.dart';
import 'package:mindfulness_bell/core/audio/audio_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'keepAliveTask':
          await _handleKeepAliveTask();
          break;
      }
      return true;
    } catch (e, stackTrace) {
      print('Error in callbackDispatcher: $e\n$stackTrace');
      return false;
    }
  });
}

// Global instance of AudioPlayerHandler for background task
AudioPlayerHandler? _audioHandler;

Future<void> _handleKeepAliveTask() async {
  try {
    print('Background service keeping timer alive...');

    // Initialize audio handler for background task
    _audioHandler = AudioPlayerHandler();

    final prefs = await SharedPreferences.getInstance();
    final nextBellMillis = prefs.getInt('nextBellTime');
    final settingsJson = prefs.getString('timer_settings');

    if (settingsJson != null) {
      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      final settings = TimerSettings.fromJson(settingsMap);

      final bellOptions = [
        'assets/sounds/singing_bowl.mp3',
        'assets/sounds/tibetan_bell.mp3',
        'assets/sounds/gong.mp3',
      ];

      if (settings.selectedBellIndex >= 0 &&
          settings.selectedBellIndex < bellOptions.length) {
        final bellSound = bellOptions[settings.selectedBellIndex];
        final now = DateTime.now();

        if (nextBellMillis != null) {
          DateTime nextBellTime =
              DateTime.fromMillisecondsSinceEpoch(nextBellMillis);

          // Catch up on all missed bells
          while (!now.isBefore(nextBellTime)) {
            print(
              'Bell due at $nextBellTime — playing sound: $bellSound at volume ${settings.volume}',
            );

            await _audioHandler!.setVolume(settings.volume);
            await _audioHandler!.playSound(bellSound);

            final audioDuration =
                await _audioHandler!.durationStream.first ?? Duration(seconds: 30);
            final safeTimeout = audioDuration + const Duration(seconds: 5);

            await _audioHandler!.playerStateStream
                .firstWhere(
                  (state) => state.processingState == ProcessingState.completed,
                  orElse: () => PlayerState(false, ProcessingState.completed),
                )
                .timeout(
                  safeTimeout,
                  onTimeout: () => PlayerState(false, ProcessingState.completed),
                );

            // Move to the next scheduled bell time
            nextBellTime = nextBellTime.add(settings.repeatInterval);
          }

          // Save updated next bell time
          await prefs.setInt(
            'nextBellTime',
            nextBellTime.millisecondsSinceEpoch,
          );
        }
      }
    }
  } catch (e, stackTrace) {
    print('Error in background task: $e\n$stackTrace');
  } finally {
    print('Cleaning up background resources...');
    if (_audioHandler != null) {
      try {
        await _audioHandler!.stop();
        await _audioHandler!.dispose();
      } catch (e) {
        print('Error during cleanup: $e');
      }
      _audioHandler = null;
    }
    print('Background task completed');
  }
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> startKeepAlive() async {
    // Register a periodic task to keep the timer alive
    await Workmanager().registerPeriodicTask(
      'keepAliveTask',
      'keepAliveTask',
      frequency: const Duration(minutes: 15), // Check every 15 minutes
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> stopKeepAlive() async {
    await Workmanager().cancelAll();
  }
}
