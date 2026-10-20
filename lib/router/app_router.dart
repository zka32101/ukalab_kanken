import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/progress_dashboard_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/global_ranking_screen.dart';
import '../screens/friend_list_screen.dart';
import '../screens/weak_area_screen.dart';
import '../screens/learning_plan_screen.dart';
import '../screens/event_screen.dart';
import '../screens/parent_dashboard_screen.dart';
import '../screens/exam_result_screen.dart';
import '../screens/exam_history_screen.dart';
import '../screens/battle_room_list_screen.dart';
import '../screens/battle_screen.dart';
import '../screens/battle_result_screen.dart';
import '../screens/analytics_dashboard_screen.dart';
import '../screens/notification_center_screen.dart';
import '../screens/mock_exam_modes_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/friend_challenges_screen.dart';
import '../screens/spaced_repetition_review_screen.dart';
import '../screens/learning_goals_screen.dart';
import '../screens/stroke_order_screen.dart';
import '../screens/auth_gate_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/paywall_screen.dart';
import '../screens/reading_list_screen.dart';
import '../screens/glossary_screen.dart';
import '../screens/study_notes_screen.dart';
import '../models/multiplayer.dart';
import '../models/mock_exam.dart';
import '../views/index.dart';

/// アプリケーションのルーティング定義
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const AuthGateScreen(),
      routes: [
        // デイリーチャレンジ画面
        GoRoute(
          path: 'daily-challenge',
          name: 'dailyChallenge',
          builder: (context, state) => const DailyChallengeScreen(),
        ),

        // 学習進捗ダッシュボード
        GoRoute(
          path: 'progress',
          name: 'progress',
          builder: (context, state) => const ProgressDashboardScreen(),
        ),

        // ランキング
        GoRoute(
          path: 'ranking',
          name: 'ranking',
          builder: (context, state) => const RankingScreen(),
        ),

        // フレンドリスト
        GoRoute(
          path: 'friends',
          name: 'friends',
          builder: (context, state) => const FriendListScreen(),
        ),

        // 苦手分野分析
        GoRoute(
          path: 'weak-areas',
          name: 'weakAreas',
          builder: (context, state) => const WeakAreaScreen(),
        ),

        // 学習推奨プラン
        GoRoute(
          path: 'learning-plan',
          name: 'learningPlan',
          builder: (context, state) => const LearningPlanScreen(),
        ),

        // イベント
        GoRoute(
          path: 'events',
          name: 'events',
          builder: (context, state) => const EventScreen(),
        ),

        // グローバルランキング
        GoRoute(
          path: 'global-ranking',
          name: 'globalRanking',
          builder: (context, state) => const GlobalRankingScreen(),
        ),

        // コレクションバッジ
        GoRoute(
          path: 'collection-badge',
          name: 'collectionBadge',
          builder: (context, state) => const CollectionBadgeScreen(),
        ),

        // 弱点漢字モード
        GoRoute(
          path: 'weak-kanji',
          name: 'weakKanji',
          builder: (context, state) => const WeakKanjiModeScreen(),
        ),

        // 手書き練習（「漢字の学習」で選択中の漢字を練習する）
        GoRoute(
          path: 'handwriting',
          name: 'handwriting',
          builder: (context, state) => HandwritingPracticeScreen(
            kanji: state.extra as String?,
          ),
        ),

        // 模擬試験モード選択
        GoRoute(
          path: 'mock-exam-modes',
          name: 'mockExamModes',
          builder: (context, state) => const MockExamModesScreen(),
        ),

        // 保護者ダッシュボード
        GoRoute(
          path: 'parent-dashboard',
          name: 'parentDashboard',
          builder: (context, state) => const ParentDashboardScreen(),
        ),

        // 試験結果
        GoRoute(
          path: 'exam-result',
          name: 'examResult',
          builder: (context, state) {
            final result = state.extra as ExamResult?;
            if (result == null) {
              return const Scaffold(
                body: Center(child: Text('エラー')),
              );
            }
            return ExamResultScreen(result: result);
          },
        ),

        // 試験履歴
        GoRoute(
          path: 'exam-history',
          name: 'examHistory',
          builder: (context, state) => const ExamHistoryScreen(),
        ),

        // バトルルーム一覧
        GoRoute(
          path: 'battle-rooms',
          name: 'battleRooms',
          builder: (context, state) => const BattleRoomListScreen(),
        ),

        // バトル中
        GoRoute(
          path: 'battle/:roomId',
          name: 'battle',
          builder: (context, state) {
            final roomId = state.pathParameters['roomId'] ?? '';
            return BattleScreen(roomId: roomId);
          },
        ),

        // バトル結果
        GoRoute(
          path: 'battle-result',
          name: 'battleResult',
          builder: (context, state) {
            final result = state.extra as BattleResult?;
            if (result == null) {
              return const Scaffold(
                body: Center(child: Text('エラー')),
              );
            }
            return BattleResultScreen(result: result);
          },
        ),

        // 学習分析ダッシュボード
        GoRoute(
          path: 'analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsDashboardScreen(),
        ),

        // 通知センター
        GoRoute(
          path: 'notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationCenterScreen(),
        ),

        // リーダーボード
        GoRoute(
          path: 'leaderboard',
          name: 'leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),

        // フレンドチャレンジ
        GoRoute(
          path: 'friend-challenges',
          name: 'friendChallenges',
          builder: (context, state) => const FriendChallengesScreen(),
        ),

        // 間隔反復復習
        GoRoute(
          path: 'spaced-repetition-review',
          name: 'spacedRepetitionReview',
          builder: (context, state) => const SpacedRepetitionReviewScreen(),
        ),

        // 学習目標管理
        GoRoute(
          path: 'learning-goals',
          name: 'learningGoals',
          builder: (context, state) => const LearningGoalsScreen(),
        ),

        // 漢字の学習（書き順・読み方・用例）
        GoRoute(
          path: 'stroke-order',
          name: 'strokeOrder',
          builder: (context, state) => const StrokeOrderScreen(),
        ),

        // 章ごとの解説読み物
        GoRoute(
          path: 'readings',
          name: 'readings',
          builder: (context, state) => const ReadingListScreen(),
        ),

        // 用語集
        GoRoute(
          path: 'glossary',
          name: 'glossary',
          builder: (context, state) => const GlossaryScreen(),
        ),

        // ブックマーク・メモ
        GoRoute(
          path: 'study-notes',
          name: 'studyNotes',
          builder: (context, state) => const StudyNotesScreen(),
        ),

        // 設定
        GoRoute(
          path: 'settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),

        // 購入（広告なし・プレミアム。買い切り）
        GoRoute(
          path: 'paywall',
          name: 'paywall',
          builder: (context, state) => const PaywallScreen(),
        ),
      ],
    ),
  ],

  // エラーハンドリング
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('エラー')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('ページが見つかりません'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    ),
  ),
);

/// テスト用: 画面遷移先を差し替える。null なら本物の画面を開く。
/// 引数は（ルート名, 渡した値）。画面の中身を作らずに「どこへ遷移したか」だけを確かめるために使う。
Widget Function(String route, Object? extra)? kankenPageOverride;

/// 画面を Navigator.push で開く。ルート名は従来の go_router のパスと同じ。
/// （UkalabShell を MaterialApp.home に置くため、画面は Navigator で積む。）
void _open(
  BuildContext context,
  String route,
  Widget Function() page, {
  Object? extra,
}) {
  Navigator.of(context).push(_pageRoute(route, page, extra));
}

Route<void> _pageRoute(String route, Widget Function() page, Object? extra) =>
    MaterialPageRoute<void>(
      settings: RouteSettings(name: route),
      builder: (_) => kankenPageOverride?.call(route, extra) ?? page(),
    );

/// ナビゲーション ヘルパー
///
/// 段階2: 中身はすべて Navigator.push。呼び出し側は変更しない。
/// `appRouter`（上の定義）はテストが参照するため、全画面の確認が済むまで残す。
extension NavigationExtension on BuildContext {
  /// ホーム（最初の画面＝下部タブ）まで戻る
  void goHome() =>
      Navigator.of(this).popUntil((route) => route.isFirst);

  /// デイリーチャレンジに遷移
  void goDailyChallenge() =>
      _open(this, '/daily-challenge', () => const DailyChallengeScreen());

  /// 学習進捗に遷移
  void goProgress() =>
      _open(this, '/progress', () => const ProgressDashboardScreen());

  /// ランキングに遷移
  void goRanking() => _open(this, '/ranking', () => const RankingScreen());

  /// フレンドリストに遷移
  void goFriends() => _open(this, '/friends', () => const FriendListScreen());

  /// 苦手分野分析に遷移
  void goWeakAreas() =>
      _open(this, '/weak-areas', () => const WeakAreaScreen());

  /// 学習推奨プランに遷移
  void goLearningPlan() =>
      _open(this, '/learning-plan', () => const LearningPlanScreen());

  /// イベントに遷移
  void goEvents() => _open(this, '/events', () => const EventScreen());

  /// グローバルランキングに遷移
  void goGlobalRanking() =>
      _open(this, '/global-ranking', () => const GlobalRankingScreen());

  /// コレクションバッジに遷移
  void goCollectionBadge() =>
      _open(this, '/collection-badge', () => const CollectionBadgeScreen());

  /// 弱点漢字に遷移
  void goWeakKanji() =>
      _open(this, '/weak-kanji', () => const WeakKanjiModeScreen());

  /// 手書き練習に遷移
  void goHandwriting(String kanji) => _open(
        this,
        '/handwriting',
        () => HandwritingPracticeScreen(kanji: kanji),
        extra: kanji,
      );

  /// 模擬試験モード選択に遷移
  void goMockExamModes() =>
      _open(this, '/mock-exam-modes', () => const MockExamModesScreen());

  /// 保護者ダッシュボードに遷移
  void goParentDashboard() =>
      _open(this, '/parent-dashboard', () => const ParentDashboardScreen());

  /// 試験結果画面に遷移
  void goExamResult(ExamResult result) => _open(
        this,
        '/exam-result',
        () => ExamResultScreen(result: result),
        extra: result,
      );

  /// 試験履歴画面に遷移
  void goExamHistory() =>
      _open(this, '/exam-history', () => const ExamHistoryScreen());

  /// バトルルーム一覧に遷移
  void goBattleRooms() =>
      _open(this, '/battle-rooms', () => const BattleRoomListScreen());

  /// 積んだ画面をホームまで戻してから、バトルルーム一覧を開く（バトル結果からの「もう一度対戦」）。
  void restartAtBattleRooms() {
    final nav = Navigator.of(this);
    nav.popUntil((route) => route.isFirst);
    nav.push(_pageRoute(
        '/battle-rooms', () => const BattleRoomListScreen(), null));
  }

  /// バトル画面に遷移
  void goBattle(String roomId) => _open(
        this,
        '/battle/$roomId',
        () => BattleScreen(roomId: roomId),
        extra: roomId,
      );

  /// バトル結果画面に遷移
  void goBattleResult(BattleResult result) => _open(
        this,
        '/battle-result',
        () => BattleResultScreen(result: result),
        extra: result,
      );

  /// 学習分析ダッシュボードに遷移
  void goAnalytics() =>
      _open(this, '/analytics', () => const AnalyticsDashboardScreen());

  /// 通知センターに遷移
  void goNotifications() =>
      _open(this, '/notifications', () => const NotificationCenterScreen());

  /// リーダーボードに遷移
  void goLeaderboard() =>
      _open(this, '/leaderboard', () => const LeaderboardScreen());

  /// フレンドチャレンジに遷移
  void goFriendChallenges() =>
      _open(this, '/friend-challenges', () => const FriendChallengesScreen());

  /// 間隔反復復習に遷移
  void goSpacedRepetitionReview() => _open(this, '/spaced-repetition-review',
      () => const SpacedRepetitionReviewScreen());

  /// 学習目標管理に遷移
  void goLearningGoals() =>
      _open(this, '/learning-goals', () => const LearningGoalsScreen());

  /// 漢字の学習画面に遷移
  void goStrokeOrder() =>
      _open(this, '/stroke-order', () => const StrokeOrderScreen());

  /// 章ごとの解説読み物の一覧に遷移
  void goReadings() =>
      _open(this, '/readings', () => const ReadingListScreen());

  /// 用語集に遷移
  void goGlossary() => _open(this, '/glossary', () => const GlossaryScreen());

  /// ブックマーク・メモ一覧に遷移
  void goStudyNotes() =>
      _open(this, '/study-notes', () => const StudyNotesScreen());

  /// 設定画面に遷移
  void goSettings() => _open(this, '/settings', () => const SettingsScreen());

  /// 広告非表示プラン購入画面に遷移
  void goPaywall() => _open(this, '/paywall', () => const PaywallScreen());
}
