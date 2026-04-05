import 'package:flutter/widgets.dart';

class LoginCopy {
  LoginCopy._();

  static String customerTitle(BuildContext context) => _resolve(
        context,
        zhCN: '安全登录',
        en: 'Secure Login',
        zhTW: '安全登入',
      );

  static String customerSubtitle(BuildContext context) => _resolve(
        context,
        zhCN: '使用手机号进行登录或注册，账号信息将加密存储到服务器',
        en: 'Sign in or register with your mobile number. Account credentials are stored securely on the server.',
        zhTW: '使用手機號進行登入或註冊，帳號資訊將加密儲存到伺服器',
      );

  static String modePassword(BuildContext context) => _resolve(
        context,
        zhCN: '密码登录',
        en: 'Password',
        zhTW: '密碼登入',
      );

  static String modeSms(BuildContext context) => _resolve(
        context,
        zhCN: '验证码登录',
        en: 'SMS Code',
        zhTW: '驗證碼登入',
      );

  static String modeRegister(BuildContext context) => _resolve(
        context,
        zhCN: '注册账号',
        en: 'Register',
        zhTW: '註冊帳號',
      );

  static String resetTitle(BuildContext context) => _resolve(
        context,
        zhCN: '找回密码',
        en: 'Reset Password',
        zhTW: '找回密碼',
      );

  static String resetSubtitle(BuildContext context) => _resolve(
        context,
        zhCN: '先验证手机号，再设置新的登录密码。',
        en: 'Verify your mobile number first, then set a new password.',
        zhTW: '先驗證手機號，再設定新的登入密碼。',
      );

  static String resendCode(BuildContext context, int seconds) => _resolve(
        context,
        zhCN: '${seconds}s 后重发',
        en: 'Resend in ${seconds}s',
        zhTW: '${seconds}s 後重發',
      );

  static String passwordLogin(BuildContext context) => _resolve(
        context,
        zhCN: '密码登录',
        en: 'Sign In with Password',
        zhTW: '密碼登入',
      );

  static String registerPasswordHint(BuildContext context) => _resolve(
        context,
        zhCN: '设置登录密码',
        en: 'Create login password',
        zhTW: '設定登入密碼',
      );

  static String confirmPasswordHint(BuildContext context) => _resolve(
        context,
        zhCN: '再次输入密码',
        en: 'Confirm password',
        zhTW: '再次輸入密碼',
      );

  static String registerSubmit(BuildContext context) => _resolve(
        context,
        zhCN: '注册并登录',
        en: 'Register and Sign In',
        zhTW: '註冊並登入',
      );

  static String resetSubmit(BuildContext context) => _resolve(
        context,
        zhCN: '重置密码并登录',
        en: 'Reset and Sign In',
        zhTW: '重設密碼並登入',
      );

  static String passwordModeHint(BuildContext context) => _resolve(
        context,
        zhCN: '已注册用户可直接使用手机号和密码登录，异常尝试会触发限流保护。',
        en: 'Registered users can sign in directly with mobile number and password. Risky attempts will be rate limited.',
        zhTW: '已註冊用戶可直接使用手機號和密碼登入，異常嘗試會觸發限流保護。',
      );

  static String smsModeHint(BuildContext context) => _resolve(
        context,
        zhCN: '验证码登录仅对已注册账号开放，适合临时快捷登录。',
        en: 'SMS code sign-in is available only for existing registered accounts.',
        zhTW: '驗證碼登入僅對已註冊帳號開放，適合臨時快速登入。',
      );

  static String registerModeHint(BuildContext context) => _resolve(
        context,
        zhCN: '首次使用请先短信验证手机号，再设置 8 位以上且含字母和数字的密码。',
        en: 'Verify your phone first, then create a password with at least 8 characters including letters and numbers.',
        zhTW: '首次使用請先簡訊驗證手機號，再設定 8 碼以上且含字母與數字的密碼。',
      );

  static String resetModeHint(BuildContext context) => _resolve(
        context,
        zhCN: '重置密码仅对已注册账号开放，验证码验证通过后会立即更新服务器端密码。',
        en: 'Password reset is available only for registered accounts and updates the server-side password immediately.',
        zhTW: '重設密碼僅對已註冊帳號開放，驗證碼通過後會立即更新伺服器端密碼。',
      );

  static String forgotPassword(BuildContext context) => _resolve(
        context,
        zhCN: '忘记密码？',
        en: 'Forgot password?',
        zhTW: '忘記密碼？',
      );

  static String backToPassword(BuildContext context) => _resolve(
        context,
        zhCN: '返回密码登录',
        en: 'Back to password sign-in',
        zhTW: '返回密碼登入',
      );

  static String termsRequired(BuildContext context) => _resolve(
        context,
        zhCN: '请先阅读并同意用户协议与隐私政策',
        en: 'Please read and accept the User Agreement and Privacy Policy first',
        zhTW: '請先閱讀並同意使用者協議與隱私政策',
      );

  static String agreementPrefix(BuildContext context) => _resolve(
        context,
        zhCN: '我已阅读并同意',
        en: 'I have read and agree to the',
        zhTW: '我已閱讀並同意',
      );

  static String agreementAnd(BuildContext context) => _resolve(
        context,
        zhCN: '和',
        en: 'and',
        zhTW: '和',
      );

  static String agreementUserAgreement(BuildContext context) => _resolve(
        context,
        zhCN: '《用户协议》',
        en: 'User Agreement',
        zhTW: '《使用者協議》',
      );

  static String agreementPrivacyPolicy(BuildContext context) => _resolve(
        context,
        zhCN: '《隐私政策》',
        en: 'Privacy Policy',
        zhTW: '《隱私政策》',
      );

  static String enterPassword(BuildContext context) => _resolve(
        context,
        zhCN: '请输入密码',
        en: 'Please enter your password',
        zhTW: '請輸入密碼',
      );

  static String enterConfirmPassword(BuildContext context) => _resolve(
        context,
        zhCN: '请再输入一次密码',
        en: 'Please confirm your password',
        zhTW: '請再輸入一次密碼',
      );

  static String passwordMismatch(BuildContext context) => _resolve(
        context,
        zhCN: '两次输入的密码不一致',
        en: 'The two passwords do not match',
        zhTW: '兩次輸入的密碼不一致',
      );

  static String passwordTooWeak(BuildContext context) => _resolve(
        context,
        zhCN: '密码需至少 8 位，且同时包含字母和数字',
        en: 'Password must be at least 8 characters and include both letters and numbers',
        zhTW: '密碼需至少 8 碼，且同時包含字母與數字',
      );

  static String _resolve(
    BuildContext context, {
    required String zhCN,
    required String en,
    required String zhTW,
  }) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'en') {
      return en;
    }

    final country = locale.countryCode?.toUpperCase();
    final script = locale.scriptCode?.toUpperCase();
    final isTraditional = locale.languageCode == 'zh' &&
        (country == 'TW' ||
            country == 'HK' ||
            country == 'MO' ||
            script == 'HANT');
    return isTraditional ? zhTW : zhCN;
  }
}
