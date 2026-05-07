import 'package:flutter/material.dart';
import '../../l10n/translator_global.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/colors.dart';
import '../common/gradient_button.dart';
import '../common/captcha_widget.dart';
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
            color: JewelryColors.champagneGold,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          mode == CustomerAuthMode.reset
              ? LoginCopy.resetSubtitle(context)
              : LoginCopy.customerSubtitle(context),
          style: TextStyle(
            color: JewelryColors.jadeMist.withOpacity(0.7),
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
          hint: TranslatorGlobal.instance.translate('login_phone_hint'),
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
                : TranslatorGlobal.instance.translate('login_password_hint'),
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
            color: JewelryColors.deepJade.withOpacity(0.56),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: JewelryColors.emeraldGlow.withOpacity(0.86),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tipText(context),
                  style: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.68),
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
                  color: JewelryColors.champagneGold,
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
                  color: JewelryColors.champagneGold,
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
        return TranslatorGlobal.instance.translate('login_verify_login');
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
        color: JewelryColors.deepJade.withOpacity(0.58),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
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
                  color: JewelryColors.jadeMist.withOpacity(0.72),
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
                  color: JewelryColors.jadeMist.withOpacity(0.72),
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
          color: JewelryColors.champagneGold,
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
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            gradient: selected ? JewelryColors.emeraldLusterGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected ? JewelryShadows.emeraldHalo : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? JewelryColors.jadeBlack
                    : JewelryColors.jadeMist.withOpacity(0.72),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected
                      ? JewelryColors.jadeBlack
                      : JewelryColors.jadeMist.withOpacity(0.72),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
        color: JewelryColors.jadeMist.withOpacity(0.56),
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
          hint: TranslatorGlobal.instance.translate('login_admin_account_hint'),
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: passwordController,
          hint: TranslatorGlobal.instance.translate('login_password_hint'),
          icon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: passwordSuffixIcon,
          keyboardType: TextInputType.visiblePassword,
          autofillHints: const [AutofillHints.password],
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: authCodeController,
          hint: TranslatorGlobal.instance.translate('login_admin_code_hint'),
          icon: Icons.verified_user_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: TranslatorGlobal.instance.translate('login_admin_login'),
            icon: Icons.login,
            isLoading: isLoading,
            onPressed: onLogin,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          TranslatorGlobal.instance.translate('login_admin_contact_hint'),
          style: TextStyle(
            fontSize: 12,
            color: JewelryColors.jadeMist.withOpacity(0.48),
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
          hint: TranslatorGlobal.instance
              .translate('login_operator_account_hint'),
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        LoginGlassInput(
          controller: passwordController,
          hint: TranslatorGlobal.instance.translate('login_password_hint'),
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
            text: TranslatorGlobal.instance.translate('login_operator_login'),
            icon: Icons.login,
            isLoading: isLoading,
            gradient: JewelryColors.champagneGradient,
            onPressed: onLogin,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          TranslatorGlobal.instance.translate('login_operator_desc'),
          style: TextStyle(
            fontSize: 12,
            color: JewelryColors.jadeMist.withOpacity(0.48),
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
    final canSend = countdown == 0 && !isSendingCode;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.13),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
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
                  color: JewelryColors.jadeMist,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: JewelryColors.emeraldGlow,
                decoration: InputDecoration(
                  hintText: TranslatorGlobal.instance
                      .translate('login_sms_code_hint'),
                  hintStyle: TextStyle(
                    color: JewelryColors.jadeMist.withOpacity(0.46),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.chat_outlined,
                    color: JewelryColors.emeraldGlow.withOpacity(0.78),
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
            color: JewelryColors.champagneGold.withOpacity(0.14),
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
                        color: JewelryColors.emeraldGlow,
                      ),
                    )
                  : Text(
                      countdown > 0
                          ? LoginCopy.resendCode(context, countdown)
                          : TranslatorGlobal.instance
                              .translate('login_get_code'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canSend
                            ? JewelryColors.champagneGold
                            : JewelryColors.jadeMist.withOpacity(0.38),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.13),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: JewelryColors.primary.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
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
            color: JewelryColors.jadeMist,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: JewelryColors.emeraldGlow,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.46),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: JewelryColors.emeraldGlow.withOpacity(0.78),
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
