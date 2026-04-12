import 'package:share_plus/share_plus.dart';
import '../utils/storage_service.dart';

class ShareService {
  static Future<void> shareCheckIn() async {
    final storage = await StorageService.getInstance();
    final stats = storage.getUserStats();
    final boss = storage.getMonthlyBoss();
    final levers = storage.getDailyLevers();

    // 生成分享文字
    final text = _generateShareText(
      stats.streak,
      stats.totalCheckIns,
      levers,
      boss?.content,
    );

    // 分享
    await Share.share(
      text,
      subject: '我在练了吗坚持打卡',
    );
  }

  static String _generateShareText(
    int streak,
    int total,
    List<Map<String, String>> levers,
    String? bossName,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('🔥 我在「练了吗」坚持打卡第 $streak 天！');
    buffer.writeln('');

    // 今日杠杆
    if (levers.isNotEmpty) {
      buffer.writeln('🎯 今日目标：');
      for (final lever in levers.take(3)) {
        final plan = lever['plan'] ?? '';
        if (plan.isNotEmpty) {
          buffer.writeln('• $plan');
        }
      }
    }

    // Boss
    if (bossName != null && bossName.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('⚔️ 本月挑战：$bossName');
    }

    buffer.writeln('');
    buffer.writeln('#练了吗 #自我提升 #坚持');

    return buffer.toString();
  }

  /// 分享成就解锁
  static Future<void> shareAchievement(String badgeName, String emoji) async {
    final text = '''
$emoji 我在「练了吗」解锁了「$badgeName」！

坚持打卡，成为更好的自己 💪

#练了吗 #成就解锁
''';
    await Share.share(text, subject: '练了吗成就解锁');
  }

  /// 分享连续记录
  static Future<void> shareStreak(int streak) async {
    String milestone;
    if (streak >= 100) {
      milestone = '百日大师';
    } else if (streak >= 30) {
      milestone = '月度达人';
    } else if (streak >= 7) {
      milestone = '一周坚持';
    } else {
      milestone = '$streak 天连续';
    }

    final text = '''
🔥 我在「练了吗」已经$milestone！

坚持，是一种品质 💪

#练了吗 #坚持打卡
''';
    await Share.share(text, subject: '练了吗连续记录');
  }
}
