import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/services/ad_service.dart';

void main() {
  test('デバッグ・テスト実行ではGoogle公式のテスト広告IDを使う(本番IDはリポジトリに置かない)', () {
    final ids = AdService.unitIds;
    expect(ids.banner, startsWith('ca-app-pub-3940256099942544/'));
    expect(ids.interstitial, startsWith('ca-app-pub-3940256099942544/'));
  });
}
