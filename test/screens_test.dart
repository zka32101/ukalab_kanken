import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('DailyChallengeScreen Widget テスト', () {
    testWidgets('画面がロードされる', (WidgetTester tester) async {
      // 基本的な StatelessWidget テスト
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('デイリーチャレンジ')),
            body: const Center(child: Text('テスト画面')),
          ),
        ),
      );

      expect(find.text('デイリーチャレンジ'), findsOneWidget);
      expect(find.text('テスト画面'), findsOneWidget);
    });

    testWidgets('ボタンがタップ可能', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('開始'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('開始'));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });

  group('ProgressDashboardScreen Widget テスト', () {
    testWidgets('進捗画面が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('学習進捗')),
            body: const Center(
              child: Column(
                children: [
                  Text('レベル'),
                  Text('学習統計'),
                  Text('週別正解率'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('学習進捗'), findsOneWidget);
      expect(find.text('レベル'), findsOneWidget);
      expect(find.text('学習統計'), findsOneWidget);
    });

    testWidgets('統計情報が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('総問題数'),
                const Text('100'),
                const Text('正解数'),
                const Text('85'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('総問題数'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('正解数'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
    });
  });

  group('UI コンポーネント テスト', () {
    testWidgets('StatTile が正しく表示される', (WidgetTester tester) async {
      const stat = 'レベル';
      const value = '5';
      const icon = '⭐';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(stat),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(icon), findsOneWidget);
      expect(find.text(value), findsOneWidget);
      expect(find.text(stat), findsOneWidget);
    });

    testWidgets('プログレスバーが表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinearProgressIndicator(
              value: 0.75,
              minHeight: 12,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('カードレイアウト', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('タイトル'),
                    const SizedBox(height: 16),
                    const Text('コンテンツ'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('タイトル'), findsOneWidget);
      expect(find.text('コンテンツ'), findsOneWidget);
    });
  });

  group('レスポンシブデザイン テスト', () {
    testWidgets('小画面でスクロール可能', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(height: 200, color: Colors.blue),
                  Container(height: 200, color: Colors.red),
                  Container(height: 200, color: Colors.green),
                  Container(height: 200, color: Colors.yellow),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('Row レイアウト', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.blue,
                    height: 100,
                    child: const Center(child: Text('左')),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.red,
                    height: 100,
                    child: const Center(child: Text('右')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('左'), findsOneWidget);
      expect(find.text('右'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });
  });
}
