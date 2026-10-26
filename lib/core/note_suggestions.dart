import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

/// 從過去的交易整理出備註推薦清單，依類別分組：只推薦「同一個類別」用過的備註。
///
/// - 收入、支出要先選好類別（[categoryId]）才有推薦，沒選類別回傳空清單。
/// - 轉帳沒有類別，所以推薦所有轉帳用過的備註。
/// - 排序：用過越多次的越前面，次數一樣則越近用過的越前面。
/// - [query] 有字的話，只留下包含該文字的備註（不分大小寫）。
List<String> suggestNotes(
  List<TransactionRecord> transactions, {
  required TransactionType type,
  int? categoryId,
  String query = '',
  int limit = 10,
}) {
  final isTransfer = type == TransactionType.transfer;
  if (!isTransfer && categoryId == null) return [];

  final stats = <String, _NoteStat>{};
  for (final t in transactions) {
    final note = t.note.trim();
    if (note.isEmpty || t.type != type) continue;
    if (!isTransfer && t.categoryId != categoryId) continue;

    final stat = stats.putIfAbsent(note, () => _NoteStat());
    stat.count++;
    if (stat.latest == null || t.date.isAfter(stat.latest!)) {
      stat.latest = t.date;
    }
  }

  final q = query.trim().toLowerCase();
  final notes = stats.keys
      .where((n) => q.isEmpty || n.toLowerCase().contains(q))
      .toList()
    ..sort((a, b) {
      final sa = stats[a]!;
      final sb = stats[b]!;
      if (sa.count != sb.count) return sb.count.compareTo(sa.count);
      return sb.latest!.compareTo(sa.latest!);
    });

  return notes.take(limit).toList();
}

class _NoteStat {
  int count = 0;
  DateTime? latest;
}
