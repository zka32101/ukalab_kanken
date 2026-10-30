import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ukalab_core/cross_promo.dart';

/// 漢検の本番 applicationId（設定画面で UkalabCrossPromoSection に渡している値）。
const _kankenAppId = 'com.yourwish.ukarulab.kanji';

void main() {
  test('漢検の applicationId は、うかラボ8アプリの一覧にある', () {
    expect(kUkalabAppIds, contains(_kankenAppId));
    expect(isUkalabAppId(_kankenAppId), isTrue);
  });

  testWidgets('Firebase 未初期化・掲載0件でも、相互紹介の初期化は例外を投げない', (tester) async {
    await tester.runAsync(() async {
      await UkalabCrossPromo.init();
      // 二重に呼んでも同じ結果（1回分しか実行しない）
      await UkalabCrossPromo.init();
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('掲載0件のとき、セクションは例外なく何も表示しない（子ども向け設定・保護者ゲート付き）',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              const Text('サポート'),
              UkalabCrossPromoSection(
                currentAppId: _kankenAppId,
                isChildDirected: true,
                beforeOpenStore: (context) async => false,
              ),
              const Text('収録問題数'),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('他のアプリもチェック！'), findsNothing);
    // 前後の項目は壊れずに残る
    expect(find.text('サポート'), findsOneWidget);
    expect(find.text('収録問題数'), findsOneWidget);
  });

  test('子ども向け設定で保護者ゲートが無いと、構築時に assert で気づける', () {
    expect(
      () => UkalabCrossPromoSection(
        currentAppId: _kankenAppId,
        isChildDirected: true,
      ),
      throwsAssertionError,
    );
  });
}
