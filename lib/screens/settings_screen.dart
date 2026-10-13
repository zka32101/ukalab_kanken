import '../views/exam_prep_entry.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app_common_kit/app_common_kit.dart';
import 'package:ukalab_core/cross_promo.dart' show UkalabCrossPromoSection;
import 'package:ukalab_core/daily_goal.dart' show DailyGoalSetting;
import 'package:ukalab_core/reminder.dart' show ReminderSettingsSection;
import 'package:ukalab_core/ui.dart';
import '../data/kanken_data_parts.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../services/handwriting_strictness.dart';
import '../services/learning_transfer_service.dart';
import '../viewmodels/user_viewmodel.dart';
import '../viewmodels/services_provider.dart';
import '../widgets/parental_gate_dialog.dart';
import 'package:kanken/widgets/ukalab_emoji.dart';

/// プロフィールのアイコンに使える絵文字候補
const _avatarIconChoices = ['🙂', '😀', '😊', '🐱', '🐶', '🐻', '🦁', '🐼', '🐸', '🦊', '⭐', '🌸'];

/// 免責表示（うかラボ共通方針・決定2）。ストア説明文の冒頭の注意書きと趣旨を揃える。
const String appDisclaimer =
    '本アプリは、各漢字検定の実施団体・主催者とは一切関係のない、Your Wish が制作した非公式の学習アプリです。\n'
    '試験名は、学習の対象を示すためにのみ使用しています。問題・解説は独自に作成したもので、実際の試験の出題内容や合格を保証するものではありません。\n'
    '最新の試験情報は、実施団体の公式サイトでご確認ください。';

/// 手書き練習の合格ライン（60/65/70/75/80点、初期は65点）。端末内に保存。
class HandwritingStrictnessTile extends ConsumerWidget {
  const HandwritingStrictnessTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(handwritingStrictnessProvider);
    return ListTile(
      leading: const Icon(Icons.edit_outlined),
      title: const Text('手書きの判定'),
      subtitle: const Text('やさしい：ざっくり合っていれば合格\nふつう\nきびしい：形をていねいに'),
      isThreeLine: true,
      trailing: DropdownButton<HandwritingStrictness>(
        value: level,
        items: HandwritingStrictness.values
            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          ref.read(handwritingStrictnessProvider.notifier).set(v);
        },
      ),
    );
  }
}

/// ながら学習モード（片手・読み上げ）の設定。
class HandsFreeSection extends ConsumerWidget {
  const HandsFreeSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(handsFreeProvider);
    final notifier = ref.read(handsFreeProvider.notifier);
    final nagara = KitStrings.of(context).nagara;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.record_voice_over),
          title: const Text('ながら学習モード'),
          subtitle: const Text('大きなボタンを下に寄せて、片手で答えられます（選択式の問題）'),
          value: settings.enabled,
          onChanged: notifier.setEnabled,
        ),
        if (settings.enabled)
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('問題を読み上げる'),
            subtitle: const Text('問題と選択肢を、端末の音声で読み上げます'),
            value: settings.speakQuestion,
            onChanged: notifier.setSpeakQuestion,
          ),
        // ながら学習（自動で進むセッション）の間。ながら学習モードのオン・オフとは別に使える。
        ListTile(
          leading: const Icon(Icons.hourglass_empty),
          title: Text(nagara.settingsThinkSeconds),
          trailing: _secondsDropdown(
            value: settings.thinkSeconds,
            options: HandsFreeSettings.thinkSecondsOptions,
            label: nagara.secondsOption,
            onChanged: notifier.setThinkSeconds,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.coffee),
          title: Text(nagara.settingsBetweenSeconds),
          trailing: _secondsDropdown(
            value: settings.betweenSeconds,
            options: HandsFreeSettings.betweenSecondsOptions,
            label: nagara.secondsOption,
            onChanged: notifier.setBetweenSeconds,
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.skip_next),
          title: Text(nagara.settingsAutoAdvance),
          value: settings.autoAdvance,
          onChanged: notifier.setAutoAdvance,
        ),
      ],
    );
  }
}

Widget _secondsDropdown({
  required int value,
  required List<int> options,
  required String Function(int) label,
  required ValueChanged<int> onChanged,
}) {
  final items = {...options, value}.toList()..sort();
  return DropdownButton<int>(
    value: value,
    items: [for (final v in items) DropdownMenuItem(value: v, child: Text(label(v)))],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

/// 学習の引き継ぎ（機種変更）。コイン・衣装・推しの成長を、ログイン中のアカウントに保存／復元する。
/// 学習の記録やフレンドなどは、同じアカウントでログインすれば自動で引き継がれる。
class TransferSection extends ConsumerWidget {
  const TransferSection({Key? key}) : super(key: key);

  Future<void> _run(BuildContext context, WidgetRef ref, {required bool restore}) async {
    final messenger = ScaffoldMessenger.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      messenger.showSnackBar(const SnackBar(content: Text('ログインしてください')));
      return;
    }
    final transfer = buildKankenTransfer(
      uid: uid,
      coin: ref.read(coinServiceProvider),
      outfit: ref.read(outfitServiceProvider),
    );
    final result = restore ? await transfer.restore() : await transfer.backup();
    if (restore) {
      // 復元した内容を画面に反映する
      await ref.read(coinProvider.notifier).load();
      ref.invalidate(outfitProvider);
    }
    messenger.showSnackBar(SnackBar(content: Text(transferResultMessage(result, restore: restore))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: const Text('いまの状態を保存する'),
          subtitle: const Text('コイン・衣装・推しの成長を、アカウントに保存します'),
          onTap: () => _run(context, ref, restore: false),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('保存した内容を復元する'),
          subtitle: const Text('機種変更したとき、同じアカウントでログインして実行します'),
          onTap: () => _run(context, ref, restore: true),
        ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
        elevation: 0,
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ログインしてください'));
          }
          return ListView(
            children: [
              const _SectionHeader('プロフィール'),
              const _ProfileManagementSection(),
              const Divider(),
              const _SectionHeader('学習'),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('出題除外の条件'),
                subtitle: Text('${user.masteryThreshold}回連続正解したら出題しない'),
                trailing: DropdownButton<int>(
                  value: user.masteryThreshold,
                  items: const [1, 2, 3, 5, 10]
                      .map((n) => DropdownMenuItem(value: n, child: Text('$n回')))
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.updateUser(
                      user.copyWith(masteryThreshold: value),
                    );
                    ref.invalidate(currentUserProvider);
                  },
                ),
              ),
              const HandwritingStrictnessTile(),
              const Divider(),
              const _SectionHeader('ながら学習'),
              const HandsFreeSection(),
              const Divider(),
              const _SectionHeader('リマインダー'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DailyGoalSetting(),
                    SizedBox(height: 16),
                    ReminderSettingsSection(),
                  ],
                ),
              ),
              const Divider(),
              const _SectionHeader('試験に向けて'),
              const ExamPrepSettingsEntry(),
              const Divider(),
              const _SectionHeader('データの引き継ぎ'),
              const TransferSection(),
              const Divider(),
              const _SectionHeader('データの管理'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DataManagementSection(
                  parts: kankenDataParts,
                  description: 'デイリーミッションの記録、自分用メモ、用語集の「覚えた」は、'
                      '書き出し・読み込み・リセットができます（ブックマークは対象外です）。',
                ),
              ),
              const Divider(),
              const _SectionHeader('公開設定'),
              SwitchListTile(
                secondary: const Icon(Icons.leaderboard),
                title: const Text('ランキングに参加する'),
                subtitle: const Text('ニックネームと成績が全員に公開されます'),
                value: user.rankingOptIn,
                onChanged: (value) async {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  await firestoreService.updateUser(
                    user.copyWith(rankingOptIn: value),
                  );
                  ref.invalidate(currentUserProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'ランキングに参加しました' : 'ランキング参加をやめました',
                        ),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              const _SectionHeader('サポート'),
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text('ご意見・不具合報告'),
                subtitle: const Text('バグ報告や改善要望をお寄せください'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedbackFormPage(
                        appName: 'kanken',
                        appVersion: '1.0.1',
                        userId: user.uid,
                      ),
                    ),
                  );
                },
              ),
              UkalabCrossPromoSection(
                currentAppId: 'com.yourwish.ukarulab.kanji',
                isChildDirected: true,
                beforeOpenStore: (context) => requireParentalGate(context),
              ),
              const _SectionHeader('このアプリについて'),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Text(
                  appDisclaimer,
                  style: TextStyle(fontSize: 12, height: 1.6, color: Colors.black54),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// 1つのFirebase Authアカウント配下の複数プロフィール（兄弟等）を
/// 一覧・切り替え・追加・削除するためのセクション。
/// 学習履歴・目標・ランキングはプロフィールごとに完全に分離される。
class _ProfileManagementSection extends ConsumerWidget {
  const _ProfileManagementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return const SizedBox.shrink();

    final profilesAsync = ref.watch(userProfilesProvider(uid));
    final activeProfileId = ref.watch(activeProfileIdProvider) ?? 'default';

    return profilesAsync.when(
      data: (profiles) {
        return Column(
          children: [
            ...profiles.map(
              (profile) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: profile.profileId == activeProfileId
                      ? Colors.blue.shade100
                      : Colors.grey.shade200,
                  child: UkalabEmoji(profile.avatarIcon, size: 20),
                ),
                title: Text(profile.displayName.isEmpty ? '(名前未設定)' : profile.displayName),
                subtitle: Text(profile.currentLevel),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.badge_outlined, size: 20),
                      tooltip: 'フレンドIDを表示',
                      onPressed: () => _showFriendIdDialog(context, uid, profile),
                    ),
                    if (profile.profileId == activeProfileId)
                      const Icon(Icons.check_circle, color: Colors.blue)
                    else
                      TextButton(
                        onPressed: () {
                          ref.read(activeProfileIdProvider.notifier).state = profile.profileId;
                        },
                        child: const Text('切り替え'),
                      ),
                    if (profiles.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _confirmDeleteProfile(
                          context,
                          ref,
                          uid,
                          profile,
                          activeProfileId,
                          profiles,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.add)),
              title: const Text('プロフィールを追加'),
              subtitle: const Text('兄弟など、複数人で使う場合に追加できます'),
              onTap: () => _showAddProfileDialog(context, ref, uid),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('プロフィールの読み込みに失敗しました: $err'),
      ),
    );
  }

  /// フレンド追加・ランキングで使う「フレンドID」を表示する。
  /// friend_provider.dart / leaderboard_provider.dart と同じ
  /// FirestoreService.rankingDocId(uid, profileId) の複合ID。
  void _showFriendIdDialog(BuildContext context, String uid, User profile) {
    final friendId = FirestoreService.rankingDocId(uid, profile.profileId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${profile.displayName}のフレンドID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('このIDを友達に伝えると、フレンド追加やチャレンジができます。'),
            const SizedBox(height: 12),
            SelectableText(
              friendId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: friendId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('フレンドIDをコピーしました')),
              );
            },
            child: const Text('コピー'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    String uid,
    User profile,
    String activeProfileId,
    List<User> profiles,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィールを削除しますか？'),
        content: Text(
          '「${profile.displayName}」の学習履歴・目標・ランキングもすべて削除されます。この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.deleteProfile(uid, profile.profileId);

    // 削除したプロフィールが選択中だった場合は、残りの先頭プロフィールに切り替える
    if (profile.profileId == activeProfileId) {
      final remaining = profiles.where((p) => p.profileId != profile.profileId).toList();
      if (remaining.isNotEmpty) {
        ref.read(activeProfileIdProvider.notifier).state = remaining.first.profileId;
      }
    }

    ref.invalidate(userProfilesProvider(uid));
    ref.invalidate(currentUserProvider);
  }

  Future<void> _showAddProfileDialog(BuildContext context, WidgetRef ref, String uid) async {
    final controller = TextEditingController();
    String selectedIcon = _avatarIconChoices.first;
    String selectedLevel = 'LEVEL_10';
    const levels = [
      'LEVEL_10',
      'LEVEL_9',
      'LEVEL_8',
      'LEVEL_7',
      'LEVEL_6',
      'LEVEL_5',
      'LEVEL_4',
      'LEVEL_3',
      'LEVEL_2_PRE',
      'LEVEL_2',
      'LEVEL_1_PRE',
      'LEVEL_1',
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('プロフィールを追加'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  maxLength: 20,
                  decoration: const InputDecoration(labelText: 'ニックネーム'),
                ),
                const SizedBox(height: 8),
                const Text('アイコン', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: _avatarIconChoices.map((icon) {
                    final selected = icon == selectedIcon;
                    return ChoiceChip(
                      label: UkalabEmoji(icon, size: 18),
                      selected: selected,
                      onSelected: (_) => setState(() => selectedIcon = icon),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('受験級', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedLevel,
                  isExpanded: true,
                  items: levels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedLevel = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  final firestoreService = ref.read(firestoreServiceProvider);
                  final newProfileId = const Uuid().v4();
                  await firestoreService.createUser(
                    User(
                      uid: uid,
                      profileId: newProfileId,
                      displayName: name,
                      avatarIcon: selectedIcon,
                      currentLevel: selectedLevel,
                      streakCount: 0,
                      createdAt: DateTime.now(),
                    ),
                  );

                  ref.invalidate(userProfilesProvider(uid));
                  ref.read(activeProfileIdProvider.notifier).state = newProfileId;

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('追加'),
              ),
            ],
          );
        },
      ),
    );
  }
}
