import 'package:flutter/material.dart';

import '../../themes/colors.dart';

/// 汇玉源用户协议页面
class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFFAF8FF);
    final textColor = isDark ? Colors.white : JewelryColors.textPrimary;
    final subColor = isDark ? Colors.white70 : Colors.black87;
    final divColor = isDark ? Colors.white12 : Colors.black12;

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
          '用户协议',
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
                      ? [const Color(0xFF2A1F3D), const Color(0xFF1A1A2E)]
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
                          '汇玉源用户协议',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '最后更新日期：2026年3月18日',
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
            _buildIntroText(
              '欢迎使用汇玉源珠宝智能交易平台。在您注册、登录或使用本平台服务之前，请认真阅读本协议。'
              '您完成注册、点击同意或继续使用本平台，即视为已阅读并接受本协议全部条款。',
              subColor,
            ),
            const SizedBox(height: 20),
            _buildSection(
              '一、协议适用范围',
              Icons.gavel_rounded,
              const [
                _AgreementItem('协议主体', '本协议适用于用户与汇玉源平台运营方之间就平台产品和服务所建立的法律关系。'),
                _AgreementItem(
                    '服务范围', '平台服务包括商品浏览、交易下单、订单履约、AI 辅助、账户管理及平台后续依法提供的其他服务。'),
                _AgreementItem('协议变更', '平台可根据业务发展、监管要求或产品调整更新本协议，并以合理方式向您提示。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '二、账号注册与安全',
              Icons.manage_accounts_rounded,
              const [
                _AgreementItem('注册要求', '您应当具备相应民事行为能力，并使用真实、合法、有效的信息完成账号注册。'),
                _AgreementItem('账号安全', '您应妥善保管账号、密码、验证码及其他身份凭证，并对账号下的操作承担责任。'),
                _AgreementItem('异常处理', '如发现账号被盗用、异常登录或其他安全风险，请尽快联系平台处理。'),
                _AgreementItem('实名或补充认证', '在特定交易、售后或风控场景下，平台可要求您完成补充身份认证。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '三、商品与平台服务',
              Icons.diamond_rounded,
              const [
                _AgreementItem(
                    '商品信息', '平台会尽力确保商品展示信息、材质说明、证书信息和价格信息真实、清晰、可识别。'),
                _AgreementItem(
                    '区块链或证书信息', '对于展示的认证信息、证书编号等内容，平台会按业务规则进行展示和校验。'),
                _AgreementItem('价格与库存',
                    '商品价格、库存、活动权益以实际下单时系统页面为准；因系统延迟或异常导致的明显错误，平台有权更正。'),
                _AgreementItem('服务可用性', '平台会持续维护服务稳定，但不承诺服务绝对不中断或完全无错误。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '四、订单、支付与售后',
              Icons.receipt_long_rounded,
              const [
                _AgreementItem('订单成立', '您提交订单并完成必要的确认流程后，订单是否成立以系统确认结果为准。'),
                _AgreementItem('支付规则', '您应按照页面展示的支付方式和流程完成付款，平台会记录必要的支付状态信息。'),
                _AgreementItem(
                    '履约与售后', '订单履约、配送、签收、退换货和售后处理，按页面规则、商品说明和适用法律执行。'),
                _AgreementItem(
                    '异常订单', '对于涉嫌刷单、套现、恶意退款、欺诈或其他异常交易，平台有权暂停处理并进行核验。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '五、用户行为规范',
              Icons.rule_rounded,
              const [
                _AgreementItem('真实合法', '您不得发布虚假信息、冒用他人身份或利用平台从事违法违规活动。'),
                _AgreementItem(
                    '禁止干扰', '您不得使用脚本、爬虫、外挂或其他方式干扰平台正常运行，或绕过平台规则获取不当利益。'),
                _AgreementItem('禁止侵权', '您不得上传、传播侵犯他人知识产权、隐私权、肖像权或其他合法权益的内容。'),
                _AgreementItem(
                    '合规使用 AI 功能', '使用平台 AI 功能时，您应自行审慎判断生成内容，不得将其用于违法违规用途。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '六、知识产权',
              Icons.copyright_rounded,
              const [
                _AgreementItem(
                    '平台内容归属', '平台界面、设计、文字、图像、代码、服务标识及相关内容的知识产权归平台或权利人所有。'),
                _AgreementItem(
                    '用户内容授权', '您上传或提交的内容，应保证拥有合法权利，并授权平台在提供服务所需范围内进行展示、存储和处理。'),
                _AgreementItem('第三方内容', '如平台中包含第三方内容或服务，其权利归属以相应权利人和协议约定为准。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '七、责任限制',
              Icons.info_outline_rounded,
              const [
                _AgreementItem(
                    '不可抗力', '因不可抗力、系统维护、网络故障或第三方服务异常导致的服务中断，平台将在合理范围内尽力恢复。'),
                _AgreementItem('用户原因', '因您自身设备、网络环境、账号保管不当或操作失误造成的损失，由您自行承担。'),
                _AgreementItem(
                    '合理注意义务', '平台会以合理商业努力保障服务质量，但不对超出合理控制范围的结果作绝对保证。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '八、协议终止与争议解决',
              Icons.logout_rounded,
              const [
                _AgreementItem(
                    '用户注销', '您可以按照平台规则申请注销账号，但在注销前应处理完毕未完成的订单、售后或其他待履行事项。'),
                _AgreementItem(
                    '平台处理权', '若您违反本协议或相关规则，平台有权视情况限制功能、暂停服务或终止账号使用。'),
                _AgreementItem('争议解决',
                    '本协议的订立、履行和解释适用中华人民共和国法律；若产生争议，双方应先协商，协商不成的，提交有管辖权的人民法院处理。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: divColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '联系方式',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _contactRow(Icons.support_agent_rounded, '客服热线：400-888-8888',
                      subColor),
                  const SizedBox(height: 6),
                  _contactRow(Icons.email_outlined,
                      '邮箱：service@huiyuanyuan.com', subColor),
                  const SizedBox(height: 6),
                  _contactRow(
                      Icons.gavel_rounded, '争议处理：依法向有管辖权法院提起诉讼', subColor),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 14, height: 1.8),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<_AgreementItem> items,
    bool isDark,
    Color textColor,
    Color subColor,
    Color divColor,
  ) {
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
                                entry.value.title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.value.content,
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: JewelryColors.gold, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color.withOpacity(0.75),
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _AgreementItem {
  final String title;
  final String content;

  const _AgreementItem(this.title, this.content);
}
