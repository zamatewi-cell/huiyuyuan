/// 汇玉源 - 真实商品数据
///
/// 数据来源: 基于市场真实商品信息
/// 更新日期: 2026-02-14
/// 图片来源: Unsplash 珠宝相关真实图片
library;

import '../models/user_model.dart';
import 'product_data_extended.dart';

/// 真实商品数据列表
final List<ProductModel> realProductData = [
  // ============ 和田玉系列 ============
  ProductModel(
    id: 'HYY-HT001',
    name: '新疆和田玉籽料福运手链',
    description: '''精选新疆和田玉籽料，玉质温润细腻，油性十足。
采用传统手工编织工艺，配以金刚结设计，寓意福运绑定、好运连连。
每颗珠子均为天然籽料，无优化处理，佩戴舒适。
附赠权威机构鉴定证书及区块链溯源码。''',
    price: 299,
    originalPrice: 599,
    category: '手链',
    material: '和田玉',
    origin: '新疆和田',
    images: [
      'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=800&h=800&fit=crop',
    ],
    stock: 156,
    rating: 4.9,
    salesCount: 2341,
    isHot: true,
    isWelfare: true,
    certificate: 'GTC-2026-HT001',
    blockchainHash: '0x7a8f...3d2e',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-HT002',
    name: '和田玉青白玉平安扣手串',
    description: '''甄选和田青白玉，色泽淡雅，质地均匀。
平安扣造型经典，寓意平安健康、万事如意。
采用弹力绳穿制，可调节松紧，适合不同手腕尺寸。
男女皆宜，适合日常佩戴或馈赠亲友。''',
    price: 399,
    originalPrice: 798,
    category: '手串',
    material: '和田玉',
    origin: '新疆和田',
    images: [
      'https://images.unsplash.com/photo-1596944924616-7b38e7cfac36?w=800&h=800&fit=crop',
    ],
    stock: 89,
    rating: 4.8,
    salesCount: 1567,
    isHot: true,
    isNew: true,
    isWelfare: true,
    certificate: 'GTC-2026-HT002',
    blockchainHash: '0x8b9c...4e5f',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-HT003',
    name: '羊脂白玉貔貅手链',
    description: '''顶级羊脂白玉，白度高、油润细腻。
精雕貔貅吊坠，招财纳福，辟邪保平安。
手工雕刻，栩栩如生，细节精致。
限量款式，极具收藏价值。''',
    price: 1280,
    originalPrice: 2560,
    category: '手链',
    material: '和田玉',
    origin: '新疆和田',
    images: [
      'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=800&h=800&fit=crop',
    ],
    stock: 35,
    rating: 5.0,
    salesCount: 521,
    isHot: true,
    isNew: true,
    certificate: 'GTC-2026-HT003',
    blockchainHash: '0x9c0d...5f6a',
    materialVerify: '天然A货',
  ),

  // ============ 缅甸翡翠系列 ============
  ProductModel(
    id: 'HYY-FC001',
    name: '缅甸翡翠平安扣吊坠',
    description: '''缅甸A货翡翠，冰种质地，透明度高。
飘花自然灵动，每件独一无二。
采用18K金镶嵌，高贵典雅。
配送精美礼盒，适合送礼。''',
    price: 1580,
    originalPrice: 3160,
    category: '吊坠',
    material: '缅甸翡翠',
    origin: '缅甸',
    images: [
      'https://images.unsplash.com/photo-1588444837495-c6cfeb53f32d?w=800&h=800&fit=crop',
    ],
    stock: 45,
    rating: 4.9,
    salesCount: 876,
    isHot: true,
    certificate: 'GIA-2026-FC001',
    blockchainHash: '0xa1b2...6c7d',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-FC002',
    name: '满绿翡翠圆珠手链',
    description: '''天然缅甸翡翠，满绿色泽，颜色均匀。
圆珠直径8mm，珠珠饱满润泽。
弹力穿绳，佩戴方便。
经国家权威机构鉴定，保证天然。''',
    price: 2380,
    originalPrice: 4760,
    category: '手链',
    material: '缅甸翡翠',
    origin: '缅甸',
    images: [
      'https://images.unsplash.com/photo-1603561591411-07134e71a2a9?w=800&h=800&fit=crop',
    ],
    stock: 28,
    rating: 4.8,
    salesCount: 432,
    isNew: true,
    certificate: 'GIA-2026-FC002',
    blockchainHash: '0xb2c3...7d8e',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-FC003',
    name: '糯冰翡翠葫芦耳环',
    description: '''糯冰种翡翠，质地细腻温润。
葫芦造型，寓意福禄双全。
925银镶嵌，防过敏材质。
精致小巧，日常百搭。''',
    price: 599,
    originalPrice: 1198,
    category: '耳饰',
    material: '缅甸翡翠',
    origin: '缅甸',
    images: [
      'https://images.unsplash.com/photo-1535632787350-4e68ef0ac584?w=800&h=800&fit=crop',
    ],
    stock: 67,
    rating: 4.7,
    salesCount: 789,
    isWelfare: true,
    certificate: 'GIA-2026-FC003',
    blockchainHash: '0xc3d4...8e9f',
    materialVerify: '天然A货',
  ),

  // ============ 南红玛瑙系列 ============
  ProductModel(
    id: 'HYY-NH001',
    name: '凉山南红玛瑙转运珠手链',
    description: '''四川凉山南红，色泽浓郁、质地温润。
转运珠设计，寓意时来运转。
纯手工打磨抛光，触感顺滑。
福利价位，品质保障。''',
    price: 199,
    originalPrice: 398,
    category: '手链',
    material: '南红玛瑙',
    origin: '四川凉山',
    images: [
      'https://images.unsplash.com/photo-1602751584552-8ba73aad10e1?w=800&h=800&fit=crop',
    ],
    stock: 234,
    rating: 4.8,
    salesCount: 3456,
    isHot: true,
    isWelfare: true,
    certificate: 'NGTC-2026-NH001',
    blockchainHash: '0xd4e5...9f0a',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-NH002',
    name: '柿子红南红玛瑙圆珠项链',
    description: '''顶级柿子红南红，颜色饱满艳丽。
圆珠均匀，直径6mm，总长45cm。
采用硅胶穿绳，结实耐用。
送礼自戴皆宜。''',
    price: 1680,
    originalPrice: 3360,
    category: '项链',
    material: '南红玛瑙',
    origin: '四川凉山',
    images: [
      'https://images.unsplash.com/photo-1611085583191-a3b181a88401?w=800&h=800&fit=crop',
    ],
    stock: 42,
    rating: 4.9,
    salesCount: 234,
    isNew: true,
    certificate: 'NGTC-2026-NH002',
    blockchainHash: '0xe5f6...0a1b',
    materialVerify: '天然A货',
  ),

  // ============ 紫水晶系列 ============
  ProductModel(
    id: 'HYY-ZS001',
    name: '乌拉圭紫水晶貔貅手串',
    description: '''乌拉圭顶级紫水晶，色泽深邃浓郁。
精雕貔貅吊坠，招财辟邪。
水晶珠子通透，光感极佳。
适合女性佩戴，优雅大气。''',
    price: 299,
    originalPrice: 598,
    category: '手串',
    material: '紫水晶',
    origin: '乌拉圭',
    images: [
      'https://images.unsplash.com/photo-1629224316810-9d8805b95e76?w=800&h=800&fit=crop',
    ],
    stock: 123,
    rating: 4.7,
    salesCount: 1234,
    isWelfare: true,
    certificate: 'IGI-2026-ZS001',
    blockchainHash: '0xf6a7...1b2c',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-ZS002',
    name: '紫晶洞摆件(小号)',
    description: '''巴西紫晶洞，晶体饱满，颜色紫艳。
天然形成，每件形态独特。
适合放置家中或办公桌，调节风水。
尺寸约15cm高，重约1.5kg。''',
    price: 880,
    originalPrice: 1760,
    category: '摆件',
    material: '紫水晶',
    origin: '巴西',
    images: [
      'https://images.unsplash.com/photo-1610694955371-d4a3e0ce4b52?w=800&h=800&fit=crop',
    ],
    stock: 56,
    rating: 4.8,
    salesCount: 567,
    isNew: true,
    certificate: 'IGI-2026-ZS002',
    blockchainHash: '0xa7b8...2c3d',
    materialVerify: '天然',
  ),

  // ============ 黄金系列 ============
  ProductModel(
    id: 'HYY-HJ001',
    name: '古法黄金传承手镯',
    description: '''采用古法黄金工艺，哑光磨砂质感。
福字祥云纹饰，寓意福气满满。
足金999，约20克重。
传承经典，历久弥新。''',
    price: 15600,
    originalPrice: 16800,
    category: '手镯',
    material: '黄金',
    origin: '中国',
    images: [
      'https://images.unsplash.com/photo-1619119069152-a2b331eb392a?w=800&h=800&fit=crop',
    ],
    stock: 20,
    rating: 4.9,
    salesCount: 899,
    certificate: 'NGTC-2026-HJ001',
    blockchainHash: '0xb8c9...3d4e',
    materialVerify: '足金999',
  ),
  ProductModel(
    id: 'HYY-HJ002',
    name: '3D硬金转运珠吊坠',
    description: '''3D硬金工艺，轻便不变形。
转运珠造型，精巧玲珑。
约1克重，含精美链条。
时尚百搭，日常必备。''',
    price: 580,
    originalPrice: 780,
    category: '吊坠',
    material: '黄金',
    origin: '中国',
    images: [
      'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=800&h=800&fit=crop',
    ],
    stock: 88,
    rating: 4.8,
    salesCount: 1567,
    isWelfare: true,
    certificate: 'NGTC-2026-HJ002',
    blockchainHash: '0xc9da...4e5f',
    materialVerify: '足金999',
  ),
  ProductModel(
    id: 'HYY-HJ003',
    name: '足金999莲花吊坠',
    description: '''精雕莲花造型，寓意出淤泥而不染。
足金999，约3克重。
3D硬金工艺，立体饱满。
赠送K金项链，到手即佩。''',
    price: 1880,
    originalPrice: 2380,
    category: '吊坠',
    material: '黄金',
    origin: '中国',
    images: [
      'https://images.unsplash.com/photo-1543294001-f7cd5d7fb516?w=800&h=800&fit=crop',
    ],
    stock: 50,
    rating: 4.9,
    salesCount: 678,
    isNew: true,
    isHot: true,
    certificate: 'NGTC-2026-HJ003',
    blockchainHash: '0xdaeb...5f60',
    materialVerify: '足金999',
  ),

  // ============ 红宝石系列 ============
  ProductModel(
    id: 'HYY-HB001',
    name: '18K金镶嵌缅甸红宝石戒指',
    description: '''缅甸天然红宝石，鸽血红色泽。
18K玫瑰金镶嵌，群镶小钻点缀。
国际GRS证书认证。
适合重要场合佩戴。''',
    price: 3580,
    originalPrice: 6880,
    category: '戒指',
    material: '红宝石',
    origin: '缅甸',
    images: [
      'https://images.unsplash.com/photo-1573408301185-9146fe634ad0?w=800&h=800&fit=crop',
    ],
    stock: 15,
    rating: 5.0,
    salesCount: 321,
    isHot: true,
    isNew: true,
    certificate: 'GRS-2026-HB001',
    blockchainHash: '0xdaeb...5f6a',
    materialVerify: '天然A货',
  ),

  // ============ 蓝宝石系列 ============
  ProductModel(
    id: 'HYY-LB001',
    name: '斯里兰卡蓝宝石吊坠',
    description: '''斯里兰卡天然蓝宝石，矢车菊蓝。
18K白金镶嵌，简约大气。
重约1.2克拉，附GRS证书。
高贵典雅，收藏佳品。''',
    price: 8880,
    originalPrice: 12800,
    category: '吊坠',
    material: '蓝宝石',
    origin: '斯里兰卡',
    images: [
      'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&h=800&fit=crop',
    ],
    stock: 8,
    rating: 5.0,
    salesCount: 89,
    isNew: true,
    certificate: 'GRS-2026-LB001',
    blockchainHash: '0xebfc...6a7b',
    materialVerify: '天然A货',
  ),

  // ============ 蜜蜡系列 ============
  ProductModel(
    id: 'HYY-ML001',
    name: '波罗的海鸡油黄蜜蜡手串',
    description: '''纯天然波罗的海蜜蜡，鸡油黄色。
圆珠直径10mm，颜色均匀。
蜡质浓郁，盘玩效果佳。
适合男士佩戴，稳重大气。''',
    price: 499,
    originalPrice: 998,
    category: '手串',
    material: '蜜蜡',
    origin: '波罗的海',
    images: [
      'https://images.unsplash.com/photo-1608042314453-ae338d80c427?w=800&h=800&fit=crop',
    ],
    stock: 78,
    rating: 4.8,
    salesCount: 876,
    isWelfare: true,
    certificate: 'NGTC-2026-ML001',
    blockchainHash: '0xfcad...7b8c',
    materialVerify: '天然A货',
  ),

  // ============ 碧玉系列 ============
  ProductModel(
    id: 'HYY-BY001',
    name: '俄罗斯碧玉菠菜绿手镯',
    description: '''俄罗斯碧玉，菠菜绿色，质地细腻。
圆条款式，内径56-60mm可选。
适合中老年女性佩戴。
经典传承款，永不过时。''',
    price: 2680,
    originalPrice: 5360,
    category: '手镯',
    material: '碧玉',
    origin: '俄罗斯',
    images: [
      'https://images.unsplash.com/photo-1610375461246-83df859d849d?w=800&h=800&fit=crop',
    ],
    stock: 32,
    rating: 4.7,
    salesCount: 234,
    certificate: 'NGTC-2026-BY001',
    blockchainHash: '0xadbe...8c9d',
    materialVerify: '天然A货',
  ),

  // ============ 新增商品 ============
  ProductModel(
    id: 'HYY-HT004',
    name: '和田玉墨玉龙凤手镯',
    description: '''新疆和田墨玉，色如浓墨，质感沉稳。
龙凤雕纹，寓意龙凤呈祥，百年好合。
圆条款式，适合婚嫁佩戴。
附NGTC鉴定证书。''',
    price: 3980,
    originalPrice: 6800,
    category: '手镯',
    material: '和田玉',
    origin: '新疆和田',
    images: [
      'https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?w=800&h=800&fit=crop',
    ],
    stock: 18,
    rating: 4.9,
    salesCount: 156,
    isNew: true,
    certificate: 'NGTC-2026-HT004',
    blockchainHash: '0xbecf...9da0',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-FC004',
    name: '冰糯种翡翠观音吊坠',
    description: '''缅甸冰糯种翡翠，温润透亮。
观音法相庄严，保佑平安。
18K白金镶嵌，精致大方。
附GTC鉴定证书。''',
    price: 2280,
    originalPrice: 4560,
    category: '吊坠',
    material: '缅甸翡翠',
    origin: '缅甸',
    images: [
      'https://images.unsplash.com/photo-1600721391776-b5cd0e0048f9?w=800&h=800&fit=crop',
    ],
    stock: 25,
    rating: 4.8,
    salesCount: 345,
    isHot: true,
    certificate: 'GTC-2026-FC004',
    blockchainHash: '0xcfd0...0ab1',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-ZJ001',
    name: '18K玫瑰金钻石项链',
    description: '''18K玫瑰金链条，光泽柔美。
主钻0.3克拉，SI 净度，H 色级。
锁骨链设计，优雅迷人。
附GIA证书。''',
    price: 4680,
    originalPrice: 6800,
    category: '项链',
    material: '钻石',
    origin: '南非',
    images: [
      'https://images.unsplash.com/photo-1605100804763-247f67b3557e?w=800&h=800&fit=crop',
    ],
    stock: 12,
    rating: 5.0,
    salesCount: 189,
    isNew: true,
    isHot: true,
    certificate: 'GIA-2026-ZJ001',
    blockchainHash: '0xd0e1...1bc2',
    materialVerify: '天然钻石',
  ),
  ProductModel(
    id: 'HYY-NH003',
    name: '保山南红玛瑙如意锁吊坠',
    description: '''云南保山南红，柿子红满色。
如意锁造型，寓意吉祥如意。
纯银镶嵌，赠送项链。
送小朋友百天礼佳选。''',
    price: 458,
    originalPrice: 916,
    category: '吊坠',
    material: '南红玛瑙',
    origin: '云南保山',
    images: [
      'https://images.unsplash.com/photo-1761210875101-1273b9ae5600?w=800&h=800&fit=crop',
    ],
    stock: 98,
    rating: 4.7,
    salesCount: 567,
    isWelfare: true,
    certificate: 'NGTC-2026-NH003',
    blockchainHash: '0xe1f2...2cd3',
    materialVerify: '天然A货',
  ),
  ProductModel(
    id: 'HYY-PT001',
    name: '天然珍珠优雅项链套装',
    description: '''天然淡水珍珠，圆润光泽。
7-8mm珍珠，搭配耳饰套装。
925银扣，防过敏材质。
优雅气质，适合日常佩戴。''',
    price: 368,
    originalPrice: 736,
    category: '项链',
    material: '珍珠',
    origin: '中国浙江',
    images: [
      'https://images.unsplash.com/photo-1739700285847-2f173370e8a7?w=800&h=800&fit=crop',
    ],
    stock: 120,
    rating: 4.6,
    salesCount: 2345,
    isWelfare: true,
    isHot: true,
    certificate: 'NGTC-2026-PT001',
    blockchainHash: '0xf2a3...3de4',
    materialVerify: '天然珍珠',
  ),
  ProductModel(
    id: 'HYY-HJ004',
    name: '黄金转运珠红绳手链',
    description: '''足金999转运珠，约0.5克。
手编红绳，寓意红红火火。
男女通用，尺寸可调。
本命年必备，祈福开运。''',
    price: 289,
    originalPrice: 399,
    category: '手链',
    material: '黄金',
    origin: '中国',
    images: [
      'https://images.unsplash.com/photo-1611652022419-a9419f74343d?w=800&h=800&fit=crop',
    ],
    stock: 200,
    rating: 4.8,
    salesCount: 4567,
    isHot: true,
    isWelfare: true,
    certificate: 'NGTC-2026-HJ004',
    blockchainHash: '0xa3b4...4ef5',
    materialVerify: '足金999',
  ),
  // 扩展商品数据（107件）
  ...extendedProductData,
];

/// 获取商品按分类
List<ProductModel> getProductsByCategory(String? category) {
  if (category == null || category == '全部') {
    return realProductData;
  }
  return realProductData.where((p) => p.category == category).toList();
}

/// 获取热门商品
List<ProductModel> getHotProducts() {
  return realProductData.where((p) => p.isHot).toList();
}

/// 获取福利款商品 (199-599元)
List<ProductModel> getWelfareProducts() {
  return realProductData.where((p) => p.isWelfare).toList();
}

/// 获取新品
List<ProductModel> getNewProducts() {
  return realProductData.where((p) => p.isNew).toList();
}

/// 按价格排序
List<ProductModel> sortByPrice(List<ProductModel> products, bool ascending) {
  final sorted = List<ProductModel>.from(products);
  sorted.sort((a, b) =>
      ascending ? a.price.compareTo(b.price) : b.price.compareTo(a.price));
  return sorted;
}

/// 按销量排序
List<ProductModel> sortBySales(List<ProductModel> products) {
  final sorted = List<ProductModel>.from(products);
  sorted.sort((a, b) => b.salesCount.compareTo(a.salesCount));
  return sorted;
}

/// 搜索商品
List<ProductModel> searchProducts(String keyword) {
  final lowered = keyword.toLowerCase();
  return realProductData.where((p) {
    return p.name.toLowerCase().contains(lowered) ||
        p.material.toLowerCase().contains(lowered) ||
        p.category.toLowerCase().contains(lowered) ||
        p.description.toLowerCase().contains(lowered);
  }).toList();
}

/// 所有商品（别名，供ProductService使用）
List<ProductModel> get allProducts => realProductData;

/// 根据ID获取本地商品
ProductModel? getLocalProductById(String productId) {
  try {
    return realProductData.firstWhere((p) => p.id == productId);
  } catch (_) {
    return null;
  }
}

/// 添加商品（管理员功能）
void addProduct(ProductModel product) {
  realProductData.add(product);
}

/// 删除商品（管理员功能）
bool removeProduct(String productId) {
  final initialLength = realProductData.length;
  realProductData.removeWhere((p) => p.id == productId);
  return realProductData.length < initialLength;
}

/// 获取所有材质类型
List<String> getAllMaterials() {
  return realProductData.map((p) => p.material).toSet().toList();
}

/// 获取所有分类
List<String> getAllCategories() {
  return realProductData.map((p) => p.category).toSet().toList();
}

/// 为新商品生成默认图片URL (基于材质类型，使用 Unsplash 珠宝图片)
String getDefaultImageForMaterial(String material) {
  final imageMap = {
    '和田玉': 'photo-1611591437281-460bfbe1220a',
    '缅甸翡翠': 'photo-1588444837495-c6cfeb53f32d',
    '南红玛瑙': 'photo-1602751584552-8ba73aad10e1',
    '紫水晶': 'photo-1629224316810-9d8805b95e76',
    '黄金': 'photo-1619119069152-a2b331eb392a',
    '红宝石': 'photo-1573408301185-9146fe634ad0',
    '蓝宝石': 'photo-1515562141207-7a88fb7ce338',
    '碧玉': 'photo-1610375461246-83df859d849d',
    '蜜蜡': 'photo-1608042314453-ae338d80c427',
    '钻石': 'photo-1605100804763-247f67b3557e',
    '珍珠': 'photo-1739700285847-2f173370e8a7',
  };
  final photoId = imageMap[material] ?? 'photo-1611591437281-460bfbe1220a';
  return 'https://images.unsplash.com/$photoId?w=800&h=800&fit=crop';
}
