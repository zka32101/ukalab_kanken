import 'package:flutter/material.dart';

/// 選択肢のボタンに出す文字。
///
/// 部首の「宀」「冖」「冂」「亠」「丶」のような、画の少ない字は、フォントの字形が行の上寄りに
/// 描かれるため、ボタンの中央からずれて見えた（上端に寄って、欠けているようにも見えた）。
/// 行の高さを固定して、字を行の中央に置く（[StrutStyle] の forceStrutHeight）。
/// 長い文字列（熟語・文など）の見た目は変えない。
class ChoiceText extends StatelessWidget {
  final String text;

  const ChoiceText(this.text, {Key? key}) : super(key: key);

  /// 1字だけの選択肢か（部首・漢字・画数の数字など）。
  static bool isSingle(String s) => s.runes.length == 1;

  @override
  Widget build(BuildContext context) {
    if (!isSingle(text)) return Text(text);
    final fontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    return Text(
      text,
      textAlign: TextAlign.center,
      strutStyle: StrutStyle(
        fontSize: fontSize,
        height: 1.2,
        forceStrutHeight: true,
        leading: 0.5,
      ),
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
  }
}
