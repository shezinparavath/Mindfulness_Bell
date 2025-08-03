import 'dart:async';
import '../entities/timer_settings.dart';

abstract class TimerRepository {
  Future<void> saveTimerSettings(TimerSettings settings);
  Future<TimerSettings> getTimerSettings();
  Stream<Duration> startTimer(TimerSettings settings);
  Future<void> stopTimer();
  bool isTimerActive();
  void dispose();
  Future<void> scheduleNextAlarm(Duration interval);
}
