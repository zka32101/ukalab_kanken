import 'package:ukalab_core/ui.dart'
    show
        ExamPhase,
        MascotDayState,
        MascotExpression,
        MascotScene,
        MascotStage,
        UkalabCert,
        UkalabOshiRoom,
        equippedOutfitProvider,
        selectedCharacterPackProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/oshi_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/text_fit.dart';

/// 推しの部屋で立たせる場面のポーズ。試験日の前日は応援、3日以上の連続学習は炎。
/// どちらでもなければ null（通常のポーズ）。ホームの推しカードと同じ基準。
MascotScene? oshiRoomSceneFor({
  required DateTime? examDate,
  required int streakDays,
  required DateTime now,
}) {
  final phase = MascotDayState(examDate: examDate).examPhase(now);
  if (phase == ExamPhase.eve) return MascotScene.eve;
  if (streakDays >= 3) return MascotScene.streak;
  return null;
}

/// 推しの部屋（表示のみ）。選んだ推し・成長段階・着替え・場面のポーズで、
/// 共通キットの [UkalabOshiRoom] を横長/縦長で見せる。画像の保存・共有はまだ作らない。
class OshiRoomScreen extends ConsumerStatefulWidget {
  const OshiRoomScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OshiRoomScreen> createState() => _OshiRoomScreenState();
}

class _OshiRoomScreenState extends ConsumerState<OshiRoomScreen> {
  bool _portrait = false;

  @override
  Widget build(BuildContext context) {
    final pack = ref.watch(selectedCharacterPackProvider);
    final outfit = ref.watch(equippedOutfitProvider);
    final stage = ref.watch(oshiStageProvider).valueOrNull ?? MascotStage.lv1;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final streak = user?.streakCount ?? 0;
    final scene = oshiRoomSceneFor(
      examDate: user?.examDate,
      streakDays: streak,
      now: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(title: const FitTitle('推しの部屋')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('横長')),
                ButtonSegment(value: true, label: Text('縦長')),
              ],
              selected: {_portrait},
              onSelectionChanged: (s) => setState(() => _portrait = s.first),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _portrait ? 320 : 560),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: UkalabOshiRoom.forCert(
                  cert: UkalabCert.kanjiKentei,
                  pack: pack,
                  stage: stage,
                  outfit: outfit,
                  scene: scene,
                  expression: (streak >= 3 || scene != null)
                      ? MascotExpression.joy
                      : MascotExpression.normal,
                  portrait: _portrait,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
