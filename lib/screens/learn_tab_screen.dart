import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart';
import '../router/app_router.dart';
import 'glossary_screen.dart' show kGlossaryMenuLabel;
import 'reading_list_screen.dart' show kReadingsMenuLabel;
import 'study_notes_screen.dart' show kStudyNotesMenuLabel;

/// 「学ぶ」タブ。学習系の画面への入口を並べる（各画面は Navigator.push で開く）。
/// ホームの作り直し（道具などの移設）は段階3。ここは既存画面への入口のみ。
class LearnTabScreen extends StatelessWidget {
  const LearnTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学ぶ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HomeMenuTile(
            icon: Icons.replay,
            title: '復習（間隔反復）',
            subtitle: '忘れる頃に出題して、定着させます。',
            onTap: () => context.goSpacedRepetitionReview(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.translate,
            title: '漢字の学習',
            subtitle: '書き順・読み方・用例を確認します。',
            onTap: () => context.goStrokeOrder(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.report_problem_outlined,
            title: '苦手漢字モード',
            subtitle: '間違えやすい漢字を集中して練習します。',
            onTap: () => context.goWeakKanji(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.auto_stories,
            title: kReadingsMenuLabel.replaceAll('\n', ''),
            onTap: () => context.goReadings(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.menu_book,
            title: kGlossaryMenuLabel,
            onTap: () => context.goGlossary(),
          ),
          const SizedBox(height: 8),
          HomeMenuTile(
            icon: Icons.bookmarks,
            title: kStudyNotesMenuLabel.replaceAll('\n', ''),
            onTap: () => context.goStudyNotes(),
          ),
        ],
      ),
    );
  }
}
