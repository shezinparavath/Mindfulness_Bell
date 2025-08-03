import 'package:flutter/material.dart' hide TimePickerDialog;
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:mindfulness_bell/features/timer/presentation/providers/timer_provider.dart';
import 'package:mindfulness_bell/features/timer/domain/entities/bell_option.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/action_buttons_widget.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/bottom_navigation_widget.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/bell_header_widget.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/bell_selection_widget.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/schedule_options_widget.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/time_picker_dialog.dart';

class MindfulnessBellScreen extends StatelessWidget {
  const MindfulnessBellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: context.read<TimerProvider>(),
      child: const _MindfulnessBellScreenContent(),
    );
  }
}

class _MindfulnessBellScreenContent extends StatefulWidget {
  const _MindfulnessBellScreenContent();

  @override
  State<_MindfulnessBellScreenContent> createState() =>
      _MindfulnessBellScreenState();
}

class _MindfulnessBellScreenState extends State<_MindfulnessBellScreenContent> {
  late final TimerProvider _timerProvider;
  late final ValueNotifier<int> _currentTabIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _timerProvider = context.read<TimerProvider>();
    // Start the timer when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timerProvider.startTimer();
    });
  }

  @override
  void dispose() {
    _currentTabIndex.dispose();
    super.dispose();
  }

  Widget _getBellIcon(int index) {
    switch (index) {
      case 0: // Singing Bowl
        return Image.asset('assets/icons/bowl_image.png');
      case 1: // Ohm Bell
        return Image.asset('assets/icons/bell_image.png');
      case 2: // Gong
        return Image.asset('assets/icons/gong_image.png');
      default:
        return Image.asset('assets/icons/bell_image.png');
    }
  }

  void _showStartTimePicker() async {
    final timeProvider = context.read<TimerProvider>();
    final result = await TimePickerDialog.show(
      context: context,
      title: 'Start Time',
      currentValue: _formatTimeOfDay(timeProvider.startTime),
      options: _generateTimeOptions(),
    );

    if (result != null && context.mounted) {
      timeProvider.updateStartTime(_parseTimeString(result));
    }
  }

  void _showEndTimePicker() async {
    final timeProvider = context.read<TimerProvider>();
    final result = await TimePickerDialog.show(
      context: context,
      title: 'End Time',
      currentValue: _formatTimeOfDay(timeProvider.endTime),
      options: _generateTimeOptions(),
    );

    if (result != null && context.mounted) {
      timeProvider.updateEndTime(_parseTimeString(result));
    }
  }

  void _showRepeatPicker() async {
    final timeProvider = context.read<TimerProvider>();
    final result = await TimePickerDialog.show(
      context: context,
      title: 'Repeat Interval',
      currentValue: timeProvider.repeatInterval,
      options: const [
        '1 minutes',
        '2 minutes',
        '4 minutes',
        '5 minutes',
        '10 minutes',
        '15 minutes',
        '20 minutes',
        '30 minutes',
        '45 minutes',
        '1 hour',
        '2 hours',
      ],
    );

    if (result != null && context.mounted) {
      timeProvider.updateRepeatInterval(_parseDuration(result));
    }
  }

  List<String> _generateTimeOptions() {
    final List<String> options = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final time = TimeOfDay(hour: hour, minute: minute);
        options.add(_formatTimeOfDay(time));
      }
    }
    return options;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _parseTimeString(String timeString) {
    final time = timeString.split(' ')[0];
    final period = timeString.split(' ')[1];
    final hour = int.parse(time.split(':')[0]);
    final minute = int.parse(time.split(':')[1]);

    return TimeOfDay(
      hour: period == 'PM'
          ? (hour == 12 ? 12 : hour + 12)
          : (hour == 12 ? 0 : hour),
      minute: minute,
    );
  }

  Duration _parseDuration(String durationString) {
    if (durationString.contains('hour')) {
      final hours = int.parse(durationString.split(' ')[0]);
      return Duration(hours: hours);
    } else {
      final minutes = int.parse(durationString.split(' ')[0]);
      return Duration(minutes: minutes);
    }
  }

  void _onTabTapped(int index) {
    _currentTabIndex.value = index;
  }

  void _saveBellSettings() async {
    // Store context before any async operations
    final currentContext = context;
    if (!mounted) return;

    HapticFeedback.mediumImpact();
    await _timerProvider.saveSettings();

    if (!mounted) return;

    if (currentContext.mounted) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: const Text(
            'Bell settings saved successfully!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _playSoundPreview(int index) {
    try {
      final bellSound = _timerProvider.bellOptions[index];
      _showBellPreviewDialog(context, bellSound);
    } catch (e) {
      debugPrint(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to play sound preview'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBellPreviewDialog(BuildContext context, BellOption bellSound) {
    debugPrint('Showing preview for: ${bellSound.name}');

    // Stop any currently playing audio first
    _timerProvider.stopAudio();

    // Play the audio after dialog is shown
    _timerProvider.playBellSound(bellSound.icon);
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF24243e),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bell icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6),
                        width: 3,
                      ),
                    ),
                    child: _getBellIcon(
                      bellSound.name == 'Singing Bowl'
                          ? 0
                          : bellSound.name == 'Ohm Bell'
                          ? 1
                          : 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bell name
                  Text(
                    bellSound.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Preview text
                  const Text(
                    'Preview Playing...',
                    style: TextStyle(color: Color(0xFFB8B8D1), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  // Close button
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('Close button pressed for: ${bellSound.name}');
                      // Stop the audio and close dialog
                      _timerProvider.stopAudio();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close Preview'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    // Stop audio when dialog is dismissed
    _timerProvider.stopAudio();
    debugPrint('Dialog closed for: ${bellSound.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF24243e),
              Color(0xFF302B63),
              Color(0xFF0F0C29),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BellHeaderWidget(
                title: 'Mindfulness Bell',
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Bell Selection
                      Selector<TimerProvider, int>(
                        selector: (_, provider) => provider.selectedBellIndex,
                        builder: (context, selectedBellIndex, _) {
                          return BellSelectionWidget(
                            bellOptions: _timerProvider.bellOptions,
                            selectedBell: selectedBellIndex,
                            onBellSelected: (index) async {
                              // Play preview sound when a bell is selected
                              _playSoundPreview(index);
                              // Update the selected bell and save settings only after preview
                              _timerProvider.selectBell(index);
                              await _timerProvider.saveSettings();
                            },
                            getBellIcon: _getBellIcon,
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      // Schedule Options
                      Selector<TimerProvider, Map<String, dynamic>>(
                        selector: (_, provider) => {
                          'startTime': provider.startTime,
                          'endTime': provider.endTime,
                          'repeatInterval': provider.repeatInterval,
                          'muteInSilentMode': provider.muteInSilentMode,
                        },
                        builder: (context, values, _) {
                          return ScheduleOptionsWidget(
                            startTime: _formatTimeOfDay(
                              values['startTime'] as TimeOfDay,
                            ),
                            endTime: _formatTimeOfDay(
                              values['endTime'] as TimeOfDay,
                            ),
                            repeatInterval: values['repeatInterval'] as String,
                            muteInSilentMode:
                                values['muteInSilentMode'] as bool,
                            onStartTimePressed: _showStartTimePicker,
                            onEndTimePressed: _showEndTimePicker,
                            onRepeatPressed: _showRepeatPicker,
                            onMuteChanged: (value) =>
                                _timerProvider.toggleMuteInSilentMode(value),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      // Action Buttons
                      StreamBuilder<PlayerState>(
                        stream: _timerProvider
                            .audioHandler
                            .playerStateStream, // just_audio stream
                        builder: (context, snapshot) {
                          final isBellPlaying = snapshot.data?.playing ?? false;

                          return ActionButtonsWidget(
                            onCancel: () {
                              _timerProvider.cancelChanges();
                            },
                            onSave: _saveBellSettings,
                            onStop: () async {
                              await _timerProvider.stopAudio();
                            },
                            showStopButton: isBellPlaying,
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              // Bottom Navigation
              ValueListenableBuilder<int>(
                valueListenable: _currentTabIndex,
                builder: (context, currentIndex, _) {
                  return BottomNavigationWidget(
                    currentIndex: currentIndex,
                    onTap: _onTabTapped,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
