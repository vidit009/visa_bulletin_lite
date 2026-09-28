import 'package:flutter/material.dart';

class CategorySelectorSheet extends StatefulWidget {
  final String initialCountry;
  final String initialCategory;
  final String initialTrack;
  final List<String> employmentCategories;
  final List<String> familyCategories;
  final VoidCallback onPickCountry;
  final Function(String track, String category) onSelected;

  const CategorySelectorSheet({
    super.key,
    required this.initialCountry,
    required this.initialCategory,
    required this.initialTrack,
    required this.employmentCategories,
    required this.familyCategories,
    required this.onPickCountry,
    required this.onSelected,
  });

  @override
  State<CategorySelectorSheet> createState() => _CategorySelectorSheetState();
}

class _CategorySelectorSheetState extends State<CategorySelectorSheet> {
  late String selectedTrack;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedTrack = widget.initialTrack;
    selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final categories = selectedTrack == 'employment'
        ? widget.employmentCategories
        : widget.familyCategories;

    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 16),
          Text(
            'Select Visa Category',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your preference category to track on your top card.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'employment',
                label: Text('Employment'),
                icon: Icon(Icons.work_outline_rounded),
              ),
              ButtonSegment(
                value: 'family',
                label: Text('Family'),
                icon: Icon(Icons.family_restroom_rounded),
              ),
            ],
            selected: {selectedTrack},
            onSelectionChanged: (s) {
              setState(() {
                selectedTrack = s.first;
                final newCats = selectedTrack == 'employment'
                    ? widget.employmentCategories
                    : widget.familyCategories;
                selectedCategory = newCats.first;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Visa Category',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: categories
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selectedCategory = v);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              widget.onSelected(selectedTrack, selectedCategory);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Save Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
