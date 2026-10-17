import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/free_tier_quota.dart';
import 'package:kanken/views/core_v069_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

class _MemoryReviewStore implements ReviewSchedulerStore {
  _MemoryReviewStore(this.items);
  List<ReviewItem> items;

  @override
  Future<List<ReviewItem>> read() async => items;

  @override
  Future<void> write(List<ReviewItem> next) async => items = next;
}

ReviewItem _item(String qid, DateTime dueAt) => ReviewItem(
      qid: qid,
      stage: 0,
      dueAt: dueAt,
      lastReviewedAt: dueAt.subtract(const Duration(days: 1)),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('模擬試験(月1回)', () {
    test('無料版は月に1回だけ始められる。月が変わると戻る', () async {
      final now = DateTime(2026, 10, 17);
      expect(await (await mockExamQuota(isPremium: false, clock: () => now)).tryConsume(), isTrue);
      expect(await (await mockExamQuota(isPremium: false, clock: () => now)).tryConsume(), isFalse);
      final next = DateTime(2026, 11, 1);
      expect(await (await mockExamQuota(isPremium: false, clock: () => next)).tryConsume(), isTrue);
    });

    test('プレミアムは回数に制限がない', () async {
      final now = DateTime(2026, 10, 17);
      for (var i = 0; i < 5; i++) {
        expect(await (await mockExamQuota(isPremium: true, clock: () => now)).tryConsume(), isTrue);
      }
    });
  });

  group('今日の復習(1日10問)', () {
    test('期限の来た復習に答えると数える。無料は10で止まり、プレミアムは無制限', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final store = _MemoryReviewStore([for (var i = 0; i < 12; i++) _item('q$i', today)]);
      for (var i = 0; i < 12; i++) {
        await recordKankenReviewResult('q$i', correct: true, at: now, store: store);
      }
      final free = await todayReviewQuota(isPremium: false);
      expect(free.used, 10);
      expect(free.remaining, 0);
      expect((await todayReviewQuota(isPremium: true)).remaining, isNull);
    });

    test('期限前の問題や、予定にない問題は数えない', () async {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final store = _MemoryReviewStore([_item('later', tomorrow)]);
      await recordKankenReviewResult('later', correct: true, at: now, store: store);
      await recordKankenReviewResult('unknown', correct: true, at: now, store: store);
      expect((await todayReviewQuota(isPremium: false)).used, 0);
    });
  });
}
