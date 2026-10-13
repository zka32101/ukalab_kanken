import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/exam_prep_data.dart';
import 'package:kanken/views/core_features_entry.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 13, 15);
  const s = ExamCountdownStrings.ja;

  Future<void> pump(WidgetTester tester, DateTime? exam,
      {void Function(BuildContext)? onOpen}) async {
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [examPrepExamDateProvider.overrideWithValue(exam)],
      child: MaterialApp(
        home: Scaffold(
          body: ExamCountdownEntry(clock: () => now, onOpenSettings: onOpen),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('試験日が未設定なら何も出ない', (tester) async {
    await pump(tester, null);
    expect(find.byType(ExamCountdownChip), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('設定済みならチップを表示する', (tester) async {
    await pump(tester, DateTime(2026, 11, 13));
    expect(find.byType(ExamCountdownChip), findsOneWidget);
    expect(find.text(s.chipDays(31)), findsOneWidget);
  });

  testWidgets('各 phase の代表値', (tester) async {
    final cases = <DateTime, String>{
      DateTime(2027, 2, 1): s.chipDays(111), // farAway
      DateTime(2026, 11, 13): s.chipDays(31), // approaching
      DateTime(2026, 10, 23): s.chipDays(10), // close
      DateTime(2026, 10, 16): s.chipDays(3), // finalDays
      DateTime(2026, 10, 13): s.chipToday, // today
      DateTime(2026, 10, 12): s.chipDone, // done
    };
    for (final e in cases.entries) {
      await pump(tester, e.key);
      expect(find.text(e.value), findsOneWidget, reason: '${e.key}');
    }
  });

  testWidgets('試験日を過ぎたらおつかれさま（日数は出ない）', (tester) async {
    await pump(tester, DateTime(2026, 10, 1));
    expect(find.text('おつかれさまでした'), findsOneWidget);
    expect(find.textContaining('日'), findsNothing);
  });

  testWidgets('タップで試験日の設定画面を開く', (tester) async {
    var opened = 0;
    await pump(tester, DateTime(2026, 11, 13), onOpen: (_) => opened++);
    await tester.tap(find.byType(ActionChip));
    await tester.pump();
    expect(opened, 1);
  });
}
