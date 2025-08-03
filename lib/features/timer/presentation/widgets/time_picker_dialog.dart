import 'package:flutter/material.dart';

class TimePickerDialog extends StatelessWidget {
  final String title;
  final String currentValue;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const TimePickerDialog({
    super.key,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.onSelected,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String currentValue,
    required List<String> options,
  }) async {
    String? selectedValue;

    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TimePickerDialog(
        title: title,
        currentValue: currentValue,
        options: options,
        onSelected: (value) => selectedValue = value,
      ),
    );

    return selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2a2a4e), Color(0xFF1a1a3e)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, currentValue),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  options[index],
                  style: TextStyle(
                    color: options[index] == currentValue
                        ? const Color(0xFF8B5CF6)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: options[index] == currentValue
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  onSelected(options[index]);
                  Navigator.pop(context, options[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
