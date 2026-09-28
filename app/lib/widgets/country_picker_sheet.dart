import 'package:flutter/material.dart';
import '../constants/country_data.dart';

class CountryPickerSheet extends StatefulWidget {
  final String selectedCountry;
  final ValueChanged<String> onSelectCountry;

  const CountryPickerSheet({
    super.key,
    required this.selectedCountry,
    required this.onSelectCountry,
  });

  @override
  State<CountryPickerSheet> createState() => CountryPickerSheetState();
}

class CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredList = allWorldCountries.where((c) {
      if (_query.isEmpty) return true;
      return c.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filteredList.sort((a, b) {
        final aStarts = a.toLowerCase().startsWith(q);
        final bStarts = b.toLowerCase().startsWith(q);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return a.compareTo(b);
      });
    }

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Select Country / Chargeability',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    'Search any country. Countries without dedicated limits automatically map to All Chargeability.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type country name (e.g. In for India)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() => _query = val.trim());
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No country matches "$_query"',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        final isSelected = item == widget.selectedCountry;
                        final isDedicated = isDedicatedCountry(item);

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                isDedicated ? Icons.star_rounded : Icons.public_rounded,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              item,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            subtitle: Text(
                              isDedicated
                                  ? 'Specific Bulletin Cutoff'
                                  : 'All Chargeability / Worldwide',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDedicated
                                    ? const Color(0xFF10B981)
                                    : Colors.grey.shade600,
                                fontWeight: isDedicated ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                                : null,
                            onTap: () {
                              widget.onSelectCountry(item);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
