/// 汇玉源 - 空状态组件
///
/// 用于显示各种空状态场景
/// - 空购物车
/// - 无搜索结果
/// - 无订单记录
/// - 网络错误
library;

import 'package:flutter/material.dart';
import '../../themes/colors.dart';

/// 空状态类型
enum EmptyType {
  cart, // 购物车为空
  search, // 搜索无结果
  order, // 无订单
  favorite, // 无收藏
  history, // 无浏览记录
  shop, // 无店铺数据
  network, // 网络错误
  general, // 通用空状态
}

/// 空状态组件
class EmptyStateWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final config = _getConfig();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
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

            // 标题
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

            // 副标题
            Text(
              subtitle ?? config['subtitle'] as String,
              style: TextStyle(
                fontSize: 14,
                color: JewelryColors.textSecondary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            // 操作按钮
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

  Map<String, dynamic> _getConfig() {
    switch (type) {
      case EmptyType.cart:
        return {
          'icon': Icons.shopping_cart_outlined,
          'title': '购物车空空如也',
          'subtitle': '快去挑选心仪的珠宝吧~',
          'action': '去逛逛',
        };
      case EmptyType.search:
        return {
          'icon': Icons.search_off,
          'title': '没有找到相关商品',
          'subtitle': '换个关键词试试吧',
          'action': null,
        };
      case EmptyType.order:
        return {
          'icon': Icons.receipt_long_outlined,
          'title': '暂无订单记录',
          'subtitle': '您还没有任何订单哦',
          'action': '去购物',
        };
      case EmptyType.favorite:
        return {
          'icon': Icons.favorite_border,
          'title': '暂无收藏',
          'subtitle': '收藏喜欢的商品，方便下次查看',
          'action': '去发现',
        };
      case EmptyType.history:
        return {
          'icon': Icons.history,
          'title': '暂无浏览记录',
          'subtitle': '您还没有浏览过任何商品',
          'action': null,
        };
      case EmptyType.shop:
        return {
          'icon': Icons.store_outlined,
          'title': '暂无店铺数据',
          'subtitle': '店铺信息正在加载中...',
          'action': '刷新',
        };
      case EmptyType.network:
        return {
          'icon': Icons.wifi_off,
          'title': '网络连接失败',
          'subtitle': '请检查网络设置后重试',
          'action': '重试',
        };
      case EmptyType.general:
        return {
          'icon': Icons.inbox_outlined,
          'title': '暂无数据',
          'subtitle': '这里还没有任何内容',
          'action': null,
        };
    }
  }
}

/// 加载中组件
class LoadingWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

/// 错误状态组件
class ErrorStateWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              title ?? '出错了',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: JewelryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? '请稍后重试',
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
                label: const Text('重试'),
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
