import 'package:flutter/material.dart';
import '../models/movement_info.dart';
import 'movement_badge.dart';

class OtherCategoriesCard extends StatelessWidget {
  final List<String> categories;
  final Map<String, Map<String, String>> currentTable;
  final Map<String, Map<String, String>> previousTable;
  final String country;
  final String chargeabilityKey;
  final String chart;
  final ValueChanged<String> onSelectCategory;

  const OtherCategoriesCard({
    super.key,
    required this.categories,
    required this.currentTable,
    required this.previousTable,
    required this.country,
    required this.chargeabilityKey,
    required this.chart,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int advancedCount = 0;
    int retrogressedCount = 0;
    int unchangedCount = 0;

    for (final cat in categories) {
      final curVal = currentTable[cat]?[chargeabilityKey] ?? '—';
      final prevVal = previousTable[cat]?[chargeabilityKey];
      final m = calculateMovement(prevVal, curVal);
      if (m.type == MovementType.advanced || m.type == MovementType.becameCurrent) {
        advancedCount++;
      } else if (m.type == MovementType.retrogressed || m.type == MovementType.becameUnavailable) {
        retrogressedCount++;
      } else {
        unchangedCount++;
      }
    }

    final chartTitle = chart == 'final' ? 'Final Action' : 'Dates for Filing';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.table_chart_outlined,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Other Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        country,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cutoffs for $country ($chartTitle). Tap any row to set as your category.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (advancedCount > 0)
                      _SummaryChip(
                        label: '$advancedCount Advanced',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF10B981),
                      ),
                    if (retrogressedCount > 0)
                      _SummaryChip(
                        label: '$retrogressedCount Retrogressed',
                        icon: Icons.trending_down_rounded,
                        color: const Color(0xFFEF4444),
                      ),
                    _SummaryChip(
                      label: '$unchangedCount Unchanged',
                      icon: Icons.remove_rounded,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: categories.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: theme.dividerColor.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final curVal = currentTable[cat]?[chargeabilityKey] ?? '—';
              final prevVal = previousTable[cat]?[chargeabilityKey];
              final m = calculateMovement(prevVal, curVal);

              return InkWell(
                onTap: () => onSelectCategory(cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Prev: ${prevVal != null ? formatCutoffDate(prevVal) : '—'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCutoffDate(curVal),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: curVal == 'C'
                                  ? const Color(0xFF10B981)
                                  : curVal == 'U'
                                      ? const Color(0xFFEF4444)
                                      : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          MovementBadge(movement: m, isLarge: false),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
