library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../themes/colors.dart';

enum EmptyType {
  cart,
  search,
  order,
  favorite,
  history,
  shop,
  network,
  general,
}

class EmptyStateWidget extends ConsumerWidget {
  final EmptyType type;
  final String? title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final double? iconSize;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyType.general,
    this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _getConfig(ref);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize ?? 120,
              height: iconSize ?? 120,
              decoration: BoxDecoration(
                color: JewelryColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                config['icon'] as IconData,
                size: (iconSize ?? 120) * 0.5,
                color: JewelryColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? config['title'] as String,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: JewelryColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? config['subtitle'] as String,
              style: TextStyle(
                fontSize: 14,
                color: JewelryColors.textSecondary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null || config['action'] != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(actionText ?? config['action'] as String),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getConfig(WidgetRef ref) {
    switch (type) {
      case EmptyType.cart:
        return {
          'icon': Icons.shopping_cart_outlined,
          'title': ref.tr('cart_empty'),
          'subtitle': ref.tr('cart_empty_subtitle'),
          'action': ref.tr('browse_products'),
        };
      case EmptyType.search:
        return {
          'icon': Icons.search_off,
          'title': ref.tr('search_empty'),
          'subtitle': ref.tr('search_discover'),
          'action': null,
        };
      case EmptyType.order:
        return {
          'icon': Icons.receipt_long_outlined,
          'title': ref.tr('order_empty_title'),
          'subtitle': ref.tr('order_empty_subtitle'),
          'action': ref.tr('order_empty_action'),
        };
      case EmptyType.favorite:
        return {
          'icon': Icons.favorite_border,
          'title': ref.tr('favorite_empty_title'),
          'subtitle': ref.tr('favorite_empty_subtitle'),
          'action': ref.tr('browse_products'),
        };
      case EmptyType.history:
        return {
          'icon': Icons.history,
          'title': ref.tr('profile_history_empty_title'),
          'subtitle': ref.tr('profile_history_empty_subtitle'),
          'action': null,
        };
      case EmptyType.shop:
        return {
          'icon': Icons.store_outlined,
          'title': ref.tr('shop_empty_title'),
          'subtitle': ref.tr('shop_loading_subtitle'),
          'action': ref.tr('refresh'),
        };
      case EmptyType.network:
        return {
          'icon': Icons.wifi_off,
          'title': ref.tr('network_error_title'),
          'subtitle': ref.tr('network_error_subtitle'),
          'action': ref.tr('retry'),
        };
      case EmptyType.general:
        return {
          'icon': Icons.inbox_outlined,
          'title': ref.tr('no_data'),
          'subtitle': ref.tr('general_empty_subtitle'),
          'action': null,
        };
    }
  }
}

class LoadingWidget extends ConsumerWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? JewelryColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: JewelryColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorStateWidget extends ConsumerWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? ref.tr('error'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: JewelryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? ref.tr('please_retry_later'),
              style: TextStyle(
                fontSize: 14,
                color: JewelryColors.textSecondary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(ref.tr('retry')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: JewelryColors.primary,
                  side: const BorderSide(color: JewelryColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
