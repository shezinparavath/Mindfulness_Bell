import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MuteOptionWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const MuteOptionWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Mute Bell in Silent Mode',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Checkbox(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue ?? false);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            checkColor: Colors.white,
            fillColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: 0.15),
            ),
            activeColor: const Color(0xFF8B5CF6),
            side: BorderSide(color: Colors.white, width: 1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
