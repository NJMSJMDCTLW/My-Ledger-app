import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hello_ledger/core/billing_dates.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// Credit card due-date reminders: notifications 3 days before the due date and on the due date at 9:00.
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

  /// Reschedules based on the current credit cards. Everything is cancelled and rescheduled, so changing a due day or archiving a card stays correct.
  Future<void> rescheduleCreditCardReminders(List<Account> accounts) async {
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
    final fmt = DateFormat('M/d');

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
          id: baseId,
          at: DateTime(
              threeDaysBefore.year, threeDaysBefore.month, threeDaysBefore.day, _hour),
          body: '$label 將於 ${fmt.format(due)} 繳款，記得準備資金',
          now: now,
        );
        await _schedule(
          id: baseId + 1,
          at: DateTime(due.year, due.month, due.day, _hour),
          body: '今天是 $label 的繳款日',
          now: now,
        );
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required String body,
    required DateTime now,
  }) async {
    if (!at.isAfter(now)) return; // do not schedule times already in the past

    await _plugin.zonedSchedule(
      id: id,
      title: '信用卡繳款提醒',
      body: body,
      // Convert local time to the same instant in UTC, so no time zone lookup is needed
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'credit_card_due',
          '信用卡繳款提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // Does not need the "exact alarm" permission; it may be off by a few minutes
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
