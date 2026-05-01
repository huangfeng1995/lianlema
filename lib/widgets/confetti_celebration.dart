import 'dart:math';
import 'package:flutter/material.dart';

/// 单个彩纸粒子数据
class ConfettiParticle {
  Offset position;
  Offset velocity;
  double rotation;
  double rotationSpeed;
  Color color;
  double size;
  double opacity;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
    this.opacity = 1.0,
  });
}

/// 彩纸Painter
class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity( p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.position.dx, p.position.dy);
      canvas.rotate(p.rotation);

      // 绘制椭圆粒子（更像彩纸）
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// 全屏彩纸庆祝动画Widget
class ConfettiCelebration extends StatefulWidget {
  final VoidCallback? onComplete;

  const ConfettiCelebration({super.key, this.onComplete});

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<ConfettiParticle> _particles = [];
  final Random _random = Random();
  Size _screenSize = Size.zero;

  // 品牌色
  static const List<Color> _colors = [
    Color(0xFFFF6B35), // 橙
    Color(0xFFFFD700), // 金
    Color(0xFFFFFFFF), // 白
    Color(0xFFFF69B4), // 粉色
    Color(0xFFE0B0FF), // 浅紫
    Color(0xFFFFB347), // 浅橙
    Color(0xFF87CEEB), // 浅蓝
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  void _initParticles(Size size) {
    if (_particles.isNotEmpty) return;
    const particleCount = 65;
    _particles = List.generate(particleCount, (i) {
      final startX = _random.nextDouble() * size.width;
      final vx = (_random.nextDouble() - 0.5) * 200;
      final vy = 150 + _random.nextDouble() * 350;
      final rotSpeed = (_random.nextDouble() - 0.5) * 10;

      return ConfettiParticle(
        position: Offset(startX, -20 - _random.nextDouble() * 100),
        velocity: Offset(vx, vy),
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: rotSpeed,
        color: _colors[_random.nextInt(_colors.length)],
        size: 6 + _random.nextDouble() * 8,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    _initParticles(_screenSize);

    final size = _screenSize;
    const dt = 1 / 60;
    final t = _controller.value;

    for (final p in _particles) {
      // 重力加速度
      const gravity = 600.0;
      // 水平空气阻力
      const dampingX = 0.995;

      // 横向飘动（正弦波模拟空气阻力左右摆动）
      final drift = sin(t * 8 + p.position.dy * 0.01) * 40;

      p.velocity = Offset(
        (p.velocity.dx + drift) * dampingX,
        p.velocity.dy + gravity * dt,
      );

      p.position = Offset(
        p.position.dx + p.velocity.dx * dt,
        p.position.dy + p.velocity.dy * dt,
      );

      p.rotation += p.rotationSpeed * dt;

      // 超过屏幕70%高度后淡出
      if (p.position.dy > size.height * 0.7) {
        final fadeProgress = ((p.position.dy - size.height * 0.7) /
                             (size.height * 0.3)).clamp(0.0, 1.0);
        p.opacity = 1.0 - fadeProgress;
      } else {
        p.opacity = 1.0;
      }
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(_particles),
          size: size,
        ),
      ),
    );
  }
}

/// 彩纸动画Overlay工具
class ConfettiOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context) {
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (context) => ConfettiCelebration(
        onComplete: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    Overlay.of(context).insert(_entry!);
  }
}
