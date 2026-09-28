import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyCountry = 'country';
  static const String keyCategory = 'category';
  static const String keyTrack = 'track';
  static const String keyChart = 'chart';
  static const String keyLastCheckedTimestamp = 'last_checked_timestamp';
  static const String keyLastNotifiedMonth = 'last_notified_month';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyCustomApiUrl = 'custom_api_url';
  static const String keyCachedBulletinJson = 'cached_bulletin_json';

  static Future<Map<String, dynamic>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'country': prefs.getString(keyCountry) ?? 'India',
      'category': prefs.getString(keyCategory) ?? 'EB-2',
      'track': prefs.getString(keyTrack) ?? 'employment',
      'chart': prefs.getString(keyChart) ?? 'final',
      'last_checked_timestamp': prefs.getInt(keyLastCheckedTimestamp),
      'last_notified_month': prefs.getString(keyLastNotifiedMonth),
      'onboarding_completed': prefs.getBool(keyOnboardingCompleted) ?? false,
      'custom_api_url': prefs.getString(keyCustomApiUrl),
    };
  }

  static Future<void> savePreferences({
    required String country,
    required String category,
    required String track,
    required String chart,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCountry, country);
    await prefs.setString(keyCategory, category);
    await prefs.setString(keyTrack, track);
    await prefs.setString(keyChart, chart);
  }

  static Future<void> setLastNotifiedMonth(String month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyLastNotifiedMonth, month);
  }

  static Future<void> setLastCheckedTimestamp(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyLastCheckedTimestamp, time.millisecondsSinceEpoch);
  }

  static Future<void> setCustomApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCustomApiUrl, url.trim());
  }

  static Future<String?> getCustomApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyCustomApiUrl);
  }

  static Future<void> saveCachedBulletinJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCachedBulletinJson, json);
  }

  static Future<String?> getCachedBulletinJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyCachedBulletinJson);
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyOnboardingCompleted, value);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyOnboardingCompleted) ?? false;
  }
}
