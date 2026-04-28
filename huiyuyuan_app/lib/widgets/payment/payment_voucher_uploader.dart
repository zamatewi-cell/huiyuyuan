/// 支付凭证上传组件
///
/// 允许用户从相册或相机拍摄上传支付凭证图片。
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/api_config.dart';
import '../../l10n/string_extension.dart';
import '../../themes/colors.dart';
import '../common/glassmorphic_card.dart';
import '../common/resilient_network_image.dart';

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
  Uint8List? _localPreviewBytes;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;
    final previewBytes = await image.readAsBytes();

    setState(() {
      _localPreview = image.path;
      _localPreviewBytes = previewBytes;
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
            backgroundColor: JewelryColors.emeraldShadow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'payment_voucher_upload_failed'.trArgs({'error': e.toString()}),
            ),
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
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'payment_voucher_pick_source'.tr,
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: JewelryColors.emeraldGlow,
              ),
              title: Text(
                'payment_voucher_gallery'.tr,
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: JewelryColors.emeraldGlow,
              ),
              title: Text(
                'payment_voucher_camera'.tr,
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            child: Text(
              'common_cancel'.tr,
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.58)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVoucher = widget.currentVoucherUrl != null &&
        widget.currentVoucherUrl!.isNotEmpty;

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 22,
      blur: 16,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: JewelryColors.emeraldLusterGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: JewelryColors.emeraldGlow.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: JewelryColors.jadeBlack,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'payment_voucher_title'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: JewelryColors.jadeMist,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasVoucher || _localPreview != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _localPreviewBytes != null
                  ? Image.memory(
                      _localPreviewBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : ResilientNetworkImage(
                      imageUrl: _resolveImageUrl(widget.currentVoucherUrl!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        height: 180,
                        color: JewelryColors.deepJade.withOpacity(0.58),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: JewelryColors.jadeMist.withOpacity(0.32),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'payment_voucher_uploaded_hint'.tr,
              style: TextStyle(
                fontSize: 12,
                color: JewelryColors.jadeMist.withOpacity(0.58),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: _uploading ? null : _showPickSourceDialog,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: JewelryColors.deepJade.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: JewelryColors.champagneGold.withOpacity(0.16),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _uploading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: JewelryColors.emeraldGlow,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: JewelryColors.emeraldGlow.withOpacity(0.72),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'payment_voucher_tap_to_upload'.tr,
                            style: TextStyle(
                              color: JewelryColors.jadeMist.withOpacity(0.68),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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

String _resolveImageUrl(String rawUrl) {
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  if (rawUrl.startsWith('/')) {
    return '${ApiConfig.apiUrl}$rawUrl';
  }
  return rawUrl;
}
