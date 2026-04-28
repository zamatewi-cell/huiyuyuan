// 汇玉源 - 地址服务测试
//
// 测试内容:
// - 地址CRUD操作
// - 默认地址管理
// - 地址校验
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuyuan/services/address_service.dart';
import 'package:huiyuyuan/models/address_model.dart';

void main() {
  late AddressService addressService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    addressService = AddressService();
    await addressService.init();
  });

  group('AddressModel 测试', () {
    test('AddressModel 应正确创建', () {
      final address = AddressModel(
        id: 'ADDR-001',
        recipientName: '张三',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '某某街道某某小区1号楼101室',
        isDefault: true,
        tag: '家',
        createdAt: DateTime(2026, 2, 1),
      );

      expect(address.id, 'ADDR-001');
      expect(address.recipientName, '张三');
      expect(address.phoneNumber, '13800138000');
      expect(address.province, '北京市');
      expect(address.city, '北京市');
      expect(address.district, '朝阳区');
      expect(address.detailAddress, '某某街道某某小区1号楼101室');
      expect(address.isDefault, true);
    });

    test('fullAddress 应返回完整地址', () {
      final address = AddressModel(
        id: 'ADDR-002',
        recipientName: '李四',
        phoneNumber: '13900139000',
        province: '广东省',
        city: '深圳市',
        district: '南山区',
        detailAddress: '科技园路1号',
        createdAt: DateTime.now(),
      );

      expect(address.fullAddress, '广东省深圳市南山区科技园路1号');
    });

    test('shortAddress 应返回简短地址', () {
      final address = AddressModel(
        id: 'ADDR-003',
        recipientName: '王五',
        phoneNumber: '13700137000',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '陆家嘴金融中心',
        createdAt: DateTime.now(),
      );

      expect(address.shortAddress, '上海市浦东新区');
    });

    test('maskedPhone 应返回脱敏手机号', () {
      final address = AddressModel(
        id: 'ADDR-004',
        recipientName: '赵六',
        phoneNumber: '13812345678',
        province: '北京市',
        city: '北京市',
        district: '海淀区',
        detailAddress: '中关村大街1号',
        createdAt: DateTime.now(),
      );

      expect(address.maskedPhone, '138****5678');
    });

    test('fromJson 应正确解析', () {
      final json = {
        'id': 'ADDR-005',
        'recipient_name': '测试用户',
        'phone_number': '13900000000',
        'province': '浙江省',
        'city': '杭州市',
        'district': '西湖区',
        'detail_address': '文三路100号',
        'postal_code': '310000',
        'is_default': true,
        'tag': '公司',
        'created_at': '2026-02-01T10:00:00',
      };

      final address = AddressModel.fromJson(json);

      expect(address.id, 'ADDR-005');
      expect(address.recipientName, '测试用户');
      expect(address.phoneNumber, '13900000000');
      expect(address.province, '浙江省');
      expect(address.isDefault, true);
      expect(address.tag, '公司');
    });

    test('toJson 应正确转换', () {
      final address = AddressModel(
        id: 'ADDR-006',
        recipientName: '测试',
        phoneNumber: '13800000000',
        province: '江苏省',
        city: '南京市',
        district: '鼓楼区',
        detailAddress: '中山路1号',
        createdAt: DateTime(2026, 2, 1),
      );

      final json = address.toJson();

      expect(json['id'], 'ADDR-006');
      expect(json['recipient_name'], '测试');
      expect(json['province'], '江苏省');
    });

    test('copyWith 应正确复制并修改', () {
      final address = AddressModel(
        id: 'ADDR-007',
        recipientName: '原始名称',
        phoneNumber: '13800000000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '原始地址',
        createdAt: DateTime.now(),
      );

      final copied = address.copyWith(
        recipientName: '新名称',
        isDefault: true,
      );

      expect(copied.id, 'ADDR-007');
      expect(copied.recipientName, '新名称');
      expect(copied.isDefault, true);
      expect(copied.province, '北京市');
    });

    test('isValid 应正确校验地址完整性', () {
      final validAddress = AddressModel(
        id: 'ADDR-008',
        recipientName: '张三',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '某某街道某某小区1号楼',
        createdAt: DateTime.now(),
      );
      expect(validAddress.isValid, true);

      final invalidAddress = AddressModel(
        id: 'ADDR-009',
        recipientName: '',
        phoneNumber: '138',
        province: '',
        city: '',
        district: '',
        detailAddress: '短',
        createdAt: DateTime.now(),
      );
      expect(invalidAddress.isValid, false);
    });
  });

  group('AddressService CRUD 测试', () {
    test('初始时应无地址', () async {
      await addressService.clearAllAddresses();
      final addresses = await addressService.getAllAddresses();
      expect(addresses, isEmpty);
    });

    test('添加地址应成功', () async {
      await addressService.clearAllAddresses();
      
      final address = AddressModel(
        id: '',
        recipientName: '测试用户',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '测试地址100号',
        createdAt: DateTime.now(),
      );

      final added = await addressService.addAddress(address);

      expect(added.id, isNotEmpty);
      expect(added.recipientName, '测试用户');
      expect(added.isDefault, true);
    });

    test('更新地址应成功', () async {
      await addressService.clearAllAddresses();
      
      final address = AddressModel(
        id: '',
        recipientName: '原始名称',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '原始地址',
        createdAt: DateTime.now(),
      );

      final added = await addressService.addAddress(address);

      final updated = added.copyWith(
        recipientName: '更新名称',
        detailAddress: '更新地址',
      );

      await addressService.updateAddress(updated);

      final retrieved = await addressService.getAddressById(added.id);
      expect(retrieved!.recipientName, '更新名称');
      expect(retrieved.detailAddress, '更新地址');
    });

    test('删除地址应成功', () async {
      await addressService.clearAllAddresses();
      
      final address = AddressModel(
        id: '',
        recipientName: '待删除',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '删除测试地址',
        createdAt: DateTime.now(),
      );

      final added = await addressService.addAddress(address);
      expect(await addressService.getAddressCount(), 1);

      await addressService.deleteAddress(added.id);
      expect(await addressService.getAddressCount(), 0);
    });

    test('删除不存在的地址不应报错', () async {
      await addressService.deleteAddress('NON_EXISTENT_ID');
    });
  });

  group('默认地址管理测试', () {
    test('第一个地址应自动设为默认', () async {
      await addressService.clearAllAddresses();
      
      final address = AddressModel(
        id: '',
        recipientName: '第一个地址',
        phoneNumber: '13800138001',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '第一个地址详情',
        createdAt: DateTime.now(),
      );

      final added = await addressService.addAddress(address);
      expect(added.isDefault, true);
    });

    test('设置新默认地址应取消旧默认', () async {
      await addressService.clearAllAddresses();
      
      final address1 = AddressModel(
        id: '',
        recipientName: '地址1',
        phoneNumber: '13800138001',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '地址1详情',
        createdAt: DateTime.now(),
      );

      final added1 = await addressService.addAddress(address1);
      expect(added1.isDefault, true);

      final address2 = AddressModel(
        id: '',
        recipientName: '地址2',
        phoneNumber: '13800138002',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '地址2详情',
        isDefault: true,
        createdAt: DateTime.now(),
      );

      await addressService.addAddress(address2);

      final oldAddress = await addressService.getAddressById(added1.id);
      expect(oldAddress!.isDefault, false);

      final defaultAddr = await addressService.getDefaultAddress();
      expect(defaultAddr!.recipientName, '地址2');
    });

    test('setDefaultAddress 应正确设置默认', () async {
      await addressService.clearAllAddresses();
      
      final address1 = await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '地址A',
        phoneNumber: '13800138001',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '地址A详情',
        createdAt: DateTime.now(),
      ));

      await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '地址B',
        phoneNumber: '13800138002',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '地址B详情',
        createdAt: DateTime.now(),
      ));

      await addressService.setDefaultAddress(address1.id);

      final defaultAddr = await addressService.getDefaultAddress();
      expect(defaultAddr!.id, address1.id);
    });

    test('删除默认地址后应自动设置新默认', () async {
      await addressService.clearAllAddresses();
      
      final address1 = await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '地址1',
        phoneNumber: '13800138001',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '地址1详情',
        createdAt: DateTime.now(),
      ));

      final address2 = await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '地址2',
        phoneNumber: '13800138002',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '地址2详情',
        isDefault: true,
        createdAt: DateTime.now(),
      ));

      await addressService.deleteAddress(address2.id);

      final defaultAddr = await addressService.getDefaultAddress();
      expect(defaultAddr!.id, address1.id);
      expect(defaultAddr.isDefault, true);
    });
  });

  group('AddressService 辅助方法测试', () {
    test('getAddressCount 应返回正确数量', () async {
      await addressService.clearAllAddresses();
      expect(await addressService.getAddressCount(), 0);

      await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '测试1',
        phoneNumber: '13800138001',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '测试地址1',
        createdAt: DateTime.now(),
      ));
      expect(await addressService.getAddressCount(), 1);

      await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '测试2',
        phoneNumber: '13800138002',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '测试地址2',
        createdAt: DateTime.now(),
      ));
      expect(await addressService.getAddressCount(), 2);
    });

    test('hasAddress 应返回正确结果', () async {
      await addressService.clearAllAddresses();
      expect(await addressService.hasAddress(), false);

      await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '测试',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '测试地址',
        createdAt: DateTime.now(),
      ));
      expect(await addressService.hasAddress(), true);
    });

    test('getAddressById 应返回正确地址', () async {
      await addressService.clearAllAddresses();
      
      final added = await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '查找测试',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '查找测试地址',
        createdAt: DateTime.now(),
      ));

      final found = await addressService.getAddressById(added.id);
      expect(found, isNotNull);
      expect(found!.recipientName, '查找测试');
    });

    test('getAddressById 不存在的ID应返回null', () async {
      final found = await addressService.getAddressById('NON_EXISTENT');
      expect(found, isNull);
    });

    test('clearAllAddresses 应清空所有地址', () async {
      await addressService.clearAllAddresses();
      
      await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '测试1',
        phoneNumber: '13800138001',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '测试地址1',
        createdAt: DateTime.now(),
      ));

      await addressService.addAddress(AddressModel(
        id: '',
        recipientName: '测试2',
        phoneNumber: '13800138002',
        province: '上海市',
        city: '上海市',
        district: '浦东新区',
        detailAddress: '测试地址2',
        createdAt: DateTime.now(),
      ));

      expect(await addressService.getAddressCount(), greaterThanOrEqualTo(2));

      await addressService.clearAllAddresses();
      expect(await addressService.getAddressCount(), 0);
    });
  });

  group('AddressTag 枚举测试', () {
    test('AddressTag 应包含所有标签', () {
      expect(AddressTag.values.length, 4);
      expect(AddressTag.values.contains(AddressTag.home), true);
      expect(AddressTag.values.contains(AddressTag.company), true);
      expect(AddressTag.values.contains(AddressTag.school), true);
      expect(AddressTag.values.contains(AddressTag.other), true);
    });

    test('AddressTag label 和 emoji 应正确', () {
      expect(AddressTag.home.label, 'address_tag_home');
      expect(AddressTag.home.emoji, '🏠');
      expect(AddressTag.company.label, 'address_tag_company');
      expect(AddressTag.company.emoji, '🏢');
    });
  });

  group('边界情况测试', () {
    test('更新不存在的地址应抛出异常', () async {
      final address = AddressModel(
        id: 'NON_EXISTENT',
        recipientName: '测试',
        phoneNumber: '13800138000',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '测试地址',
        createdAt: DateTime.now(),
      );

      expect(() => addressService.updateAddress(address), throwsException);
    });

    test('无地址时获取默认地址应返回null', () async {
      await addressService.clearAllAddresses();
      final defaultAddr = await addressService.getDefaultAddress();
      expect(defaultAddr, isNull);
    });

    test('短手机号应正确处理脱敏', () {
      final address = AddressModel(
        id: '1',
        recipientName: '测试',
        phoneNumber: '138',
        province: '北京市',
        city: '北京市',
        district: '朝阳区',
        detailAddress: '测试地址',
        createdAt: DateTime.now(),
      );

      expect(address.maskedPhone, '138');
    });
  });
}
