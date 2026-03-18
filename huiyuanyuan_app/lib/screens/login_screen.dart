/// 汇玉源 - 极致UI登录页面
/// 玻璃态 + 渐变 + 动画 设计风格
library;

import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../themes/colors.dart';

import '../widgets/common/gradient_button.dart';

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
          // 动态渐变背景
          _buildAnimatedBackground(),

          // 装饰元素
          _buildDecorations(size),

          // 主内容
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 品牌Logo
                    _buildBrandLogo(),
                    const SizedBox(height: 40),

                    // 登录卡片
                    _buildLoginCard(),

                    const SizedBox(height: 24),

                    // 底部信息
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 动态渐变背景
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_backgroundController.value * 2 * math.pi),
                math.sin(_backgroundController.value * 2 * math.pi),
              ),
              end: Alignment(
                math.cos(_backgroundController.value * 2 * math.pi + math.pi),
                math.sin(_backgroundController.value * 2 * math.pi + math.pi),
              ),
              colors: const [
                Color(0xFF0D1B2A),
                Color(0xFF1B263B),
                Color(0xFF1F4037),
                Color(0xFF0D1B2A),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  /// 装饰元素
  Widget _buildDecorations(Size size) {
    return Stack(
      children: [
        // 左上装饰球
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              top: -80 + _floatAnimation.value,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      JewelryColors.primary.withOpacity(0.3),
                      JewelryColors.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // 右下装饰球
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: -100 - _floatAnimation.value,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      JewelryColors.gold.withOpacity(0.2),
                      JewelryColors.gold.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // 中间小装饰
        Positioned(
          top: size.height * 0.3,
          right: 30,
          child: _buildFloatingJewel(JewelryColors.jadeite, 15),
        ),
        Positioned(
          top: size.height * 0.6,
          left: 40,
          child: _buildFloatingJewel(JewelryColors.gold, 10),
        ),
        Positioned(
          bottom: size.height * 0.25,
          right: 60,
          child: _buildFloatingJewel(JewelryColors.amethyst, 12),
        ),
      ],
    );
  }

  /// 浮动宝石装饰
  Widget _buildFloatingJewel(Color color, double size) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.5),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 品牌Logo
  Widget _buildBrandLogo() {
    return Column(
      children: [
        // Logo图标 - 玉石手链样式
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: JewelryColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: JewelryColors.primary.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 外圈 - 模拟手链
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 8,
                  ),
                ),
              ),
              // 小珠子装饰
              ..._buildJadeBeads(),
              // 中心图标
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 品牌名称
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, JewelryColors.gold],
          ).createShader(bounds),
          child: const Text(
            '汇玉源',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '珠宝智能交易平台',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  /// 生成玉珠装饰
  List<Widget> _buildJadeBeads() {
    final beads = <Widget>[];
    const beadCount = 8;
    const radius = 36.0;

    for (int i = 0; i < beadCount; i++) {
      final angle = (i / beadCount) * 2 * math.pi - math.pi / 2;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      beads.add(
        Positioned(
          left: 50 + x - 5,
          top: 50 + y - 5,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  i % 2 == 0 ? JewelryColors.hetianYu : JewelryColors.jadeite,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return beads;
  }

  /// 登录卡片
  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Tab切换
              _buildTabSelector(),
              const SizedBox(height: 28),

              // 表单内容
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTab == 0
                    ? _buildCustomerForm()
                    : _selectedTab == 1
                        ? _buildOperatorForm()
                        : _buildAdminForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab选择器
  Widget _buildTabSelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient:
                      _selectedTab == 0 ? JewelryColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color:
                            _selectedTab == 0 ? Colors.white : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '用户账号',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              _selectedTab == 0 ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient:
                      _selectedTab == 1 ? JewelryColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 16,
                        color:
                            _selectedTab == 1 ? Colors.white : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '操作员',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              _selectedTab == 1 ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient:
                      _selectedTab == 2 ? JewelryColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color:
                            _selectedTab == 2 ? Colors.white : Colors.white60,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '管理员',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              _selectedTab == 2 ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 用户登录表单
  Widget _buildCustomerForm() {
    return Column(
      key: const ValueKey('customer'),
      children: [
        _buildGlassInput(
          controller: _phoneController,
          hint: '手机号码',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        // 验证码输入框 + 获取按钮
        _buildVerifyCodeRow(),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: '验证并登录',
            icon: Icons.login,
            isLoading: _isLoading,
            onPressed: _loginAsCustomer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '未注册手机号登录即自动创建账号',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// 验证码输入框＋倒计时获取按钮
  Widget _buildVerifyCodeRow() {
    const inputTextColor = Color(0xFF1A1A2E);
    final inputHintColor = const Color(0xFF6B7280);
    const inputBgColor = Color(0xFFF8F9FB);

    final bool canSend = _countdown == 0 && !_isSendingCode;

    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 验证码输入区
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(),
              ),
              child: TextField(
                controller: _authCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  color: inputTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: JewelryColors.primary,
                decoration: InputDecoration(
                  hintText: '短信验证码',
                  hintStyle: TextStyle(
                    color: inputHintColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_outlined,
                    color: JewelryColors.primary.withOpacity(0.8),
                    size: 20,
                  ),
                  counterText: '',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
          // 分隔线
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFE5E7EB),
          ),
          // 获取验证码按钮
          GestureDetector(
            onTap: canSend ? _sendSmsCode : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: _isSendingCode
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: JewelryColors.primary,
                      ),
                    )
                  : Text(
                      _countdown > 0 ? '重新发送 ($_countdown秒)' : '获取验证码',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canSend
                            ? JewelryColors.primary
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
            ),
          ),
        ],
      ),
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

  /// 管理员登录表单
  Widget _buildAdminForm() {
    return Column(
      key: const ValueKey('admin'),
      children: [
        _buildGlassInput(
          controller: _phoneController,
          hint: '管理员账号',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildGlassInput(
          controller: _passwordController,
          hint: '登录密码',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _buildGlassInput(
          controller: _authCodeController,
          hint: '管理员验证码',
          icon: Icons.verified_user_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: '管理员登录',
            icon: Icons.login,
            isLoading: _isLoading,
            onPressed: _loginAsAdmin,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '管理员账号请联系系统管理员获取',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  /// 操作员登录表单
  Widget _buildOperatorForm() {
    return Column(
      key: const ValueKey('operator'),
      children: [
        _buildGlassInput(
          controller: _usernameController,
          hint: '操作员账号 (1-10号)',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        _buildGlassInput(
          controller: _passwordController,
          hint: '登录密码',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: '操作员登录',
            icon: Icons.login,
            isLoading: _isLoading,
            gradient: JewelryColors.goldGradient,
            onPressed: _loginAsOperator,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '10个独立账户 · 数据相互隔离',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  /// 玻璃态输入框
  /// 注意: 登录页始终使用深色渐变背景，因此输入框样式独立于系统主题
  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    // 登录页始终是深色背景，输入框使用固定的高对比度配色
    const inputTextColor = Color(0xFF1A1A2E);
    final inputHintColor = const Color(0xFF6B7280);
    const inputBgColor = Color(0xFFF8F9FB);

    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.95),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: JewelryColors.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        // 覆盖主题，确保输入框不受全局 inputDecorationTheme 影响
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(),
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: inputTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: JewelryColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: inputHintColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: JewelryColors.primary.withOpacity(0.8),
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  /// 底部信息
  Widget _buildFooter() {
    return Column(
      children: [
        // 安全提示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(width: 6),
            Text(
              '数据加密传输 · 符合等保三级',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 汇玉源 · 中国境内合规运营',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
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
