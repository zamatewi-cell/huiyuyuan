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
import '../../providers/app_settings_provider.dart';
import 'dart:ui';
import '../../models/user_data_models.dart';
import '../../themes/colors.dart';
import '../../services/user_data_service.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/error_handler.dart';

class _ProfileListBackdrop extends StatelessWidget {
  const _ProfileListBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          const BoxDecoration(gradient: JewelryColors.jadeDepthGradient),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _ProfileListGlowOrb(
              size: 320,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            bottom: 120,
            child: _ProfileListGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileListGlowOrb extends StatelessWidget {
  const _ProfileListGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 96, spreadRadius: 28),
        ],
      ),
    );
  }
}

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
      backgroundColor: JewelryColors.jadeBlack,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileListBackdrop()),
          historyAsync.when(
            data: (history) => history.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(context, history),
            loading: () => _buildLoadingState(),
            error: (error, _) => _buildErrorState(error),
          ),
        ],
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
            color: JewelryColors.jadeBlack.withOpacity(0.84),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: JewelryColors.jadeMist,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.deepJade.withOpacity(0.62),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.14),
                          ),
                        ),
                        child: Text(
                          ref.tr('profile_history'),
                          style: const TextStyle(
                            color: JewelryColors.jadeMist,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: JewelryColors.jadeMist,
                    ),
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

  Widget _buildEmptyState() {
    return Center(
      child: GlassmorphicCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        borderRadius: 26,
        blur: 16,
        opacity: 0.18,
        borderColor: JewelryColors.champagneGold.withOpacity(0.14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: JewelryColors.jadeMist.withOpacity(0.34),
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr('profile_history_empty_title'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ref.tr('profile_history_empty_subtitle'),
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.58),
                fontSize: 14,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: GlassmorphicCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        borderRadius: 26,
        blur: 16,
        opacity: 0.18,
        borderColor: JewelryColors.error.withOpacity(0.22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: JewelryColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr(
                'browse_history_load_failed',
                params: {'error': error.toString()},
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: JewelryColors.jadeMist.withOpacity(0.68),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(browseHistoryProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.emeraldLuster,
                foregroundColor: JewelryColors.jadeBlack,
                elevation: 0,
              ),
              child: Text(ref.tr('retry')),
            ),
          ],
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
    List<BrowseHistoryItem> history,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          ref.tr('browse_history_clear_title'),
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          ref.tr('browse_history_clear_confirm'),
          style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.68)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              ref.tr('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.58)),
            ),
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
                  SnackBar(
                    content: Text(ref.tr('browse_history_cleared')),
                    backgroundColor: JewelryColors.emeraldShadow,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                context.showError(ref.tr('search_clear_fail'));
              }
            },
            child: Text(
              ref.tr('confirm'),
              style: const TextStyle(color: JewelryColors.error),
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
    final lang = ref.watch(appSettingsProvider).language;
    final product = item.product;
    final imageUrl = product.images.isEmpty ? null : product.images.first;

    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      borderRadius: 22,
      blur: 16,
      opacity: 0.17,
      borderColor: JewelryColors.champagneGold.withOpacity(0.12),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: JewelryColors.jadeBlack.withOpacity(0.28),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: JewelryColors.champagneGold.withOpacity(0.12),
              ),
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
                        color: JewelryColors.emeraldGlow.withOpacity(0.5),
                      ),
                    ),
                  )
                : Icon(
                    Icons.diamond_outlined,
                    size: 32,
                    color: JewelryColors.emeraldGlow.withOpacity(0.5),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.localizedTitleFor(lang).isEmpty
                      ? ref.tr('product_unknown')
                      : product.localizedTitleFor(lang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: JewelryColors.jadeMist,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (product.localizedMaterialFor(lang).isNotEmpty)
                  Text(
                    product.localizedMaterialFor(lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: JewelryColors.jadeMist.withOpacity(0.58),
                    ),
                  ),
                if (product.price > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '¥${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: JewelryColors.champagneGold,
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
                color: JewelryColors.emeraldGlow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: JewelryColors.emeraldGlow.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.add_shopping_cart,
                color: JewelryColors.emeraldGlow,
                size: 20,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ref.tr('product_added_cart')),
                  backgroundColor: JewelryColors.emeraldShadow,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
