import 'package:flutter/material.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';

Future<bool> isSilentMode() async {
  final mode = await SoundMode.ringerModeStatus;
  return mode == RingerModeStatus.silent;
}

/// Format time for display
String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Parse time string to TimeOfDay
TimeOfDay parseTimeString(String timeString) {
  final parts = timeString.split(':');
  if (parts.length == 2) {
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
  return const TimeOfDay(hour: 0, minute: 0);
}
