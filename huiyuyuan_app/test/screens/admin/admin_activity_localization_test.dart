import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huiyuyuan/l10n/l10n_provider.dart';
import 'package:huiyuyuan/models/admin_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
    });
  });

  group('Admin activity localization', () {
    testWidgets('English locale prefers key-based activity copy',
        (WidgetTester tester) async {
      const activity = ActivityItem(
        id: 'activity-1',
        tag: '订单',
        tagKey: AdminActivityTags.orders,
        title: '新订单 和田玉手链 x2',
        titleKey: 'admin_activity_title_order_new',
        titleArgs: {
          'name': 'Hetian Jade Bracelet',
          'quantity': 2,
        },
        subtitle: '¥1999',
        subtitleKey: 'admin_activity_subtitle_amount',
        subtitleArgs: {
          'amount': '¥1999',
        },
        time: '2026-04-04T10:00:00',
        color: '#10B981',
        icon: 'shopping_bag',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _AdminActivityTextHarness(activity: activity),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('New order Hetian Jade Bracelet x2'), findsOneWidget);
      expect(find.text('¥1999'), findsOneWidget);
      expect(find.text('订单'), findsNothing);
      expect(find.text('新订单 和田玉手链 x2'), findsNothing);
    });

    testWidgets('Falls back to raw activity copy when keys are absent',
        (WidgetTester tester) async {
      const activity = ActivityItem(
        id: 'activity-2',
        tag: 'Custom',
        title: 'Fallback title',
        subtitle: 'Fallback subtitle',
        time: '2026-04-04T10:00:00',
        color: '#10B981',
        icon: 'info',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _AdminActivityTextHarness(activity: activity),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Fallback title'), findsOneWidget);
      expect(find.text('Fallback subtitle'), findsOneWidget);
    });
  });
}

class _AdminActivityTextHarness extends ConsumerWidget {
  const _AdminActivityTextHarness({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_activityTagLabel(ref, activity)),
        Text(_activityText(
          ref,
          fallback: activity.title,
          key: activity.titleKey,
          args: activity.titleArgs,
        )),
        Text(_activityText(
          ref,
          fallback: activity.subtitle,
          key: activity.subtitleKey,
          args: activity.subtitleArgs,
        )),
      ],
    );
  }

  String _activityTagLabel(WidgetRef ref, ActivityItem activity) {
    if (AdminActivityTags.localizedKeys.contains(activity.resolvedTagKey)) {
      return ref.tr(activity.resolvedTagKey);
    }
    return activity.tag;
  }

  String _activityText(
    WidgetRef ref, {
    required String fallback,
    String? key,
    Map<String, Object?>? args,
  }) {
    if (key == null || key.isEmpty) {
      return fallback;
    }
    return ref.tr(key, params: args ?? const {});
  }
}
