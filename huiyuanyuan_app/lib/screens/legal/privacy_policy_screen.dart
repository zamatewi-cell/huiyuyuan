import 'package:flutter/material.dart';
import '../../themes/colors.dart';

/// ��˽����ȫ��ҳ��
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
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : JewelryColors.textPrimary,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '��˽����',
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
            // ͷ����Ƭ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A1F3D), const Color(0xFF1A1A2E)]
                      : [JewelryColors.primary.withOpacity(0.08),
                         JewelryColors.primary.withOpacity(0.03)],
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
                    child: const Icon(Icons.privacy_tip,
                        color: JewelryColors.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('����Դ��˽����',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('���������ڣ�2026��2��22��',
                            style: TextStyle(
                                color: subColor.withOpacity(0.6),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildIntroText(
              '����˽���������˻���Դ�����¼��"����"������ռ���ʹ�úͱ�������ʹ�û���Դ�鱦���ܽ���ƽ̨�����¼��"��ƽ̨"��'
              '�����еĸ�����Ϣ�������ϸ����ء�������Ϣ����������PIPL������ط��ɷ��档',
              subColor,
            ),
            const SizedBox(height: 20),

            _buildSection('һ����Ϣ�ռ�', Icons.input_rounded, [
              _PolicyItem('ע����Ϣ', '����ע���˻�ʱ�ṩ���ֻ����롢�û����Ȼ�����Ϣ��'),
              _PolicyItem('������Ϣ', '����ʹ�ñ�ƽ̨���й�������в����Ķ�����¼���ջ���ַ��֧����¼����Ϣ��'),
              _PolicyItem('�豸��Ϣ', '�����Զ��ռ���ʹ�õ��豸�ͺš�����ϵͳ�汾��Ψһ�豸��ʶ������Ϣ�����ڱ��Ϸ����ȶ��ԡ�'),
              _PolicyItem('��־��Ϣ', '��ʹ�÷���ʱ������������־�����ʼ�¼��������־����Ϣ��'),
              _PolicyItem('λ����Ϣ', '��������ȷ��Ȩ������£����ǲŻ��ռ�����λ����Ϣ�������ṩ�����̼��Ƽ��ȷ���'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('������Ϣʹ��', Icons.tune_rounded, [
              _PolicyItem('�����ṩ', '�ṩ��Ʒչʾ�����߽��ס�����׷�ټ��ۺ����'),
              _PolicyItem('���Ի��Ƽ�', '������������͹����¼��Ϊ���Ƽ����ܸ���Ȥ����Ʒ��'),
              _PolicyItem('��ȫ����', '�����˻���ȫ��ʶ���Ԥ����թ��Ϊ��'),
              _PolicyItem('֪ͨ����', '�������Ͷ���״̬��������������Ҫ֪ͨ�����������йرգ���'),
              _PolicyItem('���Ʒ���', '�����û���Ϊ���ݣ������Ż���Ʒ���ܺ��û����顣'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('������Ϣ����', Icons.shield_rounded, [
              _PolicyItem('�������', '�������ݴ�������� TLS ���ܣ���ֹ�����ڴ���;�б��ػ�'),
              _PolicyItem('�洢��ȫ', '���õȱ�������ȫ������ϵ�����ڽ��а�ȫ©��ɨ�����͸���ԡ�'),
              _PolicyItem('���ʿ���', '�ϸ�����Ա�����ݷ���Ȩ�ޣ�ʵ����СȨ��ԭ��'),
              _PolicyItem('��������֤', '��Ʒ��Դ��Ϣ������֤��ȷ�����ݲ��ɴ۸ġ�'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�ġ���Ϣ����', Icons.share_rounded, [
              _PolicyItem('������ԭ��', '���ǳ�ŵ�����Ὣ���ĸ�����Ϣ���۸��κε�������'),
              _PolicyItem('�����̹���', '���ǿ�����������֧���Ⱥ��������̹����Ҫ��Ϣ����Щ�������ܵ���ͬԼ����ֻ����ָ��Ŀ�ķ�Χ�ڴ����������ݡ�'),
              _PolicyItem('����Ҫ��', '�ڷ��ɷ���Ҫ��˾������������ȡ������£����ǿ��������ṩ�����Ϣ��'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�塢����Ȩ��', Icons.how_to_reg_rounded, [
              _PolicyItem('����Ȩ', '����Ȩ�鿴���ǳ��еĹ������ĸ�����Ϣ��'),
              _PolicyItem('����Ȩ', '�������ָ�����Ϣ���󣬿����������'),
              _PolicyItem('ɾ��Ȩ', '����������ɾ��������Ϣ�����ǽ��ں�����������ɴ����'),
              _PolicyItem('ע���˻�', '��������ʱ��"�������� �� ����"��ע���˻���ע�������ǽ�ɾ�����������������ĸ�����Ϣ��'),
              _PolicyItem('����ͬ��', '��������ʱ���ض��ض����ݴ�����ͬ�⣬���ز�Ӱ�쳷��ǰ�ѽ��еĴ����ĺϷ��ԡ�'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('����Cookie �����Ƽ���', Icons.manage_search_rounded, [
              _PolicyItem('���ش洢', '����ʹ�ñ��ش洢���� SharedPreferences���������ĵ�¼״̬��ƫ�����õȣ�������ʹ�����顣'),
              _PolicyItem('�޿�վ׷��', '���ǲ�ʹ�õ����� Cookie ��վ׷��������Ϊ��'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�ߡ�δ�����˱���', Icons.child_care_rounded, [
              _PolicyItem('��������', '��ƽ̨������ 18 ������δ�������ṩ�����緢��δ������ע���˻������ǽ���ʱɾ�������Ϣ��'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�ˡ����߸���', Icons.update_rounded, [
              _PolicyItem('֪ͨ��ʽ', '����˽���߷����ش���ʱ�����ǽ�ͨ��Ӧ���ڵ�����վ���ŷ�ʽ֪ͨ����'),
              _PolicyItem('����ʹ����Ϊͬ��', '��֪ͨ�����ʹ�ñ�ƽ̨����Ϊ�����ܸ��º����˽���ߡ�'),
            ], isDark, textColor, subColor, divColor),

            const SizedBox(height: 20),
            // ��ϵ��ʽ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: divColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('��ϵ����',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _contactRow(Icons.phone_outlined, '�ͷ����ߣ�400-888-8888', subColor),
                  const SizedBox(height: 6),
                  _contactRow(Icons.email_outlined, '���䣺privacy@huiyuanyuan.com', subColor),
                  const SizedBox(height: 6),
                  _contactRow(Icons.location_on_outlined, '��ַ���й���½����', subColor),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroText(String text, Color color) => Text(
        text,
        style: TextStyle(color: color, fontSize: 14, height: 1.8),
      );

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
            Text(title,
                style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
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
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
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
                              Text(e.value.title,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(e.value.content,
                                  style: TextStyle(
                                      color: subColor.withOpacity(0.75),
                                      fontSize: 13,
                                      height: 1.6)),
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

  Widget _contactRow(IconData icon, String text, Color color) => Row(
        children: [
          Icon(icon, color: JewelryColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: color.withOpacity(0.75), fontSize: 13, height: 1.6)),
        ],
      );
}

class _PolicyItem {
  final String title;
  final String content;
  const _PolicyItem(this.title, this.content);
}
