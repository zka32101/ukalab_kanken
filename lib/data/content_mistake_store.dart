import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 熟語系の出題（四字熟語・故事・諺・対義語・類義語・同音異字・漢字作りなど）で間違えた問題の控え。
///
/// 熟語系の出題は、漢字の問題（Firestore）の問題IDでは表せないので、問題の内容そのもの
/// （問題文・指示・選択肢・正解・説明）を端末内に保存して、間違いノートの表示と解き直しに使う。
/// 保存するのは、問題の内容だけ（個人情報は含まない）。古いものから [maxItems] 件を超えた分は捨てる。
class ContentMistakeSnapshot {
  const ContentMistakeSnapshot({
    required this.id,
    required this.mode,
    required this.level,
    required this.prompt,
    required this.instruction,
    required this.choices,
    required this.correctAnswer,
    this.explanation,
  });

  /// 問題の内容から作る安定したID（[contentQuestionId]）。
  final String id;

  /// 出題形式の名前（PracticeMode.name。例: yoji）。
  final String mode;

  /// 出題された級（例: LEVEL_5）。
  final String level;
  final String prompt;
  final String instruction;
  final List<String> choices;
  final String correctAnswer;
  final String? explanation;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'level': level,
        'prompt': prompt,
        'instruction': instruction,
        'choices': choices,
        'correctAnswer': correctAnswer,
        if (explanation != null) 'explanation': explanation,
      };

  /// 壊れた入力は null（読めた分だけ復元する）。
  static ContentMistakeSnapshot? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final mode = json['mode'];
    final level = json['level'];
    final prompt = json['prompt'];
    final instruction = json['instruction'];
    final choices = json['choices'];
    final answer = json['correctAnswer'];
    if (id is! String || !id.startsWith(contentQuestionIdPrefix)) return null;
    if (mode is! String || level is! String || prompt is! String) return null;
    if (instruction is! String || answer is! String || choices is! List) return null;
    final list = [for (final c in choices) if (c is String) c];
    if (list.length != choices.length || !list.contains(answer)) return null;
    final explanation = json['explanation'];
    return ContentMistakeSnapshot(
      id: id,
      mode: mode,
      level: level,
      prompt: prompt,
      instruction: instruction,
      choices: list,
      correctAnswer: answer,
      explanation: explanation is String ? explanation : null,
    );
  }
}

/// 熟語系の問題IDの先頭。漢字の問題のIDと区別する。
const String contentQuestionIdPrefix = 'c:';

/// 熟語系の問題の、内容から決まる安定したID（出題形式・問題文・正解が同じなら同じID）。
/// 選択肢の並びや、誤答の選び方が変わっても同じ問題として扱う。
String contentQuestionId(String mode, String prompt, String correctAnswer) {
  // FNV-1a（32ビット）。Dart の hashCode は実行のたびに変わりうるので使わない。
  var h = 0x811c9dc5;
  for (final c in '$mode|$prompt|$correctAnswer'.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return '$contentQuestionIdPrefix$mode:${h.toRadixString(16).padLeft(8, '0')}';
}

class ContentMistakeStore {
  const ContentMistakeStore._();

  static const _key = 'ukalab_kanken_content_mistakes_v1';
  static const maxItems = 300;

  static Future<List<ContentMistakeSnapshot>> readAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return [
        for (final j in list)
          if (ContentMistakeSnapshot.fromJson(j) case final s?) s,
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<ContentMistakeSnapshot?> read(String id) async {
    for (final s in await readAll()) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 保存する。同じIDは入れ替えて最後（いちばん新しい）に置く。[maxItems] を超えたら古いものを捨てる。
  static Future<void> save(ContentMistakeSnapshot s) async {
    try {
      final all = [for (final x in await readAll()) if (x.id != s.id) x, s];
      final kept = all.length > maxItems ? all.sublist(all.length - maxItems) : all;
      await writeAll(kept);
    } catch (_) {}
  }

  static Future<void> writeAll(List<ContentMistakeSnapshot> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final s in list) s.toJson()]));
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
