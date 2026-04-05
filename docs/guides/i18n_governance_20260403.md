# 汇玉源多语言治理规范

目标：把多语言从“页面碰到哪里补哪里”改成“有统一词典、统一调用方式、统一发布检查”的工程化流程。

## 当前结论

- `app_name`、`theme_settings`、`order_list_title` 这类 key 直接显示在页面上，核心原因不是页面没接国际化，而是页面代码和词典文件发布不同步。
- 英文模式下仍出现中文，主要有两类来源：
  - UI 侧把中文原文直接当 key 使用，例如 `'订单总数'.tr`
  - 数据侧直接存中文原值，例如默认用户名 `用户xxxx`、商品分类和商品名原值中文
- 顶层假数据如果在文件加载时直接 `.tr`，会把文案冻结在启动语言，切换语言后不会自动更新。

## 强制规则

1. 页面层只能使用稳定 key。
   - 允许：`ref.tr('profile_total_orders')`
   - 不允许：`'订单总数'.tr`

2. Widget 中统一使用 `ref.tr(...)`。
   - `StringExtension.tr` 只保留给模型层或无 `WidgetRef` 的纯逻辑层。
   - UI 页面不要再混用中文原文 `.tr`。

3. 数据层不能预先翻译。
   - `lib/data/`、种子数据、模型默认值里不要在顶层直接 `.tr`
   - 要么存 canonical 值，再在渲染层翻译
   - 要么存完整多语言字段，例如 `name_en / name_zh_tw`

4. 新增 key 必须同一提交内补齐三种语言。
   - `zhCN`
   - `en`
   - `zhTW`

5. 安全发布 Web 时，词典文件属于核心发布面，不能再被遗漏。
   - `lib/l10n/app_strings.dart`
   - `lib/l10n/l10n_provider.dart`
   - `lib/l10n/string_extension.dart`
   - `lib/l10n/translator_global.dart`
   - 以及本次页面新增的 copy/helper 文件

## 发布前必跑

1. `flutter test test/l10n/i18n_guard_test.dart`
2. `dart run tool/i18n_audit.dart`
3. `flutter analyze --no-fatal-infos`
4. Web 发布前切换三种语言做最少人工冒烟：
   - 登录页
   - 商城页
   - 我的订单
   - 个人页

## 分阶段治理

### 第一阶段：阻断继续变乱

- 保证词典 key 完整
- 保证页面不再直接露 key
- 修掉关键路径上的中文原文 `.tr`

### 第二阶段：清理历史包袱

- 逐步替换 `lib/screens/`、`lib/widgets/` 中的中文原文 `.tr`
- 清理 `lib/data/` 顶层 `.tr`
- 给商品、店铺、用户默认名补 canonical 值或多语言字段

### 第三阶段：数据层企业化

- 商品名、分类、材质、店铺名、默认用户名从“中文原值 + 兜底翻译”过渡到“结构化多语言字段”
- 后端 seed 数据同步补齐 `*_en`、`*_zh_tw`

## 本次新增守门工具

- 测试：`test/l10n/i18n_guard_test.dart`
  - 校验三种语言 key 集合完全一致
  - 校验代码里引用的 identifier-style key 都存在于词典

- 审计脚本：`tool/i18n_audit.dart`
  - 输出缺失 key
  - 输出 UI 层中文原文 `.tr` 警告
  - 输出 `lib/data/` 顶层 `.tr` 警告
