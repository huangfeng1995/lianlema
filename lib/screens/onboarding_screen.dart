import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import 'home_screen.dart';
import 'main_screen.dart';

/// Onboarding Screen - 简化版引导流程
///
/// 步骤：
/// 0: 月度Boss — 本月最重要的挑战
///
/// 其他内容（愿景、年度目标、每日杠杆、约束）移至"我的"页面填写
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // 步骤数据
  String _antiVision = '';
  String _vision = '';
  String _yearGoal = '';
  String _monthlyBoss = '';
  List<Map<String, String>> _dailyLevers = [];
  String _constraints = '';
  int _reminderHour = 9;
  bool _enableReminder = false;

  // 每日杠杆相关
  final List<String> _leverTemplates = ['早起', '读书', '运动', '写作', '冥想', '学英语'];
  final Set<String> _selectedTemplates = {};
  final List<String> _customLevers = ['', ''];

  // 月度Boss模板
  final List<Map<String, String>> _bossTemplates = [
    {'name': '读书Boss', 'desc': '这个月读完一本书'},
    {'name': '运动Boss', 'desc': '每天运动30分钟'},
    {'name': '早起Boss', 'desc': '连续30天早睡早起'},
    {'name': '写作Boss', 'desc': '每天写作500字'},
  ];
  Set<String> _selectedBossTypes = {};
  List<String> _customBosses = [''];

  // 提醒时间
  String _reminderChoice = '不提醒';

  static const int _totalPages = 1;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final storage = await StorageService.getInstance();

      // 构建杠杆列表
      final validLevers = <Map<String, String>>[];
      for (final template in _selectedTemplates) {
        validLevers.add({'obstacle': '', 'plan': template});
      }
      for (final custom in _customLevers) {
        if (custom.trim().isNotEmpty) {
          validLevers.add({'obstacle': '', 'plan': custom.trim()});
        }
      }
      if (validLevers.isEmpty) {
        validLevers.add({'obstacle': '', 'plan': '早起'});
        validLevers.add({'obstacle': '', 'plan': '读书'});
      }

      // 构建月度Boss（支持多选）
      String bossContent = '';
      final parts = <String>[];
      if (_selectedBossTypes.isNotEmpty) {
        for (final name in _selectedBossTypes) {
          final template = _bossTemplates.firstWhere((t) => t['name'] == name);
          parts.add(template['desc']!);
        }
      }
      for (final b in _customBosses) {
        if (b.trim().isNotEmpty) parts.add(b.trim());
      }
      bossContent = parts.join('；');

      await storage.saveOnboardingData(
        antiVision: _antiVision.isEmpty ? '还在探索中' : _antiVision,
        vision: _vision.isEmpty ? '成为更好的自己' : _vision,
        yearGoal: _yearGoal.isEmpty ? '持续成长' : _yearGoal,
        monthlyBoss: bossContent,
        dailyLevers: validLevers.isEmpty ? [{'obstacle': '', 'plan': '早起'}, {'obstacle': '', 'plan': '读书'}] : validLevers,
        constraints: _constraints.isEmpty ? '每天进步一点点' : _constraints,
        temptingBundling: '',
      );

      if (_enableReminder) {
        await storage.saveReminderTime(_reminderHour, 0);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildMonthlyBossPage(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: () {
                setState(() => _currentPage -= 1);
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios, size: 16),
              ),
            )
          else
            const SizedBox(width: 32),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                return Container(
                  width: index == _currentPage ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canProceed = _canProceed();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (canProceed && !_isSaving) ? _nextPage : null,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _currentPage == _totalPages - 1 ? '开始行动' : '下一步',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: // 反愿景 - 可跳过
        return true;
      case 1: // 愿景 - 可跳过
        return true;
      case 2: // 年度目标 - 可跳过
        return true;
      case 3: // 月度Boss - 至少选一个
        return _selectedBossTypes.isNotEmpty || _customBosses.any((b) => b.trim().isNotEmpty);
      case 4: // 每日杠杆 - 至少填一个
        final hasTemplate = _selectedTemplates.isNotEmpty;
        final hasCustom = _customLevers.any((l) => l.trim().isNotEmpty);
        return hasTemplate || hasCustom;
      case 5: // 约束条件 - 可跳过
        return true;
      default:
        return true;
    }
  }

  // ====== Page 0: 反愿景 ======
  Widget _buildAntiVisionPage() {
    return _buildStepPage(
      stepLabel: '第一步',
      title: '你最不想成为什么人？',
      subtitle: '描述你最不想活成的样子\n这会帮你看清真正重要的东西',
      icon: Icons.not_interested_outlined,
      iconColor: const Color(0xFFE85A1C),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _antiVision.isNotEmpty
                    ? AppColors.primary
                    : AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '例如：每天刷短视频虚度光阴的人\n不想成为那种永远在准备却从不行动的人...',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
              onChanged: (v) => setState(() => _antiVision = v),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkipHint(),
        ],
      ),
    );
  }

  // ====== Page 1: 愿景 ======
  Widget _buildVisionPage() {
    return _buildStepPage(
      stepLabel: '第二步',
      title: '你想成为什么人？',
      subtitle: '用画面描述你理想中的自己\n这是你的北极星',
      icon: Icons.visibility_outlined,
      iconColor: const Color(0xFF4CAF50),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _vision.isNotEmpty
                    ? AppColors.primary
                    : AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '例如：每天早起写作的人\n知识渊博、能清晰表达想法\n活成了自己尊重的那个人...',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
              onChanged: (v) => setState(() => _vision = v),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkipHint(),
        ],
      ),
    );
  }

  // ====== Page 2: 年度目标 ======
  Widget _buildYearGoalPage() {
    return _buildStepPage(
      stepLabel: '第三步',
      title: '今年最重要的1件事',
      subtitle: '这一年结束后，你希望在哪方面有突破？\n用「我已经成为了...的人」来描述',
      icon: Icons.flag_outlined,
      iconColor: const Color(0xFFFF6B5B),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _yearGoal.isNotEmpty
                    ? AppColors.primary
                    : AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '例如：读完24本书的人\n能够用英语日常对话的人\n跑完半程马拉松的人...',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
              onChanged: (v) => setState(() => _yearGoal = v),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            '💡 小技巧',
            '聚焦一件事比同时做十件更有效。选择让你激动的那一个。',
          ),
          const SizedBox(height: 12),
          _buildSkipHint(),
        ],
      ),
    );
  }

  // ====== Page 3: 月度Boss ======
  Widget _buildMonthlyBossPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图标 + 标题
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_outlined, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本月Boss战',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '选择一个或自定义你的挑战',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Boss选项 - 游戏卡片风格（无勾选框）
          ..._bossTemplates.map((template) {
            final isSelected = _selectedBossTypes.contains(template['name']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedBossTypes.remove(template['name']);
                  } else {
                    _selectedBossTypes.add(template['name']!);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primaryLight.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textLight.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Boss状态图标
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.sports_mma,
                            size: 20,
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template['name']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              template['desc']!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // 自定义Boss - 动态多输入框
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _customBosses.any((b) => b.isNotEmpty)
                    ? AppColors.primary
                    : AppColors.textLight.withValues(alpha: 0.2),
                width: _customBosses.any((b) => b.isNotEmpty) ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_note,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '自定义本月Boss战',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _customBosses.add('');
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text(
                              '添加',
                              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 提示文案
                Text(
                  '好Boss的标准：具体可衡量、一个月内能完成、有挑战但不至于不可能',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                // 动态输入框列表
                ...List.generate(_customBosses.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < _customBosses.length - 1 ? 10 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: '例如：每天跑步30分钟',
                              hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6), fontSize: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.textLight.withValues(alpha: 0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.textLight.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            onChanged: (v) => setState(() {
                              _customBosses[index] = v;
                            }),
                          ),
                        ),
                        if (_customBosses.length > 1)
                          GestureDetector(
                            onTap: () => setState(() {
                              _customBosses.removeAt(index);
                            }),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6, top: 8),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textLight.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                // 已选Boss提示
                if (_selectedBossTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '已选 ${_selectedBossTypes.length} 个Boss + ${_customBosses.where((b) => b.isNotEmpty).length} 个自定义',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ====== Page 4: 每日杠杆 ======
  Widget _buildDailyLeversPage() {
    return _buildStepPage(
      stepLabel: '第五步',
      title: '每天坚持的关键行动',
      subtitle: '选择2-3个每天都要做的关键行动\n这是撬动大改变的最省力方式',
      icon: Icons.touch_app_outlined,
      iconColor: const Color(0xFF8B4513),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快速选择',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _leverTemplates.map((template) {
                final isSelected = _selectedTemplates.contains(template);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedTemplates.remove(template);
                    } else if (_selectedTemplates.length < 3) {
                      _selectedTemplates.add(template);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) const Icon(Icons.check, size: 14, color: Colors.white),
                        if (isSelected) const SizedBox(width: 4),
                        Text(
                          template,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              '自定义',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            ...List.generate(2, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _customLevers[index].isNotEmpty
                          ? AppColors.primary
                          : AppColors.textLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '例如：每天冥想10分钟',
                      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    onChanged: (v) => setState(() => _customLevers[index] = v),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            _buildInsightCard(
              '🧩 Tiny Habits 原理',
              '让行为小到不可能失败。比「每天跑5公里」更好的是「每天穿上跑鞋」。',
            ),
          ],
        ),
      ),
    );
  }

  // ====== Page 5: 约束条件 ======
  Widget _buildConstraintsPage() {
    return _buildStepPage(
      stepLabel: '第六步',
      title: '绝对不打破的规则',
      subtitle: '给自己设定底线\n这些规则无论什么情况都不能打破',
      icon: Icons.rule_outlined,
      iconColor: const Color(0xFF9C27B0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _constraints.isNotEmpty
                    ? AppColors.primary
                    : AppColors.textLight.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '例如：\n• 每天睡前30分钟不刷手机\n• 每周至少运动3次\n• 每天读书至少10页...',
                hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.6),
              onChanged: (v) => setState(() => _constraints = v),
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            '🎯 为什么约束很重要',
            '约束是你给自己签的合同。它们减少了决策疲劳，让你在关键时刻不纠结。',
          ),
          const SizedBox(height: 16),
          // 提醒设置
          const Text(
            '每日提醒',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildReminderChip('上午', '09:00'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReminderChip('下午', '14:00'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReminderChip('晚上', '20:00'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildReminderChip('不提醒', null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSkipHint(),
        ],
      ),
    );
  }

  Widget _buildReminderChip(String label, String? time) {
    final isSelected = time == null
        ? _reminderChoice == '不提醒'
        : _reminderChoice == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _reminderChoice = label;
          _enableReminder = label != '不提醒';
          if (label == '上午') _reminderHour = 9;
          if (label == '下午') _reminderHour = 14;
          if (label == '晚上') _reminderHour = 20;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (time != null)
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ====== 通用组件 ======
  Widget _buildStepPage({
    required String stepLabel,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stepLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              body,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipHint() {
    return GestureDetector(
      onTap: () {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '跳过，可之后在「目标」页面填写',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ),
      ),
    );
  }
}
