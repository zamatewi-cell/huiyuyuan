/// 汇玉源 - 合作商家数据
///
/// 注: 此为示例数据，具体信息后续更新
/// 更新日期: 2026-02-06
library;

import '../models/user_model.dart';

/// 合作商家数据列表
final List<ShopModel> partnerShopData = [
  // ============ 淘宝店铺 ============
  ShopModel(
    id: 'SHOP-TB001',
    name: '翡翠缘珠宝旗舰店',
    platform: '淘宝',
    rating: 4.9,
    conversionRate: 5.2,
    followers: 156000,
    category: '翡翠玉石',
    contactStatus: ContactStatus.cooperated,
    shopUrl: 'https://feicuiyuan.taobao.com',
    monthlySales: 3200,
    negativeRate: 0.008,
    dsrScore: 4.86,
    isInfluencer: false,
    operatorId: 'OP001',
    lastContactAt: DateTime(2026, 2, 1),
    aiPriority: 95,
  ),
  ShopModel(
    id: 'SHOP-TB002',
    name: '和田玉工厂直销店',
    platform: '淘宝',
    rating: 4.8,
    conversionRate: 4.8,
    followers: 89000,
    category: '和田玉',
    contactStatus: ContactStatus.cooperated,
    shopUrl: 'https://hetianyugongchang.taobao.com',
    monthlySales: 2100,
    negativeRate: 0.012,
    dsrScore: 4.78,
    isInfluencer: false,
    operatorId: 'OP002',
    lastContactAt: DateTime(2026, 1, 28),
    aiPriority: 88,
  ),
  ShopModel(
    id: 'SHOP-TB003',
    name: '玉满堂珠宝专营店',
    platform: '淘宝',
    rating: 4.85,
    conversionRate: 4.5,
    followers: 67000,
    category: '综合珠宝',
    contactStatus: ContactStatus.negotiating,
    shopUrl: 'https://yumantang.taobao.com',
    monthlySales: 1800,
    negativeRate: 0.015,
    dsrScore: 4.72,
    isInfluencer: false,
    operatorId: 'OP003',
    lastContactAt: DateTime(2026, 2, 5),
    aiPriority: 82,
  ),

  // ============ 抖音达人 ============
  ShopModel(
    id: 'SHOP-DY001',
    name: '玉石小金的直播间',
    platform: '抖音',
    rating: 4.92,
    conversionRate: 6.8,
    followers: 520000,
    category: '玉石翡翠',
    contactStatus: ContactStatus.cooperated,
    shopUrl: 'https://www.douyin.com/user/yushixiaojin',
    monthlySales: 8500,
    negativeRate: 0.006,
    dsrScore: 4.91,
    isInfluencer: true,
    liveRoomUrl: 'https://live.douyin.com/yushixiaojin',
    audienceMatchRate: 0.89,
    operatorId: 'OP001',
    lastContactAt: DateTime(2026, 2, 4),
    aiPriority: 98,
  ),
  ShopModel(
    id: 'SHOP-DY002',
    name: '珠宝鉴定师阿飞',
    platform: '抖音',
    rating: 4.88,
    conversionRate: 5.5,
    followers: 380000,
    category: '珠宝鉴定',
    contactStatus: ContactStatus.interested,
    shopUrl: 'https://www.douyin.com/user/afeizhubao',
    monthlySales: 5600,
    negativeRate: 0.009,
    dsrScore: 4.85,
    isInfluencer: true,
    liveRoomUrl: 'https://live.douyin.com/afeizhubao',
    audienceMatchRate: 0.75,
    operatorId: 'OP002',
    lastContactAt: DateTime(2026, 2, 3),
    aiPriority: 85,
  ),
  ShopModel(
    id: 'SHOP-DY003',
    name: '翠姐源头货',
    platform: '抖音',
    rating: 4.75,
    conversionRate: 7.2,
    followers: 890000,
    category: '翡翠直播',
    contactStatus: ContactStatus.negotiating,
    shopUrl: 'https://www.douyin.com/user/cuijie',
    monthlySales: 12000,
    negativeRate: 0.018,
    dsrScore: 4.68,
    isInfluencer: true,
    liveRoomUrl: 'https://live.douyin.com/cuijie',
    audienceMatchRate: 0.82,
    operatorId: 'OP003',
    lastContactAt: DateTime(2026, 2, 6),
    aiPriority: 78,
  ),

  // ============ 小红书达人 ============
  ShopModel(
    id: 'SHOP-XHS001',
    name: '玉石穿搭笔记',
    platform: '小红书',
    rating: 4.82,
    conversionRate: 3.8,
    followers: 230000,
    category: '珠宝穿搭',
    contactStatus: ContactStatus.cooperated,
    shopUrl: 'https://www.xiaohongshu.com/user/yushibiji',
    monthlySales: 1200,
    negativeRate: 0.005,
    dsrScore: 4.80,
    isInfluencer: true,
    audienceMatchRate: 0.92,
    operatorId: 'OP001',
    lastContactAt: DateTime(2026, 2, 2),
    aiPriority: 90,
  ),
  ShopModel(
    id: 'SHOP-XHS002',
    name: '小玉儿的珠宝日记',
    platform: '小红书',
    rating: 4.78,
    conversionRate: 4.2,
    followers: 156000,
    category: '玉石分享',
    contactStatus: ContactStatus.interested,
    shopUrl: 'https://www.xiaohongshu.com/user/xiaoyuer',
    monthlySales: 860,
    negativeRate: 0.008,
    dsrScore: 4.75,
    isInfluencer: true,
    audienceMatchRate: 0.85,
    operatorId: 'OP002',
    lastContactAt: DateTime(2026, 2, 1),
    aiPriority: 83,
  ),

  // ============ 快手达人 ============
  ShopModel(
    id: 'SHOP-KS001',
    name: '四会翡翠源头一哥',
    platform: '快手',
    rating: 4.72,
    conversionRate: 8.5,
    followers: 1200000,
    category: '翡翠直播',
    contactStatus: ContactStatus.contacted,
    shopUrl: 'https://www.kuaishou.com/user/sihuiyige',
    monthlySales: 25000,
    negativeRate: 0.022,
    dsrScore: 4.65,
    isInfluencer: true,
    liveRoomUrl: 'https://live.kuaishou.com/sihuiyige',
    audienceMatchRate: 0.68,
    operatorId: 'OP003',
    lastContactAt: DateTime(2026, 2, 5),
    aiPriority: 75,
  ),

  // ============ 京东店铺 ============
  ShopModel(
    id: 'SHOP-JD001',
    name: '中信珠宝官方旗舰店',
    platform: '京东',
    rating: 4.95,
    conversionRate: 3.2,
    followers: 450000,
    category: '品牌珠宝',
    contactStatus: ContactStatus.pending,
    shopUrl: 'https://zhongxin.jd.com',
    monthlySales: 6800,
    negativeRate: 0.003,
    dsrScore: 4.92,
    isInfluencer: false,
    operatorId: null,
    lastContactAt: null,
    aiPriority: 72,
  ),

  // ============ 拼多多店铺 ============
  ShopModel(
    id: 'SHOP-PDD001',
    name: '玉石天堂工厂店',
    platform: '拼多多',
    rating: 4.68,
    conversionRate: 9.5,
    followers: 320000,
    category: '平价玉石',
    contactStatus: ContactStatus.interested,
    shopUrl: 'https://yushitiantang.pinduoduo.com',
    monthlySales: 18000,
    negativeRate: 0.028,
    dsrScore: 4.58,
    isInfluencer: false,
    operatorId: 'OP001',
    lastContactAt: DateTime(2026, 1, 30),
    aiPriority: 68,
  ),
];

/// 获取所有合作商家
List<ShopModel> getAllPartnerShops() {
  return partnerShopData;
}

/// 按平台筛选商家
List<ShopModel> getShopsByPlatform(String platform) {
  if (platform == '全部') {
    return partnerShopData;
  }
  return partnerShopData.where((s) => s.platform == platform).toList();
}

/// 获取已合作商家
List<ShopModel> getCooperatedShops() {
  return partnerShopData
      .where((s) => s.contactStatus == ContactStatus.cooperated)
      .toList();
}

/// 获取待联系商家
List<ShopModel> getPendingShops() {
  return partnerShopData
      .where((s) => s.contactStatus == ContactStatus.pending)
      .toList();
}

/// 获取有意向商家
List<ShopModel> getInterestedShops() {
  return partnerShopData
      .where((s) => s.contactStatus == ContactStatus.interested)
      .toList();
}

/// 获取达人列表
List<ShopModel> getInfluencers() {
  return partnerShopData.where((s) => s.isInfluencer).toList();
}

/// 按AI优先级排序
List<ShopModel> sortByAIPriority(List<ShopModel> shops,
    {bool descending = true}) {
  final sorted = List<ShopModel>.from(shops);
  sorted.sort((a, b) {
    final priorityA = a.aiPriority ?? 0;
    final priorityB = b.aiPriority ?? 0;
    return descending
        ? priorityB.compareTo(priorityA)
        : priorityA.compareTo(priorityB);
  });
  return sorted;
}

/// 获取高质量商家 (评分>=4.8, 转化率>=3%, 差评率<2%)
List<ShopModel> getQualifiedShops() {
  return partnerShopData.where((s) => s.isQualified).toList();
}
