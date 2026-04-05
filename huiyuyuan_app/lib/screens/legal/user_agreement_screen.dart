import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../themes/colors.dart';

class UserAgreementScreen extends ConsumerWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFFAF8FF);
    final textColor = isDark ? Colors.white : JewelryColors.textPrimary;
    final subColor = isDark ? Colors.white70 : Colors.black87;
    final divColor = isDark ? Colors.white12 : Colors.black12;
    final content = _agreementContent(ref.watch(appSettingsProvider).language);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : JewelryColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          ref.tr('settings_agreement'),
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF2A1F3D), Color(0xFF1A1A2E)]
                      : [
                          JewelryColors.gold.withOpacity(0.08),
                          JewelryColors.gold.withOpacity(0.03),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: JewelryColors.gold.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: JewelryColors.gold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: JewelryColors.gold,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.cardTitle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content.updatedAt,
                          style: TextStyle(
                            color: subColor.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              content.intro,
              style: TextStyle(color: subColor, fontSize: 14, height: 1.8),
            ),
            const SizedBox(height: 20),
            for (final section in content.sections) ...[
              _buildSection(
                title: section.title,
                icon: section.icon,
                items: section.items,
                isDark: isDark,
                textColor: textColor,
                subColor: subColor,
                divColor: divColor,
              ),
              const SizedBox(height: 18),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color:
                    isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: divColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.contactTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < content.contacts.length; i++) ...[
                    _contactRow(
                      content.contacts[i].icon,
                      content.contacts[i].text,
                      subColor,
                    ),
                    if (i != content.contacts.length - 1)
                      const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_AgreementItem> items,
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Color divColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: JewelryColors.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: divColor),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              final item = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 10),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: JewelryColors.gold,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.content,
                                style: TextStyle(
                                  color: subColor.withOpacity(0.75),
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: divColor),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: JewelryColors.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

_AgreementContent _agreementContent(AppLanguage language) {
  switch (language) {
    case AppLanguage.en:
      return const _AgreementContent(
        cardTitle: 'Huiyuyuan User Agreement',
        updatedAt: 'Last updated: March 18, 2026',
        intro:
            'Welcome to Huiyuyuan Jewelry Intelligent Trading Platform. Please read this agreement carefully before you register, sign in, or use the platform. By registering, clicking agree, or continuing to use the platform, you are deemed to have read and accepted all terms below.',
        contactTitle: 'Contact Us',
        contacts: [
          _ContactInfo(Icons.support_agent_rounded, 'Support hotline: 400-888-8888'),
          _ContactInfo(Icons.email_outlined, 'Email: service@huiyuyuan.com'),
          _ContactInfo(Icons.gavel_rounded, 'Disputes are handled by a competent people’s court under PRC law'),
        ],
        sections: [
          _AgreementSection(
            title: '1. Scope and Services',
            icon: Icons.gavel_rounded,
            items: [
              _AgreementItem(
                title: 'Agreement scope',
                content:
                    'This agreement governs the relationship between you and the Huiyuyuan operating entity for product browsing, transactions, account services, AI features, and other lawful platform services.',
              ),
              _AgreementItem(
                title: 'Updates',
                content:
                    'The platform may update this agreement according to business development, regulatory requirements, or product changes and will notify you in a reasonable way.',
              ),
            ],
          ),
          _AgreementSection(
            title: '2. Accounts and Security',
            icon: Icons.manage_accounts_rounded,
            items: [
              _AgreementItem(
                title: 'Registration requirements',
                content:
                    'You should use true, lawful, and valid information to complete registration and should have the required civil capacity.',
              ),
              _AgreementItem(
                title: 'Credential security',
                content:
                    'You are responsible for safeguarding your account, password, verification code, and other credentials, as well as operations performed under your account.',
              ),
              _AgreementItem(
                title: 'Risk handling',
                content:
                    'If you notice account theft, abnormal sign-ins, or other security risks, please contact the platform promptly.',
              ),
            ],
          ),
          _AgreementSection(
            title: '3. Orders, Payments, and After-sales',
            icon: Icons.receipt_long_rounded,
            items: [
              _AgreementItem(
                title: 'Order confirmation',
                content:
                    'Whether an order is established is subject to the final system confirmation after you complete the required ordering flow.',
              ),
              _AgreementItem(
                title: 'Payment and fulfillment',
                content:
                    'You should complete payment according to the methods and process displayed on the page. Delivery, signing, returns, exchanges, and after-sales handling follow page rules, product descriptions, and applicable law.',
              ),
              _AgreementItem(
                title: 'Abnormal transactions',
                content:
                    'For suspected brushing orders, cash-out, malicious refunds, fraud, or other abnormal transactions, the platform may suspend processing and conduct verification.',
              ),
            ],
          ),
          _AgreementSection(
            title: '4. Platform Rules',
            icon: Icons.rule_rounded,
            items: [
              _AgreementItem(
                title: 'Truthful and lawful use',
                content:
                    'You must not publish false information, impersonate others, or use the platform for unlawful or non-compliant activities.',
              ),
              _AgreementItem(
                title: 'No interference or infringement',
                content:
                    'You must not use scripts, crawlers, plug-ins, or other means to interfere with platform operation, nor upload or distribute content that infringes lawful rights of others.',
              ),
              _AgreementItem(
                title: 'Responsible AI usage',
                content:
                    'When using AI features, you should carefully judge generated content and may not use it for illegal or non-compliant purposes.',
              ),
            ],
          ),
          _AgreementSection(
            title: '5. Liability, Termination, and Disputes',
            icon: Icons.info_outline_rounded,
            items: [
              _AgreementItem(
                title: 'Reasonable commercial efforts',
                content:
                    'The platform will use reasonable commercial efforts to maintain service quality, but it does not make absolute guarantees for results beyond reasonable control.',
              ),
              _AgreementItem(
                title: 'Account cancellation and measures',
                content:
                    'You may apply to cancel your account according to platform rules. If you violate this agreement or related rules, the platform may restrict features, suspend services, or terminate account use.',
              ),
              _AgreementItem(
                title: 'Governing law',
                content:
                    'This agreement is governed by the laws of the People’s Republic of China. Disputes should first be resolved through negotiation, and if negotiation fails they shall be submitted to a competent people’s court.',
              ),
            ],
          ),
        ],
      );
    case AppLanguage.zhTW:
      return const _AgreementContent(
        cardTitle: '匯玉源用戶協議',
        updatedAt: '最後更新日期：2026年3月18日',
        intro:
            '歡迎使用匯玉源珠寶智慧交易平台。請您在註冊、登入或使用本平台前，仔細閱讀本協議。當您完成註冊、點擊同意或繼續使用本平台時，即視為已閱讀並接受以下全部條款。',
        contactTitle: '聯絡方式',
        contacts: [
          _ContactInfo(Icons.support_agent_rounded, '客服專線：400-888-8888'),
          _ContactInfo(Icons.email_outlined, '電子郵件：service@huiyuyuan.com'),
          _ContactInfo(Icons.gavel_rounded, '爭議依中華人民共和國法律提交有管轄權法院處理'),
        ],
        sections: [
          _AgreementSection(
            title: '一、適用範圍與服務',
            icon: Icons.gavel_rounded,
            items: [
              _AgreementItem(
                title: '協議範圍',
                content:
                    '本協議規範您與匯玉源運營主體之間，就商品瀏覽、交易下單、帳戶服務、AI 功能及其他合法平台服務所形成的權利義務關係。',
              ),
              _AgreementItem(
                title: '協議更新',
                content:
                    '平台可依業務發展、監管要求或產品調整更新本協議，並以合理方式提醒您。',
              ),
            ],
          ),
          _AgreementSection(
            title: '二、帳號與安全',
            icon: Icons.manage_accounts_rounded,
            items: [
              _AgreementItem(
                title: '註冊要求',
                content:
                    '您應使用真實、合法、有效的資訊完成註冊，並具備相應民事行為能力。',
              ),
              _AgreementItem(
                title: '憑證保管',
                content:
                    '您應妥善保管帳號、密碼、驗證碼及其他身分憑證，並對帳號下的操作承擔責任。',
              ),
              _AgreementItem(
                title: '風險處理',
                content:
                    '如發現帳號被盜用、異常登入或其他安全風險，請儘速聯繫平台。',
              ),
            ],
          ),
          _AgreementSection(
            title: '三、訂單、支付與售後',
            icon: Icons.receipt_long_rounded,
            items: [
              _AgreementItem(
                title: '訂單確認',
                content:
                    '您完成必要下單流程後，訂單是否成立以系統最終確認結果為準。',
              ),
              _AgreementItem(
                title: '支付與履約',
                content:
                    '您應依頁面顯示方式完成付款。配送、簽收、退換貨與售後處理，依頁面規則、商品說明與適用法律執行。',
              ),
              _AgreementItem(
                title: '異常交易',
                content:
                    '對於涉嫌刷單、套現、惡意退款、詐欺或其他異常交易，平台有權暫停處理並進行核驗。',
              ),
            ],
          ),
          _AgreementSection(
            title: '四、平台規則',
            icon: Icons.rule_rounded,
            items: [
              _AgreementItem(
                title: '真實合法使用',
                content:
                    '您不得發布虛假資訊、冒用他人身分，或利用平台從事違法違規活動。',
              ),
              _AgreementItem(
                title: '禁止干擾與侵權',
                content:
                    '您不得使用腳本、爬蟲、外掛等方式干擾平台運行，也不得上傳或散播侵害他人合法權益的內容。',
              ),
              _AgreementItem(
                title: 'AI 合規使用',
                content:
                    '使用 AI 功能時，您應審慎判斷生成內容，不得將其用於違法違規用途。',
              ),
            ],
          ),
          _AgreementSection(
            title: '五、責任、終止與爭議',
            icon: Icons.info_outline_rounded,
            items: [
              _AgreementItem(
                title: '合理商業努力',
                content:
                    '平台會以合理商業努力維持服務品質，但不對超出合理控制範圍的結果作絕對保證。',
              ),
              _AgreementItem(
                title: '帳號註銷與處理措施',
                content:
                    '您可依平台規則申請註銷帳號；若違反本協議或相關規則，平台可限制功能、暫停服務或終止帳號使用。',
              ),
              _AgreementItem(
                title: '適用法律',
                content:
                    '本協議適用中華人民共和國法律。爭議應先協商解決，協商不成的，提交有管轄權的人民法院處理。',
              ),
            ],
          ),
        ],
      );
    case AppLanguage.zhCN:
      return const _AgreementContent(
        cardTitle: '汇玉源用户协议',
        updatedAt: '最后更新日期：2026年3月18日',
        intro:
            '欢迎使用汇玉源珠宝智能交易平台。请您在注册、登录或使用本平台前，仔细阅读本协议。当您完成注册、点击同意或继续使用本平台时，即视为已阅读并接受以下全部条款。',
        contactTitle: '联系方式',
        contacts: [
          _ContactInfo(Icons.support_agent_rounded, '客服热线：400-888-8888'),
          _ContactInfo(Icons.email_outlined, '邮箱：service@huiyuyuan.com'),
          _ContactInfo(Icons.gavel_rounded, '争议依中华人民共和国法律提交有管辖权法院处理'),
        ],
        sections: [
          _AgreementSection(
            title: '一、适用范围与服务',
            icon: Icons.gavel_rounded,
            items: [
              _AgreementItem(
                title: '协议范围',
                content:
                    '本协议规范您与汇玉源运营主体之间，就商品浏览、交易下单、账户服务、AI 功能及其他合法平台服务所形成的权利义务关系。',
              ),
              _AgreementItem(
                title: '协议更新',
                content:
                    '平台可根据业务发展、监管要求或产品调整更新本协议，并以合理方式提醒您。',
              ),
            ],
          ),
          _AgreementSection(
            title: '二、账号与安全',
            icon: Icons.manage_accounts_rounded,
            items: [
              _AgreementItem(
                title: '注册要求',
                content:
                    '您应使用真实、合法、有效的信息完成注册，并具备相应民事行为能力。',
              ),
              _AgreementItem(
                title: '凭证保管',
                content:
                    '您应妥善保管账号、密码、验证码及其他身份凭证，并对账号下的操作承担责任。',
              ),
              _AgreementItem(
                title: '风险处理',
                content:
                    '如发现账号被盗用、异常登录或其他安全风险，请尽快联系平台。',
              ),
            ],
          ),
          _AgreementSection(
            title: '三、订单、支付与售后',
            icon: Icons.receipt_long_rounded,
            items: [
              _AgreementItem(
                title: '订单确认',
                content:
                    '您完成必要下单流程后，订单是否成立以系统最终确认结果为准。',
              ),
              _AgreementItem(
                title: '支付与履约',
                content:
                    '您应依页面显示方式完成付款。配送、签收、退换货与售后处理，依页面规则、商品说明与适用法律执行。',
              ),
              _AgreementItem(
                title: '异常交易',
                content:
                    '对于涉嫌刷单、套现、恶意退款、欺诈或其他异常交易，平台有权暂停处理并进行核验。',
              ),
            ],
          ),
          _AgreementSection(
            title: '四、平台规则',
            icon: Icons.rule_rounded,
            items: [
              _AgreementItem(
                title: '真实合法使用',
                content:
                    '您不得发布虚假信息、冒用他人身份，或利用平台从事违法违规活动。',
              ),
              _AgreementItem(
                title: '禁止干扰与侵权',
                content:
                    '您不得使用脚本、爬虫、外挂等方式干扰平台运行，也不得上传或传播侵害他人合法权益的内容。',
              ),
              _AgreementItem(
                title: 'AI 合规使用',
                content:
                    '使用 AI 功能时，您应审慎判断生成内容，不得将其用于违法违规用途。',
              ),
            ],
          ),
          _AgreementSection(
            title: '五、责任、终止与争议',
            icon: Icons.info_outline_rounded,
            items: [
              _AgreementItem(
                title: '合理商业努力',
                content:
                    '平台会以合理商业努力维持服务质量，但不对超出合理控制范围的结果作绝对保证。',
              ),
              _AgreementItem(
                title: '账号注销与处理措施',
                content:
                    '您可依平台规则申请注销账号；若违反本协议或相关规则，平台可限制功能、暂停服务或终止账号使用。',
              ),
              _AgreementItem(
                title: '适用法律',
                content:
                    '本协议适用中华人民共和国法律。争议应先协商解决，协商不成的，提交有管辖权的人民法院处理。',
              ),
            ],
          ),
        ],
      );
  }
}

class _AgreementContent {
  final String cardTitle;
  final String updatedAt;
  final String intro;
  final String contactTitle;
  final List<_ContactInfo> contacts;
  final List<_AgreementSection> sections;

  const _AgreementContent({
    required this.cardTitle,
    required this.updatedAt,
    required this.intro,
    required this.contactTitle,
    required this.contacts,
    required this.sections,
  });
}

class _AgreementSection {
  final String title;
  final IconData icon;
  final List<_AgreementItem> items;

  const _AgreementSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _AgreementItem {
  final String title;
  final String content;

  const _AgreementItem({
    required this.title,
    required this.content,
  });
}

class _ContactInfo {
  final IconData icon;
  final String text;

  const _ContactInfo(this.icon, this.text);
}
