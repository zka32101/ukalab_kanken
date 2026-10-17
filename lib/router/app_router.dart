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

/// ナビゲーション ヘルパー
extension NavigationExtension on BuildContext {
  /// ホームに戻る
  void goHome() => go('/');

  /// デイリーチャレンジに遷移
  void goDailyChallenge() => push('/daily-challenge');

  /// 学習進捗に遷移
  void goProgress() => push('/progress');

  /// ランキングに遷移
  void goRanking() => push('/ranking');

  /// フレンドリストに遷移
  void goFriends() => push('/friends');

  /// 苦手分野分析に遷移
  void goWeakAreas() => push('/weak-areas');

  /// 学習推奨プランに遷移
  void goLearningPlan() => push('/learning-plan');

  /// イベントに遷移
  void goEvents() => push('/events');

  /// グローバルランキングに遷移
  void goGlobalRanking() => push('/global-ranking');

  /// コレクションバッジに遷移
  void goCollectionBadge() => push('/collection-badge');

  /// 弱点漢字に遷移
  void goWeakKanji() => push('/weak-kanji');

  /// 手書き練習に遷移
  void goHandwriting(String kanji) => push('/handwriting', extra: kanji);

  /// 模擬試験モード選択に遷移
  void goMockExamModes() => push('/mock-exam-modes');

  /// 保護者ダッシュボードに遷移
  void goParentDashboard() => push('/parent-dashboard');

  /// 試験結果画面に遷移
  void goExamResult(ExamResult result) =>
      push('/exam-result', extra: result);

  /// 試験履歴画面に遷移
  void goExamHistory() => push('/exam-history');

  /// バトルルーム一覧に遷移
  void goBattleRooms() => push('/battle-rooms');

  /// バトル画面に遷移
  void goBattle(String roomId) => push('/battle/$roomId');

  /// バトル結果画面に遷移
  void goBattleResult(BattleResult result) =>
      push('/battle-result', extra: result);

  /// 学習分析ダッシュボードに遷移
  void goAnalytics() => push('/analytics');

  /// 通知センターに遷移
  void goNotifications() => push('/notifications');

  /// ショップに遷移

  /// リーダーボードに遷移
  void goLeaderboard() => push('/leaderboard');

  /// フレンドチャレンジに遷移
  void goFriendChallenges() => push('/friend-challenges');

  /// 間隔反復復習に遷移
  void goSpacedRepetitionReview() => push('/spaced-repetition-review');

  /// 学習目標管理に遷移
  void goLearningGoals() => push('/learning-goals');

  /// 漢字の学習画面に遷移
  void goStrokeOrder() => push('/stroke-order');

  /// 章ごとの解説読み物の一覧に遷移
  void goReadings() => push('/readings');

  /// 用語集に遷移
  void goGlossary() => push('/glossary');

  /// ブックマーク・メモ一覧に遷移
  void goStudyNotes() => push('/study-notes');

  /// 設定画面に遷移
  void goSettings() => push('/settings');

  /// 広告非表示プラン購入画面に遷移
  void goPaywall() => push('/paywall');
}
