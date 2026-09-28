import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/bulletin.dart';
import 'preferences_service.dart';

class BulletinApiService {
  static Bulletin? _inMemoryCachedBulletin;

  /// Fetches the latest Visa Bulletin:
  /// 1. Tries live HTTP GET from user-configured custom URL or AppConstants.defaultApiUrl.
  /// 2. If successful, automatically caches the JSON locally for instant offline startup.
  /// 3. If offline/error, seamlessly loads from persistent device cache.
  /// 4. If first run without network, falls back to bundled asset seed.
  static Future<Bulletin> fetchBulletin({String? customUrl}) async {
    final configuredCustom = await PreferencesService.getCustomApiUrl();
    final url = customUrl ??
        (configuredCustom != null && configuredCustom.isNotEmpty
            ? configuredCustom
            : (AppConstants.defaultApiUrl.isNotEmpty ? AppConstants.defaultApiUrl : null));

    if (url != null && url.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
          await PreferencesService.saveCachedBulletinJson(res.body);
          final parsed = Bulletin.fromJson(jsonDecode(res.body));
          _inMemoryCachedBulletin = parsed;
          return parsed;
        } else {
          debugPrint('Bulletin API server returned status ${res.statusCode}');
        }
      } catch (e) {
        debugPrint('Remote bulletin fetch failed, checking local persistent cache: $e');
      }
    }

    // Check device persistent disk cache (previously fetched live bulletin)
    final cached = await PreferencesService.getCachedBulletinJson();
    if (cached != null && cached.isNotEmpty) {
      try {
        final parsed = Bulletin.fromJson(jsonDecode(cached));
        _inMemoryCachedBulletin = parsed;
        return parsed;
      } catch (e) {
        debugPrint('Error parsing cached bulletin JSON: $e');
      }
    }

    if (_inMemoryCachedBulletin != null) {
      return _inMemoryCachedBulletin!;
    }

    // Initial fallback seed
    return loadFallbackBulletin();
  }

  static Future<Bulletin> loadFallbackBulletin() async {
    if (_inMemoryCachedBulletin != null) {
      return _inMemoryCachedBulletin!;
    }
    final rawJson = await rootBundle.loadString('assets/sample_bulletin.json');
    final parsed = Bulletin.fromJson(jsonDecode(rawJson));
    _inMemoryCachedBulletin = parsed;
    return parsed;
  }
}
