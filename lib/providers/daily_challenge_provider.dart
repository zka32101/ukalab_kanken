import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_challenge.dart';
import 'firebase_provider.dart';

/// 本日のデイリーチャレンジ取得 provider
final dailyChallengeProvider = FutureProvider<DailyChallenge>((ref) async {
  final firestore = ref.watch(firebaseProvider);
  final today = DateTime.now();
  final dateStr = _formatDate(today);

  try {
    final doc = await firestore.collection('challenges').doc(dateStr).get();

    if (doc.exists && doc.data() != null) {
      return DailyChallenge.fromJson({...doc.data()!, 'id': doc.id});
    }

    // チャレンジが存在しない場合は作成
    return await _createDailyChallenge(firestore, dateStr);
  } catch (e) {
    throw Exception('Failed to load daily challenge: $e');
  }
});

/// 特定日付のデイリーチャレンジ取得 provider
final dailyChallengeByDateProvider = FutureProvider.family<DailyChallenge, String>((ref, dateStr) async {
  final firestore = ref.watch(firebaseProvider);

  try {
    final doc = await firestore.collection('challenges').doc(dateStr).get();

    if (doc.exists && doc.data() != null) {
      return DailyChallenge.fromJson({...doc.data()!, 'id': doc.id});
    }

    throw Exception('Challenge not found for date: $dateStr');
  } catch (e) {
    throw Exception('Failed to load challenge: $e');
  }
});

/// デイリーチャレンジ StateNotifier
class DailyChallengeNotifier extends StateNotifier<AsyncValue<DailyChallenge>> {
  final FirebaseFirestore _firestore;

  DailyChallengeNotifier(this._firestore) : super(const AsyncValue.loading());

  /// 本日のチャレンジを読み込む
  Future<void> loadToday() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final today = DateTime.now();
      final dateStr = _formatDate(today);

      final doc = await _firestore.collection('challenges').doc(dateStr).get();

      if (doc.exists && doc.data() != null) {
        return DailyChallenge.fromJson({...doc.data()!, 'id': doc.id});
      }

      return _createDailyChallenge(_firestore, dateStr);
    });
  }

  /// 特定日付のチャレンジを読み込む
  Future<void> loadByDate(String dateStr) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final doc = await _firestore.collection('challenges').doc(dateStr).get();

      if (doc.exists && doc.data() != null) {
        return DailyChallenge.fromJson({...doc.data()!, 'id': doc.id});
      }

      throw Exception('Challenge not found for date: $dateStr');
    });
  }
}

/// デイリーチャレンジ StateNotifier provider
final dailyChallengeNotifierProvider =
    StateNotifierProvider<DailyChallengeNotifier, AsyncValue<DailyChallenge>>((ref) {
  final firestore = ref.watch(firebaseProvider);
  return DailyChallengeNotifier(firestore);
});

/// 日付フォーマット (YYYY-MM-DD)
String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// デイリーチャレンジを作成
Future<DailyChallenge> _createDailyChallenge(
  FirebaseFirestore firestore,
  String dateStr,
) async {
  try {
    // ランダムに10問選択
    final questionsSnap = await firestore
        .collection('questions')
        .limit(10)
        .get();

    final questionIds = questionsSnap.docs.map((d) => d.id).toList();

    final resetTime = DateTime.now().add(Duration(days: 1));

    final challenge = DailyChallenge(
      id: dateStr,
      date: dateStr,
      questionIds: questionIds,
      difficulty: 'medium',
      resetTime: resetTime,
      createdAt: DateTime.now(),
    );

    // Firestore に保存
    await firestore
        .collection('challenges')
        .doc(dateStr)
        .set(challenge.toJson());

    return challenge;
  } catch (e) {
    throw Exception('Failed to create daily challenge: $e');
  }
}
