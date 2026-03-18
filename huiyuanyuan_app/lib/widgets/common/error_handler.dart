/// 汇玉源 - 错误处理工具
///
/// 功能:
/// - 统一错误处理
/// - 用户友好的错误提示
/// - 错误日志记录
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 错误类型枚举
enum ErrorType {
  network,    // 网络错误
  auth,       // 认证错误
  validation, // 验证错误
  server,     // 服务器错误
  unknown,    // 未知错误
}

/// 错误信息封装
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

  /// 从异常创建AppError
  factory AppError.fromException(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;

    String message = error.toString();
    ErrorType type = ErrorType.unknown;

    // 根据错误信息判断类型
    if (message.contains('网络') || message.contains('连接') || message.contains('超时')) {
      type = ErrorType.network;
    } else if (message.contains('登录') || message.contains('认证') || message.contains('权限')) {
      type = ErrorType.auth;
    } else if (message.contains('验证') || message.contains('格式') || message.contains('不能为空')) {
      type = ErrorType.validation;
    } else if (message.contains('服务器') || message.contains('500') || message.contains('502') || message.contains('503')) {
      type = ErrorType.server;
    }

    return AppError(
      type: type,
      message: message,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 获取用户友好的错误消息
  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return '网络连接不稳定，请检查网络后重试';
      case ErrorType.auth:
        return '登录已过期，请重新登录';
      case ErrorType.validation:
        return message;
      case ErrorType.server:
        return '服务器繁忙，请稍后重试';
      case ErrorType.unknown:
        return '操作失败，请稍后重试';
    }
  }

  /// 获取错误图标
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

/// 错误处理工具类
class ErrorHandler {
  ErrorHandler._();

  /// 处理错误并显示SnackBar
  static void showError(BuildContext context, dynamic error, [StackTrace? stackTrace]) {
    final appError = AppError.fromException(error, stackTrace);
    
    // 记录错误日志
    _logError(appError);

    // 显示用户友好的错误提示
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
            label: '知道了',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// 处理错误并显示对话框
  static Future<void> showErrorDialog(BuildContext context, dynamic error, [StackTrace? stackTrace]) async {
    final appError = AppError.fromException(error, stackTrace);
    
    // 记录错误日志
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
            const Text('提示'),
          ],
        ),
        content: Text(appError.userFriendlyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 记录错误日志
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

  /// 获取错误对应的颜色
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

  /// 包装异步操作，自动处理错误
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

/// 扩展BuildContext以方便使用错误处理
extension ErrorHandlingExtension on BuildContext {
  /// 显示错误SnackBar
  void showError(dynamic error, [StackTrace? stackTrace]) {
    ErrorHandler.showError(this, error, stackTrace);
  }

  /// 显示错误对话框
  Future<void> showErrorDialog(dynamic error, [StackTrace? stackTrace]) {
    return ErrorHandler.showErrorDialog(this, error, stackTrace);
  }

  /// 包装异步操作
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