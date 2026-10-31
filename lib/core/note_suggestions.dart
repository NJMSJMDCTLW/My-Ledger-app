import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';

/// Builds the note suggestion list from past transactions, grouped by category: only notes used in the *same category* are suggested.
///
/// - For income and expense a category ([categoryId]) must be picked first; with no category the list is empty.
/// - Transfers have no category, so every note used on a transfer is suggested.
/// - Order: notes used more often come first; ties go to the most recently used.
/// - If [query] is non-empty, only notes containing that text are kept (case-insensitive).
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
