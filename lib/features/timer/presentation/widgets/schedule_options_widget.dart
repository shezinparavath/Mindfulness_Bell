import 'package:flutter/material.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/time_option_widget.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/mute_option_widget.dart';

class ScheduleOptionsWidget extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String repeatInterval;
  final bool muteInSilentMode;
  final VoidCallback onStartTimePressed;
  final VoidCallback onEndTimePressed;
  final VoidCallback onRepeatPressed;
  final ValueChanged<bool> onMuteChanged;

  const ScheduleOptionsWidget({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.repeatInterval,
    required this.muteInSilentMode,
    required this.onStartTimePressed,
    required this.onEndTimePressed,
    required this.onRepeatPressed,
    required this.onMuteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        TimeOptionWidget(
          label: 'Starts in',
          value: startTime,
          onTap: onStartTimePressed,
        ),
        TimeOptionWidget(
          label: 'Ends in',
          value: endTime,
          onTap: onEndTimePressed,
        ),
        TimeOptionWidget(
          label: 'Repeat in',
          value: repeatInterval,
          onTap: onRepeatPressed,
        ),
        MuteOptionWidget(value: muteInSilentMode, onChanged: onMuteChanged),
      ],
    );
  }
}
