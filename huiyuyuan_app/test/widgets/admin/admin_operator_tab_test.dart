import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/widgets/admin/admin_operator_tab.dart';

void main() {
  testWidgets('AdminOperatorTab switches selected operator details', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0D1B2A),
          body: AdminOperatorTab(),
        ),
      ),
    );

    expect(find.text('Operator Performance'), findsOneWidget);
    expect(find.text('OP-01'), findsOneWidget);
    expect(find.text('Operator 01'), findsNWidgets(2));
    expect(find.text('Wholesale recovery and repeat buyers'), findsOneWidget);
    expect(find.text('CNY 8,560'), findsOneWidget);

    await tester.tap(find.text('OP-03'));
    await tester.pumpAndSettle();

    expect(find.text('OP-03'), findsOneWidget);
    expect(find.text('Operator 03'), findsNWidgets(2));
    expect(find.text('VIP conversion and high-ticket orders'), findsOneWidget);
    expect(find.text('CNY 18,900'), findsOneWidget);
  });
}
