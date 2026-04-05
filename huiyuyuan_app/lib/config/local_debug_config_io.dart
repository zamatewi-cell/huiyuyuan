library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class LocalDebugConfig {
  LocalDebugConfig._();

  static final LocalDebugConfig instance = LocalDebugConfig._();

  Map<String, dynamic> _values = const {};
  bool _loaded = false;
  String? _loadedFromPath;
  String? _loadError;

  String? get loadedFromPath => _loadedFromPath;
  String? get loadError => _loadError;

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;

    if (kReleaseMode) {
      return;
    }

    final file = await _findConfigFile();
    if (file == null) {
      return;
    }

    try {
      final decoded = jsonDecode(await file.readAsString()) as Map;
      _values = Map<String, dynamic>.from(decoded);
      _loadedFromPath = file.path;
      _loadError = null;
    } catch (error) {
      _values = const {};
      _loadedFromPath = file.path;
      _loadError = error.toString();
    }
  }

  String? getString(String key) {
    final value = _values[key];
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool? getBool(String key) {
    final value = _values[key];
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    final normalized = value.toString().trim().toLowerCase();
    switch (normalized) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
      case 'off':
        return false;
      default:
        return null;
    }
  }

  void replaceValuesForTesting(
    Map<String, dynamic> values, {
    String? loadedFromPath,
    String? loadError,
  }) {
    _loaded = true;
    _values = Map<String, dynamic>.from(values);
    _loadedFromPath = loadedFromPath;
    _loadError = loadError;
  }

  void clearForTesting() {
    _loaded = false;
    _values = const {};
    _loadedFromPath = null;
    _loadError = null;
  }

  Future<File?> _findConfigFile() async {
    var current = Directory.current;
    for (var depth = 0; depth < 8; depth++) {
      final directFile = File(
        '${current.path}${Platform.pathSeparator}.env.json',
      );
      if (await directFile.exists()) {
        return directFile;
      }

      final nestedFile = File(
        '${current.path}${Platform.pathSeparator}huiyuyuan_app'
        '${Platform.pathSeparator}.env.json',
      );
      if (await nestedFile.exists()) {
        return nestedFile;
      }

      if (current.parent.path == current.path) {
        break;
      }
      current = current.parent;
    }
    return null;
  }
}
