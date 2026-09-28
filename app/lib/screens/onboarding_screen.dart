import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/country_data.dart';
import '../constants/visa_categories.dart';
import '../services/background_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../widgets/country_picker_sheet.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onSetupComplete;

  const OnboardingScreen({super.key, required this.onSetupComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _track = 'employment';
  String _category = 'EB-2';
  String _country = 'India';
  String _chart = 'final';

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CountryPickerSheet(
        selectedCountry: _country,
        onSelectCountry: (selected) {
          setState(() => _country = selected);
        },
      ),
    );
  }

  Future<void> _completeSetup() async {
    try {
      await PreferencesService.savePreferences(
        country: _country,
        category: _category,
        track: _track,
        chart: _chart,
      );

      try {
        await NotificationService.requestPermissions();
      } catch (_) {}

      try {
        await registerDailyBackgroundCheck();
      } catch (_) {}

      await PreferencesService.setOnboardingCompleted(true);
    } catch (e) {
      debugPrint('Setup error: $e');
    }

    if (mounted) {
      widget.onSetupComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = _track == 'employment' ? VisaCategories.employment : VisaCategories.family;
    final isDedicated = isDedicatedCountry(_country);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Emblem & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Visa Bulletin. The moment it moves.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Welcome Headline
              Text(
                'Set Your Visa Beacon',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us your priority profile once. BulletinBeacon will monitor official U.S. Department of State releases daily and alert you the second your date moves.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Track Selector
              _buildSectionLabel('1. IMMIGRATION TRACK'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'employment',
                    label: Text('Employment (EB)', style: TextStyle(fontWeight: FontWeight.w700)),
                    icon: Icon(Icons.work_outline_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 'family',
                    label: Text('Family (F)', style: TextStyle(fontWeight: FontWeight.w700)),
                    icon: Icon(Icons.family_restroom_rounded, size: 16),
                  ),
                ],
                selected: {_track},
                onSelectionChanged: (s) {
                  setState(() {
                    _track = s.first;
                    final newCats = _track == 'employment' ? VisaCategories.employment : VisaCategories.family;
                    if (!newCats.contains(_category)) {
                      _category = newCats.first;
                    }
                  });
                },
              ),

              const SizedBox(height: 20),

              // 3. Category Selector Chips
              _buildSectionLabel('2. YOUR CATEGORY'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // 4. Country of Chargeability
              _buildSectionLabel('3. COUNTRY OF CHARGEABILITY / BIRTH'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _openCountryPicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D31) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded, size: 20, color: Color(0xFF0284C7)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _country,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                            ),
                            Text(
                              isDedicated ? 'Dedicated country cutoff date' : 'Mapped to All Chargeability (Worldwide)',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Filing Chart Type
              _buildSectionLabel('4. PRIMARY FILING CHART'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'final',
                    label: Text('Final Action Dates', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  ButtonSegment(
                    value: 'filing',
                    label: Text('Dates for Filing', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
                selected: {_chart},
                onSelectionChanged: (s) => setState(() => _chart = s.first),
              ),
              const SizedBox(height: 6),
              Text(
                _chart == 'final'
                    ? '• Final Action Dates govern when a Green Card visa can actually be approved & issued.'
                    : '• Dates for Filing govern when you can submit your I-485 Adjustment of Status application.',
                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black54),
              ),

              const SizedBox(height: 32),

              // 6. Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _completeSetup,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.radar_rounded, size: 20),
                  label: const Text(
                    'Activate My Beacon & Start',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  '100% on-device local privacy • No account required • Daily automated checks',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: Color(0xFF0284C7),
      ),
    );
  }
}
