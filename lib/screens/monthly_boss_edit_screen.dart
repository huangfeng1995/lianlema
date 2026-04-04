import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../utils/storage_service.dart';

class MonthlyBossEditScreen extends StatefulWidget {
  const MonthlyBossEditScreen({super.key});

  @override
  State<MonthlyBossEditScreen> createState() => _MonthlyBossEditScreenState();
}

class _MonthlyBossEditScreenState extends State<MonthlyBossEditScreen> {
  late StorageService _storage;
  bool _isLoading = true;
  bool _isSaving = false;

  // Boss 内容（多任务用 "；" 分隔）
  late TextEditingController _bossContentController;
  
  // 每日行动列表
  late List<TextEditingController> _actionControllers;
  MonthlyBoss? _boss;

  @override
  void initState() {
    super.initState();
    _bossContentController = TextEditingController();
    _actionControllers = [TextEditingController()];
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    final boss = _storage.getMonthlyBoss();
    final actions = _storage.getDailyActions();
    final now = DateTime.now();

    if (boss != null && boss.month == now.month && boss.year == now.year) {
      _boss = boss;
      // 多任务：按 "；" 分隔显示
      _bossContentController.text = boss.content;
    } else {
      _bossContentController.text = '';
    }

    // 加载每日行动
    if (actions.isNotEmpty) {
      _actionControllers = actions.map((a) => TextEditingController(text: a)).toList();
    } else {
      // 从 dailyLevers 获取（兼容旧数据）
      final levers = _storage.getDailyLevers();
      if (levers.isNotEmpty) {
        _actionControllers = levers
            .map((l) => TextEditingController(text: l['plan'] ?? ''))
            .toList();
      } else {
        _actionControllers = [TextEditingController()];
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addAction() {
    if (_actionControllers.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多5个行动'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() {
      _actionControllers.add(TextEditingController());
    });
  }

  void _removeAction(int index) {
    if (_actionControllers.length <= 1) return;
    setState(() {
      _actionControllers[index].dispose();
      _actionControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final content = _bossContentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Boss内容不能为空'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 收集非空行动
    final actions = _actionControllers
        .map((c) => c.text.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final updatedBoss = MonthlyBoss(
        content: content,
        month: now.month,
        year: now.year,
        totalDays: DateTime(now.year, now.month + 1, 0).day,
        hp: _boss?.hp ?? 0,
      );

      await _storage.saveMonthlyBoss(updatedBoss);
      // 保存每日行动
      await _storage.saveDailyActions(actions);
      await _storage.saveDailyLevers(
        actions.map((a) => {'obstacle': '', 'plan': a}).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功 ✨'),
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
  void dispose() {
    _bossContentController.dispose();
    for (final c in _actionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '编辑月度Boss',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Boss HP 状态卡片
                  if (_boss != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            AppColors.primaryLight.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_boss!.month}月${_boss!.year}年 Boss战',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'HP ${_boss!.hp}/${_boss!.totalDays}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _boss!.hpPercent.clamp(0.0, 1.0),
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Boss 内容编辑
                  const Text(
                    '本月Boss内容',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '多个任务用"；"分隔，例如：读完《原子习惯》；每天跑步30分钟',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _bossContentController.text.isNotEmpty
                            ? AppColors.primary
                            : AppColors.textLight.withValues(alpha: 0.2),
                        width: _bossContentController.text.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _bossContentController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
                      decoration: InputDecoration(
                        hintText: '这个月最重要的挑战是什么？\n\n多个任务用"；"分隔',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textLight, height: 1.6),
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 每日行动编辑
                  Row(
                    children: [
                      const Text(
                        '每日行动',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _addAction,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
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
                  const SizedBox(height: 4),
                  Text(
                    '每天坚持的关键行动',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 14),

                  ...List.generate(_actionControllers.length, (index) {
                    final circledNumbers = ['①', '②', '③', '④', '⑤'];
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < _actionControllers.length - 1 ? 12 : 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8E53).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(7),
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
                              controller: _actionControllers[index],
                              maxLines: 2,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: '例如：每天跑步30分钟',
                                hintStyle: TextStyle(fontSize: 13, color: AppColors.textLight.withValues(alpha: 0.6)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFFF8E53), width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_actionControllers.length > 1)
                            GestureDetector(
                              onTap: () => _removeAction(index),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, top: 10),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.textLight.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                          : const Text(
                              '保存',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
