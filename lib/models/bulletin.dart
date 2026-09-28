/// Represents an official monthly Visa Bulletin released by the U.S. Department of State.
library;

class Bulletin {
  final String month;
  final String? publishedAt;
  final String? previousMonth;
  final String sourceUrl;
  final Map<String, Map<String, Map<String, String>>> tables;
  final Map<String, Map<String, Map<String, String>>> previousTables;

  final String uscisFilingChart;
  final String? uscisNote;

  Bulletin({
    required this.month,
    this.publishedAt,
    this.previousMonth,
    required this.sourceUrl,
    required this.tables,
    required this.previousTables,
    this.uscisFilingChart = 'Dates for Filing',
    this.uscisNote,
  });

  factory Bulletin.fromJson(Map<String, dynamic> j) {
    String chart = 'Dates for Filing';
    String? note;
    if (j['uscisFilingChart'] != null) {
      if (j['uscisFilingChart'] is Map) {
        chart = j['uscisFilingChart']['employment']?.toString() ??
            j['uscisFilingChart']['family']?.toString() ??
            'Dates for Filing';
        note = j['uscisFilingChart']['note']?.toString();
      } else {
        chart = j['uscisFilingChart'].toString();
      }
    }

    return Bulletin(
      month: j['month'] ?? 'Current',
      publishedAt: j['publishedAt'],
      previousMonth: j['previousMonth'],
      sourceUrl: j['sourceUrl'] ?? 'https://travel.state.gov',
      tables: _parseTables(j['tables'] ?? {}),
      previousTables: _parseTables(j['previousTables'] ?? {}),
      uscisFilingChart: chart,
      uscisNote: note,
    );
  }

  static Map<String, Map<String, Map<String, String>>> _parseTables(dynamic raw) {
    final out = <String, Map<String, Map<String, String>>>{};
    if (raw is! Map) return out;
    raw.forEach((k, v) {
      final rows = <String, Map<String, String>>{};
      if (v is Map) {
        v.forEach((rk, rv) {
          if (rv is Map) {
            rows[rk.toString()] = Map<String, String>.from(
              rv.map((key, val) => MapEntry(key.toString(), val.toString())),
            );
          }
        });
      }
      out[k.toString()] = rows;
    });
    return out;
  }
}
