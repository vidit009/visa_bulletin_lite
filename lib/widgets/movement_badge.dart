import 'package:flutter/material.dart';
import '../models/movement_info.dart';

class MovementBadge extends StatelessWidget {
  final MovementInfo movement;
  final bool isLarge;

  const MovementBadge({
    super.key,
    required this.movement,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (movement.type) {
      case MovementType.advanced:
      case MovementType.becameCurrent:
      case MovementType.restored:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        icon = Icons.arrow_upward_rounded;
        break;
      case MovementType.retrogressed:
      case MovementType.becameUnavailable:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        icon = Icons.arrow_downward_rounded;
        break;
      case MovementType.unchanged:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.remove_rounded;
        break;
      case MovementType.unknown:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        icon = Icons.help_outline_rounded;
        break;
    }

    if (isLarge) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movement.label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (movement.detail.isNotEmpty)
                  Text(
                    movement.detail,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 4),
          Text(
            movement.shortLabel,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
