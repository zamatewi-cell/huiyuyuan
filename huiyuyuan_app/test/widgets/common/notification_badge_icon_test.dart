import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/widgets/common/notification_badge_icon.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('NotificationBadgeIcon', () {
    testWidgets('hides badge when count is zero', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const NotificationBadgeIcon(
            icon: Icons.notifications_none,
            count: 0,
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows count badge when count is positive', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const NotificationBadgeIcon(
            icon: Icons.notifications_none,
            count: 5,
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('caps displayed count at 99 plus', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const NotificationBadgeIcon(
            icon: Icons.notifications_none,
            count: 120,
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });
  });
}
