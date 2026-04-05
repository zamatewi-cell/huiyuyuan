import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../l10n/l10n_provider.dart';
import '../models/payment_account.dart';
import '../providers/payment_provider.dart';
import '../services/api_service.dart';
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
        title: Text(ref.tr('payment_management_title')),
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
        child: _buildContent(context, ref, paymentState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, null),
        icon: const Icon(Icons.add),
        label: Text(ref.tr('payment_add_account')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PaymentAccountsState state,
  ) {
    if (state.state == PaymentLoadingState.loading && state.accounts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.state == PaymentLoadingState.error && state.accounts.isEmpty) {
      return _buildErrorState(
        context,
        ref,
        state.errorMessage ?? 'payment_operation_retry'.tr,
      );
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
              'payment_empty_title'.tr,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'payment_empty_subtitle'.tr,
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
              label: Text('payment_add_account'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
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
              ref.tr('error'),
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
            FilledButton.icon(
              onPressed: () {
                ref.read(paymentAccountsProvider.notifier).loadAccounts();
              },
              icon: const Icon(Icons.refresh),
              label: Text(ref.tr('retry')),
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
                                ref.tr('payment_default_badge'),
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
                        account.typeName.tr,
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
                      if (account.qrCodeUrl != null &&
                          account.qrCodeUrl!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _resolveImageUrl(account.qrCodeUrl!),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 88,
                              height: 88,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'payment_qr_preview'.tr,
                                style: theme.textTheme.labelSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
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
                            'payment_operation_retry'.tr,
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
                              'payment_set_default_failed'.tr,
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text('payment_set_default'.tr),
                  ),
                TextButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) =>
                          _PaymentAccountDialog(account: account),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(ref.tr('edit')),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref, account),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(ref.tr('delete')),
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
        return Icons.account_balance_outlined;
      case PaymentType.alipay:
        return Icons.account_balance_wallet_outlined;
      case PaymentType.wechat:
        return Icons.qr_code_2_outlined;
      case PaymentType.cash:
        return Icons.payments_outlined;
      case PaymentType.other:
        return Icons.credit_card_outlined;
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PaymentAccount account,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(ref.tr('delete')),
          content: Text(
            ref.tr(
              'payment_delete_confirm',
              params: {'accountName': account.name},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(ref.tr('cancel')),
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
                  ref.read(paymentAccountsProvider).errorMessage ??
                      'payment_operation_retry'.tr,
                );
              },
              child: Text(ref.tr('delete')),
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
  final _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _qrCodeUrlController;
  late PaymentType _selectedType;
  late bool _isDefault;
  bool _isSaving = false;
  bool _isUploadingQr = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _accountNumberController =
        TextEditingController(text: widget.account?.accountNumber ?? '');
    _bankNameController =
        TextEditingController(text: widget.account?.bankName ?? '');
    _qrCodeUrlController =
        TextEditingController(text: widget.account?.qrCodeUrl ?? '');
    _selectedType = widget.account?.type ?? PaymentType.bank;
    _isDefault = widget.account?.isDefault ??
        ref.read(paymentAccountsProvider).accounts.isEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _qrCodeUrlController.dispose();
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
                  widget.account == null
                      ? 'payment_add_account'.tr
                      : 'payment_edit_account'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<PaymentType>(
                  value: _selectedType,
                  decoration:
                      InputDecoration(labelText: 'payment_account_type'.tr),
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
                  decoration: InputDecoration(
                    labelText: 'payment_account_name'.tr,
                    hintText: 'payment_account_name_example'.tr,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'payment_enter_account_name'.tr;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedType == PaymentType.bank) ...[
                  TextFormField(
                    controller: _bankNameController,
                    decoration:
                        InputDecoration(labelText: 'payment_bank_name'.tr),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(labelText: _accountNumberLabel),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _qrCodeUrlController,
                  decoration: InputDecoration(
                    labelText: 'payment_qr_code'.tr,
                    hintText: 'payment_qr_code_hint'.tr,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (_qrCodeUrlController.text.trim().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _resolveImageUrl(_qrCodeUrlController.text.trim()),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('payment_qr_preview'.tr),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isUploadingQr ? null : _uploadQrCode,
                      icon: _isUploadingQr
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_outlined),
                      label: Text(
                        _isUploadingQr
                            ? 'payment_qr_uploading'.tr
                            : 'payment_upload_qr'.tr,
                      ),
                    ),
                    if (_qrCodeUrlController.text.trim().isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _qrCodeUrlController.clear());
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text('delete'.tr),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('payment_set_default'.tr),
                  subtitle: Text('payment_default_account_hint'.tr),
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
                      child: Text(ref.tr('cancel')),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(ref.tr('save')),
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
        return 'payment_bank_card_number'.tr;
      case PaymentType.alipay:
        return 'payment_alipay_account'.tr;
      case PaymentType.wechat:
        return 'payment_wechat_account'.tr;
      case PaymentType.cash:
        return 'payment_note'.tr;
      case PaymentType.other:
        return 'payment_account_or_description'.tr;
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
    final qrCodeUrl = _qrCodeUrlController.text.trim();
    late final bool success;

    if (widget.account == null) {
      final account = PaymentAccount.create(
        name: _nameController.text.trim(),
        type: _selectedType,
        accountNumber: accountNumber.isNotEmpty ? accountNumber : null,
        bankName: _selectedType == PaymentType.bank && bankName.isNotEmpty
            ? bankName
            : null,
        qrCodeUrl: qrCodeUrl.isNotEmpty ? qrCodeUrl : null,
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
        qrCodeUrl: qrCodeUrl.isNotEmpty ? qrCodeUrl : null,
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
      ref.read(paymentAccountsProvider).errorMessage ??
          'payment_operation_retry'.tr,
    );
  }

  String _getTypeName(PaymentType type) {
    switch (type) {
      case PaymentType.bank:
        return 'payment_type_bank'.tr;
      case PaymentType.alipay:
        return 'payment_type_alipay'.tr;
      case PaymentType.wechat:
        return 'payment_type_wechat'.tr;
      case PaymentType.cash:
        return 'payment_type_cash'.tr;
      case PaymentType.other:
        return 'payment_type_other'.tr;
    }
  }

  Future<void> _uploadQrCode() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) {
        return;
      }

      setState(() => _isUploadingQr = true);
      final bytes = await file.readAsBytes();
      final result = await ApiService().uploadBytes<Map<String, dynamic>>(
        ApiConfig.uploadImage,
        bytes: bytes,
        fileName: file.name,
        extraData: const {'folder': 'payment_qrcodes'},
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.data != null) {
        setState(() {
          _qrCodeUrlController.text = result.data!['url']?.toString() ?? '';
        });
        return;
      }

      _showErrorSnackBar(
        context,
        result.message ?? 'payment_qr_upload_failed'.tr,
      );
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar(context, 'payment_qr_upload_failed'.tr);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingQr = false);
      }
    }
  }
}

void _showErrorSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _resolveImageUrl(String rawUrl) {
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  if (rawUrl.startsWith('/')) {
    return '${ApiConfig.apiUrl}$rawUrl';
  }
  return rawUrl;
}
