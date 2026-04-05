/// 汇玉源 - 浏览记录页面
///
/// 功能:
/// - 按日期分组展示浏览记录
/// - 清空浏览记录
/// - 商品快速加购
library;

import '../../models/product_model.dart';

import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../models/user_data_models.dart';
import '../../themes/colors.dart';
import '../../themes/jewelry_theme.dart';
import '../../services/user_data_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/error_handler.dart';

final _userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

final browseHistoryProvider =
    FutureProvider<List<BrowseHistoryItem>>((ref) async {
  final service = ref.watch(_userDataServiceProvider);
  await service.initialize();
  return await service.getBrowseHistoryWithDetails();
});

class BrowseHistoryScreen extends ConsumerStatefulWidget {
  const BrowseHistoryScreen({super.key});

  @override
  ConsumerState<BrowseHistoryScreen> createState() =>
      _BrowseHistoryScreenState();
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
              Icon(Icons.error_outline, size: 48, color: JewelryColors.error),
              SizedBox(height: 16),
              Text(ref.tr('browse_history_load_failed',
                  params: {'error': error.toString()})),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(browseHistoryProvider),
                child: Text(ref.tr('retry')),
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
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      ref.tr('profile_history'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.white),
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
      padding: EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ListItemSkeleton(),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<BrowseHistoryItem> history,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        return _HistoryCard(item: history[index]);
      },
    );
  }

  void _showClearDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: Text(ref.tr('browse_history_clear_title')),
        content: Text(ref.tr('browse_history_clear_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(ref.tr('cancel')),
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
                  SnackBar(content: Text(ref.tr('browse_history_cleared'))),
                );
              } else {
                context.showError(ref.tr('search_clear_fail'));
              }
            },
            child: Text(
              ref.tr('confirm'),
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final BrowseHistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = item.product;
    final imageUrl = product.images.isEmpty ? null : product.images.first;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
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
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.titleL10n.isEmpty
                      ? ref.tr('product_unknown')
                      : product.titleL10n,
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
                SizedBox(height: 4),
                if (product.matL10n.isNotEmpty)
                  Text(
                    product.matL10n,
                    style: const TextStyle(
                      fontSize: 12,
                      color: JewelryColors.textSecondary,
                    ),
                  ),
                if (product.price > 0) ...[
                  SizedBox(height: 4),
                  Text(
                    '¥${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
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
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: JewelryColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add_shopping_cart,
                color: JewelryColors.primary,
                size: 20,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ref.tr('product_added_cart'))),
              );
            },
          ),
        ],
      ),
    );
  }
}
