import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import '../models/multiplayer.dart';
import '../providers/battle_provider.dart';
import 'package:kanken/widgets/text_fit.dart';

class BattleRoomListScreen extends ConsumerWidget {
  const BattleRoomListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableRooms = ref.watch(availableBattleRoomsProvider);
    final battleStats = ref.watch(userBattleStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('オンライン対戦'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ユーザー統計カード
          battleStats.when(
            data: (stats) => _buildStatsCard(context, stats),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ルーム一覧
          Expanded(
            child: availableRooms.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return _buildEmptyState(context);
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    return _buildRoomTile(context, ref, rooms[index]);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, __) => Center(
                child: Text('エラー: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('ルームを作成'),
        backgroundColor: Colors.purple.shade400,
        onPressed: () => _showCreateRoomDialog(context, ref),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, BattleRoomStats stats) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade400, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '対戦成績',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  '対戦',
                  '${stats.totalBattles}',
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  '勝',
                  '${stats.victories}',
                  Colors.lightGreen.shade300,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  '敗',
                  '${stats.defeats}',
                  Colors.red.shade300,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  '勝率',
                  '${(stats.getWinRate() * 100).toStringAsFixed(1)}%',
                  Colors.amber.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildRoomTile(
    BuildContext context,
    WidgetRef ref,
    BattleRoom room,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${room.examLevel}級 • ${room.totalQuestions}問',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CapWidth(
                  maxFraction: 0.3,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${room.participants.length}/${room.maxParticipants}人',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('参加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: room.canJoin()
                        ? () => _joinRoom(context, ref, room.roomId)
                        : null,
                  ),
                ),
                if (room.isFull())
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Chip(
                      label: const Text('満員'),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videogame_asset_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '利用可能なルームがありません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'ルームを作成して対戦を始めましょう',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateRoomDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    String roomName = '';
    int selectedLevel = 10;
    int maxParticipants = 2;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('ルームを作成'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  label: FitTitle('ルーム名'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => roomName = value,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('受験級: $selectedLevel級'),
                    Slider(
                      value: selectedLevel.toDouble(),
                      min: 5,
                      max: 10,
                      divisions: 5,
                      label: '$selectedLevel級',
                      onChanged: (value) {
                        setState(() => selectedLevel = value.toInt());
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('最大参加人数: $maxParticipants人'),
                    Slider(
                      value: maxParticipants.toDouble(),
                      min: 2,
                      max: 4,
                      divisions: 2,
                      label: '$maxParticipants人',
                      onChanged: (value) {
                        setState(() => maxParticipants = value.toInt());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (roomName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ルーム名を入力してください')),
                );
                return;
              }

              ref.read(battleRoomNotifierProvider.notifier).createRoom(
                    roomName: roomName,
                    examLevel: selectedLevel,
                    maxParticipants: maxParticipants,
                    totalQuestions: 10,
                    timePerQuestionSeconds: 60,
                  );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ルームを作成しました')),
              );
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom(
    BuildContext context,
    WidgetRef ref,
    String roomId,
  ) async {
    ref.read(battleRoomNotifierProvider.notifier).joinRoom(roomId: roomId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ルームに参加しました')),
    );
    // ルーム詳細画面に遷移
    context.goBattle(roomId);
  }
}
