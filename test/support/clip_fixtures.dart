import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanken/data/compound_structure_data.dart';
import 'package:kanken/models/index.dart';
import 'package:kanken/models/mock_exam_modes.dart';
import 'package:kanken/providers/exam_session_provider.dart';
import 'package:kanken/models/achievement.dart';
import 'package:kanken/models/analytics.dart';
import 'package:kanken/models/daily_challenge.dart';
import 'package:kanken/models/friend.dart';
import 'package:kanken/models/friend_challenge.dart';
import 'package:kanken/models/gamification_stats.dart';
import 'package:kanken/models/global_event.dart';
import 'package:kanken/models/leaderboard.dart';
import 'package:kanken/models/learning_goal.dart';
import 'package:kanken/models/learning_recommendation.dart';
import 'package:kanken/models/multiplayer.dart';
import 'package:kanken/models/notifications.dart';
import 'package:kanken/models/parent_dashboard.dart';
import 'package:kanken/models/spaced_repetition_item.dart';
import 'package:kanken/models/user_ranking.dart';
import 'package:kanken/models/weak_area.dart';
import 'package:kanken/providers/achievement_provider.dart';
import 'package:kanken/providers/purchases_provider.dart';
import 'package:kanken/providers/analytics_provider.dart' as ana;
import 'package:kanken/providers/battle_provider.dart';
import 'package:kanken/providers/daily_challenge_provider.dart';
import 'package:kanken/providers/event_provider.dart';
import 'package:kanken/providers/friend_challenge_provider.dart';
import 'package:kanken/providers/friend_provider.dart';
import 'package:kanken/providers/gamification_provider.dart';
import 'package:kanken/providers/leaderboard_provider.dart';
import 'package:kanken/providers/learning_goal_provider.dart';
import 'package:kanken/providers/learning_plan_provider.dart';
import 'package:kanken/providers/level_progress_provider.dart';
import 'package:kanken/providers/notification_provider.dart' as noti;
import 'package:kanken/providers/parent_dashboard_provider.dart';
import 'package:kanken/providers/ranking_provider.dart';
import 'package:kanken/providers/spaced_repetition_provider.dart';
import 'package:kanken/providers/weak_area_provider.dart';
import 'package:kanken/providers/writing_mastery_provider.dart';
import 'package:kanken/providers/mock_exam_enhanced_provider.dart';
import 'package:kanken/providers/firebase_provider.dart' as fb;
import 'package:kanken/services/firestore_service.dart';
import 'package:kanken/viewmodels/practice_viewmodel.dart';
import 'package:kanken/viewmodels/services_provider.dart';
import 'package:kanken/viewmodels/user_viewmodel.dart' as vm;
import 'package:app_common_kit/app_common_kit.dart'
    show EntitlementOffer, SharedPreferencesHandsFreeStore, handsFreeStoreProvider;
import 'package:ukalab_core/ui.dart';

// 文字切れ確認用に、わざと長い名前・長い文言を入れたデータ。
const longName = 'ながいなまえのユーザーさんです１２３４５'; // 20 文字（ニックネーム上限）
final _now = DateTime(2026, 10, 14, 12);

User fixtureUser() => User(
      uid: 'u1',
      displayName: longName,
      currentLevel: 'LEVEL_3',
      streakCount: 12,
      createdAt: _now,
      examDate: DateTime(2026, 12, 6),
      lastStudyDate: _now,
    );

class _MemoStore implements QuestionMemoStore {
  @override
  Future<Map<String, String>> read() async => {};
  @override
  Future<void> write(Map<String, String> memos) async {}
}

class _BookmarkStore implements BookmarkStore {
  @override
  Future<Set<String>> read() async => {};
  @override
  Future<void> write(Set<String> qids) async {}
}

/// ブックマーク 2 件・長いメモ 2 件を持たせた、端末内の学習ノート。
List<Override> studyNotesFixture() {
  final memo = QuestionMemoService(store: _MemoStore())
    ..memos.addAll({
      'q1': '間違えた理由や覚え方を書き残せます。とても長いメモのテキストです。' * 3,
      'q2': '短いメモ',
    });
  final bm = BookmarkService(store: _BookmarkStore())..qids.addAll({'q1', 'q2'});
  return [
    questionMemoServiceProvider.overrideWithValue(memo),
    bookmarkServiceProvider.overrideWithValue(bm),
  ];
}

List<Override> fixtureOverrides() {
  final t = _now;
  final ranking = [
    for (var i = 1; i <= 5; i++)
      UserRanking(
        userId: 'r$i',
        userName: longName,
        rank: i,
        level: 12,
        experience: 123456,
        coins: 99999,
        accuracyRate: 0.987,
        streak: 365,
        lastPlayedAt: t,
      ),
  ];
  final friends = [
    for (var i = 0; i < 3; i++)
      Friend(
        userId: 'f$i',
        userName: longName,
        level: 12,
        experience: 123456,
        accuracyRate: 0.987,
        streak: 365,
        status: FriendStatus.friend,
        addedAt: t,
        lastPlayedAt: DateTime.now(),
      ),
  ];
  final weakAreas = [
    for (var i = 0; i < 4; i++)
      WeakArea(
        categoryId: 'c$i',
        categoryName: '同音異字・四字熟語の書き取り$i',
        totalAttempts: 120,
        correctAnswers: 30,
        accuracyRate: 0.25,
        level: WeakLevel.veryWeak,
        recentStreakDays: 3,
        lastAttemptAt: t,
        problematicKanjiIds: const ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
      ),
  ];
  final recs = [
    for (var i = 0; i < 3; i++)
      LearningRecommendation(
        recommendationId: 'rec$i',
        userId: 'u1',
        targetCategoryId: 'c$i',
        targetCategoryName: '同音異字・四字熟語の書き取り$i',
        priority: RecommendationPriority.critical,
        difficulty: DifficultyLevel.advanced,
        reason: '正答率が低いので、まず基礎から丁寧に復習しましょう。毎日少しずつ続けることが大切です。',
        recommendedDailyQuestions: 30,
        estimatedDaysToImprove: 14,
        createdAt: t,
        progressAccuracy: 0.42,
      ),
  ];
  final goals = [
    for (final g in GoalType.values)
      LearningGoal(
        goalId: 'g${g.index}',
        userId: 'u1',
        type: g,
        targetValue: 1000,
        currentValue: 640,
        createdAt: t,
        deadline: t.add(const Duration(days: 30)),
      ),
  ];
  final event = GlobalEvent(
    eventId: 'e1',
    eventName: '秋の漢字チャレンジ大会・特別スペシャルイベント',
    description: '期間中にたくさんの漢字問題に挑戦して、豪華なごほうびをゲットしよう。みんなで参加してね。',
    type: EventType.special,
    status: EventStatus.active,
    startAt: t,
    endAt: t.add(const Duration(days: 7)),
    targetCategory: '同音異字・四字熟語',
    targetScore: 500,
    participantCount: 12345,
    rewards: const {'1': 1000, '2': 500, '3': 300},
  );
  final notifications = [
    for (final n in NotificationType.values)
      AppNotification(
        notificationId: 'n${n.index}',
        userId: 'u1',
        type: n.value,
        title: '${n.label}のおしらせがとどいています',
        message: 'ながいメッセージ。今日の学習の続きをやってみましょう。まだ達成していない目標があります。',
        isRead: n.index.isEven,
        createdAt: t,
      ),
  ];
  return [
    firestoreServiceProvider.overrideWithValue(ClipFirestoreService()),
    hasAdsRemovedProvider.overrideWith((ref) => Stream.value(false)),
    hasPremiumProvider.overrideWith((ref) => Stream.value(false)),
    availableOffersProvider.overrideWith((ref) async => const [
          EntitlementOffer(
              id: 'o1',
              productId: 'premium-plus-monthly',
              title: 'プレミアム月額',
              priceString: '¥1,200 / 月（税込）'),
          EntitlementOffer(
              id: 'o2',
              productId: 'premium-plus-yearly',
              title: 'プレミアム年額',
              priceString: '¥12,000 / 年（税込）'),
          EntitlementOffer(
              id: 'o3',
              productId: 'premium-monthly',
              title: '広告なし月額',
              priceString: '¥300 / 月（税込）'),
          EntitlementOffer(
              id: 'o4',
              productId: 'premium-yearly',
              title: '広告なし年額',
              priceString: '¥3,000 / 年（税込）'),
        ]),
    handsFreeStoreProvider.overrideWithValue(SharedPreferencesHandsFreeStore('kanken')),
    fb.currentUserProvider.overrideWith((ref) => Stream.value(null)),
    fb.currentUserIdProvider.overrideWithValue('u1'),
    ana.currentUserIdProvider.overrideWithValue('u1'),
    noti.currentUserIdProvider.overrideWithValue('u1'),
    vm.currentUserProvider.overrideWith((ref) async => fixtureUser()),
    vm.learnedKanjiIdsProvider.overrideWith((ref) async => <String>{}),
    vm.userProfilesProvider.overrideWith((ref, uid) async => [
          fixtureUser(),
          User(
            uid: 'u1',
            profileId: 'p2',
            displayName: longName,
            avatarIcon: '🐱',
            currentLevel: 'LEVEL_2_PRE',
            streakCount: 3,
            createdAt: t,
          ),
        ]),
    ...studyNotesFixture(),
    gamificationStatsProvider.overrideWith(
      (ref) async => GamificationStats(
        userId: 'u1',
        level: 12,
        experience: 123456,
        coins: 99999,
        totalQuestions: 12345,
        correctCount: 11111,
        streak: 365,
        recordStreak: 400,
        accuracyRate: 0.987,
        lastPlayedAt: t,
        createdAt: t,
      ),
    ),
    dailyChallengeProvider.overrideWith(
      (ref) async => DailyChallenge(
        id: 'd1',
        date: '2026-10-14',
        questionIds: List.generate(10, (i) => 'q$i'),
        difficulty: 'medium',
        resetTime: t.add(const Duration(days: 1)),
        createdAt: t,
      ),
    ),
    rankingProvider.overrideWith((ref, filter) async => ranking),
    userRankProvider.overrideWith((ref, filter) async => 123),
    friendListProvider.overrideWith((ref) async => friends),
    incomingRequestsProvider.overrideWith((ref) async => [
          FriendRequest(
              requestId: 'q1',
              fromUserId: 'x',
              fromUserName: longName,
              toUserId: 'u1',
              createdAt: t),
        ]),
    outgoingRequestsProvider.overrideWith((ref) async => friends),
    weakAreaAnalysisProvider.overrideWith((ref) async =>
        WeakAreaAnalysis(allAreas: weakAreas, overallAccuracy: 0.55, analyzedAt: t)),
    activeLearningRecommendationsProvider.overrideWith((ref) async => recs),
    learningPlanProvider.overrideWith((ref) async => LearningPlan(
          recommendations: recs,
          generatedAt: t,
        )),
    activeLearningGoalsProvider.overrideWith((ref) async => goals),
    achievedLearningGoalsProvider.overrideWith((ref) async => [
          LearningGoal(
            goalId: 'a1',
            userId: 'u1',
            type: GoalType.examScore,
            targetValue: 180,
            currentValue: 190,
            createdAt: t,
            isAchieved: true,
            achievedAt: t,
          ),
        ]),
    activeEventsProvider.overrideWith((ref) async => [event]),
    upcomingEventsProvider.overrideWith((ref) async => [event]),
    pastEventsProvider.overrideWith((ref) async => [event]),
    eventParticipantsProvider.overrideWith((ref, id) async => [
          for (var i = 1; i <= 3; i++)
            EventParticipation(
              participationId: 'p$i',
              eventId: id,
              userId: 'p$i',
              userName: longName,
              currentScore: 12345,
              isCompleted: true,
              rank: i,
              rewardCoins: 1000,
              joinedAt: t,
            ),
        ]),
    for (final p in [
      dailyLeaderboardProvider,
      weeklyLeaderboardProvider,
      monthlyLeaderboardProvider,
      allTimeLeaderboardProvider,
    ])
      p.overrideWith((ref) async => LeaderboardStats(
            period: LeaderboardPeriod.daily,
            topEntries: [
              for (var i = 1; i <= 5; i++)
                LeaderboardEntry(
                  userId: 'l$i',
                  userName: longName,
                  rank: i,
                  totalScore: 1234567,
                  examsCompleted: 1234,
                  averageAccuracy: 0.987,
                  streak: 365,
                  lastUpdated: t,
                ),
            ],
            currentUserEntry: LeaderboardEntry(
              userId: 'u1',
              userName: longName,
              rank: 123,
              totalScore: 1234567,
              examsCompleted: 1234,
              averageAccuracy: 0.987,
              streak: 365,
              lastUpdated: t,
            ),
            generatedAt: t,
          )),
    userLeaderboardRankProvider.overrideWith((ref, period) async => 123),
    ana.userLearningAnalyticsProvider.overrideWith((ref) async => LearningAnalytics(
          userId: 'u1',
          totalStudyMinutes: 123456,
          averageAccuracy: 0.987,
          totalQuestionsAttempted: 123456,
          correctAnswers: 111111,
          currentStreak: 365,
          longestStreak: 400,
          lastStudyDate: t,
          categoryStats: const {'同音異字・四字熟語の書き取り': 12345, '読み': 999, '部首': 77},
        )),
    ana.userGrowthDataProvider.overrideWith((ref) async => [
          for (var i = 0; i < 30; i++)
            GrowthData(
              date: t.subtract(Duration(days: 30 - i)),
              accuracy: 0.5 + (i % 10) * 0.05,
              correctCount: 10 + i % 10,
              totalCount: 20,
              studyMinutes: 30 + i,
            ),
        ]),
    ana.userLearningTrendsProvider.overrideWith((ref) async => [
          const LearningTrend(
              category: '同音異字・四字熟語の書き取り',
              trendData: [0.5, 0.6, 0.7],
              averageTrend: 0.6,
              trend: 'up'),
          const LearningTrend(
              category: '読み',
              trendData: [0.7, 0.6, 0.5],
              averageTrend: 0.6,
              trend: 'down'),
        ]),
    ana.userStudyEfficiencyProvider.overrideWith((ref) async => StudyEfficiency(
          userId: 'u1',
          minutesStudied: 12345,
          questionsCompleted: 12345,
          accuracyRate: 0.987,
          efficiencyScore: 9.87,
          calculatedAt: t,
        )),
    noti.allNotificationsProvider.overrideWith((ref) async => notifications),
    noti.unreadNotificationsProvider.overrideWith((ref) async => notifications),
    noti.notificationStatsProvider.overrideWith((ref) async => const NotificationStats(
          userId: 'u1',
          unreadCount: 123,
          totalCount: 456,
          battleInviteCount: 12,
          friendRequestCount: 34,
          achievementCount: 56,
        )),
    noti.notificationSettingsProvider.overrideWith(
        (ref) async => NotificationSettings(userId: 'u1', updatedAt: t)),
    linkedChildrenProvider.overrideWith((ref) async => [
          for (var i = 0; i < 2; i++)
            ChildLearningStats(
              childId: 'c$i',
              childName: longName,
              currentLevel: 5,
              totalQuestions: 12345,
              correctAnswers: 11111,
              accuracyRate: 0.987,
              streakDays: 365,
              longestStreak: 400,
              totalLearningMinutes: 12345,
              lastLearningAt: t,
              badgesAcquired: 12,
              totalBadges: 60,
            ),
        ]),
    childLearningGraphProvider.overrideWith((ref, id) async => [
          for (var i = 0; i < 7; i++)
            LearningDataPoint(
              date: t.subtract(Duration(days: 7 - i)),
              questionsAnswered: 20,
              correctAnswers: 10 + i,
              accuracyRate: (10 + i) / 20,
            ),
        ]),
    childWeakAreasProvider.overrideWith((ref, id) async => [
          ChildWeakArea(
            categoryId: 'c',
            categoryName: '同音異字・四字熟語の書き取り',
            totalAttempts: 120,
            correctAnswers: 30,
            accuracyRate: 0.25,
            level: 'veryWeak',
            lastAttemptAt: t,
          ),
        ]),
    availableBattleRoomsProvider.overrideWith((ref) async => [
          BattleRoom(
            roomId: 'b1',
            creatorId: 'x',
            roomName: 'みんなでたのしくあそぶバトルルーム',
            examLevel: 5,
            maxParticipants: 4,
            participants: [
              BattleParticipant(
                userId: 'x',
                displayName: longName,
                currentScore: 0,
                correctAnswers: 0,
                level: 12,
                joinedAt: t,
                isReady: true,
                isFinished: false,
              ),
            ],
            status: 'waiting',
            totalQuestions: 20,
            timePerQuestionSeconds: 30,
            createdAt: t,
          ),
        ]),
    userBattleStatsProvider.overrideWith((ref) async => const BattleRoomStats(
          userId: 'u1',
          totalBattles: 12345,
          victories: 6789,
          defeats: 5556,
          averageScore: 98.7,
          bestScore: 12345,
          highestRank: 1234,
        )),
    for (final p in [activeChallengesProvider, sentChallengesProvider, receivedChallengesProvider])
      p.overrideWith((ref) async => [
            FriendChallenge(
              challengeId: 'ch1',
              challengerUserId: 'u1',
              challengerName: longName,
              challengeeUserId: 'x',
              changetesName: longName,
              status: ChallengeStatus.accepted,
              targetScore: 80,
              description: '腕試しチャレンジ！ぜひ挑戦してみてください。',
              createdAt: t,
              dueAt: t.add(const Duration(days: 3)),
              challengerScore: 90,
              challengeeScore: 70,
            ),
          ]),
    dueReviewItemsProvider.overrideWith((ref) async => [
          SpacedRepetitionItem(
            itemId: 'i1',
            userId: 'u1',
            questionId: 'q1',
            kanji: '憂',
            category: '同音異字・四字熟語の書き取り',
            question: 'つぎの漢字の読みを答えなさい。この問題文はとても長い文章です。',
            options: const ['ゆう（うれい）', 'ゆうしゅう', 'しゅうれい', 'ようゆう'],
            correctAnswer: 'ゆう（うれい）',
            easeFactor: 2.5,
            intervalDays: 3,
            repetitions: 2,
            nextReviewDate: t,
            lastReviewedAt: t,
            totalReviews: 5,
            correctReviews: 4,
          ),
        ]),
    levelProgressProvider.overrideWith((ref) async => {
          'LEVEL_3': const LevelProgress(level: 'LEVEL_3', correctCount: 45, totalCount: 60),
        }),
    masteredWritingKanjisProvider.overrideWith((ref) async => <String>{'雨', '車'}),
    examHistoryProvider.overrideWith((ref) async => [
          fixtureExamResult(),
          ExamResult(
            resultId: 'r2',
            userId: 'u1',
            examSessionId: 's2',
            examLevel: 2,
            totalQuestions: 20,
            correctAnswers: 9,
            accuracyRate: 0.45,
            totalTimeSeconds: 3600,
            answers: const [],
            completedAt: DateTime(2026, 10, 12, 8, 5),
            isPassed: false,
            estimatedRank: 123,
            categoryScores: const {},
          ),
        ]),
    nagaraQuestionsProvider.overrideWith((ref, level) async => [
          ...practiceFixtures()['読みがな']!,
          ...practiceFixtures()['漢字をあてる']!,
        ]),
    userAchievementsProvider.overrideWith((ref) async => [
          for (final a in AchievementType.values)
            Achievement(
              id: 'a${a.index}',
              name: 'ながい名前の実績バッジ${a.name}',
              description: 'この実績は、たくさんの問題に挑戦するとかくとくできます。がんばろう。',
              icon: '🏆',
              type: a,
              points: 1000,
              isUnlocked: a.index.isEven,
              unlockedAt: t,
            ),
        ]),
  ];
}

// ---------------------------------------------------------------------------
// 演習・結果・ダイアログ用の偽データ
// ---------------------------------------------------------------------------

/// Firestore の代わり。バッジだけ持たせる。
class ClipFirestoreService extends FirestoreService {
  ClipFirestoreService() : super();

  // 実 Firestore に触れない（応答しない）ままにする。実装側のタイムアウト用 Timer を
  // widget test に残さないため、問題取得は本物の _getWithCacheFallback を通さない。
  @override
  Future<List<KanjiQuestion>> getQuestionsByLevel(String level,
          {int limit = 50,
          String? uid,
          String profileId = 'default',
          int masteryThreshold = 3}) =>
      Completer<List<KanjiQuestion>>().future;

  @override
  Future<List<KanjiQuestion>> getQuestionsByLevelSampled(
          String level, List<String> kanjiPool,
          {int need = 10,
          int batchSize = 30,
          int maxBatches = 4,
          String? uid,
          String profileId = 'default',
          int masteryThreshold = 3}) =>
      Completer<List<KanjiQuestion>>().future;

  @override
  Future<List<CollectionBadge>> getUserBadges(String uid,
          {String profileId = 'default'}) async =>
      [
        CollectionBadge(
          badgeId: 'b10',
          name: '10級マスター',
          description: '小学1年生の漢字をマスター',
          rarity: BadgeRarity.common,
          category: BadgeCategory.achievement,
          iconEmoji: '🎓',
          requiredCount: 1,
          conditionText: '10級の模擬試験に合格',
          createdAt: DateTime(2026, 10, 1),
          level: 'LEVEL_10',
        ),
        CollectionBadge(
          badgeId: 'b3',
          name: '3級マスター',
          description: '中学校卒業程度の漢字をマスター',
          rarity: BadgeRarity.rare,
          category: BadgeCategory.achievement,
          iconEmoji: '🎓',
          requiredCount: 1,
          conditionText: '3級の模擬試験に合格',
          createdAt: DateTime(2026, 10, 2),
          level: 'LEVEL_3',
        ),
      ];
}

/// 対戦中の状態を最初から持っている BattleRoomNotifier。
class ClipBattleNotifier extends BattleRoomNotifier {
  ClipBattleNotifier() {
    final t = DateTime(2026, 10, 14, 12);
    state = BattleRoomState(
      currentRoom: BattleRoom(
        roomId: 'b1',
        creatorId: 'p0',
        roomName: 'みんなでたのしくあそぶバトルルーム',
        examLevel: 5,
        maxParticipants: 4,
        participants: [
          for (var i = 0; i < 4; i++)
            BattleParticipant(
              userId: 'p$i',
              displayName: longName,
              currentScore: 1000 - i * 100,
              correctAnswers: 10,
              level: 12,
              joinedAt: t,
              isReady: true,
              isFinished: false,
            ),
        ],
        status: 'playing',
        totalQuestions: 20,
        timePerQuestionSeconds: 30,
        createdAt: t,
      ),
      currentSession: BattleSession(
        sessionId: 's1',
        roomId: 'b1',
        currentQuestionIndex: 3,
        participantScores: {for (var i = 0; i < 4; i++) 'p$i': 12345 - i},
        participantCorrectAnswers: const {},
        elapsedSeconds: 65,
        isActive: true,
      ),
    );
  }
}

KanjiQuestion _kq(String id, String kanji, {String? reading, String? example}) =>
    KanjiQuestion(
      id: id,
      level: 'LEVEL_3',
      kanji: kanji,
      questionType: QuestionType.multipleChoice,
      choices: const ['憂鬱', '優秀', '幽霊', '遊覧'],
      correctAnswer: '憂鬱',
      version: 1,
      reading: reading,
      example: example,
    );

/// 出題形式ごとの、長めの文言を入れた問題。
Map<String, List<PracticeQuestion>> practiceFixtures() {
  final src = _kq('k1', '憂', reading: 'うれ（い）', example: '憂いを帯びた表情（うれいをおびたひょうじょう）');
  return {
    '読みがな': [
      PracticeQuestion(
        source: src,
        actualMode: PracticeMode.reading,
        prompt: '憂',
        instruction: 'この漢字の読み方はどれ？',
        choices: const ['うれ（い）', 'ゆうしゅう', 'しゅうれいだいじん', 'ようゆうがくせい'],
        correctAnswer: 'うれ（い）',
      ),
    ],
    '漢字をあてる': [
      PracticeQuestion(
        source: src,
        actualMode: PracticeMode.writing,
        prompt: 'こうこうがくせいのれんしゅう',
        instruction: 'この読み方の漢字はどれ？',
        choices: const ['高校学生の練習', '高等学生の練習', '好況学生の練習', '孝行学生の練習'],
        correctAnswer: '高校学生の練習',
      ),
    ],
    '部首': [
      PracticeQuestion(
        source: src,
        actualMode: PracticeMode.radical,
        prompt: '憂',
        instruction: 'この漢字の部首はどれ？',
        choices: const ['夂（なつあし）', '心（こころ）', '頁（おおがい）', '冖（わかんむり）'],
        correctAnswer: '夂（なつあし）',
      ),
    ],
    '熟語の構成': [
      PracticeQuestion(
        source: src,
        actualMode: PracticeMode.compoundStructure,
        prompt: '岩石（がんせき）',
        instruction: 'この熟語の構成として正しいものはどれ？',
        choices: compoundStructureLabels.values.toList(),
        correctAnswer: compoundStructureLabels.values.first,
      ),
    ],
  };
}

List<EnhancedExamQuestion> examQuestions() => [
      for (var i = 0; i < 6; i++)
        EnhancedExamQuestion(
          questionId: 'e$i',
          kanji: '憂鬱',
          questionType: ['reading', 'writing', 'meaning', 'usage', 'stroke', 'reading'][i],
          question: '次の文の傍線部の読みを答えなさい。「彼女は憂いを帯びた表情で遠くの景色をながめていた」',
          options: const ['うれ（い）を帯びた', 'ゆうしゅうなひょうじょう', 'しゅうれいなけしき', 'ようゆうがくせい'],
          correctAnswer: 'うれ（い）を帯びた',
          explanation: '「憂い」は心配・悲しみの意味。',
          level: 3,
          difficulty: ExamDifficulty.medium,
          category: [
            ExamCategory.reading,
            ExamCategory.writing,
            ExamCategory.meaning,
            ExamCategory.usage,
            ExamCategory.stroke,
            ExamCategory.reading,
          ][i],
          averageTimeSeconds: 20,
          correctnessRate: 0.5,
          userAttempts: 3,
          commonMistakes: const [],
        ),
    ];

ExamSessionState fixtureExamSession({int index = 2, bool finished = false}) =>
    ExamSessionState(
      config: ExamConfig.standard(level: 3),
      questions: examQuestions(),
      currentQuestionIndex: finished ? 6 : index,
      elapsedSeconds: 1234,
      userAnswers: {
        0: 'うれ（い）を帯びた',
        1: 'ゆうしゅうなひょうじょう',
        2: 'うれ（い）を帯びた',
        3: 'しゅうれいなけしき',
        4: 'うれ（い）を帯びた',
        5: 'うれ（い）を帯びた',
      },
    );

ExamResult fixtureExamResult() => ExamResult(
      resultId: 'r1',
      userId: 'u1',
      examSessionId: 's1',
      examLevel: 3,
      totalQuestions: 20,
      correctAnswers: 17,
      accuracyRate: 0.85,
      totalTimeSeconds: 2345,
      answers: const [],
      completedAt: DateTime(2026, 10, 14, 12, 34),
      isPassed: true,
      estimatedRank: 12,
      categoryScores: const {
        'reading': {'accuracy': 0.9},
        'writing': {'accuracy': 0.55},
        'meaning': {'accuracy': 0.7},
        'usage': {'accuracy': 0.35},
        'stroke': {'accuracy': 1.0},
      },
    );

BattleResult fixtureBattleResult() => BattleResult(
      resultId: 'br1',
      roomId: 'b1',
      winnerId: 'p0',
      finalParticipants: [
        for (var i = 0; i < 4; i++)
          BattleParticipant(
            userId: 'p$i',
            displayName: longName,
            currentScore: 1000 - i * 100,
            correctAnswers: 20 - i,
            level: 12,
            joinedAt: DateTime(2026, 10, 14),
            isReady: true,
            isFinished: true,
          ),
      ],
      totalDurationSeconds: 345,
      completedAt: DateTime(2026, 10, 14, 12, 34),
      statistics: const {},
    );
