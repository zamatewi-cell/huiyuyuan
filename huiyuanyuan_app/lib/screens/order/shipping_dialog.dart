import 'package:flutter/material.dart';
import '../../themes/colors.dart';

/// Shipping dialog for merchants to input tracking info
class ShippingDialog extends StatefulWidget {
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
  State<ShippingDialog> createState() => _ShippingDialogState();
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

class _ShippingDialogState extends State<ShippingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _trackingController = TextEditingController();
  String _selectedCarrier = '';
  bool _isFaceToFace = false;

  static const List<String> _carriers = [
    '\u987A\u4E30\u901F\u8FD0',   // SF Express
    '\u4E2D\u901A\u5FEB\u9012',   // ZTO
    '\u5706\u901A\u901F\u9012',   // YTO
    '\u97F5\u8FBE\u5FEB\u9012',   // Yunda
    '\u7533\u901A\u5FEB\u9012',   // STO
    '\u90AE\u653F\u5FEB\u9012',   // EMS
    '\u4EAC\u4E1C\u7269\u6D41',   // JD Logistics
    '\u6781\u5154\u5FEB\u9012',   // J&T
    '\u5FB7\u90A6\u5FEB\u9012',   // Deppon
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_isFaceToFace) {
      Navigator.of(context).pop(ShippingResult(
        carrier: '\u9762\u5BF9\u9762\u4EA4\u4ED8', // Face-to-face
        trackingNumber: 'F2F-${widget.orderId.substring(0, 8)}',
        isFaceToFace: true,
      ));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCarrier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u8BF7\u9009\u62E9\u5FEB\u9012\u516C\u53F8')), // Select carrier
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
    final textSecondary = isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6B7280);
    final cardBg = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF8F9FA);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                        color: JewelryColors.primaryGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: JewelryColors.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u786E\u8BA4\u53D1\u8D27', // Confirm Shipping
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.productName,
                            style: TextStyle(fontSize: 13, color: textSecondary),
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
                    onChanged: (v) => setState(() => _isFaceToFace = v ?? false),
                    title: Text(
                      '\u9762\u5BF9\u9762\u4EA4\u4ED8', // Face-to-face
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '\u65E0\u9700\u5FEB\u9012\uFF0C\u76F4\u63A5\u4EA4\u4ED8\u7ED9\u4E70\u5BB6', // No courier needed
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    activeColor: JewelryColors.primaryGreen,
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
                    '\u5FEB\u9012\u516C\u53F8', // Carrier
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _carriers.map((carrier) {
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
                  const SizedBox(height: 16),
                  // Tracking number
                  Text(
                    '\u5FEB\u9012\u5355\u53F7', // Tracking number
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _trackingController,
                    decoration: InputDecoration(
                      hintText: '\u8BF7\u8F93\u5165\u5FEB\u9012\u5355\u53F7', // Enter tracking number
                      hintStyle: TextStyle(color: textSecondary.withAlpha(150)),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '\u8BF7\u8F93\u5165\u5FEB\u9012\u5355\u53F7' : null,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: textSecondary.withAlpha(100)),
                        ),
                        child: Text(
                          '\u53D6\u6D88', // Cancel
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: JewelryColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '\u786E\u8BA4\u53D1\u8D27', // Confirm
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
