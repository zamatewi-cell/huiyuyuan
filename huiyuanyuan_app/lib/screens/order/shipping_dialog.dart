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
    '顺丰速运',   // SF Express
    '中通快递',   // ZTO
    '圆通速递',   // YTO
    '韵达快递',   // Yunda
    '申通快递',   // STO
    '邮政快递',   // EMS
    '京东物流',   // JD Logistics
    '极兔快递',   // J&T
    '德邦快递',   // Deppon
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_isFaceToFace) {
      Navigator.of(context).pop(ShippingResult(
        carrier: '面对面交付', // Face-to-face
        trackingNumber: 'F2F-${widget.orderId.substring(0, 8)}',
        isFaceToFace: true,
      ));
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCarrier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择快递公司')), // Select carrier
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
                            '确认发货', // Confirm Shipping
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
                      '面对面交付', // Face-to-face
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '无需快递，直接交付给买家', // No courier needed
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
                    '快递公司', // Carrier
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
                    '快递单号', // Tracking number
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
                      hintText: '请输入快递单号', // Enter tracking number
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
                        v == null || v.trim().isEmpty ? '请输入快递单号' : null,
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
                          '取消', // Cancel
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
                          '确认发货', // Confirm
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
