import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BulletinStatusCallout extends StatelessWidget {
  final String bulletinMonth;
  final String? publishedAt;
  final VoidCallback? onRefresh;

  const BulletinStatusCallout({
    super.key,
    required this.bulletinMonth,
    this.publishedAt,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    DateTime? pubDate;
    String? pubMonthName;
    String? pubFormattedDate;

    if (publishedAt != null && publishedAt!.isNotEmpty) {
      pubDate = DateTime.tryParse(publishedAt!);
      if (pubDate != null) {
        pubMonthName = DateFormat('MMMM').format(pubDate);
        pubFormattedDate = DateFormat('MMM d, yyyy').format(pubDate);
      }
    }

    final now = DateTime.now();
    final currentMonthName = DateFormat('MMMM').format(now);
    final lastMonthName = pubMonthName ?? 'previous month';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F2338)
            : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF0284C7).withValues(alpha: 0.35)
              : const Color(0xFFBAE6FD),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              size: 17,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PENDING NEW RELEASE',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'U.S. Department of State',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This month\'s ($currentMonthName) bulletin is not yet published.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Showing cutoff dates from the last published bulletin ($lastMonthName${pubFormattedDate != null ? ' • $pubFormattedDate' : ''}). Daily checks will notify you as soon as the Department of State releases the new edition.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
