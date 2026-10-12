import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanken/router/app_router.dart';
import 'package:kanken/screens/reading_list_screen.dart';
import 'package:ukalab_core/ukalab_core.dart'
    show ChapterReading, parseChapterReadingsJsonl;

List<ChapterReading> _readings() => parseChapterReadingsJsonl(
      File('assets/readings/kanken.readings.jsonl').readAsStringSync(),
    ).items;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('一覧に区分と題名が並び、タップで詳細（節の見出し）が開く', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final readings = _readings();
    await tester.pumpWidget(MaterialApp(
      home: ReadingListScreen(loadReadings: () async => readings),
    ));
    await tester.pumpAndSettle();

    expect(find.text('漢字のしくみ'), findsOneWidget);
    expect(find.text('答案のコツ'), findsOneWidget);
    for (final r in readings) {
      expect(find.text(r.title), findsOneWidget, reason: r.title);
    }

    await tester.tap(find.text(readings.first.title));
    await tester.pumpAndSettle();
    expect(find.text(readings.first.sections.first.heading), findsOneWidget);
  });

  testWidgets('すべての読み物が詳細画面で開ける', (tester) async {
    for (final r in _readings()) {
      await tester.pumpWidget(MaterialApp(home: ReadingDetailScreen(reading: r)));
      await tester.pumpAndSettle();
      expect(find.text(r.sections.first.heading), findsOneWidget,
          reason: r.readingId);
    }
  });

  testWidgets('読み込みに失敗したら案内を出す', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReadingListScreen(loadReadings: () async => throw StateError('x')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('読み込みに失敗しました。'), findsOneWidget);
  });

  testWidgets('ルーターに /readings の経路がある（ホームの入口から開ける）', (tester) async {
    final root = appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/');
    expect(
      root.routes.whereType<GoRoute>().any((r) => r.path == 'readings'),
      isTrue,
    );
    expect(kReadingsMenuLabel, contains('解説読み物'));
  });
}
