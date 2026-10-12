import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart'
    show bookmarkProvider, questionMemoProvider;

import '../models/kanji_question.dart';
import '../viewmodels/services_provider.dart';

/// ホームの「学習」メニューに出す、ブックマークとメモへの入口の名前。
const String kStudyNotesMenuLabel = 'ブックマーク\n・メモ';

/// 問題IDから問題を読み込む関数。見つからなければ null。
typedef KanjiQuestionLoader = Future<KanjiQuestion?> Function(String id);

/// 問題のメモを編集するダイアログを開く。保存すると端末内に残る（空にすると削除）。
Future<void> showQuestionMemoDialog(
  BuildContext context,
  WidgetRef ref, {
  required String qid,
  String? title,
}) async {
  final controller =
      TextEditingController(text: ref.read(questionMemoProvider)[qid] ?? '');
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title == null ? '自分用メモ' : '「$title」のメモ'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        minLines: 2,
        decoration: const InputDecoration(
          hintText: '間違えた理由や覚え方を書き残せます',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  final text = controller.text;
  controller.dispose();
  if (saved == true) {
    await ref.read(questionMemoProvider.notifier).setMemo(qid: qid, memo: text);
  }
}

/// ブックマークした問題と、書き残したメモの一覧。
class StudyNotesScreen extends ConsumerWidget {
  const StudyNotesScreen({super.key, this.loadQuestion});

  /// 問題の読み込み方。省略すると Firestore から読む。テストで差し替えられる。
  final KanjiQuestionLoader? loadQuestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loader = loadQuestion ??
        (String id) => ref.read(firestoreServiceProvider).getKanjiQuestion(id);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ブックマーク・メモ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ブックマーク'),
              Tab(text: 'メモ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _NoteList(loader: loader, bookmarks: true),
            _NoteList(loader: loader, bookmarks: false),
          ],
        ),
      ),
    );
  }
}

class _NoteList extends ConsumerWidget {
  const _NoteList({required this.loader, required this.bookmarks});

  final KanjiQuestionLoader loader;
  final bool bookmarks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memos = ref.watch(questionMemoProvider);
    final ids = bookmarks
        ? (ref.watch(bookmarkProvider).toList()..sort())
        : (memos.keys.toList()..sort());
    if (ids.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            bookmarks
                ? 'ブックマークはまだありません。\n演習中のしおりボタンで追加できます。'
                : 'メモはまだありません。\n演習中のメモボタンで書き残せます。',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: ids.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _NoteTile(
        key: ValueKey(ids[i]),
        qid: ids[i],
        loader: loader,
        memo: memos[ids[i]],
        bookmarks: bookmarks,
      ),
    );
  }
}

class _NoteTile extends ConsumerStatefulWidget {
  const _NoteTile({
    super.key,
    required this.qid,
    required this.loader,
    required this.memo,
    required this.bookmarks,
  });

  final String qid;
  final KanjiQuestionLoader loader;
  final String? memo;
  final bool bookmarks;

  @override
  ConsumerState<_NoteTile> createState() => _NoteTileState();
}

class _NoteTileState extends ConsumerState<_NoteTile> {
  late final Future<KanjiQuestion?> _future =
      widget.loader(widget.qid).catchError((Object _) => null);

  @override
  Widget build(BuildContext context) {
    final qid = widget.qid;
    final memo = widget.memo;
    final bookmarks = widget.bookmarks;
    return FutureBuilder<KanjiQuestion?>(
      future: _future,
      builder: (context, snapshot) {
        final q = snapshot.data;
        final title = q == null ? '問題 $qid' : q.kanji;
        final reading = q?.reading ?? '';
        final memoText = memo ?? '';
        final detail = <String>[
          if (reading.isNotEmpty) reading,
          if (memoText.isNotEmpty) memoText,
        ].join('\n');
        return ListTile(
          title: Text(title),
          subtitle: detail.isEmpty ? null : Text(detail),
          isThreeLine: detail.contains('\n'),
          onTap: () => showQuestionMemoDialog(
            context,
            ref,
            qid: qid,
            title: q?.kanji,
          ),
          trailing: bookmarks
              ? IconButton(
                  icon: const Icon(Icons.bookmark),
                  tooltip: 'ブックマークを外す',
                  onPressed: () =>
                      ref.read(bookmarkProvider.notifier).toggle(qid),
                )
              : IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'メモを削除',
                  onPressed: () => ref
                      .read(questionMemoProvider.notifier)
                      .setMemo(qid: qid, memo: ''),
                ),
        );
      },
    );
  }
}
