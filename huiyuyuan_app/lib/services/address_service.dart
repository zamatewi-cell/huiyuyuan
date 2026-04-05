library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../data/china_regions.dart';
import '../models/address_model.dart';
import '../models/json_parsing.dart';
import 'api_service.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();

  factory AddressService() => _instance;

  AddressService._internal();

  static const String _storageKey = 'shipping_addresses';

  final ApiService _api = ApiService();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _api.initialize();
  }

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<AddressModel>> getAllAddresses() async {
    await init();
    final localAddresses = await _getLocalAddresses();
    final remoteAddresses = await _fetchRemoteAddresses();

    if (remoteAddresses == null) {
      return localAddresses;
    }

    if (remoteAddresses.isEmpty && localAddresses.isNotEmpty) {
      final syncedAddresses = await _syncLocalAddressesToBackend(localAddresses);
      if (syncedAddresses.isNotEmpty) {
        await _saveAddresses(syncedAddresses);
        return syncedAddresses;
      }
    }

    await _saveAddresses(remoteAddresses);
    return remoteAddresses;
  }

  Future<AddressModel?> getDefaultAddress() async {
    final addresses = await getAllAddresses();
    for (final address in addresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return addresses.isNotEmpty ? addresses.first : null;
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    await init();
    final localAddresses = await _getLocalAddresses();

    if (_api.isLoggedIn) {
      final result = await _api.post<AddressModel>(
        ApiConfig.userAddresses,
        data: _toPayload(address),
        fromJson: (data) => AddressModel.fromJson(jsonAsMap(data)),
      );
      if (result.success && result.data != null) {
        final remoteAddresses = await _fetchRemoteAddresses() ?? [result.data!];
        await _saveAddresses(remoteAddresses);
        return result.data!;
      }
    }

    final newAddress = address.copyWith(
      id: 'addr_local_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (newAddress.isDefault || localAddresses.isEmpty) {
      for (var index = 0; index < localAddresses.length; index++) {
        localAddresses[index] = localAddresses[index].copyWith(
          isDefault: false,
          updatedAt: DateTime.now(),
        );
      }
    }

    final finalAddress = localAddresses.isEmpty
        ? newAddress.copyWith(isDefault: true)
        : newAddress;

    localAddresses.add(finalAddress);
    await _saveAddresses(localAddresses);
    return finalAddress;
  }

  Future<void> updateAddress(AddressModel address) async {
    await init();

    if (_api.isLoggedIn) {
      final result = await _api.put<AddressModel>(
        ApiConfig.userAddressDetail(address.id),
        data: _toPayload(address),
        fromJson: (data) => AddressModel.fromJson(jsonAsMap(data)),
      );
      if (result.success && result.data != null) {
        final remoteAddresses = await _fetchRemoteAddresses() ?? [result.data!];
        await _saveAddresses(remoteAddresses);
        return;
      }
    }

    final addresses = await _getLocalAddresses();
    final index = addresses.indexWhere((item) => item.id == address.id);
    if (index < 0) {
      throw Exception('Address not found');
    }

    if (address.isDefault) {
      for (var itemIndex = 0; itemIndex < addresses.length; itemIndex++) {
        if (itemIndex != index) {
          addresses[itemIndex] = addresses[itemIndex].copyWith(
            isDefault: false,
            updatedAt: DateTime.now(),
          );
        }
      }
    }

    addresses[index] = address.copyWith(updatedAt: DateTime.now());
    await _saveAddresses(addresses);
  }

  Future<void> deleteAddress(String addressId) async {
    await init();

    if (_api.isLoggedIn) {
      final result = await _api.delete<dynamic>(
        ApiConfig.userAddressDetail(addressId),
      );
      if (result.success) {
        final remoteAddresses =
            await _fetchRemoteAddresses() ?? const <AddressModel>[];
        await _saveAddresses(remoteAddresses);
        return;
      }
    }

    final addresses = await _getLocalAddresses();
    final index = addresses.indexWhere((item) => item.id == addressId);
    if (index < 0) {
      return;
    }

    final wasDefault = addresses[index].isDefault;
    addresses.removeAt(index);

    if (wasDefault && addresses.isNotEmpty) {
      addresses[0] = addresses[0].copyWith(
        isDefault: true,
        updatedAt: DateTime.now(),
      );
    }

    await _saveAddresses(addresses);
  }

  Future<void> setDefaultAddress(String addressId) async {
    await init();

    final addresses = await getAllAddresses();
    AddressModel? current;
    for (final item in addresses) {
      if (item.id == addressId) {
        current = item;
        break;
      }
    }
    if (current == null) {
      return;
    }

    if (_api.isLoggedIn) {
      final result = await _api.put<AddressModel>(
        ApiConfig.userAddressDetail(addressId),
        data: _toPayload(current.copyWith(isDefault: true)),
        fromJson: (data) => AddressModel.fromJson(jsonAsMap(data)),
      );
      if (result.success) {
        final remoteAddresses = await _fetchRemoteAddresses() ?? addresses;
        await _saveAddresses(remoteAddresses);
        return;
      }
    }

    for (var index = 0; index < addresses.length; index++) {
      addresses[index] = addresses[index].copyWith(
        isDefault: addresses[index].id == addressId,
        updatedAt: DateTime.now(),
      );
    }

    await _saveAddresses(addresses);
  }

  Future<int> getAddressCount() async {
    final addresses = await getAllAddresses();
    return addresses.length;
  }

  Future<bool> hasAddress() async {
    final count = await getAddressCount();
    return count > 0;
  }

  Future<AddressModel?> getAddressById(String addressId) async {
    final addresses = await getAllAddresses();
    for (final address in addresses) {
      if (address.id == addressId) {
        return address;
      }
    }
    return null;
  }

  Future<void> clearAllAddresses() async {
    final prefs = await _storage;
    await prefs.remove(_storageKey);
  }

  Future<List<AddressModel>?> _fetchRemoteAddresses() async {
    if (!_api.isLoggedIn) {
      return null;
    }

    final result = await _api.get<List<AddressModel>>(
      ApiConfig.userAddresses,
      fromJson: (data) => jsonAsList(
        data,
        (item) => AddressModel.fromJson(jsonAsMap(item)),
      ),
    );

    if (!result.success || result.data == null) {
      return null;
    }

    return result.data!;
  }

  Future<List<AddressModel>> _syncLocalAddressesToBackend(
    List<AddressModel> localAddresses,
  ) async {
    if (!_api.isLoggedIn || localAddresses.isEmpty) {
      return localAddresses;
    }

    for (final address in localAddresses) {
      await _api.post<dynamic>(
        ApiConfig.userAddresses,
        data: _toPayload(address),
      );
    }

    return await _fetchRemoteAddresses() ?? localAddresses;
  }

  Future<List<AddressModel>> _getLocalAddresses() async {
    final prefs = await _storage;
    final data = prefs.getString(_storageKey);
    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(data) as List;
      return list
          .map((json) => AddressModel.fromJson(jsonAsMap(json)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAddresses(List<AddressModel> addresses) async {
    final prefs = await _storage;
    final data = addresses.map((address) => address.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Map<String, dynamic> _toPayload(AddressModel address) {
    return {
      'recipient_name': address.recipientName,
      'phone_number': address.phoneNumber,
      'province': address.province,
      'city': address.city,
      'district': address.district,
      'detail_address': address.detailAddress,
      'postal_code': address.postalCode,
      'tag': address.tag,
      'is_default': address.isDefault,
    };
  }
}

List<String> get chinaProvinces => ChinaRegions.provinces;
