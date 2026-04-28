import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

import '../../l10n/l10n_provider.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';

class _JewelryPreview {
  final String name;
  final Color color;
  final int price;
  final String material;

  const _JewelryPreview({
    required this.name,
    required this.color,
    required this.price,
    required this.material,
  });
}

class _ARTryOnBackdrop extends StatelessWidget {
  const _ARTryOnBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            right: -120,
            child: _ARGlowOrb(
              size: 350,
              color: JewelryColors.emeraldGlow.withOpacity(0.11),
            ),
          ),
          Positioned(
            left: -160,
            bottom: 160,
            child: _ARGlowOrb(
              size: 300,
              color: JewelryColors.champagneGold.withOpacity(0.08),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _ARTracePainter()),
          ),
        ],
      ),
    );
  }
}

class _ARGlowOrb extends StatelessWidget {
  const _ARGlowOrb({
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
          BoxShadow(color: color, blurRadius: 110, spreadRadius: 36),
        ],
      ),
    );
  }
}

class _ARTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.08 + i * 0.12);
      final path = Path()..moveTo(-28, y);
      path.cubicTo(
        size.width * 0.2,
        y - 34,
        size.width * 0.78,
        y + 38,
        size.width + 28,
        y,
      );
      canvas.drawPath(path, pathPaint);
    }

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45
      ..color = JewelryColors.emeraldGlow.withOpacity(0.03);
    for (var x = -40.0; x < size.width + 40; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x + 120, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ARTracePainter oldDelegate) => false;
}

/// AR try-on screen.
class ARTryOnScreen extends ConsumerStatefulWidget {
  const ARTryOnScreen({super.key});

  @override
  ConsumerState<ARTryOnScreen> createState() => _ARTryOnScreenState();
}

class _ARTryOnScreenState extends ConsumerState<ARTryOnScreen> {
  int _selectedJewelry = 0;

  final List<_JewelryPreview> _jewelryList = [
    _JewelryPreview(
      name: 'ar_tryon_name_hetian_bracelet'.tr,
      color: const Color(0xFFF5F5DC),
      price: 299,
      material: 'ar_tryon_material_hetian_jade'.tr,
    ),
    _JewelryPreview(
      name: 'ar_tryon_name_jadeite_pendant'.tr,
      color: const Color(0xFF32CD32),
      price: 599,
      material: 'ar_tryon_material_jadeite'.tr,
    ),
    _JewelryPreview(
      name: 'ar_tryon_name_agate_bead'.tr,
      color: const Color(0xFFFF6347),
      price: 199,
      material: 'ar_tryon_material_agate'.tr,
    ),
    _JewelryPreview(
      name: 'ar_tryon_name_amethyst_chain'.tr,
      color: const Color(0xFF9370DB),
      price: 168,
      material: 'ar_tryon_material_amethyst'.tr,
    ),
    _JewelryPreview(
      name: 'ar_tryon_name_jasper_pendant'.tr,
      color: const Color(0xFF228B22),
      price: 880,
      material: 'ar_tryon_material_jasper'.tr,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedJewelry = _jewelryList[_selectedJewelry];

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        foregroundColor: JewelryColors.jadeMist,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.14),
            ),
          ),
          child: Text(
            'ar_tryon_title'.tr,
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'ar_tryon_take_photo'.tr,
            onPressed: _takePhoto,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: _shareProduct,
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _ARTryOnBackdrop()),
          Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildPreviewStage(selectedJewelry),
              ),
              _buildProductConsole(selectedJewelry),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStage(_JewelryPreview selectedJewelry) {
    return GlassmorphicCard(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      padding: EdgeInsets.zero,
      borderRadius: 34,
      blur: 18,
      opacity: 0.18,
      borderColor: selectedJewelry.color.withOpacity(0.34),
      boxShadow: [
        BoxShadow(
          color: selectedJewelry.color.withOpacity(0.24),
          blurRadius: 54,
          spreadRadius: 2,
          offset: const Offset(0, 20),
        ),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPainter(color: selectedJewelry.color),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: _buildStatusPill(
                icon: Icons.view_in_ar,
                label: 'ar_tryon_rotate_hint'.tr,
                color: selectedJewelry.color,
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: _buildStatusPill(
                icon: Icons.auto_awesome,
                label: 'AR',
                color: JewelryColors.champagneGold,
              ),
            ),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.92 + value * 0.08,
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildVirtualJadeRing(selectedJewelry),
                    const SizedBox(height: 26),
                    Text(
                      'ar_tryon_wrist_hint'.tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.64),
                        fontSize: 14,
                        height: 1.45,
                      ),
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

  Widget _buildVirtualJadeRing(_JewelryPreview jewelry) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            jewelry.color.withOpacity(0.2),
            jewelry.color.withOpacity(0.07),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: jewelry.color.withOpacity(0.34),
            blurRadius: 70,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: jewelry.color.withOpacity(0.62), width: 24),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  JewelryColors.jadeBlack.withOpacity(0.92),
                  JewelryColors.deepJade.withOpacity(0.74),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: JewelryColors.champagneGold.withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.pan_tool_alt_outlined,
              size: 62,
              color: JewelryColors.jadeMist.withOpacity(0.34),
            ),
          ),
          Positioned(
            top: 18,
            right: 42,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JewelryColors.champagneGold.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: JewelryColors.champagneGold.withOpacity(0.45),
                    blurRadius: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: JewelryColors.jadeBlack.withOpacity(0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductConsole(_JewelryPreview selectedJewelry) {
    return GlassmorphicCard(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      padding: const EdgeInsets.all(18),
      borderRadius: 30,
      blur: 18,
      opacity: 0.2,
      borderColor: JewelryColors.champagneGold.withOpacity(0.16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedJewelry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedJewelry.material,
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.58),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: JewelryColors.champagneGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: JewelryColors.champagneGold.withOpacity(0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Text(
                  '¥${selectedJewelry.price}',
                  style: const TextStyle(
                    color: JewelryColors.jadeBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _jewelryList.length,
              itemBuilder: (context, index) {
                final jewelry = _jewelryList[index];
                final isSelected = _selectedJewelry == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedJewelry = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 76 : 66,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          jewelry.color.withOpacity(0.92),
                          jewelry.color.withOpacity(0.52),
                          JewelryColors.deepJade.withOpacity(0.72),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? JewelryColors.champagneGold
                            : JewelryColors.jadeMist.withOpacity(0.18),
                        width: isSelected ? 2.4 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: jewelry.color.withOpacity(0.45),
                                blurRadius: 22,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      color: JewelryColors.jadeMist.withOpacity(0.92),
                      size: isSelected ? 32 : 27,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ref.tr('product_added_favorite')),
                        backgroundColor: JewelryColors.emeraldShadow,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: Text('ar_tryon_favorite'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: JewelryColors.jadeMist,
                    side: BorderSide(
                      color: JewelryColors.champagneGold.withOpacity(0.24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _recommendToCustomer,
                  icon: const Icon(Icons.send_rounded),
                  label: Text('ar_tryon_recommend_customer'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: JewelryColors.emeraldLuster,
                    foregroundColor: JewelryColors.jadeBlack,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: JewelryColors.jadeMist),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ar_tryon_saved_result'.trArgs({
                  'name': _jewelryList[_selectedJewelry].name,
                }),
              ),
            ),
          ],
        ),
        backgroundColor: JewelryColors.emeraldShadow,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareProduct() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              JewelryColors.deepJade.withOpacity(0.98),
              JewelryColors.jadeSurface.withOpacity(0.94),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(
                color: JewelryColors.champagneGold.withOpacity(0.16)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: JewelryColors.jadeMist.withOpacity(0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ar_tryon_share_to'.tr,
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareItem(Icons.chat, ref.tr('share_wechat'),
                    JewelryColors.emeraldGlow),
                _buildShareItem(Icons.group, ref.tr('share_moments'),
                    JewelryColors.emeraldLuster),
                _buildShareItem(
                    Icons.qr_code, ref.tr('share_qq'), JewelryColors.info),
                _buildShareItem(Icons.link, ref.tr('share_link'),
                    JewelryColors.champagneGold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareItem(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ar_tryon_shared_to'.trArgs({'label': label})),
            backgroundColor: JewelryColors.emeraldShadow,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.24)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: JewelryColors.jadeMist.withOpacity(0.74),
            ),
          ),
        ],
      ),
    );
  }

  void _recommendToCustomer() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'ar_tryon_recommend_title'.tr,
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'ar_tryon_recommend_confirm'.trArgs({
            'name': _jewelryList[_selectedJewelry].name,
          }),
          style: TextStyle(
            color: JewelryColors.jadeMist.withOpacity(0.68),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              ref.tr('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.58)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ar_tryon_recommend_success'.trArgs({
                      'name': _jewelryList[_selectedJewelry].name,
                    }),
                  ),
                  backgroundColor: JewelryColors.emeraldShadow,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.emeraldLuster,
              foregroundColor: JewelryColors.jadeBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(ref.tr('confirm')),
          ),
        ],
      ),
    );
  }
}

/// Background decoration painter.
class _BackgroundPainter extends CustomPainter {
  final Color color;

  _BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = color.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final scanPaint = Paint()
      ..color = JewelryColors.emeraldGlow.withOpacity(0.05)
      ..strokeWidth = 1;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = JewelryColors.champagneGold.withOpacity(0.08);

    canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.22), 86, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.18, size.height * 0.78), 68, circlePaint);

    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.12 + i * 0.09);
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), scanPaint);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.72,
        height: size.height * 0.42,
      ),
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.color != color;
}
