import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/friend.dart';

void main() {
  group('Friend Model', () {
    test('フレンド情報の生成', () {
      final friend = Friend(
        userId: 'user123',
        userName: 'Taro',
        level: 10,
        experience: 5000,
        accuracyRate: 0.85,
        streak: 5,
        status: FriendStatus.friend,
        addedAt: DateTime.now(),
        lastPlayedAt: DateTime.now(),
      );

      expect(friend.userId, 'user123');
      expect(friend.userName, 'Taro');
      expect(friend.level, 10);
      expect(friend.status, FriendStatus.friend);
      expect(friend.isOnline, true); // 今しがた再生
    });

    test('ステータス表示テキスト (friend)', () {
      final friend = Friend(
        userId: 'user1',
        userName: 'Alice',
        level: 5,
        experience: 2500,
        accuracyRate: 0.8,
        streak: 3,
        status: FriendStatus.friend,
        addedAt: DateTime.now(),
      );

      expect(friend.getStatusLabel(), 'フレンド中');
    });

    test('ステータス表示テキスト (pending)', () {
      final friend = Friend(
        userId: 'user2',
        userName: 'Bob',
        level: 3,
        experience: 1000,
        accuracyRate: 0.7,
        streak: 1,
        status: FriendStatus.pending,
        addedAt: DateTime.now(),
      );

      expect(friend.getStatusLabel(), 'リクエスト待ち');
    });

    test('ステータス表示テキスト (requested)', () {
      final friend = Friend(
        userId: 'user3',
        userName: 'Charlie',
        level: 8,
        experience: 4000,
        accuracyRate: 0.9,
        streak: 7,
        status: FriendStatus.requested,
        addedAt: DateTime.now(),
      );

      expect(friend.getStatusLabel(), 'リクエスト済み');
    });

    test('ステータスアイコン表示', () {
      final friendFriend = Friend(
        userId: 'user1',
        userName: 'Alice',
        level: 5,
        experience: 2500,
        accuracyRate: 0.8,
        streak: 3,
        status: FriendStatus.friend,
        addedAt: DateTime.now(),
      );

      final friendPending = Friend(
        userId: 'user2',
        userName: 'Bob',
        level: 3,
        experience: 1000,
        accuracyRate: 0.7,
        streak: 1,
        status: FriendStatus.pending,
        addedAt: DateTime.now(),
      );

      final friendRequested = Friend(
        userId: 'user3',
        userName: 'Charlie',
        level: 8,
        experience: 4000,
        accuracyRate: 0.9,
        streak: 7,
        status: FriendStatus.requested,
        addedAt: DateTime.now(),
      );

      expect(friendFriend.getStatusIcon(), '✅');
      expect(friendPending.getStatusIcon(), '⏳');
      expect(friendRequested.getStatusIcon(), '📤');
    });

    test('オンライン状態判定 (オンライン)', () {
      final nowMinusMin = DateTime.now().subtract(const Duration(minutes: 10));

      final friend = Friend(
        userId: 'user123',
        userName: 'OnlineUser',
        level: 10,
        experience: 5000,
        accuracyRate: 0.85,
        streak: 5,
        status: FriendStatus.friend,
        addedAt: DateTime.now(),
        lastPlayedAt: nowMinusMin,
      );

      expect(friend.isOnline, true);
    });

    test('オンライン状態判定 (オフライン)', () {
      final lastHour = DateTime.now().subtract(const Duration(hours: 1));

      final friend = Friend(
        userId: 'user123',
        userName: 'OfflineUser',
        level: 10,
        experience: 5000,
        accuracyRate: 0.85,
        streak: 5,
        status: FriendStatus.friend,
        addedAt: DateTime.now(),
        lastPlayedAt: lastHour,
      );

      expect(friend.isOnline, false);
    });

    test('JSON シリアライズ・デシリアライズ', () {
      final now = DateTime.now();
      final original = Friend(
        userId: 'user123',
        userName: 'Taro',
        level: 10,
        experience: 5000,
        accuracyRate: 0.85,
        streak: 5,
        status: FriendStatus.friend,
        addedAt: now,
        lastPlayedAt: now,
      );

      final json = original.toJson();
      final restored = Friend.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.userName, original.userName);
      expect(restored.level, original.level);
      expect(restored.experience, original.experience);
      expect(restored.accuracyRate, original.accuracyRate);
      expect(restored.streak, original.streak);
      expect(restored.status, original.status);
    });

    test('デフォルト値処理', () {
      final json = {'userId': 'user999'};
      final friend = Friend.fromJson(json);

      expect(friend.userId, 'user999');
      expect(friend.userName, 'Unknown');
      expect(friend.level, 1);
      expect(friend.experience, 0);
      expect(friend.accuracyRate, 0.0);
      expect(friend.streak, 0);
      expect(friend.status, FriendStatus.friend);
    });
  });

  group('FriendRequest Model', () {
    test('フレンドリクエスト生成', () {
      final now = DateTime.now();
      final request = FriendRequest(
        requestId: 'req123',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        createdAt: now,
      );

      expect(request.requestId, 'req123');
      expect(request.fromUserId, 'user1');
      expect(request.fromUserName, 'Alice');
      expect(request.toUserId, 'user2');
      expect(request.createdAt, now);
    });

    test('JSON シリアライズ・デシリアライズ', () {
      final now = DateTime.now();
      final original = FriendRequest(
        requestId: 'req123',
        fromUserId: 'user1',
        fromUserName: 'Alice',
        toUserId: 'user2',
        createdAt: now,
      );

      final json = original.toJson();
      final restored = FriendRequest.fromJson(json);

      expect(restored.requestId, original.requestId);
      expect(restored.fromUserId, original.fromUserId);
      expect(restored.fromUserName, original.fromUserName);
      expect(restored.toUserId, original.toUserId);
    });
  });

  group('FriendStatus Enum', () {
    test('全てのステータスが定義されている', () {
      expect(FriendStatus.friend, isNotNull);
      expect(FriendStatus.pending, isNotNull);
      expect(FriendStatus.requested, isNotNull);
    });
  });

  group('フレンド比較ロジック', () {
    test('複数フレンドをレベル順でソート', () {
      final friends = [
        Friend(
          userId: 'user1',
          userName: 'Alice',
          level: 5,
          experience: 2500,
          accuracyRate: 0.8,
          streak: 3,
          status: FriendStatus.friend,
          addedAt: DateTime.now(),
        ),
        Friend(
          userId: 'user2',
          userName: 'Bob',
          level: 10,
          experience: 5000,
          accuracyRate: 0.85,
          streak: 5,
          status: FriendStatus.friend,
          addedAt: DateTime.now(),
        ),
        Friend(
          userId: 'user3',
          userName: 'Charlie',
          level: 3,
          experience: 1000,
          accuracyRate: 0.7,
          streak: 1,
          status: FriendStatus.friend,
          addedAt: DateTime.now(),
        ),
      ];

      friends.sort((a, b) => b.level.compareTo(a.level));

      expect(friends[0].level, 10); // Bob
      expect(friends[1].level, 5);  // Alice
      expect(friends[2].level, 3);  // Charlie
    });

    test('高正答率のフレンドをフィルタリング', () {
      final friends = [
        Friend(
          userId: 'user1',
          userName: 'Alice',
          level: 5,
          experience: 2500,
          accuracyRate: 0.95,
          streak: 3,
          status: FriendStatus.friend,
          addedAt: DateTime.now(),
        ),
        Friend(
          userId: 'user2',
          userName: 'Bob',
          level: 10,
          experience: 5000,
          accuracyRate: 0.70,
          streak: 5,
          status: FriendStatus.friend,
          addedAt: DateTime.now(),
        ),
      ];

      final highAccuracy = friends
          .where((f) => f.accuracyRate >= 0.9)
          .toList();

      expect(highAccuracy.length, 1);
      expect(highAccuracy[0].userName, 'Alice');
    });

    test('オンラインフレンドを抽出', () {
      final nowMinus5Min = DateTime.now().subtract(const Duration(minutes: 5));
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final friends = [
        Friend(
          userId: 'user1',
          userName: 'Alice',
          level: 5,
          experience: 2500,
          accuracyRate: 0.8,
          streak: 3,
          status: FriendStatus.friend,
          addedAt: DateTime.now(),
          lastPlayedAt: nowMinus5Min,
        ),
        Friend(
          userId: 'user2',
          userName: 'Bob',
          level: 10,
          experience: 5000,
          accuracyRate: 0.85,
          streak: 5,
          status: FriendStatus.friend,
          addedAt: DateTime.now(),
          lastPlayedAt: oneHourAgo,
        ),
      ];

      final onlineFriends = friends.where((f) => f.isOnline).toList();

      expect(onlineFriends.length, 1);
      expect(onlineFriends[0].userName, 'Alice');
    });
  });
}
