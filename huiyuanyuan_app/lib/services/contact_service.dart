/// 汇玉源 - 联系记录服务
///
/// 功能:
/// - 联系记录 CRUD (本地持久化 + API 同步)
/// - 用于店铺详情页和操作员工作台
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/json_parsing.dart';
import 'api_service.dart';

/// 联系记录模型
class ContactRecord {
  final String id;
  final String shopId;
  final String shopName;
  final String date;
  final String action;
  final String result;
  final String? note;
  final String? statusColor;

  ContactRecord({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.date,
    required this.action,
    required this.result,
    this.note,
    this.statusColor,
  });

  factory ContactRecord.fromJson(Map<String, dynamic> json) {
    return ContactRecord(
      id: jsonAsString(json['id']),
      shopId: jsonAsString(json['shop_id']),
      shopName: jsonAsString(json['shop_name']),
      date: jsonAsString(json['date']),
      action: jsonAsString(json['action']),
      result: jsonAsString(json['result']),
      note: jsonAsNullableString(json['note']),
      statusColor: jsonAsNullableString(json['status_color']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'shop_name': shopName,
        'date': date,
        'action': action,
        'result': result,
        'note': note,
        'status_color': statusColor,
      };
}

/// 联系记录服务 — 本地存储 + API 同步
class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  static const String _storageKey = 'contact_records';
  SharedPreferences? _prefs;
  final ApiService _api = ApiService();

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 获取某店铺的联系记录
  Future<List<ContactRecord>> getShopContacts(String shopId) async {
    // 尝试 API
    try {
      final result = await _api.get<dynamic>('/api/shops/$shopId/contacts');
      if (result.success && result.data != null) {
        final data = result.data;
        if (data is List) {
          return data
              .map((j) => ContactRecord.fromJson(jsonAsMap(j)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ContactService] API 获取联系记录失败: $e');
    }

    // 降级: 本地存储
    final all = await _getAllLocal();
    return all.where((r) => r.shopId == shopId).toList();
  }

  /// 获取最近联系记录（操作员工作台用）
  Future<List<ContactRecord>> getRecentContacts({int limit = 5}) async {
    // 尝试 API
    try {
      final result = await _api.get<dynamic>(
        '/api/contacts/recent',
        params: {'limit': limit},
      );
      if (result.success && result.data != null) {
        final data = result.data;
        if (data is List) {
          return data
              .map((j) => ContactRecord.fromJson(jsonAsMap(j)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ContactService] API 获取最近联系失败: $e');
    }

    // 降级: 本地存储
    final all = await _getAllLocal();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).toList();
  }

  /// 添加联系记录
  Future<void> addRecord(ContactRecord record) async {
    // 本地保存
    final all = await _getAllLocal();
    all.insert(0, record);
    await _saveAllLocal(all);

    // 异步同步到 API
    try {
      await _api.post<dynamic>(
        '/api/shops/${record.shopId}/contacts',
        data: record.toJson(),
      );
    } catch (e) {
      debugPrint('[ContactService] API 同步联系记录失败: $e');
    }
  }

  // ─── 本地存储 ───

  Future<List<ContactRecord>> _getAllLocal() async {
    final prefs = await _storage;
    final json = prefs.getString(_storageKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((j) => ContactRecord.fromJson(jsonAsMap(j)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAllLocal(List<ContactRecord> records) async {
    final prefs = await _storage;
    final json = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
