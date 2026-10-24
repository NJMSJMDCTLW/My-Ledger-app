import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hello_ledger/core/billing_dates.dart';
import 'package:hello_ledger/data/app_database.dart';
import 'package:hello_ledger/data/enums.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// 信用卡繳款提醒：在繳款日前 3 天與當天早上 9 點通知。
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

  /// 依目前的信用卡重新排程。先全部取消再重排，所以改繳款日、封存都會正確。
  Future<void> rescheduleCreditCardReminders(List<Account> accounts) async {
    await _plugin.cancelAll();

    final cards = accounts.where((a) =>
        a.type == AccountType.creditCard && !a.isArchived && a.dueDay != null);
    if (cards.isEmpty) return;

    // Android 13 以上要使用者同意才能發通知，已同意的話不會再跳視窗
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

        // id：每張卡每個月兩個，不會跟別張卡重複
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
    if (!at.isAfter(now)) return; // 已經過去的不排

    await _plugin.zonedSchedule(
      id: id,
      title: '信用卡繳款提醒',
      body: body,
      // 本機時間轉成同一個時間點的 UTC，不需要另外查時區
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'credit_card_due',
          '信用卡繳款提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // 不需要「精確鬧鐘」權限，可能有幾分鐘誤差
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
