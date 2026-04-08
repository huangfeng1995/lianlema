import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/confetti_celebration.dart';

class BossHpBar extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final String bossName;
  final int currentMonth;

  const BossHpBar({
    super.key,
    required this.currentHp,
    required this.maxHp,
    required this.bossName,
    required this.currentMonth,
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

    // 击败时触发彩纸动画
    if (widget.currentHp <= 0 && !_hasShownConfetti) {
      Future.delayed(Duration.zero, () {
      ConfettiOverlay.show(context);
      _hasShownConfetti = true;
    });
    }
  }

  @override
  void didUpdateWidget(covariant BossHpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // HP 从 >0 变为 0 时触发彩纸
    if (oldWidget.currentHp > 0 && widget.currentHp <= 0 && !_hasShownConfetti) {
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
    final double progress = (widget.currentHp / widget.maxHp).clamp(0.0, 1.0);
    final bool isLowHp = progress <= 0.3 && progress > 0;
    final bool isDefeated = widget.currentHp <= 0;

    // 进度条颜色
    final Color hpColor = isDefeated
        ? const Color(0xFF228B22)
        : isLowHp
            ? const Color(0xFFFF4500)
            : const Color(0xFF8B0000);

    // 边框颜色
    final Color borderColor = isDefeated
        ? const Color(0xFF228B22).withOpacity(0.5)
        : isLowHp
            ? const Color(0xFFFF4500).withOpacity(0.5)
            : const Color(0xFF8B0000).withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(widget.currentMonth)}：${widget.bossName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isDefeated
                    ? '✅ Boss 已击败'
                    : 'HP ${widget.currentHp}/${widget.maxHp}',
                style: TextStyle(
                  color: isDefeated
                      ? const Color(0xFF228B22)
                      : isLowHp
                          ? const Color(0xFFFF4500)
                          : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // HP 进度条
          AnimatedBuilder(
            animation: _blinkController,
            builder: (context, child) {
              final double opacity = isLowHp ? (0.6 + 0.4 * _blinkController.value) : 1.0;
              return Opacity(
                opacity: opacity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 12,
                    width: double.infinity,
                    color: const Color(0xFF1A1A1A),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(end: progress),
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [hpColor, hpColor.withOpacity(0.8)],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return '1月';
      case 2: return '2月';
      case 3: return '3月';
      case 4: return '4月';
      case 5: return '5月';
      case 6: return '6月';
      case 7: return '7月';
      case 8: return '8月';
      case 9: return '9月';
      case 10: return '10月';
      case 11: return '11月';
      case 12: return '12月';
      default: return '$month月';
    }
  }
}
