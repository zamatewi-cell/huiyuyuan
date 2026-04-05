import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/models/user_model.dart';
import 'package:huiyuyuan/providers/auth_provider.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';
import 'package:huiyuyuan/screens/profile/profile_screen.dart';
import 'package:huiyuyuan/services/order_service.dart';
import 'package:huiyuyuan/widgets/common/notification_badge_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/notification_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final customerUser = UserModel(
    id: 'customer-1',
    username: 'Customer 01',
    phone: '13800138000',
    userType: UserType.customer,
  );

  Future<void> pumpProfileScreen(
    WidgetTester tester, {
    required NotificationNotifier notifier,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => customerUser),
          notificationProvider.overrideWith((ref) => notifier),
          orderLoadedProvider.overrideWith((ref) => true),
          orderStatsProvider.overrideWith(
            (ref) => {
              'total': 0,
              'totalAmount': 0.0,
              'pending': 0,
              'paid': 0,
            },
          ),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('ProfileScreen reminders', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
      'opens notification center from reminder sheet and clears badge after mark all read',
      (tester) async {
        final notifier = StaticNotificationNotifier([
          NotificationItem(
            id: 'notification-1',
            title: 'Order shipped',
            body: 'Your order has been shipped.',
            type: NotificationType.order,
            time: DateTime(2026, 4, 4, 12, 0),
          ),
          NotificationItem(
            id: 'notification-2',
            title: 'Promotion update',
            body: 'A new campaign is now live.',
            type: NotificationType.promotion,
            time: DateTime(2026, 4, 4, 12, 1),
          ),
        ]);

        await pumpProfileScreen(tester, notifier: notifier);

        expect(notificationBadgeCount(tester), 2);

        await tester.scrollUntilVisible(
          find.byType(NotificationBadgeIcon).first,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final reminderEntry = find.ancestor(
          of: find.byType(NotificationBadgeIcon).first,
          matching: find.byType(GestureDetector),
        ).first;
        await tester.tap(reminderEntry);
        await tester.pumpAndSettle();

        expect(find.byType(OutlinedButton), findsOneWidget);

        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();

        expect(find.text('Order shipped'), findsWidgets);
        expect(find.text('Promotion update'), findsWidgets);

        await markAllNotificationsAsRead(tester);

        expect(notifier.unreadCount, 0);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();

        expect(notificationBadgeCount(tester), 0);
      },
    );
  });
}
