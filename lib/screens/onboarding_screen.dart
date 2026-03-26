import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  String _antiVision = '';
  String _vision = '';
  String _yearGoal = '';
  String _monthlyBoss = '';
  List<String> _dailyLevers = ['', '', ''];
  String _temptingBundling = '';
  String _constraints = '';

  // Onboarding 8步流程：
  // 0:欢迎 → 1:反愿景 → 2:愿景 → 3:年度目标 → 4:月度Boss → 5:每日杠杆 → 6:诱惑捆绑 → 7:约束条件
  final int _totalPages = 8;

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
      final validLevers = _dailyLevers.where((l) => l.trim().isNotEmpty).toList();

      await storage.saveOnboardingData(
        antiVision: _antiVision.trim(),
        vision: _vision.trim(),
        yearGoal: _yearGoal.trim(),
        monthlyBoss: _monthlyBoss.trim(),
        dailyLevers: validLevers,
        constraints: _constraints.trim(),
        temptingBundling: _temptingBundling.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
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
            Padding(
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
                  GestureDetector(
                    onTap: _isSaving ? null : _completeOnboarding,
                    child: const Text(
                      '跳过',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(),
                  _buildAntiVisionPage(),
                  _buildVisionPage(),
                  _buildYearGoalPage(),
                  _buildMonthlyBossPage(),
                  _buildDailyLeversPage(),
                  _buildTemptingBundlingPage(),
                  _buildConstraintsPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_canProceed() && !_isSaving) ? _nextPage : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_currentPage == _totalPages - 1 ? '开始行动' : '下一步'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return true;
      case 1:
        return _antiVision.trim().isNotEmpty;
      case 2:
        return _vision.trim().isNotEmpty;
      case 3:
        return _yearGoal.trim().isNotEmpty;
      case 4:
        return _monthlyBoss.trim().isNotEmpty;
      case 5:
        return _dailyLevers.where((l) => l.trim().isNotEmpty).length >= 2;
      case 6:
        // 诱惑捆绑是可选的，始终可过
        return true;
      case 7:
        return _constraints.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '欢迎来到练了吗',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            '从今天开始发生改变\n每天行动一点点，成为你想成为的人',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildFeatureRow('🔥', '每日打卡', '完成行动，积累连续天数'),
                const SizedBox(height: 12),
                _buildFeatureRow('⛩️', '月度Boss战', '设定目标，月底检验成果'),
                const SizedBox(height: 12),
                _buildFeatureRow('🎯', '每日杠杆', '2-3件关键行动，撬动大改变'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String emoji, String title, String desc) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAntiVisionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「反愿景」\n锁定1年不可更改',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '描述你最不想成为的人、最不想过的生活。\n这是你的底线，让你明确要逃避什么。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '例如：每天刷短视频到凌晨3点，拒绝任何成长机会...\n\n五年后，我在出租屋里醒来，满身疲惫，对生活麻木...',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _antiVision = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「愿景」\n锁定1年不可更改',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '描述你理想中的一年后的生活。\n这是你的北极星，让你明确要走向哪里。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '例如：每天早起读书写作，保持精力充沛...\n\n一年后，我有稳定的副业收入，自信从容...',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _vision = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「一年目标」\n每年可改1次',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '今年你想要达成什么？\n用「我是_____的人」来描述，而非「我要达成_____」',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '例如：我是每年读完50本书的人\n我是能跑完全程马拉松的人',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _yearGoal = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBossPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「月度Boss」\n每月可改1次',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '这个月最重要的1件事是什么？\n用「我是已经击败了这个Boss的人」来描述',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '例如：我是已经击败了「早起30天」这个Boss的人\n我是已经读完《原子习惯》的人',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _monthlyBoss = v),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Text('👹', style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '每月打卡满天数 = 击败Boss\n没击败会累积到下个月',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLeversPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「每日杠杆」\n每天可调整',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '每天做哪2-3件事，能撬动你的一年目标？\n写成「如果[情境]，那么[行为]」格式',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'IF-THEN 格式示例',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '❌ 每天做运动\n✅ 如果早上7点闹钟响，我就立刻做5个俯卧撑\n\n❌ 每天读书\n✅ 如果通勤路上有空，我就读5页书',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _dailyLevers[index].isNotEmpty
                        ? AppColors.primary
                        : AppColors.textLight.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '如果[情境]，那么[行为]',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.check_circle_outline,
                      color: _dailyLevers[index].isNotEmpty
                          ? AppColors.primary
                          : AppColors.textLight,
                    ),
                  ),
                  onChanged: (v) => setState(() => _dailyLevers[index] = v),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTemptingBundlingPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「诱惑捆绑」\n可选设置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '把「渴望行为」绑定到「必要行为」上。\n科学研究：显著提升执行率。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🧠', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text(
                      'Temptation Bundling 原理',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Milkman et al. 研究发现：把渴望行为绑定到必要行为上，执行率提升 20-40%。\n\n格式：「只有在做完今日杠杆后，我才能_____」',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '例如：只有在做完今日杠杆后，我才能刷短视频\n\n只有在读完书之后，我才能喝奶茶\n\n只有在运动完之后，我才能吃甜点',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _temptingBundling = v),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '不填也可以，之后在「我的」页面随时设置',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConstraintsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「约束条件」\n锁定1年不可更改',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '哪些原则是你绝对不能打破的？\n明确的边界，反而让你更自由。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: TextField(
              maxLines: 5,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '例如：\n每晚11点前必须睡觉\n每天看手机娱乐不超过1小时\n每周必须运动3次',
                hintStyle: TextStyle(color: AppColors.textLight),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterStyle: TextStyle(color: AppColors.textLight),
              ),
              onChanged: (v) => setState(() => _constraints = v),
            ),
          ),
        ],
      ),
    );
  }
}
