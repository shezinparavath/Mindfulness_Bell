import 'package:flutter/material.dart';

class TimerSettings {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Duration repeatInterval;
  final bool muteInSilentMode;
  final int selectedBellIndex;
  final double volume;

  const TimerSettings({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Duration? repeatInterval,
    this.muteInSilentMode = false,
    this.selectedBellIndex = 0,
    this.volume = 0.7,
  }) : startTime = startTime ?? const TimeOfDay(hour: 9, minute: 0),
       endTime = endTime ?? const TimeOfDay(hour: 17, minute: 0),
       repeatInterval = repeatInterval ?? const Duration(minutes: 10);

  TimerSettings copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Duration? repeatInterval,
    bool? muteInSilentMode,
    int? selectedBellIndex,
    double? volume,
  }) {
    return TimerSettings(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      muteInSilentMode: muteInSilentMode ?? this.muteInSilentMode,
      selectedBellIndex: selectedBellIndex ?? this.selectedBellIndex,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'repeatInterval': repeatInterval.inMilliseconds,
      'muteInSilentMode': muteInSilentMode,
      'selectedBellIndex': selectedBellIndex,
      'volume': volume,
    };
  }

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    return TimerSettings(
      startTime: TimeOfDay(
        hour: json['startHour'] as int? ?? 9,
        minute: json['startMinute'] as int? ?? 0,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int? ?? 17,
        minute: json['endMinute'] as int? ?? 0,
      ),
      repeatInterval: Duration(
        milliseconds:
            json['repeatInterval'] as int? ??
            const Duration(minutes: 10).inMilliseconds,
      ),
      muteInSilentMode: json['muteInSilentMode'] as bool? ?? false,
      selectedBellIndex: json['selectedBellIndex'] as int? ?? 0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.7,
    );
  }
}
