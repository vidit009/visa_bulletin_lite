import 'package:flutter/material.dart';

/// Application Constants and Government Disclaimers
/// Required by Google Play & Apple App Store Review Guidelines (5.2.5).
class AppConstants {
  static const String appName = 'BulletinBeacon';
  static const String appVersion = '1.0.0+1';
  static const String appTagline = 'Visa Bulletin. The moment it moves.';
  static const String appSubtitle = 'Visa Bulletin Alerts & Changes';
  static const String appHeadline = 'Stop checking. We\'ll tell you when it moves.';
  static const String appDescription =
      'The Visa Bulletin changes once a month. You shouldn\'t have to keep checking for it. '
      'BulletinBeacon watches for new U.S. Visa Bulletins and alerts you when one is published. '
      'Open the app to instantly see what advanced, what stayed the same, what retrogressed, and what changed for your category.';

  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color accentColor = Color(0xFF3B82F6);

  static const String defaultApiUrl = String.fromEnvironment(
    'BULLETIN_URL',
    defaultValue: 'https://raw.githubusercontent.com/vidit009/visa_bulletin_lite/main/data/current.json',
  );
  static const String officialDosUrl =
      'https://travel.state.gov/content/travel/en/legal/visa-law0/visa-bulletin.html';
  static const String officialUscisUrl =
      'https://www.uscis.gov/green-card/green-card-processes-and-procedures/visa-availability-priority-dates/adjustment-of-status-filing-charts-from-the-visa-bulletin';

  /// Official disclaimer required for store acceptance:
  /// Apps showing immigration cutoff dates must disclose their source and clarify independence.
  static const String governmentDisclaimer =
      'BulletinBeacon is an independent informative application and is not affiliated with, '
      'endorsed by, or representing the U.S. Department of State (DOS), USCIS, or any other government agency. '
      'All Visa Bulletin data is public information sourced directly from the U.S. Department of State (travel.state.gov).';

  static const String backgroundTaskKey = 'com.visabulletin.dailyCheck';
  static const String notificationChannelId = 'visa_bulletin_channel';
  static const String notificationChannelName = 'BulletinBeacon Alerts';
}
