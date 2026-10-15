import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// オフライン時にサーバー応答待ち(数十秒)で出題が止まらないようにするための取得。
  /// まず通常の get() を [serverTimeout] だけ待ち、時間切れ/通信不可ならローカルキャッシュから読む。
  /// 一度フォールバックしたら、次にサーバー取得が成功するまではキャッシュを先に読む
  /// （1回の出題で待ち時間が何度も積み上がらないように）。
  bool _preferCache = false;
  static const Duration serverTimeout = Duration(seconds: 3);

  Future<QuerySnapshot<Map<String, dynamic>>> _getWithCacheFallback(
    Query<Map<String, dynamic>> query,
  ) async {
    if (_preferCache) {
      try {
        final cached = await query.get(const GetOptions(source: Source.cache));
        if (cached.docs.isNotEmpty) return cached;
      } catch (_) {
        // キャッシュが読めなければ通常取得へ
      }
    }
    try {
      final snap = await query.get().timeout(serverTimeout);
      _preferCache = false;
      return snap;
    } on TimeoutException {
      _preferCache = true;
    } on FirebaseException catch (e) {
      if (e.code != 'unavailable') rethrow;
      _preferCache = true;
    }
    return query.get(const GetOptions(source: Source.cache));
  }

  // User(プロフィール) operations
  //
  // 1つのFirebase Authアカウント(uid)の下に複数の学習者プロフィールを
  // 持たせるため、実データは users/{uid}/profiles/{profileId} に保存する。
  // ランキングのドキュメントIDもプロフィール単位で分けるため
  // "{uid}_{profileId}" の複合IDを使う。

  static String rankingDocId(String uid, String profileId) => '${uid}_$profileId';

  /// rankingDocId() の逆変換。フレンド・チャレンジ等、他プロフィールを
  /// "{uid}_{profileId}" の複合IDで参照する箇所で使う。
  /// uidにはアンダースコアを含まないため、最初の "_" で分割すれば安全。
  static ({String uid, String profileId}) parseCompositeProfileId(String docId) {
    final index = docId.indexOf('_');
    if (index == -1) return (uid: docId, profileId: 'default');
    return (uid: docId.substring(0, index), profileId: docId.substring(index + 1));
  }

  Future<User?> getUser(String uid, {String profileId = 'default'}) async {
    final doc = await _profileDoc(uid, profileId).get();
    if (!doc.exists) return null;
    return User.fromJson(doc.data()!);
  }

  /// uid配下の全プロフィール一覧を取得する
  Future<List<User>> getUserProfiles(String uid) async {
    final snapshot = await _profilesCollection(uid).get();
    return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
  }

  Future<void> deleteProfile(String uid, String profileId) async {
    await _profileDoc(uid, profileId).delete();
    await _removeFromRanking(uid, profileId);
  }

  Future<void> createUser(User user) async {
    await _profileDoc(user.uid, user.profileId)
        .set(user.toJson(), SetOptions(merge: true));
    await _mirrorUserToProfileDirectory(user);
    if (user.rankingOptIn) {
      await _mirrorUserNameToRanking(user.uid, user.profileId, user.displayName);
    }
  }

  Future<void> updateUser(User user) async {
    await _profileDoc(user.uid, user.profileId)
        .set(user.toJson(), SetOptions(merge: true));
    await _mirrorUserToProfileDirectory(user);
    if (user.rankingOptIn) {
      await _mirrorUserNameToRanking(user.uid, user.profileId, user.displayName);
    } else {
      // 参加をオフにした場合は既存のランキングエントリも削除する
      await _removeFromRanking(user.uid, user.profileId);
    }
  }

  /// フレンドIDによる検索用に、ランキング参加設定(rankingOptIn)に関わらず
  /// ニックネーム等の最小限の情報だけを profileDirectory/{uid}_{profileId}
  /// （全員読み取り可）へミラーする。詳しくは _mirrorUserNameToRanking 参照。
  Future<void> _mirrorUserToProfileDirectory(User user) async {
    await _firestore
        .collection('profileDirectory')
        .doc(rankingDocId(user.uid, user.profileId))
        .set(
      {
        'uid': user.uid,
        'profileId': user.profileId,
        'displayName': user.displayName,
        'avatarIcon': user.avatarIcon,
        'currentLevel': user.currentLevel,
      },
      SetOptions(merge: true),
    );
  }

  /// フレンドID（"{uid}_{profileId}"）から公開プロフィール情報を検索する
  Future<Map<String, dynamic>?> findProfileByCompositeId(String compositeId) async {
    final doc = await _firestore.collection('profileDirectory').doc(compositeId).get();
    return doc.data();
  }

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid, String profileId) {
    return _profilesCollection(uid).doc(profileId);
  }

  CollectionReference<Map<String, dynamic>> _profilesCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('profiles');
  }

  /// users/{uid}/profiles/{profileId} 本体（メール等を含みうる）は本人のみ
  /// 読み書き可能なため、ランキング表示に使うニックネームだけを
  /// rankings/{uid}_{profileId}（全員読み取り可）へミラーする。
  /// レベル・経験値・コイン等の統計は GamificationNotifier が別途同じドキュメントへ
  /// merge するので、ここでは触れない。ランキング参加設定(rankingOptIn)が
  /// オンのユーザーのみ呼び出すこと。
  Future<void> _mirrorUserNameToRanking(
    String uid,
    String profileId,
    String userName,
  ) async {
    await _firestore.collection('rankings').doc(rankingDocId(uid, profileId)).set(
      {'userId': uid, 'profileId': profileId, 'userName': userName},
      SetOptions(merge: true),
    );
  }

  /// ランキング参加をオフにしたユーザーのエントリを削除する
  Future<void> _removeFromRanking(String uid, String profileId) async {
    await _firestore.collection('rankings').doc(rankingDocId(uid, profileId)).delete();
  }

  // Question operations
  /// uidを指定すると、そのユーザーが「覚えた」問題(getMasteredQuestionIds参照)を
  /// 出題対象から除外する。
  Future<List<KanjiQuestion>> getQuestionsByLevel(
    String level, {
    int limit = 50,
    String? uid,
    String profileId = 'default',
    int masteryThreshold = 3,
  }) async {
    final snapshot = await _getWithCacheFallback(_firestore
        .collection('questions')
        .where('level', isEqualTo: level)
        .limit(limit));

    var questions = snapshot.docs
        .map((doc) => KanjiQuestion.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    if (uid != null) {
      final excludeIds = await getMasteredQuestionIds(
        uid,
        profileId: profileId,
        masteryThreshold: masteryThreshold,
      );
      if (excludeIds.isNotEmpty) {
        questions = questions.where((q) => !excludeIds.contains(q.id)).toList();
      }
    }

    return questions;
  }

  /// 級内の全漢字から偏りなく出題するための取得。
  /// 級の漢字が多い場合に limit だけで取ると、ドキュメントID順の先頭しか出題されない。
  /// そこで [kanjiPool]（その級の配当漢字）をシャッフルし、[batchSize] 字ずつ
  /// ドキュメントIDで直接取得する（読み取り数は取得した字数ぶんだけ）。
  /// 「覚えた」除外後に [need] 件そろうまで、最大 [maxBatches] 回まで続ける。
  Future<List<KanjiQuestion>> getQuestionsByLevelSampled(
    String level,
    List<String> kanjiPool, {
    int need = 10,
    int batchSize = 30,
    int maxBatches = 4,
    String? uid,
    String profileId = 'default',
    int masteryThreshold = 3,
  }) async {
    final pool = [...kanjiPool]..shuffle();
    var excludeIds = <String>{};
    if (uid != null) {
      excludeIds = (await getMasteredQuestionIds(
        uid,
        profileId: profileId,
        masteryThreshold: masteryThreshold,
      ))
          .toSet();
    }
    final result = <KanjiQuestion>[];
    for (var b = 0; b < maxBatches && result.length < need; b++) {
      final start = b * batchSize;
      if (start >= pool.length) break;
      final ids = pool
          .skip(start)
          .take(batchSize)
          .map((k) => '$level-$k')
          .where((id) => !excludeIds.contains(id))
          .toList();
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
        final snap = await _getWithCacheFallback(_firestore
            .collection('questions')
            .where(FieldPath.documentId, whereIn: chunk));
        result.addAll(snap.docs.map(
            (d) => KanjiQuestion.fromJson({...d.data(), 'id': d.id})));
      }
    }
    return result;
  }

  Future<KanjiQuestion?> getKanjiQuestion(String questionId) async {
    final doc = await _firestore.collection('questions').doc(questionId).get();
    if (!doc.exists) return null;
    return KanjiQuestion.fromJson({...doc.data()!, 'id': doc.id});
  }

  // Answer logging
  //
  // answerLogs には履歴として1件ずつ記録する一方、出題除外の判定に
  // 毎回全履歴を読むのは非効率なため、questionStats/{questionId} に
  // 連続正解数(correctStreak)を別途集計しておく。正解なら+1、
  // 不正解なら0にリセットする。「N問連続正解したら出題除外」
  // (User.masteryThreshold)の判定に使う。
  // いずれも users/{uid}/profiles/{profileId}/... 配下（プロフィール単位）。
  Future<void> addAnswerLog(UserAnswerLog log) async {
    final batch = _firestore.batch();
    final profileRef = _profileDoc(log.uid, log.profileId);

    // log.id は呼び出し側（practiceViewModel等）では常に空文字列で渡ってくる
    // （Firestore側で自動採番する想定）。.doc('') は無効なパスになり
    // バッチ全体がエラーになるため、空ならIDを自動生成する。
    final logRef = log.id.isEmpty
        ? profileRef.collection('answerLogs').doc()
        : profileRef.collection('answerLogs').doc(log.id);
    batch.set(logRef, log.toJson()..['id'] = logRef.id);

    final statsRef = profileRef.collection('questionStats').doc(log.questionId);
    batch.set(
      statsRef,
      {
        'correctStreak': log.isCorrect ? FieldValue.increment(1) : 0,
        'lastAnsweredAt': log.answeredAt.toIso8601String(),
      },
      SetOptions(merge: true),
    );

    // 級ごとの正答率集計（進捗バー・次の級までのカウントダウンに使う）
    if (log.level.isNotEmpty) {
      final levelStatsRef = profileRef.collection('levelStats').doc(log.level);
      batch.set(
        levelStatsRef,
        {
          'totalCount': FieldValue.increment(1),
          'correctCount': FieldValue.increment(log.isCorrect ? 1 : 0),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  // 級ごとの正答率集計（プロフィール単位 users/{uid}/profiles/{profileId}/levelStats）
  Future<Map<String, LevelProgress>> getLevelStats(
    String uid, {
    String profileId = 'default',
  }) async {
    final snapshot =
        await _profileDoc(uid, profileId).collection('levelStats').get();
    return {
      for (final doc in snapshot.docs)
        doc.id: LevelProgress.fromJson(doc.id, doc.data()),
    };
  }

  Future<List<UserAnswerLog>> getUserAnswerLogs(
    String uid, {
    String profileId = 'default',
  }) async {
    final snapshot = await _profileDoc(uid, profileId)
        .collection('answerLogs')
        .orderBy('answeredAt', descending: true)
        .limit(200)
        .get();
    return snapshot.docs
        .map((doc) => UserAnswerLog.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Weak kanji tracking（誤答パターンから苦手漢字を分析・追跡）
  // プロフィール単位（users/{uid}/profiles/{profileId}/weakKanjiList）
  Future<List<WeakKanjiList>> getWeakKanjiList(
    String uid, {
    String profileId = 'default',
  }) async {
    final snapshot =
        await _profileDoc(uid, profileId).collection('weakKanjiList').get();
    return snapshot.docs
        .map((doc) => WeakKanjiList.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// 未習得の苦手漢字IDを、誤答回数が多い順に返す
  Future<List<String>> getUserWeakKanjis(
    String uid, {
    String profileId = 'default',
  }) async {
    final weakList = await getWeakKanjiList(uid, profileId: profileId);
    final unmastered = weakList.where((w) => w.masteredAt == null).toList()
      ..sort((a, b) => b.missCount.compareTo(a.missCount));
    return unmastered.map((w) => w.kanjiId).toList();
  }

  Future<void> upsertWeakKanjiList(
    WeakKanjiList item, {
    String profileId = 'default',
  }) async {
    await _profileDoc(item.uid, profileId)
        .collection('weakKanjiList')
        .doc(item.kanjiId)
        .set(item.toJson(), SetOptions(merge: true));
  }

  // Learned kanji tracking（演習後にユーザーが手動でチェックする「覚えた」機能）
  // プロフィール単位（users/{uid}/profiles/{profileId}/learnedKanjis）
  Future<List<String>> getUserLearnedKanjis(
    String uid, {
    String profileId = 'default',
  }) async {
    final snapshot =
        await _profileDoc(uid, profileId).collection('learnedKanjis').get();
    return snapshot.docs
        .map((doc) => doc.data()['questionId'] as String? ?? doc.id)
        .toList();
  }

  Future<void> markAsLearned(
    String uid,
    String kanjiId, {
    String profileId = 'default',
  }) async {
    await _profileDoc(uid, profileId)
        .collection('learnedKanjis')
        .doc(kanjiId)
        .set({
      'uid': uid,
      'profileId': profileId,
      'questionId': kanjiId,
      'learnedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 「覚えた」チェックを取り消す
  Future<void> unmarkAsLearned(
    String uid,
    String kanjiId, {
    String profileId = 'default',
  }) async {
    await _profileDoc(uid, profileId)
        .collection('learnedKanjis')
        .doc(kanjiId)
        .delete();
  }

  /// 出題から除外すべき問題ID一覧
  /// （手動で「覚えた」チェックされた問題 + masteryThreshold回以上連続正解した問題）
  Future<Set<String>> getMasteredQuestionIds(
    String uid, {
    String profileId = 'default',
    int masteryThreshold = 3,
  }) async {
    final excludeIds = <String>{};
    final profileRef = _profileDoc(uid, profileId);

    final learnedSnapshot = await _getWithCacheFallback(profileRef.collection('learnedKanjis'));
    excludeIds.addAll(
      learnedSnapshot.docs.map((d) => d.data()['questionId'] as String? ?? d.id),
    );

    final statsSnapshot = await _getWithCacheFallback(profileRef
        .collection('questionStats')
        .where('correctStreak', isGreaterThanOrEqualTo: masteryThreshold));
    excludeIds.addAll(statsSnapshot.docs.map((d) => d.id));

    return excludeIds;
  }

  // Badge operations（級合格バッジ。プロフィール単位 users/{uid}/profiles/{profileId}/badges）
  Future<void> addCollectionBadge(
    String uid,
    CollectionBadge badge, {
    String profileId = 'default',
  }) async {
    await _profileDoc(uid, profileId)
        .collection('badges')
        .doc(badge.badgeId)
        .set(badge.toJson(), SetOptions(merge: true));
  }

  Future<List<CollectionBadge>> getUserBadges(
    String uid, {
    String profileId = 'default',
  }) async {
    final snapshot =
        await _profileDoc(uid, profileId).collection('badges').get();
    return snapshot.docs
        .map((doc) => CollectionBadge.fromJson(doc.data()))
        .toList();
  }
}
