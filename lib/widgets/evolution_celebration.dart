import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/pet_models.dart';

/// 宠物外观进化庆祝动画
/// 全屏遮罩 + 进化光效 + 阶段展示
class EvolutionCelebration extends StatefulWidget {
  final int newStage; // 1-6
  final String petEmoji;
  final VoidCallback onDismiss;

  const EvolutionCelebration({
    super.key,
    required this.newStage,
    required this.petEmoji,
    required this.onDismiss,
  });

  @override
  State<EvolutionCelebration> createState() => _EvolutionCelebrationState();
}

class _EvolutionCelebrationState extends State<EvolutionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _flashController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flashAnimation;
  late Animation<double> _rotationAnimation;

  final List<_Spark> _sparks = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 主动画控制器
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // 闪光动画控制器
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
    ]).animate(_mainController);

    _flashAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 70),
    ]).animate(_flashController);

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.linear),
    );

    // 初始化火花
    for (int i = 0; i < 40; i++) {
      _sparks.add(_Spark(
        angle: _random.nextDouble() * 2 * pi,
        distance: _random.nextDouble() * 150 + 50,
        size: _random.nextDouble() * 6 + 3,
        speed: _random.nextDouble() * 0.5 + 0.5,
        color: _getSparkColor(i),
      ));
    }

    _mainController.forward();
    _flashController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  Color _getSparkColor(int index) {
    final colors = [
      AppColors.primary,
      const Color(0xFFFF6B35),
      const Color(0xFFFFD700),
      const Color(0xFFE85D2D),
      Colors.white,
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _mainController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _flashController]),
      builder: (context, child) {
        return Stack(
          children: [
            // 背景遮罩
            Container(
              color: Colors.black.withValues(alpha: 0.85 * _flashAnimation.value.clamp(0.0, 1.0)),
            ),

            // 闪光效果
            if (_flashAnimation.value > 0)
              Center(
                child: Container(
                  width: 300 * _flashAnimation.value,
                  height: 300 * _flashAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: _flashAnimation.value * 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: _flashAnimation.value),
                        blurRadius: 100,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),

            // 火花轨迹
            CustomPaint(
              size: Size.infinite,
              painter: _SparkPainter(
                sparks: _sparks,
                progress: _mainController.value,
                rotation: _rotationAnimation.value,
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
        );
      },
    );
  }

  Widget _buildContent() {
    final stage = PetAppearanceLevel.getStage(widget.newStage);
    final emoji = stage?.evolutionEmoji ?? '✨';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 进化 emoji
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.6),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 80),
          ),
        ),
        const SizedBox(height: 24),
        // 标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.8),
                const Color(0xFFFF6B35).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Text(
            '进 化 ！',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 8,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 阶段名
        Text(
          '解锁「${stage?.name ?? ""}」形态',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        // 宠物 emoji
        Text(
          '${widget.petEmoji} × $emoji',
          style: const TextStyle(fontSize: 36),
        ),
      ],
    );
  }
}

class _Spark {
  double angle;
  double distance;
  double size;
  Color color;
  double speed;

  _Spark({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.speed,
  });
}

class _SparkPainter extends CustomPainter {
  final List<_Spark> sparks;
  final double progress;
  final double rotation;

  _SparkPainter({required this.sparks, required this.progress, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final spark in sparks) {
      final distance = spark.distance * progress * spark.speed;
      final angle = spark.angle + rotation;

      final x = center.dx + cos(angle) * distance;
      final y = center.dy + sin(angle) * distance;

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = spark.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), spark.size * (1.0 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 显示进化动画的 Overlay 入口
class EvolutionOverlay {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, int newStage, String petEmoji) {
    _currentEntry?.remove();

    _currentEntry = OverlayEntry(
      builder: (context) => EvolutionCelebration(
        newStage: newStage,
        petEmoji: petEmoji,
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
