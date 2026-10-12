import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/global_event.dart';
import '../models/user_ranking.dart';
import '../providers/event_provider.dart';
import '../providers/ranking_provider.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';
import '../theme/app_theme.dart';

class GlobalRankingScreen extends ConsumerStatefulWidget {
  const GlobalRankingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GlobalRankingScreen> createState() =>
      _GlobalRankingScreenState();
}

class _GlobalRankingScreenState extends ConsumerState<GlobalRankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RankingType _selectedType = RankingType.experience;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final activeEventsAsync = ref.watch(activeEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 グローバルランキング'),
        centerTitle: true,
        backgroundColor: AppColors.primarySoft,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryDark,
          tabs: const [
            Tab(child: Text('イベント別')),
            Tab(child: Text('全体')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // イベント別ランキング
          activeEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return _buildEmptyState('アクティブなイベントはありません');
              }

              final eventId = _selectedEventId ?? events[0].eventId;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // イベント選択
                    _buildEventSelector(events),
                    const SizedBox(height: 16),

                    // イベントのランキング
                    _buildEventRanking(eventId, currentUserId),
                  ],
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('エラー: $error')),
          ),

          // 全体ランキング
          _buildGlobalRanking(currentUserId),
        ],
      ),
    );
  }

  /// イベント選択ドロップダウン
  Widget _buildEventSelector(List<GlobalEvent> events) {
    final selectedEvent = _selectedEventId == null
        ? events[0]
        : events.firstWhere((e) => e.eventId == _selectedEventId);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primarySoft, AppColors.surfaceMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 イベントを選択',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: selectedEvent.eventId,
            isExpanded: true,
            underline: Container(),
            items: events.map((event) {
              return DropdownMenuItem<String>(
                value: event.eventId,
                child: Text(
                  '${event.getStatusEmoji()} ${event.eventName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedEventId = value);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            '参加者: ${selectedEvent.participantCount}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// イベント内のランキング
  Widget _buildEventRanking(String eventId, String? currentUserId) {
    final participantsAsync =
        ref.watch(eventParticipantsProvider(eventId));

    return participantsAsync.when(
      data: (participants) {
        if (participants.isEmpty) {
          return _buildEmptyState('参加者がいません');
        }

        // スコアでソート
        final sorted = List<EventParticipation>.from(participants)
          ..sort((a, b) => b.currentScore.compareTo(a.currentScore));

        return Column(
          children: [
            // 現在のユーザーのランク表示
            if (currentUserId != null)
              _buildUserEventRankCard(sorted, currentUserId),

            // ランキング一覧
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final participant = sorted[index];
                  final rank = index + 1;
                  return _buildEventParticipantCard(
                    participant,
                    rank,
                    isCurrentUser: participant.userId == currentUserId,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('エラー: $error'),
      ),
    );
  }

  /// ユーザーのイベント内ランク表示
  Widget _buildUserEventRankCard(
    List<EventParticipation> sorted,
    String currentUserId,
  ) {
    final userIndex = sorted.indexWhere((p) => p.userId == currentUserId);
    final userRank = userIndex >= 0 ? userIndex + 1 : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'あなたのランク',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (userRank != null) ...[
                Text(
                  userRank.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '位',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                  ),
                ),
              ] else
                const Text(
                  'このイベントに参加していません',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// イベント参加者カード
  Widget _buildEventParticipantCard(
    EventParticipation participant,
    int rank,
    {required bool isCurrentUser}
  ) {
    final isMedal = rank <= 3;
    final medalEmoji = participant.getRankBadge();
    final medalColor = rank == 1
        ? Colors.amber
        : rank == 2
            ? Colors.grey
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primarySoft
            : isMedal
                ? medalColor.withOpacity(0.1)
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : isMedal
                ? Border.all(color: medalColor.withOpacity(0.3), width: 2)
                : null,
      ),
      child: Row(
        children: [
          // ランク表示
          SizedBox(
            width: 50,
            child: Center(
              child: UkalabEmoji(medalEmoji, size: 28),
            ),
          ),
          const SizedBox(width: 12),

          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        participant.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'あなた',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'スコア',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${participant.currentScore}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '報酬',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${participant.rewardCoins} 🪙',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (participant.isCompleted)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '進行中',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 全体ランキング
  Widget _buildGlobalRanking(String? currentUserId) {
    final filter = RankingFilter(
      type: _selectedType,
      period: RankingPeriod.allTime,
      limit: 100,
    );

    final rankingAsync = ref.watch(rankingProvider(filter));

    return SingleChildScrollView(
      child: Column(
        children: [
          // フィルタータイプ選択
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip(RankingType.experience, '経験値'),
                  const SizedBox(width: 8),
                  _buildTypeChip(RankingType.coins, 'コイン'),
                  const SizedBox(width: 8),
                  _buildTypeChip(RankingType.accuracy, '正答率'),
                  const SizedBox(width: 8),
                  _buildTypeChip(RankingType.streak, 'ストリーク'),
                ],
              ),
            ),
          ),

          // ランキング一覧
          rankingAsync.when(
            data: (rankings) {
              if (rankings.isEmpty) {
                return _buildEmptyState('ランキングデータがありません');
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rankings.length,
                  itemBuilder: (context, index) {
                    return _buildGlobalRankingCard(
                      rankings[index],
                      isCurrentUser:
                          rankings[index].userId == currentUserId,
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('エラー: $error'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// グローバルランキングカード
  Widget _buildGlobalRankingCard(
    UserRanking ranking, {
    required bool isCurrentUser,
  }) {
    final isMedal = ranking.rank <= 3;
    final medalEmoji = ranking.getRankBadge();
    final medalColor = ranking.rank == 1
        ? Colors.amber
        : ranking.rank == 2
            ? Colors.grey
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primarySoft
            : isMedal
                ? medalColor.withOpacity(0.1)
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : isMedal
                ? Border.all(color: medalColor.withOpacity(0.3), width: 2)
                : null,
      ),
      child: Row(
        children: [
          // ランク表示
          SizedBox(
            width: 50,
            child: Center(
              child: UkalabEmoji(medalEmoji, size: 28),
            ),
          ),
          const SizedBox(width: 12),

          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ranking.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'あなた',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lv',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${ranking.level}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXP',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${ranking.experience}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '正答率',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${(ranking.accuracyRate * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '🔥 ${ranking.streak}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// タイプ選択チップ
  Widget _buildTypeChip(RankingType type, String label) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = type);
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 空の状態表示
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
