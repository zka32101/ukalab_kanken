import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/daily_goal.dart' show recordDailyAnswer;
import '../models/index.dart';
import '../viewmodels/index.dart';
import '../services/index.dart';
import '../widgets/level_progress_card.dart';
import '../widgets/index.dart';
import '../router/app_router.dart';
import '../providers/ranking_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/level_progress_provider.dart';
import '../models/user_ranking.dart';
import '../theme/app_theme.dart';
import '../widgets/home_group.dart';
import '../screens/reading_list_screen.dart' show kReadingsMenuLabel;
import '../screens/glossary_screen.dart' show kGlossaryMenuLabel;
import '../screens/study_notes_screen.dart'
    show kStudyNotesMenuLabel, showQuestionMemoDialog;
import '../widgets/oshi_card.dart';
import '../widgets/cert_prop_badge.dart';
import 'core_features_entry.dart';
import 'core_v069_entry.dart';
import 'exam_prep_entry.dart';
import '../widgets/oshi_readiness_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/hands_free_practice_body.dart';
import '../screens/nagara_session_screen.dart' show nagaraMenuItem;
import 'package:kanken/widgets/text_fit.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const List<String> levels = [
    'LEVEL_10', // 小1
    'LEVEL_9',  // 小2
    'LEVEL_8',  // 小3
    'LEVEL_7',  // 小4
    'LEVEL_6',  // 小5
    'LEVEL_5',  // 小6
    'LEVEL_4',  // 中学校程度
    'LEVEL_3',  // 中学校卒業程度
    'LEVEL_2_PRE', // 高校在学程度（要照合）
    'LEVEL_2',  // 高校卒業・大学・一般程度（要照合）
    'LEVEL_1_PRE', // 準1級（要照合）
    'LEVEL_1',  // 1級（要照合・用例なし）
  ];

  static const Map<String, String> levelNames = {
    'LEVEL_10': '10級（小1）',
    'LEVEL_9': '9級（小2）',
    'LEVEL_8': '8級（小3）',
    'LEVEL_7': '7級（小4）',
    'LEVEL_6': '6級（小5）',
    'LEVEL_5': '5級（小6）',
    'LEVEL_4': '4級（中学校程度）',
    'LEVEL_3': '3級（中学校卒業程度）',
    'LEVEL_2_PRE': '準2級（高校在学程度）',
    'LEVEL_2': '2級（高校卒業・大学・一般程度）',
    'LEVEL_1_PRE': '準1級（大学・一般程度）',
    'LEVEL_1': '1級（大学・一般程度）',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLevel = ref.watch(currentLevelProvider);
    final user = ref.watch(currentUserProvider);
    final weakKanjiCount = ref.watch(_weakKanjiCountProvider);
    ref.watch(reviewReminderCheckProvider); // 復習リマインダーの自動チェック

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('うかラボ 漢字検定'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CertPropBadge(),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 最上部（分類の外）: 推し
              _padded(const OshiCard()),
              const SizedBox(height: 8),
              _padded(const OshiMessageEntry()),

              // ① 今日やること
              HomeGroup(
                id: 'today',
                title: '今日やること',
                subtitle: 'まずはここから',
                emoji: '🎯',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _padded(Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryActionCard(
                            icon: Icons.play_circle_fill,
                            label: '演習を始める',
                            color: AppColors.primary,
                            onTap: () => _navigateToPractice(context, ref),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryActionCard(
                            icon: Icons.assignment,
                            label: '模擬試験モード',
                            color: AppColors.study,
                            onTap: () => context.goMockExamModes(),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(height: 8),
                    const TodayReviewEntry(),
                    const SizedBox(height: 8),
                    _padded(Text(
                      '受験級を選択',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    )),
                    const SizedBox(height: 8),
                    _padded(_buildLevelGrid(context, ref, currentLevel)),
                    const SizedBox(height: 12),
                    HomeMenuGrid(items: [
                      HomeMenuItem(
                        icon: Icons.repeat,
                        title: '復習（間隔反復）',
                        iconColor: AppColors.study,
                        onTap: () => context.goSpacedRepetitionReview(),
                      ),
                      nagaraMenuItem(context),
                      HomeMenuItem(
                        icon: Icons.edit_note,
                        title: '漢字の学習',
                        iconColor: AppColors.study,
                        onTap: () => context.goStrokeOrder(),
                      ),
                    ]),
                  ],
                ),
              ),

              // ② 記録
              HomeGroup(
                id: 'records',
                title: '記録',
                subtitle: 'これまでのがんばり',
                emoji: '📊',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _padded(const OshiGrowthEntry()),
                    const SizedBox(height: 12),
                    _padded(_buildProgressCard(context, ref, user, weakKanjiCount)),
                    const SizedBox(height: 12),
                    user.when(
                      data: (u) => (u == null || u.streakCount <= 0)
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: StreakWidget(
                                streakDays: u.streakCount,
                                lastActiveDate:
                                    u.lastStudyDate ?? DateTime.now(),
                              ),
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    _padded(const WeeklyRecapEntry()),
                    const SizedBox(height: 12),
                    _padded(_buildLevelProgressSection(context, ref)),
                    const SizedBox(height: 12),
                    HomeMenuGrid(items: [
                      HomeMenuItem(
                        icon: Icons.analytics,
                        title: '苦手分析',
                        iconColor: AppColors.analysis,
                        onTap: () => context.goWeakAreas(),
                      ),
                    ]),
                  ],
                ),
              ),

              // ③ 試験に向けて
              HomeGroup(
                id: 'exam',
                title: '試験に向けて',
                subtitle: '本番の準備をすすめよう',
                emoji: '📝',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _padded(const ExamCountdownEntry()),
                    const SizedBox(height: 8),
                    _padded(const ExamPrepEntryCard()),
                    const SizedBox(height: 12),
                    _padded(const OshiReadinessCard()),
                    const SizedBox(height: 12),
                    HomeMenuGrid(items: [
                      HomeMenuItem(
                        icon: Icons.lightbulb,
                        title: '学習計画',
                        iconColor: AppColors.analysis,
                        onTap: () => context.goLearningPlan(),
                      ),
                      HomeMenuItem(
                        icon: Icons.flag,
                        title: '学習目標',
                        iconColor: AppColors.analysis,
                        onTap: () => context.goLearningGoals(),
                      ),
                    ]),
                  ],
                ),
              ),

              // ④ 道具
              HomeGroup(
                id: 'tools',
                title: '道具',
                subtitle: '調べる・まとめる',
                emoji: '🧰',
                initiallyExpanded: false,
                child: HomeMenuGrid(items: [
                  HomeMenuItem(
                    icon: Icons.auto_stories,
                    title: kReadingsMenuLabel.replaceAll('\n', ''),
                    iconColor: AppColors.study,
                    onTap: () => context.goReadings(),
                  ),
                  HomeMenuItem(
                    icon: Icons.menu_book,
                    title: kGlossaryMenuLabel,
                    iconColor: AppColors.study,
                    onTap: () => context.goGlossary(),
                  ),
                  HomeMenuItem(
                    icon: Icons.bookmarks,
                    title: kStudyNotesMenuLabel.replaceAll('\n', ''),
                    iconColor: AppColors.study,
                    onTap: () => context.goStudyNotes(),
                  ),
                  HomeMenuItem(
                    icon: Icons.fact_check,
                    title: '間違いノート',
                    iconColor: AppColors.study,
                    onTap: () => openMistakeNote(context),
                  ),
                ]),
              ),

              // ソーシャル（漢検だけの独自グループ）
              HomeGroup(
                id: 'social',
                title: 'ソーシャル',
                subtitle: 'ともだちと楽しむ',
                emoji: '👥',
                initiallyExpanded: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HomeMenuGrid(items: [
                      HomeMenuItem(
                        icon: Icons.people,
                        title: 'フレンド',
                        iconColor: AppColors.social,
                        onTap: () => context.goFriends(),
                      ),
                      HomeMenuItem(
                        icon: Icons.sports_kabaddi,
                        title: 'チャレンジ',
                        iconColor: AppColors.social,
                        onTap: () => context.goFriendChallenges(),
                      ),
                      HomeMenuItem(
                        icon: Icons.leaderboard,
                        title: 'ランキング',
                        iconColor: AppColors.social,
                        onTap: () => context.goGlobalRanking(),
                      ),
                      HomeMenuItem(
                        icon: Icons.emoji_events,
                        title: 'スコアボード',
                        iconColor: AppColors.social,
                        onTap: () => context.goLeaderboard(),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _padded(_buildRankingPreview(context, ref)),
                    const SizedBox(height: 12),
                    _padded(_buildFriendPreview(context, ref)),
                  ],
                ),
              ),

              // ⑥ 設定・その他（常に表示）
              HomeGroup(
                id: 'others',
                title: '設定・その他',
                emoji: '⭐',
                collapsible: false,
                child: HomeMenuGrid(items: [
                  HomeMenuItem(
                    icon: Icons.card_giftcard,
                    title: 'バッジ',
                    iconColor: AppColors.reward,
                    onTap: () => context.goCollectionBadge(),
                  ),
                  HomeMenuItem(
                    icon: Icons.settings,
                    title: '設定',
                    iconColor: AppColors.info,
                    onTap: () => context.goSettings(),
                  ),
                  HomeMenuItem(
                    icon: Icons.workspace_premium,
                    title: 'プラン',
                    iconColor: AppColors.primary,
                    onTap: () => context.goPaywall(),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _padded(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  Widget _buildPrimaryActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<User?> user,
    AsyncValue<int> weakKanjiCount,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'あなたの進捗',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '🔥 ストリーク',
                user.when(
                  data: (u) => '${u?.streakCount ?? 0}日',
                  loading: () => '-',
                  error: (_, __) => 'エラー',
                ),
              ),
              _buildStatItem(
                '⚠️ 苦手漢字',
                weakKanjiCount.when(
                  data: (count) => '$count個',
                  loading: () => '-',
                  error: (_, __) => 'エラー',
                ),
              ),
              _buildStatItem(
                '🎯 合格級',
                user.when(
                  data: (u) =>
                      levelNames[u?.currentLevel ?? 'LEVEL_10'] ??
                      'LEVEL_10',
                  loading: () => '-',
                  error: (_, __) => 'エラー',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
        child: Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    ));
  }

  /// プレミアム加入者だけが学べる級（準1級・1級）。広告なしだけでは学べない
  static const premiumOnlyLevels = {'LEVEL_1_PRE', 'LEVEL_1'};

  Widget _buildLevelGrid(BuildContext context, WidgetRef ref, String currentLevel) {
    final isPremium = ref.watch(hasPremiumProvider).valueOrNull ?? false;
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: levels.map((level) {
        final isSelected = level == currentLevel;
        return GestureDetector(
          onTap: () {
            if (premiumOnlyLevels.contains(level) && !isPremium) {
              _showPremiumRequired(context, levelNames[level]?.split('（').first ?? level);
              return;
            }
            ref.read(currentLevelProvider.notifier).state = level;
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.surface,
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (premiumOnlyLevels.contains(level) && !isPremium)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock, size: 16, color: cs.onSurfaceVariant),
                    ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        levelNames[level]?.split('（').first ?? level,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showPremiumRequired(BuildContext context, String levelName) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text('$levelNameはプレミアム限定です'),
        content: const Text('準1級・1級はプレミアムに加入すると学習できます（広告も非表示になります）。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.goPaywall();
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
  }

  /// 級ごとの正答率進捗バー（現在選択中の級だけ表示）＋次の級までのカウントダウン
  Widget _buildLevelProgressSection(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(levelProgressProvider);
    final currentLevel = ref.watch(currentLevelProvider);

    return statsAsync.when(
      data: (stats) {
        final progress = levelProgressFor(stats, currentLevel);
        final levelLabel = levelNames[currentLevel] ?? currentLevel;

        // 演習画面と同じ判定（その級の問題が1問も無い）。読み込み中は通常の表示にする。
        final noQuestions =
            ref.watch(practiceQuestionsProvider(currentLevel)).valueOrNull?.isEmpty ?? false;
        return LevelProgressCard(
          levelLabel: levelLabel,
          progress: progress,
          noQuestions: noQuestions,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRankingPreview(BuildContext context, WidgetRef ref) {
    final filter = const RankingFilter(limit: 5);
    final rankingAsyncValue = ref.watch(rankingProvider(filter));

    return rankingAsyncValue.when(
      data: (rankings) {
        if (rankings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ランキングデータなし',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rankings.take(3).length,
            itemBuilder: (context, index) {
              final ranking = rankings[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    FitWidth(
                      maxFraction: 0.15,
                      child: Text(
                        ranking.getRankBadge(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ranking.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Lv ${ranking.level} • ${(ranking.accuracyRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FitWidth(
                      maxFraction: 0.2,
                      child: Text(
                        '🔥${ranking.streak}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 80,
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'ランキング取得エラー',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildFriendPreview(BuildContext context, WidgetRef ref) {
    final friendsAsyncValue = ref.watch(friendListProvider);

    return friendsAsyncValue.when(
      data: (friends) {
        if (friends.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'フレンドを追加しましょう',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friends.take(3).length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: friend.isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Lv ${friend.level} • ${(friend.accuracyRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FitWidth(
                      maxFraction: 0.15,
                      child: Text(
                        friend.getStatusIcon(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 80,
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'フレンド取得エラー',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _navigateToPractice(BuildContext context, WidgetRef ref) async {
    final level = ref.read(currentLevelProvider);
    final singleModes = availableModesForLevel(level);

    final mode = await showDialog<PracticeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('出題形式をえらぼう'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, PracticeMode.mixed),
            child: const ListTile(
              leading: Icon(Icons.shuffle),
              title: Text('まぜて出題'),
              subtitle: Text('この級の出題形式をランダムに出題'),
            ),
          ),
          for (final m in singleModes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, m),
              child: ListTile(
                leading: Icon(_practiceModeIcon(m)),
                title: Text(_practiceModeLabel(m)),
                subtitle: Text(_practiceModeDescription(m)),
              ),
            ),
        ],
      ),
    );
    if (mode == null) return;

    ref.read(practiceModeProvider.notifier).state = mode;
    ref.read(practiceRetryQuestionsProvider.notifier).state = null;
    ref.invalidate(practiceQuestionsProvider(level));

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PracticeScreen(),
      ),
    );
  }
}

double _promptFontSize(PracticeMode mode) {
  switch (mode) {
    case PracticeMode.reading:
    case PracticeMode.radical:
      return 80;
    case PracticeMode.compoundStructure:
      return 48;
    case PracticeMode.writing:
    case PracticeMode.mixed:
      return 40;
  }
}

IconData _practiceModeIcon(PracticeMode mode) {
  switch (mode) {
    case PracticeMode.reading:
      return Icons.record_voice_over;
    case PracticeMode.writing:
      return Icons.edit;
    case PracticeMode.radical:
      return Icons.category;
    case PracticeMode.compoundStructure:
      return Icons.account_tree;
    case PracticeMode.mixed:
      return Icons.shuffle;
  }
}

String _practiceModeLabel(PracticeMode mode) {
  switch (mode) {
    case PracticeMode.reading:
      return '読みがな';
    case PracticeMode.writing:
      return '漢字をあてる';
    case PracticeMode.radical:
      return '部首';
    case PracticeMode.compoundStructure:
      return '熟語の構成';
    case PracticeMode.mixed:
      return 'まぜて出題';
  }
}

String _practiceModeDescription(PracticeMode mode) {
  switch (mode) {
    case PracticeMode.reading:
      return '漢字を見て読み方を答える';
    case PracticeMode.writing:
      return '読み方を見て漢字を答える';
    case PracticeMode.radical:
      return '漢字の部首を答える';
    case PracticeMode.compoundStructure:
      return '二字熟語の成り立ちを答える';
    case PracticeMode.mixed:
      return 'この級の出題形式をランダムに出題';
  }
}

// 苦手漢字数を取得するProvider
final _weakKanjiCountProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return 0;

  final user = await ref.watch(currentUserProvider.future);
  final aiWeakService = ref.watch(aiWeakAnalysisServiceProvider);
  return await aiWeakService.getWeakKanjiCount(
    uid,
    profileId: user?.profileId ?? 'default',
  );
});

/// 今回の練習で貯まった学習コインの内訳（付与がなければ何も出ない）。
Widget _practiceCoinBreakdown(WidgetRef ref) {
  try {
    return CoinBreakdownCard(grants: ref.watch(coinProvider).recent);
  } catch (_) {
    return const SizedBox.shrink();
  }
}

// 練習画面
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(currentLevelProvider);
    final questions = ref.watch(practiceQuestionsProvider(level));
    final currentIndex = ref.watch(currentQuestionIndexProvider);
    final correctCount = ref.watch(correctCountProvider);
    final comboCount = ref.watch(comboCountProvider);
    final ahaMomentReached = ref.watch(ahaMomentReachedProvider);
    final levelStatsAsync = ref.watch(levelProgressProvider);

    return WillPopScope(
      onWillPop: () async {
        ref.read(practiceViewModelProvider.notifier).reset();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const FitTitle('演習中'),
          leading: BackButton(
            onPressed: () {
              ref.read(practiceViewModelProvider.notifier).reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: questions.when(
          data: (qList) {
            // この級の問題がまだ用意されていないときは、「0問クリア」ではなく案内を出す
            if (qList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: MinHeightScroll(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 72, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'この級の問題は、じゅんびちゅうです。\nほかの級で、れんしゅうしてね。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(practiceViewModelProvider.notifier).reset();
                          Navigator.pop(context);
                        },
                        child: const Text('ホームに戻る'),
                      ),
                    ],
                    ),
                  ),
                ),
              );
            }
            if (currentIndex >= qList.length) {
              return MinHeightScroll(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      '🎉 ${qList.length}問クリア！\n正解数: $correctCount / ${qList.length}問',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _practiceCoinBreakdown(ref),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(practiceViewModelProvider.notifier).reset();
                        Navigator.pop(context);
                      },
                      child: const Text('ホームに戻る'),
                    ),
                  ],
                ),
              );
            }

            final question = qList[currentIndex];
            return _buildPracticeContent(
              context,
              ref,
              question,
              currentIndex,
              qList.length,
              correctCount,
              comboCount,
              ahaMomentReached,
              levelStatsAsync.valueOrNull,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('エラー: $err')),
        ),
      ),
    );
  }

  Widget _buildPracticeContent(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion question,
    int currentIndex,
    int totalQuestions,
    int correctCount,
    int comboCount,
    bool ahaMomentReached,
    Map<String, LevelProgress>? levelStats,
  ) {
    final level = ref.read(currentLevelProvider);
    final levelProgress =
        levelStats != null ? levelProgressFor(levelStats, level) : null;

    // ながら学習モード（片手・読み上げ）: 選択式の問題は、大きなボタンを下に寄せた表示にする。
    if (ref.watch(handsFreeProvider).enabled &&
        question.source.questionType == QuestionType.multipleChoice) {
      return HandsFreePracticeBody(
        question: question,
        index: currentIndex,
        total: totalQuestions,
        onAnswer: (isCorrect) => _handleAnswer(context, ref, isCorrect),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      // 文字が大きいとき・画面が小さいときは、内容が画面より高くなるので縦にスクロールできるようにする
      // （収まるときは今までどおり、選択肢を残りの高さの中央に並べる）。
      child: MinHeightScroll(
        intrinsicHeight: true,
        child: Column(
        children: [
          // 進捗バー
          LinearProgressIndicator(
            value: (currentIndex + 1) / totalQuestions,
          ),
          const SizedBox(height: 4),
          Text(
            '問題 ${currentIndex + 1} / $totalQuestions',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (levelProgress != null && !levelProgress.isCleared)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'あと${levelProgress.remainingCorrectToClear}問正解で次の級へ！',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // 正解数・コンボ表示
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text('正解: $correctCount問', style: const TextStyle(fontSize: 14)),
              Text('コンボ: $comboCount', style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 24),

          // 出題形式の指示文
          Text(
            question.instruction,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),

          // 問題表示（漢字 or 読み方 or 熟語など、大きく）
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _promptFontSize(question.actualMode),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _markAsLearned(context, ref, question),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('覚えた！ 次から出さない'),
              ),
              BookmarkToggleButton(qid: question.source.id),
              IconButton(
                icon: Icon(
                  ref.watch(questionMemoProvider).containsKey(question.source.id)
                      ? Icons.sticky_note_2
                      : Icons.sticky_note_2_outlined,
                ),
                tooltip: '自分用メモ',
                onPressed: () => showQuestionMemoDialog(
                  context,
                  ref,
                  qid: question.source.id,
                  title: question.source.kanji,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 選択肢
          if (question.source.questionType == QuestionType.multipleChoice)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: question.choices.asMap().entries.map((entry) {
                  final choice = entry.value;
                  final isCorrect = choice == question.correctAnswer;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          _handleAnswer(context, ref, isCorrect);
                        },
                        child: Text(choice),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('手書き判定（実装予定）'),
              ),
            ),

          // Aha Moment達成メッセージ
          if (ahaMomentReached)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '🎉 初回3問正解達成！\n苦手分析を確認できるようになります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Future<void> _handleAnswer(BuildContext context, WidgetRef ref, bool isCorrect) async {
    final practiceVM = ref.read(practiceViewModelProvider.notifier);
    final level = ref.read(currentLevelProvider);
    final question = ref.read(practiceViewModelProvider).currentQuestion;

    await practiceVM.answerQuestion(isCorrect);
    // デイリーミッション（学習リマインダーの判定にも使う）
    await recordDailyAnswer(ref);

    // 演出（Lottie + SE + ハプティクス）
    if (isCorrect) {
      // SE再生（正解）
      await ref.read(answerFeedbackProvider).correct();
      // 正解演出表示
      _showCorrectFeedback(context, question);
      // Analytics: 3問正解でAha Moment
      final ahaMoment = ref.read(ahaMomentReachedProvider);
      if (ahaMoment) {
        await AnalyticsService.logAhaMomentReached(level: level);
      }
    } else {
      // SE再生（不正解）
      await ref.read(answerFeedbackProvider).incorrect();
      // 不正解演出表示
      _showIncorrectFeedback(context, question);
    }

    // 読み方・用例を読む時間を確保してから次の問題へ
    await Future.delayed(const Duration(milliseconds: 2200));

    // 演習セッション(practiceSessionSize問)の最後の1問が終わったタイミングのみ、
    // 広告ゲートがインタースティシャルを挟む（加入中・間隔/日次上限内は出さない）。
    // 演習の最中(セッション途中)には広告を出さない(うかラボ共通方針)。
    final currentIndex = ref.read(currentQuestionIndexProvider);
    final isSessionEnd = currentIndex + 1 >= practiceSessionSize;
    if (isSessionEnd) {
      await AdService.gate?.maybeShowInterstitial(InterstitialTrigger.sessionEnd);
    }

    // 正解の場合のみ、級クリア（正答率80%以上）に達したか確認し、
    // 新しく達成していれば証書風のお祝いダイアログを出す
    if (isCorrect) {
      final newlyCleared = await checkAndAwardLevelClearBadge(ref, level);
      if (newlyCleared && context.mounted) {
        await showLevelClearCelebration(
          context,
          levelName: HomeScreen.levelNames[level] ?? level,
          feedback: ref.read(answerFeedbackProvider),
        );
      }
    }

    practiceVM.moveToNextQuestion();
  }

  Future<void> _markAsLearned(
    BuildContext context,
    WidgetRef ref,
    PracticeQuestion question,
  ) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    final user = await ref.read(currentUserProvider.future);
    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.markAsLearned(
      uid,
      question.source.id,
      profileId: user?.profileId ?? 'default',
    );
    ref.invalidate(learnedKanjiIdsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${question.source.kanji}」を覚えた問題にしました')),
      );
    }
  }

  /// 読み仮名・用例があれば付け足した解説文を作る
  String? _buildExplanation(PracticeQuestion? question) {
    if (question == null) return null;
    final source = question.source;
    final parts = <String>[];
    if (source.reading != null && source.reading!.isNotEmpty) {
      parts.add('読み方: ${source.reading}');
    }
    if (source.example != null && source.example!.isNotEmpty) {
      parts.add('例: ${source.example}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  void _showCorrectFeedback(BuildContext context, PracticeQuestion? question) {
    final explanation = _buildExplanation(question);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          explanation == null ? '✨ 正解！' : '✨ 正解！\n$explanation',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 2200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showIncorrectFeedback(BuildContext context, PracticeQuestion? question) {
    final explanation = _buildExplanation(question);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          explanation == null ? '⚠️ 不正解' : '⚠️ 不正解\n$explanation',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(milliseconds: 2200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
