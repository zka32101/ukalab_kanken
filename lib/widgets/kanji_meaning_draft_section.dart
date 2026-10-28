import 'package:flutter/material.dart';
import '../data/kanji_meaning_draft_data.dart';

/// 漢字の「意味(AI下書き・未確認)」を表示する。
/// [visible] が false(既定は [kKanjiMeaningVisible] = true)のとき、または
/// その字の下書きが無いときは何も描かない。
/// 意味は AI が書いた下書きで、公的データでも検定協会の公式でもない。
class KanjiMeaningDraftSection extends StatelessWidget {
  final String kanji;
  final bool visible;

  const KanjiMeaningDraftSection({
    super.key,
    required this.kanji,
    this.visible = kKanjiMeaningVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final entry = kanjiMeaningDraftEntry(kanji);
    if (entry == null) return const SizedBox.shrink();
    final needsReview = entry.reviewStatus == KanjiMeaningReviewStatus.needsReview;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            needsReview ? '意味（AI下書き・未確認・要確認）' : '意味（AI下書き・未確認）',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            entry.meaning,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
