import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukalab_core/ui.dart';
import 'package:ukalab_core/ukalab_core.dart';

import '../data/exam_prep_data.dart';
import '../models/kanji_question.dart' as k;
import '../screens/study_notes_screen.dart' show KanjiQuestionLoader;
import '../viewmodels/practice_viewmodel.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import 'home_screen.dart' show HomeScreen, PracticeScreen;

/// ukalab_core v0.58〜v0.61 の「推しの一言」「週間ふりかえり」「間違いノート」を
/// このアプリのデータにつなぐ部分。画面・文言は core 側。ここは入力の組み立て・保存・遷移だけ。
/// 子ども向けのため、外部共有・外部リンクは付けない（この3機能に共有は無い）。
/// premium 制限: core の PremiumFeature に3機能は無いため、すべて無料で表示する。

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 級IDの表示名（無ければID）。
String kankenLevelLabel(String id) => HomeScreen.levelNames[id] ?? id;

/// 推しの一言の入力を、端末内の解答履歴・連続日数・試験日から作る（個人情報は含めない）。
OshiMessageContext oshiMessageContextFrom({
  required List<ProgressRecord> history,
  required DateTime now,
  int streakDays = 0,
  DateTime? examDate,
  DateTime? lastStudyDate,
}) {
  final today = _dateOnly(now);
  DateTime? last = lastStudyDate == null ? null : _dateOnly(lastStudyDate);
  var todayAnswered = 0;
  var todayCorrect = 0;
  for (final r in history) {
    final d = _dateOnly(r.at);
    if (d.isAfter(today)) continue;
    if (last == null || d.isAfter(last)) last = d;
    if (d == today) {
      todayAnswered++;
      if (r.correct) todayCorrect++;
    }
  }
  final daysLeft = examDate == null
      ? null
      : _dateOnly(examDate).difference(today).inDays;
  return OshiMessageContext(
    daysSinceLastStudy: last == null ? null : today.difference(last).inDays,
    streakDays: streakDays,
    todayAnswered: todayAnswered,
    todayCorrectRate: todayAnswered == 0 ? null : todayCorrect / todayAnswered,
    examDaysLeft: daysLeft != null && daysLeft >= 1 ? daysLeft : null,
    hasWeakTopics:
        const MistakeNoteEngine().build(history).any((e) => !e.overcome),
  );
}

/// ホームの推しカード付近に出す「推しの一言」。タップで別の一言。
class OshiMessageEntry extends ConsumerWidget {
  const OshiMessageEntry({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final now = clock();
    return OshiMessageBubble(
      now: now,
      situation: oshiMessageContextFrom(
        history: ref.watch(historyProvider),
        now: now,
        streakDays: user?.streakCount ?? 0,
        examDate: ref.watch(examPrepExamDateProvider),
        lastStudyDate: user?.lastStudyDate,
      ),
    );
  }
}

/// ホームの週間ふりかえり（週1回分のまとめ。月曜始まり）。
/// メダル数は日付を持たないため渡さない（行は出ない）。
class WeeklyRecapEntry extends ConsumerWidget {
  const WeeklyRecapEntry({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recap = const WeeklyRecapEngine(weekStartsOn: DateTime.monday).build(
      weeklyRecapDaysFromRecords(ref.watch(historyProvider)),
      weekOf: clock(),
    );
    return WeeklyRecapCard(recap: recap, topicLabel: kankenLevelLabel);
  }
}

/// 間違いノートの保存先（端末内。バックアップ・リセットの対象は kankenDataParts）。
final MistakeNoteStore kankenMistakeNoteStore =
    SharedPreferencesMistakeNoteStore('kanken');

/// ノートの内容と、新しく克服した問題ID。
class MistakeNoteData {
  const MistakeNoteData(this.entries, this.celebrate);
  final List<MistakeNoteEntry> entries;
  final Set<String> celebrate;
}

/// 解答履歴をノートに取り込んで保存し、返す（同じ履歴を何度渡しても結果は同じ）。
final mistakeNotesProvider =
    FutureProvider.autoDispose<MistakeNoteData>((ref) async {
  const engine = MistakeNoteEngine();
  final history = ref.watch(historyProvider);
  final before = await kankenMistakeNoteStore.read();
  final after = engine.update(before, history);
  if (!listEquals(before, after)) {
    try {
      await kankenMistakeNoteStore.write(after);
    } catch (_) {}
  }
  return MistakeNoteData(after, engine.newlyOvercome(before, after).toSet());
});

typedef RetryPoolLoader = Future<List<k.KanjiQuestion>> Function(String level);

/// 間違いノート画面。問題文は既存の問題データ（Firestore）から取る。
/// 取得できない問題・級が分からない問題は載せない（安全に省略）。
class MistakeNoteScreen extends ConsumerStatefulWidget {
  const MistakeNoteScreen({
    super.key,
    this.loadQuestion,
    this.loadPool,
    this.practiceBuilder,
  });

  /// 問題IDから問題を読む。省略すると Firestore。テストで差し替える。
  final KanjiQuestionLoader? loadQuestion;

  /// 解き直しの選択肢の候補（同じ級の問題）を読む。省略すると Firestore。
  final RetryPoolLoader? loadPool;

  /// 解き直しで開く出題画面。省略すると既存の [PracticeScreen]。
  final WidgetBuilder? practiceBuilder;

  @override
  ConsumerState<MistakeNoteScreen> createState() => _MistakeNoteScreenState();
}

class _MistakeNoteScreenState extends ConsumerState<MistakeNoteScreen> {
  final Map<String, k.KanjiQuestion?> _questions = {};
  String _sig = '';
  Future<void>? _loading;

  KanjiQuestionLoader get _loader =>
      widget.loadQuestion ??
      (String id) => ref.read(firestoreServiceProvider).getKanjiQuestion(id);

  RetryPoolLoader get _poolLoader =>
      widget.loadPool ??
      (String level) =>
          ref.read(firestoreServiceProvider).getQuestionsByLevel(level, limit: 100);

  Future<void> _ensureLoaded(List<MistakeNoteEntry> entries) {
    final sig = entries.map((e) => e.qid).join(',');
    if (sig != _sig || _loading == null) {
      _sig = sig;
      _loading = _loadMissing(entries);
    }
    return _loading!;
  }

  Future<void> _loadMissing(List<MistakeNoteEntry> entries) async {
    await Future.wait([
      for (final e in entries)
        if (!_questions.containsKey(e.qid))
          () async {
            try {
              _questions[e.qid] = await _loader(e.qid);
            } catch (_) {
              _questions[e.qid] = null;
            }
          }(),
    ]);
  }

  bool _isShowable(MistakeNoteEntry e) =>
      _questions[e.qid] != null && HomeScreen.levels.contains(e.topicId);

  Future<void> _retry(MistakeNoteEntry entry) async {
    final target = _questions[entry.qid];
    final level = entry.topicId;
    if (target == null || level == null) return;
    final messenger = ScaffoldMessenger.of(context);
    List<PracticeQuestion> pq;
    try {
      pq = buildRetryPracticeQuestions(target, await _poolLoader(level), level);
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('問題を読み込めませんでした。あとでもう一度ためしてね')));
      return;
    }
    if (!mounted) return;
    final prevLevel = ref.read(currentLevelProvider);
    ref.read(practiceViewModelProvider.notifier).reset();
    ref.read(currentLevelProvider.notifier).state = level;
    ref.read(practiceRetryQuestionsProvider.notifier).state = pq;
    ref.invalidate(practiceQuestionsProvider(level));
    try {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: widget.practiceBuilder ?? (_) => const PracticeScreen()));
    } finally {
      ref.read(practiceRetryQuestionsProvider.notifier).state = null;
      ref.read(currentLevelProvider.notifier).state = prevLevel;
      ref.invalidate(practiceQuestionsProvider(level));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(mistakeNotesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(MistakeNoteStrings.ja.title)),
      body: _body(notes),
    );
  }

  Widget _body(AsyncValue<MistakeNoteData> notes) {
    final data = notes.valueOrNull;
    if (data == null) {
      return notes.hasError
          ? const Center(child: Text('読み込めませんでした'))
          : const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<void>(
          future: _ensureLoaded(data.entries),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final shown = data.entries.where(_isShowable).toList();
            return MistakeNoteView(
              entries: shown,
              celebrateQids: data.celebrate,
              topicLabel: kankenLevelLabel,
              questionBuilder: (context, e) {
                final q = _questions[e.qid]!;
                final reading = q.reading;
                return Text(
                  reading == null || reading.isEmpty
                      ? q.kanji
                      : '${q.kanji}（$reading）',
                  style: Theme.of(context).textTheme.titleLarge,
                );
              },
              onRetry: _retry,
            );
          },
    );
  }
}

/// 間違いノートを開く。
void openMistakeNote(BuildContext context) {
  Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MistakeNoteScreen()));
}
