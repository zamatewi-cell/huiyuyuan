/// 支付凭证上传组件
///
/// 允许用户从相册或相机拍摄上传支付凭证图片。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/string_extension.dart';
import '../../themes/colors.dart';
import '../common/glassmorphic_card.dart';

class PaymentVoucherUploader extends ConsumerStatefulWidget {
  final String paymentId;
  final String? currentVoucherUrl;
  final ValueChanged<String?> onUploaded;

  const PaymentVoucherUploader({
    super.key,
    required this.paymentId,
    this.currentVoucherUrl,
    required this.onUploaded,
  });

  @override
  ConsumerState<PaymentVoucherUploader> createState() =>
      _PaymentVoucherUploaderState();
}

class _PaymentVoucherUploaderState
    extends ConsumerState<PaymentVoucherUploader> {
  bool _uploading = false;
  String? _localPreview;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _localPreview = image.path;
      _uploading = true;
    });

    try {
      // TODO: 实现真实的上传到后端逻辑（当前使用本地预览模拟）
      await Future.delayed(const Duration(seconds: 1));

      // 模拟上传成功，使用本地路径作为预览
      if (mounted) {
        widget.onUploaded(_localPreview);
        setState(() {
          _uploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment_voucher_uploaded'.tr),
            backgroundColor: JewelryColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('payment_voucher_upload_failed'.trArgs({'error': e.toString()})),
            backgroundColor: JewelryColors.error,
          ),
        );
      }
    }
  }

  void _showPickSourceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: JewelryColors.darkSurface,
        title: Text('payment_voucher_pick_source'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: JewelryColors.primary),
              title: Text('payment_voucher_gallery'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: JewelryColors.primary),
              title: Text('payment_voucher_camera'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common_cancel'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVoucher = widget.currentVoucherUrl != null && widget.currentVoucherUrl!.isNotEmpty;

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: JewelryColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'payment_voucher_title'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: JewelryColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasVoucher || _localPreview != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _localPreview != null
                  ? Image.file(
                      File(_localPreview!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      widget.currentVoucherUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: JewelryColors.darkBackground,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 48, color: JewelryColors.textSecondary),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'payment_voucher_uploaded_hint'.tr,
              style: const TextStyle(fontSize: 12, color: JewelryColors.textSecondary),
            ),
          ] else ...[
            GestureDetector(
              onTap: _uploading ? null : _showPickSourceDialog,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: JewelryColors.darkBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: JewelryColors.primary.withOpacity(0.3),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: JewelryColors.primary.withOpacity(0.7),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'payment_voucher_tap_to_upload'.tr,
                            style: TextStyle(
                              color: JewelryColors.primary.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
