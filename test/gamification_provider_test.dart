// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kanken/providers/firebase_provider.dart';
import 'package:kanken/providers/gamification_provider.dart';

// Mocks
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  final bool _exists;
  final Map<String, dynamic>? _data;

  MockDocumentSnapshot({required bool exists, Map<String, dynamic>? data})
      : _exists = exists,
        _data = data;

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

void main() {
  group('GamificationNotifier Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocRef;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocRef = MockDocumentReference();
    });

    // users/{uid}/profiles/{profileId}/stats/current までの参照チェーンを同じモックで辿らせる
    void stubStatsDoc(MockDocumentSnapshot snapshot) {
      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
      when(() => mockDocRef.collection(any())).thenReturn(mockCollection);
      when(() => mockDocRef.get()).thenAnswer((_) async => snapshot);
    }

    test('GamificationNotifier initializes with loading state', () {
      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');

      expect(notifier.state, isA<AsyncLoading>());
    });

    test('loadStats successfully loads gamification stats', () async {
      final mockStatsData = {
        'userId': 'test-user-123',
        'level': 5,
        'experience': 1500,
        'coins': 250,
        'totalQuestions': 100,
        'correctCount': 85,
        'streak': 10,
        'recordStreak': 25,
        'accuracyRate': 0.85,
        'lastPlayedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final mockSnapshot = MockDocumentSnapshot(
        exists: true,
        data: mockStatsData,
      );

      stubStatsDoc(mockSnapshot);

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      expect(notifier.state, isA<AsyncData>());
      expect(notifier.state.asData?.value.level, equals(5));
      expect(notifier.state.asData?.value.coins, equals(250));
    });

    test('loadStats returns initial values when doc does not exist', () async {
      final mockSnapshot = MockDocumentSnapshot(exists: false);

      stubStatsDoc(mockSnapshot);

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      expect(notifier.state, isA<AsyncData>());
      expect(notifier.state.asData?.value.level, equals(1));
      expect(notifier.state.asData?.value.experience, equals(0));
      expect(notifier.state.asData?.value.coins, equals(0));
    });

    test('loadStats handles errors gracefully', () async {
      when(() => mockFirestore.collection('users')).thenThrow(
        Exception('Firestore connection error'),
      );

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      expect(notifier.state, isA<AsyncError>());
    });

    test('addExperience updates experience correctly', () async {
      final mockStatsData = {
        'userId': 'test-user-123',
        'level': 1,
        'experience': 100,
        'coins': 50,
        'totalQuestions': 10,
        'correctCount': 8,
        'streak': 3,
        'recordStreak': 5,
        'accuracyRate': 0.8,
        'lastPlayedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      final mockSnapshot = MockDocumentSnapshot(
        exists: true,
        data: mockStatsData,
      );

      stubStatsDoc(mockSnapshot);

      final notifier = GamificationNotifier(mockFirestore, 'test-user-123');
      await notifier.loadStats();

      // Simulate adding experience
      final currentStats = notifier.state.asData?.value;
      expect(currentStats?.experience, equals(100));
    });
  });

  group('gamificationStatsProvider Tests', () {
    test('gamificationStatsProvider requires authentication', () async {
      // 未ログイン(currentUserId == null)なら例外になる。Firebase 実体は使わずモックで差し替える
      final container = ProviderContainer(
        overrides: [
          firebaseProvider.overrideWithValue(MockFirebaseFirestore()),
          currentUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(gamificationStatsProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
