import 'dart:io';
import 'package:app_common_kit/app_common_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

/// 文字切れ・はみ出しスモークテストの 1 条件。
class ClipCase {
  const ClipCase(this.width, this.deviceScale, [this.appScale = AppTextScale.standard]);

  final double width;

  /// 端末の文字サイズ倍率（OS 設定）。
  final double deviceScale;

  /// アプリ内『文字の大きさ』設定（標準・大・特大）。
  final AppTextScale appScale;

  String get label => 'w${width.toInt()} x$deviceScale app=${appScale.name}';
}

/// 幅 320/280dp × 端末倍率 1/2/3、さらにアプリ内の 大・特大。
const clipCases = <ClipCase>[
  ClipCase(320, 1),
  ClipCase(320, 2),
  ClipCase(320, 3),
  ClipCase(280, 1),
  ClipCase(280, 2),
  ClipCase(280, 3),
  ClipCase(320, 1, AppTextScale.large),
  ClipCase(320, 1, AppTextScale.xLarge),
  ClipCase(280, 1, AppTextScale.xLarge),
];

/// 画面ウィジェットを [c] の条件で表示し、レイアウトのはみ出し系の例外を集めて返す。
/// 返り値が空ならはみ出しなし。
Future<List<String>> pumpAndCollectOverflow(
  WidgetTester tester,
  Widget screen,
  ClipCase c, {
  List<Override> overrides = const [],
  List<String> externalWidgets = const [],
  double height = 640,
  bool dark = false,
  String name = '',
  bool checkParagraphs = true,
  Future<void> Function(WidgetTester tester)? interact,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(c.width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  appTextScale.value = c.appScale;
  addTearDown(() => appTextScale.value = AppTextScale.standard);

  final errors = <String>[];
  final prev = FlutterError.onError;
  FlutterError.onError = (d) {
    errors.add(_summ(d.exceptionAsString(), d.toString()));
  };
  addTearDown(() => FlutterError.onError = prev);

  try {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      coinServiceProvider.overrideWithValue(
          CoinService(store: InMemoryCoinStore(), shop: const [])),
      outfitServiceProvider
          .overrideWithValue(OutfitService(store: InMemoryOutfitStore())),
      ...overrides,
    ],
    child: MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(c.deviceScale)),
        child: applyAppTextScale(context, child),
      ),
      home: screen,
    ),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (interact != null) {
    try {
      await interact(tester);
    } catch (e) {
      errors.add('FIXTURE-GAP 操作に失敗: ${e.toString().split('\n').first}');
    }
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
  // 画面を作る過程での例外もここで拾う
  Object? ex;
  while ((ex = tester.takeException()) != null) {
    errors.add(_summ(ex.toString(), ex.toString()));
  }
  } finally {
    FlutterError.onError = prev;
  }
  if (checkParagraphs) errors.addAll(_clippedParagraphs(tester, externalWidgets));
  final dump = Platform.environment['CLIP_DUMP'];
  if (dump != null && name.contains(dump)) {
    final texts = <String>[];
    void v(RenderObject r) {
      if (r is RenderParagraph) texts.add(r.text.toPlainText().replaceAll('\n', '⏎'));
      r.visitChildren(v);
    }
    v(tester.binding.renderViews.first);
    // ignore: avoid_print
    print('DUMP[$name ${c.label}]: ${texts.join(' | ')}');
  }
  final log = Platform.environment['CLIP_LOG'];
  if (log != null) {
    for (final e in errors) {
      File(log).writeAsStringSync('$name | ${tester.testDescription} | $e\n', mode: FileMode.append);
    }
  }
  return errors
      .where((e) =>
          !e.startsWith('EXTERNAL') &&
          (e.startsWith('CLIPPED') ||
          e.startsWith('FIXTURE-GAP') ||
          e.contains('overflowed') ||
          e.contains('RenderFlex') ||
          e.contains('RenderBox') ||
          e.contains('unbounded') ||
          e.contains('constraints')))
      .toSet()
      .toList();
}

String describe(List<String> errs) => errs.join('\n');

String _summ(String msg, String full) {
  final first = msg.split('\n').first;
  final m = RegExp(r'file:///[^\s]*/lib/[^\s]+').firstMatch(full);
  if (m == null) return first;
  final external = m.group(0)!.contains('.pub-cache');
  return '${external ? 'EXTERNAL ' : ''}$first @ ${m.group(0)!.split('/lib/').last}';
}

/// 画面内のテキストのうち、箱が小さくて文字が切れている（または省略されている）ものを返す。
/// RenderFlex overflow の例外にならない「固定サイズの箱の中の Text」「maxLines/ellipsis」を拾う。
List<String> _clippedParagraphs(WidgetTester tester, List<String> externalWidgets) {
  final out = <String>[];
  void visit(RenderObject r) {
    if (r is RenderParagraph) {
      final text = r.text.toPlainText();
      final isIcon = text.isNotEmpty &&
          text.runes.every((c) => c >= 0xE000 && c <= 0xF8FF || c >= 0xF0000);
      if (text.startsWith('エラー') ||
          text.contains('MissingPlugin') ||
          text.contains('core/no-app') ||
          text.contains('UnimplementedError')) {
        out.add('FIXTURE-GAP エラー表示のまま: ${text.split('\n').first}');
      }
      final sz = r.size;
      final ts = r.textSize;
      // 折り返せない最長の語（数字の並びなど）が箱より広いと、はみ出して描かれる
      // （日本語は文字の間のどこでも折り返せるので、数字や英字だけの語で調べる）
      final hasCjk = text.runes.any((c) => c >= 0x3000 && c <= 0xFFEF);
      final wordW = hasCjk ? 0.0 : r.getMinIntrinsicWidth(double.infinity);
      if (!isIcon &&
          text.trim().isNotEmpty &&
          (ts.width > sz.width + 1 ||
              ts.height > sz.height + 1 ||
              wordW * 0.55 > sz.width + 1 ||
              r.didExceedMaxLines)) {
        final t = text.replaceAll('\n', '⏎');
        // 共通パッケージ（ukalab_core / app_common_kit）の部品の中の文字は、このリポジトリでは直せないので EXTERNAL として別扱い。
        var chain = '';
        final creator = r.debugCreator;
        if (creator is DebugCreator) chain = creator.element.debugGetCreatorChain(150);
        final external = externalWidgets.any(chain.contains);
        out.add('${external ? 'EXTERNAL ' : ''}CLIPPED "${t.length > 24 ? '${t.substring(0, 24)}…' : t}" '
            'text=${ts.width.toStringAsFixed(0)}x${ts.height.toStringAsFixed(0)} '
            'box=${sz.width.toStringAsFixed(0)}x${sz.height.toStringAsFixed(0)}'
            '${r.didExceedMaxLines ? ' maxLines' : ''}'
            '${Platform.environment['CLIP_CHAIN'] != null ? ' chain=${chain.split('\n').take(8).join('<')}' : ''}'
            '${wordW * 0.55 > sz.width + 1 ? ' word=${wordW.toStringAsFixed(0)}' : ''}');
      }
    }
    r.visitChildren(visit);
  }

  visit(tester.binding.renderViews.first);
  return out;
}

/// Firebase を「初期化済みだが通信はしない」状態にする（FirebaseAuth.instance 等を直接使う画面用）。
Future<void> initFirebaseMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
}
