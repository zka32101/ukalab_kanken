import 'package:flutter/material.dart';

import '../services/content_counts.dart';
import '../views/core_features_entry.dart' show kankenLevelLabel;

/// 設定から開く「収録問題数」の一覧。級ごとに、配当漢字の数と、演習で出せる問題の数(分野ごと)を出す。
class ContentCountsScreen extends StatelessWidget {
  const ContentCountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = buildContentCounts();
    return Scaffold(
      appBar: AppBar(title: const Text('収録問題数')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '各級の演習で出せる問題の数です。上の級では、やさしい級の問題も出ます。'
            '漢字1字の読み・書き取り・筆順・画数は、配当漢字から作るので、この数には入っていません。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          for (final row in rows) _LevelCard(row: row),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.row});

  final ContentCountRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('contentCounts_${row.level}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kankenLevelLabel(row.level), style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('配当漢字 ${row.kanjiCount}字 ／ 形式別の問題 計${row.total}問',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            if (row.counts.isEmpty)
              const Text('この級は、漢字の読み・書きが中心です。')
            else
              for (final e in row.counts.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key)),
                      Text('${e.value}問', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
