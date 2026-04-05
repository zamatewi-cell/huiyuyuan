// 汇玉源 - 用户模型测试
//
// 测试内容:
// - UserModel 的创建和字段验证
// - 枚举类型转换
// - JSON 序列化/反序列化
// - 辅助方法测试
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/user_model.dart';

void main() {
  group('UserType 枚举测试', () {
    test('应正确返回管理员类型', () {
      expect(UserType.admin.index, 0);
    });

    test('应正确返回操作员类型', () {
      expect(UserType.operator.index, 1);
    });
  });

  group('UserModel 基础测试', () {
    test('应正确创建管理员用户', () {
      final admin = UserModel(
        id: 'admin_001',
        username: '超级管理员',
        phone: '18937766669',
        userType: UserType.admin,
        isActive: true,
        token: 'test_token',
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: DateTime.now(),
      );

      expect(admin.id, 'admin_001');
      expect(admin.username, '超级管理员');
      expect(admin.phone, '18937766669');
      expect(admin.userType, UserType.admin);
      expect(admin.isActive, true);
      expect(admin.isAdmin, true);
      expect(admin.isSuperAdmin, true);
    });

    test('应正确创建操作员用户', () {
      final operator = UserModel(
        id: 'operator_1',
        username: '操作员1号',
        userType: UserType.operator,
        isActive: true,
        token: 'op_token',
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: DateTime.now(),
        operatorNumber: 1,
      );

      expect(operator.id, 'operator_1');
      expect(operator.username, '操作员1号');
      expect(operator.userType, UserType.operator);
      expect(operator.operatorNumber, 1);
      expect(operator.isAdmin, false);
      expect(operator.isSuperAdmin, false);
    });

    test('操作员编号应在 1-10 范围内', () {
      for (int i = 1; i <= 10; i++) {
        final operator = UserModel(
          id: 'operator_$i',
          username: '操作员$i号',
          userType: UserType.operator,
          isActive: true,
          token: 'token_$i',
          createdAt: DateTime(2024, 1, 1),
          operatorNumber: i,
        );
        expect(operator.operatorNumber, i);
      }
    });

    test('isSuperAdmin 需要正确手机号', () {
      // 有正确手机号的管理员
      final superAdmin = UserModel(
        id: 'admin_001',
        username: '管理员',
        phone: '18937766669',
        userType: UserType.admin,
      );
      expect(superAdmin.isSuperAdmin, true);

      // 没有正确手机号的管理员
      final regularAdmin = UserModel(
        id: 'admin_002',
        username: '管理员2',
        phone: '13800138000',
        userType: UserType.admin,
      );
      expect(regularAdmin.isSuperAdmin, false);
    });
  });

  group('UserModel JSON 序列化测试', () {
    test('toJson 应返回正确的 Map', () {
      final user = UserModel(
        id: 'test_user',
        username: '测试用户',
        phone: '13800138000',
        userType: UserType.admin,
        isActive: true,
        token: 'test_token_123',
        createdAt: DateTime(2024, 1, 1, 10, 30),
        lastLoginAt: DateTime(2024, 6, 15, 14, 45),
      );

      final json = user.toJson();

      expect(json['id'], 'test_user');
      expect(json['username'], '测试用户');
      expect(json['phone'], '13800138000');
      expect(json['user_type'], 'admin');
      expect(json['is_active'], true);
      expect(json['token'], 'test_token_123');
    });

    test('fromJson 应正确解析 JSON', () {
      final json = {
        'id': 'parsed_user',
        'username': '解析用户',
        'phone': '13900139000',
        'user_type': 'operator',
        'is_active': true,
        'token': 'parsed_token',
        'created_at': '2024-01-01T00:00:00.000',
        'operator_number': 5,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'parsed_user');
      expect(user.username, '解析用户');
      expect(user.phone, '13900139000');
      expect(user.userType, UserType.operator);
      expect(user.operatorNumber, 5);
    });

    test('序列化后反序列化应保持数据一致', () {
      final original = UserModel(
        id: 'roundtrip_test',
        username: '往返测试',
        userType: UserType.admin,
        isActive: true,
        token: 'roundtrip_token',
        createdAt: DateTime(2024, 3, 15),
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.userType, original.userType);
      expect(restored.isActive, original.isActive);
      expect(restored.token, original.token);
    });
  });

  group('ProductModel 测试', () {
    test('应正确创建商品模型', () {
      final product = ProductModel(
        id: 'prod_001',
        name: '和田玉手链',
        category: '手链',
        material: '和田玉',
        price: 9999.0,
        originalPrice: 12999.0,
        stock: 10,
        images: ['image1.jpg', 'image2.jpg'],
        description: '精美和田玉手链',
        isHot: true,
        isNew: false,
      );

      expect(product.id, 'prod_001');
      expect(product.name, '和田玉手链');
      expect(product.category, '手链');
      expect(product.material, '和田玉');
      expect(product.price, 9999.0);
      expect(product.stock, 10);
      expect(product.isHot, true);
    });

    test('商品分类标签应正确', () {
      expect(ProductCategory.bracelet.label, '手链');
      expect(ProductCategory.pendant.label, '吊坠');
      expect(ProductCategory.ring.label, '戒指');
      expect(ProductCategory.bangle.label, '手镯');
      expect(ProductCategory.necklace.label, '项链');
      expect(ProductCategory.earring.label, '耳饰');
    });

    test('材质类型应有正确标签', () {
      expect(MaterialType.hetianYu.label, '和田玉');
      expect(MaterialType.jadeite.label, '缅甸翡翠');
      expect(MaterialType.nanHong.label, '南红玛瑙');
    });

    test('折扣率计算应正确', () {
      final product = ProductModel(
        id: 'prod_001',
        name: '测试商品',
        category: '手链',
        material: '和田玉',
        price: 800.0,
        originalPrice: 1000.0,
        stock: 10,
        images: [],
        description: '测试',
      );

      expect(product.discountRate, 20.0);
    });

    test('福利款价格范围判断应正确', () {
      final welfareProduct = ProductModel(
        id: 'prod_001',
        name: '福利商品',
        category: '手链',
        material: '和田玉',
        price: 399.0,
        stock: 10,
        images: [],
        description: '测试',
      );
      expect(welfareProduct.isWelfarePriceRange, true);

      final normalProduct = ProductModel(
        id: 'prod_002',
        name: '普通商品',
        category: '手链',
        material: '和田玉',
        price: 1999.0,
        stock: 10,
        images: [],
        description: '测试',
      );
      expect(normalProduct.isWelfarePriceRange, false);
    });
  });

  group('ShopModel 测试', () {
    test('应正确创建店铺模型', () {
      final shop = ShopModel(
        id: 'shop_001',
        name: '玉石坊',
        platform: '淘宝',
        category: '珠宝首饰',
        rating: 4.8,
        followers: 10000,
        conversionRate: 5.0,
        contactStatus: ContactStatus.cooperated,
      );

      expect(shop.id, 'shop_001');
      expect(shop.name, '玉石坊');
      expect(shop.platform, '淘宝');
      expect(shop.rating, 4.8);
      expect(shop.followers, 10000);
      expect(shop.contactStatus, ContactStatus.cooperated);
    });

    test('平台枚举应有正确标签', () {
      expect(Platform.taobao.label, '淘宝');
      expect(Platform.douyin.label, '抖音');
      expect(Platform.xiaohongshu.label, '小红书');
    });

    test('联系状态应有正确标签', () {
      expect(ContactStatus.pending.label, '待联系');
      expect(ContactStatus.negotiating.label, '洽谈中');
      expect(ContactStatus.cooperated.label, '已合作');
      expect(ContactStatus.rejected.label, '已拒绝');
    });

    test('isQualified 判断应正确', () {
      // 高质量店铺
      final qualifiedShop = ShopModel(
        id: 'shop_001',
        name: '优质店铺',
        platform: '淘宝',
        category: '珠宝',
        rating: 4.8,
        followers: 10000,
        conversionRate: 5.0,
        negativeRate: 0.01,
      );
      expect(qualifiedShop.isQualified, true);

      // 低质量店铺
      final unqualifiedShop = ShopModel(
        id: 'shop_002',
        name: '一般店铺',
        platform: '淘宝',
        category: '珠宝',
        rating: 4.0,
        followers: 1000,
        conversionRate: 1.0,
        negativeRate: 0.1,
      );
      expect(unqualifiedShop.isQualified, false);
    });
  });

  group('OrderModel 测试', () {
    test('订单状态应有正确标签', () {
      expect(OrderStatus.pending.label, '待支付');
      expect(OrderStatus.paid.label, '已支付');
      expect(OrderStatus.shipped.label, '已发货');
      expect(OrderStatus.delivered.label, '已签收');
      expect(OrderStatus.completed.label, '已完成');
      expect(OrderStatus.cancelled.label, '已取消');
      expect(OrderStatus.refunding.label, '退款中');
      expect(OrderStatus.refunded.label, '已退款');
    });

    test('应正确创建订单模型', () {
      final order = OrderModel(
        id: 'order_001',
        productId: 'prod_001',
        productName: '和田玉手链',
        quantity: 2,
        amount: 19998.0,
        status: OrderStatus.paid,
        createdAt: DateTime.now(),
      );

      expect(order.id, 'order_001');
      expect(order.productName, '和田玉手链');
      expect(order.quantity, 2);
      expect(order.amount, 19998.0);
      expect(order.status, OrderStatus.paid);
    });
  });

  group('ChatMessage 测试', () {
    test('应正确创建消息', () {
      final message = ChatMessage(
        id: 'msg_001',
        content: '你好，请问这款玉石怎么样？',
        isUser: true,
        timestamp: DateTime.now(),
      );

      expect(message.id, 'msg_001');
      expect(message.content, '你好，请问这款玉石怎么样？');
      expect(message.isUser, true);
      expect(message.type, 'text');
    });

    test('AI 消息应正确识别', () {
      final aiMessage = ChatMessage(
        id: 'msg_002',
        content: '这是一款上等和田玉...',
        isUser: false,
        timestamp: DateTime.now(),
      );

      expect(aiMessage.isUser, false);
    });
  });

  group('BlockchainCertificate 测试', () {
    test('应正确创建区块链证书', () {
      final cert = BlockchainCertificate(
        id: 'cert_001',
        certNo: 'CERT-2024-001',
        materialType: '和田玉',
        origin: '新疆和田',
        certDate: DateTime(2024, 1, 1),
        institution: '国家珠宝玉石检测中心',
        txHash: '0x123456789abcdef',
      );

      expect(cert.id, 'cert_001');
      expect(cert.certNo, 'CERT-2024-001');
      expect(cert.materialType, '和田玉');
      expect(cert.institution, '国家珠宝玉石检测中心');
      expect(cert.isVerified, true);
    });
  });
}
