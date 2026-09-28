import 'package:flutter/material.dart';

class ChartExplainerDialog extends StatelessWidget {
  const ChartExplainerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.help_outline_rounded, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Final Action vs Dates for Filing',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ExplainerSection(
              title: '1. Final Action Dates (Green Card Approval)',
              icon: Icons.verified_user_rounded,
              iconColor: Color(0xFF10B981),
              description:
                  'This is when USCIS or the U.S. Consulate can actually issue and approve your Green Card / Immigrant Visa. If your Priority Date is earlier than this date, your visa is officially available.',
            ),
            const SizedBox(height: 16),
            const _ExplainerSection(
              title: '2. Dates for Filing (Submit Application)',
              icon: Icons.post_add_rounded,
              iconColor: Color(0xFF3B82F6),
              description:
                  'This allows you to submit your Form I-485 application package (or DS-260). Even if the final green card is not ready yet, filing gives you an EAD (Work Authorization Card) and Advance Parole (Travel Permit) while waiting.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_rounded, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Important: Each month, USCIS determines whether applicants in the U.S. can use the "Dates for Filing" chart or must use the "Final Action" chart.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it!'),
        ),
      ],
    );
  }
}

class _ExplainerSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String description;

  const _ExplainerSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            description,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.35),
          ),
        ),
      ],
    );
  }
}
