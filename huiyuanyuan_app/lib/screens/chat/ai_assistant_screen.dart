import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service.dart';
import '../../services/api_service.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../themes/colors.dart';
import '../../l10n/l10n_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/trade/product_detail_screen.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/animations/typing_indicator.dart';
import '../../widgets/animations/blinking_cursor.dart';
import '../../widgets/animations/fade_slide_transition.dart';

/// AI 助手页面
class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with TickerProviderStateMixin {
  final _aiService = AIService();
  final _productService = ProductService();
  final _storage = StorageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Map<String, ProductModel?> _recommendedProducts = {};
  final Set<String> _loadingRecommendedProducts = {};
  bool _isLoading = false;

  /// 当前正在流式输出的内容
  String _streamingContent = '';
  bool _isStreaming = false;

  /// 用户选择的待发送图片
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  /// 当前用户 ID（用于持久化隔离）
  String _userId = 'anonymous';

  /// 欢迎动画控制器
  late AnimationController _welcomeAnimController;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;

  @override
  void initState() {
    super.initState();

    // 欢迎动画
    _welcomeAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeAnimController, curve: Curves.easeOut),
    );
    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _welcomeAnimController, curve: Curves.easeOutCubic),
    );

    // 添加欢迎消息
    _messages.add(ChatMessage(
      id: 'welcome',
      content:
          '您好！我是汇玉源智能助手 🌟\n\n我可以帮您：\n• 推荐适合您的珠宝款式\n• 解答玉石鉴别相关问题\n• 分析珠宝市场行情趋势\n• 查询订单和物流信息\n\n请问有什么可以帮您？',
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // 启动欢迎动画
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _welcomeAnimController.forward();
    });

    // 加载历史对话
    _loadChatHistory();
  }

  /// 加载聊天历史
  Future<void> _loadChatHistory() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user != null) {
      _userId = user.id;
    }
    final history = await _storage.loadChatHistory(_userId);
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
    }
  }

  /// 保存聊天历史
  Future<void> _saveChatHistory() async {
    await _storage.saveChatHistory(_userId, _messages);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _welcomeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 动态更新欢迎语
    if (_messages.isNotEmpty && _messages[0].id == 'welcome') {
      final welcomeText = ref.tr('ai_welcome');
      if (_messages[0].content != welcomeText) {
        _messages[0] = ChatMessage(
          id: 'welcome',
          content: welcomeText,
          isUser: false,
          timestamp: _messages[0].timestamp,
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GlassmorphicCard(
          borderRadius: 20,
          blur: 10,
          opacity: 0.1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: JewelryColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy,
                    size: 16, color: JewelryColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                ref.tr('ai_title'),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: JewelryColors.textPrimary),
              ),
              const SizedBox(width: 6),
              // 在线状态指示点
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: JewelryColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: JewelryColors.success.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            onPressed: () {
              if (_messages.length <= 1) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(ref.tr('ai_clear')),
                  content: Text(ref.tr('ai_clear_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(ref.tr('cancel')),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearChat();
                      },
                      child: Text(ref.tr('confirm')),
                    ),
                  ],
                ),
              );
            },
            tooltip: ref.tr('ai_clear'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // 背景
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? JewelryColors.darkGradient
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[50]!,
                        Colors.purple[50]!,
                        Colors.white,
                      ],
                    ),
            ),
          ),

          // 装饰圆点
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JewelryColors.primary.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: JewelryColors.primary.withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 100), // AppBar高度占位

              // 快捷提问区域（使用预设问题）
              _buildQuickQuestions(isDark),

              // 消息列表
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount:
                      _messages.length + (_isLoading || _isStreaming ? 1 : 0),
                  itemBuilder: (context, index) {
                    // 正在加载或流式输出
                    if (index == _messages.length) {
                      if (_isStreaming) {
                        return _buildStreamingBubble();
                      }
                      return _buildTypingIndicator();
                    }
                    // 欢迎消息带动画
                    if (_messages[index].id == 'welcome') {
                      return FadeTransition(
                        opacity: _welcomeFadeAnimation,
                        child: SlideTransition(
                          position: _welcomeSlideAnimation,
                          child: _buildMessageBubble(_messages[index], isDark),
                        ),
                      );
                    }
                    return _buildMessageBubble(_messages[index], isDark);
                  },
                ),
              ),

              // 输入区域
              _buildInputArea(isDark),
            ],
          ),
        ],
      ),
    );
  }

  /// 快捷提问区域（使用 AI 服务中的预设问题）
  Widget _buildQuickQuestions(bool isDark) {
    if (_messages.length > 1) return const SizedBox.shrink();

    final questions = [
      {'label': ref.tr('ai_quick_1'), 'icon': Icons.verified},
      {'label': ref.tr('ai_quick_2'), 'icon': Icons.spa},
      {'label': ref.tr('ai_quick_3'), 'icon': Icons.shopping_bag},
      {'label': ref.tr('ai_quick_4'), 'icon': Icons.trending_up},
      {'label': ref.tr('ai_quick_5'), 'icon': Icons.help},
      {'label': ref.tr('ai_quick_6'), 'icon': Icons.watch},
      {'label': ref.tr('ai_quick_7'), 'icon': Icons.diamond},
      {'label': ref.tr('ai_quick_8'), 'icon': Icons.card_giftcard},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(q['icon'] as IconData,
                  size: 16, color: JewelryColors.primary),
              label: Text(q['label'] as String),
              backgroundColor:
                  (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              labelStyle: TextStyle(
                color: isDark ? Colors.white : JewelryColors.textPrimary,
                fontSize: 12,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _messageController.text = q['label'] as String;
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  /// 消息气泡
  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;

    // 从 AI 消息中提取商品 ID
    final productIds = _extractProductIds(message.content);
    // 清理文本中的 [PRODUCT:xxx] 标签
    final cleanContent =
        message.content.replaceAll(RegExp(r'\[PRODUCT:[^\]]+\]\s*'), '').trim();

    return FadeSlideTransition(
        key: ValueKey(message.id),
        beginOffset: const Offset(0, 0.1),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: JewelryColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: JewelryShadows.primaryGlow,
                  ),
                  child: const Icon(Icons.smart_toy,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // 消息图片（使用内存字节渲染，兼容 Web）
                    if (isUser && message.imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxWidth: 250, maxHeight: 250),
                            child: Image.memory(
                              message.imageBytes!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    // 消息内容
                    isUser
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: JewelryColors.primaryGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(4),
                              ),
                              boxShadow: JewelryShadows.primaryGlow,
                            ),
                            child: Text(
                              message.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          )
                        : GlassmorphicCard(
                            borderRadius: 20,
                            blur: 10,
                            opacity: isDark ? 0.15 : 0.6,
                            padding: const EdgeInsets.all(16),
                            child: MarkdownBody(
                              data: cleanContent,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black87,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                strong: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                                listBullet: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                                h1: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontSize: 20),
                                h2: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontSize: 18),
                                h3: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontSize: 16),
                                code: TextStyle(
                                  color: JewelryColors.primary,
                                  backgroundColor:
                                      JewelryColors.primary.withOpacity(0.1),
                                ),
                              ),
                            ),
                          ),

                    // 商品推荐卡片
                    if (!isUser && productIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: productIds
                              .map((id) => _buildProductCard(id, isDark))
                              .toList(),
                        ),
                      ),

                    // AI 消息底部操作按钮（复制）
                    if (!isUser && message.id != 'welcome')
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildActionChip(
                              icon: Icons.copy,
                              label: '复制',
                              onTap: () => _copyMessage(cleanContent),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ));
  }

  /// 从 AI 回复中提取 [PRODUCT:xxx] 标签
  List<String> _extractProductIds(String content) {
    final matches = RegExp(r'\[PRODUCT:([^\]]+)\]').allMatches(content);
    return matches.map((m) => m.group(1)!.trim()).toList();
  }

  void _ensureRecommendedProductLoaded(String productId) {
    if (_recommendedProducts.containsKey(productId) ||
        _loadingRecommendedProducts.contains(productId)) {
      return;
    }

    _loadingRecommendedProducts.add(productId);
    _productService.getProductDetail(productId).then((product) {
      if (!mounted) return;
      setState(() {
        _recommendedProducts[productId] = product;
        _loadingRecommendedProducts.remove(productId);
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _recommendedProducts[productId] = null;
        _loadingRecommendedProducts.remove(productId);
      });
    });
  }

  /// 构建商品推荐卡片
  Widget _buildProductCard(String productId, bool isDark) {
    _ensureRecommendedProductLoaded(productId);
    final product = _recommendedProducts[productId];
    final isLoading = _loadingRecommendedProducts.contains(productId);

    if (product == null) {
      if (!isLoading && _recommendedProducts.containsKey(productId)) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: JewelryColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: JewelryColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '正在加载推荐商品...',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _navigateToProduct(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: JewelryColors.primary.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: JewelryColors.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 商品图片
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                product.images.isNotEmpty ? product.images[0] : '',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: JewelryColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.diamond,
                      color: JewelryColors.primary, size: 40),
                ),
              ),
            ),
            // 商品信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.material} · ${product.category}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '¥${product.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product.originalPrice != null &&
                            product.originalPrice! > product.price)
                          Text(
                            '¥${product.originalPrice!.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: JewelryColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '查看详情 →',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 跳转到商品详情
  void _navigateToProduct(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  /// 复制操作按钮
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: JewelryColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: JewelryColors.primary.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: JewelryColors.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 复制消息到剪贴板
  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('已复制到剪贴板'),
            ],
          ),
          backgroundColor: JewelryColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 流式输出气泡
  Widget _buildStreamingBubble() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: JewelryColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: JewelryShadows.primaryGlow,
            ),
            child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: GlassmorphicCard(
              borderRadius: 20,
              blur: 10,
              opacity: isDark ? 0.15 : 0.6,
              padding: const EdgeInsets.all(16),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _streamingContent,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    // ✨ 闪烁光标：仅在流式输出时显示
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: BlinkingCursor(
                        height: 15,
                        baseColor: JewelryColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 打字指示器
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: JewelryColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: JewelryShadows.primaryGlow,
            ),
            child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          GlassmorphicCard(
            borderRadius: 20,
            blur: 10,
            opacity: 0.6,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '正在思考',
                  style: TextStyle(
                    fontSize: 12,
                    color: JewelryColors.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 8),
                // ✨ 全新跳动点动画
                const TypingIndicator(
                  dotColor: JewelryColors.primary,
                  dotSize: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 输入区域
  Widget _buildInputArea(bool isDark) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImage != null && _selectedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedImageBytes!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedImage = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: isDark ? Colors.white70 : Colors.black54,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: ref.tr('ai_input_hint'),
                          hintStyle: TextStyle(
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: (_isLoading || _isStreaming) ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: (_isLoading || _isStreaming)
                            ? LinearGradient(
                                colors: [Colors.grey[400]!, Colors.grey[500]!],
                              )
                            : JewelryColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isLoading || _isStreaming)
                                ? Colors.grey.withOpacity(0.2)
                                : JewelryColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ), // closes Row
            ],
          ), // closes Column
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // 立即读取字节，兼容 Web 环境（透过内存渲染）
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  /// 发送消息 — 使用流式输出
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final imageFile = _selectedImage;
    final imageBytes = _selectedImageBytes;
    if ((text.isEmpty && imageFile == null) || _isLoading || _isStreaming)
      return;

    // 获取发送前的纯历史对话（不包含当前即将发出的消息）
    final history = _messages
        .where((m) => m.id != 'welcome')
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    // 添加当前用户输入到UI（带内存字节，不存文件路径）
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text.isEmpty ? '请帮我看看这张图片' : text,
        isUser: true,
        timestamp: DateTime.now(),
        imageBytes: imageBytes,
      ));
      _isLoading = true;
      _streamingContent = '';
      _selectedImage = null;
      _selectedImageBytes = null;
    });

    _messageController.clear();
    _scrollToBottom();

    // 图片视觉前置处理 (通过后端代理，支持国内网络)
    String queryToAI = text.isEmpty ? '请帮我看看这张图片' : text;
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      // 先尝试后端代理 AI 分析
      try {
        final api = ApiService();
        final result = await api.uploadBytes(
          '/api/ai/analyze-image',
          bytes: bytes,
          fileName: imageFile.name,
        );
        if (result.success && result.data != null) {
          final data = result.data as Map<String, dynamic>;
          final analysis = data['analysis'] as Map<String, dynamic>? ?? {};
          final desc = analysis['description'] as String? ?? '';
          final mat = analysis['material'] as String? ?? '未知';
          final cat = analysis['category'] as String? ?? '未知';
          if (desc.isNotEmpty) {
            queryToAI = '【系统补充：用户上传了一张珠宝图片。目前AI系统已通过底层视觉模型提取了该图的特征，请参考这些信息作答】\n'
                '- 视觉分析详情：$desc\n'
                '- 材质判定：$mat\n'
                '- 品类判定：$cat\n\n'
                '【用户具体问题】：$queryToAI';
          } else {
            queryToAI = '【系统补充：用户上传了一张图片，但视觉分析未能获得有效结果。】\n\n【用户提问】：$queryToAI';
          }
        } else {
          queryToAI =
              '【系统补充：用户上传了一张图片，但视觉识别模块读取失败，未能获得有关该图的明确特征。】\n\n【用户提问】：$queryToAI';
        }
      } catch (e) {
        queryToAI = '【系统补充：用户上传了一张图片，但视觉识别服务暂不可用（$e）。】\n\n【用户提问】：$queryToAI';
      }
    }

    // 短暂显示"正在思考"指示器后开始流式输出
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
      _isStreaming = true;
    });

    // 尝试流式输出 (OpenRouter 作主模型)
    final currentLanguage = ref.read(appSettingsProvider).language.code;
    await _aiService.chatStream(
      userMessage: queryToAI,
      history:
          history.length > 10 ? history.sublist(history.length - 10) : history,
      language: currentLanguage,
      onToken: (token) {
        if (mounted) {
          setState(() {
            _streamingContent += token;
          });
          _scrollToBottom();
        }
      },
      onDone: (fullResponse) {
        if (mounted) {
          setState(() {
            _isStreaming = false;
            _messages.add(ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  fullResponse.isNotEmpty ? fullResponse : _streamingContent,
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _streamingContent = '';
          });
          _scrollToBottom();
          // 自动保存聊天历史
          _saveChatHistory();
        }
      },
      onError: (error) {
        // 网络异常时显示友好提示（不显示原始错误）
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('网络连接不稳定，已切换到离线模式'),
                  ),
                ],
              ),
              backgroundColor: JewelryColors.warning,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 清空对话
  void _clearChat() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: JewelryColors.error, size: 22),
            const SizedBox(width: 8),
            Text(
              '清空对话',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        content: Text(
          '确定要清空所有对话记录吗？',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: JewelryColors.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  id: 'welcome',
                  content: '您好！我是汇玉源智能助手 🌟\n\n有什么可以帮您的吗？',
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
              // 清除持久化历史
              _storage.clearChatHistory(_userId);
              // 重新播放欢迎动画
              _welcomeAnimController.reset();
              _welcomeAnimController.forward();
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}
