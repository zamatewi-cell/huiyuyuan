/// 汇玉源 - 图片选择上传组件
///
/// 功能:
/// - 相册选择/相机拍摄
/// - 图片预览
/// - 多图上传
/// - 上传进度显示
/// - AI图片分析
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/oss_service.dart';
import '../../services/gemini_image_service.dart';
import '../../themes/colors.dart';

/// 图片项模型
class ImageItem {
  final String id;
  final String localPath;
  final String? remoteUrl;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  ImageItem({
    required this.id,
    required this.localPath,
    this.remoteUrl,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.error,
  });

  ImageItem copyWith({
    String? remoteUrl,
    bool? isUploading,
    double? uploadProgress,
    String? error,
  }) {
    return ImageItem(
      id: id,
      localPath: localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
    );
  }

  bool get isUploaded => remoteUrl != null;
  bool get hasError => error != null;
}

/// 图片选择上传组件
class ImagePickerWidget extends StatefulWidget {
  /// 已选择的图片URL列表
  final List<String> initialImages;

  /// 最大图片数量
  final int maxCount;

  /// 图片变化回调
  final ValueChanged<List<String>>? onImagesChanged;

  /// 是否启用AI分析
  final bool enableAIAnalysis;

  /// AI分析结果回调
  final ValueChanged<ImageAnalysisResult>? onAIAnalysis;

  /// 上传文件夹
  final String uploadFolder;

  /// 是否只读模式
  final bool readOnly;

  /// 图片尺寸
  final double imageSize;

  const ImagePickerWidget({
    super.key,
    this.initialImages = const [],
    this.maxCount = 9,
    this.onImagesChanged,
    this.enableAIAnalysis = false,
    this.onAIAnalysis,
    this.uploadFolder = 'products',
    this.readOnly = false,
    this.imageSize = 100,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final OssService _ossService = OssService();
  final GeminiImageService _geminiService = GeminiImageService();

  final List<ImageItem> _images = [];
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeImages();
  }

  void _initializeImages() {
    for (final url in widget.initialImages) {
      _images.add(ImageItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        localPath: '',
        remoteUrl: url,
      ));
    }
  }

  void _notifyChange() {
    final urls = _images
        .where((img) => img.isUploaded)
        .map((img) => img.remoteUrl!)
        .toList();
    widget.onImagesChanged?.call(urls);
  }

  /// 显示选择方式底部弹窗
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildPickerOption(
                icon: Icons.photo_library_outlined,
                title: '从相册选择',
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              _buildPickerOption(
                icon: Icons.camera_alt_outlined,
                title: '拍摄照片',
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              if (widget.enableAIAnalysis) ...[
                const Divider(),
                _buildPickerOption(
                  icon: Icons.auto_awesome,
                  title: 'AI智能识别',
                  subtitle: '上传图片自动识别商品信息',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndAnalyze();
                  },
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: JewelryColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: JewelryColors.primary),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// 从相册选择
  Future<void> _pickFromGallery() async {
    // TODO: 实际实现需要添加 image_picker 依赖
    // 这里使用模拟实现
    _showNotImplementedMessage('相册选择');

    /*
    final picker = ImagePicker();
    final remaining = widget.maxCount - _images.length;
    
    if (remaining <= 0) {
      _showMaxCountMessage();
      return;
    }
    
    final images = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (images.isNotEmpty) {
      final toAdd = images.take(remaining).toList();
      for (final image in toAdd) {
        await _addImage(image.path);
      }
    }
    */
  }

  /// 拍摄照片
  Future<void> _pickFromCamera() async {
    // TODO: 实际实现需要添加 image_picker 依赖
    _showNotImplementedMessage('相机拍摄');

    /*
    final picker = ImagePicker();
    
    if (_images.length >= widget.maxCount) {
      _showMaxCountMessage();
      return;
    }
    
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (image != null) {
      await _addImage(image.path);
    }
    */
  }

  /// 选择并分析
  Future<void> _pickAndAnalyze() async {
    // TODO: 实际实现
    _showNotImplementedMessage('AI智能识别');

    /*
    final picker = ImagePicker();
    
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    
    if (image != null) {
      await _addImage(image.path);
      await _analyzeImage(image.path);
    }
    */
  }

  /// 添加图片
  // ignore: unused_element
  Future<void> _addImage(String localPath) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = ImageItem(id: id, localPath: localPath, isUploading: true);

    setState(() {
      _images.add(item);
    });

    // 上传图片
    await _uploadImage(id);
  }

  /// 上传图片
  Future<void> _uploadImage(String id) async {
    final index = _images.indexWhere((img) => img.id == id);
    if (index < 0) return;

    final item = _images[index];

    final result = await _ossService.uploadImage(
      item.localPath,
      folder: widget.uploadFolder,
      onProgress: (sent, total) {
        if (mounted) {
          setState(() {
            _images[index] = item.copyWith(
              uploadProgress: sent / total,
            );
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        if (result.success) {
          _images[index] = item.copyWith(
            remoteUrl: result.url,
            isUploading: false,
            uploadProgress: 1.0,
          );
        } else {
          _images[index] = item.copyWith(
            isUploading: false,
            error: result.message,
          );
        }
      });
      _notifyChange();
    }
  }

  /// 分析图片
  // ignore: unused_element
  Future<void> _analyzeImage(String localPath) async {
    setState(() {
      _isAnalyzing = true;
    });

    final result = await _geminiService.analyzeProductImage(localPath);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });

      if (result.success) {
        widget.onAIAnalysis?.call(result);
        _showAnalysisResult(result);
      } else {
        _showError(result.message ?? '分析失败');
      }
    }
  }

  /// 显示分析结果
  void _showAnalysisResult(ImageAnalysisResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: JewelryColors.gold),
            SizedBox(width: 8),
            Text('AI分析结果'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.material != null) ...[
                _buildResultItem('材质', result.material!),
                const SizedBox(height: 8),
              ],
              if (result.category != null) ...[
                _buildResultItem('分类', result.category!),
                const SizedBox(height: 8),
              ],
              if (result.description != null) ...[
                _buildResultItem('描述', result.description!),
                const SizedBox(height: 8),
              ],
              if (result.tags != null && result.tags!.isNotEmpty) ...[
                const Text('标签:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: result.tags!
                      .map((tag) => Chip(
                            label:
                                Text(tag, style: const TextStyle(fontSize: 12)),
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value),
      ],
    );
  }

  /// 删除图片
  void _removeImage(String id) {
    setState(() {
      _images.removeWhere((img) => img.id == id);
    });
    _notifyChange();
  }

  /// 预览图片
  void _previewImage(int index) {
    // TODO: 实现图片预览
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: _buildImageWidget(_images[index], size: 300),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showMaxCountMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('最多选择${widget.maxCount}张图片')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showNotImplementedMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature功能需要添加 image_picker 依赖'),
        action: SnackBarAction(
          label: '了解',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 图片网格
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 已选图片
            ..._images
                .asMap()
                .entries
                .map((entry) => _buildImageItem(entry.key, entry.value)),

            // 添加按钮
            if (!widget.readOnly && _images.length < widget.maxCount)
              _buildAddButton(),
          ],
        ),

        // 提示文字
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          Text(
            '${_images.length}/${widget.maxCount} 张',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],

        // AI分析中提示
        if (_isAnalyzing) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('AI正在分析图片...', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImageItem(int index, ImageItem item) {
    return GestureDetector(
      onTap: () => _previewImage(index),
      child: Stack(
        children: [
          // 图片容器
          Container(
            width: widget.imageSize,
            height: widget.imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageWidget(item),
          ),

          // 上传进度
          if (item.isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: item.uploadProgress,
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
              ),
            ),

          // 错误标识
          if (item.hasError)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child:
                      Icon(Icons.error_outline, color: Colors.white, size: 32),
                ),
              ),
            ),

          // 删除按钮
          if (!widget.readOnly)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(item.id),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(ImageItem item, {double? size}) {
    final imageSize = size ?? widget.imageSize;

    if (item.remoteUrl != null) {
      // 远程图片
      return Image.network(
        item.remoteUrl!,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(imageSize),
      );
    } else if (item.localPath.isNotEmpty) {
      // 本地图片 (Web 环境使用 network 加载 Object URL / blob url)
      return kIsWeb
          ? Image.network(
              item.localPath,
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(imageSize),
            )
          : Image.file(
              File(item.localPath),
              width: imageSize,
              height: imageSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(imageSize),
            );
    }

    return _buildPlaceholder(imageSize);
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Icon(Icons.image, color: Colors.grey[400], size: size * 0.4),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showPickerOptions,
      child: Container(
        width: widget.imageSize,
        height: widget.imageSize,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.grey[500],
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '添加图片',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
