import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanken/data/kanken_data_parts.dart';
import 'package:kanken/data/kanken_glossary.dart';
import 'package:kanken/router/app_router.dart';
import 'package:kanken/screens/glossary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/glossary.dart';
import 'package:ukalab_core/ukalab_core.dart';

List<ChapterReading> _readings() => parseChapterReadingsJsonl(
      File('assets/readings/kanken.readings.jsonl').readAsStringSync(),
    ).items;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('用語の生成', () {
    test('3区分とも1件以上ある', () {
      expect(buildRadicalTerms(), isNotEmpty);
      expect(buildCompoundTerms(), isNotEmpty);
      expect(buildReadingTerms(_readings()), isNotEmpty);
    });

    test('termId が一意で、接頭辞と分野が合い、説明が空でない', () {
      final all = buildKankenGlossary(_readings());
      expect(all.map((t) => t.termId).toSet().length, all.length);
      for (final t in all) {
        expect(t.term.trim(), isNotEmpty, reason: t.termId);
        expect(t.headline.trim(), isNotEmpty, reason: t.termId);
        expect(t.definition.trim(), isNotEmpty, reason: t.termId);
        expect(t.termId.startsWith('${t.subjectId}:'), isTrue,
            reason: t.termId);
        expect(kGlossarySubjects.containsKey(t.subjectId), isTrue);
      }
    });

    test('部首の例の漢字は上限を超えない', () {
      for (final t in buildRadicalTerms()) {
        final line = t.definition.split('\n').last;
        final body = line.split(': ').last.split('　').first;
        expect(body.split('・').length, lessThanOrEqualTo(kRadicalExampleLimit),
            reason: t.termId);
      }
    });

    test('熟語の構成問題の熟語が含まれ、成り立ちが説明にある', () {
      final t = buildCompoundTerms().firstWhere((t) => t.termId == 'compound:岩石');
      expect(t.definition, contains('似た意味の漢字を重ねたもの'));
    });

    test('読み物は節の見出しだけを用語にする', () {
      final r = _readings();
      final terms = buildReadingTerms(r);
      expect(terms.length, r.fold<int>(0, (n, e) => n + e.sections.length));
    });
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: GlossaryScreen(loadReadings: () async => _readings()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('チェックの付け外しと、未習得フィルタ（既定はすべて）', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);

    final first = buildRadicalTerms().first;
    expect(find.text(first.term), findsOneWidget);
    expect(tester.widgetList<Checkbox>(find.byType(Checkbox)).first.value,
        isFalse);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(tester.widgetList<Checkbox>(find.byType(Checkbox)).first.value,
        isTrue);
    expect(
      await LearnedTermsStore('kanken').load(),
      {first.termId},
    );

    // 未習得: チェック済みを除く
    await tester.tap(find.text('未習得'));
    await tester.pumpAndSettle();
    expect(find.text(first.term), findsNothing);

    // 覚えた: チェック済みだけ
    await tester.tap(find.text('覚えた'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsOneWidget);

    // 外す
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(await LearnedTermsStore('kanken').load(), isEmpty);
  });

  test('保存キーは ukalab_kanken_learned_term_ids', () async {
    SharedPreferences.setMockInitialValues({});
    await LearnedTermsStore('kanken').setLearned('radical:木', true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('ukalab_kanken_learned_term_ids'), ['radical:木']);
  });

  testWidgets('バックアップ・リセットに「覚えた」が含まれる', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    late WidgetRef ref;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox();
      }),
    ));
    expect(kankenDataParts.any((p) => p.id == 'learnedTerms'), isTrue);

    final store = LearnedTermsStore('kanken');
    await tester.runAsync(() async {
      await store.setLearned('compound:岩石', true);
      final part = kankenDataParts.firstWhere((p) => p.id == 'learnedTerms');
      final exported = await part.export(ref);
      expect(exported, ['compound:岩石']);
      await part.reset(ref);
      expect(await store.load(), isEmpty);
      await part.restore(ref, exported);
      expect(await store.load(), {'compound:岩石'});
    });
  });

  testWidgets('ルーターに /glossary の経路があり、画面が開く', (tester) async {
    final root = appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/');
    expect(
      root.routes.whereType<GoRoute>().any((r) => r.path == 'glossary'),
      isTrue,
    );
    expect(kGlossaryMenuLabel, '用語集');
    SharedPreferences.setMockInitialValues({});
    await pumpScreen(tester);
    expect(find.text('用語集'), findsOneWidget);
    expect(find.text('部首'), findsOneWidget);
  });
}
