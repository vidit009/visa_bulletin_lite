import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visa_bulletin_lite/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('be.tramckas.workmanager/foreground_channel_work_manager'),
      (MethodCall methodCall) async => true,
    );

    SharedPreferences.setMockInitialValues({
      'country': 'India',
      'category': 'EB-2',
      'track': 'employment',
      'chart': 'final',
      'onboarding_completed': true,
      'last_notified_month': 'August 2026',
      'last_checked_timestamp': DateTime(2026, 9, 27, 14, 30).millisecondsSinceEpoch,
    });
  });

  group('1. Country & Chargeability Area Tests', () {
    test('Dedicated countries map to their specific chargeability area', () {
      expect(getChargeabilityKey('India'), 'India');
      expect(getChargeabilityKey('China'), 'China');
      expect(getChargeabilityKey('Mexico'), 'Mexico');
      expect(getChargeabilityKey('Philippines'), 'Philippines');
      expect(isDedicatedCountry('India'), isTrue);
      expect(isDedicatedCountry('China'), isTrue);
      expect(isDedicatedCountry('Mexico'), isTrue);
      expect(isDedicatedCountry('Philippines'), isTrue);
    });

    test('All other worldwide countries map to All Chargeability', () {
      expect(getChargeabilityKey('Indonesia'), 'All Chargeability');
      expect(getChargeabilityKey('Canada'), 'All Chargeability');
      expect(getChargeabilityKey('United Kingdom'), 'All Chargeability');
      expect(getChargeabilityKey('Pakistan'), 'All Chargeability');
      expect(getChargeabilityKey('Nigeria'), 'All Chargeability');
      expect(getChargeabilityKey('All Chargeability (Worldwide)'), 'All Chargeability');
      expect(isDedicatedCountry('Indonesia'), isFalse);
      expect(isDedicatedCountry('Canada'), isFalse);
    });

    test('Country search filters by prefix and case-insensitive query (e.g. "In")', () {
      const query = 'In';
      final matches = allWorldCountries
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(matches.contains('India'), isTrue);
      expect(matches.contains('Indonesia'), isTrue);
      expect(matches.contains('Finland'), isTrue);
      expect(matches.contains('Argentina'), isTrue);
    });
  });

  group('2. Date Parsing, Formatting & Movement Calculations', () {
    test('parseDosDate handles standard DOS format DDMMMYY', () {
      final oct22 = parseDosDate('15OCT22');
      expect(oct22, isNotNull);
      expect(oct22!.year, 2022);
      expect(oct22.month, 10);
      expect(oct22.day, 15);

      final jan14 = parseDosDate('01JAN14');
      expect(jan14, isNotNull);
      expect(jan14!.year, 2014);
      expect(jan14.month, 1);
      expect(jan14.day, 1);
    });

    test('parseDosDate handles special non-date values', () {
      expect(parseDosDate('C'), isNull);
      expect(parseDosDate('U'), isNull);
      expect(parseDosDate(''), isNull);
      expect(parseDosDate(null), isNull);
    });

    test('formatCutoffDate formats dates and codes for users', () {
      expect(formatCutoffDate('C'), 'Current');
      expect(formatCutoffDate('U'), 'Unavailable');
      expect(formatCutoffDate('15OCT22'), '15 Oct 2022');
      expect(formatCutoffDate('01JAN14'), '01 Jan 2014');
    });

    test('calculateMovement detects advancement', () {
      final m = calculateMovement('15JUL22', '15OCT22');
      expect(m.type, MovementType.advanced);
      expect(m.label.contains('Advanced'), isTrue);
      expect(m.days, 92);
      expect(m.shortLabel.contains('+'), isTrue);
    });

    test('calculateMovement detects retrogression', () {
      final m = calculateMovement('15OCT22', '15JUL22');
      expect(m.type, MovementType.retrogressed);
      expect(m.label.contains('Retrogressed'), isTrue);
      expect(m.days, -92);
    });

    test('calculateMovement detects unchanged dates', () {
      final m = calculateMovement('15OCT22', '15OCT22');
      expect(m.type, MovementType.unchanged);
      expect(m.shortLabel, 'No change');
    });

    test('calculateMovement detects became current or unavailable', () {
      final current = calculateMovement('15OCT22', 'C');
      expect(current.type, MovementType.becameCurrent);
      expect(current.shortLabel, 'Current');

      final unavail = calculateMovement('15OCT22', 'U');
      expect(unavail.type, MovementType.becameUnavailable);
      expect(unavail.shortLabel, 'Unavailable');

      final restored = calculateMovement('U', '15OCT22');
      expect(restored.type, MovementType.restored);
      expect(restored.shortLabel, 'Restored');
    });
  });

  group('3. Bulletin Model & Parser Tests', () {
    test('Bulletin.fromJson parses all fields including published date and tables', () {
      final json = {
        'month': 'September 2026',
        'publishedAt': '2026-08-12T12:00:00Z',
        'previousMonth': 'August 2026',
        'sourceUrl': 'https://travel.state.gov/visa-bulletin',
        'tables': {
          'employment_final': {
            'EB-2': {
              'India': 'U',
              'China': '01SEP21',
              'All Chargeability': 'C',
            }
          }
        },
        'previousTables': {
          'employment_final': {
            'EB-2': {
              'India': 'U',
              'China': '01JUL21',
              'All Chargeability': 'C',
            }
          }
        }
      };

      final b = Bulletin.fromJson(json);
      expect(b.month, 'September 2026');
      expect(b.publishedAt, '2026-08-12T12:00:00Z');
      expect(b.previousMonth, 'August 2026');
      expect(b.tables['employment_final']?['EB-2']?['India'], 'U');
      expect(b.tables['employment_final']?['EB-2']?['China'], '01SEP21');
      expect(b.previousTables['employment_final']?['EB-2']?['China'], '01JUL21');
    });
  });

  group('4. Component Unit & Widget Tests', () {
    testWidgets('Explainer Dialog displays both Final Action and Filing explanation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChartExplainerDialog(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Final Action vs Dates for Filing'), findsOneWidget);
      expect(find.text('1. Final Action Dates (Green Card Approval)'), findsOneWidget);
      expect(find.text('2. Dates for Filing (Submit Application)'), findsOneWidget);
      expect(find.text('Got it!'), findsOneWidget);
    });

    testWidgets('Searchable Country Picker searches and selects a country', (tester) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountryPickerSheet(
              selectedCountry: 'India',
              onSelectCountry: (c) => selected = c,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Select Country / Chargeability'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Search for "In"
      await tester.enterText(find.byType(TextField), 'In');
      await tester.pump();

      expect(find.text('India'), findsOneWidget);
      expect(find.text('Indonesia'), findsOneWidget);

      // Tap Indonesia
      await tester.tap(find.text('Indonesia'));
      await tester.pump();

      expect(selected, 'Indonesia');
    });

    testWidgets('Header Status Banner shows latest bulletin date and daily check status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeaderStatusBanner(
              month: 'September 2026',
              publishedAt: '2026-08-12T12:00:00Z',
              previousMonth: 'August 2026',
              lastChecked: DateTime(2026, 9, 27, 17, 30),
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DAILY CHECK ACTIVE'), findsOneWidget);
      expect(find.text('September 2026 Visa Bulletin'), findsOneWidget);
      expect(find.text('Official U.S. Department of State & USCIS Cutoff Dates'), findsOneWidget);
      expect(find.text('Published: Aug 12, 2026'), findsOneWidget);
      expect(find.text('Compared with: August 2026'), findsOneWidget);
    });

    testWidgets('Bulletin Status Callout displays pending release shout-out and last published date', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BulletinStatusCallout(
              bulletinMonth: 'September 2026',
              publishedAt: '2026-08-12T12:00:00Z',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PENDING NEW RELEASE'), findsOneWidget);
      expect(find.textContaining('bulletin is not yet published'), findsOneWidget);
      expect(find.textContaining('Showing cutoff dates from the last published bulletin'), findsOneWidget);
      expect(find.textContaining('August'), findsWidgets);
    });

    testWidgets('Onboarding Screen allows selecting country, category, and completing setup', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onSetupComplete: () => completed = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Set Your Visa Beacon'), findsOneWidget);
      expect(find.text('1. IMMIGRATION TRACK'), findsOneWidget);
      expect(find.text('2. YOUR CATEGORY'), findsOneWidget);
      expect(find.text('3. COUNTRY OF CHARGEABILITY / BIRTH'), findsOneWidget);
      expect(find.text('4. PRIMARY FILING CHART'), findsOneWidget);
      expect(find.text('Activate My Beacon & Start'), findsOneWidget);

      final btn = find.text('Activate My Beacon & Start');
      await tester.ensureVisible(btn);
      await tester.pumpAndSettle();
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('Your Category Card shows category, country, dates and movement', (tester) async {
      final movement = calculateMovement('15JUL22', '15OCT22');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YourCategoryCard(
              category: 'EB-2',
              country: 'India',
              chargeabilityKey: 'India',
              track: 'employment',
              chart: 'final',
              currentValue: '15OCT22',
              previousValue: '15JUL22',
              movement: movement,
              onEdit: () {},
              onShowExplainer: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('YOUR CATEGORY'), findsOneWidget);
      expect(find.text('EB-2'), findsOneWidget);
      expect(find.text('India'), findsOneWidget);
      expect(find.text('15 Oct 2022'), findsOneWidget);
      expect(find.text('15 Jul 2022'), findsOneWidget);
      expect(find.text(movement.label), findsOneWidget);
    });

    testWidgets('Other Categories Card shows all other categories together', (tester) async {
      final currentTable = {
        'EB-1': {'India': '15OCT22'},
        'EB-3': {'India': '01JAN14'},
      };
      final previousTable = {
        'EB-1': {'India': '15OCT22'},
        'EB-3': {'India': '01JAN14'},
      };

      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtherCategoriesCard(
              categories: const ['EB-1', 'EB-3'],
              currentTable: currentTable,
              previousTable: previousTable,
              country: 'India',
              chargeabilityKey: 'India',
              chart: 'final',
              onSelectCategory: (c) => selected = c,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Other Categories'), findsOneWidget);
      expect(find.text('EB-1'), findsOneWidget);
      expect(find.text('EB-3'), findsOneWidget);

      await tester.tap(find.text('EB-1'));
      await tester.pump();

      expect(selected, 'EB-1');
    });
  });

  group('5. Full App End-to-End User Flow Test', () {
    testWidgets('Loads dashboard, displays cards, switches filters, and updates category', (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const VisaBulletinApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // 1. Verify Header and App title
      expect(find.text('BulletinBeacon'), findsOneWidget);
      expect(find.text('DAILY CHECK ACTIVE'), findsOneWidget);
      expect(find.textContaining('Visa Bulletin'), findsWidgets);

      // 2. Verify new bulletin published notification alert banner
      expect(
        find.textContaining('New September 2026 bulletin got published! Dashboard updated with the new details.'),
        findsOneWidget,
      );

      // 3. Verify Your Beacon Top Card
      expect(find.text('YOUR BEACON'), findsOneWidget);
      expect(find.textContaining('EB-2'), findsWidgets);

      // 4. Verify Other Categories Card
      expect(find.text('Other Categories'), findsOneWidget);

      // 5. Test Explainer Dialog button
      final infoBtn = find.byTooltip('What is Final Action vs Dates for Filing?');
      expect(infoBtn, findsOneWidget);
      await tester.tap(infoBtn);
      await tester.pumpAndSettle();
      expect(find.text('Final Action vs Dates for Filing'), findsOneWidget);
      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();

      // 6. Test Country Picker search
      await tester.tap(find.byIcon(Icons.public_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Select Country / Chargeability'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'In');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'India'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Indonesia'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Indonesia'));
      await tester.pumpAndSettle();

      // Dashboard now displays Indonesia
      expect(find.textContaining('Indonesia'), findsWidgets);

      // 7. Test Switch Chart to Dates for Filing
      await tester.tap(find.text('Dates for Filing'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chart'), 'filing');
      expect(prefs.getString('last_notified_month'), 'September 2026');

      // 8. Test Select category from Other Categories
      final eb1 = find.text('EB-1').first;
      await tester.tap(eb1);
      await tester.pumpAndSettle();
      expect(prefs.getString('category'), 'EB-1');
    });

    testWidgets('App fresh install launches onboarding, saves preferences, and transitions to dashboard', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': false,
      });

      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const VisaBulletinApp());
      await tester.pumpAndSettle();

      // Verify Onboarding Screen is shown on fresh install
      expect(find.text('Set Your Visa Beacon'), findsOneWidget);
      expect(find.text('Activate My Beacon & Start'), findsOneWidget);

      // Select Family track
      await tester.tap(find.text('Family (F)'));
      await tester.pumpAndSettle();

      // Tap Activate
      final btn = find.text('Activate My Beacon & Start');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();

      // Wait for async preference storage and bulletin loading to complete
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.text('YOUR BEACON').evaluate().isNotEmpty) break;
      }

      // Verify it transitions to DashboardScreen
      expect(find.text('BulletinBeacon'), findsOneWidget);
      expect(find.text('YOUR BEACON'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_completed'), isTrue);
      expect(prefs.getString('track'), 'family');

      // Flush post-frame permission check timer
      await tester.pump(const Duration(milliseconds: 800));
    });
  });

  group('6. Resilience, Error Handling & System Stability Tests', () {
    test('Corrupted cached JSON falls back safely without crashing', () async {
      await PreferencesService.saveCachedBulletinJson('{malformed json : true, broken');
      final bulletin = await BulletinApiService.fetchBulletin();
      expect(bulletin, isNotNull);
      expect(bulletin.tables, isNotEmpty);
    });

    test('Bulletin.fromJson handles empty, malformed, or missing structure safely', () {
      final empty = Bulletin.fromJson({});
      expect(empty.month, 'Current');
      expect(empty.tables, isEmpty);
      expect(empty.previousTables, isEmpty);

      final weirdTypes = Bulletin.fromJson({
        'tables': 'not-a-map',
        'previousTables': null,
        'uscisFilingChart': {'random': 'field'},
      });
      expect(weirdTypes.tables, isEmpty);
      expect(weirdTypes.previousTables, isEmpty);
    });

    test('performBackgroundDailyBulletinCheck runs safely without unhandled exceptions', () async {
      await PreferencesService.savePreferences(
        country: 'India',
        category: 'EB-2',
        track: 'employment',
        chart: 'final',
      );
      await performBackgroundDailyBulletinCheck();
      final prefs = await PreferencesService.loadPreferences();
      expect(prefs['last_checked_timestamp'], isNotNull);
    });

    test('showBulletinLocalNotification handles all modes, retrogressions, and current states safely', () async {
      // 1. Bulletin alert mode
      await showBulletinLocalNotification(
        month: 'October 2026',
        userCategory: 'EB-2',
        country: 'India',
        movementText: 'advanced 30 days',
        notificationMode: 'bulletinAlert',
      );

      // 2. Important movement mode (retrogression)
      await showBulletinLocalNotification(
        month: 'October 2026',
        userCategory: 'EB-2',
        country: 'India',
        movementText: 'retrogressed 90 days',
        notificationMode: 'importantMovement',
        movement: calculateMovement('15OCT22', '15JUL22'),
      );

      // 3. Important movement mode (became Current)
      await showBulletinLocalNotification(
        month: 'October 2026',
        userCategory: 'EB-1',
        country: 'All Chargeability',
        movementText: 'became Current',
        notificationMode: 'importantMovement',
        movement: calculateMovement('15OCT22', 'C'),
      );

      // 4. Important movement mode (unchanged)
      await showBulletinLocalNotification(
        month: 'October 2026',
        userCategory: 'EB-2',
        country: 'China',
        movementText: 'remained unchanged',
        notificationMode: 'importantMovement',
        movement: calculateMovement('15OCT22', '15OCT22'),
      );

      // 5. My Category & Changes mode (with filing text & USCIS chart note)
      await showBulletinLocalNotification(
        month: 'October 2026',
        userCategory: 'EB-2',
        country: 'India',
        movementText: 'advanced 45 days',
        finalActionText: '15OCT20 → 01DEC20',
        filingText: '01JAN21 → 15FEB21',
        uscisChartText: 'Dates for Filing',
        notificationMode: 'myCategory',
        movement: calculateMovement('15OCT20', '01DEC20'),
      );
    });

    test('parseDosDate handles strange dates, leap days, and edge cases', () {
      expect(parseDosDate(null), isNull);
      expect(parseDosDate(''), isNull);
      expect(parseDosDate('INVALID_DATE'), isNull);
      expect(parseDosDate('C'), isNull);
      expect(parseDosDate('U'), isNull);

      // Leap day 2024
      final leap = parseDosDate('29FEB24');
      expect(leap, isNotNull);
      expect(leap!.year, 2024);
      expect(leap.month, 2);
      expect(leap.day, 29);
    });

    test('Custom API URL saves and clears reliably in PreferencesService', () async {
      await PreferencesService.setCustomApiUrl('https://api.myvisaapp.com/v1/bulletin.json');
      expect(await PreferencesService.getCustomApiUrl(), 'https://api.myvisaapp.com/v1/bulletin.json');
      await PreferencesService.setCustomApiUrl('');
      expect(await PreferencesService.getCustomApiUrl(), '');
    });
  });
}
