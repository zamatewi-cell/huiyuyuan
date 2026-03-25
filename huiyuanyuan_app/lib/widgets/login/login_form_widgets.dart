import 'package:flutter/material.dart';

import '../../themes/colors.dart';
import '../common/gradient_button.dart';

class LoginCustomerForm extends StatelessWidget {
  const LoginCustomerForm({
    super.key,
    required this.phoneController,
    required this.authCodeController,
    required this.isLoading,
    required this.onLogin,
    required this.onSendCode,
    required this.countdown,
    required this.isSendingCode,
  });

  final TextEditingController phoneController;
  final TextEditingController authCodeController;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onSendCode;
  final int countdown;
  final bool isSendingCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('customer'),
      children: [
        LoginGlassInput(
          controller: phoneController,
          hint: '手机号码',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        LoginVerifyCodeRow(
          authCodeController: authCodeController,
          countdown: countdown,
          isSendingCode: isSendingCode,
          onSendCode: onSendCode,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: '验证并登录',
            icon: Icons.login,
            isLoading: isLoading,
            onPressed: onLogin,
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
}

class LoginAdminForm extends StatelessWidget {
  const LoginAdminForm({
    super.key,
    required this.phoneController,
    required this.passwordController,
    required this.authCodeController,
    required this.passwordSuffixIcon,
    required this.obscurePassword,
    required this.isLoading,
    required this.onLogin,
  });

  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController authCodeController;
  final Widget passwordSuffixIcon;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('admin'),
      children: [
        LoginGlassInput(
          controller: phoneController,
          hint: '管理员账号',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: passwordController,
          hint: '登录密码',
          icon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: passwordSuffixIcon,
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: authCodeController,
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
            isLoading: isLoading,
            onPressed: onLogin,
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
}

class LoginOperatorForm extends StatelessWidget {
  const LoginOperatorForm({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.passwordSuffixIcon,
    required this.obscurePassword,
    required this.isLoading,
    required this.onLogin,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Widget passwordSuffixIcon;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('operator'),
      children: [
        LoginGlassInput(
          controller: usernameController,
          hint: '操作员账号 (1-10号)',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: passwordController,
          hint: '登录密码',
          icon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: passwordSuffixIcon,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: '操作员登录',
            icon: Icons.login,
            isLoading: isLoading,
            gradient: JewelryColors.goldGradient,
            onPressed: onLogin,
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
}

class LoginVerifyCodeRow extends StatelessWidget {
  const LoginVerifyCodeRow({
    super.key,
    required this.authCodeController,
    required this.countdown,
    required this.isSendingCode,
    required this.onSendCode,
  });

  final TextEditingController authCodeController;
  final int countdown;
  final bool isSendingCode;
  final VoidCallback onSendCode;

  @override
  Widget build(BuildContext context) {
    const inputTextColor = Color(0xFF1A1A2E);
    const inputHintColor = Color(0xFF6B7280);
    const inputBgColor = Color(0xFFF8F9FB);

    final canSend = countdown == 0 && !isSendingCode;

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
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(),
              ),
              child: TextField(
                controller: authCodeController,
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
                  hintStyle: const TextStyle(
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
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFE5E7EB),
          ),
          GestureDetector(
            onTap: canSend ? onSendCode : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: isSendingCode
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: JewelryColors.primary,
                      ),
                    )
                  : Text(
                      countdown > 0 ? '重新发送 ($countdown秒)' : '获取验证码',
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
}

class LoginGlassInput extends StatelessWidget {
  const LoginGlassInput({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    const inputTextColor = Color(0xFF1A1A2E);
    const inputHintColor = Color(0xFF6B7280);
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
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: inputTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: JewelryColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: inputHintColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: JewelryColors.primary.withOpacity(0.8),
              size: 20,
            ),
            suffixIcon: suffixIcon,
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
}
