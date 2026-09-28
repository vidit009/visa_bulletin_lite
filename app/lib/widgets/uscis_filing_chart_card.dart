import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

class UscisFilingChartCard extends StatefulWidget {
  final String chartSelection; // 'Dates for Filing' or 'Final Action Dates'
  final String? note;
  final VoidCallback onShowExplainer;

  const UscisFilingChartCard({
    super.key,
    required this.chartSelection,
    this.note,
    required this.onShowExplainer,
  });

  @override
  State<UscisFilingChartCard> createState() => _UscisFilingChartCardState();
}

class _UscisFilingChartCardState extends State<UscisFilingChartCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFiling = widget.chartSelection.toLowerCase().contains('filing');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFiling
              ? const Color(0xFF0284C7).withValues(alpha: 0.25)
              : const Color(0xFF059669).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable Header Row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isFiling
                          ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                          : const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 16,
                      color: isFiling ? const Color(0xFF0284C7) : const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'USCIS DETERMINATION',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isFiling
                                    ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                                    : const Color(0xFF059669).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isFiling ? 'FILING ALLOWED' : 'FINAL ACTION ONLY',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: isFiling ? const Color(0xFF0284C7) : const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.chartSelection.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            color: isFiling ? const Color(0xFF0284C7) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'What is this?',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.help_outline_rounded, size: 16),
                    onPressed: widget.onShowExplainer,
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.note ??
                        'Applicants seeking to file for adjustment of status with USCIS must use the ${widget.chartSelection} chart to determine when to submit their application.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(AppConstants.officialUscisUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Official USCIS Guidance Page',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF0284C7)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
