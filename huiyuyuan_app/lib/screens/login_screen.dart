/// HuiYuYuan login entry with an animated glassmorphism shell.
library;

import 'dart:async';
import '../l10n/translator_global.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../utils/url_helper.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/user_agreement_screen.dart';
import '../themes/colors.dart';
import '../widgets/login/login_copy.dart';
import '../widgets/login/login_form_widgets.dart';
import '../widgets/login/login_shell_widgets.dart';

/// Login screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // Form controllers.
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _usernameController = TextEditingController();

  int _selectedTab = 0; // 0: customer, 1: operator, 2: admin
  CustomerAuthMode _customerMode = CustomerAuthMode.password;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  // SMS code resend countdown.
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isSendingCode = false;

  // Captcha state.
  String? _captchaSessionId;
  String _captchaInput = '';

  // Background animations.
  late AnimationController _backgroundController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Animated background gradient.
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Floating accent animation.
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
    _confirmPasswordController.dispose();
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
                    if (kIsWeb) _DownloadAppButton(),
                    const SizedBox(height: 16),
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
          mode: _customerMode,
          onModeChanged: (mode) {
            setState(() {
              _customerMode = mode;
              _authCodeController.clear();
              _confirmPasswordController.clear();
              _captchaInput = '';
              _captchaSessionId = null;
            });
          },
          phoneController: _phoneController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          authCodeController: _authCodeController,
          obscurePassword: _obscurePassword,
          onTogglePasswordVisibility: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          isLoading: _isLoading,
          onSubmit: _loginAsCustomer,
          onSendCode: _sendSmsCode,
          onForgotPassword: () {
            setState(() {
              _customerMode = CustomerAuthMode.reset;
              _authCodeController.clear();
              _confirmPasswordController.clear();
            });
          },
          onBackToPassword: () {
            setState(() {
              _customerMode = CustomerAuthMode.password;
              _authCodeController.clear();
              _confirmPasswordController.clear();
            });
          },
          hasAcceptedAgreement: _acceptedTerms,
          onAgreementChanged: (value) {
            setState(() => _acceptedTerms = value);
          },
          onOpenAgreement: () => _openLegalPage(const UserAgreementScreen()),
          onOpenPrivacy: () => _openLegalPage(const PrivacyPolicyScreen()),
          countdown: _countdown,
          isSendingCode: _isSendingCode,
          onCaptchaChanged: (value) {
            setState(() => _captchaInput = value);
          },
          onCaptchaSessionChanged: (sessionId) {
            setState(() => _captchaSessionId = sessionId);
          },
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

  /// Requests an SMS code for login, signup, or password reset.
  Future<void> _sendSmsCode() async {
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showError(
          TranslatorGlobal.instance.translate('login_error_invalid_phone'));
      return;
    }

    final action = _customerMode == CustomerAuthMode.register
        ? 'register'
        : _customerMode == CustomerAuthMode.reset
            ? 'reset'
            : 'login';

    setState(() => _isSendingCode = true);
    final result = await ref
        .read(authProvider.notifier)
        .sendSmsCodeLocalized(phone, action: action);
    setState(() => _isSendingCode = false);

    if (!mounted) return;

    if (result['success'] == true) {
      // Start the 60-second resend countdown.
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
      _showError(result['message'] as String? ??
          TranslatorGlobal.instance.translate('login_error_send_failed'));
    }
  }

  /// Handles customer authentication flows.
  Future<void> _loginAsCustomer() async {
    if (_isLoading) return;

    final phone = _phoneController.text.trim();
    final authCode = _authCodeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (phone.isEmpty) {
      _showError(
          TranslatorGlobal.instance.translate('login_error_enter_phone'));
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      _showError(TranslatorGlobal.instance
          .translate('login_error_invalid_phone_format'));
      return;
    }

    // 图形验证码校验（密码登录和注册时需要）
    if ((_customerMode == CustomerAuthMode.password ||
            _customerMode == CustomerAuthMode.register) &&
        _captchaInput.isEmpty) {
      _showError(TranslatorGlobal.instance.translate('login_captcha_required'));
      return;
    }

    if (_customerMode == CustomerAuthMode.password && password.isEmpty) {
      _showError(LoginCopy.enterPassword(context));
      return;
    }

    if ((_customerMode == CustomerAuthMode.sms ||
            _customerMode == CustomerAuthMode.register ||
            _customerMode == CustomerAuthMode.reset) &&
        authCode.isEmpty) {
      _showError(TranslatorGlobal.instance.translate('login_error_enter_code'));
      return;
    }

    if (_customerMode == CustomerAuthMode.register) {
      if (password.isEmpty) {
        _showError(LoginCopy.enterPassword(context));
        return;
      }
      if (confirmPassword.isEmpty) {
        _showError(LoginCopy.enterConfirmPassword(context));
        return;
      }
      if (password != confirmPassword) {
        _showError(LoginCopy.passwordMismatch(context));
        return;
      }
      if (!_isStrongPassword(password)) {
        _showError(LoginCopy.passwordTooWeak(context));
        return;
      }
      if (!_acceptedTerms) {
        _showError(LoginCopy.termsRequired(context));
        return;
      }
    }

    if (_customerMode == CustomerAuthMode.reset) {
      if (password.isEmpty) {
        _showError(LoginCopy.enterPassword(context));
        return;
      }
      if (confirmPassword.isEmpty) {
        _showError(LoginCopy.enterConfirmPassword(context));
        return;
      }
      if (password != confirmPassword) {
        _showError(LoginCopy.passwordMismatch(context));
        return;
      }
      if (!_isStrongPassword(password)) {
        _showError(LoginCopy.passwordTooWeak(context));
        return;
      }
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(authProvider.notifier);
    bool success = false;
    switch (_customerMode) {
      case CustomerAuthMode.password:
        success = await notifier.loginCustomerWithPassword(
          phone,
          password,
          captchaSessionId: _captchaSessionId,
          captcha: _captchaInput,
        );
        break;
      case CustomerAuthMode.sms:
        success = await notifier.loginCustomerWithSms(phone, authCode);
        break;
      case CustomerAuthMode.register:
        success = await notifier.registerCustomer(
          phone,
          authCode,
          password,
          confirmPassword,
          _acceptedTerms,
          captchaSessionId: _captchaSessionId,
          captcha: _captchaInput,
        );
        break;
      case CustomerAuthMode.reset:
        success = await notifier.resetCustomerPassword(
          phone,
          authCode,
          password,
          confirmPassword,
        );
        break;
    }

    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showError(
        notifier.lastLoginError ??
            (_customerMode == CustomerAuthMode.password
                ? TranslatorGlobal.instance
                    .translate('login_error_account_or_password')
                : TranslatorGlobal.instance
                    .translate('login_error_wrong_code')),
      );
    }
  }

  /// Handles admin sign-in.
  Future<void> _loginAsAdmin() async {
    if (_isLoading) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final authCode = _authCodeController.text.trim();
    final notifier = ref.read(authProvider.notifier);

    setState(() => _isLoading = true);

    final success = await notifier.loginAdmin(
      phone,
      password,
      authCode,
    );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showError(notifier.lastLoginError ??
          TranslatorGlobal.instance.translate('login_error_password_or_code'));
    }
  }

  /// Handles operator sign-in.
  Future<void> _loginAsOperator() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final notifier = ref.read(authProvider.notifier);

    if (username.isEmpty) {
      _showError(TranslatorGlobal.instance
          .translate('login_error_enter_operator_account'));
      return;
    }

    setState(() => _isLoading = true);

    final success = await notifier.loginOperator(
      username,
      password,
    );

    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showError(
        notifier.lastLoginError ??
            TranslatorGlobal.instance
                .translate('login_error_account_or_password'),
      );
    }
  }

  /// Shows the verification code dialog in test mode.
  void _showCodeDialog(String message) {
    // Extract the 6-digit code from the test-mode message payload.
    final codeMatch = RegExp(r'\d{6}').firstMatch(message);
    final code = codeMatch?.group(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Row(
          children: [
            const Icon(Icons.sms, color: Color(0xFF4CAF50)),
            const SizedBox(width: 8),
            Text(
              TranslatorGlobal.instance.translate('login_dialog_code_title'),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (code != null) ...[
              Text(
                TranslatorGlobal.instance
                    .translate('login_dialog_code_message'),
                style: const TextStyle(color: Colors.grey),
              ),
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
              Text(
                TranslatorGlobal.instance.translate('login_dialog_test_mode'),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ] else
              Text(message),
          ],
        ),
        actions: [
          if (code != null)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(TranslatorGlobal.instance.translate('ai_copied')),
                    backgroundColor: JewelryColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: Text(TranslatorGlobal.instance.translate('ai_copy')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              TranslatorGlobal.instance.translate('login_dialog_ok'),
              style: const TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows an error snackbar.
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

  bool _isStrongPassword(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(password);
  }

  Future<void> _openLegalPage(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

/// Download app button displayed below the login card.
class _DownloadAppButton extends StatelessWidget {
  const _DownloadAppButton();

  void _openDownloadPage() {
    openUrl('${ApiConfig.productionUrl}/download.html');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _openDownloadPage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: JewelryColors.primary.withOpacity(0.4),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              JewelryColors.primary.withOpacity(0.15),
              JewelryColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              size: 18,
              color: JewelryColors.primaryLight,
            ),
            const SizedBox(width: 8),
            Text(
              '下载App',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: JewelryColors.primaryLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: JewelryColors.primaryLight.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
