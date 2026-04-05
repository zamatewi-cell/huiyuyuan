/// HuiYuYuan error handling helpers.
///
/// Features:
/// - unified error handling
/// - user-friendly error messages
/// - error logging
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

/// Error type enum.
enum ErrorType {
  network, // 网络错误
  auth, // 认证错误
  validation, // 验证错误
  server, // 服务器错误
  unknown, // 未知错误
}

/// Error payload wrapper.
class AppError {
  final ErrorType type;
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// Creates an [AppError] from an exception.
  factory AppError.fromException(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    String message = error.toString();
    ErrorType type = ErrorType.unknown;
    final normalized = message.toLowerCase();

    // Match common Chinese/Traditional/English backend and client error tokens.
    if (_containsAny(normalized, [
      '网络',
      '網路',
      '连接',
      '連線',
      'connect',
      'connection',
      'timeout',
      'timed out',
      '超时',
      '超時',
    ])) {
      type = ErrorType.network;
    } else if (_containsAny(normalized, [
      '登录',
      '登入',
      'login',
      'sign in',
      '认证',
      '認證',
      'auth',
      'unauthorized',
      '权限',
      '權限',
      'forbidden',
      'permission',
    ])) {
      type = ErrorType.auth;
    } else if (_containsAny(normalized, [
      '验证',
      '驗證',
      'validation',
      '格式',
      'format',
      '不能为空',
      '不能為空',
      'required',
      'invalid',
    ])) {
      type = ErrorType.validation;
    } else if (_containsAny(normalized, [
      '服务器',
      '伺服器',
      'server',
      'internal server error',
      'bad gateway',
      'service unavailable',
      '500',
      '502',
      '503',
    ])) {
      type = ErrorType.server;
    }

    return AppError(
      type: type,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Returns a user-friendly error message.
  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'error_network_retry'.tr;
      case ErrorType.auth:
        return 'error_session_expired'.tr;
      case ErrorType.validation:
        return message;
      case ErrorType.server:
        return 'error_server_busy'.tr;
      case ErrorType.unknown:
        return 'error_operation_failed_retry'.tr;
    }
  }

  /// Returns the icon for the error type.
  IconData get icon {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.auth:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_amber;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }
}

/// Error handling utilities.
class ErrorHandler {
  ErrorHandler._();

  /// Handles an error and shows a snackbar.
  static void showError(BuildContext context, dynamic error,
      [StackTrace? stackTrace]) {
    final appError = AppError.fromException(error, stackTrace);

    // Log the error details.
    _logError(appError);

    // Show a user-friendly error message.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(appError.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appError.userFriendlyMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _getErrorColor(appError.type),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'action_got_it'.tr,
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Handles an error and shows a dialog.
  static Future<void> showErrorDialog(BuildContext context, dynamic error,
      [StackTrace? stackTrace]) async {
    final appError = AppError.fromException(error, stackTrace);

    // Log the error details.
    _logError(appError);

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(appError.icon, color: _getErrorColor(appError.type)),
            const SizedBox(width: 8),
            Text('common_notice'.tr),
          ],
        ),
        content: Text(appError.userFriendlyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  /// Logs an error for debugging.
  static void _logError(AppError error) {
    if (kDebugMode) {
      debugPrint('''
╔══════════════════════════════════════════════════════════════
║ 错误类型: ${error.type}
║ 错误消息: ${error.message}
║ 错误代码: ${error.code ?? 'N/A'}
║ 原始错误: ${error.originalError ?? 'N/A'}
╚══════════════════════════════════════════════════════════════
      ''');
    }
  }

  /// Returns the color associated with the error type.
  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.auth:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.redAccent;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  /// Wraps an async operation with consistent error handling.
  static Future<T?> wrapAsync<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? errorMessage,
    bool showDialog = false,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (!context.mounted) return null;
      if (showDialog) {
        await showErrorDialog(context, e, stackTrace);
      } else {
        showError(context, e, stackTrace);
      }
      return null;
    }
  }
}

bool _containsAny(String message, List<String> needles) {
  for (final needle in needles) {
    if (message.contains(needle.toLowerCase())) {
      return true;
    }
  }
  return false;
}

/// Convenience extensions for error handling on [BuildContext].
extension ErrorHandlingExtension on BuildContext {
  /// Shows an error snackbar.
  void showError(dynamic error, [StackTrace? stackTrace]) {
    ErrorHandler.showError(this, error, stackTrace);
  }

  /// Shows an error dialog.
  Future<void> showErrorDialog(dynamic error, [StackTrace? stackTrace]) {
    return ErrorHandler.showErrorDialog(this, error, stackTrace);
  }

  /// Wraps an async operation.
  Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showDialog = false,
  }) {
    return ErrorHandler.wrapAsync(
      this,
      operation,
      errorMessage: errorMessage,
      showDialog: showDialog,
    );
  }
}
