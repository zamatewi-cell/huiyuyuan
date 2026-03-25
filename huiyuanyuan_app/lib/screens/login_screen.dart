/// 汇玉源 - 极致UI登录页面
/// 玻璃态 + 渐变 + 动画 设计风格
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../themes/colors.dart';

import '../widgets/login/login_form_widgets.dart';
import '../widgets/login/login_shell_widgets.dart';

/// 登录页面
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // 控制器
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _usernameController = TextEditingController();

  int _selectedTab = 0; // 0: 用户, 1: 操作员, 2: 管理员
  bool _isLoading = false;
  bool _obscurePassword = true;

  // 验证码倒计时
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isSendingCode = false;

  // 动画控制器
  late AnimationController _backgroundController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // 背景渐变动画
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 浮动装饰动画
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _authCodeController.dispose();
    _usernameController.dispose();
    _backgroundController.dispose();
    _floatController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          LoginAnimatedBackground(animation: _backgroundController),
          LoginDecorations(size: size, animation: _floatAnimation),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LoginBrandLogo(),
                    const SizedBox(height: 40),
                    LoginCardShell(
                      selectedTab: _selectedTab,
                      onTabChanged: (tab) {
                        setState(() => _selectedTab = tab);
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildActiveForm(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const LoginFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveForm() {
    switch (_selectedTab) {
      case 1:
        return LoginOperatorForm(
          usernameController: _usernameController,
          passwordController: _passwordController,
          passwordSuffixIcon: _buildPasswordToggleButton(),
          obscurePassword: _obscurePassword,
          isLoading: _isLoading,
          onLogin: _loginAsOperator,
        );
      case 2:
        return LoginAdminForm(
          phoneController: _phoneController,
          passwordController: _passwordController,
          authCodeController: _authCodeController,
          passwordSuffixIcon: _buildPasswordToggleButton(),
          obscurePassword: _obscurePassword,
          isLoading: _isLoading,
          onLogin: _loginAsAdmin,
        );
      case 0:
      default:
        return LoginCustomerForm(
          phoneController: _phoneController,
          authCodeController: _authCodeController,
          isLoading: _isLoading,
          onLogin: _loginAsCustomer,
          onSendCode: _sendSmsCode,
          countdown: _countdown,
          isSendingCode: _isSendingCode,
        );
    }
  }

  Widget _buildPasswordToggleButton() {
    return IconButton(
      icon: Icon(
        _obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: const Color(0xFF9CA3AF),
        size: 20,
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  /// 发送短信验证码
  Future<void> _sendSmsCode() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showError('请输入正确的手机号');
      return;
    }

    setState(() => _isSendingCode = true);
    final result = await ref.read(authProvider.notifier).sendSmsCode(phone);
    setState(() => _isSendingCode = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // 启助60秒倒计时
      setState(() => _countdown = 60);
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
          }
        });
      });
      _showCodeDialog(result['message'] as String);
    } else {
      _showError(result['message'] as String? ?? '发送失败');
    }
  }

  /// 用户登录
  Future<void> _loginAsCustomer() async {
    if (_isLoading) return;

    final phone = _phoneController.text.trim();
    final authCode = _authCodeController.text.trim();

    if (phone.isEmpty) {
      _showError('请输入手机号');
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showError('手机号格式不正确');
      return;
    }

    if (authCode.isEmpty) {
      _showError('请输入验证码');
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(authProvider.notifier);
    final success = await notifier.loginCustomer(
      phone,
      authCode,
    );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showError(notifier.lastLoginError ?? '验证码错误，请重新获取');
    }
  }

  /// 管理员登录
  Future<void> _loginAsAdmin() async {
    if (_isLoading) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final authCode = _authCodeController.text.trim();

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).loginAdmin(
          phone,
          password,
          authCode,
        );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showError('密码或验证码错误');
    }
  }

  /// 操作员登录
  Future<void> _loginAsOperator() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showError('请输入操作员账号');
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).loginOperator(
          username,
          password,
        );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showError('账号或密码错误');
    }
  }

  /// 显示验证码弹窗（测试模式下使验证码醒目可见）
  void _showCodeDialog(String message) {
    // 从 message 中提取验证码（格式："（测试模式）验证码：123456"）
    final codeMatch = RegExp(r'\d{6}').firstMatch(message);
    final code = codeMatch?.group(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sms, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('验证码', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code != null) ...[
              const Text('您的验证码为（5分钟有效）：',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('【测试模式，真实短信待审核】',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ] else
              Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的，已记住',
                style: TextStyle(color: Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: JewelryColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
