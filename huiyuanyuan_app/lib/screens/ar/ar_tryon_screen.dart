import 'package:flutter/material.dart';

/// AR 虚拟试戴页面
class ARTryOnScreen extends StatefulWidget {
  const ARTryOnScreen({super.key});

  @override
  State<ARTryOnScreen> createState() => _ARTryOnScreenState();
}

class _ARTryOnScreenState extends State<ARTryOnScreen> {
  int _selectedJewelry = 0;

  final List<Map<String, dynamic>> _jewelryList = [
    {
      'name': '和田玉福运手链',
      'color': const Color(0xFFF5F5DC),
      'price': 299,
      'material': '和田玉'
    },
    {
      'name': '翡翠平安扣',
      'color': const Color(0xFF32CD32),
      'price': 599,
      'material': '缅甸翡翠'
    },
    {
      'name': '玛瑙转运珠',
      'color': const Color(0xFFFF6347),
      'price': 199,
      'material': '南红玛瑙'
    },
    {
      'name': '紫水晶能量链',
      'color': const Color(0xFF9370DB),
      'price': 168,
      'material': '紫水晶'
    },
    {
      'name': '碧玉如意吊坠',
      'color': const Color(0xFF228B22),
      'price': 880,
      'material': '碧玉'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('虚拟试戴'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: '拍照',
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
          // 虚拟展示区域
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
                    color: _jewelryList[_selectedJewelry]['color']
                        .withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 背景装饰
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BackgroundPainter(
                        color: _jewelryList[_selectedJewelry]['color'],
                      ),
                    ),
                  ),

                  // 主展示内容
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 手链展示
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _jewelryList[_selectedJewelry]['color'],
                              width: 25,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _jewelryList[_selectedJewelry]['color']
                                    .withOpacity(0.5),
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
                                  color: _jewelryList[_selectedJewelry]['color']
                                      .withOpacity(0.3),
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
                          '将手腕放置于此处',
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
                              Icon(
                                Icons.view_in_ar,
                                color: const Color(0xFF2E8B57),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '360° 旋转查看',
                                style: TextStyle(
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

          // 产品信息
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                // 产品名称和价格
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _jewelryList[_selectedJewelry]['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _jewelryList[_selectedJewelry]['material'],
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
                        '¥${_jewelryList[_selectedJewelry]['price']}',
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

                // 款式选择
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
                            color: _jewelryList[index]['color'],
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
                                      color: _jewelryList[index]['color']
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

                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已加入收藏')),
                          );
                        },
                        icon: const Icon(Icons.favorite_border,
                            color: Colors.white),
                        label: const Text('收藏',
                            style: TextStyle(color: Colors.white)),
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
                        label: const Text('向客户推荐'),
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
            Text('已保存 ${_jewelryList[_selectedJewelry]['name']} 的试戴效果'),
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
            const Text(
              '分享到',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareItem(Icons.chat, '微信', Colors.green),
                _buildShareItem(Icons.group, '朋友圈', Colors.green),
                _buildShareItem(Icons.qr_code, 'QQ', Colors.blue),
                _buildShareItem(Icons.link, '复制链接', Colors.grey),
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
          SnackBar(content: Text('已分享到$label')),
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
        title: const Text('推荐给客户'),
        content: Text(
            '确定将 "${_jewelryList[_selectedJewelry]['name']}" 推荐给当前沟通的客户吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '已将 ${_jewelryList[_selectedJewelry]['name']} 推荐给客户'),
                  backgroundColor: const Color(0xFF2E8B57),
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 背景装饰画笔
class _BackgroundPainter extends CustomPainter {
  final Color color;

  _BackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // 绘制装饰圆
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
