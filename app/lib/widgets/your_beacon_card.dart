import 'package:flutter/material.dart';

import '../constants/country_data.dart';
import '../models/movement_info.dart';
import 'movement_badge.dart';

class YourBeaconCard extends StatelessWidget {
  final String category;
  final String country;
  final String chargeabilityKey;
  final String track;
  final String finalActionValue;
  final String? finalActionPrevious;
  final MovementInfo finalActionMovement;
  final String filingValue;
  final String? filingPrevious;
  final MovementInfo filingMovement;
  final String uscisFilingChart;
  final VoidCallback onEdit;
  final VoidCallback onShowExplainer;

  const YourBeaconCard({
    super.key,
    required this.category,
    required this.country,
    required this.chargeabilityKey,
    required this.track,
    required this.finalActionValue,
    this.finalActionPrevious,
    required this.finalActionMovement,
    required this.filingValue,
    this.filingPrevious,
    required this.filingMovement,
    required this.uscisFilingChart,
    required this.onEdit,
    required this.onShowExplainer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flag = getCountryFlag(country);
    final isFilingActive = uscisFilingChart.toLowerCase().contains('filing');

    return Container(
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
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        'YOUR BEACON',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  flag,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${country.toUpperCase()} • $category',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 15),
                  label: const Text(
                    'Change',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // TWO COLUMN DATE COMPARISON: Final Action & Dates for Filing
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. FINAL ACTION COLUMN
                Expanded(
                  child: _buildDateColumn(
                    context: context,
                    isDark: isDark,
                    title: 'FINAL ACTION',
                    subtitle: 'Green Card Approval',
                    currentVal: finalActionValue,
                    previousVal: finalActionPrevious,
                    movement: finalActionMovement,
                    isUSCISSelected: !isFilingActive,
                    onShowExplainer: onShowExplainer,
                  ),
                ),
                const SizedBox(width: 10),
                // 2. DATES FOR FILING COLUMN
                Expanded(
                  child: _buildDateColumn(
                    context: context,
                    isDark: isDark,
                    title: 'DATES FOR FILING',
                    subtitle: 'Application Filing',
                    currentVal: filingValue,
                    previousVal: filingPrevious,
                    movement: filingMovement,
                    isUSCISSelected: isFilingActive,
                    onShowExplainer: onShowExplainer,
                  ),
                ),
              ],
            ),
          ),

          // USCIS Guidance Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isFilingActive
                  ? const Color(0xFF0284C7).withValues(alpha: 0.08)
                  : const Color(0xFF059669).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: isFilingActive ? const Color(0xFF0284C7) : const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'USCIS this month: Use $uscisFilingChart',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isFilingActive
                          ? (isDark ? Colors.lightBlue.shade200 : const Color(0xFF0369A1))
                          : (isDark ? Colors.green.shade200 : const Color(0xFF047857)),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onShowExplainer,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String subtitle,
    required String currentVal,
    required String? previousVal,
    required MovementInfo movement,
    required bool isUSCISSelected,
    required VoidCallback onShowExplainer,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? (isUSCISSelected ? const Color(0xFF0B2545) : Colors.white.withValues(alpha: 0.03))
            : (isUSCISSelected ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUSCISSelected
              ? const Color(0xFF0284C7)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: isUSCISSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: isUSCISSelected
                        ? const Color(0xFF0284C7)
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
          if (isUSCISSelected) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ACTIVE USCIS',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0284C7),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            formatCutoffDate(currentVal),
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          MovementBadge(movement: movement),
          if (previousVal != null) ...[
            const SizedBox(height: 6),
            Text(
              'Prev: ${formatCutoffDate(previousVal)}',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
