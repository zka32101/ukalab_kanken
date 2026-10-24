import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/index.dart';

/// アプリに同梱した問題データ（assets/questions/kanken_questions.json）。
///
/// オフラインなどで Firestore から問題が取れないときに、演習の出題を続けるために使う。
/// 本番の questions コレクションと同じ元データ（scripts/seed-kanji-questions.js）から
/// scripts/generate_bundled_questions.py で作る。10級〜2級の2,136問。
class BundledQuestions {
  BundledQuestions({Future<String> Function()? loader})
      : _loader = loader ?? (() => rootBundle.loadString(assetPath));

  static const String assetPath = 'assets/questions/kanken_questions.json';

  final Future<String> Function() _loader;
  Future<Map<String, List<KanjiQuestion>>>? _byLevel;

  /// 級ごとの問題（読み込みは1回だけ）。読めなければ空（出題は他の手段に任せる）。
  Future<Map<String, List<KanjiQuestion>>> _load() => _byLevel ??= () async {
        try {
          return parse(await _loader());
        } catch (_) {
          return <String, List<KanjiQuestion>>{};
        }
      }();

  /// JSON の文字列を、級ごとの問題にする。
  static Map<String, List<KanjiQuestion>> parse(String json) {
    final out = <String, List<KanjiQuestion>>{};
    for (final raw in jsonDecode(json) as List) {
      final q = KanjiQuestion.fromJson(Map<String, dynamic>.from(raw as Map));
      out.putIfAbsent(q.level, () => []).add(q);
    }
    return out;
  }

  /// 指定の級の同梱の問題（無ければ空）。
  Future<List<KanjiQuestion>> forLevel(String level) async =>
      (await _load())[level] ?? const [];
}
