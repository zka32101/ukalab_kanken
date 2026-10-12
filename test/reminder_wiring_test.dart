import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/services/local_reminder_notifier.dart';
import 'package:ukalab_core/daily_goal.dart';
import 'package:ukalab_core/reminder.dart';
import 'package:ukalab_core/reminder_notification.dart';

class _FakeNotifier implements ReminderNotifier {
  int cancelCount = 0;
  List<DateTime>? scheduled;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(List<DateTime> times,
      {required String title, required String body}) async {
    scheduled = times;
  }

  @override
  Future<void> cancelAll() async => cancelCount++;
}

void main() {
  test('既定の通知は何もしない（Web と同じ）', () async {
    const n = NoopReminderNotifier();
    expect(await n.requestPermission(), isFalse);
    await n.schedule([DateTime(2030)], title: 't', body: 'b');
    await n.cancelAll();
  });

  test('スマホ以外（Web・デスクトップ）では LocalReminderNotifier は何もせず例外も出さない', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final n = LocalReminderNotifier();
    expect(await n.requestPermission(), isFalse);
    await n.schedule([DateTime(2030)], title: 't', body: 'b');
    await n.cancelAll();
  });

  test('通知時刻: 過ぎた今日は含めず、7日分', () {
    final now = DateTime(2026, 10, 12, 20);
    final times =
        upcomingReminderTimes(now: now, hour: 18, achievedToday: false);
    expect(times.length, 6);
    expect(times.first, DateTime(2026, 10, 13, 18));
  });

  test('目標が未設定なら予約を取り消し、設定ありなら予約する', () async {
    final fake = _FakeNotifier();
    final now = DateTime(2026, 10, 12, 9);
    const settings = ReminderSettings();
    await rescheduleStudyReminders(
        notifier: fake, settings: settings, goal: const DailyGoal(), now: now);
    expect(fake.cancelCount, 1);

    await rescheduleStudyReminders(
        notifier: fake,
        settings: settings,
        goal: const DailyGoal(target: 10),
        now: now);
    expect(fake.scheduled, isNotEmpty);
  });
}
