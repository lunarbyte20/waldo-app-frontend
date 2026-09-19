import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool isFlagged;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.isFlagged,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = customLabel ?? (isFlagged ? 'FLAGGED LOCATION' : 'VALID / APPROVED');
    final bgColor = isFlagged ? Colors.amber.shade100 : Colors.green.shade100;
    final fgColor = isFlagged ? Colors.amber.shade900 : Colors.green.shade900;
    final iconData = isFlagged ? Icons.warning_amber_rounded : Icons.check_circle_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: 16,
            color: fgColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
