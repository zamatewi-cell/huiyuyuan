import 'package:flutter/material.dart';
import '../../themes/colors.dart';

/// �û�����Э��ȫ��ҳ��
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
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : JewelryColors.textPrimary,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '�û�����Э��',
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
                      : [JewelryColors.gold.withOpacity(0.08),
                         JewelryColors.gold.withOpacity(0.03)],
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
                    child: const Icon(Icons.description_rounded,
                        color: JewelryColors.gold, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('����Դ�û�����Э��',
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
              '��ӭʹ�û���Դ�鱦���ܽ���ƽ̨��������ע���˻���ʹ�ñ�ƽ̨ǰ����ϸ�Ķ������û�����Э�顷�����¼��"��Э��"����'
              '��Э����к�ͬЧ���������"ͬ��"�����ʹ�ñ�ƽ̨������ʾ�����ܱ�Э��ȫ�����',
              subColor,
            ),
            const SizedBox(height: 20),

            _buildSection('һ������', Icons.gavel_rounded, [
              _AgreementItem('��������',
                  '��Э�����������¼��"�û�"�������Դƽ̨��Ӫ�������¼��"ƽ̨"����������������ʹ�û���Դ�ṩ�����з���'),
              _AgreementItem('���÷�Χ',
                  '��Э�������ڻ���Դ�ƶ�Ӧ�ó���App������ط��񣬰�������������Ʒ��������߹���AI���֡�AR�Դ��ȹ��ܡ�'),
              _AgreementItem('Э�����',
                  'ƽ̨��Ȩ����ҵ��չ��Ҫ�޸ı�Э�飬�޸ĺ�ͨ��App��֪ͨ��֪�û�������ʹ�ñ�ƽ̨����Ϊͬ���޸ĺ��Э�顣'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�����˻�ע�������', Icons.manage_accounts_rounded, [
              _AgreementItem('ע��Ҫ��',
                  '�û�������18���꣬��ʹ����ʵ��Ч���ֻ��������ע�ᡣ'),
              _AgreementItem('�˻�Ψһ��',
                  'ÿ���ֻ��������ע��һ���˻�����ֹת�á����������˻���'),
              _AgreementItem('�˻���ȫ',
                  '�û�Ӧ���Ʊ����˻���Ϣ���򱣹ܲ������µ���ʧ���û����ге���'),
              _AgreementItem('ʵ����֤',
                  '������д��׻�ʹ���ض����ܣ�ƽ̨����Ҫ���û����ʵ����֤��'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('������Ʒ�����', Icons.diamond_rounded, [
              _AgreementItem('��Ʒ����',
                  'ƽ̨������Ʒ�������ϸ���ˣ���֤Ϊ��Ʒ�������鱦��ʯ��Ʒ������Ȩ������֤�顣'),
              _AgreementItem('��������Դ',
                  '�û���ͨ����������Դ������֤��Ʒ��ʵ�ԺͲ�����Ϣ��������ݲ��ɴ۸ġ�'),
              _AgreementItem('�۸�˵��',
                  'ҳ��չʾ����Ʒ�۸����µ�ʱΪ׼��ƽ̨�����޸ļ۸��Ȩ��������Ӱ���ѳɽ�������'),
              _AgreementItem('������',
                  'ƽ̨��Ȩ�����������ݣ�������ǰ֪ͨ�û�����Ӱ���û��ѹ���ķ���'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�ġ����׹���', Icons.receipt_long_rounded, [
              _AgreementItem('������Ч',
                  '�û��ύ���������֧���󣬶�����ʽ��Ч��ƽ̨��ʼ���ŷ�����'),
              _AgreementItem('�˻�������',
                  '֧��7���������˻�����������Ʒ��������Ʒ���⣩����Ʒ�豣��ԭ��װ��ã���Ӱ��������ۡ�'),
              _AgreementItem('��ֹ��Ϊ',
                  '�û����ö���ˢ����������ۡ���ȡƽ̨�Żݣ�Υ��ƽ̨��Ȩ����˻���׷���������Ρ�'),
              _AgreementItem('���鴦��',
                  '�罻�׷������飬�û���ͨ��ƽ̨�ͷ����������⣬ƽ̨�����ݽ��׼�¼���������'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�塢�û���Ϊ�淶', Icons.rule_rounded, [
              _AgreementItem('��ʵ��Ϣ',
                  '�û����÷��������Ʒ��Ϣ�����ۻ��κ���ƭ�����ݡ�'),
              _AgreementItem('��ȫʹ��',
                  '�û��������ü����ֶΣ������桢�ű������Ż��ƻ�ƽ̨������Ӫ��'),
              _AgreementItem('�Ϸ�ʹ��',
                  '�û��������й���½���õ����з��ɷ��棬�������ñ�ƽ̨����Υ�����'),
              _AgreementItem('��ֹ����',
                  '�û����÷����ַ�����֪ʶ��Ȩ����˽Ȩ�������Ϸ�Ȩ������ݡ�'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('����֪ʶ��Ȩ', Icons.copyright_rounded, [
              _AgreementItem('ƽ̨����',
                  '��ƽ̨���������ݣ����������������֡�ͼƬ����Ƶ��������ƣ���֪ʶ��Ȩ�����Դ���С�'),
              _AgreementItem('�û�����',
                  '�û����������ݣ�����Ʒ���ۡ�ͼƬ��Ӧ��֤���ַ�������Ȩ�棬�û�����ƽ̨�Ƕ�ռ�Ե�չʾ�ʹ�����ɡ�'),
              _AgreementItem('AI ����',
                  '�� AI �������ɵ����ݽ����ο�����Ȩ�����������÷���ȷ����'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�ߡ���������', Icons.info_outline_rounded, [
              _AgreementItem('���ɿ���',
                  '����Ȼ�ֺ���ս����������Ϊ��������ϵȲ��ɿ������ص��µķ����жϣ�ƽ̨���е����Ρ�'),
              _AgreementItem('����������',
                  '��ƽ̨�������������������񣬶Ե�������������ݺͰ�ȫ�ԣ�ƽ̨������֤��'),
              _AgreementItem('�����ж�',
                  '��ϵͳά���������ȵ��µ���ʱ�����жϣ�ƽ̨����ǰ֪ͨ�����е��⳥���Ρ�'),
            ], isDark, textColor, subColor, divColor),

            _buildSection('�ˡ�Э����ֹ', Icons.logout_rounded, [
              _AgreementItem('�û�ע��',
                  '�û�����ʱ����ע���˻���ע��ǰ��������д�����Ķ������ʽ�'),
              _AgreementItem('ƽ̨���',
                  '�û�Υ����Э�飬ƽ̨��Ȩ��ͣ�����÷���˻���������֪ͨ��'),
              _AgreementItem('��ֹЧ��',
                  'Э����ֹ���û���Ȩ�����˻��ڵ����ݣ�ƽ̨��������˽���ߴ�����ظ�����Ϣ��'),
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
                  _contactRow(Icons.support_agent_rounded, '�ͷ����ߣ�400-888-8888', subColor),
                  const SizedBox(height: 6),
                  _contactRow(Icons.email_outlined, '���䣺service@huiyuanyuan.com', subColor),
                  const SizedBox(height: 6),
                  _contactRow(Icons.gavel_rounded, '���׹�Ͻ���л����񹲺͹��ڵط�Ժ', subColor),
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
                            color: JewelryColors.gold,
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
          Icon(icon, color: JewelryColors.gold, size: 16),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: color.withOpacity(0.75), fontSize: 13, height: 1.6)),
        ],
      );
}

class _AgreementItem {
  final String title;
  final String content;
  const _AgreementItem(this.title, this.content);
}
