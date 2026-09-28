import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Store Compliance Disclaimer Card
/// Satisfies Apple App Store Review Guideline 5.2.5 and Google Play Store Government Impersonation Policy.
class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 18, color: Colors.blueGrey.shade600),
              const SizedBox(width: 8),
              Text(
                'Official Data Source & Legal Disclaimer',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.governmentDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.blueGrey.shade600,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('travel.state.gov', style: TextStyle(fontSize: 11)),
                onPressed: () => _openUrl(AppConstants.officialDosUrl),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('USCIS Filing Dates', style: TextStyle(fontSize: 11)),
                onPressed: () => _openUrl(AppConstants.officialUscisUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
