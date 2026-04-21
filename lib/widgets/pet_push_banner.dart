import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../services/pet_push_service.dart';
import '../controllers/push_banner_controller.dart';
import '../utils/storage_service.dart';

/// 推送类型配置
class PushTypeConfig {
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
  final Color accentColor;

  const PushTypeConfig({
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
    required this.accentColor,
  });
}

// 预计算的推送配置缓存（静态，只创建一次）
final Map<PushType, PushTypeConfig> _pushConfigCache = {
  PushType.streakReminder: PushTypeConfig(
    icon: CupertinoIcons.sun_max_fill,
    primaryColor: const Color(0xFFFF9500),
    bgColor: const Color(0xFFFF9500).withValues(alpha: 0.08),
    accentColor: const Color(0xFFFF9500).withValues(alpha: 0.15),
  ),
  PushType.milestoneApproaching: PushTypeConfig(
    icon: CupertinoIcons.star_fill,
    primaryColor: const Color(0xFFFF2D55),
    bgColor: const Color(0xFFFF2D55).withValues(alpha: 0.08),
    accentColor: const Color(0xFFFF2D55).withValues(alpha: 0.15),
  ),
  PushType.idleWarning: PushTypeConfig(
    icon: CupertinoIcons.heart_fill,
    primaryColor: const Color(0xFFFF2D92),
    bgColor: const Color(0xFFFF2D92).withValues(alpha: 0.08),
    accentColor: const Color(0xFFFF2D92).withValues(alpha: 0.15),
  ),
  PushType.weeklySummary: PushTypeConfig(
    icon: CupertinoIcons.chart_bar_fill,
    primaryColor: const Color(0xFF5856D6),
    bgColor: const Color(0xFF5856D6).withValues(alpha: 0.08),
    accentColor: const Color(0xFF5856D6).withValues(alpha: 0.15),
  ),
  PushType.challengeProgress: PushTypeConfig(
    icon: CupertinoIcons.flag_fill,
    primaryColor: const Color(0xFFFF3B30),
    bgColor: const Color(0xFFFF3B30).withValues(alpha: 0.08),
    accentColor: const Color(0xFFFF3B30).withValues(alpha: 0.15),
  ),
  PushType.obstacleGuidance: PushTypeConfig(
    icon: CupertinoIcons.compass,
    primaryColor: const Color(0xFF007AFF),
    bgColor: const Color(0xFF007AFF).withValues(alpha: 0.08),
    accentColor: const Color(0xFF007AFF).withValues(alpha: 0.15),
  ),
  PushType.annualPlanGuide: PushTypeConfig(
    icon: CupertinoIcons.star_circle_fill,
    primaryColor: const Color(0xFFFFD60A),
    bgColor: const Color(0xFFFFD60A).withValues(alpha: 0.08),
    accentColor: const Color(0xFFFFD60A).withValues(alpha: 0.15),
  ),
};

class PetPushBanner extends StatefulWidget {
  final PetPush push;

  const PetPushBanner({super.key, required this.push});

  @override
  State<PetPushBanner> createState() => _PetPushBannerState();
}

class _PetPushBannerState extends State<PetPushBanner>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  double _slideOffset = 20.0;
  bool _showClose = false;
  Timer? _closeTimer;
  Timer? _fadeTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  PushTypeConfig? _cachedConfig;

  @override
  void initState() {
    super.initState();
    // 预缓存配置，避免每次build都查找
    _cachedConfig = _pushConfigCache[widget.push.type];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // 记录推送已显示
    _markPushShown();

    // 入场动画
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _slideOffset = 0.0;
        });
        _animationController.forward();
      }
    });

    // 3.5秒后显示关闭按钮
    _closeTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _showClose = true);
    });

    // 6秒后淡出
    _fadeTimer = Timer(const Duration(seconds: 6), _fadeOut);
  }

  /// 获取推送类型的配置（从缓存获取）
  PushTypeConfig _getConfig(PushType type) {
    return _cachedConfig ?? _pushConfigCache[type]!;
  }

  Future<void> _markPushShown() async {
    try {
      final storage = await StorageService.getInstance();
      await storage.markPushShown();
    } catch (_) {}
  }

  void _fadeOut() {
    _fadeTimer?.cancel();
    _closeTimer?.cancel();

    if (mounted) {
      setState(() => _opacity = 0.0);
      // 通知控制器隐藏
      if (Get.isRegistered<PushBannerController>()) {
        PushBannerController.to.hidePush();
      }
      // 300ms后从tree移除
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _fadeTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_opacity == 0.0 && _slideOffset == 20.0) {
      return const SizedBox.shrink();
    }

    final config = _getConfig(widget.push.type);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: _opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.decelerate,
        transform: Matrix4.translationValues(0, _slideOffset, 0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: config.primaryColor.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 背景装饰
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: config.bgColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -10,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: config.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // 主内容
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧图标
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              config.primaryColor,
                              config.primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: config.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          config.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // 中间内容
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.push.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: config.primaryColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.push.body,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary.withValues(alpha: 0.85),
                              height: 1.35,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 关闭按钮
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showClose ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: _fadeOut,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.textLight.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
