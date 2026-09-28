import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../constants/app_constants.dart';
import '../constants/country_data.dart';
import '../models/movement_info.dart';
import 'bulletin_api_service.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

const String dailyBulletinTaskKey = AppConstants.backgroundTaskKey;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Background Workmanager executing: $task');
    try {
      await NotificationService.initialize();
      await performBackgroundDailyBulletinCheck();
      return true;
    } catch (err) {
      debugPrint('Background daily check error: $err');
      return false;
    }
  });
}

Future<void> performBackgroundDailyBulletinCheck() async {
  final prefsMap = await PreferencesService.loadPreferences();
  final country = prefsMap['country'] as String;
  final category = prefsMap['category'] as String;
  final track = prefsMap['track'] as String;
  final lastNotifiedMonth = prefsMap['last_notified_month'] as String?;

  try {
    final parsed = await BulletinApiService.fetchBulletin();
    final now = DateTime.now();
    await PreferencesService.setLastCheckedTimestamp(now);

    if (lastNotifiedMonth != null && lastNotifiedMonth != parsed.month) {
      final mode = prefsMap['notification_mode'] as String? ?? 'myCategory';
      final chargeKey = getChargeabilityKey(country);
      final finalTable = parsed.tables['${track}_final'] ?? {};
      final prevFinalTable = parsed.previousTables['${track}_final'] ?? {};
      final nowVal = finalTable[category]?[chargeKey] ?? '—';
      final prevVal = prevFinalTable[category]?[chargeKey];
      final movement = calculateMovement(prevVal, nowVal);

      final filingTable = parsed.tables['${track}_filing'] ?? {};
      final prevFilingTable = parsed.previousTables['${track}_filing'] ?? {};
      final filingNow = filingTable[category]?[chargeKey] ?? '—';
      final filingPrev = prevFilingTable[category]?[chargeKey];
      final filingMovement = calculateMovement(filingPrev, filingNow);

      String? filingText;
      if (filingNow != '—') {
        if (filingPrev != null && filingPrev != filingNow) {
          filingText = '${formatCutoffDate(filingPrev)} → ${formatCutoffDate(filingNow)}';
        } else {
          filingText = '${formatCutoffDate(filingNow)} (${filingMovement.shortLabel})';
        }
      }

      String finalActionText;
      if (prevVal != null && prevVal != nowVal) {
        finalActionText = '${formatCutoffDate(prevVal)} → ${formatCutoffDate(nowVal)}';
      } else {
        finalActionText = '${formatCutoffDate(nowVal)} (${movement.shortLabel})';
      }

      showBulletinLocalNotification(
        month: parsed.month,
        userCategory: category,
        country: country,
        movementText: movement.summary,
        finalActionText: finalActionText,
        filingText: filingText,
        uscisChartText: parsed.uscisFilingChart,
        notificationMode: mode,
        movement: movement,
      );
      await PreferencesService.setLastNotifiedMonth(parsed.month);
    } else if (lastNotifiedMonth == null) {
      await PreferencesService.setLastNotifiedMonth(parsed.month);
    }
  } catch (e) {
    debugPrint('Background check fetch error: $e');
  }
}

void initWorkmanager() {
  if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  try {
    Workmanager().initialize(
      callbackDispatcher,
    );

    Workmanager().registerPeriodicTask(
      'daily-visa-bulletin-check',
      dailyBulletinTaskKey,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint('Workmanager init notice: $e');
  }
}

Future<void> registerDailyBackgroundCheck() async {
  initWorkmanager();
}
