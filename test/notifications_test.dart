import 'package:flutter_test/flutter_test.dart';
import 'package:kanken/models/notifications.dart';

void main() {
  group('AppNotification Tests', () {
    test('AppNotification can be created', () {
      final notification = AppNotification(
        notificationId: 'notif1',
        userId: 'user1',
        type: 'battle_invite',
        title: '対戦招待',
        message: '太郎があなたを対戦に招待しました',
        relatedId: 'room1',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(notification.notificationId, equals('notif1'));
      expect(notification.type, equals('battle_invite'));
      expect(notification.isRead, isFalse);
    });

    test('JSON round-trip serialization', () {
      final original = AppNotification(
        notificationId: 'notif1',
        userId: 'user1',
        type: 'battle_invite',
        title: '対戦招待',
        message: '太郎があなたを対戦に招待しました',
        relatedId: 'room1',
        isRead: false,
        createdAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson = AppNotification.fromJson(json);

      expect(fromJson.notificationId, equals(original.notificationId));
      expect(fromJson.type, equals(original.type));
      expect(fromJson.title, equals(original.title));
      expect(fromJson.isRead, equals(original.isRead));
    });
  });

  group('NotificationSettings Tests', () {
    test('NotificationSettings can be created with defaults', () {
      final settings = NotificationSettings(
        userId: 'user1',
        updatedAt: DateTime.now(),
      );

      expect(settings.userId, equals('user1'));
      expect(settings.battleInviteEnabled, isTrue);
      expect(settings.soundEnabled, isTrue);
      expect(settings.vibrationEnabled, isTrue);
    });

    test('NotificationSettings copyWith works correctly', () {
      final original = NotificationSettings(
        userId: 'user1',
        battleInviteEnabled: true,
        battleResultEnabled: true,
        updatedAt: DateTime.now(),
      );

      final updated =
          original.copyWith(battleInviteEnabled: false);

      expect(original.battleInviteEnabled, isTrue);
      expect(updated.battleInviteEnabled, isFalse);
      expect(updated.battleResultEnabled, isTrue);
    });

    test('JSON round-trip serialization', () {
      final original = NotificationSettings(
        userId: 'user1',
        battleInviteEnabled: false,
        soundEnabled: false,
        updatedAt: DateTime(2026, 9, 13),
      );

      final json = original.toJson();
      final fromJson =
          NotificationSettings.fromJson(json);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.battleInviteEnabled, equals(original.battleInviteEnabled));
      expect(fromJson.soundEnabled, equals(original.soundEnabled));
    });
  });

  group('NotificationStats Tests', () {
    test('NotificationStats can be created', () {
      final stats = NotificationStats(
        userId: 'user1',
        unreadCount: 5,
        totalCount: 20,
        battleInviteCount: 2,
        friendRequestCount: 3,
        achievementCount: 1,
      );

      expect(stats.userId, equals('user1'));
      expect(stats.unreadCount, equals(5));
      expect(stats.hasUnread, isTrue);
    });

    test('hasUnread property works correctly', () {
      final statsWithUnread = NotificationStats(
        userId: 'user1',
        unreadCount: 5,
        totalCount: 20,
        battleInviteCount: 2,
        friendRequestCount: 3,
        achievementCount: 1,
      );

      final statsNoUnread = NotificationStats(
        userId: 'user1',
        unreadCount: 0,
        totalCount: 20,
        battleInviteCount: 0,
        friendRequestCount: 0,
        achievementCount: 0,
      );

      expect(statsWithUnread.hasUnread, isTrue);
      expect(statsNoUnread.hasUnread, isFalse);
    });

    test('JSON round-trip serialization', () {
      final original = NotificationStats(
        userId: 'user1',
        unreadCount: 5,
        totalCount: 20,
        battleInviteCount: 2,
        friendRequestCount: 3,
        achievementCount: 1,
      );

      final json = original.toJson();
      final fromJson = NotificationStats.fromJson(json);

      expect(fromJson.userId, equals(original.userId));
      expect(fromJson.unreadCount, equals(original.unreadCount));
      expect(fromJson.totalCount, equals(original.totalCount));
    });
  });

  group('NotificationType Enum Tests', () {
    test('NotificationType has correct values', () {
      expect(NotificationType.battleInvite.value, equals('battle_invite'));
      expect(NotificationType.battleInvite.label, equals('オンライン対戦招待'));
      expect(NotificationType.friendRequest.value, equals('friend_request'));
      expect(NotificationType.achievement.value, equals('achievement'));
    });

    test('NotificationType enum values are consistent', () {
      const battleType = NotificationType.battleInvite;
      expect(battleType.value, equals('battle_invite'));
      expect(battleType.label.isNotEmpty, isTrue);
    });
  });
}
