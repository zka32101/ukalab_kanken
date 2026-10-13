import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart' show handsFreeSpeakerProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/index.dart';

/// 演習（選択式）の、ながら学習モードの表示。問題文は上、大きな選択肢ボタンは下に寄せる。
/// 問題が変わるたびに、設定に従って問題文と選択肢を自動で読み上げる。
class HandsFreePracticeBody extends ConsumerStatefulWidget {
  const HandsFreePracticeBody({
    Key? key,
    required this.question,
    required this.index,
    required this.total,
    required this.onAnswer,
  }) : super(key: key);

  final PracticeQuestion question;

  /// 0 始まりの問題番号と、出題数。
  final int index;
  final int total;

  /// 選択肢をタップしたとき。正解なら true。
  final void Function(bool isCorrect) onAnswer;

  @override
  ConsumerState<HandsFreePracticeBody> createState() => _HandsFreePracticeBodyState();
}

class _HandsFreePracticeBodyState extends ConsumerState<HandsFreePracticeBody> {
  static const _labels = ['ア', 'イ', 'ウ', 'エ', 'オ', 'カ'];

  // dispose 中は ref を使えないため、停止用に保持しておく。
  late final HandsFreeSpeaker _speaker;

  @override
  void initState() {
    super.initState();
    _speaker = ref.read(handsFreeSpeakerProvider);
    _autoRead();
  }

  @override
  void didUpdateWidget(covariant HandsFreePracticeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _autoRead();
  }

  @override
  void dispose() {
    // 画面を離れたら読み上げを止める（読み上げ中の音が残らないように）。
    _speaker.stop();
    super.dispose();
  }

  String get _spokenPrompt => '${widget.question.instruction} ${widget.question.prompt}';

  void _autoRead() {
    ref.read(handsFreeSpeakerProvider).readQuestion(_spokenPrompt, widget.question.choices);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final speaker = ref.read(handsFreeSpeakerProvider);

    return HandsFreeQuestionLayout(
      question: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '問題 ${widget.index + 1} / ${widget.total}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Text(q.instruction, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            q.prompt,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      trailing: ReadAloudButton(
        onPressed: () => speaker.speakNow(questionReadAloudText(_spokenPrompt, q.choices)),
      ),
      choices: [
        for (var i = 0; i < q.choices.length; i++)
          HandsFreeChoiceTile(
            label: i < _labels.length ? _labels[i] : '${i + 1}',
            text: q.choices[i],
            state: ChoiceState.idle,
            onTap: () => widget.onAnswer(q.choices[i] == q.correctAnswer),
          ),
      ],
    );
  }
}
