import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/data/bundled_questions.dart';
import 'package:kanken/data/level_kanji_data.dart';
import 'package:kanken/models/index.dart';
import 'package:kanken/services/firestore_service.dart';
import 'package:mocktail/mocktail.dart';

/// オフライン（Firestore から問題が取れない）でも、演習の問題が出る。
class _MockFirestore extends Mock implements FirebaseFirestore {}

/// Firestore がつながらない状態（どの操作も失敗する）。覚えた問題だけ、指定できる。
class _OfflineService extends FirestoreService {
  _OfflineService({Set<String> mastered = const {}, BundledQuestions? bundled})
      : _mastered = mastered,
        super(firestore: _MockFirestore(), bundled: bundled ?? _fromDisk());
  final Set<String> _mastered;

  @override
  Future<Set<String>> getMasteredQuestionIds(
    String uid, {
    String profileId = 'default',
    int masteryThreshold = 3,
  }) async =>
      _mastered;
}

BundledQuestions _fromDisk() => BundledQuestions(
    loader: () async => File('assets/questions/kanken_questions.json').readAsString());

/// シードスクリプトの問題（本番の questions コレクションの元データ）。
List<Map<String, dynamic>> _seed() {
  // 改行が CRLF の環境でも読めるように、LF にそろえる。
  final src = File('scripts/seed-kanji-questions.js').readAsStringSync().replaceAll('\r\n', '\n');
  final a = src.indexOf('const questions = ') + 'const questions = '.length;
  final b = src.indexOf('];\nasync function main') + 1;
  return (jsonDecode(src.substring(a, b)) as List).cast<Map<String, dynamic>>();
}

void main() {
  const levels = ['LEVEL_10', 'LEVEL_9', 'LEVEL_8', 'LEVEL_7', 'LEVEL_6', 'LEVEL_5', 'LEVEL_4', 'LEVEL_3', 'LEVEL_2_PRE', 'LEVEL_2'];

  group('同梱の問題データ', () {
    test('本番の元データ（シード）と一致する（準1級・1級は除く）', () {
      final seed = _seed().where((q) => q['level'] != 'LEVEL_1' && q['level'] != 'LEVEL_1_PRE').toList();
      final bundled = (jsonDecode(File('assets/questions/kanken_questions.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
      expect(bundled.length, seed.length);
      for (var i = 0; i < seed.length; i++) {
        expect(bundled[i]['id'], seed[i]['id'], reason: '$i');
        expect(bundled[i]['correctAnswer'], seed[i]['correctAnswer'], reason: seed[i]['id']);
        expect(bundled[i]['choices'], seed[i]['choices'], reason: seed[i]['id']);
        expect(bundled[i]['reading'], seed[i]['reading'], reason: seed[i]['id']);
        expect(bundled[i]['example'], seed[i]['example'], reason: seed[i]['id']);
      }
    });

    test('10級〜2級の配当漢字の問題が、全字そろっている（IDは重複しない・正解は選択肢の中）', () async {
      final byLevel = BundledQuestions.parse(File('assets/questions/kanken_questions.json').readAsStringSync());
      final ids = <String>{};
      for (final l in levels) {
        final qs = byLevel[l] ?? const [];
        expect(qs.map((q) => q.kanji).toSet(), LevelKanjiData.forLevel(l).toSet(), reason: l);
        for (final q in qs) {
          expect(ids.add(q.id), isTrue, reason: '${q.id} が重複');
          expect(q.choices, contains(q.correctAnswer), reason: q.id);
          expect(q.choices.toSet().length, q.choices.length, reason: q.id);
        }
      }
      expect(byLevel.containsKey('LEVEL_1'), isFalse);
      expect(byLevel.containsKey('LEVEL_1_PRE'), isFalse);
    });

    test('読み込みに失敗しても、例外にせず空（出題は他の手段に任せる）', () async {
      final b = BundledQuestions(loader: () async => throw Exception('読めない'));
      expect(await b.forLevel('LEVEL_10'), isEmpty);
    });

    test('読み込みは1回だけ', () async {
      var calls = 0;
      final b = BundledQuestions(loader: () async {
        calls++;
        return '[]';
      });
      await b.forLevel('LEVEL_10');
      await b.forLevel('LEVEL_9');
      expect(calls, 1);
    });
  });

  group('Firestore がつながらないとき（オフライン）', () {
    test('級の問題を取ると、同梱の問題が返る（上限まで）', () async {
      final fs = _OfflineService();
      final all = await fs.getQuestionsByLevel('LEVEL_10', limit: 100);
      expect(all.length, 80);
      final some = await fs.getQuestionsByLevel('LEVEL_10', limit: 30);
      expect(some.length, 30);
      expect(all.every((q) => q.level == 'LEVEL_10'), isTrue);
    });

    test('「覚えた」問題は、同梱の問題からも除く', () async {
      final fs = _OfflineService(mastered: {'LEVEL_10-一', 'LEVEL_10-二'});
      final qs = await fs.getQuestionsByLevel('LEVEL_10', limit: 100, uid: 'u1');
      expect(qs.length, 78);
      expect(qs.any((q) => q.id == 'LEVEL_10-一' || q.id == 'LEVEL_10-二'), isFalse);
    });

    test('サンプル取得でも、必要な数が重複なく、その級の問題だけ返る', () async {
      final fs = _OfflineService();
      for (final l in ['LEVEL_9', 'LEVEL_5', 'LEVEL_2']) {
        final qs = await fs.getQuestionsByLevelSampled(l, LevelKanjiData.forLevel(l), need: 10, uid: 'u1');
        expect(qs.length, 10, reason: l);
        expect(qs.map((q) => q.id).toSet().length, 10, reason: l);
        expect(qs.every((q) => q.level == l), isTrue, reason: l);
      }
    });

    test('サンプル取得でも、「覚えた」問題は出さない', () async {
      final mastered = {for (final k in LevelKanjiData.forLevel('LEVEL_9').take(150)) 'LEVEL_9-$k'};
      final fs = _OfflineService(mastered: mastered);
      final qs = await fs.getQuestionsByLevelSampled('LEVEL_9', LevelKanjiData.forLevel('LEVEL_9'), need: 10, uid: 'u1');
      expect(qs.length, 10);
      expect(qs.any((q) => mastered.contains(q.id)), isFalse);
    });

    test('「覚えた」の取得に失敗しても（オフライン）、出題は止まらない', () async {
      final fs = FirestoreService(firestore: _MockFirestore(), bundled: _fromDisk());
      final qs = await fs.getQuestionsByLevel('LEVEL_10', limit: 100, uid: 'u1');
      expect(qs.length, 80);
      final sampled = await fs.getQuestionsByLevelSampled('LEVEL_8', LevelKanjiData.forLevel('LEVEL_8'), need: 10, uid: 'u1');
      expect(sampled.length, 10);
    });

    test('同梱の無い級（準1級・1級）は、空（例外にしない）', () async {
      final fs = _OfflineService();
      expect(await fs.getQuestionsByLevel('LEVEL_1', limit: 100), isEmpty);
      expect(await fs.getQuestionsByLevelSampled('LEVEL_1', const ['乂'], need: 10), isEmpty);
    });
  });
}
