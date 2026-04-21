import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/confetti_celebration.dart';

class BossHpBar extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final String bossName;
  final int currentMonth;
  final int checkInDays;
  final List<CheckIn> checkIns;
  final VoidCallback? onTap;

  const BossHpBar({
    super.key,
    required this.currentHp,
    required this.maxHp,
    required this.bossName,
    required this.currentMonth,
    this.checkInDays = 0,
    this.checkIns = const [],
    this.onTap,
  });

  @override
  State<BossHpBar> createState() => _BossHpBarState();
}

class _BossHpBarState extends State<BossHpBar> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  bool _hasShownConfetti = false;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    if (widget.currentHp <= 0 && !_hasShownConfetti) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ConfettiOverlay.show(context);
          _hasShownConfetti = true;
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant BossHpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentHp > 0 && widget.currentHp <= 0 && !_hasShownConfetti && mounted) {
      ConfettiOverlay.show(context);
      _hasShownConfetti = true;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final checkedDays = widget.checkIns
        .where((c) => c.date.year == now.year && c.date.month == widget.currentMonth)
        .map((c) => c.date.day)
        .toSet();

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                const Text(
                  '本月挑战',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${checkedDays.length}/${DateTime(now.year, now.month + 1, 0).day}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: const Color(0xFFF5A623).withValues(alpha: 0.6)),
              ],
            ),
            const SizedBox(height: 12),
            // 任务列表
            ...widget.bossName.split('；').where((s) => s.trim().isNotEmpty).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      task.trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
