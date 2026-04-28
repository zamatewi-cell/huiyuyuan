import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/config/api_config.dart';
import 'package:huiyuyuan/widgets/admin/admin_operator_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiConfig.useMockApi = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    ApiConfig.useMockApi = false;
  });

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: Color(0xFF0D1B2A),
            body: AdminOperatorTab(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('AdminOperatorTab shows account management copy in Chinese', (
    tester,
  ) async {
    await pumpTab(tester);

    expect(find.text('操作员业绩'), findsOneWidget);
    expect(find.text('操作员账号管理'), findsOneWidget);
    expect(find.text('权限管理'), findsOneWidget);
    expect(find.text('一键套用常用角色模板，再按需微调权限。'), findsOneWidget);
    expect(find.text('标准操作员'), findsOneWidget);
    expect(find.text('巡店员'), findsOneWidget);
    expect(find.text('跟单员'), findsOneWidget);
    expect(find.text('库存员'), findsOneWidget);
    expect(find.text('店长/主管'), findsOneWidget);
    expect(find.text('当前模板：标准操作员'), findsOneWidget);
  });

  testWidgets('AdminOperatorTab applies role templates and detects custom mode',
      (tester) async {
    await pumpTab(tester);

    await tester.ensureVisible(find.text('跟单员'));
    await tester.tap(find.text('跟单员'));
    await tester.pumpAndSettle();

    expect(find.text('当前模板：跟单员'), findsOneWidget);

    await tester.ensureVisible(find.text('智能巡店'));
    await tester.tap(find.text('智能巡店'));
    await tester.pumpAndSettle();

    expect(find.text('当前模板：自定义权限'), findsOneWidget);
  });

  testWidgets('AdminOperatorTab saves the current permissions as a template', (
    tester,
  ) async {
    await pumpTab(tester);

    await tester.ensureVisible(find.text('库存员'));
    await tester.tap(find.text('库存员'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('保存为模板'));
    await tester.tap(find.text('保存为模板'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '夜班对账员');
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(find.text('夜班对账员'), findsWidgets);
    expect(find.text('当前模板：夜班对账员'), findsOneWidget);
  });

  testWidgets('AdminOperatorTab renames and deletes saved templates', (
    tester,
  ) async {
    await pumpTab(tester);

    await tester.ensureVisible(find.text('库存员'));
    await tester.tap(find.text('库存员'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('保存为模板'));
    await tester.tap(find.text('保存为模板'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '夜班对账员');
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重命名'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '夜班复核员');
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    expect(find.text('夜班复核员'), findsWidgets);
    expect(find.text('当前模板：夜班复核员'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除模板'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, '删除'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('夜班复核员'), findsNothing);
  });
}
