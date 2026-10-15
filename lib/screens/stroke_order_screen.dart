import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/kanji_info_data.dart';
import '../data/kanji_radical_data.dart';
import '../data/level_kanji_data.dart';
import '../data/stroke_order_sample_data.dart';
import '../providers/writing_mastery_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../views/handwriting_practice_screen.dart';
import '../widgets/kanji_meaning_draft_section.dart';
import '../widgets/stroke_order_animation.dart';
import '../theme/app_theme.dart';
import 'package:kanken/widgets/text_fit.dart';

/// 選択中の級の配当漢字（公式級別漢字表準拠、`LevelKanjiData`）のうち、
/// 書き順データがあるものに絞る。
/// 以前はFirestoreの`questions`コレクションを`limit: 200`で取得していたが、
/// 級によっては配当漢字の一部しか返らず表示数が不足していたため、
/// 公式配当漢字表のローカルデータを直接使う方式に変更した。
final _levelStrokeOrderKanjiProvider =
    FutureProvider.family<List<String>, String>((ref, level) async {
  return strokeOrderKanjiForLevel(level);
});

/// 級の配当漢字のうち書き順データがあるものだけを返す（配当表の並び順）。
/// 書き順データが1字も無い級（現状は4級・3級）は、他の級の漢字で埋めずに空を返す。
/// 以前は空のとき全漢字（小学校分）にフォールバックしていたため、
/// 4級・3級を選んでも下の級の漢字が混ざって表示されていた。
List<String> strokeOrderKanjiForLevel(String level) {
  final available = StrokeOrderSampleData.availableKanji.toSet();
  return LevelKanjiData.forLevel(level).where(available.contains).toList();
}

/// 漢字の学習画面（漢字一覧 → タップで書き順アニメーション・読み方・用例を表示）
/// 一覧は現在選択中の級（currentLevelProvider）に出題される漢字のみに絞る。
class StrokeOrderScreen extends ConsumerStatefulWidget {
  const StrokeOrderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StrokeOrderScreen> createState() => _StrokeOrderScreenState();
}

class _StrokeOrderScreenState extends ConsumerState<StrokeOrderScreen> {
  String? _selectedKanji;
  String? _selectedForLevel;

  @override
  Widget build(BuildContext context) {
    final level = ref.watch(currentLevelProvider);
    final kanjiListAsync = ref.watch(_levelStrokeOrderKanjiProvider(level));
    final masteredAsync = ref.watch(masteredWritingKanjisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('漢字の学習'),
        centerTitle: true,
      ),
      body: kanjiListAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
        data: (kanjiList) {
          if (kanjiList.isEmpty) {
            return const Center(child: Text('この級の書き順データは準備中です'));
          }
          // 級が変わったら選択をリセットする（別の級の漢字が選ばれたままにならないように）。
          if (_selectedForLevel != level) {
            _selectedForLevel = level;
            _selectedKanji = null;
          }
          final selected =
              (_selectedKanji != null && kanjiList.contains(_selectedKanji))
                  ? _selectedKanji!
                  : kanjiList.first;
          final mastered = masteredAsync.valueOrNull ?? const <String>{};
          return _buildContent(context, level, kanjiList, selected, mastered);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String level,
    List<String> kanjiList,
    String selected,
    Set<String> mastered,
  ) {
    final data = StrokeOrderSampleData.getStrokeOrder(selected)!;
    final info = KanjiInfoData.get(selected);
    final radicalInfo = KanjiRadicalData.get(selected);

    // 詳細エリア（書き順・読み方・部首・用例）は画面上部に固定し、
    // 漢字をタップするたびにスクロールして見に行かなくて済むようにする。
    // 用例の数などで高さが変動しても、下の漢字選択グリッドの表示領域が
    // つぶれないよう、詳細エリアは画面の45%までに収め、はみ出す分は
    // その中だけでスクロールできるようにする。
    // 文字が大きいとき、下の「かんじをえらぼう」の見出しとグリッドの分を必ず残す。
    final scale = textScaleOf(context);
    final headerHeight = scale > 1.2 ? 28.0 * scale * 3 + 16 : 48.0;
    return LayoutBuilder(builder: (context, constraints) {
    final maxDetailHeight = math.min(
      MediaQuery.of(context).size.height * 0.45,
      math.max(120.0, constraints.maxHeight - headerHeight - 160),
    );

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDetailHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: StrokeOrderAnimationWidget(
                  key: ValueKey(selected),
                  data: data,
                  size: 160,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HandwritingPracticeScreen(
                          level: level,
                          kanji: selected,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('書く練習'),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: info == null
                    ? const SizedBox.shrink(key: ValueKey('no-info'))
                    : Container(
                        key: ValueKey('info-$selected'),
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '読み方',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: info.readings.map((reading) {
                                return Chip(
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(reading),
                                  ),
                                  backgroundColor: Colors.white,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                            if (radicalInfo != null) ...[
                              const SizedBox(height: 10),
                              const Text(
                                '部首',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('${radicalInfo.radical}（${radicalInfo.radicalName}）'),
                                ),
                                backgroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                            // 意味(AI下書き)。kKanjiMeaningVisible が false の間は何も出ない。
                            KanjiMeaningDraftSection(kanji: selected),
                            const SizedBox(height: 10),
                            const Text(
                              '使い方の例',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            ...info.examples.map(
                              (example) => Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '・$example',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              Text(
                'かんじをえらぼう',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${kanjiList.where(mastered.contains).length} / ${kanjiList.length} 覚えた',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: kanjiList.length,
            itemBuilder: (context, index) {
              final kanji = kanjiList[index];
              final isSelected = kanji == selected;
              final isMastered = mastered.contains(kanji);
              final bgColor = isSelected
                  ? AppColors.primary
                  : isMastered
                      ? Colors.green.shade50
                      : Colors.white;
              final borderColor = isSelected
                  ? AppColors.primary
                  : isMastered
                      ? Colors.green
                      : Colors.grey.shade300;
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedKanji = kanji),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              kanji,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isMastered && !isSelected)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
    });
  }
}
