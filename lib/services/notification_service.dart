import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';
import '../constants/country_data.dart';
import '../models/movement_info.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        description: 'Notifies when a new U.S. Visa Bulletin is issued',
        importance: Importance.max,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Explicitly request notification permissions (required for Android 13+ and iOS store compliance)
  static Future<bool> requestPermissions() async {
    if (!_initialized) return true;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.requestNotificationsPermission() ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        return await iosImpl?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
    return true;
  }

  /// Check if notifications are currently enabled
  static Future<bool> areNotificationsEnabled() async {
    if (!_initialized) return true;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
    }
    return true;
  }
}

Future<void> showBulletinLocalNotification({
  required String month,
  required String userCategory,
  required String country,
  required String movementText,
  String? finalActionText,
  String? filingText,
  String? uscisChartText,
  String notificationMode = 'myCategory',
  MovementInfo? movement,
}) async {
  final flag = getCountryFlag(country);
  String title;
  String bodyText;

  switch (notificationMode) {
    case 'bulletinAlert':
      // Mode 1: Bulletin Alert
      // Clean, general alert that a new monthly bulletin is published
      title = '🔔 $month Visa Bulletin is out';
      bodyText = '$month Visa Bulletin has been published.';
      break;

    case 'importantMovement':
      // Mode 3: Important Movement
      // Explicitly highlights significant category date changes or retrogressions
      final days = movement?.days ?? 0;
      final mType = movement?.type ?? MovementType.unchanged;

      if (mType == MovementType.retrogressed || mType == MovementType.becameUnavailable) {
        title = '⚠️ $userCategory $country Movement Alert';
        final durationText = days != 0 ? '${days.abs()} days' : 'retrogressed';
        bodyText = '$flag $userCategory $country retrogressed $durationText in the $month Bulletin.';
      } else if (mType == MovementType.advanced || mType == MovementType.becameCurrent || mType == MovementType.restored) {
        title = '🚀 $userCategory $country Movement Alert';
        final durationText = days != 0 ? '$days days' : 'advanced';
        bodyText = '$flag $userCategory $country advanced $durationText in the $month Bulletin.';
      } else {
        title = '⚪ $userCategory $country Update';
        bodyText = '$flag $userCategory $country had no date movement in the $month Bulletin.';
      }
      if (finalActionText != null && finalActionText.isNotEmpty) {
        bodyText += '\nFinal Action: $finalActionText';
      }
      break;

    case 'myCategory':
    default:
      // Mode 2: My Category & Changes (Beacon Brief)
      // Instant alert with specific movement + cutoff comparisons + USCIS filing chart status
      title = '🔔 $month Bulletin is out';
      final buffer = StringBuffer('$flag Your $userCategory category $movementText in the $month Bulletin.');
      if (finalActionText != null && finalActionText.isNotEmpty) {
        buffer.write('\nFinal Action: $finalActionText');
      }
      if (filingText != null && filingText.isNotEmpty) {
        buffer.write('\nFiling Date: $filingText');
      }
      if (uscisChartText != null && uscisChartText.isNotEmpty) {
        buffer.write('\nUSCIS this month: Use $uscisChartText');
      }
      bodyText = buffer.toString();
      break;
  }

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    AppConstants.notificationChannelId,
    AppConstants.notificationChannelName,
    channelDescription: 'Notifies when a new U.S. Visa Bulletin is issued',
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(bodyText),
    showWhen: true,
    icon: '@mipmap/ic_launcher',
  );

  const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
    macOS: darwinDetails,
  );

  if (!NotificationService._initialized) {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Notification auto-init error: $e');
    }
  }
  if (!NotificationService._initialized) return;
  try {
    await flutterLocalNotificationsPlugin.show(
      id: 1001,
      title: title,
      body: bodyText,
      notificationDetails: notificationDetails,
    );
  } catch (e) {
    debugPrint('Notification dispatch notice: $e');
  }
}
