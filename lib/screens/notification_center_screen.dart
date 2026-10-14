import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notifications.dart';
import '../providers/notification_provider.dart';
import '../widgets/text_fit.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(notificationStatsProvider);
    final notifications = ref.watch(allNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('通知センター'),
        centerTitle: true,
        elevation: 0,
        actions: [
          stats.when(
            data: (data) {
              if (data == null || data.unreadCount == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('すべて既読'),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await ref
                          .read(notificationProvider.notifier)
                          .markAllAsRead();
                    },
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: notifications.when(
        data: (notificationList) {
          if (notificationList.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notificationList.length,
            itemBuilder: (context, index) {
              final notification = notificationList[index];
              return _buildNotificationTile(context, ref, notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('エラーが発生しました'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => _showSettingsDialog(context, ref),
        tooltip: '通知設定',
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '通知がありません',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'すべてチェック済みです',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                  children: [
                    // 通知アイコン
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification.type),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(notification.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // タイトル
                    Expanded(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(notification.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    ),
                  ],
                ),
                ),
                // 未読インジケーター
                if (!notification.isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // メッセージ
            Text(
              notification.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // アクションボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(notificationProvider.notifier)
                        .deleteNotification(notification.notificationId);
                  },
                  child: const Text('削除'),
                ),
                const SizedBox(width: 8),
                if (!notification.isRead)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await ref
                          .read(notificationProvider.notifier)
                          .markAsRead(notification.notificationId);
                    },
                    child: const Text('既読'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'battle_invite':
        return Colors.purple;
      case 'battle_result':
        return Colors.orange;
      case 'exam_result':
        return Colors.blue;
      case 'new_badge':
        return Colors.amber;
      case 'friend_request':
        return Colors.pink;
      case 'friend_accepted':
        return Colors.green;
      case 'achievement':
        return Colors.red;
      case 'daily_challenge':
        return Colors.cyan;
      case 'review_due':
        return Colors.teal;
      case 'goal_achieved':
        return Colors.deepPurple;
      case 'challenge_received':
        return Colors.pinkAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'battle_invite':
        return Icons.sports_esports;
      case 'battle_result':
        return Icons.emoji_events;
      case 'exam_result':
        return Icons.assignment;
      case 'new_badge':
        return Icons.star;
      case 'friend_request':
        return Icons.person_add;
      case 'friend_accepted':
        return Icons.person_add_alt_1;
      case 'achievement':
        return Icons.emoji_events;
      case 'daily_challenge':
        return Icons.today;
      case 'review_due':
        return Icons.repeat;
      case 'goal_achieved':
        return Icons.flag_circle;
      case 'challenge_received':
        return Icons.sports_kabaddi;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  Future<void> _showSettingsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final settings = ref.watch(notificationSettingsProvider);

    await showDialog(
      context: context,
      builder: (context) => settings.when(
        data: (setting) {
          if (setting == null) {
            return AlertDialog(
              scrollable: true,
              title: const Text('通知設定'),
              content: const Text('設定を読み込めませんでした'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            );
          }

          return _NotificationSettingsDialog(
            settings: setting,
            onSave: (updatedSettings) {
              ref
                  .read(notificationProvider.notifier)
                  .updateNotificationSettings(updatedSettings);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定を保存しました')),
              );
            },
          );
        },
        loading: () => AlertDialog(
          content: const CircularProgressIndicator(),
        ),
        error: (_, __) => AlertDialog(
          title: const Text('エラー'),
          content: const Text('設定の読み込みに失敗しました'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsDialog extends StatefulWidget {
  final NotificationSettings settings;
  final Function(NotificationSettings) onSave;

  const _NotificationSettingsDialog({
    required this.settings,
    required this.onSave,
  });

  @override
  State<_NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<_NotificationSettingsDialog> {
  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('通知設定'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSettingTile(
              '対戦招待',
              _settings.battleInviteEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(battleInviteEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              '対戦結果',
              _settings.battleResultEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(battleResultEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              '試験結果',
              _settings.examResultEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(examResultEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              'バッジ獲得',
              _settings.badgeEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(badgeEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              'フレンド要求',
              _settings.friendRequestEnabled,
              (value) {
                setState(() {
                  _settings =
                      _settings.copyWith(friendRequestEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              '実績達成',
              _settings.achievementEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(achievementEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              'デイリーチャレンジ',
              _settings.dailyChallengeEnabled,
              (value) {
                setState(() {
                  _settings =
                      _settings.copyWith(dailyChallengeEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              '復習リマインダー',
              _settings.reviewReminderEnabled,
              (value) {
                setState(() {
                  _settings =
                      _settings.copyWith(reviewReminderEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              '目標達成',
              _settings.goalAchievedEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(goalAchievedEnabled: value);
                });
              },
            ),
            const Divider(),
            _buildSettingTile(
              'サウンド',
              _settings.soundEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(soundEnabled: value);
                });
              },
            ),
            _buildSettingTile(
              'バイブレーション',
              _settings.vibrationEnabled,
              (value) {
                setState(() {
                  _settings = _settings.copyWith(vibrationEnabled: value);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () => widget.onSave(_settings),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
