import 'package:flutter/material.dart';

import '../constants/country_data.dart';
import '../models/movement_info.dart';

class BeaconBriefCard extends StatelessWidget {
  final String month;
  final MonthMovementSummary summary;
  final VoidCallback? onFilterAdvanced;
  final VoidCallback? onFilterUnchanged;
  final VoidCallback? onFilterRetrogressed;

  const BeaconBriefCard({
    super.key,
    required this.month,
    required this.summary,
    this.onFilterAdvanced,
    this.onFilterUnchanged,
    this.onFilterRetrogressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: WHAT CHANGED?
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                '${month.toUpperCase()} AT A GLANCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '10-SEC BRIEF',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3 Metric Stat Badges
          Row(
            children: [
              Expanded(
                child: _buildStatBadge(
                  label: '${summary.advanced} Advanced',
                  symbol: '↑',
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                  isDark: isDark,
                  onTap: onFilterAdvanced,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBadge(
                  label: '${summary.unchanged} No change',
                  symbol: '—',
                  color: const Color(0xFF64748B),
                  bgColor: const Color(0xFF64748B).withValues(alpha: isDark ? 0.15 : 0.08),
                  isDark: isDark,
                  onTap: onFilterUnchanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBadge(
                  label: '${summary.retrogressed} Retrogressed',
                  symbol: '↓',
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                  isDark: isDark,
                  onTap: onFilterRetrogressed,
                ),
              ),
            ],
          ),

          // Biggest Movement Highlight
          if (summary.biggestCategory != null && summary.biggestDays > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Biggest Movement: ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : const Color(0xFF065F46),
                            ),
                          ),
                          TextSpan(
                            text: '${summary.biggestCategory} (${summary.biggestCountry ?? 'All'}) • ${summary.biggestLabel ?? '+${summary.biggestDays} days'}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    getCountryFlag(summary.biggestCountry ?? ''),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String symbol,
    required Color color,
    required Color bgColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
