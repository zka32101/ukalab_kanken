import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';

import '../data/level_kanji_data.dart';
import '../router/app_router.dart';
import '../screens/nagara_session_screen.dart' show NagaraMenuCard;
import '../viewmodels/user_viewmodel.dart' show currentLevelProvider;
import '../views/core_features_entry.dart' show openMistakeNote;
import '../views/home_screen.dart' show HomeScreen;
import '../widgets/text_fit.dart';

/// 級を選んだあとの画面。この級でやること（漢字学習・演習・模擬試験・苦手と復習）を並べる。
///
/// 開いたときに、この級を [currentLevelProvider] に入れる。漢字学習・演習・模擬試験・
/// ながら学習などの既存の画面は、どれもこの級を見て動く。
class LevelHubScreen extends ConsumerStatefulWidget {
  const LevelHubScreen({Key? key, required this.level}) : super(key: key);

  final String level;

  /// 「10級（小1）」のカッコの前だけ。
  static String shortName(String level) =>
      HomeScreen.levelNames[level]?.split('（').first ?? level;

  @override
  ConsumerState<LevelHubScreen> createState() => _LevelHubScreenState();
}

class _LevelHubScreenState extends ConsumerState<LevelHubScreen> {
  @override
  void initState() {
    super.initState();
    // build の最中にプロバイダーを書き換えないよう、最初のフレームのあとに入れる。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(currentLevelProvider.notifier).state = widget.level;
    });
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    final kanjiCount = LevelKanjiData.forLevel(level).length;
    return Scaffold(
      appBar: AppBar(title: FitTitle(HomeScreen.levelNames[level] ?? level)),
      // 項目が少ないので、全部を作っておく（大きい文字でも、画面外の項目が消えない）。
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${LevelHubScreen.shortName(level)}の配当漢字は$kanjiCount字です。',
                key: const ValueKey('levelHubKanjiCount'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            HomeMenuTile(
              icon: Icons.edit_note,
              title: '漢字学習',
              subtitle: '書き順・読み方・用例を確認します。',
              onTap: () => context.goStrokeOrder(),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.play_circle_fill,
              title: '演習',
              subtitle: '出題形式を選んで、問題に答えます。',
              onTap: () => HomeScreen.startPractice(context, ref),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.assignment,
              title: '模擬試験',
              subtitle: '本番に近い形式で解きます。',
              onTap: () => context.goMockExamModes(),
            ),
            const SizedBox(height: 16),
            Text('苦手・復習', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.report_problem_outlined,
              title: '苦手漢字モード',
              subtitle: '間違えやすい漢字を集中して練習します。',
              onTap: () => context.goWeakKanji(),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.repeat,
              title: '復習（間隔反復）',
              subtitle: '忘れる頃に出題して、定着させます。',
              onTap: () => context.goSpacedRepetitionReview(),
            ),
            const SizedBox(height: 8),
            HomeMenuTile(
              icon: Icons.fact_check,
              title: '間違いノート',
              subtitle: '間違えた問題を見返して、解き直せます。',
              onTap: () => openMistakeNote(context),
            ),
            const SizedBox(height: 8),
            const NagaraMenuCard(),
          ],
        ),
      ),
    );
  }
}
