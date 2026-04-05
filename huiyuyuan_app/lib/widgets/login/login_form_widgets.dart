import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../themes/colors.dart';
import '../common/gradient_button.dart';
import '../common/captcha_widget.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';
import 'login_copy.dart';

enum CustomerAuthMode {
  password,
  sms,
  register,
  reset,
}

class LoginCustomerForm extends ConsumerWidget {
  const LoginCustomerForm({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.authCodeController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.isLoading,
    required this.onSubmit,
    required this.onSendCode,
    required this.onForgotPassword,
    required this.onBackToPassword,
    required this.hasAcceptedAgreement,
    required this.onAgreementChanged,
    required this.onOpenAgreement,
    required this.onOpenPrivacy,
    required this.countdown,
    required this.isSendingCode,
    this.onCaptchaChanged,
    this.onCaptchaSessionChanged,
  });

  final CustomerAuthMode mode;
  final ValueChanged<CustomerAuthMode> onModeChanged;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController authCodeController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onSendCode;
  final VoidCallback onForgotPassword;
  final VoidCallback onBackToPassword;
  final bool hasAcceptedAgreement;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback onOpenAgreement;
  final VoidCallback onOpenPrivacy;
  final int countdown;
  final bool isSendingCode;
  final ValueChanged<String>? onCaptchaChanged;
  final ValueChanged<String?>? onCaptchaSessionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: ValueKey('customer-${mode.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mode == CustomerAuthMode.reset
              ? LoginCopy.resetTitle(context)
              : LoginCopy.customerTitle(context),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mode == CustomerAuthMode.reset
              ? LoginCopy.resetSubtitle(context)
              : LoginCopy.customerSubtitle(context),
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _CustomerModeSwitcher(
          mode: mode,
          onModeChanged: onModeChanged,
        ),
        const SizedBox(height: 18),
        LoginGlassInput(
          controller: phoneController,
          hint: 'login_phone_hint'.tr,
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          autofillHints: const [AutofillHints.telephoneNumber],
        ),
        if (mode == CustomerAuthMode.sms ||
            mode == CustomerAuthMode.register ||
            mode == CustomerAuthMode.reset) ...[
          const SizedBox(height: 16),
          LoginVerifyCodeRow(
            authCodeController: authCodeController,
            countdown: countdown,
            isSendingCode: isSendingCode,
            onSendCode: onSendCode,
          ),
        ],
        if (mode == CustomerAuthMode.password ||
            mode == CustomerAuthMode.register ||
            mode == CustomerAuthMode.reset) ...[
          const SizedBox(height: 16),
          LoginGlassInput(
            controller: passwordController,
            hint: mode == CustomerAuthMode.register
                ? LoginCopy.registerPasswordHint(context)
                : 'login_password_hint'.tr,
            icon: Icons.lock_outline,
            obscureText: obscurePassword,
            suffixIcon: _PasswordToggleButton(
              obscurePassword: obscurePassword,
              onPressed: onTogglePasswordVisibility,
            ),
            keyboardType: TextInputType.visiblePassword,
            autofillHints: mode == CustomerAuthMode.register
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
          ),
        ],
        if (mode == CustomerAuthMode.register ||
            mode == CustomerAuthMode.reset) ...[
          const SizedBox(height: 16),
          LoginGlassInput(
            controller: confirmPasswordController,
            hint: LoginCopy.confirmPasswordHint(context),
            icon: Icons.lock_person_outlined,
            obscureText: obscurePassword,
            suffixIcon: _PasswordToggleButton(
              obscurePassword: obscurePassword,
              onPressed: onTogglePasswordVisibility,
            ),
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.newPassword],
          ),
        ],
        if (mode == CustomerAuthMode.register) ...[
          const SizedBox(height: 16),
          _AgreementRow(
            checked: hasAcceptedAgreement,
            onChanged: onAgreementChanged,
            onOpenAgreement: onOpenAgreement,
            onOpenPrivacy: onOpenPrivacy,
          ),
        ],
        // 图形验证码（密码登录和注册时需要）
        if (mode == CustomerAuthMode.password ||
            mode == CustomerAuthMode.register) ...[
          const SizedBox(height: 16),
          CaptchaWidget(
            onCaptchaChanged: onCaptchaChanged ?? (_) {},
            onSessionIdChanged: onCaptchaSessionChanged ?? (_) {},
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: JewelryColors.primary.withOpacity(0.92),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tipText(context),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: _submitText(context, ref),
            icon: _submitIcon(),
            isLoading: isLoading,
            gradient: mode == CustomerAuthMode.register
                ? JewelryColors.goldGradient
                : null,
            onPressed: onSubmit,
          ),
        ),
        if (mode == CustomerAuthMode.password) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              child: Text(
                LoginCopy.forgotPassword(context),
                style: const TextStyle(
                  color: JewelryColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        if (mode == CustomerAuthMode.reset) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onBackToPassword,
              child: Text(
                LoginCopy.backToPassword(context),
                style: const TextStyle(
                  color: JewelryColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _submitText(BuildContext context, WidgetRef ref) {
    switch (mode) {
      case CustomerAuthMode.password:
        return LoginCopy.passwordLogin(context);
      case CustomerAuthMode.sms:
        return ref.tr('login_verify_login');
      case CustomerAuthMode.register:
        return LoginCopy.registerSubmit(context);
      case CustomerAuthMode.reset:
        return LoginCopy.resetSubmit(context);
    }
  }

  IconData _submitIcon() {
    switch (mode) {
      case CustomerAuthMode.register:
        return Icons.person_add_alt_1;
      case CustomerAuthMode.reset:
        return Icons.lock_reset;
      case CustomerAuthMode.password:
      case CustomerAuthMode.sms:
        return Icons.login;
    }
  }

  String _tipText(BuildContext context) {
    switch (mode) {
      case CustomerAuthMode.password:
        return LoginCopy.passwordModeHint(context);
      case CustomerAuthMode.sms:
        return LoginCopy.smsModeHint(context);
      case CustomerAuthMode.register:
        return LoginCopy.registerModeHint(context);
      case CustomerAuthMode.reset:
        return LoginCopy.resetModeHint(context);
    }
  }
}

class _CustomerModeSwitcher extends StatelessWidget {
  const _CustomerModeSwitcher({
    required this.mode,
    required this.onModeChanged,
  });

  final CustomerAuthMode mode;
  final ValueChanged<CustomerAuthMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _CustomerModeChip(
            label: LoginCopy.modePassword(context),
            icon: Icons.lock_outline,
            selected: mode == CustomerAuthMode.password ||
                mode == CustomerAuthMode.reset,
            onTap: () => onModeChanged(CustomerAuthMode.password),
          ),
          const SizedBox(width: 6),
          _CustomerModeChip(
            label: LoginCopy.modeSms(context),
            icon: Icons.chat_bubble_outline,
            selected: mode == CustomerAuthMode.sms,
            onTap: () => onModeChanged(CustomerAuthMode.sms),
          ),
          const SizedBox(width: 6),
          _CustomerModeChip(
            label: LoginCopy.modeRegister(context),
            icon: Icons.person_add_alt_1,
            selected: mode == CustomerAuthMode.register,
            onTap: () => onModeChanged(CustomerAuthMode.register),
          ),
        ],
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.checked,
    required this.onChanged,
    required this.onOpenAgreement,
    required this.onOpenPrivacy,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenAgreement;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-10, -10),
          child: Checkbox(
            value: checked,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: JewelryColors.primary,
            side: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
        ),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text(
                LoginCopy.agreementPrefix(context),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 12,
                ),
              ),
              _AgreementLink(
                label: LoginCopy.agreementUserAgreement(context),
                onTap: onOpenAgreement,
              ),
              Text(
                LoginCopy.agreementAnd(context),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 12,
                ),
              ),
              _AgreementLink(
                label: LoginCopy.agreementPrivacyPolicy(context),
                onTap: onOpenPrivacy,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgreementLink extends StatelessWidget {
  const _AgreementLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: JewelryColors.gold,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CustomerModeChip extends StatelessWidget {
  const _CustomerModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            gradient: selected ? JewelryColors.primaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.white.withOpacity(0.75),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      selected ? Colors.white : Colors.white.withOpacity(0.75),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordToggleButton extends StatelessWidget {
  const _PasswordToggleButton({
    required this.obscurePassword,
    required this.onPressed,
  });

  final bool obscurePassword;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: const Color(0xFF9CA3AF),
        size: 20,
      ),
      onPressed: onPressed,
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
          hint: 'login_admin_account_hint'.tr,
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: passwordController,
          hint: 'login_password_hint'.tr,
          icon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: passwordSuffixIcon,
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.password],
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: authCodeController,
          hint: 'login_admin_code_hint'.tr,
          icon: Icons.verified_user_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'login_admin_login'.tr,
            icon: Icons.login,
            isLoading: isLoading,
            onPressed: onLogin,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'login_admin_contact_hint'.tr,
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
          hint: 'login_operator_account_hint'.tr,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: passwordController,
          hint: 'login_password_hint'.tr,
          icon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: passwordSuffixIcon,
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.password],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'login_operator_login'.tr,
            icon: Icons.login,
            isLoading: isLoading,
            gradient: JewelryColors.goldGradient,
            onPressed: onLogin,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'login_operator_desc'.tr,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class LoginVerifyCodeRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                  hintText: 'login_sms_code_hint'.tr,
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
                      countdown > 0
                          ? LoginCopy.resendCode(context, countdown)
                          : ref.tr('login_get_code'),
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
    this.autofillHints,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final int? maxLength;

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
          autofillHints: autofillHints,
          maxLength: maxLength,
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
    );
  }
}
