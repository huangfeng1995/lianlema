import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../utils/pet_service.dart';
import 'home_screen.dart';
import 'main_screen.dart';

/// Onboarding Screen - 简化版引导流程
///
/// 步骤：
/// 0: 年度目标 — 今年最想做成的一件事
/// 1: 月度挑战 — 本月最重要的挑战
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
  List<String> _yearGoals = ['']; // 年度目标（可多条）
  String _monthlyBoss = '';
  List<Map<String, String>> _dailyLevers = [];
  String _constraints = '';
  int _reminderHour = 9;
  bool _enableReminder = false;

  // 每日杠杆相关
  final List<String> _leverTemplates = ['早起', '读书', '运动', '写作', '冥想', '学英语'];
  final Set<String> _selectedTemplates = {};
  final List<String> _customLevers = ['', ''];

  // 月度挑战模板（3个）
  final List<Map<String, String>> _bossTemplates = [
    {'name': '读完一本书', 'desc': '这个月读完一本书', 'dailyActionHints': '["每天阅读10页", "写读书笔记"]'},
    {'name': '运动习惯', 'desc': '每周运动3次', 'dailyActionHints': '["晨跑30分钟", "睡前拉伸"]'},
    {'name': '早起习惯', 'desc': '连续30天早睡早起', 'dailyActionHints': '["23点前睡觉", "6点起床"]'},
  ];
  Set<String> _selectedBossTypes = {};
  List<String> _customBosses = [''];

  // 提醒时间
  String _reminderChoice = '不提醒';

  // 每个Boss对应的每日行动 Map<bossKey, List<action>>
  Map<String, List<String>> _dailyActionsPerBoss = {};

  // ====== 宠物智能拆解状态 ======
  List<String> _petSuggestedChallenges = []; // 宠物建议的月度挑战
  Map<String, List<String>> _petDailyActionsPerChallenge = {}; // challenge → 每日行动
  bool _isLoadingPetSuggestions = false;
  // 用户编辑后的宠物建议（key=原始建议, value=编辑后的文本）
  Map<String, String> _editedPetSuggestions = {};

  static const int _totalPages = 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 获取所有选中的Boss（包括模板+自定义）的key列表
  List<String> _getAllBossKeys() {
    final keys = <String>[];
    keys.addAll(_selectedBossTypes);
    for (var i = 0; i < _customBosses.length; i++) {
      if (_customBosses[i].trim().isNotEmpty) {
        keys.add('custom_$i');
      }
    }
    return keys;
  }

  // 获取Boss的显示名
  String _getBossDisplayName(String key) {
    if (key.startsWith('custom_')) {
      final idx = int.tryParse(key.substring(7)) ?? 0;
      return _customBosses[idx].trim();
    }
    final template = _bossTemplates.firstWhere(
      (t) => t['name'] == key,
      orElse: () => {'desc': key},
    );
    return template['desc'] ?? key;
  }

  void _ensureBossActions(String key) {
    if (!_dailyActionsPerBoss.containsKey(key)) {
      _dailyActionsPerBoss[key] = ['', ''];
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // 如果即将前往月度挑战页，提前加载宠物拆解建议
      if (_currentPage == 0) {
        _loadPetSuggestions();
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  /// 加载宠物的智能拆解建议（年度目标 → 月度挑战 → 每日行动）
  Future<void> _loadPetSuggestions() async {
    final goals = _yearGoals.where((g) => g.trim().isNotEmpty).toList();
    if (goals.isEmpty) return;
    if (_isLoadingPetSuggestions) return;

    setState(() {
      _isLoadingPetSuggestions = true;
      _petSuggestedChallenges = [];
      _petDailyActionsPerChallenge = {};
    });

    try {
      final result = await PetService.instance.decomposeGoals(goals);
      if (mounted) {
        setState(() {
          _petSuggestedChallenges = result.monthlyChallenges;
          _petDailyActionsPerChallenge = result.dailyActionsPerChallenge;
          _isLoadingPetSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPetSuggestions = false);
      }
    }
  }

  /// 处理宠物建议的点击：选中时弹出编辑框，取消选中时移除
  void _handleSuggestionTap(String suggestion, bool wasSelected) {
    if (wasSelected) {
      // 取消选中
      setState(() {
        _selectedBossTypes.remove(suggestion);
        _editedPetSuggestions.remove(suggestion);
      });
    } else {
      // 选中 → 弹出编辑对话框
      final controller = TextEditingController(
        text: _editedPetSuggestions[suggestion] ?? suggestion,
      );
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('编辑挑战'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '输入月度挑战...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final editedText = controller.text.trim();
                if (editedText.isNotEmpty) {
                  setState(() {
                    _editedPetSuggestions[suggestion] = editedText;
                    _selectedBossTypes.add(suggestion);
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
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

      // 构建月度挑战（支持多选 + 用户编辑）
      // 注意：用户可能选择了「为你推荐」的选项，这些不在 _bossTemplates 里
      String bossContent = '';
      final parts = <String>[];
      if (_selectedBossTypes.isNotEmpty) {
        for (final name in _selectedBossTypes) {
          // 如果用户编辑过宠物建议，用编辑后的文本
          final displayText = _editedPetSuggestions[name] ?? name;
          // 尝试在模板里找，找不到就用编辑/原始文本
          final templateMatch = _bossTemplates.where((t) => t['name'] == displayText || t['name'] == name).toList();
          if (templateMatch.isNotEmpty) {
            parts.add(templateMatch.first['desc']!);
          } else {
            // 推荐词或自定义 → 使用编辑后的文本（如果有）
            parts.add(displayText);
          }
        }
      }
      for (final b in _customBosses) {
        if (b.trim().isNotEmpty) parts.add(b.trim());
      }
      bossContent = parts.join('；');

      // 构建每日行动（优先使用宠物智能拆解的结果，按原始key查找）
      List<String> dailyActionsFromPet = [];
      for (final key in _selectedBossTypes) {
        if (_petDailyActionsPerChallenge.containsKey(key)) {
          dailyActionsFromPet.addAll(_petDailyActionsPerChallenge[key]!);
        }
      }

      await storage.saveOnboardingData(
        antiVision: _antiVision.isEmpty ? '还在探索中' : _antiVision,
        vision: _vision.isEmpty ? '成为更好的自己' : _vision,
        yearGoal: _yearGoals.any((g) => g.isNotEmpty) ? _yearGoals.where((g) => g.isNotEmpty).join('；') : '持续成长',
        monthlyBoss: bossContent,
        dailyLevers: validLevers.isEmpty 
            ? (bossContent.isNotEmpty && bossContent != '本月挑战' 
                ? [{'obstacle': '', 'plan': '开始行动'}] 
                : [{'obstacle': '', 'plan': '早起'}, {'obstacle': '', 'plan': '读书'}])
            : validLevers,
        constraints: _constraints.isEmpty ? '每天进步一点点' : _constraints,
        temptingBundling: '',
        dailyActions: dailyActionsFromPet.isNotEmpty ? dailyActionsFromPet : [],
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
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildYearGoalPage(),
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
          onPressed: _isSaving
              ? null
              : () {
                  if (!canProceed) {
                    if (_currentPage == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('先写下你的年度目标吧 ✍️'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }
                  _nextPage();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _currentPage == _totalPages - 1 ? '完成' : '下一步',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: // 年度目标 - 必须填写
        return _yearGoals.any((g) => g.trim().isNotEmpty);
      case 1: // 月度挑战 - 至少选一个
        return _selectedBossTypes.isNotEmpty || _customBosses.any((b) => b.trim().isNotEmpty);
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

  // ====== Page 0: 年度目标 ======
  Widget _buildYearGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区
          const Text(
            '年度目标',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '这一年结束后，你在哪方面想有突破？',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // 多条目标输入（风格与月度挑战自定义输入完全一致）
          ...List.generate(_yearGoals.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index < _yearGoals.length - 1 ? 10 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: '例如：读完24本书，跑完半程马拉松...',
                        hintStyle: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
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
                            color: Color(0xFFFF6B35),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      onChanged: (v) => setState(() => _yearGoals[index] = v),
                    ),
                  ),
                  if (_yearGoals.length > 1)
                    GestureDetector(
                      onTap: () => setState(() => _yearGoals.removeAt(index)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6, top: 10),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textLight.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          // 添加按钮
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (_yearGoals.length >= 11) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('年度目标不宜过多，聚焦最重要的事效果更好'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (_yearGoals.length >= 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('目标较多，聚焦最重要的事效果更好哦（${_yearGoals.length}/3）'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              setState(() => _yearGoals.add(''));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Color(0xFFFF6B35)),
                  SizedBox(width: 2),
                  Text(
                    '添加',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // 引导提示语（去掉标题，与月度挑战的提示语风格一致）
          Text(
            '你最想突破的领域是什么？这一年你想成为什么样的自己？',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.55),
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ====== Page 1: 月度挑战 ======
  Widget _buildMonthlyBossPage() {
    // 宠物智能拆解的建议挑战
    final suggestions = _petSuggestedChallenges;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            '本月挑战',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '基于你的年度目标，建议当月挑战如下',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // 年度目标上下文
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  size: 18,
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '年度目标：${_yearGoals.where((g) => g.isNotEmpty).join('；')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 加载中：宠物正在思考拆解方案
          if (_isLoadingPetSuggestions) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '宠物正在帮你拆解目标...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 建议挑战（宠物智能拆解）
          if (suggestions.isNotEmpty) ...[
            Text(
              '为你推荐',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            ...suggestions.map((s) {
              final isSelected = _selectedBossTypes.contains(s);
              final editedText = _editedPetSuggestions[s];
              final displayText = editedText ?? s;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _handleSuggestionTap(s, isSelected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                const Color(0xFFFF6B35).withValues(alpha: 0.12),
                                const Color(0xFFE85D2D).withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF6B35)
                            : AppColors.textLight.withValues(alpha: 0.15),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF6B35)
                                : AppColors.textLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSelected ? Icons.edit : Icons.check,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textLight.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFE85D2D)
                                  : AppColors.textPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.6),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // 或分隔线
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: AppColors.textLight.withValues(alpha: 0.1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '或自定义',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: AppColors.textLight.withValues(alpha: 0.1)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 自定义挑战输入
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _customBosses.any((b) => b.isNotEmpty)
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.textLight.withValues(alpha: 0.15),
                width: _customBosses.any((b) => b.isNotEmpty) ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '自定义本月挑战',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _customBosses.add('');
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 14, color: Color(0xFFFF6B35)),
                            SizedBox(width: 2),
                            Text(
                              '添加',
                              style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...List.generate(_customBosses.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: index < _customBosses.length - 1 ? 10 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6B35),
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
                                  color: Color(0xFFFF6B35),
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
                              padding: const EdgeInsets.only(left: 6, top: 10),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.textLight.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

                // 心理学提示
                const SizedBox(height: 16),
                Text(
                  '好目标的标准：具体可衡量、一个月内能完成、有挑战但不至于不可能',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDailyActionPage() {
    final bossKeys = _getAllBossKeys();
    // 保证每个boss都有初始化的行动列表
    for (final key in bossKeys) {
      _ensureBossActions(key);
    }
    final selectedHintMap = <String, List<String>>{};
    for (final key in bossKeys) {
      // 优先使用宠物智能拆解的每日行动
      if (_petDailyActionsPerChallenge.containsKey(key)) {
        selectedHintMap[key] = _petDailyActionsPerChallenge[key] ?? [];
      } else if (!key.startsWith('custom_')) {
        // 回退到模板的每日行动
        final template = _bossTemplates.firstWhere(
          (t) => t['name'] == key,
          orElse: () => {'name': '', 'desc': '', 'dailyActionHints': '[]'},
        );
        final hintsStr = template['dailyActionHints'] ?? '[]';
        if (hintsStr.isNotEmpty && hintsStr != '[]') {
          try {
            final parsed = hintsStr.substring(1, hintsStr.length - 1).split(',').map((s) => s.trim().replaceAll('"', '')).toList();
            selectedHintMap[key] = parsed;
          } catch (_) {
            selectedHintMap[key] = [];
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题区
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B5B), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B5B).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '每日行动',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '每个Boss每天做什么？',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 多个Boss时每个Boss一个行动区块（不用Tab）
          if (bossKeys.length > 1)
            ...bossKeys.map((key) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildBossActionSection(key, selectedHintMap[key] ?? []),
            ))
          else if (bossKeys.isNotEmpty)
            _buildBossActionSection(bossKeys.first, selectedHintMap[bossKeys.first] ?? [])
          else
            const Center(
              child: Text(
                '请先在上一页选择你的挑战',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 每个Boss的行动输入区域
  Widget _buildBossActionSection(String bossKey, List<String> hints) {
    final actions = _dailyActionsPerBoss[bossKey] ?? ['', ''];
    final circledNumbers = ['①', '②', '③', '④', '⑤'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Boss标签
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primaryLight.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getBossDisplayName(bossKey),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 建议提示
        if (hints.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8E53).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 13, color: Color(0xFFFF8E53)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '建议：${hints.join('、')}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 提示文案
        Text(
          '每天坚持的关键行动：',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        // 行动输入框
        ...List.generate(actions.length, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < actions.length - 1 ? 10 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8E53).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      circledNumbers[index],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF8E53),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    maxLines: 2,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: '例如：每天跑步30分钟',
                      hintStyle: TextStyle(
                        color: AppColors.textLight.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2), width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF8E53), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    onChanged: (v) => setState(() {
                      _dailyActionsPerBoss[bossKey]![index] = v;
                    }),
                  ),
                ),
                if (actions.length > 1)
                  GestureDetector(
                    onTap: () => setState(() {
                      _dailyActionsPerBoss[bossKey]!.removeAt(index);
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
        const SizedBox(height: 12),

        // 添加按钮
        if (actions.length < 5)
          GestureDetector(
            onTap: () => setState(() {
              _dailyActionsPerBoss[bossKey]!.add('');
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8E53).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF8E53).withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Color(0xFFFF8E53)),
                  SizedBox(width: 4),
                  Text(
                    '添加行动',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF8E53),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
