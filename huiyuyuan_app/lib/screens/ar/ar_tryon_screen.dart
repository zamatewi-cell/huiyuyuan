import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

import '../../l10n/l10n_provider.dart';

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
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ar_tryon_title'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'ar_tryon_take_photo'.tr,
            onPressed: _takePhoto,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // Virtual preview area.
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[850]!,
                    Colors.grey[800]!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: selectedJewelry.color.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background decoration.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundPainter(
                        color: selectedJewelry.color,
                      ),
                    ),
                  ),

                  // Main preview content.
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Jewelry preview.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedJewelry.color,
                              width: 25,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedJewelry.color.withOpacity(0.5),
                                blurRadius: 50,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[850],
                                border: Border.all(
                                  color: selectedJewelry.color.withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.pan_tool_outlined,
                                  size: 60,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'ar_tryon_wrist_hint'.tr,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E8B57).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.view_in_ar,
                                color: Color(0xFF2E8B57),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ar_tryon_rotate_hint'.tr,
                                style: const TextStyle(
                                  color: Color(0xFF2E8B57),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product information.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                // Product name and price.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedJewelry.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedJewelry.material,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '¥${selectedJewelry.price}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Style selector.
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _jewelryList.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedJewelry == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedJewelry = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 70,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: _jewelryList[index].color,
                            borderRadius: BorderRadius.circular(35),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _jewelryList[index]
                                          .color
                                          .withOpacity(0.6),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.link,
                              color: Colors.white.withOpacity(0.9),
                              size: 30,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons.
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(ref.tr('product_added_favorite'))),
                          );
                        },
                        icon: const Icon(Icons.favorite_border,
                            color: Colors.white),
                        label: Text('ar_tryon_favorite'.tr,
                            style: const TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _recommendToCustomer,
                        icon: const Icon(Icons.send),
                        label: Text('ar_tryon_recommend_customer'.tr),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('ar_tryon_saved_result'
                .trArgs({'name': _jewelryList[_selectedJewelry].name})),
          ],
        ),
        backgroundColor: const Color(0xFF2E8B57),
      ),
    );
  }

  void _shareProduct() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ar_tryon_share_to'.tr,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareItem(
                    Icons.chat, ref.tr('share_wechat'), Colors.green),
                _buildShareItem(
                    Icons.group, ref.tr('share_moments'), Colors.green),
                _buildShareItem(Icons.qr_code, ref.tr('share_qq'), Colors.blue),
                _buildShareItem(Icons.link, ref.tr('share_link'), Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
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
              content: Text('ar_tryon_shared_to'.trArgs({'label': label}))),
        );
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  void _recommendToCustomer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ar_tryon_recommend_title'.tr),
        content: Text('ar_tryon_recommend_confirm'
            .trArgs({'name': _jewelryList[_selectedJewelry].name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ref.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ar_tryon_recommend_success'
                      .trArgs({'name': _jewelryList[_selectedJewelry].name})),
                  backgroundColor: const Color(0xFF2E8B57),
                ),
              );
            },
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
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Draw decorative circles.
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      80,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      60,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
