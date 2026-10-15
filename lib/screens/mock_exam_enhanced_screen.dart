import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_label.dart';
import '../models/mock_exam_modes.dart';
import '../providers/exam_session_provider.dart';
import 'mock_exam_result_screen.dart';
import 'package:kanken/utils/option_shuffle.dart';
import 'package:kanken/widgets/text_fit.dart';

class MockExamEnhancedScreen extends ConsumerStatefulWidget {
  final ExamConfig config;

  const MockExamEnhancedScreen({
    required this.config,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MockExamEnhancedScreen> createState() =>
      _MockExamEnhancedScreenState();
}

class _MockExamEnhancedScreenState extends ConsumerState<MockExamEnhancedScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();

    // 試験を開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startExam();
    });

    // タイマーを初期化（最大時間制限）
    final maxDuration = Duration(minutes: widget.config.timeLimit);
    _timerController = AnimationController(
      duration: maxDuration,
      vsync: this,
    )..forward();

    _timerController.addListener(() {
      setState(() {
        _elapsedSeconds = (_timerController.value * maxDuration.inSeconds).toInt();
      });
      ref
          .read(examSessionProvider.notifier)
          .updateElapsedTime(_elapsedSeconds);

      // 時間切れチェック
      if (_elapsedSeconds >= maxDuration.inSeconds) {
        _handleTimeUp();
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _startExam() async {
    try {
      await ref.read(examSessionProvider.notifier).startExam(widget.config);
    } catch (e) {
      if (mounted) {
        final message = e is NoExamQuestionsException
            ? 'この級の問題はまだ準備中です。別の級や別のモードを試してみてください。'
            : '試験を開始できませんでした。通信状態を確認して、もう一度お試しください。';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.pop(context);
      }
    }
  }

  void _handleTimeUp() {
    if (mounted) {
      _showResults();
    }
  }

  void _showResults() {
    final session = ref.read(examSessionProvider);
    if (session == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MockExamResultScreen(
          session: session,
          elapsedSeconds: _elapsedSeconds,
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(examSessionProvider);
    final modeName = ref.watch(currentExamModeNameProvider);

    if (sessionAsync == null) {
      return Scaffold(
        appBar: AppBar(title: const FitTitle('試験読み込み中')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final session = sessionAsync;
    final currentQuestion = session.getCurrentQuestion();
    final remainingTime = session.getRemainingTime();
    final isTimeWarning = remainingTime < 300; // 5分以下で警告

    return WillPopScope(
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('試験を中断しますか？'),
            content: const Text('進捗が失われます'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('続ける'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('中断'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          ref.read(examSessionProvider.notifier).reset();
        }
        return confirmed ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: FitTitle(modeName),
          centerTitle: true,
          elevation: 0,
          actions: [
            Padding(
              // 縦に余白を取ると、AppBarの高さ(56)を超えて「BOTTOM OVERFLOWED」になる。
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // 文字が大きいときは、AppBar の高さ（56）と幅に収まるまで縮める。
              child: Center(
                child: CapWidth(
                  maxFraction: 0.3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '残り時間',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          _formatTime(remainingTime),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isTimeWarning ? Colors.red : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: currentQuestion == null
            ? const Center(child: Text('試験が終了しました'))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 進捗バー
                      LinearProgressIndicator(
                        value: session.getProgressPercentage(),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          Text(
                            '問題 ${session.currentQuestionIndex + 1} / ${session.questions.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '正解: ${session.getCorrectAnswerCount()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 問題表示
                      // writing（読み方から漢字を選ぶ）・usage（文中の空欄に入る
                      // 漢字を選ぶ）ではkanjiフィールド自体が正解のため、表示すると
                      // 答えが漏洩してしまう。これらの形式では種別ラベルのみ表示し、
                      // 実際の問い（読み方・文章）は下の問題文で示す。
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '【${questionTypeLabel(currentQuestion.questionType)}】',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            if (currentQuestion.questionType != 'writing' &&
                                currentQuestion.questionType != 'usage') ...[
                              const SizedBox(height: 16),
                              Text(
                                currentQuestion.kanji,
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 問題文
                      Text(
                        currentQuestion.question,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),

                      // 選択肢
                      // 正解が常にAにならないよう、問題IDから決めた安定した順序で並べる。
                      // 回答・採点は選択肢の文字列で行うので、順序が変わっても壊れない。
                      ...shuffledOptions(
                        currentQuestion.questionId,
                        currentQuestion.options,
                      ).map((option) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                ref
                                    .read(examSessionProvider.notifier)
                                    .recordAnswer(
                                      session.currentQuestionIndex,
                                      option,
                                    );

                                // 次の問題へ
                                ref
                                    .read(examSessionProvider.notifier)
                                    .moveToNextQuestion();

                                // 最後の問題の場合は結果表示
                                if (session.currentQuestionIndex >=
                                    session.questions.length - 1) {
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    _showResults,
                                  );
                                }
                              },
                              child: Text(option),
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 24),

                      // ナビゲーションボタン
                      if (session.currentQuestionIndex > 0)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(examSessionProvider.notifier)
                                  .moveToPreviousQuestion();
                            },
                            child: const Text('前へ'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// 出題形式の内部名を、画面に出す日本語名にする。
String questionTypeLabel(String type) {
  return categoryLabel(type);
}
