// Playwright 用の最小アプリ（Flutter Web）。実機アプリは Firebase・課金・広告を起動時に使うため、
// Web ではホームの「学習」メニューと同じ入口（MenuGridCard）から、解説読み物の画面だけを開く。
//   flutter build web -t e2e/reading_main.dart
import 'package:flutter/material.dart';
import 'package:kanken/screens/reading_list_screen.dart';
import 'package:kanken/widgets/menu_grid_card.dart';

void main() {
  runApp(const MaterialApp(home: _Home()));
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学習')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          children: [
            MenuGridCard(
              icon: Icons.auto_stories,
              label: kReadingsMenuLabel,
              color: Colors.green,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReadingListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
