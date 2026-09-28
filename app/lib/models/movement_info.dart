import 'package:intl/intl.dart';

enum MovementType {
  advanced,
  retrogressed,
  unchanged,
  becameCurrent,
  becameUnavailable,
  restored,
  unknown,
}

class MovementInfo {
  final MovementType type;
  final String label;
  final String shortLabel;
  final String detail;
  final int days;

  const MovementInfo({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.detail,
    this.days = 0,
  });

  String get summary => label;
}

DateTime? parseDosDate(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.trim().toUpperCase();
  if (cleaned == 'C' || cleaned == 'U' || cleaned.length < 7) return null;
  const m = {
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
    'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
  };
  try {
    final day = int.parse(cleaned.substring(0, 2));
    final mon = m[cleaned.substring(2, 5)];
    final yy = int.parse(cleaned.substring(5));
    if (mon == null) return null;
    final year = yy > 50 ? 1900 + yy : 2000 + yy;
    return DateTime(year, mon, day);
  } catch (_) {
    return null;
  }
}

String formatCutoffDate(String raw) {
  final cleaned = raw.trim().toUpperCase();
  if (cleaned == 'C') return 'Current';
  if (cleaned == 'U') return 'Unavailable';
  final dt = parseDosDate(cleaned);
  if (dt != null) {
    return DateFormat('dd MMM yyyy').format(dt);
  }
  return raw;
}

MovementInfo calculateMovement(String? before, String now) {
  final cur = now.trim().toUpperCase();
  final prev = before?.trim().toUpperCase();

  if (prev == null) {
    return const MovementInfo(
      type: MovementType.unknown,
      label: 'New Category Data',
      shortLabel: 'New',
      detail: 'No prior bulletin comparison available',
    );
  }

  if (prev == cur) {
    return const MovementInfo(
      type: MovementType.unchanged,
      label: 'No Movement',
      shortLabel: 'No change',
      detail: 'Cutoff date unchanged from last month',
    );
  }

  if (cur == 'C') {
    return const MovementInfo(
      type: MovementType.becameCurrent,
      label: 'Became Current',
      shortLabel: 'Current',
      detail: 'Visas are now authorized for all applicants in category',
    );
  }

  if (cur == 'U') {
    return const MovementInfo(
      type: MovementType.becameUnavailable,
      label: 'Became Unavailable',
      shortLabel: 'Unavailable',
      detail: 'Visas are unauthorized for issuance this month',
    );
  }

  if (prev == 'C') {
    return const MovementInfo(
      type: MovementType.retrogressed,
      label: 'Retrogressed from Current',
      shortLabel: 'Retrogressed',
      detail: 'Category cutoff date imposed',
    );
  }

  if (prev == 'U') {
    return const MovementInfo(
      type: MovementType.restored,
      label: 'Date Restored',
      shortLabel: 'Restored',
      detail: 'Visas resumed after being unavailable',
    );
  }

  final dtBefore = parseDosDate(prev);
  final dtNow = parseDosDate(cur);

  if (dtBefore == null || dtNow == null) {
    return const MovementInfo(
      type: MovementType.unknown,
      label: 'Date Changed',
      shortLabel: 'Changed',
      detail: 'Cutoff date modified',
    );
  }

  final days = dtNow.difference(dtBefore).inDays;
  if (days == 0) {
    return const MovementInfo(
      type: MovementType.unchanged,
      label: 'No Movement',
      shortLabel: 'No change',
      detail: 'Cutoff date unchanged',
    );
  }

  final absDays = days.abs();
  final approxMonths = (absDays / 30.4375).round();
  final timeSpan = approxMonths >= 1
      ? '$approxMonths ${approxMonths == 1 ? 'month' : 'months'} ($absDays days)'
      : '$absDays days';

  if (days > 0) {
    return MovementInfo(
      type: MovementType.advanced,
      label: 'Advanced +$timeSpan',
      shortLabel: '+${approxMonths >= 1 ? '$approxMonths mo' : '$absDays d'}',
      detail: 'Moved forward by $absDays days',
      days: days,
    );
  } else {
    return MovementInfo(
      type: MovementType.retrogressed,
      label: 'Retrogressed -$timeSpan',
      shortLabel: '-${approxMonths >= 1 ? '$approxMonths mo' : '$absDays d'}',
      detail: 'Moved backwards by $absDays days',
      days: days,
    );
  }
}

class MonthMovementSummary {
  final int advanced;
  final int unchanged;
  final int retrogressed;
  final String? biggestCategory;
  final String? biggestCountry;
  final int biggestDays;
  final String? biggestLabel;

  const MonthMovementSummary({
    required this.advanced,
    required this.unchanged,
    required this.retrogressed,
    this.biggestCategory,
    this.biggestCountry,
    this.biggestDays = 0,
    this.biggestLabel,
  });
}

MonthMovementSummary calculateMonthSummary({
  required Map<String, Map<String, String>> currentTable,
  required Map<String, Map<String, String>> previousTable,
}) {
  int adv = 0;
  int unc = 0;
  int ret = 0;
  int maxAdvDays = 0;
  String? maxCat;
  String? maxCountry;
  String? maxLabel;

  currentTable.forEach((cat, countries) {
    countries.forEach((country, curVal) {
      final prevVal = previousTable[cat]?[country];
      final m = calculateMovement(prevVal, curVal);
      if (m.type == MovementType.advanced ||
          m.type == MovementType.becameCurrent ||
          m.type == MovementType.restored) {
        adv++;
        if (m.days > maxAdvDays) {
          maxAdvDays = m.days;
          maxCat = cat;
          maxCountry = country;
          maxLabel = m.label;
        }
      } else if (m.type == MovementType.retrogressed ||
          m.type == MovementType.becameUnavailable) {
        ret++;
      } else {
        unc++;
      }
    });
  });

  return MonthMovementSummary(
    advanced: adv,
    unchanged: unc,
    retrogressed: ret,
    biggestCategory: maxCat,
    biggestCountry: maxCountry,
    biggestDays: maxAdvDays,
    biggestLabel: maxLabel,
  );
}
