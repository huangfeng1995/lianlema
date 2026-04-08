import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 等级提升庆祝动画
/// 全屏遮罩 + 大字等级展示 + 缩放/脉冲动画 + 光效粒子
class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 缩放动画控制器（0.5秒启动，1.5秒保持，0.5秒消失）
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_scaleController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_scaleController);

    // 粒子动画控制器
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // 初始化粒子
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 8 + 4,
        color: [
          AppColors.primary,
          AppColors.primaryLight,
          const Color(0xFFFFD700),
          Colors.white,
        ][_random.nextInt(4)],
        speed: _random.nextDouble() * 0.3 + 0.2,
        angle: _random.nextDouble() * 2 * pi,
      ));
    }

    _scaleController.forward();
    _particleController.forward();

    // 自动关闭
    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _particleController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value.clamp(0.0, 1.0),
          child: Stack(
            children: [
              // 背景遮罩
              Container(
                color: Colors.black.withValues(alpha: 0.7 * _opacityAnimation.value),
              ),
              // 粒子层
              CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
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
        // 光晕效果
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.4),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: -180),
        // 等级数字
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LV',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 4,
                ),
              ),
              Text(
                '${widget.newLevel}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 升级文案
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            '等级提升！',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '已解锁更多宠物外观',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  Color color;
  double speed;
  double angle;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final distance = progress * p.speed * 200;
      final x = (p.x + cos(p.angle) * distance / size.width) * size.width;
      final y = (p.y + sin(p.angle) * distance / size.height) * size.height;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 显示等级提升动画的 Overlay 入口
class LevelUpOverlay {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, int newLevel) {
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => LevelUpCelebration(
        newLevel: newLevel,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
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
