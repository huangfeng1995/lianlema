import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../models/goal_templates.dart';

class AnnualPlanScreen extends StatefulWidget {
  const AnnualPlanScreen({super.key});

  @override
  State<AnnualPlanScreen> createState() => _AnnualPlanScreenState();
}

class _AnnualPlanScreenState extends State<AnnualPlanScreen> {
  StorageService? _storage;
  bool _isSaving = false;
  bool _dataLoaded = false;

  List<String> _yearGoals = [''];
  List<TextEditingController> _goalControllers = [];
  final TextEditingController _antiVisionController = TextEditingController();
  final TextEditingController _visionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goalControllers = [TextEditingController()];
    // 先显示表单，再异步加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final storage = await StorageService.getInstance();
      if (!mounted) return;
      final yearGoalStr = storage.getYearGoal();
      final goals = yearGoalStr.isEmpty
          ? <String>[]
          : yearGoalStr.split('；').where((g) => g.trim().isNotEmpty).toList();
      _yearGoals = goals.isEmpty ? <String>[''] : goals;

      // 重建 controllers
      for (final c in _goalControllers) c.dispose();
      _goalControllers = _yearGoals.map((g) => TextEditingController(text: g)).toList();
      _antiVisionController.text = storage.getAntiVision();
      _visionController.text = storage.getVision();
      _storage = storage;
      if (mounted) setState(() => _dataLoaded = true);
    } catch (e) {
      debugPrint('[AnnualPlanScreen] loadData error: $e');
      if (mounted) setState(() => _dataLoaded = true);
    }
  }

  @override
  void dispose() {
    for (final c in _goalControllers) c.dispose();
    _antiVisionController.dispose();
    _visionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final storage = _storage ?? await StorageService.getInstance();
    setState(() => _isSaving = true);
    try {
      final goals = _goalControllers.map((c) => c.text.trim()).where((g) => g.isNotEmpty).toList();
      await storage.saveYearGoal(goals.join('；'));
      await storage.saveAntiVision(_antiVisionController.text.trim());
      await storage.saveVision(_visionController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '长期计划',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 长远目标 =====
            _buildSectionHeader('长远目标', Icons.flag_outlined, '今年最想做成的一件事'),
            const SizedBox(height: 12),
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
                        controller: index < _goalControllers.length ? _goalControllers[index] : null,
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
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    if (_yearGoals.length > 1)
                      GestureDetector(
                        onTap: () {
                          _goalControllers[index].dispose();
                          _goalControllers.removeAt(index);
                          setState(() => _yearGoals.removeAt(index));
                        },
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
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                if (_yearGoals.length >= 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('目标不宜过多，聚焦最重要的事效果更好'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                setState(() {
                  _yearGoals.add('');
                  _goalControllers.add(TextEditingController());
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text(
                      '添加目标',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ===== 反愿景 =====
            _buildSectionHeader('反愿景', Icons.not_interested_outlined, '你不想成为什么样的人'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _antiVisionController.text.isNotEmpty
                      ? AppColors.primary
                      : AppColors.textLight.withValues(alpha: 0.25),
                ),
              ),
              child: TextField(
                controller: _antiVisionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '例如：拖延成性的人，三分钟热度的人...',
                  hintStyle: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '可跳过',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight.withValues(alpha: 0.45),
              ),
            ),

            if (_antiVisionController.text.isEmpty && _visionController.text.isEmpty) ...[
              const SizedBox(height: 4),
              _buildTemplateSelector(),
            ],

            const SizedBox(height: 28),

            // ===== 愿景 =====
            _buildSectionHeader('愿景', Icons.visibility_outlined, '用画面描述你理想中的自己'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _visionController.text.isNotEmpty
                      ? AppColors.primary
                      : AppColors.textLight.withValues(alpha: 0.25),
                ),
              ),
              child: TextField(
                controller: _visionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '例如：每天早起写作的人\n知识渊博、能清晰表达想法\n活成了自己尊重的那个人...',
                  hintStyle: TextStyle(
                    color: AppColors.textLight.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '可跳过',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 不知道定什么目标？试试模板',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GoalTemplates.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, index) {
              final template = GoalTemplates.all[index];
              return _buildTemplateCard(template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(GoalTemplate template) {
    return GestureDetector(
      onTap: () => _applyTemplate(template),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              template.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              template.description,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _applyTemplate(GoalTemplate template) {
    _antiVisionController.text = template.antiVision;
    _visionController.text = template.vision;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(template.emoji),
            const SizedBox(width: 8),
            Text('已选择「${template.name}」模板，可继续编辑'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
