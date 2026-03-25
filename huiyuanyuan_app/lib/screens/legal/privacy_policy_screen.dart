import 'package:flutter/material.dart';

import '../../themes/colors.dart';

/// 汇玉源隐私政策页面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          '隐私政策',
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
                          '汇玉源隐私政策',
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
              '本隐私政策用于说明汇玉源如何收集、使用、存储、共享和保护您在使用本平台期间产生的个人信息。'
              '我们会按照合法、正当、必要和诚信原则处理您的信息，并尽力保障您的知情权与选择权。',
              subColor,
            ),
            const SizedBox(height: 20),
            _buildSection(
              '一、我们收集的信息',
              Icons.input_rounded,
              const [
                _PolicyItem(
                    '注册与账号信息', '当您注册或登录时，我们会处理手机号、用户名、用户类型以及必要的登录凭证信息。'),
                _PolicyItem(
                    '交易与收货信息', '当您下单、收货或申请售后时，我们会处理订单信息、收货地址、联系人、支付相关记录等必要信息。'),
                _PolicyItem(
                    '设备与日志信息', '为保障服务稳定性，我们会记录设备型号、系统版本、应用日志、访问时间、请求结果等运行信息。'),
                _PolicyItem('客服与反馈信息', '当您联系客服、提交反馈或发起争议处理时，我们会保存沟通内容及处理结果。'),
                _PolicyItem(
                    '位置信息', '仅在您授权的前提下，我们才会处理位置信息，用于门店推荐、附近服务等与位置相关的功能。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '二、我们如何使用信息',
              Icons.tune_rounded,
              const [
                _PolicyItem('提供基础服务', '用于完成账号登录、商品展示、下单购买、订单履约、售后处理等核心功能。'),
                _PolicyItem('安全风控', '用于识别异常登录、欺诈行为、接口滥用及其他可能危及平台安全的行为。'),
                _PolicyItem('个性化推荐', '在符合法律规定的前提下，我们会根据浏览、收藏、搜索等行为改进推荐结果。'),
                _PolicyItem('服务通知', '用于发送订单状态、账户安全、规则更新等必要通知。'),
                _PolicyItem('统计与改进', '用于分析系统性能和功能使用情况，以持续优化产品体验。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '三、我们如何保护信息',
              Icons.shield_rounded,
              const [
                _PolicyItem('传输加密', '应用与服务端之间的敏感数据传输会采用加密通道，降低传输过程中被截获的风险。'),
                _PolicyItem('权限控制', '我们对后台数据访问实行最小权限控制，仅授权有业务需要的人员访问。'),
                _PolicyItem('安全监测', '我们会持续进行日志审计、异常告警和安全巡检，并对已知风险进行修复。'),
                _PolicyItem('存储期限', '我们仅在实现业务目的所需的最短期限内保存您的信息，法律法规另有规定的除外。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '四、信息共享与披露',
              Icons.share_rounded,
              const [
                _PolicyItem('最小必要原则', '除法律法规另有规定外，我们不会向无关第三方出售您的个人信息。'),
                _PolicyItem('受托处理与合作方',
                    '为完成支付、物流、消息通知等服务，我们可能向必要的合作方提供最小范围的信息，并要求其承担相应保护义务。'),
                _PolicyItem('依法披露', '在符合法律法规、司法程序或监管要求的情况下，我们可能依法披露相关信息。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '五、您的权利',
              Icons.how_to_reg_rounded,
              const [
                _PolicyItem('查询与复制', '您有权查询我们持有的与您相关的个人信息，并在符合法律规定的情况下申请复制。'),
                _PolicyItem('更正与补充', '如果您发现信息不准确或不完整，可以通过应用内资料页或联系客服进行更正。'),
                _PolicyItem('删除与注销', '在符合法律规定的情况下，您可以申请删除相关信息或注销账户。'),
                _PolicyItem('撤回同意', '对于基于授权同意处理的信息，您可以撤回授权。撤回前的处理活动不受影响。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '六、本地存储与类似技术',
              Icons.manage_search_rounded,
              const [
                _PolicyItem('本地存储',
                    '应用会使用本地存储能力，例如 SharedPreferences，用于保存登录态、偏好设置和必要的功能状态。'),
                _PolicyItem('无跨站跟踪', '当前应用不使用面向广告目的的第三方跨站跟踪 Cookie。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '七、未成年人保护',
              Icons.child_care_rounded,
              const [
                _PolicyItem('年龄要求',
                    '若您为未成年人，请在监护人同意和指导下使用本平台。若我们发现存在违规收集未成年人信息的情形，会尽快处理。'),
              ],
              isDark,
              textColor,
              subColor,
              divColor,
            ),
            _buildSection(
              '八、政策更新与联系我们',
              Icons.update_rounded,
              const [
                _PolicyItem('更新通知', '当本政策发生重大变化时，我们会通过应用内公告、弹窗或其他合理方式提示您。'),
                _PolicyItem('联系渠道', '如您对隐私政策或信息处理存在疑问，可通过页面底部提供的方式与我们联系。'),
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
                  _contactRow(
                      Icons.phone_outlined, '客服热线：400-888-8888', subColor),
                  const SizedBox(height: 6),
                  _contactRow(Icons.email_outlined,
                      '邮箱：privacy@huiyuanyuan.com', subColor),
                  const SizedBox(height: 6),
                  _contactRow(
                      Icons.location_on_outlined, '地址：中国大陆地区运营主体所在地', subColor),
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
    List<_PolicyItem> items,
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
        Icon(icon, color: JewelryColors.primary, size: 16),
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

class _PolicyItem {
  final String title;
  final String content;

  const _PolicyItem(this.title, this.content);
}
