import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Streak 断裂动画
/// 火焰熄灭效果 + 灰色界面 + 断裂提示
class StreakBrokenCelebration extends StatefulWidget {
  final int brokenAtStreak;
  final VoidCallback onDismiss;

  const StreakBrokenCelebration({
    super.key,
    required this.brokenAtStreak,
    required this.onDismiss,
  });

  @override
  State<StreakBrokenCelebration> createState() => _StreakBrokenCelebrationState();
}

class _StreakBrokenCelebrationState extends State<StreakBrokenCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fireFadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _crackProgressAnimation;

  final Random _random = Random();
  final List<_SmokeParticle> _smokeParticles = [];

  @override
  void initState() {
    super.initState();

    // 主控制器（3秒动画）
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    // 渐入动画
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
        ));

    // 火焰熄灭动画
    _fireFadeAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
        ));

    // 缩放动画
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_mainController);

    // 裂痕动画
    _crackProgressAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.2, 0.5, curve: Curves.easeIn),
        ));

    // 初始化烟雾粒子
    for (int i = 0; i < 20; i++) {
      _smokeParticles.add(_SmokeParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 30 + 15,
        speed: _random.nextDouble() * 0.15 + 0.05,
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
        return Opacity(
          opacity: _fadeInAnimation.value.clamp(0.0, 1.0),
          child: Stack(
            children: [
              // 灰化背景
              ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1 - _fireFadeAnimation.value * 0.7, 0,
                ]),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5 * _fadeInAnimation.value),
                ),
              ),
              // 裂痕效果
              if (_crackProgressAnimation.value > 0)
                CustomPaint(
                  size: Size.infinite,
                  painter: _CrackPainter(
                    progress: _crackProgressAnimation.value,
                  ),
                ),
              // 烟雾粒子层
              CustomPaint(
                size: Size.infinite,
                painter: _SmokeParticlePainter(
                  particles: _smokeParticles,
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
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 火焰图标（熄灭动画）
        Stack(
          alignment: Alignment.center,
          children: [
            // 灰色火焰
            Opacity(
              opacity: 1.0 - _fireFadeAnimation.value,
              child: const Icon(
                Icons.local_fire_department_rounded,
                size: 100,
                color: AppColors.textLight,
              ),
            ),
            // 原本火焰
            Opacity(
              opacity: _fireFadeAnimation.value,
              child: const Icon(
                Icons.local_fire_department_rounded,
                size: 100,
                color: AppColors.primary,
                shadows: [
                  Shadow(
                    color: AppColors.primary,
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            // 裂痕
            Opacity(
              opacity: _crackProgressAnimation.value,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  width: 120,
                  height: 4,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 断裂文字
        const Text(
          'STREAK BROKEN',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.textLight,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 连续天数
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '连续 ${widget.brokenAtStreak} 天',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 鼓励文案
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            '没关系，再来一次会更好',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmokeParticle {
  double x;
  double y;
  double size;
  double speed;

  _SmokeParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class _SmokeParticlePainter extends CustomPainter {
  final List<_SmokeParticle> particles;
  final double progress;

  _SmokeParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (progress > 0.2 && progress < 0.8)
          ? (progress - 0.2) * 2.5 * (1.0 - (progress - 0.2) / 0.6)
          : 0.0;

      final yPos = (p.y - progress * p.speed * size.height * 0.5) % size.height;

      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawOval(
        Rect.fromLTWH(
          p.x * size.width,
          yPos,
          p.size,
          p.size * 1.5,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SmokeParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CrackPainter extends CustomPainter {
  final double progress;

  _CrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A).withValues(alpha: 0.8 * progress)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 主裂痕
    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.5);
    
    double currentX = size.width * 0.3;
    double currentY = size.height * 0.5;
    
    for (int i = 0; i < 10; i++) {
      if (i / 10 > progress) break;
      
      currentX += (Random().nextDouble() - 0.3) * 30;
      currentY += (Random().nextDouble() - 0.5) * 15;
      path.lineTo(currentX, currentY);
    }
    
    // 分叉
    final forkPath = Path();
    forkPath.moveTo(size.width * 0.5, size.height * 0.52);
    forkPath.lineTo(size.width * 0.6, size.height * 0.45);
    
    canvas.drawPath(path, paint);
    if (progress > 0.5) {
      canvas.drawPath(forkPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 显示 Streak 断裂动画的 Overlay 入口
class StreakBrokenOverlay {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, {
    required int brokenAtStreak,
    required VoidCallback onDismiss,
  }) {
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => StreakBrokenCelebration(
        brokenAtStreak: brokenAtStreak,
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
