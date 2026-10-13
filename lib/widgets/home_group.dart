import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ukalab_core/ui.dart';

/// ホームの分類（見出し + 中身）。折りたたみ状態は端末内（SharedPreferences）に保存する。
/// キーは `ukalab_kanken_home_section_<id>`。保存できない環境でも初期状態で動く。
class HomeGroup extends StatefulWidget {
  const HomeGroup({
    super.key,
    required this.id,
    required this.title,
    this.subtitle,
    this.emoji,
    this.collapsible = true,
    this.initiallyExpanded = true,
    required this.child,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? emoji;
  final bool collapsible;
  final bool initiallyExpanded;
  final Widget child;

  static String prefsKey(String id) => 'ukalab_kanken_home_section_$id';

  @override
  State<HomeGroup> createState() => _HomeGroupState();
}

class _HomeGroupState extends State<HomeGroup> {
  late final ValueNotifier<bool> _expanded =
      ValueNotifier<bool>(widget.initiallyExpanded);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!widget.collapsible) return;
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getBool(HomeGroup.prefsKey(widget.id));
      if (v != null && mounted) _expanded.value = v;
    } catch (_) {}
  }

  Future<void> _save(bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(HomeGroup.prefsKey(widget.id), v);
    } catch (_) {}
  }

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeSection(
      title: widget.title,
      subtitle: widget.subtitle,
      leading: widget.emoji == null
          ? null
          : Text(widget.emoji!, style: const TextStyle(fontSize: 22)),
      collapsible: widget.collapsible,
      expandedListenable: widget.collapsible ? _expanded : null,
      onExpandedChanged: _save,
      child: widget.child,
    );
  }
}
