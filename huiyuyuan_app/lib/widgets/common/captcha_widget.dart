/// 图形验证码输入组件。
///
/// 用于登录、注册等需要人机验证的场景。
/// 点击图片可刷新验证码。
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import '../../l10n/string_extension.dart';
import '../../services/api_service.dart';

class CaptchaWidget extends StatefulWidget {
  final ValueChanged<String> onCaptchaChanged;
  final ValueChanged<String?> onSessionIdChanged;

  const CaptchaWidget({
    super.key,
    required this.onCaptchaChanged,
    required this.onSessionIdChanged,
  });

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  final _controller = TextEditingController();
  String? _sessionId;
  String? _imageData;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => widget.onCaptchaChanged(_controller.text.trim()));
    _refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _imageData = null;
    });

    try {
      // 生成 UUID 作为 session_id
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString() +
          DateTime.now().microsecondsSinceEpoch.toString();
      widget.onSessionIdChanged(_sessionId);

      final api = ApiService();
      final res = await api.get(
        '/api/auth/captcha',
        params: {'session_id': _sessionId},
      );

      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        setState(() {
          _imageData = data['image'] as String?;
        });
      }
    } catch (error) {
      debugPrint('[Captcha] load failed: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'login_captcha_hint'.tr,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            style: const TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _loading ? null : _refresh,
          child: Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : _imageData != null
                      ? _buildCaptchaImage()
                      : Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Text(
                              'login_captcha_load_fail'.tr,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptchaImage() {
    // 解析 base64 data URI
    final raw = _imageData!;
    final commaIdx = raw.indexOf(',');
    if (commaIdx == -1) return const SizedBox.shrink();

    final base64Str = raw.substring(commaIdx + 1);
    final bytes = base64Decode(base64Str);

    return Image.memory(
      bytes,
      fit: BoxFit.fill,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[800],
        child: Center(
          child: Text(
            'login_captcha_load_fail'.tr,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
      ),
    );
  }
}
