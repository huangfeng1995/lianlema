import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/pet_service.dart';

class EncouragementStatsCard extends StatelessWidget {
  const EncouragementStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 从 PetService 获取统计数据
    final stats = PetService.instance.getEncouragementStats();
    final records = PetService.instance.getEncouragementRecords();

    // 转换为列表并排序（按有效性从高到低）
    final sortedStats = EncouragementType.values.map((type) {
      return stats[type.index] ?? EncouragementStats(type: type);
    }).toList()
      ..sort((a, b) => b.effectiveness.compareTo(a.effectiveness));

    // 找出最有效的类型
    final topType = sortedStats.isNotEmpty ? sortedStats.first : null;

    // 获取推荐类型标签
    String getInsightText(EncouragementType type, double effectiveness) {
      if (effectiveness >= 0.7) return '对你最有效';
      if (effectiveness >= 0.5) return '效果不错';
      if (effectiveness >= 0.3) return '可以试试';
      return '效果一般';
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(Icons.insights, size: 18, color: AppColors.primary),
                ),
              ),
              SizedBox(width: 12),
              Text(
                '激励效果分析',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // 如果没有数据
          if (records.isEmpty) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  '暂无数据\n开始打卡后这里会显示分析',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            // 进度条列表
            ...sortedStats.map((stat) {
              final percent = (stat.effectiveness * 100).round();
              final label = stat.type.label;
              final emoji = stat.type.emoji;
              final insight = getInsightText(stat.type, stat.effectiveness);

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(emoji, style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                        Spacer(),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: percent >= 70
                                ? AppColors.primary
                                : percent >= 40
                                    ? AppColors.textSecondary
                                    : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: stat.effectiveness.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: percent >= 70
                                    ? [AppColors.primary, Color(0xFFFF6B35)]
                                    : percent >= 40
                                        ? [AppColors.primary.withValues(alpha: 0.7), AppColors.primary]
                                        : [AppColors.textLight.withValues(alpha: 0.5), AppColors.textLight],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      insight,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // 结论
            if (topType != null && topType.effectiveness >= 0.5) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${topType.type.emoji} ${topType.type.label}对你最有效！炭炭会用这种方式督促你 💪',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
