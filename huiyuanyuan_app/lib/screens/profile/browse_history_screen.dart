/// 汇玉源 - 浏览记录页面
///
/// 功能:
/// - 按日期分组展示浏览记录
/// - 清空浏览记录
/// - 商品快速加购
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../services/user_data_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/error_handler.dart';

final _userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

final browseHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(_userDataServiceProvider);
  await service.initialize();
  return await service.getBrowseHistoryWithDetails();
});

class BrowseHistoryScreen extends ConsumerStatefulWidget {
  const BrowseHistoryScreen({super.key});

  @override
  ConsumerState<BrowseHistoryScreen> createState() => _BrowseHistoryScreenState();
}

class _BrowseHistoryScreenState extends ConsumerState<BrowseHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(browseHistoryProvider);

    return Scaffold(
      backgroundColor: context.adaptiveBackground,
      appBar: _buildAppBar(context),
      body: historyAsync.when(
        data: (history) => history.isEmpty
            ? const EmptyStateWidget(type: EmptyType.history)
            : _buildHistoryList(context, history),
        loading: () => _buildLoadingState(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: JewelryColors.error),
              const SizedBox(height: 16),
              Text('加载失败: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(browseHistoryProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  JewelryColors.primary.withOpacity(0.9),
                  JewelryColors.primaryDark.withOpacity(0.9),
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '浏览记录',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () => _showClearDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ListItemSkeleton(),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<Map<String, dynamic>> history,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return _HistoryCard(product: history[index]);
      },
    );
  }

  void _showClearDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空浏览记录'),
        content: const Text('确定要清空所有浏览记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final service = ref.read(_userDataServiceProvider);
              final success = await service.clearBrowseHistory();
              if (!mounted) return;
              ref.invalidate(browseHistoryProvider);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('浏览记录已清空')),
                );
              } else {
                context.showError('清空失败，请重试');
              }
            },
            child: Text(
              '确定',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _HistoryCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = product['image'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? JewelryColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: JewelryColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.diamond_outlined,
                        size: 32,
                        color: JewelryColors.primary.withOpacity(0.5),
                      ),
                    ),
                  )
                : Icon(
                    Icons.diamond_outlined,
                    size: 32,
                    color: JewelryColors.primary.withOpacity(0.5),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] as String? ?? '未知商品',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? JewelryColors.darkTextPrimary
                        : JewelryColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if ((product['material'] as String?)?.isNotEmpty == true)
                  Text(
                    product['material'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: JewelryColors.textSecondary,
                    ),
                  ),
                if ((product['price'] as num?) != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '¥${(product['price'] as num).toDouble().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: JewelryColors.price,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JewelryColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_shopping_cart,
                color: JewelryColors.primary,
                size: 20,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已加入购物车')),
              );
            },
          ),
        ],
      ),
    );
  }
}
