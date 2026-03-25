/// 汇玉源 - 收货地址服务
///
/// 功能:
/// - 地址CRUD操作
/// - 默认地址管理
/// - 本地存储
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';
import '../models/json_parsing.dart';

/// 地址服务类
class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  static const String _storageKey = 'shipping_addresses';
  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============ 地址 CRUD ============

  /// 获取所有地址
  Future<List<AddressModel>> getAllAddresses() async {
    final prefs = await _storage;
    final data = prefs.getString(_storageKey);
    if (data == null) return [];

    try {
      final list = jsonDecode(data) as List;
      return list.map((json) => AddressModel.fromJson(jsonAsMap(json))).toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取默认地址
  Future<AddressModel?> getDefaultAddress() async {
    final addresses = await getAllAddresses();
    try {
      return addresses.firstWhere((a) => a.isDefault);
    } catch (e) {
      // 如果没有默认地址，返回第一个
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  /// 添加地址
  Future<AddressModel> addAddress(AddressModel address) async {
    final addresses = await getAllAddresses();

    // 生成ID
    final newId = 'ADDR-${DateTime.now().millisecondsSinceEpoch}';
    final newAddress = address.copyWith(
      id: newId,
      createdAt: DateTime.now(),
    );

    // 如果是第一个地址或者设为默认，更新其他地址
    if (newAddress.isDefault || addresses.isEmpty) {
      for (var i = 0; i < addresses.length; i++) {
        addresses[i] = addresses[i].copyWith(isDefault: false);
      }
    }

    // 如果是第一个地址，自动设为默认
    final finalAddress =
        addresses.isEmpty ? newAddress.copyWith(isDefault: true) : newAddress;

    addresses.add(finalAddress);
    await _saveAddresses(addresses);

    return finalAddress;
  }

  /// 更新地址
  Future<void> updateAddress(AddressModel address) async {
    final addresses = await getAllAddresses();
    final index = addresses.indexWhere((a) => a.id == address.id);

    if (index < 0) {
      throw Exception('地址不存在');
    }

    // 如果设为默认，取消其他地址的默认状态
    if (address.isDefault) {
      for (var i = 0; i < addresses.length; i++) {
        if (i != index) {
          addresses[i] = addresses[i].copyWith(isDefault: false);
        }
      }
    }

    addresses[index] = address.copyWith(updatedAt: DateTime.now());
    await _saveAddresses(addresses);
  }

  /// 删除地址
  Future<void> deleteAddress(String addressId) async {
    final addresses = await getAllAddresses();
    final index = addresses.indexWhere((a) => a.id == addressId);

    if (index < 0) return;

    final wasDefault = addresses[index].isDefault;
    addresses.removeAt(index);

    // 如果删除的是默认地址，自动设置第一个为默认
    if (wasDefault && addresses.isNotEmpty) {
      addresses[0] = addresses[0].copyWith(isDefault: true);
    }

    await _saveAddresses(addresses);
  }

  /// 设置默认地址
  Future<void> setDefaultAddress(String addressId) async {
    final addresses = await getAllAddresses();

    for (var i = 0; i < addresses.length; i++) {
      addresses[i] = addresses[i].copyWith(
        isDefault: addresses[i].id == addressId,
        updatedAt: addresses[i].id == addressId ? DateTime.now() : null,
      );
    }

    await _saveAddresses(addresses);
  }

  /// 保存地址列表
  Future<void> _saveAddresses(List<AddressModel> addresses) async {
    final prefs = await _storage;
    final data = addresses.map((a) => a.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  // ============ 辅助方法 ============

  /// 获取地址数量
  Future<int> getAddressCount() async {
    final addresses = await getAllAddresses();
    return addresses.length;
  }

  /// 检查是否有地址
  Future<bool> hasAddress() async {
    final count = await getAddressCount();
    return count > 0;
  }

  /// 根据ID获取地址
  Future<AddressModel?> getAddressById(String addressId) async {
    final addresses = await getAllAddresses();
    try {
      return addresses.firstWhere((a) => a.id == addressId);
    } catch (e) {
      return null;
    }
  }

  /// 清空所有地址
  Future<void> clearAllAddresses() async {
    final prefs = await _storage;
    await prefs.remove(_storageKey);
  }
}

/// 中国省份列表
const List<String> chinaProvinces = [
  '北京市',
  '天津市',
  '上海市',
  '重庆市',
  '河北省',
  '山西省',
  '辽宁省',
  '吉林省',
  '黑龙江省',
  '江苏省',
  '浙江省',
  '安徽省',
  '福建省',
  '江西省',
  '山东省',
  '河南省',
  '湖北省',
  '湖南省',
  '广东省',
  '海南省',
  '四川省',
  '贵州省',
  '云南省',
  '陕西省',
  '甘肃省',
  '青海省',
  '台湾省',
  '内蒙古自治区',
  '广西壮族自治区',
  '西藏自治区',
  '宁夏回族自治区',
  '新疆维吾尔自治区',
  '香港特别行政区',
  '澳门特别行政区',
];
