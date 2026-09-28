import 'package:flutter/material.dart';

import '../models/movement_info.dart';
import 'movement_badge.dart';

class AllCategoriesBreakdown extends StatefulWidget {
  final List<String> categories;
  final Map<String, Map<String, String>> finalActionTable;
  final Map<String, Map<String, String>> previousFinalActionTable;
  final Map<String, Map<String, String>> filingTable;
  final Map<String, Map<String, String>> previousFilingTable;
  final String country;
  final String chargeabilityKey;
  final String activeUserCategory;
  final ValueChanged<String> onSelectCategory;

  const AllCategoriesBreakdown({
    super.key,
    required this.categories,
    required this.finalActionTable,
    required this.previousFinalActionTable,
    required this.filingTable,
    required this.previousFilingTable,
    required this.country,
    required this.chargeabilityKey,
    required this.activeUserCategory,
    required this.onSelectCategory,
  });

  @override
  State<AllCategoriesBreakdown> createState() => _AllCategoriesBreakdownState();
}

class _AllCategoriesBreakdownState extends State<AllCategoriesBreakdown> {
  String _filter = 'all'; // 'all', 'advanced', 'unchanged', 'retrogressed'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter categories
    final displayCategories = widget.categories.where((cat) {
      if (_filter == 'all') return true;
      final curVal = widget.finalActionTable[cat]?[widget.chargeabilityKey] ?? '—';
      final prevVal = widget.previousFinalActionTable[cat]?[widget.chargeabilityKey];
      final m = calculateMovement(prevVal, curVal);

      if (_filter == 'advanced') {
        return m.type == MovementType.advanced ||
            m.type == MovementType.becameCurrent ||
            m.type == MovementType.restored;
      } else if (_filter == 'retrogressed') {
        return m.type == MovementType.retrogressed ||
            m.type == MovementType.becameUnavailable;
      } else if (_filter == 'unchanged') {
        return m.type == MovementType.unchanged;
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.6 : 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_chart_rounded, size: 18, color: Color(0xFF38BDF8)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Other Categories',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Tap any category to set as Your Beacon',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', 'All (${widget.categories.length})'),
                const SizedBox(width: 6),
                _buildFilterChip('advanced', 'Advanced ↑'),
                const SizedBox(width: 6),
                _buildFilterChip('unchanged', 'No change —'),
                const SizedBox(width: 6),
                _buildFilterChip('retrogressed', 'Retrogressed ↓'),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // List of Category Tiles
          if (displayCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No categories match this filter',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < displayCategories.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                  () {
                    final cat = displayCategories[i];
                    final isCurrentBeacon = cat == widget.activeUserCategory;

                    final finalVal = widget.finalActionTable[cat]?[widget.chargeabilityKey] ?? '—';
                    final prevFinalVal = widget.previousFinalActionTable[cat]?[widget.chargeabilityKey];
                    final finalMovement = calculateMovement(prevFinalVal, finalVal);

                    final filingVal = widget.filingTable[cat]?[widget.chargeabilityKey] ?? '—';
                    final prevFilingVal = widget.previousFilingTable[cat]?[widget.chargeabilityKey];
                    final filingMovement = calculateMovement(prevFilingVal, filingVal);

                    return InkWell(
                      onTap: () => widget.onSelectCategory(cat),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Category Badge
                            Container(
                              width: 58,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isCurrentBeacon
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                    : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCurrentBeacon
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: isCurrentBeacon
                                      ? const Color(0xFFD97706)
                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Final Action Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FINAL ACTION',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCutoffDate(finalVal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  MovementBadge(movement: finalMovement),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Filing Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DATES FOR FILING',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCutoffDate(filingVal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  MovementBadge(movement: filingMovement),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),

                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: isDark ? Colors.white38 : Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    );
                  }(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      onSelected: (val) {
        if (val) setState(() => _filter = key);
      },
    );
  }
}
