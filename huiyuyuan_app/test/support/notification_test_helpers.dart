import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/models/notification_models.dart';
import 'package:huiyuyuan/providers/notification_provider.dart';
import 'package:huiyuyuan/repositories/notification_repository.dart';
import 'package:huiyuyuan/screens/notification/notification_screen.dart';
import 'package:huiyuyuan/widgets/common/notification_badge_icon.dart';

/// Fake repository that returns seed notifications.
class FakeNotificationRepository extends NotificationRepository {
  FakeNotificationRepository(this._items);

  final List<NotificationItem> _items;

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    return _items;
  }

  @override
  Future<bool> markAsRead(String id) async => true;

  @override
  Future<bool> markAllAsRead() async => true;
}

/// Notifier backed by a [FakeNotificationRepository].
class StaticNotificationNotifier extends NotificationNotifier {
  StaticNotificationNotifier(List<NotificationItem> items)
      : super.withDependencies(FakeNotificationRepository(items));
}

// ── Badge assertions ──────────────────────────────────────────────

/// Reads the unread count from the first [NotificationBadgeIcon] on screen.
int notificationBadgeCount(WidgetTester tester, {int index = 0}) {
  return tester.widget<NotificationBadgeIcon>(
    find.byType(NotificationBadgeIcon).at(index),
  ).count;
}

/// Asserts that exactly [count] [NotificationBadgeIcon] widgets exist.
void expectBadgeIcons(WidgetTester tester, int count) {
  expect(find.byType(NotificationBadgeIcon), findsNWidgets(count));
}

/// Asserts that no notification badge icons are visible.
void expectNoBadges(WidgetTester tester) {
  expect(find.byType(NotificationBadgeIcon), findsNothing);
}

// ── Navigation helpers ────────────────────────────────────────────

/// Taps the first "全部已读" button and waits for animations to settle.
/// Supports i18n: tries English "Mark All Read" first, falls back to Chinese.
Future<void> markAllNotificationsAsRead(WidgetTester tester) async {
  final finder = find.text('Mark All Read').evaluate().isEmpty
      ? find.text('全部已读')
      : find.text('Mark All Read');
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens the notification center by tapping a bell icon's GestureDetector ancestor.
/// Works for both admin dashboard and operator home bell icons.
Future<void> openNotificationCenter(WidgetTester tester) async {
  final bellTarget = find.ancestor(
    of: find.byIcon(Icons.notifications_none_rounded),
    matching: find.byType(GestureDetector),
  ).first;
  await tester.tap(bellTarget);
  await tester.pumpAndSettle();
}

/// Taps the back button and waits for the route to pop.
Future<void> goBack(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

/// Returns true if the NotificationScreen is currently mounted.
bool isNotificationScreenVisible(WidgetTester tester) {
  return find.byType(NotificationScreen).evaluate().isNotEmpty;
}

/// Asserts that the notification badge count equals [expected] at the given [index].
void expectBadgeCount(WidgetTester tester, int expected, {int index = 0}) {
  expect(notificationBadgeCount(tester, index: index), expected);
}

/// Simulates the full flow: open notification center → mark all read → go back.
/// Returns true if the flow completed successfully.
Future<bool> simulateMarkAllReadFlow(WidgetTester tester) async {
  try {
    await openNotificationCenter(tester);
    if (!isNotificationScreenVisible(tester)) return false;
    await markAllNotificationsAsRead(tester);
    await goBack(tester);
    return true;
  } catch (_) {
    return false;
  }
}

// ── Factory helpers ───────────────────────────────────────────────

/// Creates a list of unread notifications of the given [type].
List<NotificationItem> unreadNotifications({
  required NotificationType type,
  int count = 3,
  DateTime? baseTime,
}) {
  final now = baseTime ?? DateTime(2026, 4, 5, 12, 0);
  return List.generate(
    count,
    (i) => NotificationItem(
      id: 'test-${type.name}-$i',
      title: '${type.name} 通知 $i',
      body: '这是一条测试通知',
      type: type,
      time: now.subtract(Duration(minutes: i * 5)),
    ),
  );
}

/// Creates a mixed set of read/unread notifications.
List<NotificationItem> mixedNotifications({
  int unread = 2,
  int read = 1,
}) {
  final now = DateTime(2026, 4, 5, 12, 0);
  final items = <NotificationItem>[];
  for (var i = 0; i < unread; i++) {
    items.add(
      NotificationItem(
        id: 'unread-$i',
        title: '未读通知 $i',
        body: '未读内容',
        type: NotificationType.system,
        time: now.subtract(Duration(minutes: i * 10)),
      ),
    );
  }
  for (var i = 0; i < read; i++) {
    items.add(
      NotificationItem(
        id: 'read-$i',
        title: '已读通知 $i',
        body: '已读内容',
        type: NotificationType.system,
        time: now.subtract(Duration(minutes: (unread + i) * 10)),
        isRead: true,
      ),
    );
  }
  return items;
}
