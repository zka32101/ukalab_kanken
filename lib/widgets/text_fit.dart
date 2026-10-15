import 'package:flutter/material.dart';

/// 端末の文字サイズ設定とアプリ内『文字の大きさ』をあわせた倍率。
double textScaleOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) / 14;

/// AppBar のタイトル。標準の AppBar は長いタイトルを「…」で省略して隠すので、
/// 幅に収まらないときだけ文字を縮めて、最後まで読めるようにする。
class FitTitle extends StatelessWidget {
  const FitTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, maxLines: 1, softWrap: false),
      );
}

/// タブの文字が、幅を等分したタブに収まらないとき true。
/// そのときは TabBar を横スクロールにして、文字が切れないようにする。
/// 収まるうちは今までどおり幅を等分して並べる。
bool tabBarScrollable(BuildContext context, List<FitTabSpec> tabs) {
  final s = textScaleOf(context);
  final each = MediaQuery.sizeOf(context).width / tabs.length;
  // 全角 1 文字 = 16sp として見積もる（TabBar の左右の余白は 16 ずつ）
  return tabs.any((t) => t.text.runes.length * 16.0 * s + 32 > each);
}

/// アイコン付きタブの高さ。文字が大きいときは文字の分だけ高くする。
double iconTabHeight(BuildContext context) {
  final s = textScaleOf(context);
  return s <= 1.0 ? 72.0 : 72.0 + 20.0 * (s - 1.0);
}

/// 文字だけのタブの高さ。
double textTabHeight(BuildContext context) {
  final s = textScaleOf(context);
  return s <= 1.0 ? 46.0 : 46.0 + 20.0 * (s - 1.0);
}

/// グラフの軸ラベルなど、決まった広さの中に置く文字用の倍率（拡大は 1.3 倍まで）。
TextScaler chartTextScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

/// 1 行の文字。置き場所の大きさが決まっている（DropdownButton の項目は高さ 48 など）ので、
/// 文字が大きいときは収まるまで縮めて、切れないようにする。
class FitText extends StatelessWidget {
  const FitText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, maxLines: 1, softWrap: false),
      );
}

/// 数字などの 1 行表示を、親の幅の [maxFraction] までに収める（超えるときだけ縮める）。
/// 標準の大きさのときは見た目が変わらない。
class FitWidth extends StatelessWidget {
  const FitWidth({super.key, required this.child, this.maxFraction = 0.4});

  final Widget child;
  final double maxFraction;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * maxFraction,
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      );
}

/// [fitTabBar] に渡すタブの定義。
class FitTabSpec {
  const FitTabSpec(this.text, {this.icon});

  final String text;
  final IconData? icon;
}

/// 文字が大きくても、タブの文字が「…」や薄れで隠れない TabBar。
/// 標準の大きさのときは、今までの TabBar と同じ見た目（幅を等分）。
TabBar fitTabBar(
  BuildContext context, {
  TabController? controller,
  required List<FitTabSpec> tabs,
  Color? labelColor,
  Color? unselectedLabelColor,
  Color? indicatorColor,
}) {
  final scroll = tabBarScrollable(context, tabs);
  return TabBar(
    controller: controller,
    labelColor: labelColor,
    unselectedLabelColor: unselectedLabelColor,
    indicatorColor: indicatorColor,
    isScrollable: scroll,
    tabAlignment: scroll ? TabAlignment.start : null,
    tabs: [
      for (final t in tabs)
        Tab(
          text: t.text,
          icon: t.icon == null ? null : Icon(t.icon),
          height: t.icon == null ? textTabHeight(context) : iconTabHeight(context),
        ),
    ],
  );
}

/// GridView の childAspectRatio（幅÷高さ）を、文字が大きいときだけ縦長にして文字が収まるようにする。
double gridAspect(BuildContext context, double base) {
  final s = textScaleOf(context);
  return s <= 1.0 ? base : base / (1.0 + (s - 1.0) * 0.5);
}

/// 数字や短い文字を並べる格子の列数。文字がとても大きいときは 1 列にして、
/// 1 つあたりの幅を確保する。標準の大きさでは [columns] のまま。
int gridColumns(BuildContext context, int columns) {
  final s = textScaleOf(context);
  if (s <= 1.15) return columns;
  if (s <= 1.6) return columns >= 3 ? columns - 1 : columns;
  return columns >= 3 ? 2 : 1;
}

/// [gridColumns] とあわせて使う childAspectRatio（幅÷高さ）。
/// 列を減らして 1 つあたりの幅が広がった分と、文字が大きくなった分だけ縦に伸ばす。
double gridColumnsAspect(BuildContext context, int columns, double base) {
  final s = textScaleOf(context);
  if (s <= 1.0) return base;
  final cols = gridColumns(context, columns);
  return base * (columns / cols) / (1.0 + (s - 1.0) * 0.5);
}

/// 子の幅を、親（画面）の幅の [maxFraction] までにする。バッジやボタンの文字が長いとき、
/// 隣の文字を押しつぶさずに、自分の中で折り返すようにする。標準の大きさでは見た目が変わらない。
class CapWidth extends StatelessWidget {
  const CapWidth({super.key, required this.child, this.maxFraction = 0.4});

  final Widget child;
  final double maxFraction;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * maxFraction,
        ),
        child: child,
      );
}

/// 画面いっぱいの高さを最低限とし、中身が高くなったら（文字が大きいときなど）
/// 縦にスクロールできる箱。標準の大きさでは [child] がそのまま画面に収まって見た目は同じ。
/// [child] が Expanded を持つ Column のときは [intrinsicHeight] を true にする。
class MinHeightScroll extends StatelessWidget {
  const MinHeightScroll({
    super.key,
    required this.child,
    this.intrinsicHeight = false,
  });

  final Widget child;
  final bool intrinsicHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: intrinsicHeight ? IntrinsicHeight(child: child) : child,
          ),
        ),
      );
}
