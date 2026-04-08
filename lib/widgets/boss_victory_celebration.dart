import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Boss 击败庆祝动画
/// 全屏战损风格 + 火焰爆炸效果 + 胜利文案
class BossVictoryCelebration extends StatefulWidget {
  final String bossName;
  final int month;
  final int totalDays;
  final VoidCallback onDismiss;

  const BossVictoryCelebration({
    super.key,
    required this.bossName,
    required this.month,
    required this.totalDays,
    required this.onDismiss,
  });

  @override
  State<BossVictoryCelebration> createState() => _BossVictoryCelebrationState();
}

class _BossVictoryCelebrationState extends State<BossVictoryCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  final Random _random = Random();
  final List<_FireParticle> _fireParticles = [];
  final List<_SparkleParticle> _sparkleParticles = [];

  @override
  void initState() {
    super.initState();

    // 主控制器（4秒动画）
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // 震动动画
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.15, curve: Curves.bounceOut),
        ));

    // 渐入动画
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
        ));

    // 缩放动画
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_mainController);

    // 初始化火焰粒子
    for (int i = 0; i < 40; i++) {
      _fireParticles.add(_FireParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 20 + 10,
        color: [
          AppColors.primary,
          AppColors.primaryLight,
          const Color(0xFFFFB74D),
          const Color(0xFFFF9800),
        ][_random.nextInt(4)],
        speed: _random.nextDouble() * 0.2 + 0.1,
        angle: _random.nextDouble() * pi + pi / 2,
      ));
    }

    // 初始化闪光粒子
    for (int i = 0; i < 25; i++) {
      _sparkleParticles.add(_SparkleParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 6 + 3,
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFFFA726),
          Colors.white,
          AppColors.primaryLight,
        ][_random.nextInt(4)],
        speed: _random.nextDouble() * 0.3 + 0.2,
        delay: _random.nextDouble() * 0.3,
      ));
    }

    _mainController.forward();

    // 自动关闭
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        // 震动偏移
        final shakeOffset = _shakeAnimation.value > 0
            ? Offset(
                sin(_shakeAnimation.value * 10 * pi) * 8 * (1 - _shakeAnimation.value),
                cos(_shakeAnimation.value * 10 * pi) * 8 * (1 - _shakeAnimation.value),
              )
            : Offset.zero;

        return Transform.translate(
          offset: shakeOffset,
          child: Opacity(
            opacity: _fadeInAnimation.value.clamp(0.0, 1.0),
            child: Stack(
              children: [
                // 战损背景（暗红色渐变）
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.95),
                        const Color(0xFF2C0700).withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
                // 火焰粒子层
                CustomPaint(
                  size: Size.infinite,
                  painter: _FireParticlePainter(
                    particles: _fireParticles,
                    progress: _mainController.value,
                  ),
                ),
                // 闪光粒子层
                CustomPaint(
                  size: Size.infinite,
                  painter: _SparkleParticlePainter(
                    particles: _sparkleParticles,
                    progress: _mainController.value,
                  ),
                ),
                // 中央内容
                Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value.clamp(0.0, 1.5),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 火焰图标
        Stack(
          alignment: Alignment.center,
          children: [
            // 光晕
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.6),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // 火焰图标
            const Icon(
              Icons.local_fire_department_rounded,
              size: 120,
              color: AppColors.primary,
              shadows: [
                Shadow(
                  color: AppColors.primary,
                  blurRadius: 40,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // VICTORY 文字
        const Text(
          'V I C T O R Y',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 8,
            shadows: [
              Shadow(
                color: AppColors.primary,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 月度标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            '${widget.month}月挑战',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLight,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Boss 名称
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.bossName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // 统计数据
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 20, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text(
              '连续打卡 ${widget.totalDays} 天',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // 战利品提示
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            '获得 +50 XP +20 宠物币',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFD700),
            ),
          ),
        ),
      ],
    );
  }
}

class _FireParticle {
  double x;
  double y;
  double size;
  Color color;
  double speed;
  double angle;

  _FireParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
  });
}

class _FireParticlePainter extends CustomPainter {
  final List<_FireParticle> particles;
  final double progress;

  _FireParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final distance = progress * p.speed * 400;
      final x = (p.x + cos(p.angle) * distance / size.width) * size.width;
      final y = (p.y + sin(p.angle) * distance / size.height) * size.height;

      final opacity = (1.0 - (progress - 0.1).clamp(0.0, 1.0) * 1.2).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size * (1.0 - progress * 0.7), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparkleParticle {
  double x;
  double y;
  double size;
  Color color;
  double speed;
  double delay;

  _SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.delay,
  });
}

class _SparkleParticlePainter extends CustomPainter {
  final List<_SparkleParticle> particles;
  final double progress;

  _SparkleParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (progress < p.delay) continue;
      final adjustedProgress = (progress - p.delay) / (1.0 - p.delay);

      final distance = adjustedProgress * p.speed * 200;
      final x = (p.x * size.width);
      final y = (p.y - distance / size.height) * size.height;

      final opacity = (1.0 - adjustedProgress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // 画菱形闪光
      final path = Path();
      final center = Offset(x, y);
      final halfSize = p.size * (1.0 - adjustedProgress * 0.5) / 2;
      
      path.moveTo(center.dx, center.dy - halfSize);
      path.lineTo(center.dx + halfSize, center.dy);
      path.lineTo(center.dx, center.dy + halfSize);
      path.lineTo(center.dx - halfSize, center.dy);
      path.close();
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 显示 Boss 胜利动画的 Overlay 入口
class BossVictoryOverlay {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, {
    required String bossName,
    required int month,
    required int totalDays,
    required VoidCallback onDismiss,
  }) {
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => BossVictoryCelebration(
        bossName: bossName,
        month: month,
        totalDays: totalDays,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
          onDismiss();
        },
      ),
    );

    Overlay.of(context).insert(_currentEntry!);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
