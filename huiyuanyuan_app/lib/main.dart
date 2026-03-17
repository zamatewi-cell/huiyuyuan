/// 汇玉源 - 珠宝智能交易平台
///
/// 版本: 3.0.0 企业智能版
///
/// 核心功能:
/// - 智能商城 (福利款手链)
/// - AI助手 (OpenRouter 多模态对话)
/// - 自动获客 (电商平台巡视)
/// - AR试戴 (虚拟珠宝试戴)
/// - 区块链存证 (材质证书上链)
/// - 直播监控 (话术实时分析)
///
/// 合规说明:
/// - 中国境内服务器部署
/// - 符合《个人信息保护法》
/// - 符合《广告法》违禁词过滤
/// - 简体中文界面
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/app_settings_provider.dart';
import 'themes/jewelry_theme.dart';
import 'themes/colors.dart';

// 页面导入
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/user_agreement_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // 锁定竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: HuiYuYuanApp(),
    ),
  );
}

/// 汇玉源应用主入口
class HuiYuYuanApp extends ConsumerStatefulWidget {
  const HuiYuYuanApp({super.key});

  @override
  ConsumerState<HuiYuYuanApp> createState() => _HuiYuYuanAppState();
}

class _HuiYuYuanAppState extends ConsumerState<HuiYuYuanApp> {
  /// 将 AppThemeMode 枚举映射为 Flutter ThemeMode
  ThemeMode _mapThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听 appSettingsProvider，主题和语言切换即时生效
    final settings = ref.watch(appSettingsProvider);
    final themeMode = _mapThemeMode(settings.themeMode);

    // 根据主题模式动态调整状态栏
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    // 延迟到帧结束后设置，避免 build() 中每帧重复调用平台通道
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            isDark ? const Color(0xFF121218) : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ));
    });

    // 根据语言设置确定 locale
    Locale appLocale;
    switch (settings.language) {
      case AppLanguage.zhCN:
        appLocale = const Locale('zh', 'CN');
        break;
      case AppLanguage.en:
        appLocale = const Locale('en', 'US');
        break;
      case AppLanguage.zhTW:
        appLocale = const Locale('zh', 'TW');
        break;
    }

    return MaterialApp(
      // 应用信息
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      // 主题配置 - 由 appSettingsProvider 驱动
      theme: JewelryTheme.light,
      darkTheme: JewelryTheme.dark,
      themeMode: themeMode,

      // 多语言支持
      locale: appLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
        Locale('zh', 'TW'),
      ],

      // 入口页面
      home: const _AppRouter(),

      // 页面构建器 - 添加全局配置
      builder: (context, child) {
        // 限制字体缩放
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// 应用路由 - 根据登录状态跳转，首次启动检查隐私授权
class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  static const _privacyKey = 'privacy_accepted_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrivacy());
  }

  Future<void> _checkPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_privacyKey) ?? false;
    if (!accepted && mounted) {
      await _showPrivacyConsent();
    }
  }

  Future<void> _showPrivacyConsent() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PrivacyConsentDialog(
        onAccept: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_privacyKey, true);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
        onDecline: () => SystemNavigator.pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (error, stack) => _ErrorScreen(error: error.toString()),
      data: (user) => user == null ? const LoginScreen() : const MainScreen(),
    );
  }
}

/// 启动页
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: JewelryColors.darkGradient,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: JewelryColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: JewelryColors.primary.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 品牌名
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, JewelryColors.gold],
                        ).createShader(bounds),
                        child: const Text(
                          '汇玉源',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        '珠宝智能交易平台',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // 加载指示器
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 错误页面
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: JewelryColors.darkGradient,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: JewelryColors.error.withOpacity(0.8),
              ),
              const SizedBox(height: 20),
              const Text(
                '加载出错',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // 重启应用 - 重新触发初始化流程
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (_) => false);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首次启动隐私授权弹窗（不可取消，符合《个人信息保护法》要求）
class _PrivacyConsentDialog extends StatelessWidget {
  const _PrivacyConsentDialog({
    required this.onAccept,
    required this.onDecline,
  });

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部 header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      JewelryColors.primary,
                      JewelryColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.diamond_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '汇玉源',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '用户隐私保护提示',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // 正文
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '在您开始使用之前，请仔细阅读以下内容：',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: TextSpan(
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[800],
                          height: 1.8,
                        ),
                        children: [
                          const TextSpan(text: '我们依据'),
                          TextSpan(
                            text: '《隐私政策》',
                            style: TextStyle(
                              color: JewelryColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PrivacyPolicyScreen(),
                                    ),
                                  ),
                          ),
                          const TextSpan(text: '和'),
                          TextSpan(
                            text: '《用户协议》',
                            style: TextStyle(
                              color: JewelryColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const UserAgreementScreen(),
                                    ),
                                  ),
                          ),
                          const TextSpan(
                            text:
                                ' 收集和处理您的个人信息，用于提供珠宝交易、AI对话等服务。我们不会将您的信息出售给第三方。',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击"同意并继续"即表示您已阅读并同意上述协议。',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // 按钮区域
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JewelryColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '同意并继续',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onDecline,
                        child: Text(
                          '不同意，退出',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
