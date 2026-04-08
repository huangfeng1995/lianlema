import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';

class PetHomeScreen extends StatefulWidget {
  const PetHomeScreen({super.key});

  @override
  State<PetHomeScreen> createState() => _PetHomeScreenState();
}

class _PetHomeScreenState extends State<PetHomeScreen> {
  late StorageService _storage;
  bool _initialized = false;
  String _petName = '炭炭';
  int _coins = 50;
  String? _equippedCostume;
  List<String> _equippedDecorations = [];
  List<PetOwnedItem> _ownedItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    setState(() {
      _petName = _storage.getPetName();
      _coins = _storage.getPetCoins();
      _equippedCostume = _storage.getEquippedCostume();
      _equippedDecorations = _storage.getEquippedDecorations();
      _ownedItems = _storage.getPetOwnedItems();
      _initialized = true;
    });
  }

  List<PetOwnedItem> get _ownedSnacks => _ownedItems
      .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.snack)
      .toList();

  List<PetOwnedItem> get _ownedCostumes => _ownedItems
      .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.costume)
      .toList();

  List<PetOwnedItem> get _ownedDecorations => _ownedItems
      .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.decoration)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏠', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            const Text(
              '宠物家',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _initialized
          ? Column(
              children: [
                _buildPetArea(),
                Expanded(child: _buildBottomActions()),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildPetArea() {
    // 当前穿戴的外观
    final costume = _equippedCostume != null
        ? PetShopConfig.getById(_equippedCostume!)
        : null;
    // 当前家居装饰
    final decorations = _equippedDecorations
        .map((id) => PetShopConfig.getById(id))
        .whereType<PetShopItem>()
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadowLight,
      ),
      child: Column(
        children: [
          // 家居装饰图标（如果已装备）
          if (decorations.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: decorations.map((d) => Text(d.icon, style: const TextStyle(fontSize: 20))).toList(),
            ),
          if (decorations.isNotEmpty) const SizedBox(height: 8),

          // 宠物形象区域
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.whatshot, color: Colors.white, size: 48),
                if (costume != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Text(costume.icon, style: const TextStyle(fontSize: 20)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 宠物名字 + 等级
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _petName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lv${_getLevel()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 心情条
          _buildMoodBar(),
        ],
      ),
    );
  }

  Widget _buildMoodBar() {
    final moodLevel = _getMoodLevel();
    final moodText = _getMoodText();
    final moodColor = _getMoodColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '心情：',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: moodLevel,
                  backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              moodText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: moodColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _getLevel() {
    final checkIns = _storage.getCheckIns();
    return (checkIns.length ~/ 10) + 1;
  }

  double _getMoodLevel() {
    // 基于打卡频率简单计算心情（这里用连续天数模拟）
    final checkIns = _storage.getCheckIns();
    if (checkIns.isEmpty) return 0.4;
    final today = DateTime.now();
    final recent = checkIns.where((c) => today.difference(c.date).inDays <= 3).length;
    return (recent / 3).clamp(0.0, 1.0);
  }

  String _getMoodText() {
    final level = _getMoodLevel();
    if (level >= 0.8) return '超开心 ✨';
    if (level >= 0.6) return '开心';
    if (level >= 0.4) return '平静';
    if (level >= 0.2) return '有点丧';
    return '很低落';
  }

  Color _getMoodColor() {
    final level = _getMoodLevel();
    if (level >= 0.8) return const Color(0xFFFF6B35);
    if (level >= 0.6) return AppColors.primary;
    if (level >= 0.4) return AppColors.textSecondary;
    if (level >= 0.2) return const Color(0xFFFF9800);
    return Colors.red;
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildActionButton('🏠', '家居', _openDecorationSheet)),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton('🍪', '零食', _openSnackSheet)),
          const SizedBox(width: 12),
          Expanded(child: _buildActionButton('👗', '换装', _openCostumeSheet)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadowLight,
          border: Border.all(color: AppColors.textLight.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSnackSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SnackSheet(
        ownedSnacks: _ownedSnacks,
        coins: _coins,
        onUse: _useSnack,
        onRefresh: _loadData,
      ),
    );
  }

  void _openCostumeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CostumeSheet(
        ownedCostumes: _ownedCostumes,
        equippedCostume: _equippedCostume,
        onToggle: _toggleCostume,
        onRefresh: _loadData,
      ),
    );
  }

  void _openDecorationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DecorationSheet(
        ownedDecorations: _ownedDecorations,
        equippedDecorations: _equippedDecorations,
        onToggle: _toggleDecoration,
        onRefresh: _loadData,
      ),
    );
  }

  Future<void> _useSnack(PetOwnedItem owned) async {
    final item = PetShopConfig.getById(owned.itemId);
    if (item == null) return;

    // 移除已使用的零食
    await _storage.removePetOwnedItem(owned.itemId);
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_petName 吃了 ${item.icon}${item.name}，心情提升了！'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleCostume(PetOwnedItem owned, bool currentlyEquipped) async {
    if (currentlyEquipped) {
      await _storage.saveEquippedCostume(null);
    } else {
      await _storage.saveEquippedCostume(owned.itemId);
    }
    await _loadData();
  }

  Future<void> _toggleDecoration(PetOwnedItem owned, bool currentlyEquipped) async {
    final current = List<String>.from(_equippedDecorations);
    if (currentlyEquipped) {
      current.remove(owned.itemId);
    } else {
      current.add(owned.itemId);
    }
    await _storage.saveEquippedDecorations(current);
    await _loadData();
  }
}

class _SnackSheet extends StatelessWidget {
  final List<PetOwnedItem> ownedSnacks;
  final int coins;
  final void Function(PetOwnedItem) onUse;
  final VoidCallback onRefresh;

  const _SnackSheet({
    required this.ownedSnacks,
    required this.coins,
    required this.onUse,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('零食', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ownedSnacks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '还没有零食，快去商店买一些吧～',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ownedSnacks.map((o) {
                final item = PetShopConfig.getById(o.itemId)!;
                return _SnackChip(item: item, onTap: () {
                  onUse(o);
                  Navigator.pop(context);
                });
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SnackChip extends StatelessWidget {
  final PetShopItem item;
  final VoidCallback onTap;

  const _SnackChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            Text(
              '心情+${item.effect}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostumeSheet extends StatelessWidget {
  final List<PetOwnedItem> ownedCostumes;
  final String? equippedCostume;
  final void Function(PetOwnedItem, bool) onToggle;
  final VoidCallback onRefresh;

  const _CostumeSheet({
    required this.ownedCostumes,
    required this.equippedCostume,
    required this.onToggle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checkroom, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('换装', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ownedCostumes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '还没有外观，快去商店买一些吧～',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ownedCostumes.map((o) {
                final item = PetShopConfig.getById(o.itemId)!;
                final isEquipped = equippedCostume == o.itemId;
                return _ItemChip(
                  item: item,
                  isEquipped: isEquipped,
                  onTap: () {
                    onToggle(o, isEquipped);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DecorationSheet extends StatelessWidget {
  final List<PetOwnedItem> ownedDecorations;
  final List<String> equippedDecorations;
  final void Function(PetOwnedItem, bool) onToggle;
  final VoidCallback onRefresh;

  const _DecorationSheet({
    required this.ownedDecorations,
    required this.equippedDecorations,
    required this.onToggle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('家居', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ownedDecorations.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '还没有家居，快去商店买一些吧～',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ownedDecorations.map((o) {
                final item = PetShopConfig.getById(o.itemId)!;
                final isEquipped = equippedDecorations.contains(o.itemId);
                return _ItemChip(
                  item: item,
                  isEquipped: isEquipped,
                  onTap: () {
                    onToggle(o, isEquipped);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final PetShopItem item;
  final bool isEquipped;
  final VoidCallback onTap;

  const _ItemChip({
    required this.item,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isEquipped ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEquipped ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEquipped ? Colors.white : AppColors.primary,
              ),
            ),
            if (isEquipped) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
