import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ResilientNetworkImage extends StatefulWidget {
  const ResilientNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<ResilientNetworkImage> createState() => _ResilientNetworkImageState();
}

class _ResilientNetworkImageState extends State<ResilientNetworkImage> {
  late Future<ApiResult<Uint8List>> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  @override
  void didUpdateWidget(covariant ResilientNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _loadImage();
    }
  }

  Future<ApiResult<Uint8List>> _loadImage() {
    return ApiService().downloadBytes(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ApiResult<Uint8List>>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ?? _buildLoadingPlaceholder();
        }

        final result = snapshot.data;
        final bytes = result?.data;
        if (result?.success == true && bytes != null && bytes.isNotEmpty) {
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        }

        return widget.errorWidget ?? _buildLoadingPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
