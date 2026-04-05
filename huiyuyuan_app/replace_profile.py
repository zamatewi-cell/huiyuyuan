import re

with open('lib/screens/profile/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

reps = {
    "'主题设置'": "ref.tr('theme_settings')",
    "'清除缓存'": "ref.tr('settings_cache_clear')",
    "'包含图片缓存、网络缓存等'": "ref.tr('settings_cache_desc')",
    "'清除后可能需要重新加载部分内容'": "ref.tr('settings_cache_hint')",
    "'确认清除'": "ref.tr('confirm_clear')",
    "'✅ 已清除 ${cacheSize.toStringAsFixed(1)} MB 缓存'": "ref.tr('cache_cleared_tpl').replaceAll('{size}', cacheSize.toStringAsFixed(1))",
    "'汇玉源'": "ref.tr('app_name')",
    "'珠宝玉石全产业链 AI 平台'": "ref.tr('app_slogan')",
    "'区块链溯源 · AI智能鉴定 · 全链路服务'": "ref.tr('app_features')",
    "'合作店铺'": "ref.tr('about_partner')",
    "'鉴定证书'": "ref.tr('about_cert')",
    "'用户数'": "ref.tr('about_users')",
    "'© 2026 汇玉源科技有限公司'": "ref.tr('about_copyright')",
    "'关闭'": "ref.tr('close')",
    "class _ReminderSettingsSheet extends StatefulWidget": "class _ReminderSettingsSheet extends ConsumerStatefulWidget",
    "State<_ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();": "ConsumerState<_ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();",
    "class _ReminderSettingsSheetState extends State<_ReminderSettingsSheet>": "class _ReminderSettingsSheetState extends ConsumerState<_ReminderSettingsSheet>",
    "'提醒设置'": "ref.tr('reminder_settings')",
    "'客户跟进提醒'": "ref.tr('reminder_customer')",
    "'到期自动提醒跟进客户'": "ref.tr('reminder_customer_desc')",
    "'订单状态提醒'": "ref.tr('reminder_order')",
    "'订单状态变更时通知'": "ref.tr('reminder_order_desc')",
    "'每日工作简报'": "ref.tr('reminder_daily')",
    "'每天18:00自动生成'": "ref.tr('reminder_daily_desc')",
    "'AI智能提醒'": "ref.tr('reminder_ai')",
    "'AI分析后推荐跟进客户'": "ref.tr('reminder_ai_desc')",
    "'✅ 提醒设置已保存'": "ref.tr('reminder_saved')",
    "'保存设置'": "ref.tr('save_settings')",
}

for k, v in reps.items():
    content = content.replace(k, v)

with open('lib/screens/profile/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
