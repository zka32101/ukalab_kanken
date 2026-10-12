import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/kanji_question.dart';
import 'package:kanken/screens/study_notes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart'
    show bookmarkProvider, questionMemoProvider, studyNotesOverrides;

KanjiQuestion _q(String id, String kanji, {String? reading}) => KanjiQuestion(
      id: id,
      level: 'LEVEL_10',
      kanji: kanji,
      questionType: QuestionType.multipleChoice,
      choices: const ['a', 'b'],
      correctAnswer: 'a',
      version: 1,
      reading: reading,
    );

Future<ProviderContainer> _container() async {
  final overrides = await studyNotesOverrides('kanken');
  return ProviderContainer(overrides: overrides);
}

Future<void> _pump(WidgetTester tester, ProviderContainer c) async {
  final questions = {'q1': _q('q1', '山', reading: 'やま'), 'q2': _q('q2', '川')};
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      home: StudyNotesScreen(loadQuestion: (id) async => questions[id]),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('何も無いときは案内を出す', (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await _pump(tester, c);
    expect(find.textContaining('ブックマークはまだありません'), findsOneWidget);
    await tester.tap(find.text('メモ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('メモはまだありません'), findsOneWidget);
  });

  testWidgets('ブックマークした問題が並び、外すと消える', (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await c.read(bookmarkProvider.notifier).toggle('q1');
    await _pump(tester, c);
    expect(find.text('山'), findsOneWidget);
    expect(find.textContaining('やま'), findsOneWidget);

    await tester.tap(find.byTooltip('ブックマークを外す'));
    await tester.pumpAndSettle();
    expect(c.read(bookmarkProvider), isEmpty);
    expect(find.text('山'), findsNothing);
  });

  testWidgets('メモを保存でき、端末内に残り、空にすると消える', (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await c.read(bookmarkProvider.notifier).toggle('q2');
    await _pump(tester, c);

    await tester.tap(find.text('川'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'かわ と読む');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(c.read(questionMemoProvider)['q2'], 'かわ と読む');

    // 再起動相当: 保存先から読み直しても残っている
    final c2 = await _container();
    addTearDown(c2.dispose);
    expect(c2.read(questionMemoProvider)['q2'], 'かわ と読む');
    expect(c2.read(bookmarkProvider), {'q2'});

    await tester.tap(find.text('メモ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('かわ と読む'), findsWidgets);
    await tester.tap(find.byTooltip('メモを削除'));
    await tester.pumpAndSettle();
    expect(c.read(questionMemoProvider), isEmpty);
  });

  testWidgets('問題が見つからなくてもIDで表示する', (tester) async {
    final c = await _container();
    addTearDown(c.dispose);
    await c.read(bookmarkProvider.notifier).toggle('zzz');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: StudyNotesScreen(loadQuestion: (id) async => null),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('問題 zzz'), findsOneWidget);
  });
}
