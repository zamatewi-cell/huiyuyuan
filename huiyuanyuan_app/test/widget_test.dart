// 汇玉源珠宝智能交易平台 - 基础测试
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:huiyuanyuan/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // 构建应用
    await tester.pumpWidget(
      const ProviderScope(
        child: HuiYuYuanApp(),
      ),
    );

    // 等待页面加载
    await tester.pump();

    // 验证基本内容显示
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
