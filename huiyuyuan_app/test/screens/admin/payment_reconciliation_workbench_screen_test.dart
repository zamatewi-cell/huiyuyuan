import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/models/user_model.dart';
import 'package:huiyuyuan/providers/auth_provider.dart';
import 'package:huiyuyuan/screens/admin/payment_reconciliation_workbench_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UserModel operatorWithPermissions(List<String> permissions) => UserModel(
        id: 'operator-1',
        username: 'Operator 01',
        phone: '13800138000',
        userType: UserType.operator,
        isActive: true,
        operatorNumber: 1,
        permissions: permissions,
      );

  setUp(() {
    ApiConfig.useMockApi = true;
  });

  tearDown(() {
    ApiConfig.useMockApi = false;
  });

  Future<void> pumpWorkbench(
    WidgetTester tester, {
    required UserModel user,
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => user),
        ],
        child: const MaterialApp(
          home: PaymentReconciliationWorkbenchScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  testWidgets('payment reconcile permission can confirm payments', (
    tester,
  ) async {
    await pumpWorkbench(
      tester,
      user: operatorWithPermissions(['payment_reconcile']),
    );

    expect(find.text('支付对账'), findsWidgets);
    expect(find.textContaining('pay_demo_001'), findsOneWidget);
    expect(find.text('确认到账'), findsWidgets);
    expect(find.text('标记异常'), findsNothing);

    await tester.tap(find.text('确认到账').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认').last);
    await tester.pumpAndSettle();

    expect(find.text('已确认到账'), findsOneWidget);
  });

  testWidgets('exception permission can flag payment exceptions only', (
    tester,
  ) async {
    await pumpWorkbench(
      tester,
      user: operatorWithPermissions(['payment_exception_mark']),
    );

    expect(find.text('支付对账'), findsWidgets);
    expect(find.text('确认到账'), findsNothing);
    expect(find.text('标记异常'), findsOneWidget);

    await tester.tap(find.text('标记异常'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '凭证金额不一致');
    await tester.tap(find.text('确认').last);
    await tester.pumpAndSettle();

    expect(find.text('已标记支付异常'), findsOneWidget);
    expect(find.textContaining('凭证金额不一致'), findsOneWidget);
  });

  testWidgets('operators without payment permissions are blocked', (
    tester,
  ) async {
    await pumpWorkbench(
      tester,
      user: operatorWithPermissions(['orders']),
    );

    expect(find.text('当前操作员没有此功能权限，请联系管理员开通。'), findsOneWidget);
    expect(find.textContaining('需要支付对账或异常标记权限'), findsOneWidget);
  });
}
