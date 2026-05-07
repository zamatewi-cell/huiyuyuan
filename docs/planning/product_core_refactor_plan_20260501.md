# 汇玉源核心重构计划 v1（2026-05-01）

> 起草日期：2026-05-01
> 适用范围：在 `docs/cursor_development_handoff_20260501.md` 的 review 基础上，做更深一层的工程与产品重构计划。
> 立场：暂缓真实第三方支付，优先重塑产品骨架与系统潜在坍塌点；让"鉴赏 + 信任 + 顾问"压过"商品列表 + 下单"的小程序惯性。
> 这是一份会被开发执行的工作蓝图，不是宣传稿。所有结论都要能在代码里指到具体行。

---

## 0. 思考前提与基调

1. **现在不是写新功能，是修地基。** 系统里有几条潜在的反模式（最严重的是语言切换实现），如果不先修，再多产品改造也守不住。
2. **三条主轴必须并行**：
   - 工程地基修复（i18n / 后端乱码 / 测试支付保护 / 项目噪音）。
   - 产品叙事重构（首页 / 一物一档 / AI 顾问 / 后台驾驶舱）。
   - Cursor 续开发交接稳定性（规则、MCP、索引忽略）。
3. **不接入真实第三方支付**，但要给"人工凭证 + 后台确认"模式补齐风控边界，让它在生产里跑得住。
4. **先小步、先有验收口径，再放规模。** 头部 30 个商品先走通"一物一档"，确认产品观感站起来后再批量补料。

---

## 1. Review 增量发现（在 handoff 风险表上的补充）

### 1.1 P0 新增：语言切换是系统级反模式（用户特别提示，已实证）

> 详细说明，因为这是一处会拖累后续所有产品改造的地基坑。

**问题 1：`MaterialApp` 用 `key: ValueKey(settings.language)` 作弊式刷新整树**

`huiyuyuan_app/lib/app/huiyuyuan_app.dart:69-87` 中：

- `MaterialApp(key: ValueKey(settings.language), ...)` 一旦 language 变化，Flutter 把整个 MaterialApp 子树 dispose 重建。
- 直接副作用：
  - **导航栈被销毁**：用户在"我的 → 设置 → 语言"里切换，会被强制弹回 `AppRouter` 的初始判断分支；正在打开的商品详情、购物车、订单详情全部丢失。
  - 进行中的 Dialog / SnackBar / Hero 动画被中断。
  - 所有不在 Riverpod 中的临时状态（TextEditingController、TabController、Form 草稿、Scroll offset）被重置。
  - 在已登录的设备上切换语言可能短暂闪回登录页或隐私协议页（取决于 `AppRouter` 的判断顺序）。
- 这是因为下层翻译机制无法响应式刷新，所以用整树重建作弊。属于"用炸药拆图钉"。

**问题 2：项目里有三套并行的翻译机制，互相冲突**

| 机制 | 入口 | 是否响应式 | 典型用法 |
|------|------|-----------|---------|
| Riverpod 翻译 | `lib/l10n/l10n_provider.dart` 的 `tProvider` / `WidgetRef.tr()` | 是（依赖 `appSettingsProvider`） | `ref.tr('home_hot')` |
| 静态全局翻译 | `lib/l10n/string_extension.dart` 的 `String.tr` 走 `TranslatorGlobal.currentLang` 静态变量 | **否**（仅靠 MaterialApp 重建作弊才能刷新） | `'order_paid'.tr` |
| 内联多语言 helper | `lib/screens/trade/product_list_screen.dart:43` 的 `_copyByLanguage(language, zhCN: ..., en: ..., zhTW: ...)` | 是（仅当外层 widget 读了 `language`） | 仅此一处页面 |

第二套机制是问题根源：`String.tr` 读静态全局，widget 自己不会订阅 `appSettingsProvider`，所以单纯靠 Riverpod 通知是刷不掉的，只能靠 MaterialApp 整树重建。这就是为什么 `huiyuyuan_app.dart` 必须挂 `key: ValueKey`。

**问题 3：商品模型读静态全局算"本地化标题"**

`lib/models/product_model.dart`：

```dart
String get titleL10n => localizedTitleFor(TranslatorGlobal.currentLang);
String get descL10n => localizedDescriptionFor(TranslatorGlobal.currentLang);
String get matL10n => localizedMaterialFor(TranslatorGlobal.currentLang);
```

被 14+ 个文件直接调用（`order_detail_screen`、`cart_screen`、`product_list_screen`、`profile/favorite_list_screen`、`widgets/admin/admin_product_management_tab` 等）。这些 widget 自身不订阅 `appSettingsProvider`，依赖整树重建。

**问题 4：`_parseLanguage` 静默回落**

`lib/providers/app_settings_provider.dart:103-125`：

- `'fr'`、`'ja'`、`'ko'` 等系统 locale 全部静默回落为 `zh-CN`，对国际访客不友好。
- `'en-Us'` 命中（特殊大小写组合），但 `'en-us'`、`'EN_US'` 不命中（switch 大小写敏感）。
- 没有任何告警日志，难以排查。

**问题 5：4000+ 行手写 Map，无 ARB，无 lint，无 key diff**

`lib/l10n/app_strings.dart` 三套语言 map（zhCN/en/zhTW）共约 4000 行。缺失 key 时 `lookup` 会回落到 `key` 字符串本身——用户会直接看到 `home_promotion_subtitle` 这种字面量。`_zhCNLegacyCompatibility` 等三个 legacy map 全为空（lib/l10n/app_strings.dart:4110-4114），是死代码。

**问题 6：`ProductTranslator` 的字符级"拼接式翻译"质量不稳**

`lib/l10n/product_translator.dart` 1300+ 行，里面：

- 中转繁体：手写 70+ 字 / 90+ 短语对照表，按长度排序后逐条 replaceAll。未覆盖的简体字直接保留（详情页里就会出现简繁混杂）。
- 中转英文：用关键词词典对中文词做 replaceAll，得到机翻味浓的英文（"龙凤呈祥"被逐词替换会生成奇怪字符串）。
- 这是商品名 / 描述切到 zh-TW 或 en 时观感拙劣的根因。

**问题 7：后端没有为不同语言返回内容**

订单提示、推送标题、AI 回复都在前端 / 全语言用同一份中文字符串，再用 `ProductTranslator` 反向拼接出英文 / 繁体。可信度很低，且没有 fallback 治理。

---

### 1.2 P0 新增：后端 `orders.py` 编码损坏远不止个别字段

`grep` 出 35 处乱码错误提示（GBK 解码后的 mojibake），覆盖：

- `handle_database_error(db, "璇诲彇璁㈠崟鍒楄〃", ...)` 等 9 处（"读取订单列表"等被 GBK→UTF-8 错码的产物）。
- `raise HTTPException(... detail=f"鍟嗗搧 {product.name} 搴撳瓨涓嶈冻 ...")` 等下单/库存提示 2 处。
- 物流提示 `"鎮ㄧ殑璁㈠崟宸插彂璐э紝{carrier} 杩愬崟鍙?{tracking}"` 1 处。
- 注释 `# 浣跨敤鏀粯鏈嶅姟鍒涘缓璁板綍` 等。

任何用户在 PostgreSQL 异常时会直接收到这种字符串；同时严重污染 systemd 日志。`grep` 同样模式在 `backend/main_v3_backup.py` 也存在（备份文件，删掉即可）。

---

### 1.3 P0 新增：商品数据模型不支撑"一物一档"

`ProductModel`（`lib/models/product_model.dart:617-647`）当前只有：

| 字段 | 是否有 |
|------|------|
| 主图 `images` | 有（一组 URL） |
| 证书号 `certificate` | 有（仅 ID） |
| 区块链溯源 `blockchainHash` | 有（仅 hash） |
| 产地 `origin` | 有（短字符串） |
| 材质鉴定 `materialVerify` | 有（"天然 A 货"等枚举） |
| 一句话鉴赏理由 | **没有** |
| 适合人群 / 场景标签 | **没有** |
| 检测机构名（NGTC / GIA / 国检） | **没有** |
| 证书图片 / 证书查验链接 | **没有** |
| 工艺亮点（雕工 / 镶嵌 / 抛光） | **没有** |
| 来源故事（矿坑 / 师傅 / 选料） | **没有** |
| 自然瑕疵 / 包浆 / 皮色 | **没有** |
| 多角度图（细节微距 / 上手图） | **没有**（统一塞 `images`） |

直接做"一物一档"页面会缺数据，必须先补 schema + DB migration + 头部商品种子数据。

---

### 1.4 P1 新增：AI 与商品脱节

- `AIProductContextService.buildProductContext` 加载全部商品按材质拼成 prompt（`lib/services/ai_product_context_service.dart`），但页面级"问这件商品"没有专门入口。
- 商品详情、结算页、图片识别后没有 deep link 把 `productId` 带进 `AIAssistantScreen`。
- `gemini_image_service.dart` 类名保留旧实现，新人接手会误以为还在用 Gemini，应改为 `image_recognition_service.dart` 或在文件头加显式说明。

---

### 1.5 P1 新增：人工支付的安全边界还没拉好

- `backend/routers/payments.py:150` `if amount == 0.01: ...` 自动确认逻辑在生产/测试一并生效；任何 0.01 真实订单（巧合或恶意构造）都会被自动确认。
- `backend/routers/orders.py:647` `f"https://pay.example.com/{order_id}"` 占位 URL 直接被前端拉去渲染 / 跳转。Web 端上有人复制错链路会跳错域名。
- 所有外部文案没有显式说明"当前为人工凭证模式"，用户可能误以为是真实自动支付，到时候出现售后纠纷。

---

### 1.6 P1 新增：根目录视觉素材噪音

- handoff 已经记录约 212 个根目录 PNG（Git 跟踪 PNG 约 331 个），实测 `cursor` 打开仓库索引时间被显著拖慢；`grep` 命中范围更大；`git status` 显得脏。
- 这不是品味问题，是工程效率问题——一个新加入的开发者面对杂乱根目录会先丢掉对项目的信任。

---

## 2. 重构方向（产品 + 工程并行）

### 2.1 工程地基修复（P0，必须最先做）

#### 2.1.1 i18n 引擎重构（最核心、最迫切）

**方案对比**：

| 方案 | 描述 | 成本 | 推荐度 |
|------|------|------|--------|
| A | 全面切到 `flutter_localizations` + `intl` + ARB 生成 | 高（重写 4000+ key 调用，但有 IDE 支持、复数处理） | 长期方向 |
| B | 保留 zh/en/zhTW 三套 Map，但全部走 Riverpod 化、移除 MaterialApp 整树重建作弊 | 中（重写翻译入口，逐文件清理 `String.tr`） | **推荐先做 B，再向 A 演进** |
| C | 引入 `easy_localization` 第三方包 | 引入新依赖、key 管理与现有不一致 | 不推荐 |

**推荐路径（B + 后续向 A 靠拢）**：

1. **重写 `String.tr` 扩展**：把它改成"基于 `LocalizationScope` InheritedWidget 注入"的语言读取，而不是读 `TranslatorGlobal.currentLang` 静态全局。或者直接弃用这个扩展，强制所有调用点改用 `ref.tr('key')`。
2. **`ProductModel` 去掉 `titleL10n` / `descL10n` / `matL10n` getter**：所有调用点必须显式传 `AppLanguage`（从 widget 中 `ref.watch(appSettingsProvider).language` 拿）。这样 widget 才会真正订阅语言变化。
3. **移除 `MaterialApp` 的 `key: ValueKey(settings.language)`**：让所有 widget 通过 Riverpod 自然刷新。
4. **修复 `_parseLanguage`**：
   - 不识别的 code 不要静默回落，加 `assert` + `debugPrint`。
   - 大小写不敏感匹配（`code.toLowerCase().replaceAll('-', '_')` 后再 switch）。
   - 接受 system locale 作为首选 fallback，再到 zhCN。
5. **删除或填充 `legacyCompatibility*` 三个空 map**（建议直接删，简化代码）。
6. **`ProductTranslator` 降级为"仅展示用"**：
   - 短期：保持现状，但加 `assert` 检测拼出来的英文是否包含中文字符；包含则记日志。
   - 中期：把"一物一档"新字段（appraisalNote / craftHighlights / originStory 等）改成 backend 返回三语 → 前端只取对应语言字段，**不再拼接**。
   - 老字段（name / description）继续用 ProductTranslator 兜底，但目标是 6 个月内迁完。
7. **新增 `tool/lint_i18n.dart`**：
   - 扫描 `lib/screens/**/*.dart` 与 `lib/widgets/**/*.dart`。
   - 规则：
     - 禁止 `Text('裸中文')`、`Text("裸中文")`。
     - 禁止 `_copyByLanguage` 这种内联 inline helper。
     - 禁止 `String.tr` 调用（强制 `ref.tr`）。
     - 报告 `app_strings.dart` 三套 map 的 key 差集。
   - 接入 `verify-quality` workflow（`.agent/workflows/verify-quality.md`）和 `flutter test` 之外的 CI 步骤。
8. **验收**：
   - `flutter run -d chrome`，依次进入：登录页、首页、商品详情、购物车、结算、订单详情、AI 助手、设置；在每个页面切 zh-CN ↔ en ↔ zh-TW。
   - 导航栈不丢，文案立刻刷新，没有看到 raw key（如 `home_hot` 这种）。
   - `flutter test`、`flutter analyze` 全绿。
   - `dart run tool/lint_i18n.dart` 0 issue。

**回退策略**：保留 feature flag `AppConfig.useLegacyLocaleRebuild`（dart-define 控制），出问题时一行开关回到旧行为。

#### 2.1.2 后端 `orders.py` 乱码全量修复

1. 把 `orders.py` 中 35 处乱码字符串全部改为 UTF-8 中文（如 "璇诲彇璁㈠崟鍒楄〃" → "读取订单列表失败"）。
2. 同步删除 `backend/main_v3_backup.py`（备份文件，已不再用）。
3. **更进一步**：把 `handle_database_error` 改为接 `error_code: str` 而不是中文字面量；前端按 `error_code` 自己本地化。短期可只改 UTF-8。
4. **新增 sanity test**（`backend/tests/test_no_mojibake.py`）：
   - 遍历 `backend/routers/*.py` 与 `backend/services/*.py`。
   - 用正则匹配典型 GBK-mojibake 字符段（如 `[\u9526-\u9556][\u8000-\u8FFF]`），命中即 fail。
5. 验收：
   - `python -m pytest backend/tests/test_no_mojibake.py -v` 全绿。
   - 故意在 dev 环境造一次 DB 异常，前端拿到的 detail 是清晰中文。

#### 2.1.3 测试支付保护

`backend/routers/payments.py:150` 改为：

```python
auto_confirm_eligible = (
    amount == 0.01
    and config.APP_ENV != "production"
    and payment_method in {"test_alipay", "test_wechat"}
    and order.get("is_test_order") is True
)
if auto_confirm_eligible and record:
    ...
```

`backend/routers/orders.py:647` 占位 URL 改为：

```python
return {
    "success": True,
    "order_id": data.get("order_id"),
    "payment_url": None,
    "payment_mode": "manual_voucher",
    "message": "请在订单详情中查看人工确认收款方式",
}
```

前端 `OrderRepository` 识别 `payment_url is None` 时不再展示"打开支付链接"按钮。

新增 pytest：

- 生产 APP_ENV 下，amount=0.01 不允许走自动确认。
- 非测试 payment_method 不走自动确认。

#### 2.1.4 ProductModel 扩展（schema + migration + 种子数据）

目标字段（**全部 nullable**，向后兼容）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `appraisal_note` / `appraisal_note_en` / `appraisal_note_zh_tw` | `String?`，≤ 60 字 | 一句话鉴赏理由 |
| `audience_tags` / `audience_tags_en` / `audience_tags_zh_tw` | `List<String>?` | 送礼 / 自戴 / 收藏 / 入门 / 进阶 |
| `craft_highlights_*` | `List<String>?` | 雕工、镶嵌、抛光、打磨 |
| `origin_story_*` | `String?`，多 paragraph | 产地故事、矿坑、师傅 |
| `flaw_notes_*` | `List<String>?` | 自然瑕疵、包浆、皮色（突出诚实） |
| `certificate_authority` / `certificate_authority_en` / `certificate_authority_zh_tw` | `String?` | NGTC / GIA / 国检 |
| `certificate_image_url` | `String?` | 证书图片 |
| `certificate_verify_url` | `String?` | 官方查验链接 |
| `gallery_detail` | `List<String>?` | 微距图 |
| `gallery_hand` | `List<String>?` | 上手图 |

> 状态校准（2026-05-05）：字段契约已补齐到 backend schema/router、Alembic、seed upsert、Flutter `ProductModel` / `ProductUpsertRequest`；`craft_highlights` 已升级为三语 `List<String>`，并兼容旧换行文本自动拆分。头部 30 件已补 `audience_tags`、`origin_story`、`flaw_notes`、`certificate_authority` 文本内容并同步 `product_seed_generated.dart`；证书图片、官方查验链接、微距图、上手图因缺真实资产仍保持空值，因此只能按"数据契约 + 文本档案骨架"验收，不能按完整图文"一物一档"体验验收。

落地步骤：

1. 修改 `backend/schemas/product.py`、`backend/models/product.py`、Pydantic schema。
2. 写 Alembic migration `add_curation_fields_to_products.py`（全部允许 NULL）。
3. 修改前端 `lib/models/product_model.dart` 加对应字段 + `fromJson` / `toJson`。
4. 头部 30 个高曝光商品手工补完整内容（运营手动 / 写一次性 seed）；其他商品默认空，详情页对未补字段做"待补内容"灰显或隐藏，**不要硬假装**。
5. 验收：30 个商品的详情页能把"一物一档"骨架填满。

#### 2.1.5 根目录 PNG 治理

1. `New-Item docs/reference/visual_archive` 创建归档目录。
2. 用 PowerShell 脚本批量 `git mv *.png docs/reference/visual_archive/`，但保留：
   - `huiyuyuan_app/assets/**`（运行时资源）。
   - 必要的 `favicon.ico`、APK / Web build 输出。
3. 全文 grep 一遍 markdown 中对这些 PNG 的相对路径引用，同步改路径。
4. `.gitignore` 增加 `*.bmp`、`temp_*.png`、`screenshot_*.png` 等噪音前缀。
5. 新建 `.cursorindexignore`：把 `docs/reference/`（含 visual_archive）、`build/`、`.dart_tool/` 排除出 Cursor 索引。
6. 验收：`git ls-files '*.png' | wc -l` 从 ~331 降到 < 50；Cursor 打开仓库索引时间显著缩短。

---

### 2.2 产品叙事重构（P0 / P1）

#### 2.2.1 首页：从"分类商品流"到"鉴赏入口"

策略：不动 `ProductListScreen`，把它降级为底部 Tab 中的"全部商品"；新建 `HomeCurationScreen` 作为 Tab 1 / 主入口。

骨架（自顶向下）：

| 模块 | 内容 | 数据来源 |
|------|------|---------|
| Hero 卡 | 今日甄选 1 件，大图 + 一句话鉴赏 + 鉴宝师/创始人短评 | `appraisal_note` + 后台运营手选 |
| 本周入库 | 横向滑动 5–10 件，每张只展示鉴赏理由，不强调促销 | `is_new` + 时间排序 |
| 材质百科 | 6 张卡片：翡翠 / 和田玉 / 南红 / 蜜蜡 / 蜜珀 / 银饰 | 静态内容，可后续接 CMS |
| 鉴宝助理今日值班 | 圆角 CTA，点击带入 prompt"我想了解今天值得看的" | AIAssistantScreen 新入参 |
| 信任带 | 证书机构 / 区块链溯源 / 三天无理由 / 人工客服 | 静态 |

**删除项**：`PromotionalBanner` 降级到次要位置或仅在"全部商品"展示。

#### 2.2.2 商品详情：从"电商详情"到"一物一档"

重构后骨架：

1. **沉浸主图**：主图 + 自动切到细节微距 + 上手图（随手势横滑）。
2. **一句话鉴赏**（`appraisal_note`），加引号样式，做配色。
3. **信任卡片**：证书号 + 检测机构 + 区块链溯源 + 实拍图（点击放大）+ 官方查验链接（外跳）。
4. **材质与工艺**：`craft_highlights` chip 组 + 材质百科链接。
5. **来源故事**（`origin_story`）：纸张纹理背景，多 paragraph。
6. **适合谁**：`audience_tags` chip 组（送礼 / 自戴 / 收藏 / 入门 / 进阶）。
7. **自然特征 / 瑕疵**（`flaw_notes`）：突出诚实性，是奢品平台的关键差异。
8. **沉浸 AI**：底部 sticky bar"帮我看懂这件" → 跳 `AIAssistantScreen` 带 `productId` + 商品上下文。
9. **价格 + 下单**：放到信息消化之后；CTA 用"加入私室 / 加入鉴赏"代替"加入购物车"。
10. **评价 + 同材质**：底部。

#### 2.2.3 AI 从聊天页升级为顾问能力

落地点：

- `AIAssistantScreen` 增加可选入参 `productId` / `productContext`；进入时若有，则首条消息是 AI 主动开口 "您正在看这件 {product.name}，我可以帮您聚焦：来源 / 工艺 / 适合人群 / 比价。"
- 商品详情页底部 CTA "帮我看懂这件"。
- 结算页 `CheckoutScreen` 加快捷气泡："这件适合送什么人"。
- 图片识别页：识别完成后引导跳转"找类似的"（按材质 + 价位 query 进 SearchScreen）。
- 客服 / 管理后台：新增"AI 回复建议"小卡，把订单 + 凭证上下文喂给模型，运营人员一键采纳到回复输入框。
- **数据安全**：发送给 DashScope 的上下文不要包含手机号、地址、IP；把 `_buildSafeContext` 抽成统一的 prompt 装配入口。

#### 2.2.4 后台从"功能集合"到"运营驾驶舱"

`AdminDashboard` 顶部 4 张状态卡（点击直跳工作台）：

| 卡片 | 数据源 | 颜色提示 |
|------|--------|---------|
| 待人工确认到账 | `payments` 表 status=awaiting_confirmation 计数 | 蓝色 |
| 待发货订单 | `orders` 表 status=paid 计数 | 翠绿 |
| 库存异常 | `products` stock <= 1 或最近 24h 售出 / 总库存 > 0.5 | 香槟金 |
| 高价值订单 / 争议支付 | `orders.total_amount > 5000` 或 `payments.status=disputed` 计数 | 红色 |

下面接"今日待办" timeline，按时间倒序聚合最近 24h 的：新订单、上传凭证、争议、退款、发货成功。

AI 咨询热点：用最近 24h 的 `/api/ai/chat` 用户消息做关键词词频前 5（不需要复杂 NLP）。

---

### 2.3 视觉系统延展（P1）

保持 Liquid Glass + 翠绿 + 香槟金大方向，但避免"所有页一张玻璃卡"。差异化：

- **首页**：横向"展柜"，深色光影、留白多、玻璃卡尺寸更大。
- **详情**：模拟"鉴定档案"，纸纹底纹、序列号刻字、证书章风格。
- **AI 页**：私人顾问室，去掉气泡 App 的拥挤感，改用"会话流 + 证书摘要"双栏。
- **后台**：交易控制台，信息密度更高，玻璃透明度更低、装饰更克制。
- **luxury_redesign_preview_screen.dart** 保持只在 debug 入口可见。

---

## 3. 落地分期与验收

### 3.1 第一里程碑：P0 工程地基（建议 1 周）

- [x] **i18n 引擎重构**（代码级验收完成，发布前仍需手工三语走读）。
  - **阶段完成 2026-05-01**：`huiyuyuan_app.dart` 移除 `key: ValueKey`；`_parseLanguage` 大小写不敏感；`String.tr` / `trArgs` `@Deprecated`；9 个核心 Widget 文件迁至 `localizedXxxFor(lang)`；`ProductImageView` 转 `ConsumerStatefulWidget`；新建 `tool/lint_i18n.dart`（12 条规则，退出码语义）。
  - **补强 2026-05-05**：外部 `product.titleL10n` / `catL10n` / `matL10n` 调用已从库存与 AI 商品上下文中移除；`AIProductContextService` 改为显式接收语言并读取后端三语字段。
  - **完成 2026-05-06**：`ProductModel` 内部六个读 `TranslatorGlobal.currentLang` 的兼容 getter（`titleL10n` / `descL10n` / `matL10n` / `catL10n` / `originL10n` / `materialVerifyL10n`）已删除，模型层只保留显式 `localizedXxxFor(AppLanguage)` 接口；`OrderModel.localizedProductName` 兼容 getter已删除，订单相关 UI 改为显式传语言；`order_detail_screen` 与 `product_list_screen` 已清掉直接语言读取 / `_copyByLanguage` helper。所有 service/repository/provider 层废弃 `String.tr` / `trArgs` 调用已移除；`dart run tool/lint_i18n.dart` 当前为 **0 issue**，`flutter test test/l10n/i18n_guard_test.dart` 与 `dart run tool/i18n_audit.dart` 均通过。
  - **发布前保留项**：登录页、首页、商品详情、订单详情、AI 助手、设置等核心路径仍需手工 zh-CN / en / zh-TW 走读确认视觉与导航栈。
- [x] orders.py 乱码全量修复 + 删除 `main_v3_backup.py` + sanity test。
  - **完成 2026-05-01**：`orders.py` 22 处乱码全部修复（支付/订单/库存/物流相关中文字符串及注释）；`main_v3_backup.py`（85 KB）已删除；新增 `tests/test_no_mojibake.py`（2 条：全文件乱码扫描 + 备份文件检测），190 passed。
- [x] 测试支付保护（环境守卫 + payment_url None + pytest）。
  - **完成 2026-05-01，补强 2026-05-05**：`payments.py` 0.01 自动确认块加 `not IS_PRODUCTION`、`payment_method in {"test_alipay", "test_wechat"}`、`is_test_order is True` 三重守卫；`orders.py` `/checkout` 端点 `payment_url` 改为 `None`，移除 `pay.example.com` 占位；`tests/test_payment_auto_confirm_guard.py` 增加行为测试，覆盖普通支付方式不自动确认、缺少测试订单标记不自动确认、显式测试订单可自动确认。
- [x] 根目录视觉素材搬家 + `.cursorindexignore`。
  - **完成 2026-05-01**：229 张截图（根目录 + `huiyuyuan_app/` 根）移入 `docs/screenshots/`；git rm --cached 解除追踪；`.gitignore` 补充根级 `*.png` 条目；新建 `.cursorindexignore`（覆盖图片、build 产物、venv、lock 文件、归档文档）；追踪 PNG 从 331 降到 **36**（全为合法 app 资产）。
  - **补强 2026-05-05**：从 Git 索引移除 Android `.gradle` / `.kotlin`、`key.properties`、`local.properties`、`.jks`、`GeneratedPluginRegistrant`、iOS/macOS Flutter ephemeral 等本地生成或敏感文件，并在 `.gitignore` / `.cursorindexignore` 增加对应规则。
- [x] Cursor `.cursor/rules/` 落地（i18n 规则、Liquid Glass 规则、保密规则）。
  - **完成 2026-05-01**：`.cursor/rules/i18n-flutter.mdc`（glob: `lib/**/*.dart`）、`.cursor/rules/liquid-glass-design.mdc`（glob: `screens/**/*.dart,widgets/**/*.dart`）、`.cursor/rules/secrets-safety.mdc`（alwaysApply: true）。

**验收口径**：

- `flutter analyze` 0 issue；`flutter test` 全绿；`dart run tool/lint_i18n.dart` 0 issue。
  - 当前状态（2026-05-06）：`dart run tool/lint_i18n.dart` 未发现违规；`flutter test test/l10n/i18n_guard_test.dart` 5 passed；`dart run tool/i18n_audit.dart` passed；`flutter analyze --no-fatal-infos lib` 通过（仅剩既有 info）。
- `python -m pytest` 全绿，且包含 `test_no_mojibake.py`、`test_payment_auto_confirm_guard.py` 两个新用例。
- 三种语言切换不丢导航栈（手工脚本走读 8 个核心页面）。
- 后端 GET 订单失败时日志 / response 里无乱码。
- `git ls-files '*.png'` < 50 个。

### 3.2 第二里程碑：商品骨架升级（建议 1 周）

- [x] ProductModel + Alembic migration + 种子数据扩展（数据契约阶段）。
  - **阶段完成 2026-05-01**：新增 8 个字段（`appraisal_note` 三语、`craft_highlights` 三语、`weight_g`、`dimensions`）；Alembic `20260501_0010_product_appraisal_fields`；后端 schema 同步；`PRODUCT_SEED_UPSERT_SQL` 扩展支持新列（`COALESCE` 更新策略保护已有内容）。
  - **补强 2026-05-05**：新增 Alembic `20260505_0011_product_dossier_fields`；补齐 `audience_tags` 三语、`origin_story` 三语、`flaw_notes` 三语、`certificate_authority` 三语、`certificate_image_url`、`certificate_verify_url`、`gallery_detail`、`gallery_hand`；`craft_highlights` 三语字段改为 `List<String>` / JSONB，并保留旧字符串自动拆分；同步后端读写 router、seed upsert、Flutter `ProductModel`、`ProductUpsertRequest` 与 runtime catalog。
  - **补料 2026-05-05**：头部 30 件商品已补二阶段文本字段：适合人群、来源故事、自然特征/瑕疵说明、证书机构；`craft_highlights` 已从旧换行字符串转为数组，并同步 `backend/data/product_seed_payloads.json` 与 `lib/data/product_seed_generated.dart`。
  - **未完成**：证书图片、官方查验链接、微距图、上手图仍缺真实资产，暂不造假填充。
- [x] 商品详情页"一物一档"第一阶段骨架（即使部分字段为空也优雅降级）。
  - **阶段完成 2026-05-01**：`product_detail_screen.dart` 在「商品信息」面板追加克重/尺寸行（条件显示）；新增「鉴定说明」和「工艺亮点」两个独立 GlassPanel 区块，均以 `?.isNotEmpty` 判空，空则整块不渲染。追加 5 个 i18n 键（`product_weight`、`product_weight_value`、`product_dimensions`、`product_appraisal_note`、`product_craft_highlights`），三语全覆盖。
  - **补强 2026-05-05**：详情页条件渲染二阶段字段：适合人群 chip、来源故事、自然特征/瑕疵、证书机构/证书图/官方查验链接、微距细节与上手图库；AI 商品上下文同步带入适合人群、来源故事、自然特征摘要。
- [x] 头部 30 个商品手工补完整三语字段。
  - **完成 2026-05-01**：`product_seed_payloads.json` 前 30 件商品（HYY-HT001～HYY-HT011、HYY-FC001～HYY-FC004、HYY-NH001～HYY-NH003、HYY-ZS001、HYY-ZS002、HYY-HJ001～HYY-HJ004、HYY-HB001、HYY-LB001、HYY-ML001、HYY-BY001、HYY-PT001、HYY-ZJ001）全部补充：英/繁名称、英/繁描述、英/繁材质/品类/产地/材质验证、鉴定说明（三语）、工艺亮点（三语）、克重、尺寸。其余 70+ 件商品字段补 `null`（待后续批次）。
  - **补强 2026-05-05**：前 30 件商品继续补充适合人群、来源故事、自然特征/瑕疵说明、证书机构三语字段；证书图片、官方查验链接、微距图、上手图继续空置，等待真实图片/官方链接资产后再补。
- [x] AI 上下文从全量改为基于 `appraisal_note` / `craft_highlights` 的精简 prompt。
  - **完成 2026-05-01**：`AIProductContextService.buildProductContext` 在商品有 `appraisalNote` 时追加「| 鉴定：（前60字）」，有 `craftHighlights` 时追加「| 工艺：（前60字）」；两者都为空则维持原行格式，token 消耗无增加。

**验收口径**：

- 30 个高曝光商品的详情页都不再像"电商小程序"。
- 新字段三语都来自后端字段（不依赖 `ProductTranslator` 字符级拼接）。
- 完整"一物一档"验收仍必须等真实媒体资产补齐：证书图片、官方查验链接、微距细节图、上手图需要进入头部商品 seed。
- DashScope token 消耗下降（精简 prompt 后）。

### 3.3 第三里程碑：首页 + AI 顾问（建议 1 周）

- [x] `HomeCurationScreen` 上线作为 Tab 1（customer 角色）。
  - **完成 2026-05-01**：新建 `lib/screens/home/home_curation_screen.dart`；包含：Hero Banner（品牌名 + 副标题）、材质快捷芯片行（按热度排序，含颜色/图标映射）、AI 顾问横幅（直接入 `AIAssistantScreen`）、「今日甄选」热门商品横向滚动、「新品上架」横向列表、「查看全部」横幅。`main_screen.dart` customer Tab 0 从 `ProductListScreen` 换为 `HomeCurationScreen`，admin/operator 不变。
- [x] 商品详情底部 CTA + 结算页快捷气泡 + 三处 deep link 进 `AIAssistantScreen`。
  - **完成 2026-05-01**：① `AIAssistantScreen` 新增 `productId`/`productName`/`initialContext` 可选参数，从产品页打开时自动注入一条 AI 商品上下文问候语。② 商品详情底栏在「加购」左侧增加 `auto_awesome` 圆形图标按钮，传入 `productId`、`productName` 打开 AI。③ 结算页 `Stack` 右下角增加「AI 咨询」毛玻璃气泡，带入购物车商品名称作为 `initialContext`。
- [x] 客服回复建议（管理端）。
  - **完成 2026-05-01**：操作员首页「导入聊天记录」功能键（原 Toast 占位）升级为「AI起草回复」，打开 `AIAssistantScreen` 并预设「帮我起草专业客服回复」上下文提示；权限守卫延用 `ai_assistant`。新增 `work_ai_reply_draft` i18n 键（简/英/繁）。

**验收口径**：

- 首屏一眼可识别为"珠宝鉴赏 + 交易"，不是商城。
- AI 在三个入口都能正确读到 `productId` 与上下文，并做相应 prompt。
- DashScope 离线降级仍有效。

### 3.4 第四里程碑：后台驾驶舱 + 视觉延展（建议 1 周）

- [x] AdminDashboard 4 张状态卡 + 待办 timeline。
  - **完成 2026-05-01**：① `DashboardStats` 补充 `todayRevenue`/`todayOrders`/`pendingRefund` 三字段，对齐后端 `/api/admin/dashboard` 真实返回。② 4 张统计卡改为有意义的差异化 KPI：「今日营业额」/「待发货订单」/「退款申请」/「低库存预警」，urgent=true 时边框加亮高亮。③ 新增 `_buildTodoBulletin()` Timeline 组件（显示于统计卡下方）：非零待办项目逐条列出（带紧急徽章），全部为零时展示「今日无待办」绿色状态卡。④ Tab 激活指示条由翡翠绿渐变改为琥珀金渐变，视觉调性与客户界面区分。
- [x] AI 咨询热点。
  - **完成 2026-05-01**：在活动 Feed 底部新增 `_buildAIHotspotSection()`，仅在「全部」或「AI」筛选时展示；同时展示 AI 活动日志（tag=ai）+ 热销商品（`isHot=true`，按 `salesCount` 排序），供运营人员快速识别高关注品类。
- [x] 详情 / 首页 / AI / 后台四类页面视觉差异化。
  - **完成 2026-05-01**：① **首页（HomeCurationScreen）**：`jadeBlack` 纯深色底，翡翠绿光晕，策展展柜调性。② **AI 助手页（AIAssistantScreen）**：顶右改为紫蓝色光晕（`#7C3AED`），左下为天蓝色（`#0EA5E9`），科技/私人顾问感。③ **后台（AdminDashboard）**：Tab 激活条琥珀金、待办 Timeline 左侧竖条金色、统计标题金色，控制台调性。④ **商品详情**（已有风格）：鉴定档案式，不作改动。四页均遵循 Liquid Glass，但主色光晕/强调色各不相同。

**验收口径**：

- 运营人员打开后台 30 秒内能说出"今天该处理什么"。
- 首页 / 详情 / AI / 后台四类页面视觉指纹不同，但都遵守 Liquid Glass。

---

## 4. 风险与回退

| 风险 | 描述 | 缓解 |
|------|------|------|
| i18n 重构后翻译漏刷新 | 改动点漏改、widget 没订阅 `appSettingsProvider` | feature flag `AppConfig.useLegacyLocaleRebuild`，灰度开 / 关；lint 工具检查 |
| ProductModel 扩展打挂旧客户端 | 旧 APK 拿到新字段反序列化失败 | 所有新字段 nullable + `fromJson` 容错；后端按 `User-Agent`/`X-Client-Version` 决定是否返回新字段 |
| 测试支付保护过严 | 开发本地无法跑通 0.01 流程 | `APP_ENV=development` + `is_test_order=True` 双重守卫；开发文档明确说明 |
| PNG 搬家影响 README 引用 | 相对路径失效 | 先 grep 引用，批量替换；CI 可加 markdown 链接检查 |
| AI 上下文升级触发限流 | DashScope 配额 / 并发限制 | 按 `productId` 缓存 prompt（TTL 30 分钟）；本地降级保留 |
| 删除 `String.tr` 静态扩展破坏现有调用 | 调用面广 | 先标记 `@Deprecated`，给出 codemod 脚本，分批迁移 |

---

## 5. Cursor 续开发配套

### 5.1 `.cursor/rules/` 建议落地三个规则文件

1. **`huiyuyuan-core.mdc`**：handoff 文档第 8.2 节列的核心规则（不接入真实支付、不偏离 Liquid Glass、不提交密钥）。
2. **`i18n.mdc`**：禁止裸 `Text('中文')` / `_copyByLanguage` / `String.tr`；强制 `ref.tr` + `ref.watch(appSettingsProvider).language`。
3. **`product-model.mdc`**：新增字段必须三语 + nullable + fromJson 容错；详情页对空字段优雅降级。

### 5.2 `.cursorindexignore`

```text
docs/reference/
docs/reference/visual_archive/
build/
huiyuyuan_app/.dart_tool/
huiyuyuan_app/build/
huiyuyuan_app/android/.gradle/
huiyuyuan_app/ios/Pods/
huiyuyuan_app/macos/Pods/
huiyuyuan_app/windows/build/
gradle_repro_version_catalog/
*.apk
```

### 5.3 MCP

`.vscode/mcp.json` 保持空；MCP 配置写到 Cursor 用户级；如需在仓库示例化，新建 `docs/cursor_mcp_example.md` 只放占位字符串。

### 5.4 handoff 文档补丁

在 `docs/cursor_development_handoff_20260501.md` 第 2 节"Review 结论与风险"表里追加两行：

| 优先级 | 发现 | 影响 | 建议 |
|------|------|------|------|
| P0 | 语言切换依赖 MaterialApp 整树重建 + 静态全局，导致切换语言时导航栈丢失 | 用户体验断裂、产品观感塌方 | 按本计划 2.1.1 执行 i18n 重构 |
| P0 | ProductModel 缺鉴赏理由 / 来源故事 / 检测机构 / 适合人群 / 工艺亮点 / 自然特征 / 多角度图 | 无法做"一物一档"，只能继续做"商品列表" | 按本计划 2.1.4 + 2.2.2 扩展 schema |

---

## 6. Definition of Done（产品 + 工程）

可验收的最终目标，全部命中才算完成本轮重构：

- [ ] 切换语言不会跳回登录页或丢失当前导航位置。
- [ ] `MaterialApp` 没有 `key: ValueKey(language)` 这样的整树重建作弊。
- [x] `ProductModel` 没有 `titleL10n` / `descL10n` 这种"读静态全局"的 getter。
- [x] `lib/screens/**/*.dart` 没有裸 `Text('中文')`、没有 `_copyByLanguage`、没有 `String.tr`（lint 工具检测通过）。
- [ ] 商品详情页能在 5 秒内让用户读出"为什么这件值得看"。
- [ ] AI 在商品页 / 结算页 / 识图后均能正确带商品上下文。
- [ ] 后端无乱码错误返回；运营人员看后台 1 屏内能知道今天要处理什么。
- [ ] 测试 0.01 自动确认在生产被拒绝、在开发可走通。
- [ ] 根目录干净，新加入的开发者打开仓库不会"被噪音淹没"。
- [ ] 文档同步：handoff 风险表 + 本计划 + 任务清单（`docs/planning/task.md`）三处同步更新。

---

## 7. 后续路线（不在本轮范围）

> 列出来是为了让后续工作能接续，不让这次重构成为孤岛。

- ARB 化（方案 A）：6 个月内迁完，享受 IDE 自动补全和 `genl10n` 校验。
- 后端三语接口：把订单 / 推送 / AI 系统提示语都按 `Accept-Language` 返回不同语言，不再前端拼接。
- 真实支付：等 GitHub 账号恢复 + 阿里云资质 + 风控后再启动。
- 阿里云 SMS 真实通道：注册资质后替换 dev 万能码 `8888`。
- Android 签名：生成 `huiyuyuan.jks` 并加入 CI 安全注入。
- Firebase Crashlytics：补齐崩溃监控。
- 隐私政策 HTTPS 落地：当前已有页面，需要正式 URL 公布。

---

## 8. 执行顺序总结（一张图）

```text
Week 1  (P0 工程地基)
  └─ i18n 引擎重构 + orders.py 乱码 + 测试支付保护 + 根目录治理 + Cursor 规则
Week 2  (P0 商品骨架)
  └─ ProductModel 扩展 + 一物一档详情页 + 30 件头部商品种子
Week 3  (P0/P1 产品叙事)
  └─ 首页 HomeCurationScreen + AI 顾问 deep link + 客服 AI 建议
Week 4  (P1 后台驾驶舱 + 视觉延展)
  └─ Dashboard 状态卡 + 待办 timeline + AI 咨询热点 + 视觉差异化
```

---

> 本计划是工作蓝图，不是营销文案。每个验收口径都能在代码 / 命令里落到一行。
> 任何条目执行偏差，先回头看 review 发现的根因，再决定是补救还是放弃。
