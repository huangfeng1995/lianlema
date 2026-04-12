class GoalTemplate {
  final String id;
  final String name;
  final String description;
  final String antiVision;
  final String vision;
  final String monthlyBoss;
  final List<String> dailyLevers;
  final String emoji;

  const GoalTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.antiVision,
    required this.vision,
    required this.monthlyBoss,
    required this.dailyLevers,
    required this.emoji,
  });
}

class GoalTemplates {
  static const List<GoalTemplate> all = [
    GoalTemplate(
      id: 'kaoyan',
      name: '考研上岸',
      description: '系统复习，冲刺上岸',
      emoji: '📚',
      antiVision: '每天假装学习，实际在焦虑和后悔中度过',
      vision: '成为研究生，站在更高的起点看世界',
      monthlyBoss: '完成第二轮专业课复习',
      dailyLevers: [
        '📖 专业课：完成一章笔记整理',
        '📝 英语：背50个单词 + 1篇阅读',
        '🏃 运动：每天30分钟（保持精力）',
      ],
    ),
    GoalTemplate(
      id: 'fitness',
      name: '健身减脂',
      description: '科学训练，健康饮食',
      emoji: '💪',
      antiVision: '继续臃肿疲惫，身体越来越差',
      vision: '拥有健康的体态和充沛的精力',
      monthlyBoss: '体脂率降低2%',
      dailyLevers: [
        '🏋️ 力量训练：每次40分钟',
        '🥗 饮食：记录饮食，不喝奶茶',
        '😴 睡眠：23点前睡觉',
      ],
    ),
    GoalTemplate(
      id: 'sleep',
      name: '早起早睡',
      description: '规律作息，精力充沛',
      emoji: '🌙',
      antiVision: '继续熬夜到1点，第二天昏昏沉沉',
      vision: '精力充沛地过好每一天',
      monthlyBoss: '连续30天11点前睡觉',
      dailyLevers: [
        '🌅 起床：闹钟响了就起，不赖床',
        '📵 睡前：手机不放床头，22:30后不刷手机',
        '🧘 晨间：起床后冥想5分钟',
      ],
    ),
    GoalTemplate(
      id: 'deeplearn',
      name: '深度学习',
      description: '专注深入，成为专家',
      emoji: '🧠',
      antiVision: '永远停留在浅层学习，什么都懂一点但都不精',
      vision: '成为某个领域的专家',
      monthlyBoss: '完成一个专题的深度学习',
      dailyLevers: [
        '📚 深度学习：至少2小时专注学习',
        '✍️ 输出：写学习笔记或心得',
        '🔄 复习：定期回顾已学内容',
      ],
    ),
    GoalTemplate(
      id: 'reading',
      name: '养成读书习惯',
      description: '每日阅读，增长见识',
      emoji: '📖',
      antiVision: '书架上的书落灰，知识焦虑但从不学习',
      vision: '成为一个有见识、有思想的人',
      monthlyBoss: '读完2本书',
      dailyLevers: [
        '📖 阅读：每天至少阅读30分钟',
        '📝 笔记：记录触动你的段落',
        '💬 分享：和他人讨论书中内容',
      ],
    ),
  ];
}
