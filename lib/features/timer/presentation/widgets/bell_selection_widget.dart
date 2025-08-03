import 'package:flutter/material.dart';
import 'package:mindfulness_bell/features/timer/domain/entities/bell_option.dart';
import 'package:mindfulness_bell/features/timer/presentation/widgets/bell_option_widget.dart';

class BellSelectionWidget extends StatelessWidget {
  final List<BellOption> bellOptions;
  final int selectedBell;
  final ValueChanged<int> onBellSelected;
  final Widget Function(int) getBellIcon;

  const BellSelectionWidget({
    super.key,
    required this.bellOptions,
    required this.selectedBell,
    required this.onBellSelected,
    required this.getBellIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            bellOptions.length,
            (index) => BellOptionWidget(
              option: bellOptions[index],
              isSelected: selectedBell == index,
              onTap: () => onBellSelected(index),
              icon: getBellIcon(index),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Select a Sound For Your Mindfulness Bell',
          style: TextStyle(
            color: Color(0xFFB8B8D1),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
