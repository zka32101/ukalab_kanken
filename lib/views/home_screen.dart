import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../viewmodels/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';
import '../router/app_router.dart';
import '../providers/ranking_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../providers/level_progress_provider.dart';
import '../models/user_ranking.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_grid_card.dart';
import '../screens/reading_list_screen.dart' show kReadingsMenuLabel;
import '../widgets/oshi_card.dart';
import '../widgets/oshi_readiness_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/hands_free_practice_body.dart';

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
        title: const Text('うかラボ漢字検定'),
      ),
      bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ユーザー情報・進捗セクション
              _buildProgressCard(context, ref, user, weakKanjiCount),
              const SizedBox(height: 12),
              user.when(
                data: (u) => (u == null || u.streakCount <= 0)
                    ? const SizedBox.shrink()
                    : StreakWidget(
                        streakDays: u.streakCount,
                        lastActiveDate: u.lastStudyDate ?? DateTime.now(),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const OshiCard(),
              const SizedBox(height: 12),
              const OshiReadinessCard(),
              const SizedBox(height: 20),

              // メインCTA（演習・模擬試験）
              Row(
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
              ),
              const SizedBox(height: 24),

              // 級選択セクション
              const Text(
                '受験級を選択',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLevelGrid(context, ref, currentLevel),
              const SizedBox(height: 20),
              _buildLevelProgressSection(context, ref),
              const SizedBox(height: 28),

              // 学習セクション
              const SectionHeader(title: '学習 📖'),
              const SizedBox(height: 12),
              MenuGrid(children: [
                MenuGridCard(
                  icon: Icons.edit_note,
                  label: '漢字の\n学習',
                  color: AppColors.study,
                  onTap: () => context.goStrokeOrder(),
                ),
                MenuGridCard(
                  icon: Icons.auto_stories,
                  label: kReadingsMenuLabel,
                  color: AppColors.study,
                  onTap: () => context.goReadings(),
                ),
                MenuGridCard(
                  icon: Icons.repeat,
                  label: '復習\n(間隔反復)',
                  color: AppColors.study,
                  onTap: () => context.goSpacedRepetitionReview(),
                ),
                MenuGridCard(
                  icon: Icons.analytics,
                  label: '苦手分析',
                  color: AppColors.analysis,
                  onTap: () => context.goWeakAreas(),
                ),
                MenuGridCard(
                  icon: Icons.lightbulb,
                  label: '学習計画',
                  color: AppColors.analysis,
                  onTap: () => context.goLearningPlan(),
                ),
                MenuGridCard(
                  icon: Icons.flag,
                  label: '学習目標',
                  color: AppColors.analysis,
                  onTap: () => context.goLearningGoals(),
                ),
              ]),
              const SizedBox(height: 28),

              // ソーシャルセクション
              const SectionHeader(title: 'ソーシャル 👥'),
              const SizedBox(height: 12),
              MenuGrid(children: [
                MenuGridCard(
                  icon: Icons.people,
                  label: 'フレンド',
                  color: AppColors.social,
                  onTap: () => context.goFriends(),
                ),
                MenuGridCard(
                  icon: Icons.sports_kabaddi,
                  label: 'チャレンジ',
                  color: AppColors.social,
                  onTap: () => context.goFriendChallenges(),
                ),
                MenuGridCard(
                  icon: Icons.leaderboard,
                  label: 'ランキング',
                  color: AppColors.social,
                  onTap: () => context.goGlobalRanking(),
                ),
                MenuGridCard(
                  icon: Icons.emoji_events,
                  label: 'スコアボード',
                  color: AppColors.social,
                  onTap: () => context.goLeaderboard(),
                ),
              ]),
              const SizedBox(height: 20),
              _buildRankingPreview(context, ref),
              const SizedBox(height: 12),
              _buildFriendPreview(context, ref),
              const SizedBox(height: 28),

              // コレクション・その他セクション
              const SectionHeader(title: 'その他 ⭐'),
              const SizedBox(height: 12),
              MenuGrid(children: [
                MenuGridCard(
                  icon: Icons.card_giftcard,
                  label: 'バッジ',
                  color: AppColors.reward,
                  onTap: () => context.goCollectionBadge(),
                ),
                MenuGridCard(
                  icon: Icons.settings,
                  label: '設定',
                  color: AppColors.info,
                  onTap: () => context.goSettings(),
                ),
                MenuGridCard(
                  icon: Icons.workspace_premium,
                  label: 'プラン',
                  color: AppColors.primary,
                  onTap: () => context.goPaywall(),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

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
        gradient: const LinearGradient(
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  /// プレミアム加入者だけが学べる級（準1級・1級）。広告なしだけでは学べない
  static const premiumOnlyLevels = {'LEVEL_1_PRE', 'LEVEL_1'};

  Widget _buildLevelGrid(BuildContext context, WidgetRef ref, String currentLevel) {
    final isPremium = ref.watch(hasPremiumProvider).valueOrNull ?? false;
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
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (premiumOnlyLevels.contains(level) && !isPremium)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.lock, size: 16, color: Colors.black45),
                    ),
                  Text(
                    levelNames[level]?.split('（').first ?? level,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
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

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryProgressBar(
                category: levelLabel,
                progress: progress.accuracyRate,
                correctCount: progress.correctCount,
                totalCount: progress.totalCount,
              ),
              if (progress.isCleared)
                const Text(
                  '✅ この級はクリア基準を達成しています！',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                )
              else
                Text(
                  'あと${progress.remainingCorrectToClear}問正解で次の級へ！',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
            ],
          ),
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
                    Text(
                      ranking.getRankBadge(),
                      style: const TextStyle(fontSize: 20),
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
                    Text(
                      '🔥${ranking.streak}',
                      style: const TextStyle(fontSize: 12),
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
                    Text(
                      friend.getStatusIcon(),
                      style: const TextStyle(fontSize: 12),
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
          title: const Text('演習中'),
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
              );
            }
            if (currentIndex >= qList.length) {
              return Center(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          TextButton.icon(
            onPressed: () => _markAsLearned(context, ref, question),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('覚えた！ 次から出さない'),
          ),
          const SizedBox(height: 8),

          // 選択肢
          if (question.source.questionType == QuestionType.multipleChoice)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: question.choices.asMap().entries.map((entry) {
                  final idx = entry.key;
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
    );
  }

  Future<void> _handleAnswer(BuildContext context, WidgetRef ref, bool isCorrect) async {
    final practiceVM = ref.read(practiceViewModelProvider.notifier);
    final level = ref.read(currentLevelProvider);
    final question = ref.read(practiceViewModelProvider).currentQuestion;

    await practiceVM.answerQuestion(isCorrect);

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
