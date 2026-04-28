import 'package:huiyuyuan/l10n/string_extension.dart';
import 'package:huiyuyuan/l10n/translator_global.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_service.dart';
import '../../services/api_service.dart';
import '../../services/ai_product_context_service.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../themes/colors.dart';
import '../../l10n/l10n_provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/text_sanitizer.dart';
import '../../screens/trade/product_detail_screen.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/animations/typing_indicator.dart';
import '../../widgets/animations/blinking_cursor.dart';
import '../../widgets/animations/fade_slide_transition.dart';

class _AiConciergeBackdrop extends StatelessWidget {
  const _AiConciergeBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            right: -120,
            child: _AiGlowOrb(
              size: 340,
              color: JewelryColors.emeraldGlow.withOpacity(0.12),
            ),
          ),
          Positioned(
            left: -130,
            top: 260,
            child: _AiGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.12),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _AiWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiGlowOrb extends StatelessWidget {
  const _AiGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 36,
          ),
        ],
      ),
    );
  }
}

class _AiWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.8
      ..color = JewelryColors.champagneGold.withOpacity(0.035)
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.12 + i * 0.115);
      final path = Path()..moveTo(-24, y);
      for (var x = -24.0; x <= size.width + 24; x += 36) {
        path.lineTo(x, y + ((x / size.width) - 0.5) * (i.isEven ? 14 : -14));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AiWavePainter oldDelegate) => false;
}

class _ConciergeCapability extends StatelessWidget {
  const _ConciergeCapability({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: JewelryColors.deepJade.withOpacity(0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: JewelryColors.champagneGold.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: JewelryColors.champagneGold),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.76),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// AI assistant screen.
class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with TickerProviderStateMixin {
  final _aiService = AIService();
  final _productService = ProductService();
  final _productContextService = AIProductContextService();
  final _storage = StorageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Map<String, ProductModel?> _recommendedProducts = {};
  final Set<String> _loadingRecommendedProducts = {};
  bool _isLoading = false;

  /// Current draft content being streamed.
  String _streamingContent = '';
  bool _isStreaming = false;

  /// Selected image queued for sending.
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  /// Current user id used to isolate persisted history.
  String _userId = 'anonymous';

  /// Welcome animation controller.
  late AnimationController _welcomeAnimController;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;

  String _welcomeMessage() => TranslatorGlobal.instance.translate('ai_welcome');

  @override
  void initState() {
    super.initState();

    // Configure the welcome animation.
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

    // Seed the welcome message.
    _messages.add(ChatMessage(
      id: 'welcome',
      content: _welcomeMessage(),
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Start the welcome animation.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _welcomeAnimController.forward();
    });

    // Load persisted chat history.
    _loadChatHistory();
  }

  /// Loads chat history.
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

  /// Persists chat history.
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
    final aiOnline = _aiService.isOnlineConfigured;
    final aiStatusColor =
        aiOnline ? JewelryColors.success : JewelryColors.warning;
    final aiStatusText =
        aiOnline ? ref.tr('work_online') : ref.tr('ai_offline');

    // Refresh the localized welcome copy.
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
          blur: 18,
          opacity: 0.12,
          borderColor: JewelryColors.champagneGold.withOpacity(0.16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: JewelryColors.emeraldLusterGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: JewelryColors.jadeBlack,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ref.tr('ai_title'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: JewelryColors.jadeMist,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 6),
              // Online status indicator.
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: aiStatusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: aiStatusColor.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                aiStatusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: aiStatusColor,
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
                color: JewelryColors.deepJade.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: JewelryColors.champagneGold.withOpacity(0.14),
                ),
              ),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: JewelryColors.jadeMist.withOpacity(0.72),
              ),
            ),
            onPressed: () {
              if (_messages.length <= 1) return;
              _clearChat();
            },
            tooltip: ref.tr('ai_clear'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Background layer.
          const _AiConciergeBackdrop(),

          Column(
            children: [
              const SizedBox(height: 100), // AppBar高度占位

              _buildConciergeIntro(
                aiOnline: aiOnline,
                statusText: aiStatusText,
                statusColor: aiStatusColor,
              ),

              // Suggested prompts.
              _buildQuickQuestions(),

              // Message list.
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount:
                      _messages.length + (_isLoading || _isStreaming ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading or streaming bubble.
                    if (index == _messages.length) {
                      if (_isStreaming) {
                        return _buildStreamingBubble();
                      }
                      return _buildTypingIndicator();
                    }
                    // Animated welcome message.
                    if (_messages[index].id == 'welcome') {
                      return FadeTransition(
                        opacity: _welcomeFadeAnimation,
                        child: SlideTransition(
                          position: _welcomeSlideAnimation,
                          child: _buildMessageBubble(_messages[index]),
                        ),
                      );
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              // Composer.
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  /// Suggested prompt section backed by preset questions.
  Widget _buildConciergeIntro({
    required bool aiOnline,
    required String statusText,
    required Color statusColor,
  }) {
    if (_messages.length > 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: JewelryColors.liquidGlassGradient,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: JewelryColors.champagneGold.withOpacity(0.16),
              ),
              boxShadow: JewelryShadows.liquidGlass,
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -36,
                  child: Container(
                    width: 122,
                    height: 122,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: JewelryColors.champagneGold.withOpacity(0.16),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: JewelryColors.emeraldLusterGradient,
                            boxShadow: JewelryShadows.emeraldHalo,
                          ),
                          child: const Icon(
                            Icons.diamond_outlined,
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
                                'PRIVATE GEM ADVISOR',
                                style: TextStyle(
                                  color: JewelryColors.emeraldGlow
                                      .withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ref.tr('ai_title'),
                                style: const TextStyle(
                                  color: JewelryColors.jadeMist,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: statusColor.withOpacity(0.24),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.45),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      aiOnline
                          ? '从预算、材质、寓意、送礼场景到真伪风险，我会像私顾一样帮你缩小选择范围。'
                          : '当前使用离线兜底建议，仍可提供选购方向、材质知识和场景化推荐。',
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.68),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        _ConciergeCapability(
                          icon: Icons.search_rounded,
                          label: '甄选',
                        ),
                        SizedBox(width: 8),
                        _ConciergeCapability(
                          icon: Icons.verified_user_outlined,
                          label: '鉴别',
                        ),
                        SizedBox(width: 8),
                        _ConciergeCapability(
                          icon: Icons.card_giftcard_outlined,
                          label: '送礼',
                        ),
                      ],
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

  Widget _buildQuickQuestions() {
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
      height: 54,
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
              backgroundColor: JewelryColors.deepJade.withOpacity(0.68),
              labelStyle: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.12),
              ),
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

  /// Message bubble.
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    // Extract product ids embedded in AI messages.
    final productIds =
        _productContextService.extractProductIds(message.content);
    // Remove [PRODUCT:xxx] tags from the display text.
    final cleanContent =
        sanitizeUtf16(_productContextService.stripProductTags(message.content));

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
                  gradient: JewelryColors.emeraldLusterGradient,
                  shape: BoxShape.circle,
                  boxShadow: JewelryShadows.emeraldHalo,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: JewelryColors.jadeBlack,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Message image rendered from memory bytes for web support.
                  if (isUser && message.imageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 250,
                            maxHeight: 250,
                          ),
                          child: Image.memory(
                            message.imageBytes!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  // Message body.
                  isUser
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: JewelryColors.emeraldLusterGradient,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(22),
                              topRight: Radius.circular(22),
                              bottomLeft: Radius.circular(22),
                              bottomRight: Radius.circular(6),
                            ),
                            boxShadow: JewelryShadows.emeraldHalo,
                          ),
                          child: Text(
                            message.content,
                            style: const TextStyle(
                              color: JewelryColors.jadeBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        )
                      : GlassmorphicCard(
                          borderRadius: 22,
                          blur: 18,
                          opacity: 0.18,
                          borderColor:
                              JewelryColors.champagneGold.withOpacity(0.14),
                          padding: const EdgeInsets.all(16),
                          child: MarkdownBody(
                            data: cleanContent,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: JewelryColors.jadeMist.withOpacity(0.9),
                                fontSize: 15,
                                height: 1.55,
                              ),
                              strong: const TextStyle(
                                color: JewelryColors.champagneGold,
                                fontWeight: FontWeight.w900,
                              ),
                              listBullet: TextStyle(
                                color: JewelryColors.jadeMist.withOpacity(0.64),
                              ),
                              h1: const TextStyle(
                                color: JewelryColors.jadeMist,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                              h2: const TextStyle(
                                color: JewelryColors.jadeMist,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                              h3: const TextStyle(
                                color: JewelryColors.jadeMist,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              code: TextStyle(
                                color: JewelryColors.emeraldGlow,
                                backgroundColor:
                                    JewelryColors.emeraldGlow.withOpacity(0.08),
                              ),
                            ),
                          ),
                        ),

                  // Product recommendation card.
                  if (!isUser && productIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: productIds
                            .map((id) => _buildProductCard(id))
                            .toList(),
                      ),
                    ),

                  // Copy action for AI replies.
                  if (!isUser && message.id != 'welcome')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionChip(
                            icon: Icons.copy,
                            label: ref.tr('ai_copy'),
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
                  color: JewelryColors.deepJade.withOpacity(0.82),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JewelryColors.champagneGold.withOpacity(0.16),
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 16,
                  color: JewelryColors.jadeMist.withOpacity(0.72),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  /// Builds a product recommendation card.
  Widget _buildProductCard(String productId) {
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
          gradient: JewelryColors.liquidGlassGradient,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.14),
            width: 1,
          ),
          boxShadow: JewelryShadows.liquidGlass,
        ),
        child: Row(
          children: [
            const SizedBox(
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
                TranslatorGlobal.instance
                    .translate('loading_recommended_products'),
                style: TextStyle(
                  fontSize: 13,
                  color: JewelryColors.jadeMist.withOpacity(0.68),
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
          gradient: LinearGradient(
            colors: [
              JewelryColors.deepJade.withOpacity(0.92),
              JewelryColors.jadeSurface.withOpacity(0.62),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: JewelryColors.jadeBlack.withOpacity(0.28),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image.
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
                  decoration: const BoxDecoration(
                    gradient: JewelryColors.emeraldLusterGradient,
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: JewelryColors.jadeBlack,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Product information.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.titleL10n,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: JewelryColors.jadeMist,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.matL10n} · ${product.catL10n}',
                      style: TextStyle(
                        fontSize: 12,
                        color: JewelryColors.jadeMist.withOpacity(0.54),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '¥${product.price.toInt()}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: JewelryColors.champagneGold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product.originalPrice != null &&
                            product.originalPrice! > product.price)
                          Text(
                            '¥${product.originalPrice!.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: JewelryColors.jadeMist.withOpacity(0.34),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  JewelryColors.champagneGold.withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            ref.tr('common_view_detail'),
                            style: const TextStyle(
                              color: JewelryColors.champagneGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
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

  /// Opens the product detail page.
  void _navigateToProduct(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  /// Copy action button.
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
          color: JewelryColors.deepJade.withOpacity(0.64),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: JewelryColors.champagneGold.withOpacity(0.78),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: JewelryColors.jadeMist.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copies a message to the clipboard.
  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(ref.tr('ai_copied')),
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

  /// Streaming response bubble.
  Widget _buildStreamingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: JewelryColors.emeraldLusterGradient,
              shape: BoxShape.circle,
              boxShadow: JewelryShadows.emeraldHalo,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: JewelryColors.jadeBlack,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: GlassmorphicCard(
              borderRadius: 22,
              blur: 18,
              opacity: 0.18,
              borderColor: JewelryColors.champagneGold.withOpacity(0.14),
              padding: const EdgeInsets.all(16),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: sanitizeUtf16(_streamingContent),
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.9),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                    // Show the blinking cursor only while streaming.
                    const WidgetSpan(
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

  /// Typing indicator.
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: JewelryColors.emeraldLusterGradient,
              shape: BoxShape.circle,
              boxShadow: JewelryShadows.emeraldHalo,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: JewelryColors.jadeBlack,
            ),
          ),
          const SizedBox(width: 12),
          GlassmorphicCard(
            borderRadius: 22,
            blur: 18,
            opacity: 0.18,
            borderColor: JewelryColors.champagneGold.withOpacity(0.14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ref.tr('ai_thinking'),
                  style: TextStyle(
                    fontSize: 12,
                    color: JewelryColors.jadeMist.withOpacity(0.64),
                  ),
                ),
                const SizedBox(width: 8),
                // Animated jumping dots.
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

  /// Input area.
  Widget _buildInputArea() {
    final isBusy = _isLoading || _isStreaming;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                JewelryColors.deepJade.withOpacity(0.88),
                JewelryColors.jadeBlack.withOpacity(0.94),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              top: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.12),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: JewelryColors.jadeBlack.withOpacity(0.36),
                blurRadius: 28,
                offset: const Offset(0, -12),
              ),
            ],
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
                              onTap: () => setState(() {
                                _selectedImage = null;
                                _selectedImageBytes = null;
                              }),
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
                        color: JewelryColors.deepJade.withOpacity(0.76),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: JewelryColors.champagneGold.withOpacity(0.14),
                        ),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: JewelryColors.jadeMist.withOpacity(0.72),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: JewelryColors.jadeSurface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: JewelryColors.champagneGold.withOpacity(0.12),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: ref.tr('ai_input_hint'),
                          hintStyle: TextStyle(
                            color: JewelryColors.jadeMist.withOpacity(0.42),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          color: JewelryColors.jadeMist,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: isBusy ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isBusy
                            ? LinearGradient(
                                colors: [
                                  JewelryColors.jadeSurface.withOpacity(0.7),
                                  JewelryColors.deepJade.withOpacity(0.7),
                                ],
                              )
                            : JewelryColors.emeraldLusterGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isBusy
                                ? JewelryColors.jadeBlack.withOpacity(0.18)
                                : JewelryColors.emeraldGlow.withOpacity(0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.send,
                        color: isBusy
                            ? JewelryColors.jadeMist.withOpacity(0.42)
                            : JewelryColors.jadeBlack,
                        size: 20,
                      ),
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
      // Read bytes eagerly for web-compatible in-memory rendering.
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }

  /// Sends a message using streamed output.
  Future<void> _sendMessage() async {
    final text = sanitizeUtf16(_messageController.text.trim());
    final imageFile = _selectedImage;
    final imageBytes = _selectedImageBytes;
    if ((text.isEmpty && imageFile == null) || _isLoading || _isStreaming) {
      return;
    }

    // Capture history before appending the pending user message.
    final history = _messages
        .where((m) => m.id != 'welcome')
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.content,
            })
        .toList();

    // Add the pending user message with in-memory image bytes only.
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text.isEmpty ? ref.tr('ai_image_default_prompt') : text,
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

    // Preprocess images through the backend proxy for mainland networks.
    String queryToAI = text.isEmpty ? ref.tr('ai_image_default_prompt') : text;
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      // Try backend-proxied AI analysis first.
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
          final mat = analysis['material'] as String? ?? ref.tr('ai_unknown');
          final cat = analysis['category'] as String? ?? ref.tr('ai_unknown');
          if (desc.isNotEmpty) {
            queryToAI = [
              ref.tr('ai_image_context_intro'),
              ref.tr('ai_image_context_desc', params: {'description': desc}),
              ref.tr('ai_image_context_material', params: {'material': mat}),
              ref.tr('ai_image_context_category', params: {'category': cat}),
              '',
              ref.tr('ai_image_context_question',
                  params: {'question': queryToAI}),
            ].join('\n');
          } else {
            queryToAI = ref.tr(
              'ai_image_context_no_result',
              params: {'question': queryToAI},
            );
          }
        } else {
          queryToAI = ref.tr(
            'ai_image_context_read_failed',
            params: {'question': queryToAI},
          );
        }
      } catch (e) {
        queryToAI = ref.tr(
          'ai_image_context_service_unavailable',
          params: {
            'error': sanitizeUtf16(e.toString()),
            'question': queryToAI,
          },
        );
      }
    }

    // Briefly show the thinking indicator before streaming starts.
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
      _isStreaming = true;
    });

    // Try streaming output with DashScope as the primary model.
    final currentLanguage = ref.read(appSettingsProvider).language.code;
    await _aiService.chatStream(
      userMessage: queryToAI,
      history:
          history.length > 10 ? history.sublist(history.length - 10) : history,
      language: currentLanguage,
      onToken: (token) {
        if (mounted) {
          setState(() {
            _streamingContent = sanitizeUtf16(_streamingContent + token);
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
          // Persist chat history after each update.
          _saveChatHistory();
        }
      },
      onError: (error) {
        // Show a friendly network error instead of the raw exception.
        if (mounted) {
          final message = _formatAiFallbackMessage(error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(message),
                  ),
                ],
              ),
              backgroundColor: JewelryColors.warning,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  String _formatAiFallbackMessage(String error) {
    final message = sanitizeUtf16(error.trim());
    if (message.isEmpty) {
      return 'ai_fallback_offline'.tr;
    }

    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('network') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('socketexception') ||
        lowerMessage.contains('connection refused') ||
        message.contains('网络') ||
        message.contains('網路')) {
      return 'ai_fallback_network'.tr;
    }

    if (lowerMessage.contains('dashscope') ||
        lowerMessage.contains('qwen') ||
        message.contains('千问') ||
        message.contains('千問') ||
        lowerMessage.contains('ai proxy') ||
        message.contains('未配置') ||
        message.contains('未設定') ||
        lowerMessage.contains('missing')) {
      return 'ai_fallback_offline'.tr;
    }

    return 'ai_fallback_generic'.trArgs({'message': message});
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

  /// Clears the conversation.
  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(
              Icons.delete_outline,
              color: JewelryColors.error,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              ref.tr('ai_clear'),
              style: const TextStyle(color: JewelryColors.jadeMist),
            ),
          ],
        ),
        content: Text(
          ref.tr('ai_clear_confirm'),
          style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.68)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              ref.tr('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.56)),
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
                  content: _welcomeMessage(),
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
              // Clear persisted history.
              _storage.clearChatHistory(_userId);
              // Replay the welcome animation.
              _welcomeAnimController.reset();
              _welcomeAnimController.forward();
            },
            child: Text(ref.tr('ai_clear')),
          ),
        ],
      ),
    );
  }
}
