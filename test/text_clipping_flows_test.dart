import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/providers/battle_provider.dart';
import 'package:kanken/screens/battle_result_screen.dart';
import 'package:kanken/screens/battle_screen.dart';
import 'package:kanken/screens/exam_result_screen.dart';
import 'package:kanken/screens/mock_exam_enhanced_screen.dart';
import 'package:kanken/screens/mock_exam_result_screen.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/providers/exam_session_provider.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/views/home_screen.dart';

import 'support/clip_fixtures.dart';
import 'support/overflow_harness.dart';

/// 演習（出題・解答・結果）と、結果画面の「文字切れ・はみ出し」スモーク。
/// 条件は text_clipping_smoke_test.dart と同じ（幅 320/280dp × 文字倍率 1/2/3 × アプリ内 大・特大）。
void main() {
  setUpAll(initFirebaseMocks);

  group('演習画面', () {
    for (final e in practiceFixtures().entries) {
      for (final c in clipCases) {
        testWidgets('${e.key} 出題 ${c.label}', (tester) async {
          final errs = await pumpAndCollectOverflow(
            tester,
            const PracticeScreen(),
            c,
            name: '演習 ${e.key}',
            overrides: [
              ...fixtureOverrides(),
              practiceQuestionsProvider
                  .overrideWith((ref, level) async => e.value),
              ahaMomentReachedProvider.overrideWith((ref) => true),
              comboCountProvider.overrideWith((ref) => 12),
              correctCountProvider.overrideWith((ref) => 12345),
            ],
          );
          expect(errs, isEmpty, reason: describe(errs));
        });
      }
    }

    for (final c in clipCases) {
      testWidgets('ながら学習モード 出題 ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          const PracticeScreen(),
          c,
          name: '演習 ながら',
          overrides: [
            ...fixtureOverrides(),
            practiceQuestionsProvider
                .overrideWith((ref, level) async => practiceFixtures()['読みがな']!),
          ],
          interact: (t) async {
            final container = ProviderScope.containerOf(
                t.element(find.byType(PracticeScreen)));
            await t.runAsync(
                () => container.read(handsFreeProvider.notifier).setEnabled(true));
            await t.pump();
          },
        );
        expect(errs, isEmpty, reason: describe(errs));
      });

      testWidgets('終了（結果） ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          const PracticeScreen(),
          c,
          name: '演習 終了',
          overrides: [
            ...fixtureOverrides(),
            practiceQuestionsProvider
                .overrideWith((ref, level) async => practiceFixtures()['読みがな']!),
            currentQuestionIndexProvider.overrideWith((ref) => 1),
            correctCountProvider.overrideWith((ref) => 12345),
          ],
        );
        expect(errs, isEmpty, reason: describe(errs));
      });

      testWidgets('問題が無い級 ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          const PracticeScreen(),
          c,
          name: '演習 空',
          overrides: [
            ...fixtureOverrides(),
            practiceQuestionsProvider.overrideWith((ref, level) async => []),
          ],
        );
        expect(errs, isEmpty, reason: describe(errs));
      });
    }
  });

  group('対戦画面', () {
    for (final c in clipCases) {
      testWidgets('対戦中 ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          const BattleScreen(roomId: 'b1'),
          c,
          name: '対戦中',
          overrides: [
            ...fixtureOverrides(),
            battleRoomNotifierProvider.overrideWith((ref) => ClipBattleNotifier()),
          ],
        );
        expect(errs, isEmpty, reason: describe(errs));
      });
    }
  });

  group('結果画面', () {
    for (final c in clipCases) {
      testWidgets('試験結果 ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          ExamResultScreen(result: fixtureExamResult()),
          c,
          name: '試験結果',
          overrides: fixtureOverrides(),
        );
        expect(errs, isEmpty, reason: describe(errs));
      });

      testWidgets('対戦結果 ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          BattleResultScreen(result: fixtureBattleResult()),
          c,
          name: '対戦結果',
          overrides: fixtureOverrides(),
        );
        expect(errs, isEmpty, reason: describe(errs));
      });

      testWidgets('模擬試験 受験中 ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          MockExamEnhancedScreen(config: ExamConfig.standard(level: 3)),
          c,
          name: '模擬試験 受験中',
          overrides: [
            ...fixtureOverrides(),
            examModeQuestionsProvider.overrideWith((ref) async => examQuestions()),
          ],
          interact: (t) async {
            final container = ProviderScope.containerOf(
                t.element(find.byType(MockExamEnhancedScreen)));
            // 開始（問題の読み込み）を待ってから、2 問目に進める
            await t.runAsync(() async {
              await container
                  .read(examSessionProvider.notifier)
                  .startExam(ExamConfig.standard(level: 3));
            });
            container.read(examSessionProvider.notifier).moveToNextQuestion();
            await t.pump();
          },
        );
        expect(errs, isEmpty, reason: describe(errs));
      });

      testWidgets('模擬試験 結果 ${c.label}', (tester) async {
        final errs = await pumpAndCollectOverflow(
          tester,
          MockExamResultScreen(
              session: fixtureExamSession(finished: true), elapsedSeconds: 1234),
          c,
          name: '模擬試験 結果',
          overrides: fixtureOverrides(),
        );
        expect(errs, isEmpty, reason: describe(errs));
      });
    }
  });
}
