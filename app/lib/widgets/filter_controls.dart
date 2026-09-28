import 'package:flutter/material.dart';
import '../constants/country_data.dart';

class FilterControls extends StatelessWidget {
  final String track;
  final String chart;
  final String country;
  final ValueChanged<String> onTrackChanged;
  final ValueChanged<String> onChartChanged;
  final VoidCallback onCountryTap;
  final VoidCallback onShowExplainer;

  const FilterControls({
    super.key,
    required this.track,
    required this.chart,
    required this.country,
    required this.onTrackChanged,
    required this.onChartChanged,
    required this.onCountryTap,
    required this.onShowExplainer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDedicated = isDedicatedCountry(country);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Employment vs Family Track
        SegmentedButton<String>(
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: const [
            ButtonSegment(
              value: 'employment',
              label: Text('Employment (EB)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              icon: Icon(Icons.work_outline_rounded, size: 15),
            ),
            ButtonSegment(
              value: 'family',
              label: Text('Family (F)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              icon: Icon(Icons.family_restroom_rounded, size: 15),
            ),
          ],
          selected: {track},
          onSelectionChanged: (s) => onTrackChanged(s.first),
        ),

        const SizedBox(height: 8),

        // 2. Searchable Country Button
        InkWell(
          onTap: onCountryTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.public_rounded, size: 17, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: country,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        TextSpan(
                          text: isDedicated ? '  •  Dedicated Area' : '  •  Worldwide',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded, size: 12, color: theme.colorScheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 3. Final Action vs Dates for Filing + Info Icon
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(
                    value: 'final',
                    label: Text('Final Action', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  ButtonSegment(
                    value: 'filing',
                    label: Text('Dates for Filing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
                selected: {chart},
                onSelectionChanged: (s) => onChartChanged(s.first),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              tooltip: 'What is Final Action vs Dates for Filing?',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              onPressed: onShowExplainer,
            ),
          ],
        ),
      ],
    );
  }
}
