library;

import 'package:flutter/material.dart';

import '../../themes/colors.dart';

class AdminOperatorTab extends StatefulWidget {
  const AdminOperatorTab({super.key});

  @override
  State<AdminOperatorTab> createState() => _AdminOperatorTabState();
}

class _AdminOperatorTabState extends State<AdminOperatorTab> {
  int _selectedIndex = 0;

  _OperatorSnapshot get _selectedOperator => _operatorSnapshots[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    final selectedOperator = _selectedOperator;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: JewelryColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Operator Performance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track follow-up quality, AI usage, and conversion by operator.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List<Widget>.generate(_operatorSnapshots.length, (
                    index,
                  ) {
                    final operator = _operatorSnapshots[index];
                    final isSelected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected ? JewelryColors.primaryGradient : null,
                          color: isSelected
                              ? null
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              operator.code,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              operator.name,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedOperator.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedOperator.focusArea,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: JewelryColors.gold.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        selectedOperator.stageLabel,
                        style: const TextStyle(
                          color: JewelryColors.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      label: 'Contacted shops',
                      value: '${selectedOperator.contactedShops}',
                      color: JewelryColors.primary,
                      icon: Icons.store_mall_directory_outlined,
                    ),
                    _MetricCard(
                      label: 'Intentions',
                      value: '${selectedOperator.intentions}',
                      color: JewelryColors.gold,
                      icon: Icons.trending_up_rounded,
                    ),
                    _MetricCard(
                      label: 'Wins',
                      value: '${selectedOperator.wins}',
                      color: JewelryColors.success,
                      icon: Icons.handshake_outlined,
                    ),
                    _MetricCard(
                      label: 'AI sessions',
                      value: '${selectedOperator.aiSessions}',
                      color: const Color(0xFF667EEA),
                      icon: Icons.auto_awesome_rounded,
                    ),
                    _MetricCard(
                      label: 'Order amount',
                      value: _formatCurrency(selectedOperator.orderAmount),
                      color: JewelryColors.primary,
                      icon: Icons.payments_outlined,
                    ),
                    _MetricCard(
                      label: 'Response SLA',
                      value: selectedOperator.responseSla,
                      color: const Color(0xFF14B8A6),
                      icon: Icons.schedule_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final whole = amount.round().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      final reverseIndex = whole.length - index;
      buffer.write(whole[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'CNY $buffer';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorSnapshot {
  const _OperatorSnapshot({
    required this.code,
    required this.name,
    required this.focusArea,
    required this.stageLabel,
    required this.contactedShops,
    required this.intentions,
    required this.wins,
    required this.aiSessions,
    required this.orderAmount,
    required this.responseSla,
  });

  final String code;
  final String name;
  final String focusArea;
  final String stageLabel;
  final int contactedShops;
  final int intentions;
  final int wins;
  final int aiSessions;
  final double orderAmount;
  final String responseSla;
}

const List<_OperatorSnapshot> _operatorSnapshots = <_OperatorSnapshot>[
  _OperatorSnapshot(
    code: 'OP-01',
    name: 'Operator 01',
    focusArea: 'Wholesale recovery and repeat buyers',
    stageLabel: 'Stable',
    contactedShops: 23,
    intentions: 8,
    wins: 3,
    aiSessions: 156,
    orderAmount: 8560,
    responseSla: '< 15 min',
  ),
  _OperatorSnapshot(
    code: 'OP-02',
    name: 'Operator 02',
    focusArea: 'New catalog onboarding',
    stageLabel: 'Growing',
    contactedShops: 31,
    intentions: 12,
    wins: 5,
    aiSessions: 184,
    orderAmount: 12680,
    responseSla: '< 12 min',
  ),
  _OperatorSnapshot(
    code: 'OP-03',
    name: 'Operator 03',
    focusArea: 'VIP conversion and high-ticket orders',
    stageLabel: 'Top',
    contactedShops: 19,
    intentions: 11,
    wins: 6,
    aiSessions: 143,
    orderAmount: 18900,
    responseSla: '< 10 min',
  ),
  _OperatorSnapshot(
    code: 'OP-04',
    name: 'Operator 04',
    focusArea: 'Dormant account reactivation',
    stageLabel: 'Recovering',
    contactedShops: 27,
    intentions: 9,
    wins: 4,
    aiSessions: 132,
    orderAmount: 9740,
    responseSla: '< 18 min',
  ),
];
