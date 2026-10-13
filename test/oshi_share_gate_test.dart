import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/widgets/oshi_card.dart';

void main() {
  group('shareCardImageWithGate', () {
    Future<void> run(
      WidgetTester tester,
      Future<bool> Function(BuildContext) gate,
      List<Uint8List> shared,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ));
      await shareCardImageWithGate(
        ctx,
        Uint8List.fromList([1, 2, 3]),
        gate: gate,
        share: (p) async => shared.add(p),
      );
    }

    testWidgets('ゲート不通過では共有されない', (tester) async {
      final shared = <Uint8List>[];
      var calls = 0;
      await run(tester, (_) async {
        calls++;
        return false;
      }, shared);
      expect(calls, 1);
      expect(shared, isEmpty);
    });

    testWidgets('ゲート通過で共有される', (tester) async {
      final shared = <Uint8List>[];
      var calls = 0;
      await run(tester, (_) async {
        calls++;
        return true;
      }, shared);
      expect(calls, 1);
      expect(shared, hasLength(1));
    });
  });
}
