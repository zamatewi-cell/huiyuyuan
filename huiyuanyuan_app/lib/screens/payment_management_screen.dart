import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/payment_account.dart';
import '../providers/payment_provider.dart';
import '../widgets/common/glassmorphic_card.dart';

class PaymentManagementScreen extends ConsumerWidget {
  const PaymentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(paymentAccountsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('收款账户管理'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.9),
                Theme.of(context).colorScheme.surface.withOpacity(0.5),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: isDark
            ? null
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[50]!,
                  ],
                ),
              ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PaymentAccountCard(account: account),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, ref, null),
        label: const Text('新增账户'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, PaymentAccount? account) {
    showDialog(
      context: context,
      builder: (context) => _PaymentAccountDialog(account: account),
    );
  }
}

class _PaymentAccountCard extends ConsumerWidget {
  final PaymentAccount account;

  const _PaymentAccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassmorphicCard(
      opacity: isDark ? 0.1 : 0.6,
      blur: 20,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(account.type),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (account.accountNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          account.accountNumber!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ],
                      if (account.bankName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          account.bankName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: account.isActive,
                  onChanged: (value) {
                    ref
                        .read(paymentAccountsProvider.notifier)
                        .toggleActive(account.id);
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          _PaymentAccountDialog(account: account),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('编辑'),
                ),
                TextButton.icon(
                  onPressed: () {
                    _confirmDelete(context, ref, account);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(PaymentType type) {
    switch (type) {
      case PaymentType.bank:
        return Icons.account_balance;
      case PaymentType.alipay:
        return Icons.payment; // Replace with custom icon if available
      case PaymentType.wechat:
        return Icons.qr_code; // Replace with custom icon if available
      case PaymentType.cash:
        return Icons.money;
      case PaymentType.other:
        return Icons.credit_card;
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, PaymentAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${account.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(paymentAccountsProvider.notifier)
                  .deleteAccount(account.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _PaymentAccountDialog extends ConsumerStatefulWidget {
  final PaymentAccount? account;

  const _PaymentAccountDialog({this.account});

  @override
  ConsumerState<_PaymentAccountDialog> createState() =>
      _PaymentAccountDialogState();
}

class _PaymentAccountDialogState extends ConsumerState<_PaymentAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late PaymentType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _accountNumberController =
        TextEditingController(text: widget.account?.accountNumber ?? '');
    _bankNameController =
        TextEditingController(text: widget.account?.bankName ?? '');
    _selectedType = widget.account?.type ?? PaymentType.bank;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.account == null ? '新增收款账户' : '编辑收款账户',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<PaymentType>(
                  value: _selectedType,
                  decoration: const InputDecoration(labelText: '账户类型'),
                  items: PaymentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: '账户名称 (如: 公司主账户)'),
                  validator: (value) =>
                      value == null || value.isEmpty ? '请输入账户名称' : null,
                ),
                const SizedBox(height: 16),
                if (_selectedType == PaymentType.bank) ...[
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(labelText: '开户行'),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(labelText: '账号 / 收款码链接'),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final account = PaymentAccount(
        id: widget.account?.id ?? const Uuid().v4(),
        name: _nameController.text,
        type: _selectedType,
        accountNumber: _accountNumberController.text.isNotEmpty
            ? _accountNumberController.text
            : null,
        bankName: _bankNameController.text.isNotEmpty
            ? _bankNameController.text
            : null,
        isActive: widget.account?.isActive ?? true,
      );

      if (widget.account == null) {
        ref.read(paymentAccountsProvider.notifier).addAccount(account);
      } else {
        ref.read(paymentAccountsProvider.notifier).updateAccount(account);
      }
      Navigator.pop(context);
    }
  }

  String _getTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.bank:
        return '银行卡';
      case PaymentType.alipay:
        return '支付宝';
      case PaymentType.wechat:
        return '微信支付';
      case PaymentType.cash:
        return '现金';
      case PaymentType.other:
        return '其他';
    }
  }
}
