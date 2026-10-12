import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart'
    show ChapterReadingWidget, ReadingSectionView;
import 'package:ukalab_core/ukalab_core.dart' show ChapterReading;

import '../data/chapter_readings.dart';

/// ホームの「学習」メニューに出す、解説読み物への入口の名前。
const String kReadingsMenuLabel = '章ごとの\n解説読み物';

/// 章ごとの解説読み物（教科書のようなまとめページ）の一覧。
///
/// 区分（漢字のしくみ・読みと書き・熟語と語彙・答案のコツ）ごとに並べ、
/// タップで [ReadingDetailScreen] を開く。
class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key, this.loadReadings = loadChapterReadings});

  /// 読み物の読み込み方。テストで差し替えられる。
  final Future<List<ChapterReading>> Function() loadReadings;

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen> {
  late final Future<List<ChapterReading>> _future = widget.loadReadings();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('章ごとの解説読み物')),
      body: FutureBuilder<List<ChapterReading>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('読み込みに失敗しました。'));
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final readings = snapshot.data ?? const <ChapterReading>[];
          if (readings.isEmpty) {
            return const Center(child: Text('解説読み物のデータがまだありません。'));
          }
          final children = <Widget>[];
          for (final group in kReadingGroups) {
            final items =
                readings.where((r) => r.subjectId == group.id).toList();
            if (items.isEmpty) continue;
            children.add(Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(group.name, style: theme.textTheme.titleMedium),
            ));
            for (final r in items) {
              children.add(Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text(r.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReadingDetailScreen(reading: r),
                    ),
                  ),
                ),
              ));
            }
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          );
        },
      ),
    );
  }
}

/// 解説読み物1本の詳細。節（見出しと本文）を順に表示する。
class ReadingDetailScreen extends StatelessWidget {
  const ReadingDetailScreen({super.key, required this.reading});

  final ChapterReading reading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(reading.title)),
      body: ChapterReadingWidget(
        title: reading.title,
        sections: [
          for (final s in reading.sections)
            ReadingSectionView(heading: s.heading, body: s.body),
        ],
      ),
    );
  }
}
