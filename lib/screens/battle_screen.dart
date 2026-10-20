import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import '../models/multiplayer.dart';
import '../providers/battle_provider.dart';
import 'package:kanken/widgets/text_fit.dart';

class BattleScreen extends ConsumerStatefulWidget {
  final String roomId;

  const BattleScreen({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(minutes: 30),
      vsync: this,
    )..forward();

    _timerController.addListener(() {
      setState(() {
        _elapsedSeconds = (_timerController.value * 1800).toInt();
      });
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final battleState = ref.watch(battleRoomNotifierProvider);

    if (battleState.currentRoom == null || battleState.currentSession == null) {
      return Scaffold(
        appBar: AppBar(title: const FitTitle('対戦中')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final room = battleState.currentRoom!;
    final session = battleState.currentSession!;

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('対戦中'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            // 縦の余白は AppBar の高さ（56）に収めるため 0（中央寄せなので見た目は同じ）
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatTime(300 - _elapsedSeconds), // 5分制限
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _elapsedSeconds > 240
                            ? Colors.red
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
      // 文字が大きいときは、全体を縦にスクロールできるようにする（収まるときは今までどおり）。
      body: MinHeightScroll(
        intrinsicHeight: true,
        child: Column(
        children: [
          // 参加者のスコア表示
          _buildScoreBoard(context, session, room.participants),

          // 問題進捗
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: session.currentQuestionIndex / room.totalQuestions,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  '問題 ${session.currentQuestionIndex} / ${room.totalQuestions}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // 問題表示エリア
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '問題表示',
                        style:
                            Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('正解'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      onPressed: () => _recordAnswer(
                        session.sessionId,
                        true,
                        10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('不正解'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                      ),
                      onPressed: () =>
                          _recordAnswer(session.sessionId, false, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 対戦終了ボタン
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flag),
                label: const Text('対戦を終了'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _endBattle(context),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard(
    BuildContext context,
    BattleSession session,
    List<BattleParticipant> participants,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: participants.map((participant) {
          final score = session.participantScores[participant.userId] ?? 0;
          final isCurrentUser = participant.userId ==
              ref.read(battleRoomNotifierProvider).currentRoom?.creatorId;

          return Expanded(
            child: Column(
            children: [
              Text(
                participant.displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blue : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$score点',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isCurrentUser ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _recordAnswer(
    String sessionId,
    bool isCorrect,
    int points,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final notifier = ref.read(battleRoomNotifierProvider.notifier);

    await notifier.recordBattleAnswer(
      sessionId: sessionId,
      userId: userId,
      isCorrect: isCorrect,
      pointsEarned: points,
    );

    if (!mounted) return;

    final battleState = ref.read(battleRoomNotifierProvider);
    final room = battleState.currentRoom;
    final session = battleState.currentSession;

    // 全問終了していたら対戦を自動終了する
    if (room != null &&
        session != null &&
        session.currentQuestionIndex >= room.totalQuestions) {
      await _endBattle(context);
    }
  }

  Future<void> _endBattle(BuildContext context) async {
    final battleState = ref.read(battleRoomNotifierProvider);
    if (battleState.currentRoom == null ||
        battleState.currentSession == null) {
      return;
    }

    final result = await ref
        .read(battleRoomNotifierProvider.notifier)
        .completeBattle(
          roomId: battleState.currentRoom!.roomId,
          sessionId: battleState.currentSession!.sessionId,
        );

    if (result != null && mounted) {
      context.goBattleResult(result);
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
