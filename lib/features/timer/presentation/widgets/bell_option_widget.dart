import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindfulness_bell/features/timer/domain/entities/bell_option.dart';

class BellOptionWidget extends StatelessWidget {
  final BellOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget icon;

  const BellOptionWidget({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: const Color(0xFF8B5CF6), width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
            ),
            child: icon,
          ),
          const SizedBox(height: 12),
          Text(
            option.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
