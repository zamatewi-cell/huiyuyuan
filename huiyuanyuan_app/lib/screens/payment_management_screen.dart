import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_account.dart';
import '../providers/payment_provider.dart';
import '../widgets/common/glassmorphic_card.dart';

class PaymentManagementScreen extends ConsumerWidget {
  const PaymentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentAccountsProvider);
    final isLoading = paymentState.state == PaymentLoadingState.loading;
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
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(paymentAccountsProvider.notifier).loadAccounts();
            },
          ),
        ],
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
        child: _buildContent(context, paymentState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, null),
        label: const Text('新增账户'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentAccountsState state) {
    if (state.state == PaymentLoadingState.loading && state.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.state == PaymentLoadingState.error && state.accounts.isEmpty) {
      return _buildErrorState(context, state.errorMessage ?? '加载支付账户失败');
    }

    if (state.accounts.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
      itemCount: state.accounts.length,
      itemBuilder: (context, index) {
        final account = state.accounts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _PaymentAccountCard(account: account),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, PaymentAccount? account) {
    showDialog<void>(
      context: context,
      builder: (context) => _PaymentAccountDialog(account: account),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '还没有收款账户',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请先添加真实的银行卡、支付宝或微信收款账户，再开始收款。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showEditDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text('新增账户'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '加载失败',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Consumer(
              builder: (context, ref, _) {
                return FilledButton.icon(
                  onPressed: () {
                    ref.read(paymentAccountsProvider.notifier).loadAccounts();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                );
              },
            ),
          ],
        ),
      ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            account.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (account.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '默认账户',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.typeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      if (account.accountNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          account.accountNumber!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.75),
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
                  onChanged: (_) async {
                    final success = await ref
                        .read(paymentAccountsProvider.notifier)
                        .toggleActive(account.id);
                    if (!success && context.mounted) {
                      _showErrorSnackBar(
                        context,
                        ref.read(paymentAccountsProvider).errorMessage ??
                            '更新账户状态失败',
                      );
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!account.isDefault)
                  TextButton.icon(
                    onPressed: () async {
                      final success = await ref
                          .read(paymentAccountsProvider.notifier)
                          .updateAccount(account.copyWith(isDefault: true));
                      if (!success && context.mounted) {
                        _showErrorSnackBar(
                          context,
                          ref.read(paymentAccountsProvider).errorMessage ??
                              '设置默认账户失败',
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('设为默认'),
                  ),
                TextButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) =>
                          _PaymentAccountDialog(account: account),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('编辑'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    _confirmDelete(context, ref, account);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('删除'),
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
        return Icons.payment;
      case PaymentType.wechat:
        return Icons.qr_code;
      case PaymentType.cash:
        return Icons.money;
      case PaymentType.other:
        return Icons.credit_card;
    }
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, PaymentAccount account) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除“${account.name}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final success = await ref
                    .read(paymentAccountsProvider.notifier)
                    .deleteAccount(account.id);
                if (!dialogContext.mounted) {
                  return;
                }
                if (success) {
                  Navigator.pop(dialogContext);
                  return;
                }
                _showErrorSnackBar(
                  dialogContext,
                  ref.read(paymentAccountsProvider).errorMessage ?? '删除支付账户失败',
                );
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
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
  late final TextEditingController _nameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _bankNameController;
  late PaymentType _selectedType;
  late bool _isDefault;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _accountNumberController =
        TextEditingController(text: widget.account?.accountNumber ?? '');
    _bankNameController =
        TextEditingController(text: widget.account?.bankName ?? '');
    _selectedType = widget.account?.type ?? PaymentType.bank;
    _isDefault = widget.account?.isDefault ??
        ref.read(paymentAccountsProvider).accounts.isEmpty;
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
        child: SingleChildScrollView(
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
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '账户名称',
                    hintText: '例如：公司主账户',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入账户名称';
                    }
                    return null;
                  },
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
                  decoration: InputDecoration(labelText: _accountNumberLabel),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('设为默认账户'),
                  subtitle: const Text('订单和个人资料将优先使用这个收款账户。'),
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() => _isDefault = value);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: Text(_isSaving ? '保存中...' : '保存'),
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

  String get _accountNumberLabel {
    switch (_selectedType) {
      case PaymentType.bank:
        return '银行卡号';
      case PaymentType.alipay:
        return '支付宝账号';
      case PaymentType.wechat:
        return '微信号或收款码链接';
      case PaymentType.cash:
        return '备注';
      case PaymentType.other:
        return '账号或说明';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final notifier = ref.read(paymentAccountsProvider.notifier);
    final accountNumber = _accountNumberController.text.trim();
    final bankName = _bankNameController.text.trim();
    late final bool success;

    if (widget.account == null) {
      final account = PaymentAccount.create(
        name: _nameController.text.trim(),
        type: _selectedType,
        accountNumber: accountNumber.isNotEmpty ? accountNumber : null,
        bankName: _selectedType == PaymentType.bank && bankName.isNotEmpty
            ? bankName
            : null,
        isDefault: _isDefault,
      );
      success = await notifier.addAccount(account);
    } else {
      final account = widget.account!.copyWith(
        name: _nameController.text.trim(),
        type: _selectedType,
        accountNumber: accountNumber.isNotEmpty ? accountNumber : null,
        bankName: _selectedType == PaymentType.bank && bankName.isNotEmpty
            ? bankName
            : null,
        isDefault: _isDefault,
      );
      success = await notifier.updateAccount(account);
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      return;
    }

    _showErrorSnackBar(
      context,
      ref.read(paymentAccountsProvider).errorMessage ?? '保存支付账户失败',
    );
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

void _showErrorSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}
