/// HuiYuYuan contact record service.
///
/// Responsibilities:
/// - CRUD for contact records with local persistence and API sync
/// - Support the shop detail screen and operator workspace
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/json_parsing.dart';
import 'api_service.dart';

/// Contact record model.
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

/// Contact record service backed by local storage and API sync.
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

  /// Returns the contact records for a specific shop.
  Future<List<ContactRecord>> getShopContacts(String shopId) async {
    // Prefer the API when it is available.
    try {
      final result = await _api.get<dynamic>('/api/shops/$shopId/contacts');
      if (result.success && result.data != null) {
        final data = result.data;
        if (data is List) {
          return data.map((j) => ContactRecord.fromJson(jsonAsMap(j))).toList();
        }
      }
    } catch (e) {
      debugPrint('[ContactService] Failed to fetch shop contacts from API: $e');
    }

    // Fall back to local storage.
    final all = await _getAllLocal();
    return all.where((r) => r.shopId == shopId).toList();
  }

  /// Returns recent contact records for the operator workspace.
  Future<List<ContactRecord>> getRecentContacts({int limit = 5}) async {
    // Prefer the API when it is available.
    try {
      final result = await _api.get<dynamic>(
        '/api/contacts/recent',
        params: {'limit': limit},
      );
      if (result.success && result.data != null) {
        final data = result.data;
        if (data is List) {
          return data.map((j) => ContactRecord.fromJson(jsonAsMap(j))).toList();
        }
      }
    } catch (e) {
      debugPrint(
        '[ContactService] Failed to fetch recent contacts from API: $e',
      );
    }

    // Fall back to local storage.
    final all = await _getAllLocal();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).toList();
  }

  /// Adds a contact record locally and then syncs it to the API.
  Future<void> addRecord(ContactRecord record) async {
    // Save locally first.
    final all = await _getAllLocal();
    all.insert(0, record);
    await _saveAllLocal(all);

    // Sync to the API asynchronously.
    try {
      await _api.post<dynamic>(
        '/api/shops/${record.shopId}/contacts',
        data: record.toJson(),
      );
    } catch (e) {
      debugPrint('[ContactService] Failed to sync contact record to API: $e');
    }
  }

  // Local storage helpers.

  Future<List<ContactRecord>> _getAllLocal() async {
    final prefs = await _storage;
    final json = prefs.getString(_storageKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((j) => ContactRecord.fromJson(jsonAsMap(j))).toList();
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
