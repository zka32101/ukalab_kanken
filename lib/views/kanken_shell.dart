import 'package:flutter/material.dart';
import 'package:ukalab_core/ui.dart';
import '../screens/learn_tab_screen.dart';
import '../screens/mock_exam_modes_screen.dart';
import '../screens/record_tab_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/banner_ad_widget.dart';
import 'home_screen.dart';

/// 下部5タブ（ホーム／学ぶ／模擬／記録／設定）。他のうかラボアプリと同じ [UkalabShell]。
///
/// 約30の個別画面はタブの外で Navigator.push で開く（そのあいだ下部タブとバナーは出ない）。
/// バナー広告はタブ共通で下部に1枠だけ置く。非表示・児童向け設定は [BannerAdWidget]（AdGate）側。
class KankenShell extends StatelessWidget {
  const KankenShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            // 下端の余白はバナー側（SafeArea）で受けるため、タブバーでは二重に取らない。
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: const UkalabShell(
                pages: [
                  HomeScreen(),
                  LearnTabScreen(),
                  MockExamModesScreen(),
                  RecordTabScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ),
          const SafeArea(top: false, child: BannerAdWidget()),
        ],
      ),
    );
  }
}
