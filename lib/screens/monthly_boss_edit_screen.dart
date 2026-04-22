import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';

class MonthlyBossEditScreen extends StatefulWidget {
  const MonthlyBossEditScreen({super.key});

  @override
  State<MonthlyBossEditScreen> createState() => _MonthlyBossEditScreenState();
}

class _MonthlyBossEditScreenState extends State<MonthlyBossEditScreen> {
  StorageService? _storage;
  bool _isSaving = false;
  bool _dataLoaded = false;

  // 月度挑战列表
  List<String> _monthlyGoals = [''];
  List<TextEditingController> _goalControllers = [];

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

      // 加载月度挑战
      final boss = storage.getMonthlyBoss();
      if (boss != null && boss.content.isNotEmpty) {
        final parts = boss.content.split('；').where((g) => g.trim().isNotEmpty).toList();
        if (parts.isNotEmpty) {
          // 有已有数据：显示已有数据 + 一个额外的空输入框
          _monthlyGoals = [...parts, ''];
        } else {
          // 没有已有数据：显示1个空输入框
          _monthlyGoals = [''];
        }
      } else {
        // 没有已有数据：显示1个空输入框
        _monthlyGoals = [''];
      }

      // 重建 controllers
      for (final c in _goalControllers) c.dispose();
      _goalControllers = _monthlyGoals.map((g) => TextEditingController(text: g)).toList();

      _storage = storage;
      if (mounted) setState(() => _dataLoaded = true);
    } catch (e) {
      debugPrint('[MonthlyBossEditScreen] loadData error: $e');
      if (mounted) setState(() => _dataLoaded = true);
    }
  }

  @override
  void dispose() {
    for (final c in _goalControllers) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final storage = _storage ?? await StorageService.getInstance();
    setState(() => _isSaving = true);

    try {
      final goals = _goalControllers.map((c) => c.text.trim()).where((g) => g.isNotEmpty).toList();

      final now = DateTime.now();
      final boss = storage.getMonthlyBoss();

      // 保存 monthlyBoss
      if (goals.isNotEmpty || (boss != null && boss.content.isNotEmpty)) {
        final updatedBoss = MonthlyBoss(
          content: goals.isNotEmpty ? goals.join('；') : boss?.content ?? '',
          month: now.month,
          year: now.year,
          totalDays: DateTime(now.year, now.month + 1, 0).day,
          hp: boss?.hp ?? 0,
        );
        await storage.saveMonthlyBoss(updatedBoss);
      }

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
          '月度计划',
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8533A)),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE8533A)),
                  ),
          ),
        ],
        elevation: 0,
      ),
      body: !_dataLoaded
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== 月度目标 =====
                  _buildSectionHeader('月度目标', Icons.flag_outlined, '这个月最想做成的一件事'),
                  const SizedBox(height: 12),
                  ...List.generate(_monthlyGoals.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < _monthlyGoals.length - 1 ? 10 : 0),
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
                                hintText: '例如：读完一本书，养成运动习惯...',
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
                          if (_monthlyGoals.length > 1)
                            GestureDetector(
                              onTap: () {
                                _goalControllers[index].dispose();
                                _goalControllers.removeAt(index);
                                setState(() => _monthlyGoals.removeAt(index));
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
                      if (_monthlyGoals.length >= 5) {
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
                        _monthlyGoals.add('');
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

                  const SizedBox(height: 32),
                ],
              ),
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
