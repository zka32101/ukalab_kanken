import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../viewmodels/index.dart';
import 'package:kanken/widgets/text_fit.dart';

/// コレクション・バッジ表示画面
class CollectionBadgeScreen extends ConsumerWidget {
  const CollectionBadgeScreen({Key? key}) : super(key: key);

  static const Map<String, BadgeInfo> badgeInfoMap = {
    'LEVEL_10': BadgeInfo(
      name: '10級マスター',
      description: '小学1年生の漢字をマスター',
      color: Colors.blue,
      icon: Icons.school,
      conditionText: '10級の模擬試験に合格',
    ),
    'LEVEL_9': BadgeInfo(
      name: '9級マスター',
      description: '小学2年生の漢字をマスター',
      color: Colors.purple,
      icon: Icons.school,
      conditionText: '9級の模擬試験に合格',
    ),
    'LEVEL_8': BadgeInfo(
      name: '8級マスター',
      description: '小学3年生の漢字をマスター',
      color: Colors.green,
      icon: Icons.school,
      conditionText: '8級の模擬試験に合格',
    ),
    'LEVEL_7': BadgeInfo(
      name: '7級マスター',
      description: '小学4年生の漢字をマスター',
      color: Colors.orange,
      icon: Icons.school,
      conditionText: '7級の模擬試験に合格',
    ),
    'LEVEL_6': BadgeInfo(
      name: '6級マスター',
      description: '小学5年生の漢字をマスター',
      color: Colors.red,
      icon: Icons.school,
      conditionText: '6級の模擬試験に合格',
    ),
    'LEVEL_5': BadgeInfo(
      name: '5級マスター',
      description: '小学6年生の漢字をマスター',
      color: Colors.amber,
      icon: Icons.school,
      conditionText: '5級の模擬試験に合格',
    ),
    'LEVEL_4': BadgeInfo(
      name: '4級マスター',
      description: '中学校程度の漢字をマスター',
      color: Colors.teal,
      icon: Icons.school,
      conditionText: '4級の模擬試験に合格',
    ),
    'LEVEL_3': BadgeInfo(
      name: '3級マスター',
      description: '中学校卒業程度の漢字をマスター',
      color: Colors.indigo,
      icon: Icons.school,
      conditionText: '3級の模擬試験に合格',
    ),
    'LEVEL_2_PRE': BadgeInfo(
      name: '準2級マスター',
      description: '高校在学程度の漢字をマスター',
      color: Colors.deepPurple,
      icon: Icons.school,
      conditionText: '準2級の模擬試験に合格',
    ),
    'LEVEL_2': BadgeInfo(
      name: '2級マスター',
      description: '高校卒業・大学・一般程度の漢字をマスター',
      color: Colors.brown,
      icon: Icons.school,
      conditionText: '2級の模擬試験に合格',
    ),
    'LEVEL_1_PRE': BadgeInfo(
      name: '準1級マスター',
      description: '大学・一般程度の漢字をマスター',
      color: Colors.pink,
      icon: Icons.school,
      conditionText: '準1級の模擬試験に合格',
    ),
    'LEVEL_1': BadgeInfo(
      name: '1級マスター',
      description: '大学・一般程度の漢字をマスター',
      color: Colors.blueGrey,
      icon: Icons.school,
      conditionText: '1級の模擬試験に合格',
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const FitTitle('コレクション')),
        body: const Center(child: Text('ユーザーログインが必要です')),
      );
    }

    // ユーザーの獲得バッジを取得
    final collectionBadgesAsync = ref.watch(
      FutureProvider((async) async {
        final firestoreService = ref.watch(firestoreServiceProvider);
        return await firestoreService.getUserBadges(uid);
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const FitTitle('コレクション'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: collectionBadgesAsync.when(
        data: (badges) {
          final acquiredLevels = badges.map((b) => b.level).toSet();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー：獲得数
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                          children: [
                            Text(
                              '${badges.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '獲得済みバッジ',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        ),
                        Expanded(
                          child: Column(
                          children: [
                            Text(
                              '${6 - badges.length}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '残り',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 獲得済みバッジセクション
                  if (badges.isNotEmpty) ...[
                    const Text(
                      '獲得済み',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: gridColumns(context, 3),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: gridColumnsAspect(context, 3, 1.0),
                      children: badges.map((badge) {
                        final badgeInfo =
                            badgeInfoMap[badge.level];
                        return _buildAcquiredBadgeCard(
                          context,
                          badgeInfo,
                          badge,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 未獲得バッジセクション
                  if (acquiredLevels.length < 6) ...[
                    const Text(
                      '未獲得',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: gridColumns(context, 3),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: gridColumnsAspect(context, 3, 1.0),
                      children: badgeInfoMap.entries
                          .where((e) => !acquiredLevels.contains(e.key))
                          .map((entry) {
                        return _buildLockedBadgeCard(context, entry.value);
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 実績バッジ（級に紐づかないもの。例：継続学習ストリーク）
                  const Text(
                    '実績バッジ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: gridColumns(context, 3),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: gridColumnsAspect(context, 3, 1.0),
                    children: streakBadgeThresholds.entries.map((entry) {
                      final info = entry.value;
                      final acquired = badges.any((b) => b.badgeId == info.$1);
                      final achievementInfo = BadgeInfo(
                        name: info.$2,
                        description: info.$3,
                        color: Colors.deepOrange,
                        icon: Icons.local_fire_department,
                        conditionText: '${entry.key}日連続で学習する',
                      );
                      return acquired
                          ? _buildAcquiredBadgeCard(
                              context,
                              achievementInfo,
                              badges.firstWhere((b) => b.badgeId == info.$1),
                            )
                          : _buildLockedBadgeCard(context, achievementInfo);
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }

  Widget _buildAcquiredBadgeCard(
    BuildContext context,
    BadgeInfo? badgeInfo,
    CollectionBadge badge,
  ) {
    if (badgeInfo == null) return Container();

    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badgeInfo, badge),
      child: Container(
        decoration: BoxDecoration(
          color: badgeInfo.color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeInfo.color[300]!),
          boxShadow: [
            BoxShadow(
              color: badgeInfo.color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              badgeInfo.icon,
              size: 40,
              color: badgeInfo.color[600],
            ),
            const SizedBox(height: 8),
            Text(
              badgeInfo.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeInfo.color[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedBadgeCard(
    BuildContext context,
    BadgeInfo badgeInfo,
  ) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(context, badgeInfo, null),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              badgeInfo.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    BadgeInfo badgeInfo,
    CollectionBadge? badge,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: badgeInfo.color[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: badgeInfo.color[300]!,
              width: 2,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // バッジアイコン
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: badgeInfo.color[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badgeInfo.icon,
                  size: 50,
                  color: badgeInfo.color[600],
                ),
              ),
              const SizedBox(height: 16),

              // バッジ名
              Text(
                badgeInfo.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: badgeInfo.color[900],
                ),
              ),
              const SizedBox(height: 8),

              // 説明
              Text(
                badgeInfo.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // 条件
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeInfo.color[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '獲得条件',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badgeInfo.conditionText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // 作成日時（バッジの作成日）
              if (badge != null) ...[
                const SizedBox(height: 12),
                Text(
                  '作成日: ${badge.createdAt.year}年${badge.createdAt.month}月${badge.createdAt.day}日',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // 閉じるボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badgeInfo.color[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '閉じる',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class BadgeInfo {
  final String name;
  final String description;
  final MaterialColor color;
  final IconData icon;
  final String conditionText;

  const BadgeInfo({
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.conditionText,
  });
}
