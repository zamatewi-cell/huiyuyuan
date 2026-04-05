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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF8F9FA);
    final carriers = _carrierKeys.map(ref.tr).toList();

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
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
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: JewelryColors.primaryGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: JewelryColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ref.tr('shipping_confirm_title'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
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
                SizedBox(height: 20),

                // Face-to-face toggle
                Container(
                  decoration: BoxDecoration(
                    color: _isFaceToFace
                        ? JewelryColors.primaryGreen.withAlpha(15)
                        : cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isFaceToFace
                          ? JewelryColors.primaryGreen.withAlpha(100)
                          : Colors.transparent,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: _isFaceToFace,
                    onChanged: (v) =>
                        setState(() => _isFaceToFace = v ?? false),
                    title: Text(
                      ref.tr('shipping_face_to_face'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      ref.tr('shipping_face_to_face_hint'),
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    activeColor: JewelryColors.primaryGreen,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                  ),
                ),

                // Carrier & tracking fields (hidden when face-to-face)
                if (!_isFaceToFace) ...[
                  SizedBox(height: 16),
                  // Carrier selection
                  Text(
                    ref.tr('shipping_carrier_label'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: carriers.map((carrier) {
                      final isSelected = _selectedCarrier == carrier;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCarrier = carrier),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? JewelryColors.primaryGreen.withAlpha(25)
                                : cardBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? JewelryColors.primaryGreen
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            carrier,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? JewelryColors.primaryGreen
                                  : textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  // Tracking number
                  Text(
                    ref.tr('shipping_tracking_number_label'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _trackingController,
                    decoration: InputDecoration(
                      hintText: ref.tr('shipping_tracking_number_hint'),
                      hintStyle: TextStyle(color: textSecondary.withAlpha(150)),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? ref.tr('shipping_tracking_number_hint')
                        : null,
                  ),
                ],
                SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: textSecondary.withAlpha(100)),
                        ),
                        child: Text(
                          ref.tr('cancel'), // Cancel
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JewelryColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          ref.tr('shipping_confirm_title'),
                          style: TextStyle(fontWeight: FontWeight.w600),
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
