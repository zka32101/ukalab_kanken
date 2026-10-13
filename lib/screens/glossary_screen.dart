import 'package:flutter/material.dart';
import 'package:ukalab_core/glossary.dart';
import 'package:ukalab_core/ukalab_core.dart' show ChapterReading;

import '../data/chapter_readings.dart';
import '../data/kanken_glossary.dart';

/// ホームの「学習」メニューに出す、用語集への入口の名前。
const String kGlossaryMenuLabel = '用語集';

/// 「覚えた」の保存先（端末内）。キーは `ukalab_kanken_learned_term_ids`。
final LearnedTermsStore kankenLearnedTermsStore = LearnedTermsStore('kanken');

/// 用語集の画面。部首・熟語と用例・読み物の用語を、検索・分野の絞り込み・
/// 「覚えた」チェックつきで一覧にする（一覧と保存は ukalab_core の部品）。
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key, this.loadReadings = loadChapterReadings});

  /// 読み物の読み込み方。テストで差し替えられる。
  final Future<List<ChapterReading>> Function() loadReadings;

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  late final Future<List<ChapterReading>> _future = widget.loadReadings();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(kGlossaryMenuLabel)),
      body: FutureBuilder<List<ChapterReading>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // 読み物が読めなくても、部首と熟語・用例は使える。
          final terms = buildKankenGlossary(snapshot.data ?? const []);
          return GlossaryListView(
            terms: terms,
            store: kankenLearnedTermsStore,
            subjects: kGlossarySubjects,
            sortByTerm: false,
          );
        },
      ),
    );
  }
}
