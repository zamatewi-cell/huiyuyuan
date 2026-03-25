import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huiyuanyuan/models/payment_account.dart';
import 'package:huiyuanyuan/providers/payment_provider.dart';
import 'package:huiyuanyuan/screens/payment_management_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    const MethodChannel secureStorageChannel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final Map<String, String> store = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
          store[call.arguments['key'] as String] =
              call.arguments['value'] as String? ?? '';
          return null;
        case 'read':
          return store[call.arguments['key'] as String];
        case 'delete':
          store.remove(call.arguments['key'] as String);
          return null;
        case 'deleteAll':
          store.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'containsKey':
          return store.containsKey(call.arguments['key'] as String);
        default:
          return null;
      }
    });

    SharedPreferences.setMockInitialValues({});
  });

  group('PaymentManagementScreen 加载失败提示测试', () {
    testWidgets('加载失败时应显示错误状态和重试按钮', (WidgetTester tester) async {
      final notifier = _LoadingFailsNotifier();
      notifier.state = const PaymentAccountsState(
        state: PaymentLoadingState.error,
        errorMessage: '网络连接失败，请检查网络设置',
        accounts: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentAccountsProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: PaymentManagementScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('网络连接失败，请检查网络设置'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });
  });

  group('PaymentManagementScreen 设置默认账户测试', () {
    testWidgets('设置默认失败时应显示错误 snackbar', (WidgetTester tester) async {
      final now = DateTime.now();
      final account = PaymentAccount(
        id: 'acc_001',
        name: '测试账户',
        type: PaymentType.bank,
        accountNumber: '6222***1234',
        bankName: '测试银行',
        isActive: true,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );

      final notifier = _UpdateFailsNotifier();
      notifier.state = PaymentAccountsState(
        state: PaymentLoadingState.loaded,
        accounts: [account],
        errorMessage: '设置默认失败：服务器错误',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentAccountsProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: PaymentManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('设为默认'));
      await tester.pumpAndSettle();

      expect(find.text('设置默认失败：服务器错误'), findsOneWidget);
    });
  });

  group('PaymentManagementScreen 删除失败 snackbar 测试', () {
    testWidgets('删除失败时应显示错误 snackbar', (WidgetTester tester) async {
      final now = DateTime.now();
      final account = PaymentAccount(
        id: 'acc_001',
        name: '待删除账户',
        type: PaymentType.bank,
        accountNumber: '6222***1234',
        bankName: '测试银行',
        isActive: true,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );

      final notifier = _DeleteFailsNotifier();
      notifier.state = PaymentAccountsState(
        state: PaymentLoadingState.loaded,
        accounts: [account],
        errorMessage: '删除失败：账户正在使用中',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentAccountsProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: PaymentManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('删除').first);
      await tester.pumpAndSettle();

      expect(find.text('确认删除'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('删除'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('删除失败：账户正在使用中'), findsOneWidget);
    });

    testWidgets('删除失败时账户列表应保持不变', (WidgetTester tester) async {
      final now = DateTime.now();
      final account = PaymentAccount(
        id: 'acc_001',
        name: '测试账户',
        type: PaymentType.bank,
        accountNumber: '6222***1234',
        bankName: '测试银行',
        isActive: true,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );

      final notifier = _DeleteFailsNotifier();
      notifier.state = PaymentAccountsState(
        state: PaymentLoadingState.loaded,
        accounts: [account],
        errorMessage: '网络错误',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentAccountsProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: PaymentManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('测试账户'), findsOneWidget);

      await tester.tap(find.text('删除').first);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('删除'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('测试账户'), findsOneWidget);
    });
  });
}

class _LoadingFailsNotifier extends StateNotifier<PaymentAccountsState>
    implements PaymentAccountNotifier {
  _LoadingFailsNotifier() : super(const PaymentAccountsState());

  @override
  Future<void> loadAccounts() async {
    // do nothing - error state already set
  }

  @override
  Future<bool> deleteAccount(String accountId) async => false;

  @override
  Future<bool> updateAccount(PaymentAccount account) async => false;

  @override
  Future<bool> addAccount(PaymentAccount account) async => false;

  @override
  Future<bool> toggleActive(String accountId) async => false;
}

class _UpdateFailsNotifier extends StateNotifier<PaymentAccountsState>
    implements PaymentAccountNotifier {
  _UpdateFailsNotifier() : super(const PaymentAccountsState());

  @override
  Future<void> loadAccounts() async {}

  @override
  Future<bool> deleteAccount(String accountId) async => false;

  @override
  Future<bool> updateAccount(PaymentAccount account) async {
    state = state.copyWith(errorMessage: '设置默认失败：服务器错误');
    return false;
  }

  @override
  Future<bool> addAccount(PaymentAccount account) async => false;

  @override
  Future<bool> toggleActive(String accountId) async => false;
}

class _DeleteFailsNotifier extends StateNotifier<PaymentAccountsState>
    implements PaymentAccountNotifier {
  _DeleteFailsNotifier() : super(const PaymentAccountsState());

  @override
  Future<void> loadAccounts() async {}

  @override
  Future<bool> deleteAccount(String accountId) async {
    state = state.copyWith(errorMessage: '删除失败：账户正在使用中');
    return false;
  }

  @override
  Future<bool> updateAccount(PaymentAccount account) async => false;

  @override
  Future<bool> addAccount(PaymentAccount account) async => false;

  @override
  Future<bool> toggleActive(String accountId) async => false;
}
