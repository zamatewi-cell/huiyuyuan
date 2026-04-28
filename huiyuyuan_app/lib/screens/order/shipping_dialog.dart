import 'package:flutter/material.dart';
import '../../l10n/l10n_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../themes/colors.dart';

/// Shipping dialog for merchants to input tracking info
class ShippingDialog extends ConsumerStatefulWidget {
  final String orderId;
  final String productName;

  const ShippingDialog({
    super.key,
    required this.orderId,
    required this.productName,
  });

  /// Show shipping dialog and return result
  static Future<ShippingResult?> show(
    BuildContext context, {
    required String orderId,
    required String productName,
  }) {
    return showDialog<ShippingResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ShippingDialog(
        orderId: orderId,
        productName: productName,
      ),
    );
  }

  @override
  ConsumerState<ShippingDialog> createState() => _ShippingDialogState();
}

class ShippingResult {
  final String carrier;
  final String trackingNumber;
  final bool isFaceToFace;

  const ShippingResult({
    required this.carrier,
    required this.trackingNumber,
    this.isFaceToFace = false,
  });
}

class _ShippingDialogState extends ConsumerState<ShippingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _trackingController = TextEditingController();
  String _selectedCarrier = '';
  bool _isFaceToFace = false;

  static const List<String> _carrierKeys = [
    'shipping_carrier_sf',
    'shipping_carrier_zto',
    'shipping_carrier_yto',
    'shipping_carrier_yunda',
    'shipping_carrier_sto',
    'shipping_carrier_ems',
    'shipping_carrier_jd',
    'shipping_carrier_jnt',
    'shipping_carrier_deppon',
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_isFaceToFace) {
      Navigator.of(context).pop(ShippingResult(
        carrier: ref.tr('shipping_face_to_face'),
        trackingNumber: 'F2F-${widget.orderId.substring(0, 8)}',
        isFaceToFace: true,
      ));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCarrier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.tr('shipping_select_carrier'))),
      );
      return;
    }

    Navigator.of(context).pop(ShippingResult(
      carrier: _selectedCarrier,
      trackingNumber: _trackingController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = JewelryColors.jadeMist;
    final textSecondary = JewelryColors.jadeMist.withOpacity(0.62);
    final cardBg = JewelryColors.deepJade.withOpacity(0.5);
    final carriers = _carrierKeys.map(ref.tr).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              JewelryColors.deepJade.withOpacity(0.96),
              JewelryColors.jadeSurface.withOpacity(0.9),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: JewelryColors.emeraldLusterGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: JewelryColors.emeraldGlow.withOpacity(0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: JewelryColors.jadeBlack,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref.tr('shipping_confirm_title'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.productName,
                            style:
                                TextStyle(fontSize: 13, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Face-to-face toggle
                Container(
                  decoration: BoxDecoration(
                    color: _isFaceToFace
                        ? JewelryColors.emeraldGlow.withOpacity(0.12)
                        : cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isFaceToFace
                          ? JewelryColors.emeraldGlow.withOpacity(0.3)
                          : JewelryColors.champagneGold.withOpacity(0.1),
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _isFaceToFace,
                    onChanged: (v) =>
                        setState(() => _isFaceToFace = v ?? false),
                    title: Text(
                      ref.tr('shipping_face_to_face'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      ref.tr('shipping_face_to_face_hint'),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    activeColor: JewelryColors.emeraldGlow,
                    checkColor: JewelryColors.jadeBlack,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                  ),
                ),

                // Carrier & tracking fields (hidden when face-to-face)
                if (!_isFaceToFace) ...[
                  const SizedBox(height: 16),
                  // Carrier selection
                  Text(
                    ref.tr('shipping_carrier_label'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: carriers.map((carrier) {
                      final isSelected = _selectedCarrier == carrier;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCarrier = carrier),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? JewelryColors.emeraldGlow.withOpacity(0.12)
                                : cardBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? JewelryColors.emeraldGlow.withOpacity(0.36)
                                  : JewelryColors.champagneGold
                                      .withOpacity(0.08),
                            ),
                          ),
                          child: Text(
                            carrier,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? JewelryColors.emeraldGlow
                                  : textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Tracking number
                  Text(
                    ref.tr('shipping_tracking_number_label'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _trackingController,
                    style: const TextStyle(
                      color: JewelryColors.jadeMist,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: ref.tr('shipping_tracking_number_hint'),
                      hintStyle: TextStyle(color: textSecondary.withAlpha(150)),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: JewelryColors.champagneGold.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: JewelryColors.champagneGold.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: JewelryColors.emeraldGlow.withOpacity(0.5),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? ref.tr('shipping_tracking_number_hint')
                        : null,
                  ),
                ],
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          backgroundColor:
                              JewelryColors.deepJade.withOpacity(0.38),
                          side: BorderSide(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.26),
                          ),
                        ),
                        child: Text(
                          ref.tr('cancel'), // Cancel
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JewelryColors.emeraldLuster,
                          foregroundColor: JewelryColors.jadeBlack,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          elevation: 4,
                          shadowColor:
                              JewelryColors.emeraldGlow.withOpacity(0.24),
                        ),
                        child: Text(
                          ref.tr('shipping_confirm_title'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
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
}
