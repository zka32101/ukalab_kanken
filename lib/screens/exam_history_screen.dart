import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/mock_exam.dart';
import '../providers/mock_exam_enhanced_provider.dart';
import 'package:kanken/widgets/text_fit.dart';

/// 模擬試験の受験履歴一覧画面
class ExamHistoryScreen extends ConsumerWidget {
  const ExamHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(examHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('試験履歴'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(examHistoryProvider);
          await ref.read(examHistoryProvider.future);
        },
        child: historyAsync.when(
          data: (results) {
            if (results.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ExamHistoryTile(result: results[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildEmptyState(
            context,
            message: '履歴の読み込みに失敗しました',
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? message}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message ?? 'まだ受験履歴がありません',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExamHistoryTile extends StatelessWidget {
  final ExamResult result;

  const _ExamHistoryTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.calculateScore();

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: result.isPassed ? Colors.green : Colors.redAccent,
          child: Icon(
            result.isPassed ? Icons.check : Icons.close,
            color: Colors.white,
          ),
        ),
        title: Text(
          '${result.examLevel}級 模擬試験',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatDate(result.completedAt)}\n'
          '正答率 ${(result.accuracyRate * 100).toStringAsFixed(0)}% '
          '(${result.correctAnswers}/${result.totalQuestions}問)',
        ),
        isThreeLine: true,
        trailing: FitWidth(
          maxFraction: 0.3,
          child: Text(
            '$score点',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: result.isPassed ? Colors.green : Colors.redAccent,
                ),
          ),
        ),
        onTap: () {
          context.push('/exam-result', extra: result);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
