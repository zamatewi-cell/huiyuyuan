import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/payment_account.dart';
import 'package:huiyuyuan/providers/payment_provider.dart';
import 'package:huiyuyuan/services/api_service.dart';
import 'package:huiyuyuan/config/api_config.dart';

class FakeApiService extends ApiService {
  ApiResult<List<dynamic>> Function(String path, {Map<String, dynamic>? params})? getHandler;
  ApiResult<Map<String, dynamic>> Function(String path, {dynamic data, Map<String, dynamic>? params})? postHandler;
  ApiResult<Map<String, dynamic>> Function(String path, {dynamic data, Map<String, dynamic>? params})? putHandler;
  ApiResult<Map<String, dynamic>> Function(String path, {dynamic data, Map<String, dynamic>? params})? deleteHandler;

  FakeApiService() : super.forTesting();

  @override
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (getHandler != null) {
      return getHandler!(path, params: params) as ApiResult<T>;
    }
    return ApiResult.success([]) as ApiResult<T>;
  }

  @override
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (postHandler != null) {
      return postHandler!(path, data: data, params: params) as ApiResult<T>;
    }
    return ApiResult.success({}) as ApiResult<T>;
  }

  @override
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (putHandler != null) {
      return putHandler!(path, data: data, params: params) as ApiResult<T>;
    }
    return ApiResult.success({}) as ApiResult<T>;
  }

  @override
  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    if (deleteHandler != null) {
      return deleteHandler!(path, data: data, params: params) as ApiResult<T>;
    }
    return ApiResult.success({}) as ApiResult<T>;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentAccountsState', () {
    test('copyWith should preserve errorMessage when not explicitly set', () {
      const state = PaymentAccountsState(
        state: PaymentLoadingState.error,
        errorMessage: 'test error',
        accounts: [],
      );

      final newState = state.copyWith(state: PaymentLoadingState.loaded);

      expect(newState.errorMessage, 'test error');
    });

    test('copyWith should clear errorMessage when explicitly set to null', () {
      const state = PaymentAccountsState(
        state: PaymentLoadingState.error,
        errorMessage: 'test error',
        accounts: [],
      );

      final newState = state.copyWith(
        state: PaymentLoadingState.loaded,
        errorMessage: null,
      );

      expect(newState.errorMessage, isNull);
    });

    test('initial state should have empty accounts and initial state', () {
      const state = PaymentAccountsState();

      expect(state.accounts, isEmpty);
      expect(state.state, PaymentLoadingState.initial);
      expect(state.errorMessage, isNull);
    });
  });

  group('PaymentAccountNotifier 加载失败测试', () {
    test('错误状态应正确保存错误消息', () {
      const state = PaymentAccountsState(
        state: PaymentLoadingState.error,
        errorMessage: '网络连接失败',
        accounts: [],
      );

      expect(state.state, PaymentLoadingState.error);
      expect(state.errorMessage, '网络连接失败');
      expect(state.accounts, isEmpty);
    });

    test('错误状态应保留空账户列表', () {
      const state = PaymentAccountsState(
        state: PaymentLoadingState.error,
        errorMessage: '服务器错误',
        accounts: [],
      );

      expect(state.accounts, isEmpty);
      expect(state.state, PaymentLoadingState.error);
    });
  });

  group('PaymentAccountNotifier 设置默认账户测试', () {
    test('账户列表中的默认账户标记应正确', () {
      final account1 = PaymentAccount(
        id: 'acc_001',
        name: '账户1',
        type: PaymentType.bank,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final account2 = PaymentAccount(
        id: 'acc_002',
        name: '账户2',
        type: PaymentType.alipay,
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final state = PaymentAccountsState(
        state: PaymentLoadingState.loaded,
        accounts: [account1, account2],
      );

      expect(state.accounts.length, 2);
      expect(
          state.accounts.firstWhere((a) => a.id == 'acc_001').isDefault, false);
      expect(
          state.accounts.firstWhere((a) => a.id == 'acc_002').isDefault, true);
    });
  });

  group('PaymentAccountNotifier 删除失败测试', () {
    test('删除失败时错误消息应正确设置', () {
      final account = PaymentAccount(
        id: 'acc_001',
        name: '测试账户',
        type: PaymentType.bank,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final stateBefore = PaymentAccountsState(
        state: PaymentLoadingState.loaded,
        accounts: [account],
      );

      final stateAfter = stateBefore.copyWith(
        errorMessage: '删除失败：账户不存在',
      );

      expect(stateAfter.errorMessage, '删除失败：账户不存在');
      expect(stateAfter.accounts.length, 1);
    });

    test('删除失败时账户列表应保持不变', () {
      final account = PaymentAccount(
        id: 'acc_001',
        name: '测试账户',
        type: PaymentType.bank,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final stateBefore = PaymentAccountsState(
        state: PaymentLoadingState.loaded,
        accounts: [account],
      );

      final stateAfter = stateBefore.copyWith(
        errorMessage: '网络错误',
      );

      expect(stateAfter.accounts.length, 1);
      expect(stateAfter.accounts.first.id, 'acc_001');
    });
  });

  group('PaymentAccountNotifier 创建账户测试', () {
    test('创建账户失败时错误消息应正确设置', () {
      const state = PaymentAccountsState(
        state: PaymentLoadingState.loaded,
        errorMessage: '创建失败：参数错误',
        accounts: [],
      );

      expect(state.errorMessage, '创建失败：参数错误');
      expect(state.accounts, isEmpty);
    });
  });

  group('PaymentAccountNotifier FakeApiService 真实 mutation 测试', () {
    test('loadAccounts success: 状态应为 loaded，accounts 不为空', () async {
      final fakeApi = FakeApiService();
      fakeApi.getHandler = (path, {params}) {
        expect(path, ApiConfig.paymentAccounts);
        return ApiResult.success([
          {
            'id': 'acc_001',
            'name': '我的支付宝',
            'type': 'alipay',
            'account_number': '138****8888',
            'bank_name': null,
            'is_active': true,
            'is_default': true,
            'created_at': '2026-03-01T10:00:00Z',
            'updated_at': '2026-03-01T10:00:00Z',
          },
        ]);
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();

      expect(notifier.state.state, PaymentLoadingState.loaded);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.accounts.length, 1);
      expect(notifier.state.accounts.first.name, '我的支付宝');
    });

    test('loadAccounts failure: 状态应为 error，errorMessage 应正确', () async {
      final fakeApi = FakeApiService();
      fakeApi.getHandler = (path, {params}) {
        return ApiResult.error('服务器内部错误', code: 500);
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();

      expect(notifier.state.state, PaymentLoadingState.error);
      expect(notifier.state.errorMessage, '服务器内部错误');
    });

    test('addAccount success: 新账户应追加到列表头部', () async {
      final fakeApi = FakeApiService();
      fakeApi.getHandler = (path, {params}) => ApiResult.success([]);
      fakeApi.postHandler = (path, {data, params}) {
        expect(path, ApiConfig.paymentAccounts);
        return ApiResult.success({
          'id': 'acc_new',
          'name': '微信支付',
          'type': 'wechat',
          'account_number': 'wx****',
          'bank_name': null,
          'is_active': true,
          'is_default': false,
          'created_at': '2026-03-18T12:00:00Z',
          'updated_at': '2026-03-18T12:00:00Z',
        });
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();

      final result = await notifier.addAccount(PaymentAccount(
        id: 'acc_new',
        name: '微信支付',
        type: PaymentType.wechat,
        accountNumber: 'wx****',
        isActive: true,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(result, true);
      expect(notifier.state.accounts.length, 1);
      expect(notifier.state.accounts.first.id, 'acc_new');
    });

    test('addAccount failure: 返回 false，errorMessage 应设置，列表不变', () async {
      final fakeApi = FakeApiService();
      fakeApi.getHandler = (path, {params}) => ApiResult.success([]);
      fakeApi.postHandler = (path, {data, params}) {
        return ApiResult.error('余额不足，无法创建账户');
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();

      final result = await notifier.addAccount(PaymentAccount(
        id: 'acc_fail',
        name: '无效账户',
        type: PaymentType.bank,
        accountNumber: '000',
        isActive: true,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(result, false);
      expect(notifier.state.errorMessage, '余额不足，无法创建账户');
      expect(notifier.state.accounts, isEmpty);
    });

    test('deleteAccount success: 目标账户应从列表移除', () async {
      final fakeApi = FakeApiService();
      final now = DateTime.now();
      final existingAccounts = [
        {
          'id': 'acc_del_001',
          'name': '待删除账户',
          'type': 'bank',
          'account_number': '6222***1234',
          'bank_name': '中国银行',
          'is_active': true,
          'is_default': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ];
      fakeApi.getHandler = (path, {params}) => ApiResult.success(existingAccounts);
      fakeApi.deleteHandler = (path, {data, params}) {
        expect(path, endsWith('acc_del_001'));
        return ApiResult.success({});
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();
      expect(notifier.state.accounts.length, 1);

      final result = await notifier.deleteAccount('acc_del_001');

      expect(result, true);
      expect(notifier.state.accounts, isEmpty);
    });

    test('deleteAccount failure: 返回 false，列表保持不变', () async {
      final fakeApi = FakeApiService();
      final now = DateTime.now();
      fakeApi.getHandler = (path, {params}) => ApiResult.success([
        {
          'id': 'acc_err',
          'name': '出错账户',
          'type': 'bank',
          'account_number': '111',
          'bank_name': null,
          'is_active': true,
          'is_default': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ]);
      fakeApi.deleteHandler = (path, {data, params}) {
        return ApiResult.error('账户已被绑定，无法删除');
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();

      final result = await notifier.deleteAccount('acc_err');

      expect(result, false);
      expect(notifier.state.errorMessage, '账户已被绑定，无法删除');
      expect(notifier.state.accounts.length, 1);
      expect(notifier.state.accounts.first.id, 'acc_err');
    });

    test('updateAccount success: 账户信息应正确更新', () async {
      final fakeApi = FakeApiService();
      final now = DateTime.now();
      fakeApi.getHandler = (path, {params}) => ApiResult.success([
        {
          'id': 'acc_upd',
          'name': '旧名称',
          'type': 'bank',
          'account_number': '1234',
          'bank_name': null,
          'is_active': false,
          'is_default': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ]);
      fakeApi.putHandler = (path, {data, params}) {
        return ApiResult.success({
          'id': 'acc_upd',
          'name': '新名称',
          'type': 'bank',
          'account_number': '5678',
          'bank_name': null,
          'is_active': true,
          'is_default': true,
          'created_at': now.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();

      final updatedAccount = notifier.state.accounts.first.copyWith(
        name: '新名称',
        isActive: true,
        isDefault: true,
      );

      final result = await notifier.updateAccount(updatedAccount);

      expect(result, true);
      expect(notifier.state.accounts.first.name, '新名称');
      expect(notifier.state.accounts.first.isActive, true);
      expect(notifier.state.accounts.first.isDefault, true);
    });

    test('updateAccount failure: 列表保持不变，错误消息设置', () async {
      final fakeApi = FakeApiService();
      final now = DateTime.now();
      fakeApi.getHandler = (path, {params}) => ApiResult.success([
        {
          'id': 'acc_upd_fail',
          'name': '测试账户',
          'type': 'bank',
          'account_number': '1234',
          'bank_name': null,
          'is_active': true,
          'is_default': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ]);
      fakeApi.putHandler = (path, {data, params}) {
        return ApiResult.error('更新失败：权限不足');
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();
      final originalName = notifier.state.accounts.first.name;

      final result = await notifier.updateAccount(
        notifier.state.accounts.first.copyWith(name: '非法名称'),
      );

      expect(result, false);
      expect(notifier.state.errorMessage, '更新失败：权限不足');
      expect(notifier.state.accounts.first.name, originalName);
    });

    test('toggleActive success: 激活状态应取反', () async {
      final fakeApi = FakeApiService();
      final now = DateTime.now();
      fakeApi.getHandler = (path, {params}) => ApiResult.success([
        {
          'id': 'acc_toggle',
          'name': '切换账户',
          'type': 'bank',
          'account_number': '9999',
          'bank_name': null,
          'is_active': true,
          'is_default': false,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
      ]);
      fakeApi.putHandler = (path, {data, params}) {
        return ApiResult.success({
          'id': 'acc_toggle',
          'name': '切换账户',
          'type': 'bank',
          'account_number': '9999',
          'bank_name': null,
          'is_active': false,
          'is_default': false,
          'created_at': now.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      };

      final notifier = PaymentAccountNotifier(fakeApi);
      await notifier.loadAccounts();
      expect(notifier.state.accounts.first.isActive, true);

      final result = await notifier.toggleActive('acc_toggle');

      expect(result, true);
      expect(notifier.state.accounts.first.isActive, false);
    });
  });
}
