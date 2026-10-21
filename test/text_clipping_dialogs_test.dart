import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/achievement.dart';
import 'package:kanken/screens/battle_room_list_screen.dart';
import 'package:kanken/screens/event_screen.dart';
import 'package:kanken/screens/friend_list_screen.dart';
import 'package:kanken/screens/learning_goals_screen.dart';
import 'package:kanken/screens/mock_exam_modes_screen.dart';
import 'package:kanken/screens/notification_center_screen.dart';
import 'package:kanken/screens/parent_dashboard_screen.dart';
import 'package:kanken/screens/settings_screen.dart';
import 'package:kanken/screens/spaced_repetition_review_screen.dart';
import 'package:kanken/screens/stroke_order_screen.dart';
import 'package:kanken/screens/study_notes_screen.dart';
import 'package:kanken/views/home_screen.dart';
import 'package:kanken/widgets/achievement_unlock_dialog.dart';
import 'package:kanken/widgets/correct_feedback_widget.dart';
import 'package:kanken/widgets/level_clear_celebration_dialog.dart';
import 'package:ukalab_core/learning.dart';

import 'support/clip_fixtures.dart';
import 'support/overflow_harness.dart';

/// ダイアログや、タップして開く画面の「文字切れ・はみ出し」スモーク。
/// 条件は text_clipping_smoke_test.dart と同じ。
class ClipFlow {
  const ClipFlow(this.name, this.build, this.interact);

  final String name;
  final Widget Function() build;
  final Future<void> Function(WidgetTester t) interact;
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> tapText(WidgetTester t, String text, {int index = 0}) async {
  final f = find.text(text).at(index);
  await t.ensureVisible(f);
  await t.tap(f, warnIfMissed: false);
  await settle(t);
}

Future<void> tapFinder(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.tap(f.first, warnIfMissed: false);
  await settle(t);
}

Future<void> tapIcon(WidgetTester t, IconData icon) =>
    tapFinder(t, find.byIcon(icon));

/// 何かのウィジェットの中から ProviderContainer を取り出す。
ProviderContainer containerOf(WidgetTester t, Type screen) =>
    ProviderScope.containerOf(t.element(find.byType(screen).first));

/// ボタンを押すと showDialog する小さな画面。
class _DialogHost extends StatelessWidget {
  const _DialogHost(this.label, this.open);

  final String label;
  final void Function(BuildContext context) open;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(onPressed: () => open(context), child: Text(label)),
        ),
      );
}

final flows = <ClipFlow>[
  ClipFlow('ホーム 出題形式の選択', () => const HomeScreen(),
      (t) => tapText(t, '演習を始める')),
  ClipFlow('ホーム プレミアム限定の案内', () => const HomeScreen(),
      (t) => tapText(t, '準1級')),
  ClipFlow('ホーム 全グループ展開', () => const HomeScreen(), (t) async {
    await tapText(t, 'ソーシャル');
    await tapText(t, '道具');
  }),
  ClipFlow('設定 プロフィール追加', () => const SettingsScreen(),
      (t) => tapText(t, 'プロフィールを追加')),
  ClipFlow('設定 フレンドID', () => const SettingsScreen(),
      (t) => tapFinder(t, find.byTooltip('フレンドIDを表示'))),
  ClipFlow('設定 プロフィール削除の確認', () => const SettingsScreen(),
      (t) => tapIcon(t, Icons.delete_outline)),
  ClipFlow('フレンド 追加', () => const FriendListScreen(),
      (t) => tapIcon(t, Icons.person_add)),
  ClipFlow('フレンド チャレンジ送信', () => const FriendListScreen(),
      (t) => tapIcon(t, Icons.sports_esports)),
  ClipFlow('通知 設定', () => const NotificationCenterScreen(),
      (t) => tapIcon(t, Icons.settings)),
  ClipFlow('対戦 ルーム作成', () => const BattleRoomListScreen(),
      (t) => tapText(t, 'ルームを作成')),
  ClipFlow('学習目標 作成', () => const LearningGoalsScreen(),
      (t) => tapIcon(t, Icons.add)),
  ClipFlow('イベント 参加確認', () => const EventScreen(),
      (t) => tapText(t, '参加する')),
  ClipFlow('模擬試験 カテゴリ選択', () => const MockExamModesScreen(),
      (t) => tapText(t, '集中試験')),
  ClipFlow('保護者 子ども追加', () => const ParentDashboardScreen(),
      (t) => tapIcon(t, Icons.add)),
  ClipFlow('漢字の学習 書く練習', () => const StrokeOrderScreen(),
      (t) => tapText(t, '書く練習')),
  ClipFlow('復習 答え表示', () => const SpacedRepetitionReviewScreen(),
      (t) => tapText(t, '答えを表示')),
  ClipFlow('ノート メモ編集', () => const StudyNotesScreen(), (t) async {
    await tapText(t, '問題 q1');
  }),
  ClipFlow(
      '実績獲得ダイアログ',
      () => _DialogHost(
            '開く',
            (context) => showDialog<void>(
              context: context,
              builder: (_) => AchievementUnlockDialog(
                onComplete: () {},
                achievements: [
                  for (var i = 0; i < 3; i++)
                    Achievement(
                      id: 'a$i',
                      name: 'ながい名前の実績バッジ$i',
                      description: 'この実績は、たくさんの問題に挑戦するとかくとくできます。がんばろう。',
                      icon: '🏆',
                      type: AchievementType.milestone,
                      points: 12345,
                      isUnlocked: true,
                      unlockedAt: DateTime(2026, 10, 14),
                    ),
                ],
              ),
            ),
          ),
      (t) => tapText(t, '開く')),
  ClipFlow(
      '級クリアのお祝い',
      () => _DialogHost(
            '開く',
            (context) => showLevelClearCelebration(
              context,
              levelName: '2級（高校卒業・大学・一般程度）',
              feedback: AnswerFeedback(sound: FakeSoundBackend()),
            ),
          ),
      (t) => tapText(t, '開く')),
  ClipFlow(
      '正解の演出',
      () => _DialogHost(
            '開く',
            (context) => showDialog<void>(
              context: context,
              builder: (d) => Dialog(
                insetPadding: const EdgeInsets.all(24),
                child: CorrectFeedbackWidget(
                  onComplete: () {},
                  onLearnedToggle: (_) {},
                ),
              ),
            ),
          ),
      (t) async {
        await tapText(t, '開く');
        // 演出の終わりに 2 秒待つタイマーが残らないよう、進めておく
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 300));
        }
      }),
];

void main() {
  setUpAll(initFirebaseMocks);

  for (final f in flows) {
    group(f.name, () {
      for (final c in clipCases) {
        testWidgets(c.label, (tester) async {
          final errs = await pumpAndCollectOverflow(
            tester,
            f.build(),
            c,
            name: f.name,
            overrides: fixtureOverrides(),
            interact: f.interact,
          );
          expect(errs, isEmpty, reason: describe(errs));
        });
      }
    });
  }
}
