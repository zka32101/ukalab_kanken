/// 選択肢を「問題ごとに安定した順序」で並べ替える。
///
/// 模擬試験の問題データは正解が先頭(A)に置かれているため、画面側で
/// 並べ替えないと毎回Aを押すだけで満点になってしまう。
/// 乱数の種を問題ID(seedKey)から決めるので、同じ問題なら再描画・戻る操作・
/// 端末が変わっても同じ順序になる(setStateのたびに順序が変わらない)。
/// 回答は選択肢の文字列で記録・採点されるため、並べ替えても採点は変わらない。
///
/// Web(JSの数値)でも同じ結果になるよう、途中の値は常に32bit内に収める。
List<String> shuffledOptions(String seedKey, List<String> options) {
  const mask = 0xFFFFFFFF;
  final result = List<String>.of(options);
  if (result.length < 2) return result;

  var h = 5381;
  for (final c in seedKey.codeUnits) {
    h = (h * 31 + c) & mask;
  }
  var x = h == 0 ? 0x9E3779B9 : h;
  int next() {
    x ^= (x << 13) & mask;
    x ^= x >> 17;
    x ^= (x << 5) & mask;
    return x;
  }

  // 最初の数値は種の下位ビットに引きずられやすいので捨てる
  for (var i = 0; i < 4; i++) {
    next();
  }
  for (var i = result.length - 1; i > 0; i--) {
    final j = next() % (i + 1);
    final t = result[i];
    result[i] = result[j];
    result[j] = t;
  }
  return result;
}
