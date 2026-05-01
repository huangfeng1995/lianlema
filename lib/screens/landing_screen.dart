import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

/// 落地页 - AI宠物亲笔信
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isOldUser = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _checkUser();
  }

  Future<void> _checkUser() async {
    final storage = await StorageService.getInstance();
    if (mounted) {
      setState(() {
        _isOldUser = storage.isOnboardingComplete;
        _ready = true;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onStart() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  void _onEnter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEE6),
      body: !_ready
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _isOldUser
                  ? _ReturningUserView(onEnter: _onEnter)
                  : _NewUserView(onStart: _onStart),
            ),
    );
  }
}

// ===== 新用户：亲笔信 =====
class _NewUserView extends StatefulWidget {
  final VoidCallback onStart;
  const _NewUserView({required this.onStart});

  @override
  State<_NewUserView> createState() => _NewUserViewState();
}

class _NewUserViewState extends State<_NewUserView>
    with TickerProviderStateMixin {
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _itemAnimations = [];

  String get _letterDate {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() async {
    final durations = [700, 900, 600, 600, 500];
    final delays    = [300, 1000, 2000, 2700, 3400];

    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: durations[i]),
      );
      final animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
      _itemControllers.add(controller);
      _itemAnimations.add(animation);

      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (var c in _itemControllers) c.dispose();
    super.dispose();
  }

  Widget _anim(int index, Widget child, {double dy = 12}) {
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (ctx, _) => Opacity(
        opacity: _itemAnimations[index].value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, dy * (1 - _itemAnimations[index].value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EEE6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    children: [
                      // 信封大背景（信封色）
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E8DC),  // 牛皮纸色
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E1F0E).withOpacity( 0.1),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. 开场白
                            _anim(0, const _GreetingBlock()),
                            const SizedBox(height: 28),
                            // 装饰分隔线
                            _anim(1, const _Divider()),
                            const SizedBox(height: 28),
                            // 2. 金句
                            _anim(1, const _QuoteBlock()),
                            const SizedBox(height: 28),
                            // 装饰分隔线
                            _anim(2, const _Divider()),
                            const SizedBox(height: 28),
                            // 3. 年愿景
                            _anim(2, const _PlanBlock(
                              label: '年愿景',
                              question: '这一年，你想成为什么样的人？',
                            )),
                            const SizedBox(height: 18),
                            // 4. 月度挑战
                            _anim(3, const _PlanBlock(
                              label: '月度挑战',
                              question: '这个月，你想搞定什么事？',
                            )),
                            const SizedBox(height: 28),
                            // 装饰分隔线
                            _anim(4, const _Divider()),
                            const SizedBox(height: 24),
                            // 5. 收尾语
                            _anim(4, const _ClosingLine()),
                            const SizedBox(height: 20),
                            // 落款
                            _anim(4, Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _letterDate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary.withOpacity( 0.5),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const _InkSignature(size: 44),
                                  ],
                                ),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 按钮在信封下方
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: _anim(4, _StartButton(onTap: widget.onStart)),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 开场白 =====
class _GreetingBlock extends StatelessWidget {
  const _GreetingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '嘿，你终于来了',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary.withOpacity( 0.9),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '我是你的 AI 伙伴，等你很久了。',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withOpacity( 0.55),
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ===== 装饰分隔线 =====
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF6B35)],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.textSecondary.withOpacity( 0.1),
          ),
        ),
      ],
    );
  }
}

// ===== 金句 =====
class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock();

  @override
  Widget build(BuildContext context) {
    return Text(
      '我们不是在某个伟大的时刻开始改变，\n而是在每一个微小的行动里，\n悄悄成为了想成为的人。',
      style: TextStyle(
        fontSize: 15,
        height: 2.2,
        color: AppColors.textPrimary.withOpacity( 0.8),
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

// ===== 计划内容 =====
class _PlanBlock extends StatelessWidget {
  final String label;
  final String question;
  const _PlanBlock({required this.label, required this.question});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFF6B35).withOpacity( 0.7),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          question,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary.withOpacity( 0.85),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ===== 收尾语 =====
class _ClosingLine extends StatelessWidget {
  const _ClosingLine();

  @override
  Widget build(BuildContext context) {
    return Text(
      '想好了的话，我们就出发吧。',
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary.withOpacity( 0.55),
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

// ===== 水墨猫掌 =====
class _InkSignature extends StatelessWidget {
  final double size;
  const _InkSignature({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image(
        image: const AssetImage('assets/images/icon/paw_ink.png'),
        fit: BoxFit.contain,
      ),
    );
  }
}

// ===== 开始按钮 =====
class _StartButton extends StatefulWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed
                ? [const Color(0xFFE85D2D), const Color(0xFFCC3D1A)]
                : [const Color(0xFFFF6B35), const Color(0xFFE85D2D)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity( 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: const Text(
          '开始',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ===== 老用户：slogan 页 =====
class _ReturningUserView extends StatelessWidget {
  final VoidCallback onEnter;
  const _ReturningUserView({required this.onEnter});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          children: [
            const Spacer(flex: 3),
            const _FlameLogo(size: 80),
            const SizedBox(height: 24),
            const Text(
              '练了吗',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 4,
              ),
            ),
            const Spacer(flex: 1),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF6B35), AppColors.primary],
              ).createShader(bounds),
              child: const Text(
                '从今天开始\n发生改变',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const Spacer(flex: 3),
            _EnterButton(onTap: onEnter),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

// ===== 火焰 Logo =====
class _FlameLogo extends StatelessWidget {
  final double size;
  const _FlameLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity( 0.15),
                  AppColors.primary.withOpacity( 0),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity( 0.4),
                  blurRadius: size * 0.28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image(
              width: size * 0.5,
              height: size * 0.5,
              image: const AssetImage('assets/images/icon/paw_icon.png'),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 老用户进入按钮 =====
class _EnterButton extends StatefulWidget {
  final VoidCallback onTap;
  const _EnterButton({required this.onTap});

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.primary.withOpacity( 0.85)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity( 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: const Text(
          '继续今天的行动',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
