import 'dart:typed_data';

import 'package:ukalab_core/ui.dart' show MascotStage, UkalabCert, UkalabOshiCard;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/oshi_provider.dart';
import '../screens/oshi_room_screen.dart';
import '../viewmodels/user_viewmodel.dart';
import 'oshi_medal_button.dart';

/// 画像（共有カード）をOSの共有シートで共有する。
Future<void> shareCardImage(Uint8List png) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(png, mimeType: 'image/png', name: 'ukalab_pass.png')],
      text: '#うかラボ #漢字検定',
    ),
  );
}

/// ホームの「推し」カード。共通キットの [UkalabOshiCard] に、漢字検定の成長段階・
/// 試験日・連続日数を渡す。推しの選択・着替え・合格報告・表示切替はキット側。
class OshiCard extends ConsumerWidget {
  const OshiCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = ref.watch(oshiStageProvider).valueOrNull ?? MascotStage.lv1;
    final user = ref.watch(currentUserProvider).valueOrNull;
    // 共通キットのカードのメニュー(推しを選ぶ／着替え・ショップ)には項目を足せない(v0.4.11)ため、
    // 推しの部屋への入口は、カードのすぐ下に置く。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UkalabOshiCard(
          cert: UkalabCert.kanjiKentei,
          stage: stage,
          appId: 'kanken',
          examDate: user?.examDate,
          streakDays: user?.streakCount ?? 0,
          onShare: shareCardImage,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const OshiMedalButton(),
              TextButton.icon(
                icon: const Icon(Icons.meeting_room_outlined),
                label: const Text('推しの部屋'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const OshiRoomScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
