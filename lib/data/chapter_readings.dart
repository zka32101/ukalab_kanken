import 'package:flutter/services.dart' show rootBundle;
import 'package:ukalab_core/ukalab_core.dart'
    show ChapterReading, parseChapterReadingsJsonl;

/// 章ごとの解説読み物（自作の文章）のデータ。
const String kChapterReadingsAsset = 'assets/readings/kanken.readings.jsonl';

/// 解説読み物をまとめる区分（JSONL の `subjectId` に対応する）。表示順もこの並び。
class ReadingGroup {
  const ReadingGroup(this.id, this.name);

  final String id;
  final String name;
}

const List<ReadingGroup> kReadingGroups = [
  ReadingGroup('kanji_basics', '漢字のしくみ'),
  ReadingGroup('reading_writing', '読みと書き'),
  ReadingGroup('jukugo_vocab', '熟語と語彙'),
  ReadingGroup('exam_tips', '答案のコツ'),
];

Future<List<ChapterReading>>? _chapterReadingsFuture;

/// 解説読み物を読み込む（一度読んだらキャッシュする。失敗したときは次回やり直す）。
Future<List<ChapterReading>> loadChapterReadings() {
  return _chapterReadingsFuture ??= _loadOnce();
}

Future<List<ChapterReading>> _loadOnce() async {
  try {
    return await _load();
  } catch (_) {
    _chapterReadingsFuture = null;
    rethrow;
  }
}

Future<List<ChapterReading>> _load() async {
  final text = await rootBundle.loadString(kChapterReadingsAsset);
  final parsed = parseChapterReadingsJsonl(text);
  if (parsed.issues.isNotEmpty) {
    throw StateError('解説読み物データの読み込みに失敗しました: ${parsed.issues}');
  }
  return parsed.items.where((r) => !r.disabled).toList();
}
