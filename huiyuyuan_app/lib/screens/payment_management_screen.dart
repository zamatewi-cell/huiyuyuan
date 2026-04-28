import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../l10n/l10n_provider.dart';
import '../models/payment_account.dart';
import '../providers/payment_provider.dart';
import '../services/api_service.dart';
import '../themes/colors.dart';
import '../widgets/common/glassmorphic_card.dart';
import '../widgets/common/resilient_network_image.dart';

class _PaymentManagementBackdrop extends StatelessWidget {
  const _PaymentManagementBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _PaymentManagementGlowOrb(
              size: 330,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -150,
            top: 330,
            child: _PaymentManagementGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _PaymentManagementTracePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentManagementGlowOrb extends StatelessWidget {
  const _PaymentManagementGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 96, spreadRadius: 30),
        ],
      ),
    );
  }
}

class _PaymentManagementTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.1 + i * 0.13);
      final path = Path()..moveTo(-24, y);
      path.cubicTo(
        size.width * 0.2,
        y - 30,
        size.width * 0.72,
        y + 34,
        size.width + 24,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaymentManagementTracePainter oldDelegate) =>
      false;
}

class PaymentManagementScreen extends ConsumerWidget {
  const PaymentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentState = ref.watch(paymentAccountsProvider);
    final isLoading = paymentState.state == PaymentLoadingState.loading;

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.14),
            ),
          ),
          child: Text(
            ref.tr('payment_management_title'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        foregroundColor: JewelryColors.jadeMist,
        elevation: 0,
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: JewelryColors.emeraldGlow,
                ),
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
      body: Stack(
        children: [
          const Positioned.fill(child: _PaymentManagementBackdrop()),
          _buildContent(context, ref, paymentState),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(context, null),
        icon: const Icon(Icons.add),
        label: Text(ref.tr('payment_add_account')),
        backgroundColor: JewelryColors.emeraldLuster,
        foregroundColor: JewelryColors.jadeBlack,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    PaymentAccountsState state,
  ) {
    if (state.state == PaymentLoadingState.loading && state.accounts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: JewelryColors.emeraldGlow),
      );
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        child: GlassmorphicCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          borderRadius: 26,
          blur: 16,
          opacity: 0.18,
          borderColor: JewelryColors.champagneGold.withOpacity(0.14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: JewelryColors.emeraldGlow.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JewelryColors.emeraldGlow.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: JewelryColors.emeraldGlow,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'payment_empty_title'.tr,
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'payment_empty_subtitle'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: JewelryColors.jadeMist.withOpacity(0.62),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _showEditDialog(context, null),
                icon: const Icon(Icons.add),
                label: Text('payment_add_account'.tr),
                style: FilledButton.styleFrom(
                  backgroundColor: JewelryColors.emeraldLuster,
                  foregroundColor: JewelryColors.jadeBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
        child: GlassmorphicCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          borderRadius: 26,
          blur: 16,
          opacity: 0.18,
          borderColor: JewelryColors.error.withOpacity(0.22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: JewelryColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JewelryColors.error.withOpacity(0.18),
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: JewelryColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ref.tr('error'),
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: JewelryColors.jadeMist.withOpacity(0.62),
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
                style: FilledButton.styleFrom(
                  backgroundColor: JewelryColors.emeraldLuster,
                  foregroundColor: JewelryColors.jadeBlack,
                ),
              ),
            ],
          ),
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
    return GlassmorphicCard(
      opacity: 0.18,
      blur: 16,
      borderRadius: 24,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
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
                    color: JewelryColors.emeraldGlow.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: JewelryColors.emeraldGlow.withOpacity(0.16),
                    ),
                  ),
                  child: Icon(
                    _getIconForType(account.type),
                    color: JewelryColors.emeraldGlow,
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
                            style: const TextStyle(
                              color: JewelryColors.jadeMist,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
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
                                    JewelryColors.emeraldGlow.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: JewelryColors.emeraldGlow
                                      .withOpacity(0.18),
                                ),
                              ),
                              child: Text(
                                ref.tr('payment_default_badge'),
                                style: const TextStyle(
                                  color: JewelryColors.emeraldGlow,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.typeName.tr,
                        style: TextStyle(
                          color: JewelryColors.jadeMist.withOpacity(0.62),
                          fontSize: 12,
                        ),
                      ),
                      if (account.accountNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          account.accountNumber!,
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.78),
                            fontFamily: 'Monospace',
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (account.bankName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          account.bankName!,
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.48),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (account.qrCodeUrl != null &&
                          account.qrCodeUrl!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ResilientNetworkImage(
                            imageUrl: _resolveImageUrl(account.qrCodeUrl!),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              width: 88,
                              height: 88,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: JewelryColors.deepJade.withOpacity(0.58),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: JewelryColors.champagneGold
                                      .withOpacity(0.12),
                                ),
                              ),
                              child: Text(
                                'payment_qr_preview'.tr,
                                style: TextStyle(
                                  color:
                                      JewelryColors.jadeMist.withOpacity(0.58),
                                  fontSize: 11,
                                ),
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
                  activeColor: JewelryColors.emeraldGlow,
                  activeTrackColor: JewelryColors.emeraldGlow.withOpacity(0.28),
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
            Divider(
              height: 24,
              color: JewelryColors.champagneGold.withOpacity(0.12),
            ),
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
                    style: TextButton.styleFrom(
                      foregroundColor: JewelryColors.emeraldGlow,
                    ),
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
                  style: TextButton.styleFrom(
                    foregroundColor: JewelryColors.jadeMist.withOpacity(0.72),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ref, account),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(ref.tr('delete')),
                  style: TextButton.styleFrom(
                    foregroundColor: JewelryColors.error,
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
          backgroundColor: JewelryColors.deepJade,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            ref.tr('delete'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            ref.tr(
              'payment_delete_confirm',
              params: {'accountName': account.name},
            ),
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.66),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                ref.tr('cancel'),
                style:
                    TextStyle(color: JewelryColors.jadeMist.withOpacity(0.58)),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: JewelryColors.error),
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
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JewelryColors.deepJade.withOpacity(0.98),
                JewelryColors.jadeSurface.withOpacity(0.94),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.16),
            ),
            boxShadow: JewelryShadows.liquidGlass,
          ),
          child: SingleChildScrollView(
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
                    style: const TextStyle(
                      color: JewelryColors.jadeMist,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<PaymentType>(
                    value: _selectedType,
                    dropdownColor: JewelryColors.deepJade,
                    iconEnabledColor: JewelryColors.champagneGold,
                    iconDisabledColor: JewelryColors.jadeMist.withOpacity(0.3),
                    decoration: _inputDecoration('payment_account_type'.tr),
                    style: const TextStyle(color: JewelryColors.jadeMist),
                    items: PaymentType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          _getTypeName(type),
                          style: const TextStyle(
                            color: JewelryColors.jadeMist,
                          ),
                        ),
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
                    cursorColor: JewelryColors.emeraldGlow,
                    style: const TextStyle(color: JewelryColors.jadeMist),
                    decoration: _inputDecoration(
                      'payment_account_name'.tr,
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
                      cursorColor: JewelryColors.emeraldGlow,
                      style: const TextStyle(color: JewelryColors.jadeMist),
                      decoration: _inputDecoration('payment_bank_name'.tr),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _accountNumberController,
                    cursorColor: JewelryColors.emeraldGlow,
                    style: const TextStyle(color: JewelryColors.jadeMist),
                    decoration: _inputDecoration(_accountNumberLabel),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qrCodeUrlController,
                    cursorColor: JewelryColors.emeraldGlow,
                    style: const TextStyle(color: JewelryColors.jadeMist),
                    decoration: _inputDecoration(
                      'payment_qr_code'.tr,
                      hintText: 'payment_qr_code_hint'.tr,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  if (_qrCodeUrlController.text.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ResilientNetworkImage(
                        imageUrl:
                            _resolveImageUrl(_qrCodeUrlController.text.trim()),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          height: 120,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: JewelryColors.jadeBlack.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  JewelryColors.champagneGold.withOpacity(0.14),
                            ),
                          ),
                          child: Text(
                            'payment_qr_preview'.tr,
                            style: TextStyle(
                              color: JewelryColors.jadeMist.withOpacity(0.58),
                            ),
                          ),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: JewelryColors.emeraldGlow,
                                ),
                              )
                            : const Icon(Icons.upload_outlined),
                        label: Text(
                          _isUploadingQr
                              ? 'payment_qr_uploading'.tr
                              : 'payment_upload_qr'.tr,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: JewelryColors.jadeMist,
                          backgroundColor:
                              JewelryColors.jadeBlack.withOpacity(0.18),
                          side: BorderSide(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.26),
                          ),
                        ),
                      ),
                      if (_qrCodeUrlController.text.trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _qrCodeUrlController.clear());
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: Text('delete'.tr),
                          style: TextButton.styleFrom(
                            foregroundColor: JewelryColors.error,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'payment_set_default'.tr,
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      'payment_default_account_hint'.tr,
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.54),
                      ),
                    ),
                    value: _isDefault,
                    activeColor: JewelryColors.emeraldGlow,
                    activeTrackColor:
                        JewelryColors.emeraldGlow.withOpacity(0.3),
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
                        child: Text(
                          ref.tr('cancel'),
                          style: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.58),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JewelryColors.emeraldLuster,
                          foregroundColor: JewelryColors.jadeBlack,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: JewelryColors.jadeBlack,
                                ),
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
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText, {String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.62)),
      hintStyle: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.36)),
      filled: true,
      fillColor: JewelryColors.jadeBlack.withOpacity(0.28),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: JewelryColors.champagneGold.withOpacity(0.14),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: JewelryColors.emeraldGlow.withOpacity(0.5),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JewelryColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: JewelryColors.error),
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
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: JewelryColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
