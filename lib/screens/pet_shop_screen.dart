import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../theme/app_theme.dart';
import '../utils/storage_service.dart';

class PetShopScreen extends StatefulWidget {
  const PetShopScreen({super.key});

  @override
  State<PetShopScreen> createState() => _PetShopScreenState();
}

class _PetShopScreenState extends State<PetShopScreen> {
  late StorageService _storage;
  bool _storageInitialized = false;
  int _selectedCategory = 0; // 0=全部, 1=外观, 2=零食, 3=家居
  int _coins = 50;
  int _moodValue = 50;

  final _categories = ['全部', '外观', '零食', '家居'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _storage = await StorageService.getInstance();
    setState(() {
      _storageInitialized = true;
      _coins = _storage.getPetCoins();
      _moodValue = _storage.getPetMoodValue();
    });
  }

  List<PetShopItem> get _filteredItems {
    switch (_selectedCategory) {
      case 1:
        return PetShopConfig.byCategory(PetShopCategory.costume);
      case 2:
        return PetShopConfig.byCategory(PetShopCategory.snack);
      case 3:
        return PetShopConfig.byCategory(PetShopCategory.decoration);
      default:
        return PetShopConfig.allItems;
    }
  }

  Future<void> _refreshCoins() async {
    setState(() {
      _coins = _storage.getPetCoins();
      _moodValue = _storage.getPetMoodValue();
    });
  }

  Future<void> _buyItem(PetShopItem item) async {
    final owned = _storage.getPetOwnedItems();
    final alreadyOwned = owned.any((o) => o.itemId == item.id);

    if (alreadyOwned && item.category == PetShopCategory.snack) {
      // 零食可以重复购买
    } else if (alreadyOwned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已拥有该物品')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(item.name, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            if (item.effect > 0)
              Text(
                '效果：心情+${item.effect}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('🪙 ', style: TextStyle(fontSize: 16)),
                Text(
                  '${item.price} 宠物币',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _coins >= item.price ? AppColors.primary : Colors.red,
                  ),
                ),
              ],
            ),
            if (_coins < item.price) ...[
              const SizedBox(height: 4),
              const Text(
                '宠物币不足',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _coins >= item.price ? () => Navigator.pop(ctx, true) : null,
            child: Text(_coins >= item.price ? '确认购买' : '宠物币不足'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 扣币
    final reason = switch (item.category) {
      PetShopCategory.snack => PetCoinReason.buySnack,
      PetShopCategory.costume => PetCoinReason.buyCostume,
      PetShopCategory.decoration => PetCoinReason.buyDecoration,
    };
    await _storage.addPetCoins(-item.price, reason);

    // 加入背包
    await _storage.addPetOwnedItem(PetOwnedItem(
      itemId: item.id,
      purchasedAt: DateTime.now(),
      equipped: false,
    ));

    // 购买零食时增加心情
    if (item.category == PetShopCategory.snack && item.effect > 0) {
      final currentMood = _storage.getPetMoodValue();
      await _storage.savePetMoodValue(currentMood + item.effect);
    }

    await _refreshCoins();

    if (!mounted) return;

    // 成功动画
    _showSuccessAnimation(item);
  }

  void _showSuccessAnimation(PetShopItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => _SuccessAnimationDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 8),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '宠物商店',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _storageInitialized
          ? Column(
              children: [
                _buildHeader(),
                _buildCategoryTabs(),
                Expanded(child: _buildGrid()),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primaryLight.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('宠物币', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getMoodEmoji(), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_moodValue',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _openBag,
            icon: const Icon(Icons.backpack_outlined, size: 18),
            label: const Text('背包'),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji() {
    if (_moodValue >= 80) return '😄';
    if (_moodValue >= 60) return '🙂';
    if (_moodValue >= 40) return '😐';
    if (_moodValue >= 20) return '😟';
    return '😢';
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_categories.length, (i) {
            final isSelected = _selectedCategory == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _categories[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return Center(
        child: Text('暂无商品', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _ShopItemCard(
        item: items[i],
        coins: _coins,
        onBuy: () => _buyItem(items[i]),
      ),
    );
  }

  void _openBag() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BagSheet(storage: _storage, onRefresh: _refreshCoins),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final PetShopItem item;
  final int coins;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.coins,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = coins >= item.price;
    return GestureDetector(
      onTap: onBuy,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadowLight,
          border: Border.all(
            color: AppColors.textLight.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              item.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: canAfford
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(canAfford ? '🪙' : '🔒', style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 2),
                  Text(
                    '${item.price}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: canAfford ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _SuccessAnimationDialog extends StatefulWidget {
  final PetShopItem item;
  const _SuccessAnimationDialog({required this.item});

  @override
  State<_SuccessAnimationDialog> createState() => _SuccessAnimationDialogState();
}

class _SuccessAnimationDialogState extends State<_SuccessAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadowLight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.item.icon, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                '购买成功！',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.category == PetShopCategory.snack
                    ? '已使用'
                    : '已加入背包',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BagSheet extends StatelessWidget {
  final StorageService storage;
  final VoidCallback onRefresh;
  const _BagSheet({required this.storage, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final owned = storage.getPetOwnedItems();
    final equippedCostume = storage.getEquippedCostume();
    final equippedDecorations = storage.getEquippedDecorations();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.backpack, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('背包', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (owned.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('背包空空，快去商店逛逛吧～', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...[
              // 外观
              if (owned.any((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.costume)) ...[
                const Text('外观', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: owned
                      .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.costume)
                      .map((o) {
                    final item = PetShopConfig.getById(o.itemId)!;
                    final isEquipped = equippedCostume == o.itemId;
                    return _BagItemChip(
                      item: item,
                      isEquipped: isEquipped,
                      onTap: () async {
                        if (isEquipped) {
                          await storage.saveEquippedCostume(null);
                        } else {
                          await storage.saveEquippedCostume(o.itemId);
                        }
                        onRefresh();
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // 家居
              if (owned.any((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.decoration)) ...[
                const Text('家居', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: owned
                      .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.decoration)
                      .map((o) {
                    final item = PetShopConfig.getById(o.itemId)!;
                    final isEquipped = equippedDecorations.contains(o.itemId);
                    return _BagItemChip(
                      item: item,
                      isEquipped: isEquipped,
                      onTap: () async {
                        final current = storage.getEquippedDecorations();
                        if (isEquipped) {
                          current.remove(o.itemId);
                        } else {
                          current.add(o.itemId);
                        }
                        await storage.saveEquippedDecorations(current);
                        onRefresh();
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              // 零食
              if (owned.any((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.snack)) ...[
                const Text('零食', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: owned
                      .where((o) => PetShopConfig.getById(o.itemId)?.category == PetShopCategory.snack)
                      .map((o) {
                    final item = PetShopConfig.getById(o.itemId)!;
                    return _BagItemChip(item: item, isEquipped: false, onTap: () {});
                  }).toList(),
                ),
              ],
            ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _BagItemChip extends StatelessWidget {
  final PetShopItem item;
  final bool isEquipped;
  final VoidCallback onTap;
  const _BagItemChip({
    required this.item,
    required this.isEquipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Text(item.icon, style: const TextStyle(fontSize: 16)),
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
              Icon(Icons.check_circle, size: 14, color: Colors.white.withValues(alpha: 0.8)),
            ],
          ],
        ),
      ),
    );
  }
}
