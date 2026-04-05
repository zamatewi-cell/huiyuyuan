import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../themes/colors.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFFAF8FF);
    final textColor = isDark ? Colors.white : JewelryColors.textPrimary;
    final subColor = isDark ? Colors.white70 : Colors.black87;
    final divColor = isDark ? Colors.white12 : Colors.black12;
    final content = _privacyContent(ref.watch(appSettingsProvider).language);

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
          ref.tr('settings_privacy'),
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
                          JewelryColors.primary.withOpacity(0.08),
                          JewelryColors.primary.withOpacity(0.03),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: JewelryColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: JewelryColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.privacy_tip,
                      color: JewelryColors.primary,
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
    required List<_PolicyItem> items,
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
            Icon(icon, color: JewelryColors.primary, size: 18),
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
                            color: JewelryColors.primary,
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
        Icon(icon, size: 16, color: JewelryColors.primary),
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

_PrivacyContent _privacyContent(AppLanguage language) {
  switch (language) {
    case AppLanguage.en:
      return const _PrivacyContent(
        cardTitle: 'Huiyuyuan Privacy Policy',
        updatedAt: 'Last updated: March 18, 2026',
        intro:
            'This Privacy Policy explains how Huiyuyuan collects, uses, stores, shares, and protects personal information generated when you use our platform. We process information lawfully, properly, necessarily, and in good faith, and we work to protect your right to know and choose.',
        contactTitle: 'Contact Us',
        contacts: [
          _ContactInfo(Icons.phone_outlined, 'Support hotline: 400-888-8888'),
          _ContactInfo(Icons.email_outlined, 'Email: privacy@huiyuyuan.com'),
          _ContactInfo(
            Icons.location_on_outlined,
            'Address: Mainland China operating entity address',
          ),
        ],
        sections: [
          _PolicySection(
            title: '1. Information We Collect',
            icon: Icons.input_rounded,
            items: [
              _PolicyItem(
                title: 'Registration and account information',
                content:
                    'When you register or sign in, we process your mobile number, username, account type, and required login credentials.',
              ),
              _PolicyItem(
                title: 'Transaction and delivery information',
                content:
                    'When you place an order, receive goods, or request after-sales service, we process necessary information such as order details, delivery address, contact person, and payment records.',
              ),
              _PolicyItem(
                title: 'Device and log information',
                content:
                    'To keep the service stable and secure, we record device model, system version, app logs, visit time, request result, and similar operational data.',
              ),
              _PolicyItem(
                title: 'Customer service and feedback information',
                content:
                    'When you contact support, submit feedback, or raise a dispute, we store the communication content and handling result.',
              ),
              _PolicyItem(
                title: 'Location information',
                content:
                    'Only with your authorization do we process location information for store recommendations, nearby services, and related features.',
              ),
            ],
          ),
          _PolicySection(
            title: '2. How We Use Information',
            icon: Icons.tune_rounded,
            items: [
              _PolicyItem(
                title: 'Provide core services',
                content:
                    'Information is used to complete login, product display, purchasing, order fulfillment, and after-sales workflows.',
              ),
              _PolicyItem(
                title: 'Security and risk control',
                content:
                    'We use information to identify abnormal sign-ins, fraud, interface abuse, and other behaviors that may threaten platform security.',
              ),
              _PolicyItem(
                title: 'Personalized experience',
                content:
                    'Subject to applicable laws, we improve recommendations based on browsing, favorites, and search behavior.',
              ),
              _PolicyItem(
                title: 'Service notifications',
                content:
                    'We send necessary notices about order status, account security, and important rule updates.',
              ),
              _PolicyItem(
                title: 'Analytics and optimization',
                content:
                    'We analyze performance and feature usage to continuously improve product quality and service efficiency.',
              ),
            ],
          ),
          _PolicySection(
            title: '3. Information Sharing and Disclosure',
            icon: Icons.share_rounded,
            items: [
              _PolicyItem(
                title: 'No sale of personal information',
                content:
                    'Unless required by law, we do not sell your personal information to unrelated third parties.',
              ),
              _PolicyItem(
                title: 'Necessary partners',
                content:
                    'To complete payment, logistics, or messaging services, we may share the minimum necessary information with partners and require them to fulfill protection obligations.',
              ),
              _PolicyItem(
                title: 'Legal disclosure',
                content:
                    'We may disclose relevant information when required by laws, judicial procedures, or regulatory authorities.',
              ),
            ],
          ),
          _PolicySection(
            title: '4. Storage and Protection',
            icon: Icons.shield_rounded,
            items: [
              _PolicyItem(
                title: 'Encrypted transmission',
                content:
                    'Sensitive data transmitted between the app and our services is protected through encrypted channels.',
              ),
              _PolicyItem(
                title: 'Access control',
                content:
                    'We apply least-privilege access controls and only authorize personnel who need the data for business purposes.',
              ),
              _PolicyItem(
                title: 'Retention period',
                content:
                    'We keep information only for the minimum period necessary to achieve the stated purpose, unless laws require otherwise.',
              ),
              _PolicyItem(
                title: 'Security monitoring',
                content:
                    'We perform logging, alerting, and regular security checks, and we remediate identified risks in a timely manner.',
              ),
            ],
          ),
          _PolicySection(
            title: '5. Your Rights',
            icon: Icons.how_to_reg_rounded,
            items: [
              _PolicyItem(
                title: 'Access and copy',
                content:
                    'You may request access to the personal information we hold about you and apply for a copy where permitted by law.',
              ),
              _PolicyItem(
                title: 'Correction and supplementation',
                content:
                    'If information is inaccurate or incomplete, you may correct it in the app or contact support for assistance.',
              ),
              _PolicyItem(
                title: 'Deletion and account cancellation',
                content:
                    'Where permitted by law, you may request deletion of relevant information or cancellation of your account.',
              ),
              _PolicyItem(
                title: 'Withdraw consent',
                content:
                    'For processing based on consent, you may withdraw authorization at any time. Processing completed before withdrawal is not affected.',
              ),
            ],
          ),
          _PolicySection(
            title: '6. Protection of Minors',
            icon: Icons.child_care_rounded,
            items: [
              _PolicyItem(
                title: 'Age requirement',
                content:
                    'If you are a minor, please use this platform under the consent and guidance of your guardian. If we discover improper collection of minors’ information, we will handle it promptly.',
              ),
            ],
          ),
          _PolicySection(
            title: '7. Policy Updates',
            icon: Icons.update_rounded,
            items: [
              _PolicyItem(
                title: 'Update notices',
                content:
                    'When this policy changes materially, we will notify you through in-app announcements, pop-ups, or other reasonable means.',
              ),
              _PolicyItem(
                title: 'How to reach us',
                content:
                    'If you have questions about this policy or our information processing practices, please contact us using the channels listed below.',
              ),
            ],
          ),
        ],
      );
    case AppLanguage.zhTW:
      return const _PrivacyContent(
        cardTitle: '匯玉源隱私政策',
        updatedAt: '最後更新日期：2026年3月18日',
        intro:
            '本隱私政策用於說明匯玉源如何收集、使用、儲存、共享及保護您在使用本平台期間產生的個人資訊。我們會依照合法、正當、必要及誠信原則處理您的資訊，並盡力保障您的知情權與選擇權。',
        contactTitle: '聯絡方式',
        contacts: [
          _ContactInfo(Icons.phone_outlined, '客服專線：400-888-8888'),
          _ContactInfo(Icons.email_outlined, '電子郵件：privacy@huiyuyuan.com'),
          _ContactInfo(
            Icons.location_on_outlined,
            '地址：中國大陸境內運營主體所在地',
          ),
        ],
        sections: [
          _PolicySection(
            title: '一、我們收集的資訊',
            icon: Icons.input_rounded,
            items: [
              _PolicyItem(
                title: '註冊與帳號資訊',
                content:
                    '當您註冊或登入時，我們會處理手機號碼、使用者名稱、帳號類型以及必要的登入憑證資訊。',
              ),
              _PolicyItem(
                title: '交易與收貨資訊',
                content:
                    '當您下單、收貨或申請售後服務時，我們會處理訂單資訊、收貨地址、聯絡人與支付相關記錄等必要資訊。',
              ),
              _PolicyItem(
                title: '設備與日誌資訊',
                content:
                    '為保障服務穩定與安全，我們會記錄設備型號、系統版本、應用日誌、造訪時間、請求結果等運行資訊。',
              ),
              _PolicyItem(
                title: '客服與回饋資訊',
                content:
                    '當您聯繫客服、提交回饋或發起爭議處理時，我們會保存溝通內容與處理結果。',
              ),
              _PolicyItem(
                title: '位置資訊',
                content:
                    '僅在您授權的前提下，我們才會處理位置資訊，用於門店推薦、附近服務等相關功能。',
              ),
            ],
          ),
          _PolicySection(
            title: '二、我們如何使用資訊',
            icon: Icons.tune_rounded,
            items: [
              _PolicyItem(
                title: '提供核心服務',
                content:
                    '資訊將用於完成帳號登入、商品展示、購買交易、訂單履約及售後處理等核心流程。',
              ),
              _PolicyItem(
                title: '安全與風控',
                content:
                    '我們會使用資訊識別異常登入、詐欺行為、介面濫用及其他可能危及平台安全的行為。',
              ),
              _PolicyItem(
                title: '個人化體驗',
                content:
                    '在符合法律規定的前提下，我們會基於瀏覽、收藏與搜尋行為持續優化推薦結果。',
              ),
              _PolicyItem(
                title: '服務通知',
                content:
                    '我們會發送訂單狀態、帳號安全與重要規則更新等必要通知。',
              ),
              _PolicyItem(
                title: '統計與優化',
                content:
                    '我們會分析系統效能與功能使用情況，以持續提升產品品質與服務效率。',
              ),
            ],
          ),
          _PolicySection(
            title: '三、資訊共享與揭露',
            icon: Icons.share_rounded,
            items: [
              _PolicyItem(
                title: '不出售個人資訊',
                content:
                    '除法律法規另有規定外，我們不會向無關第三方出售您的個人資訊。',
              ),
              _PolicyItem(
                title: '必要合作方',
                content:
                    '為完成支付、物流或訊息通知等服務，我們可能向必要合作方提供最小範圍資訊，並要求其履行保護義務。',
              ),
              _PolicyItem(
                title: '依法揭露',
                content:
                    '在符合法律法規、司法程序或監管要求的情況下，我們可能依法揭露相關資訊。',
              ),
            ],
          ),
          _PolicySection(
            title: '四、儲存與保護',
            icon: Icons.shield_rounded,
            items: [
              _PolicyItem(
                title: '加密傳輸',
                content:
                    '應用與服務之間傳輸的敏感資料會使用加密通道，以降低傳輸過程中的風險。',
              ),
              _PolicyItem(
                title: '權限控制',
                content:
                    '我們遵循最小權限原則，僅授權有業務需要的人員存取相關資料。',
              ),
              _PolicyItem(
                title: '保存期限',
                content:
                    '除法律另有規定外，我們僅在實現處理目的所需的最短期間內保存您的資訊。',
              ),
              _PolicyItem(
                title: '安全監測',
                content:
                    '我們持續進行日誌審計、異常告警與安全檢查，並及時修復已識別的風險。',
              ),
            ],
          ),
          _PolicySection(
            title: '五、您的權利',
            icon: Icons.how_to_reg_rounded,
            items: [
              _PolicyItem(
                title: '查詢與複製',
                content:
                    '在符合法律規定的情況下，您有權查詢我們持有的與您相關的個人資訊，並申請複製。',
              ),
              _PolicyItem(
                title: '更正與補充',
                content:
                    '若資訊不準確或不完整，您可在應用內更正，或聯絡客服協助處理。',
              ),
              _PolicyItem(
                title: '刪除與註銷',
                content:
                    '在符合法律法規的情況下，您可申請刪除相關資訊或註銷帳號。',
              ),
              _PolicyItem(
                title: '撤回同意',
                content:
                    '對於基於授權同意處理的資訊，您可隨時撤回授權；撤回前已完成的處理不受影響。',
              ),
            ],
          ),
          _PolicySection(
            title: '六、未成年人保護',
            icon: Icons.child_care_rounded,
            items: [
              _PolicyItem(
                title: '年齡要求',
                content:
                    '若您為未成年人，請在監護人同意與指導下使用本平台。如發現存在違規收集未成年人資訊的情形，我們將及時處理。',
              ),
            ],
          ),
          _PolicySection(
            title: '七、政策更新',
            icon: Icons.update_rounded,
            items: [
              _PolicyItem(
                title: '更新通知',
                content:
                    '當本政策發生重大變更時，我們會透過應用內公告、彈窗或其他合理方式提醒您。',
              ),
              _PolicyItem(
                title: '聯絡我們',
                content:
                    '若您對本政策或我們的資訊處理方式有疑問，請透過下方聯絡方式與我們聯繫。',
              ),
            ],
          ),
        ],
      );
    case AppLanguage.zhCN:
      return const _PrivacyContent(
        cardTitle: '汇玉源隐私政策',
        updatedAt: '最后更新日期：2026年3月18日',
        intro:
            '本隐私政策用于说明汇玉源如何收集、使用、存储、共享和保护您在使用本平台期间产生的个人信息。我们会按照合法、正当、必要和诚信原则处理您的信息，并尽力保障您的知情权与选择权。',
        contactTitle: '联系方式',
        contacts: [
          _ContactInfo(Icons.phone_outlined, '客服热线：400-888-8888'),
          _ContactInfo(Icons.email_outlined, '邮箱：privacy@huiyuyuan.com'),
          _ContactInfo(
            Icons.location_on_outlined,
            '地址：中国大陆地区运营主体所在地',
          ),
        ],
        sections: [
          _PolicySection(
            title: '一、我们收集的信息',
            icon: Icons.input_rounded,
            items: [
              _PolicyItem(
                title: '注册与账号信息',
                content:
                    '当您注册或登录时，我们会处理手机号、用户名、用户类型以及必要的登录凭证信息。',
              ),
              _PolicyItem(
                title: '交易与收货信息',
                content:
                    '当您下单、收货或申请售后服务时，我们会处理订单信息、收货地址、联系人、支付相关记录等必要信息。',
              ),
              _PolicyItem(
                title: '设备与日志信息',
                content:
                    '为保障服务稳定与安全，我们会记录设备型号、系统版本、应用日志、访问时间、请求结果等运行信息。',
              ),
              _PolicyItem(
                title: '客服与反馈信息',
                content:
                    '当您联系客户、提交反馈或发起争议处理时，我们会保存沟通内容与处理结果。',
              ),
              _PolicyItem(
                title: '位置信息',
                content:
                    '仅在您授权的前提下，我们才会处理位置信息，用于门店推荐、附近服务等相关功能。',
              ),
            ],
          ),
          _PolicySection(
            title: '二、我们如何使用信息',
            icon: Icons.tune_rounded,
            items: [
              _PolicyItem(
                title: '提供核心服务',
                content:
                    '信息将用于完成账号登录、商品展示、购买交易、订单履约及售后处理等核心流程。',
              ),
              _PolicyItem(
                title: '安全与风控',
                content:
                    '我们会使用信息识别异常登录、欺诈行为、接口滥用及其他可能危及平台安全的行为。',
              ),
              _PolicyItem(
                title: '个性化体验',
                content:
                    '在符合法律规定的前提下，我们会基于浏览、收藏和搜索行为持续优化推荐结果。',
              ),
              _PolicyItem(
                title: '服务通知',
                content:
                    '我们会发送订单状态、账号安全与重要规则更新等必要通知。',
              ),
              _PolicyItem(
                title: '统计与优化',
                content:
                    '我们会分析系统性能与功能使用情况，以持续提升产品质量与服务效率。',
              ),
            ],
          ),
          _PolicySection(
            title: '三、信息共享与披露',
            icon: Icons.share_rounded,
            items: [
              _PolicyItem(
                title: '不出售个人信息',
                content:
                    '除法律法规另有规定外，我们不会向无关第三方出售您的个人信息。',
              ),
              _PolicyItem(
                title: '必要合作方',
                content:
                    '为完成支付、物流或消息通知等服务，我们可能向必要合作方提供最小范围的信息，并要求其履行保护义务。',
              ),
              _PolicyItem(
                title: '依法披露',
                content:
                    '在符合法律法规、司法程序或监管要求的情况下，我们可能依法披露相关信息。',
              ),
            ],
          ),
          _PolicySection(
            title: '四、存储与保护',
            icon: Icons.shield_rounded,
            items: [
              _PolicyItem(
                title: '加密传输',
                content:
                    '应用与服务之间传输的敏感数据会通过加密通道保护，以降低传输过程中的风险。',
              ),
              _PolicyItem(
                title: '权限控制',
                content:
                    '我们遵循最小权限原则，仅授权有业务需要的人员访问相关数据。',
              ),
              _PolicyItem(
                title: '保存期限',
                content:
                    '除法律另有规定外，我们仅在实现处理目的所需的最短期限内保存您的信息。',
              ),
              _PolicyItem(
                title: '安全监测',
                content:
                    '我们持续进行日志审计、异常告警与安全检查，并及时修复已识别的风险。',
              ),
            ],
          ),
          _PolicySection(
            title: '五、您的权利',
            icon: Icons.how_to_reg_rounded,
            items: [
              _PolicyItem(
                title: '查询与复制',
                content:
                    '在符合法律规定的情况下，您有权查询我们持有的与您相关的个人信息，并申请复制。',
              ),
              _PolicyItem(
                title: '更正与补充',
                content:
                    '若信息不准确或不完整，您可在应用内更正，或联系客户协助处理。',
              ),
              _PolicyItem(
                title: '删除与注销',
                content:
                    '在符合法律法规的情况下，您可申请删除相关信息或注销账号。',
              ),
              _PolicyItem(
                title: '撤回同意',
                content:
                    '对于基于授权同意处理的信息，您可随时撤回授权；撤回前已完成的处理不受影响。',
              ),
            ],
          ),
          _PolicySection(
            title: '六、未成年人保护',
            icon: Icons.child_care_rounded,
            items: [
              _PolicyItem(
                title: '年龄要求',
                content:
                    '若您为未成年人，请在监护人同意和指导下使用本平台。如发现存在违规收集未成年人信息的情形，我们会及时处理。',
              ),
            ],
          ),
          _PolicySection(
            title: '七、政策更新',
            icon: Icons.update_rounded,
            items: [
              _PolicyItem(
                title: '更新通知',
                content:
                    '当本政策发生重大变化时，我们会通过应用内公告、弹窗或其他合理方式提醒您。',
              ),
              _PolicyItem(
                title: '联系我们',
                content:
                    '若您对本政策或我们的信息处理方式有疑问，请通过下方联系方式与我们联系。',
              ),
            ],
          ),
        ],
      );
  }
}

class _PrivacyContent {
  final String cardTitle;
  final String updatedAt;
  final String intro;
  final String contactTitle;
  final List<_ContactInfo> contacts;
  final List<_PolicySection> sections;

  const _PrivacyContent({
    required this.cardTitle,
    required this.updatedAt,
    required this.intro,
    required this.contactTitle,
    required this.contacts,
    required this.sections,
  });
}

class _PolicySection {
  final String title;
  final IconData icon;
  final List<_PolicyItem> items;

  const _PolicySection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _PolicyItem {
  final String title;
  final String content;

  const _PolicyItem({
    required this.title,
    required this.content,
  });
}

class _ContactInfo {
  final IconData icon;
  final String text;

  const _ContactInfo(this.icon, this.text);
}
