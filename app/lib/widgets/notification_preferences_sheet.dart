import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/preferences_service.dart';

class NotificationPreferencesSheet extends StatefulWidget {
  final String currentCategory;
  final String currentCountry;
  final void Function(String mode) onSendTestNotification;

  const NotificationPreferencesSheet({
    super.key,
    required this.currentCategory,
    required this.currentCountry,
    required this.onSendTestNotification,
  });

  @override
  State<NotificationPreferencesSheet> createState() => _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState extends State<NotificationPreferencesSheet> {
  String _selectedMode = 'myCategory';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationMode();
  }

  Future<void> _loadNotificationMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMode = prefs.getString('notification_mode') ?? 'myCategory';
      _isLoading = false;
    });
  }

  Future<void> _setNotificationMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_mode', mode);
    setState(() => _selectedMode = mode);
    await NotificationService.requestPermissions();
  }

  Future<void> _openDataSourceDialog() async {
    final currentCustom = await PreferencesService.getCustomApiUrl() ?? '';
    final controller = TextEditingController(text: currentCustom);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Live Data Source URL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a custom JSON endpoint (e.g., Azure Function, GitHub Pages, or Cloudflare Worker) to fetch real-time Visa Bulletin updates:',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://your-domain.com/current.json',
                labelText: 'Endpoint URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty to use built-in offline seed and auto-cache.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await PreferencesService.setCustomApiUrl(controller.text);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data source URL saved. Pulling updates...')),
                );
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0284C7), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Preferences',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '100% on-device • No account required',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else ...[
            // Mode 1: My Category (Recommended)
            _buildModeTile(
              modeKey: 'myCategory',
              title: 'My Category & Changes (Recommended)',
              subtitle:
                  'Instant alert with your specific ${widget.currentCategory} (${widget.currentCountry}) date movement + USCIS filing chart status.',
              badge: 'BEACON BRIEF',
              icon: Icons.star_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 10),

            // Mode 2: All Bulletin Alerts
            _buildModeTile(
              modeKey: 'bulletinAlert',
              title: 'All Bulletin Alerts',
              subtitle: 'Notifies when any new monthly bulletin is published, including the 10-second summary.',
              icon: Icons.public_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 10),

            // Mode 3: Important Movement Only
            _buildModeTile(
              modeKey: 'importantMovement',
              title: 'Important Movement Only',
              subtitle: 'Only alerts you if your category advances or retrogresses.',
              icon: Icons.trending_up_rounded,
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 12),

            // Live Data Source Endpoint Button
            OutlinedButton.icon(
              onPressed: _openDataSourceDialog,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.cloud_sync_rounded, size: 16),
              label: const Text(
                'Data Source & Live Sync URL',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),

            const SizedBox(height: 10),

            // Send Test Notification Button
            FilledButton.tonalIcon(
              onPressed: () {
                final mode = _selectedMode;
                Navigator.of(context).pop();
                widget.onSendTestNotification(mode);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                'Send Sample for "${_modeTitle(_selectedMode)}"',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _modeTitle(String mode) {
    switch (mode) {
      case 'bulletinAlert':
        return 'Bulletin Alert';
      case 'importantMovement':
        return 'Important Movement';
      case 'myCategory':
      default:
        return 'My Category';
    }
  }

  Widget _buildModeTile({
    required String modeKey,
    required String title,
    required String subtitle,
    String? badge,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedMode == modeKey;

    return InkWell(
      onTap: () => _setNotificationMode(modeKey),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0284C7).withValues(alpha: isDark ? 0.18 : 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0284C7)
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? const Color(0xFF0284C7) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? (isDark ? Colors.white : const Color(0xFF0369A1))
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
