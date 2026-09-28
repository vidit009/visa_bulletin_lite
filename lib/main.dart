import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';

// Re-export all domain models, services, constants, and widgets for clean architecture & test compatibility
export 'constants/app_constants.dart';
export 'constants/country_data.dart';
export 'constants/visa_categories.dart';
export 'models/bulletin.dart';
export 'models/movement_info.dart';
export 'screens/dashboard_screen.dart';
export 'screens/onboarding_screen.dart';
export 'services/background_service.dart';
export 'services/bulletin_api_service.dart';
export 'services/notification_service.dart';
export 'services/preferences_service.dart';
export 'widgets/all_categories_breakdown.dart';
export 'widgets/beacon_brief_card.dart';
export 'widgets/bulletin_status_callout.dart';
export 'widgets/category_selector_sheet.dart';
export 'widgets/chart_explainer_dialog.dart';
export 'widgets/country_picker_sheet.dart';
export 'widgets/disclaimer_card.dart';
export 'widgets/filter_controls.dart';
export 'widgets/header_status_banner.dart';
export 'widgets/movement_badge.dart';
export 'widgets/notification_preferences_sheet.dart';
export 'widgets/other_categories_card.dart';
export 'widgets/uscis_filing_chart_card.dart';
export 'widgets/your_beacon_card.dart';
export 'widgets/your_category_card.dart';

const apiUrl = AppConstants.defaultApiUrl;
const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
const firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (firebaseApiKey.isEmpty) return;
  await Firebase.initializeApp(options: firebaseOptions());
}

FirebaseOptions firebaseOptions() => FirebaseOptions(
  apiKey: firebaseApiKey,
  appId: firebaseAppId,
  messagingSenderId: firebaseMessagingSenderId,
  projectId: firebaseProjectId,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize local notifications with high importance channel
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Local notifications init error: $e');
  }

  // 2. Initialize Firebase if environment configurations are supplied
  if (firebaseApiKey.isNotEmpty && firebaseAppId.isNotEmpty && firebaseProjectId.isNotEmpty) {
    try {
      await Firebase.initializeApp(options: firebaseOptions());
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      await FirebaseMessaging.instance.subscribeToTopic('visa-bulletin');
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
  }

  // 3. Register Workmanager background daily check
  initWorkmanager();

  runApp(const BulletinBeaconApp());
}

/// Backwards compatibility alias for DashboardScreen
class HomePage extends DashboardScreen {
  const HomePage({super.key});
}

class BulletinBeaconApp extends StatelessWidget {
  const BulletinBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
      surface: Colors.white,
      surfaceContainerLowest: const Color(0xFFF8FAFC),
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6),
      brightness: Brightness.dark,
      surface: const Color(0xFF111827),
      surfaceContainerLowest: const Color(0xFF0F172A),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AppHome(),
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final completed = await PreferencesService.isOnboardingCompleted();
    if (mounted) {
      setState(() => _onboardingCompleted = completed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingCompleted == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_onboardingCompleted!) {
      return OnboardingScreen(
        onSetupComplete: () {
          setState(() => _onboardingCompleted = true);
        },
      );
    }

    return const DashboardScreen();
  }
}

/// Backwards compatibility alias for tests
typedef VisaBulletinApp = BulletinBeaconApp;
