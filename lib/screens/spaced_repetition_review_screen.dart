import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../models/spaced_repetition_item.dart';
import '../providers/learning_goal_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../viewmodels/services_provider.dart';
import '../viewmodels/user_viewmodel.dart';
import 'package:kanken/widgets/text_fit.dart';

class SpacedRepetitionReviewScreen extends ConsumerStatefulWidget {
  const SpacedRepetitionReviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SpacedRepetitionReviewScreen> createState() =>
      _SpacedRepetitionReviewScreenState();
}

class _SpacedRepetitionReviewScreenState
    extends ConsumerState<SpacedRepetitionReviewScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctCount = 0;
  List<SpacedRepetitionItem> _reviewItems = [];
  bool _isLoading = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadReviewSession();
  }

  Future<void> _loadReviewSession() async {
    final dueItems = await ref.read(dueReviewItemsProvider.future);

    setState(() {
      _reviewItems = dueItems;
      _isLoading = false;
      _isFinished = dueItems.isEmpty;
    });
  }

  SpacedRepetitionItem? get _currentItem {
    if (_currentIndex >= _reviewItems.length) return null;
    return _reviewItems[_currentIndex];
  }

  Future<void> _submitQuality(int quality) async {
    final isCorrect = quality >= 3;
    if (isCorrect) _correctCount++;

    final item = _reviewItems[_currentIndex];

    await recordReviewResult(
      ref,
      item: item,
      quality: quality,
    );

    // 演習と同様に答ログを残し、日次問題数の目標更新・苦手漢字分析の
    // 対象にも含める（完了を待たずバックグラウンドで実行）。
    final uid = ref.read(currentUserIdProvider);
    if (uid != null) {
      final user = await ref.read(currentUserProvider.future);
      final profileId = user?.profileId ?? 'default';

      ref.read(firestoreServiceProvider).addAnswerLog(UserAnswerLog(
            id: '',
            uid: uid,
            profileId: profileId,
            questionId: item.questionId,
            isCorrect: isCorrect,
            mode: AnswerMode.review,
            answeredAt: DateTime.now(),
          ));

      incrementDailyQuestionGoal(ref).catchError((_) {});

      if (!isCorrect) {
        ref
            .read(aiWeakAnalysisServiceProvider)
            .analyzeWeakKanjis(uid, profileId: profileId)
            .catchError((_) {});
      }
    }

    if (_currentIndex + 1 >= _reviewItems.length) {
      setState(() => _isFinished = true);
      ref.invalidate(dueReviewItemsProvider);
      ref.invalidate(allSpacedRepetitionItemsProvider);
      ref.invalidate(reviewSessionStatsProvider);
    } else {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('間隔反復復習'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isFinished
                ? _buildFinishedView(context)
                : _buildReviewView(context),
      ),
    );
  }

  Widget _buildFinishedView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: MinHeightScroll(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              _reviewItems.isEmpty ? '今日の復習はありません！' : '復習完了！',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_reviewItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '正解: $_correctCount / ${_reviewItems.length}問',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewView(BuildContext context) {
    final item = _currentItem;
    if (item == null) {
      return const Center(child: Text('問題データを読み込めませんでした'));
    }

    final progress = (_currentIndex + 1) / _reviewItems.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      // 文字が大きく、評価ボタンが何段にもなるときは、全体を縦にスクロールできるようにする。
      child: MinHeightScroll(
        intrinsicHeight: true,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 進捗バー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentIndex + 1} / ${_reviewItems.length}問  (習熟: ${item.masteryLevel})',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 32),

          // 問題カード
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.kanji,
                            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (item.question.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            item.question,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_showAnswer)
                          Text(
                            item.correctAnswer,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          OutlinedButton(
                            onPressed: () => setState(() => _showAnswer = true),
                            child: const Text('答えを表示'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 評価ボタン（回答表示後のみ）
          if (_showAnswer) _buildQualityButtons(),
        ],
        ),
      ),
    );
  }

  Widget _buildQualityButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'どのくらい覚えていましたか？',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQualityButton(0, '忘れた', Colors.red),
              _buildQualityButton(3, '難しい', Colors.orange),
              _buildQualityButton(4, '普通', Colors.blue),
              _buildQualityButton(5, '簡単', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityButton(int quality, String label, Color color) {
    return ElevatedButton(
      onPressed: () => _submitQuality(quality),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
