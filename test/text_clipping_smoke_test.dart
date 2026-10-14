import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/screens/analytics_dashboard_screen.dart';
import 'package:kanken/screens/battle_room_list_screen.dart';
import 'package:kanken/screens/daily_challenge_screen.dart';
import 'package:kanken/screens/event_screen.dart';
import 'package:kanken/screens/exam_history_screen.dart';
import 'package:kanken/screens/friend_challenges_screen.dart';
import 'package:kanken/screens/friend_list_screen.dart';
import 'package:kanken/screens/global_ranking_screen.dart';
import 'package:kanken/screens/glossary_screen.dart';
import 'package:kanken/screens/leaderboard_screen.dart';
import 'package:kanken/screens/learning_goals_screen.dart';
import 'package:kanken/screens/learning_plan_screen.dart';
import 'package:kanken/screens/login_choice_screen.dart';
import 'package:kanken/screens/mock_exam_modes_screen.dart';
import 'package:kanken/screens/nagara_session_screen.dart';
import 'package:kanken/screens/nickname_setup_screen.dart';
import 'package:kanken/screens/notification_center_screen.dart';
import 'package:kanken/screens/oshi_room_screen.dart';
import 'package:kanken/screens/parent_dashboard_screen.dart';
import 'package:kanken/screens/paywall_screen.dart';
import 'package:kanken/screens/progress_dashboard_screen.dart';
import 'package:kanken/screens/ranking_screen.dart';
import 'package:kanken/screens/reading_list_screen.dart';
import 'package:kanken/screens/settings_screen.dart';
import 'package:kanken/screens/spaced_repetition_review_screen.dart';
import 'package:kanken/screens/stroke_order_screen.dart';
import 'package:kanken/screens/study_notes_screen.dart';
import 'package:kanken/screens/weak_area_screen.dart';
import 'package:kanken/views/handwriting_practice_screen.dart';
import 'package:kanken/views/home_screen.dart';
import 'package:ukalab_core/ukalab_core.dart'
    show ChapterReading, parseChapterReadingsJsonl;

import 'support/clip_fixtures.dart';
import 'support/overflow_harness.dart';

/// 画面ごとの「文字切れ・はみ出し」スモーク。
/// 幅 320/280dp × 端末文字倍率 1/2/3 × アプリ内『文字の大きさ』大・特大で表示し、
/// RenderFlex overflow などのレイアウト例外と、箱に収まらず切れているテキストが無いことを確かめる。
/// 外部サービス（Firebase など）は使わず、test/support/clip_fixtures.dart の
/// 「長い名前・大きな数字」入りの偽データで表示する。
List<ChapterReading> _readings() => parseChapterReadingsJsonl(
      File('assets/readings/kanken.readings.jsonl').readAsStringSync(),
    ).items;

class ClipScreen {
  const ClipScreen(this.name, this.build,
      {this.tabs = 0, this.interact, this.external = const []});

  /// 共通パッケージの部品名。その中の文字切れは、このリポジトリでは直せないので除外する
  /// （PR 本文の「残課題」に載せている）。
  final List<String> external;

  final String name;
  final Widget Function() build;

  /// TabBar のタブ数（1 より大きいときは、各タブを開いた状態も確かめる）
  final int tabs;

  final Future<void> Function(WidgetTester tester)? interact;
}

Future<void> openTab(WidgetTester t, int i) async {
  final bar = find.byType(TabBar);
  final el = t.element(bar);
  final c = t.widget<TabBar>(bar).controller ?? DefaultTabController.of(el);
  c.index = i;
  await t.pump();
}

Future<void> selectFirstChild(WidgetTester t) async {
  await t.tap(find.byType(FilterChip).first);
  await t.pump();
}

final screens = <ClipScreen>[
  ClipScreen('ホーム', () => const HomeScreen()),
  ClipScreen('設定', () => const SettingsScreen()),
  ClipScreen('ペイウォール', () => const PaywallScreen()),
  ClipScreen('ログイン選択', () => const LoginChoiceScreen()),
  ClipScreen('ニックネーム設定', () => NicknameSetupScreen(onComplete: () {})),
  ClipScreen('推しの部屋', () => const OshiRoomScreen()),
  // コレクションバッジ・弱点漢字モードは、build() の中で FutureProvider を作り直す実装のため
  // 読み込みが終わらず（呼ぶたびに再読み込みする）、外から偽データを差し込めない。
  // 画面の中身は、タップで開く詳細ダイアログも含めて、コードの確認と手動の確認にとどめる（PR 本文参照）。
  ClipScreen('手書き練習', () => const HandwritingPracticeScreen(kanji: '憂', level: 'LEVEL_3')),
  ClipScreen('用語集', () => GlossaryScreen(loadReadings: () async => _readings()),
      external: ['GlossaryListView']),
  ClipScreen('読み一覧', () => ReadingListScreen(loadReadings: () async => _readings())),
  ClipScreen('ながら学習', () => const NagaraSessionScreen(),
      external: ['NagaraSessionView']),
  ClipScreen('ブックマーク・メモ', () => const StudyNotesScreen(), tabs: 2),
  ClipScreen('間隔反復復習', () => const SpacedRepetitionReviewScreen()),
  ClipScreen('漢字の学習', () => const StrokeOrderScreen()),
  ClipScreen('模擬試験モード', () => const MockExamModesScreen()),
  ClipScreen('試験履歴', () => const ExamHistoryScreen()),
  ClipScreen('学習進捗', () => const ProgressDashboardScreen()),
  ClipScreen('学習分析', () => const AnalyticsDashboardScreen(), tabs: 3),
  ClipScreen('苦手分野', () => const WeakAreaScreen()),
  ClipScreen('学習プラン', () => const LearningPlanScreen()),
  ClipScreen('学習目標', () => const LearningGoalsScreen()),
  ClipScreen('デイリーチャレンジ', () => const DailyChallengeScreen()),
  ClipScreen('イベント', () => const EventScreen(), tabs: 3),
  ClipScreen('通知センター', () => const NotificationCenterScreen()),
  ClipScreen('保護者ダッシュボード', () => const ParentDashboardScreen(),
      interact: selectFirstChild),
  ClipScreen('ランキング', () => const RankingScreen()),
  ClipScreen('グローバルランキング', () => const GlobalRankingScreen(), tabs: 2),
  ClipScreen('スコアボード', () => const LeaderboardScreen()),
  ClipScreen('フレンド', () => const FriendListScreen(), tabs: 3),
  ClipScreen('フレンドチャレンジ', () => const FriendChallengesScreen(), tabs: 2),
  ClipScreen('対戦ルーム一覧', () => const BattleRoomListScreen()),
];

void main() {
  setUpAll(initFirebaseMocks);

  for (final e in screens) {
    group(e.name, () {
      final tabCount = e.tabs > 1 ? e.tabs : 1;
      for (var tab = 0; tab < tabCount; tab++) {
        for (final c in clipCases) {
          testWidgets('${tabCount > 1 ? 'tab$tab ' : ''}${c.label}', (tester) async {
            final errs = await pumpAndCollectOverflow(
              tester,
              e.build(),
              c,
              name: '${e.name}${tabCount > 1 ? ' tab$tab' : ''}',
              overrides: fixtureOverrides(),
              externalWidgets: e.external,
              interact: (t) async {
                if (e.interact != null) await e.interact!(t);
                if (tabCount > 1) await openTab(t, tab);
              },
            );
            expect(errs, isEmpty, reason: describe(errs));
          });
        }
      }
    });
  }
}
