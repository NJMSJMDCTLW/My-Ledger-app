import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hello_ledger/core/billing_dates.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:hello_ledger/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart' as tz;

/// Credit card due-date reminders: notifications 3 days before the due date and on the due date at 9:00.
///
/// A notification's text is fixed when it is scheduled, so the reminders have to be scheduled
/// again whenever the language changes (see `reminderSyncProvider`).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _hour = 9;
  static const _monthsAhead = 6;

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  /// The text of the reminder sent 3 days before [due], e.g. "Travel card (1234) is due on 11/5. ...".
  static String dueSoonBody(AppLocalizations l10n, String cardLabel, DateTime due) =>
      l10n.notificationDueSoon(cardLabel, due);

  /// The text of the reminder sent on the due date itself.
  static String dueTodayBody(AppLocalizations l10n, String cardLabel) =>
      l10n.notificationDueToday(cardLabel);

  /// Reschedules based on the current credit cards. Everything is cancelled and rescheduled, so changing a due day or archiving a card stays correct.
  /// The text is written in the language of [l10n].
  Future<void> rescheduleCreditCardReminders(
    List<Account> accounts,
    AppLocalizations l10n,
  ) async {
    await _plugin.cancelAll();

    final cards = accounts.where((a) =>
        a.type == AccountType.creditCard && !a.isArchived && a.dueDay != null);
    if (cards.isEmpty) return;

    // Android 13+ needs the user's consent to post notifications; no dialog is shown again once granted
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final now = DateTime.now();

    for (final card in cards) {
      final label =
          card.last4 == null ? card.name : '${card.name} (${card.last4})';

      for (var k = 0; k < _monthsAhead; k++) {
        final month = DateTime(now.year, now.month + k);
        final due = dayInMonth(month.year, month.month, card.dueDay!);
        final threeDaysBefore = due.subtract(const Duration(days: 3));

        // id: two per card per month, so it never collides with another card
        final baseId = card.id * 100 + k * 2;
        await _schedule(
          l10n: l10n,
          id: baseId,
          at: DateTime(
              threeDaysBefore.year, threeDaysBefore.month, threeDaysBefore.day, _hour),
          body: dueSoonBody(l10n, label, due),
          now: now,
        );
        await _schedule(
          l10n: l10n,
          id: baseId + 1,
          at: DateTime(due.year, due.month, due.day, _hour),
          body: dueTodayBody(l10n, label),
          now: now,
        );
      }
    }
  }

  Future<void> _schedule({
    required AppLocalizations l10n,
    required int id,
    required DateTime at,
    required String body,
    required DateTime now,
  }) async {
    if (!at.isAfter(now)) return; // do not schedule times already in the past

    await _plugin.zonedSchedule(
      id: id,
      title: l10n.notificationTitle,
      body: body,
      // Convert local time to the same instant in UTC, so no time zone lookup is needed
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'credit_card_due',
          // Android keeps the name the channel was first created with
          l10n.notificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // Does not need the "exact alarm" permission; it may be off by a few minutes
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
