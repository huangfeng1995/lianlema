import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';
import '../models/pet_models.dart';

class PetEvolutionScreen extends StatefulWidget {
  const PetEvolutionScreen({super.key});

  @override
  State<PetEvolutionScreen> createState() => _PetEvolutionScreenState();
}

class _PetEvolutionScreenState extends State<PetEvolutionScreen> {
  late StorageService _storage;
  int _currentLevel = 1;
  int _currentStreak = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    setState(() {
      _currentLevel = _storage.getPetAppearanceLevel();
      _currentStreak = _storage.getUserStats().totalCheckIns;
      _loaded = true;
    });
  }

  // 6个阶段
  final stages = [
    _EvolutionStage(1, '🥚', '蛋', 0, '等待孵化'),
    _EvolutionStage(2, '🐣', '孵化', 3, '即将破壳'),
    _EvolutionStage(3, '🔥', '初级', 7, '小火苗'),
    _EvolutionStage(4, '⚡', '中级', 30, '火焰精灵'),
    _EvolutionStage(5, '👑', '高级', 100, '火焰使者'),
    _EvolutionStage(6, '🌟', '终极', 365, '永恒之火'),
  ];

  IconData _getStageIcon(String emoji) {
    switch (emoji) {
      case '🥚': return Icons.egg_outlined;
      case '🐣': return Icons.egg;
      case '🔥': return Icons.local_fire_department;
      case '⚡': return Icons.bolt;
      case '👑': return Icons.star;
      case '🌟': return Icons.star_border;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '外观进化',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatus(_currentLevel, _currentStreak),
            const SizedBox(height: 24),
            _buildSectionTitle('进化路线图'),
            const SizedBox(height: 12),
            _buildEvolutionTimeline(stages, _currentLevel, _currentStreak),
            const SizedBox(height: 24),
            if (_currentLevel < 6) ...[
              _buildSectionTitle('下一阶段预览'),
              const SizedBox(height: 12),
              _buildNextStagePreview(stages[_currentLevel], _currentStreak),
            ] else ...[
              _buildSectionTitle('已达到最高形态'),
              const SizedBox(height: 12),
              _buildMaxLevelCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCurrentStatus(int level, int streak) {
    final stage = PetAppearanceLevel.getStage(level);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getStageIcon(stage?.evolutionEmoji ?? '🥚'),
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage?.name ?? '蛋',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '累计打卡 \$streak 天',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lv.\$level',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildEvolutionTimeline(List<_EvolutionStage> stages, int currentLevel, int streak) {
    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isUnlocked = currentLevel >= stage.level;
        final isCurrent = currentLevel == stage.level;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? AppColors.primary 
                        : AppColors.textLight.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: isCurrent 
                        ? Border.all(color: AppColors.primary, width: 3)
                        : null,
                    boxShadow: isUnlocked 
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      _getStageIcon(stage.emoji),
                      size: 24,
                      color: isUnlocked ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
                if (index < stages.length - 1)
                  Container(
                    width: 2,
                    height: 50,
                    color: currentLevel > stage.level
                        ? AppColors.primary
                        : AppColors.textLight.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? AppColors.cardBackground 
                      : AppColors.textLight.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrent 
                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                stage.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isUnlocked 
                                      ? AppColors.textPrimary 
                                      : AppColors.textLight,
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '当前',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stage.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '\${stage.requiredDays}天解锁',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isUnlocked) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\${stage.requiredDays - streak}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          Text(
                            '天',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNextStagePreview(_EvolutionStage nextStage, int streak) {
    final daysRemaining = nextStage.requiredDays - streak;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getStageIcon(nextStage.emoji),
                size: 32,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '距离「\${nextStage.name}」还差',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$daysRemaining',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '天',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '保持每日打卡，即可解锁「\${nextStage.name}」',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaxLevelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD700).withValues(alpha: 0.2),
            Color(0xFFFF6B35).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFFD700).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.star_fill,
            size: 48,
            color: Color(0xFFFFD700),
          ),
          const SizedBox(height: 8),
          Text(
            '你已达到最高形态！',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '永恒之火，与你同在',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionStage {
  final int level;
  final String emoji;
  final String name;
  final int requiredDays;
  final String description;

  _EvolutionStage(this.level, this.emoji, this.name, this.requiredDays, this.description);
}
