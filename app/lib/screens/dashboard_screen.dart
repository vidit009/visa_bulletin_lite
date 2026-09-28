import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../constants/country_data.dart';
import '../constants/visa_categories.dart';
import '../models/bulletin.dart';
import '../models/movement_info.dart';
import '../services/background_service.dart';
import '../services/bulletin_api_service.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../widgets/all_categories_breakdown.dart';
import '../widgets/beacon_brief_card.dart';
import '../widgets/bulletin_status_callout.dart';
import '../widgets/category_selector_sheet.dart';
import '../widgets/chart_explainer_dialog.dart';
import '../widgets/country_picker_sheet.dart';
import '../widgets/disclaimer_card.dart';
import '../widgets/filter_controls.dart';
import '../widgets/header_status_banner.dart';
import '../widgets/notification_preferences_sheet.dart';
import '../widgets/uscis_filing_chart_card.dart';
import '../widgets/your_beacon_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  Bulletin? bulletin;
  bool loading = true;
  String? error;
  DateTime? lastCheckedTime;

  String country = 'India';
  String category = 'EB-2';
  String track = 'employment'; // 'employment' or 'family'
  String chart = 'final'; // 'final' (Final Action) or 'filing' (Dates for Filing)

  bool? notificationsEnabled;

  static const List<String> employmentCategories = VisaCategories.employment;
  static const List<String> familyCategories = VisaCategories.family;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferencesAndBulletin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForDailyUpdate();
      NotificationService.areNotificationsEnabled().then((enabled) {
        if (mounted && notificationsEnabled != enabled) {
          setState(() => notificationsEnabled = enabled);
        }
      });
    }
  }

  Future<void> _loadPreferencesAndBulletin() async {
    final prefsMap = await PreferencesService.loadPreferences();
    setState(() {
      country = prefsMap['country'] as String;
      category = prefsMap['category'] as String;
      track = prefsMap['track'] as String;
      chart = prefsMap['chart'] as String;
      final lastMillis = prefsMap['last_checked_timestamp'] as int?;
      if (lastMillis != null) {
        lastCheckedTime = DateTime.fromMillisecondsSinceEpoch(lastMillis);
      }
    });

    await _fetchBulletin(isDailyCheck: true);

    // Proactively check and prompt notification permissions if not prompted before
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final prompted = prefs.getBool('notification_permission_prompted') ?? false;
      if (!prompted) {
        await prefs.setBool('notification_permission_prompted', true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          final granted = await NotificationService.requestPermissions();
          final enabled = await NotificationService.areNotificationsEnabled();
          setState(() {
            notificationsEnabled = granted || enabled;
          });
        }
      } else {
        final enabled = await NotificationService.areNotificationsEnabled();
        if (mounted) {
          setState(() {
            notificationsEnabled = enabled;
          });
        }
      }
    });
  }

  Future<void> _savePreferences() async {
    await PreferencesService.savePreferences(
      country: country,
      category: category,
      track: track,
      chart: chart,
    );
    initWorkmanager();
  }

  Future<void> _checkForDailyUpdate() async {
    if (lastCheckedTime != null) {
      final now = DateTime.now();
      if (now.difference(lastCheckedTime!).inMinutes < 15) return;
    }
    await _fetchBulletin(isDailyCheck: true);
  }

  Future<void> _fetchBulletin({bool isDailyCheck = false}) async {
    setState(() {
      loading = bulletin == null;
      error = null;
    });

    try {
      final parsed = await BulletinApiService.fetchBulletin();
      final now = DateTime.now();
      await PreferencesService.setLastCheckedTimestamp(now);

      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedMonth = prefs.getString('last_notified_month');

      if (lastNotifiedMonth != null && lastNotifiedMonth != parsed.month) {
        final mode = prefs.getString('notification_mode') ?? 'myCategory';
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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'New ${parsed.month} bulletin got published! Dashboard updated with the new details.',
              ),
              backgroundColor: const Color(0xFF1E3A8A),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (lastNotifiedMonth == null) {
        await PreferencesService.setLastNotifiedMonth(parsed.month);
      }

      if (mounted) {
        setState(() {
          bulletin = parsed;
          loading = false;
          lastCheckedTime = now;
        });
      }
    } catch (e) {
      debugPrint('Bulletin fetch error: $e');
      if (mounted) {
        setState(() {
          loading = false;
          error = 'Could not fetch live bulletin. Using latest cached records.';
        });
      }
      try {
        final fallback = await rootBundle.loadString('assets/sample_bulletin.json');
        final parsed = Bulletin.fromJson(jsonDecode(fallback));
        if (mounted) {
          setState(() {
            bulletin = parsed;
          });
        }
      } catch (_) {}
    }
  }

  void _openCountrySearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryPickerSheet(
        selectedCountry: country,
        onSelectCountry: (selected) {
          setState(() => country = selected);
          _savePreferences();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chargeability set to $selected (${getChargeabilityKey(selected)})'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _openCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectorSheet(
        initialCountry: country,
        initialCategory: category,
        initialTrack: track,
        employmentCategories: employmentCategories,
        familyCategories: familyCategories,
        onPickCountry: _openCountrySearch,
        onSelected: (newTrack, newCategory) {
          setState(() {
            track = newTrack;
            category = newCategory;
          });
          _savePreferences();
        },
      ),
    );
  }

  void _switchSelectedCategory(String newCategory) async {
    setState(() {
      category = newCategory;
    });
    await _savePreferences();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated your category to $newCategory ($country)'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openNotificationPreferences() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPreferencesSheet(
        currentCategory: category,
        currentCountry: country,
        onSendTestNotification: _sendTestNotification,
      ),
    );
  }

  Future<void> _sendTestNotification([String? mode]) async {
    await NotificationService.requestPermissions();

    final prefs = await SharedPreferences.getInstance();
    final effectiveMode = mode ?? prefs.getString('notification_mode') ?? 'myCategory';

    final chargeKey = getChargeabilityKey(country);
    final finalTable = bulletin?.tables['${track}_final'] ?? {};
    final prevFinalTable = bulletin?.previousTables['${track}_final'] ?? {};
    final nowVal = finalTable[category]?[chargeKey] ?? '—';
    final prevVal = prevFinalTable[category]?[chargeKey];
    final movement = calculateMovement(prevVal, nowVal);

    final filingTable = bulletin?.tables['${track}_filing'] ?? {};
    final prevFilingTable = bulletin?.previousTables['${track}_filing'] ?? {};
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
      month: bulletin?.month ?? 'Latest',
      userCategory: category,
      country: country,
      movementText: movement.summary,
      finalActionText: finalActionText,
      filingText: filingText,
      uscisChartText: bulletin?.uscisFilingChart ?? 'Dates for Filing',
      notificationMode: effectiveMode,
      movement: movement,
    );

    if (mounted) {
      final modeTitles = {
        'myCategory': 'My Category & Changes',
        'bulletinAlert': 'All Bulletin Alerts',
        'importantMovement': 'Important Movement Only',
      };
      final label = modeTitles[effectiveMode] ?? effectiveMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent for "$label"! Check your notification tray.'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showChartExplainer() {
    showDialog(
      context: context,
      builder: (context) => const ChartExplainerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading && bulletin == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              const Text(
                'Checking Visa Bulletin...',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Connecting to official Department of State records',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final b = bulletin!;
    final chargeKey = getChargeabilityKey(country);

    // Retrieve both Final Action and Filing tables
    final finalActionTable = b.tables['${track}_final'] ?? {};
    final prevFinalActionTable = b.previousTables['${track}_final'] ?? {};
    final filingTable = b.tables['${track}_filing'] ?? {};
    final prevFilingTable = b.previousTables['${track}_filing'] ?? {};

    // For user's category
    final userFinalVal = finalActionTable[category]?[chargeKey] ?? '—';
    final userPrevFinalVal = prevFinalActionTable[category]?[chargeKey];
    final userFinalMovement = calculateMovement(userPrevFinalVal, userFinalVal);

    final userFilingVal = filingTable[category]?[chargeKey] ?? '—';
    final userPrevFilingVal = prevFilingTable[category]?[chargeKey];
    final userFilingMovement = calculateMovement(userPrevFilingVal, userFilingVal);

    // Calculate Month Movement Summary (10-Second Bulletin)
    final monthSummary = calculateMonthSummary(
      currentTable: finalActionTable,
      previousTable: prevFinalActionTable,
    );

    final categories = track == 'employment' ? employmentCategories : familyCategories;
    final otherCategories = categories.where((c) => c != category).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notification Preferences',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: _openNotificationPreferences,
          ),
          IconButton(
            tooltip: 'Refresh Bulletin',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchBulletin(isDailyCheck: false),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchBulletin(isDailyCheck: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. Header Banner: Month, publication date, sync status, beacon emblem
            HeaderStatusBanner(
              month: b.month,
              publishedAt: b.publishedAt,
              previousMonth: b.previousMonth,
              lastChecked: lastCheckedTime,
              onRefresh: () => _fetchBulletin(isDailyCheck: false),
            ),

            const SizedBox(height: 10),

            // 1b. Publication Status Shout-out & Clarification
            BulletinStatusCallout(
              bulletinMonth: b.month,
              publishedAt: b.publishedAt,
              onRefresh: () => _fetchBulletin(isDailyCheck: false),
            ),

            if (error != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(color: Colors.amber.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Notification Disabled Alert Banner (with Enable button)
            if (notificationsEnabled == false)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notification alerts are disabled. Enable them to be alerted when new Visa Bulletin dates are issued.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber.shade200
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () async {
                        final granted = await NotificationService.requestPermissions();
                        final enabled = await NotificationService.areNotificationsEnabled();
                        setState(() => notificationsEnabled = granted || enabled);
                      },
                      child: const Text('Enable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // 3. Track, Chart, and Country Filter Controls
            FilterControls(
              track: track,
              chart: chart,
              country: country,
              onTrackChanged: (newTrack) {
                final cats = newTrack == 'employment' ? employmentCategories : familyCategories;
                setState(() {
                  track = newTrack;
                  if (!cats.contains(category)) {
                    category = cats.first;
                  }
                });
                _savePreferences();
              },
              onChartChanged: (newChart) {
                setState(() => chart = newChart);
                _savePreferences();
              },
              onCountryTap: _openCountrySearch,
              onShowExplainer: _showChartExplainer,
            ),

            const SizedBox(height: 12),

            // 4. TOP CARD: "★ YOUR BEACON" (Final Action + Dates for Filing + USCIS status)
            YourBeaconCard(
              category: category,
              country: country,
              chargeabilityKey: chargeKey,
              track: track,
              finalActionValue: userFinalVal,
              finalActionPrevious: userPrevFinalVal,
              finalActionMovement: userFinalMovement,
              filingValue: userFilingVal,
              filingPrevious: userPrevFilingVal,
              filingMovement: userFilingMovement,
              uscisFilingChart: b.uscisFilingChart,
              onEdit: _openCategorySelector,
              onShowExplainer: _showChartExplainer,
            ),

            const SizedBox(height: 12),

            // 5. BEACON BRIEF: "10-SECOND BULLETIN" (Advanced, Unchanged, Retrogressed, Biggest Movement)
            BeaconBriefCard(
              month: b.month,
              summary: monthSummary,
            ),

            const SizedBox(height: 12),

            // 6. USCIS FILING CHART DETERMINATION CARD
            UscisFilingChartCard(
              chartSelection: b.uscisFilingChart,
              note: b.uscisNote,
              onShowExplainer: _showChartExplainer,
            ),

            const SizedBox(height: 12),

            // 7. ALL CATEGORIES / OTHER CATEGORIES BREAKDOWN
            AllCategoriesBreakdown(
              categories: otherCategories,
              finalActionTable: finalActionTable,
              previousFinalActionTable: prevFinalActionTable,
              filingTable: filingTable,
              previousFilingTable: prevFilingTable,
              country: country,
              chargeabilityKey: chargeKey,
              activeUserCategory: category,
              onSelectCategory: _switchSelectedCategory,
            ),

            const SizedBox(height: 12),

            // 8. Government Source & Legal Disclaimer Card
            const DisclaimerCard(),
          ],
        ),
      ),
    );
  }
}
