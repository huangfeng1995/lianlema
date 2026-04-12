import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/pet_push_service.dart';

class PetPushBanner extends StatefulWidget {
  final PetPush push;

  const PetPushBanner({super.key, required this.push});

  @override
  State<PetPushBanner> createState() => _PetPushBannerState();
}

class _PetPushBannerState extends State<PetPushBanner> {
  double _opacity = 1.0;
  bool _showClose = false;
  Timer? _closeTimer;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    // 6秒后显示关闭按钮
    _closeTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showClose = true);
    });
    // 8秒后淡出
    _fadeTimer = Timer(const Duration(seconds: 8), _fadeOut);
  }

  void _fadeOut() {
    _fadeTimer?.cancel();
    if (mounted) setState(() => _opacity = 0.0);
    // 300ms后从tree移除
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }

  String _getPetEmoji(PushType type) {
    switch (type) {
      case PushType.streakReminder:   return '☀️';
      case PushType.milestoneApproaching: return '🎯';
      case PushType.idleWarning:      return '💪';
      case PushType.weeklySummary:    return '📋';
      case PushType.challengeProgress: return '🏃';
      case PushType.obstacleGuidance: return '🧭';
      case PushType.annualPlanGuide:  return '🌟';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_opacity == 0.0) return const SizedBox.shrink();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _opacity,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 宠物头像
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getPetEmoji(widget.push.type),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 消息内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.push.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.push.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 关闭按钮
            if (_showClose)
              GestureDetector(
                onTap: _fadeOut,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
