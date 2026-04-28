/// 汇玉源 - 购物车 Provider
/// 从 cart_screen.dart 迁移至此，遵循项目架构规范
/// 支持 CartItemModel 强类型 + API 同步 + 本地缓存
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

/// 购物车 Provider
final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

/// 购物车已选商品总价
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items
      .where((item) => item.isSelected)
      .fold(0.0, (sum, item) => sum + item.subtotal);
});

/// 购物车已选商品数量
final cartSelectedCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.where((item) => item.isSelected).length;
});

/// 购物车状态管理
class CartNotifier extends StateNotifier<List<CartItemModel>> {
  final _storage = StorageService();
  final _api = ApiService();

  CartNotifier() : super([]) {
    _loadCart();
  }

  /// 从本地存储加载购物车（兼容旧 Map 格式）
  Future<void> _loadCart() async {
    try {
      final cartData = await _storage.getCart();
      // 防止 dispose 后异步回调写入 state（测试容器提前销毁时会触发 Bad state）
      if (!mounted) return;
      state = cartData.map((map) => CartItemModel.fromJson(map)).toList();
    } catch (_) {
      if (!mounted) return;
      state = [];
    }
  }

  /// [私有] 保存时自动触发云端同步
  Future<void> _saveCart() async {
    final data = state.map((item) => item.toJson()).toList();
    await _storage.saveCart(data);

    // 尝试同步到服务端（非阻塞）
    _syncToServer();
  }

  /// 同步购物车到服务端（非阻塞，可供外部调用）
  void syncToServer() {
    _syncToServer();
  }

  /// 实际执行同步的私有方法
  Future<void> _syncToServer() async {
    try {
      // 后端API期望单个CartItem对象，逐项同步
      for (final item in state) {
        await _api.post(
          ApiConfig.cart,
          data: {
            'product_id': item.product.id,
            'quantity': item.quantity,
            'selected': item.isSelected,
          },
        );
      }
    } catch (_) {
      // 同步失败不影响本地操作
    }
  }

  /// 刷新购物车
  Future<void> refresh() async {
    await _loadCart();
  }

  /// 添加商品到购物车
  Future<void> addItem(ProductModel product,
      {int quantity = 1, String? spec}) async {
    final index = state.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      // 已存在则累加数量
      final existing = state[index];
      final updated = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
    } else {
      // 新增
      state = [
        ...state,
        CartItemModel(
          product: product,
          quantity: quantity,
          selectedSpec: spec,
        ),
      ];
    }

    await _saveCart();
  }

  /// 更新商品数量
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }

    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updated = state[index].copyWith(quantity: quantity);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
      await _saveCart();
    }
  }

  /// 切换选中状态
  void toggleSelect(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updated = state[index].copyWith(
        isSelected: !state[index].isSelected,
      );
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
    }
  }

  /// 全选/全不选
  void toggleSelectAll(bool selectAll) {
    state = state.map((item) => item.copyWith(isSelected: selectAll)).toList();
  }

  /// 是否全选
  bool get isAllSelected =>
      state.isNotEmpty && state.every((item) => item.isSelected);

  /// 移除商品
  Future<void> removeItem(String productId) async {
    state = state.where((item) => item.product.id != productId).toList();
    await _saveCart();
  }

  /// 移除已选商品
  Future<void> removeSelected() async {
    state = state.where((item) => !item.isSelected).toList();
    await _saveCart();
  }

  /// 清空购物车
  Future<void> clearCart() async {
    state = [];
    await _storage.clearCart();
  }

  /// 获取已选商品列表
  List<CartItemModel> get selectedItems =>
      state.where((item) => item.isSelected).toList();

  /// 总价（所有商品）
  double get totalAmount {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// 已选商品总价
  double get selectedTotalAmount {
    return selectedItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}
