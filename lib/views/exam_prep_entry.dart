import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/exam_prep_data.dart';
import 'package:kanken/widgets/text_fit.dart';

/// ukalab_core の「試験に向けて」共通画面をこのアプリのデータにつなぐ部分。
/// 画面・文言は core 側。ここは取得・保存・premium 判定・遷移だけ。
/// 子ども向けのため、保存・共有など端末外へ出す操作は付けない。

/// 選択式の練習（core の [Question] 用）。解答は端末内の履歴にだけ記録する。
class ExamPrepPracticeView extends ConsumerStatefulWidget {
  const ExamPrepPracticeView(
      {super.key, required this.pool, required this.emptyMessage});

  final List<Question> pool;
  final String emptyMessage;

  @override
  ConsumerState<ExamPrepPracticeView> createState() =>
      _ExamPrepPracticeViewState();
}

class _ExamPrepPracticeViewState extends ConsumerState<ExamPrepPracticeView> {
  int _index = 0;
  int? _picked;
  int _correct = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.pool.isEmpty) {
      return Center(child: Text(widget.emptyMessage));
    }
    if (_index >= widget.pool.length) {
      return Center(
          child: Text('おつかれさま！ ${widget.pool.length}問中 $_correct問 せいかい',
              style: Theme.of(context).textTheme.titleMedium));
    }
    final q = widget.pool[_index];
    final answered = _picked != null;
    return ListView(
      children: [
        Text('${_index + 1} / ${widget.pool.length}'),
        const SizedBox(height: 8),
        Text(q.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (var i = 0; i < q.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: answered
                  ? null
                  : () {
                      final ok = i == q.answerIndex;
                      setState(() {
                        _picked = i;
                        if (ok) _correct++;
                      });
                      ref.read(historyProvider.notifier).record(
                          historyRecordFor(q, correct: ok));
                    },
              child: Text(q.choices[i]),
            ),
          ),
        if (answered) ...[
          Text(_picked == q.answerIndex ? 'せいかい！' : 'ざんねん。つぎはできるよ',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(q.explanation),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => setState(() {
              _index++;
              _picked = null;
            }),
            child: const Text('つぎへ'),
          ),
        ],
      ],
    );
  }
}

void _openPractice(
    BuildContext context, String title, List<Question> pool, String empty) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: FitTitle(title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ExamPrepPracticeView(pool: pool, emptyMessage: empty),
        ),
      ),
    ),
  );
}

/// ホームの「試験に向けて」カード。
class ExamPrepEntryCard extends ConsumerWidget {
  const ExamPrepEntryCard({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExamPrepCard(
      clock: clock,
      questions: () => ref.read(examPrepQuestionsProvider).valueOrNull ?? const [],
      records: () => ref.read(historyProvider),
      examDate: ref.watch(examPrepExamDateProvider),
      tenMinUnlocked: isPremiumFor(ref, PremiumFeature.tenMinutePlan),
      examEveUnlocked: isPremiumFor(ref, PremiumFeature.examEveMode),
      onStartPractice: _openPractice,
      onOpenChecklist: (c) async {
        final notifier = ref.read(checklistProvider.notifier);
        await notifier.ready;
        if (!c.mounted) return;
        final items = await loadChecklist();
        if (!c.mounted) return;
        await Navigator.of(c).push(MaterialPageRoute<void>(
          builder: (_) => ExamDayChecklistView(
            examId: kExamId,
            items: items,
            initialProgress: ref.read(checklistProvider),
            onChanged: notifier.setProgress,
          ),
        ));
      },
    );
  }
}

/// 設定タブの、更新ログ・履歴の書き出し（コピーのみ）の入口。
class ExamPrepSettingsEntry extends ConsumerWidget {
  const ExamPrepSettingsEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExamPrepSettingsTiles(
      exportUnlocked: isPremiumFor(ref, PremiumFeature.historyExport),
      onOpenUpdateLog: (c) => Navigator.of(c).push(MaterialPageRoute<void>(
          builder: (_) => UpdateLogView(entriesFuture: loadUpdateLog()))),
      onOpenExport: (c) => Navigator.of(c).push(MaterialPageRoute<void>(
          builder: (_) => HistoryExportView(
                records: ref.read(historyProvider),
                questions: ref.read(examPrepQuestionsProvider).valueOrNull ??
                    const [],
              ))),
    );
  }
}
