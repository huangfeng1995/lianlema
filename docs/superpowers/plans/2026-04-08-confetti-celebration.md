# Confetti Celebration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a full-screen confetti particle animation triggered on check-in success, pet level-up, and badge unlock events.

**Architecture:** A single `ConfettiCelebration` StatefulWidget with `ConfettiPainter` CustomPainter drives ~65 particles using a single `AnimationController`. Particles are initialized with random positions/velocities at start, then rendered each frame. No third-party packages.

**Tech Stack:** Pure Flutter — `AnimationController`, `CustomPainter`, `Canvas`.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/widgets/confetti_celebration.dart` | **Create** | ConfettiCelebration widget + ConfettiPainter + ConfettiParticle data class |
| `lib/screens/home_screen.dart` | Modify | Trigger confetti overlay in `_checkIn()` |
| `lib/screens/profile_screen.dart` | Modify | Trigger confetti in `_showBadgeDetail()` for newly unlocked badges |

---

## Task 1: Create `confetti_celebration.dart`

**Files:**
- Create: `lib/widgets/confetti_celebration.dart`

- [ ] **Step 1: Write confetti_celebration.dart**

```dart
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
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
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
  late List<ConfettiParticle> _particles;
  final Random _random = Random();

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

    _controller.addListener(_updateParticles);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  void _updateParticles() {
    // 仅在必要时重建（每帧）
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initParticles();
  }

  void _initParticles() {
    final size = MediaQuery.of(context).size;
    const particleCount = 65;
    _particles = List.generate(particleCount, (i) {
      final startX = _random.nextDouble() * size.width;
      final vx = (_random.nextDouble() - 0.5) * 200; // 水平速度
      final vy = 150 + _random.nextDouble() * 350; // 下落速度
      final rotSpeed = (_random.nextDouble() - 0.5) * 10;
      final driftPhase = _random.nextDouble() * 2 * pi; // 飘动相位
      final driftAmp = 30 + _random.nextDouble() * 60; // 飘动幅度

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
    final size = MediaQuery.of(context).size;
    final t = _controller.value; // 0~1
    final dt = 1 / 60; // 假设60fps

    // 更新粒子位置
    for (final p in _particles) {
      // 重力加速度
      const gravity = 600.0;
      // 水平阻尼（空气阻力）
      const damping = 0.98;

      p.velocity = Offset(
        (p.velocity.dx + sin(t * 8 + p.position.dy * 0.01) * 50) * damping,
        p.velocity.dy + gravity * dt,
      );

      p.position = Offset(
        p.position.dx + p.velocity.dx * dt,
        p.position.dy + p.velocity.dy * dt,
      );

      p.rotation += p.rotationSpeed * dt;

      // 到底部后淡出（最后30%动画）
      if (p.position.dy > size.height * 0.7) {
        final fadeStart = 0.7;
        final fadeProgress = (t - fadeStart) / (1.0 - fadeStart);
        p.opacity = (1.0 - fadeProgress.clamp(0.0, 1.0));
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
```

- [ ] **Step 2: Verify file created correctly**

Run: `ls -la lib/widgets/confetti_celebration.dart`

---

## Task 2: 集成到 home_screen.dart

**Files:**
- Modify: `lib/screens/home_screen.dart`

- [ ] **Step 1: Add import**

在 `import '../services/pet_push_service.dart';` 之后添加：
```dart
import '../widgets/confetti_celebration.dart';
```

- [ ] **Step 2: 在 `_checkIn()` 中 `_playSuccessFeedback` 后面触发彩纸**

在 `home_screen.dart:281-282` 区域（`_playSuccessFeedback(xpEarned);` 之后）添加：
```dart
    // 彩纸庆祝动画
    ConfettiOverlay.show(context);
```

- [ ] **Step 3: 在 `profile_screen.dart` 中添加 import 并触发**

在 `profile_screen.dart` 文件开头添加：
```dart
import '../widgets/confetti_celebration.dart';
```

在 `_showBadgeDetail()` 方法中，badge解锁状态时（`if (badge.isUnlocked && badge.unlockedAt != null)` 分支内）添加：
```dart
    // 彩纸庆祝
    ConfettiOverlay.show(context);
```

---

## Task 3: 验证

- [ ] **Step 1: 运行 flutter analyze**

Run: `cd /Users/openclaw/Documents/trae_projects/change/lianlema && flutter analyze lib/`
Expected: 0 errors (warnings acceptable)

---

## Task 4: Commit

- [ ] **Step 1: Stage and commit**

```bash
git add lib/widgets/confetti_celebration.dart lib/screens/home_screen.dart lib/screens/profile_screen.dart
git commit -m "feat: 打卡成功彩纸庆祝动画

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```
