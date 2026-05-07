# 汇玉源项目状态总览

> 更新时间：2026-04-28
> 目的：记录 UI 重构上线后的真实项目状态、验证结果、文件清理结果和后续改进建议。

---

## 当前结论

- 生产域名：`https://汇玉源.top` / `https://xn--lsws2cdzg.top`
- 服务器：阿里云 ECS `47.112.98.191`
- 后端状态：`huiyuyuan-backend=active`，`/api/health=200`
- Nginx 状态：配置测试通过，已 reload
- Web 静态目录：`/var/www/huiyuyuan/`
- 最近一次生产同步：2026-04-28 15:37 左右，已部署后端、Nginx、Flutter Web
- 当前 GitHub 状态：本地已整理成提交，但 GitHub 账号暂时封禁申诉中，尚未推送远端

当前版本适合继续做内部试运行和小范围业务验证。相比上一版，视觉体验、支付/订单后台能力、部署脚本可靠性都有明显提升；但真实第三方支付、短信资质、Android 正式签名和线上监控仍是正式商用前的关键缺口。

### 2026-05-01 补充结论

- 已新增 [Cursor 续开发交接与项目 Review](cursor_development_handoff_20260501.md)，用于在 Cursor 中继续开发时快速接上项目上下文。
- 真实微信/支付宝支付改为暂缓事项，不作为近期产品主线。
- 近期重点调整为：产品高级感、珠宝鉴赏叙事、商品“一物一档”、AI 导购嵌入、人工支付闭环稳定、后台处理效率。
- 当前最需要避免的是继续堆普通电商功能，导致项目看起来像点单/咖啡小程序换皮。

---

## 本轮上线范围

### Flutter UI 重构

- 全站继续统一到 Liquid Glass / 深玉翡翠 / 香槟金视觉体系。
- 登录、首页框架、商品列表、商品详情、购物车、结算、支付、订单、物流、评价、个人中心、收藏、浏览记录、地址、通知、AI 助手、店铺详情、店铺雷达、AR 试戴、隐私政策、用户协议、管理员/操作员页面都已完成新版视觉落地。
- 新增 `luxury_redesign_preview_screen.dart` 作为 Figma/视觉方向预览与交接参考。
- 新增 `resilient_network_image.dart`，提升线上图片加载的容错体验。

### 支付、订单与后台能力

- 后端订单与支付链路已增强，人工确认到账、争议/取消状态保护、支付对账工作台等能力已补齐。
- 新增 Alembic 迁移：`20260415_0009_operator_permissions.py`。
- 生产 Alembic 当前 head：`20260415_0009_operator_permissions`。
- 管理端新增支付对账工作台及对应前端 Provider / Model / Test。

### 更新机制

- Web 端不再弹应用更新提示，Web 应按静态资源自动更新。
- Android 端保留托管下载/安装更新能力。
- 生产 Web 部署时额外上传 `download.html`，供 App 下载页使用。

### 部署脚本修复

`scripts/deploy.ps1` 在本轮上线中做了发版稳定性修复：

- SSH 多行命令去除 Windows CRLF，避免远端 bash 收到 `$'\r'`。
- SSH 命令按退出码判断，不再把 Alembic 正常 `INFO` 日志当失败。
- Web 发布前自动 `flutter pub get`。
- Web 分析改为 `flutter analyze --no-fatal-infos lib/`。
- Flutter 命令按退出码和产物存在判断，不再只依赖输出文本。
- Web build 只要 `build/web/index.html` 和 `build/web/main.dart.js` 存在且命令退出码为 0，即视为构建成功。

---

## 验证结果

### 发布前检查

- `flutter test test/l10n/i18n_guard_test.dart`：通过，`5 passed`
- `dart run tool/i18n_audit.dart`：通过，阻塞项为 0
- `flutter analyze --no-fatal-infos lib/`：通过，仅保留 info 级建议
- `flutter test`：通过，`507 passed`
- 后端 `python -m pytest -q`：通过，`183 passed`
- `flutter build web --release`：通过，已生成 `build/web`
- `git diff --check origin/master..HEAD`：通过

### 生产验证

- 服务器内网：`curl http://127.0.0.1:8000/api/health` 返回 200
- 服务器访问公网域名：`https://xn--lsws2cdzg.top/api/health` 返回 200
- 本地强制 Host 到真实服务器 IP 验证：
  - `https://47.112.98.191/` + `Host: xn--lsws2cdzg.top` 返回 200
  - `https://47.112.98.191/api/health` + `Host: xn--lsws2cdzg.top` 返回 200
- 生产文件时间戳：
  - `/var/www/huiyuyuan/index.html`：2026-04-28 15:37
  - `/var/www/huiyuyuan/main.dart.js`：2026-04-28 15:37
  - `/var/www/huiyuyuan/download.html`：2026-04-28 15:37

### 验证注意点

- 本机开启代理/虚拟网卡时，域名可能解析到 `198.18.x.x`，这是代理网络行为，不代表线上 DNS 或服务器异常。
- Flutter Web 可能被浏览器 Service Worker 缓存旧包；上线后若看到旧页面，优先强刷、无痕窗口或清理站点缓存。

---

## Git 与备份状态

当前本地分支：`codex/ui-redesign-release-check`

相对 `origin/master` 的提交：

```text
244fb41 fix: capture flutter deploy command output safely
971b247 fix: make web deploy checks snapshot-safe
5f441ac fix: tolerate deploy ssh stderr output
1e8691e fix: normalize SSH deploy commands
76b8676 chore: trim release diff whitespace
4311096 docs: document redesign release readiness
7d9aa70 feat: harden backend order and payment flows
902e273 feat: refresh liquid glass Flutter experience
```

GitHub 推送暂未完成，原因是当前 GitHub 账号被封禁并在申诉中。恢复后建议第一时间执行：

```powershell
git push -u origin codex/ui-redesign-release-check
```

发布备份已移出仓库，避免污染 Git 状态：

```text
D:\huiyuyuan_release_backups\release_artifacts_20260428_200916
```

---

## 文件清理结果

已清理内容：

- 根目录旧排查脚本：`check_*.sh`、`test_*.sh`、`debug_*.sh` 等
- 临时 SQL：`.tmp_*.sql`、`add_test_product.sql`
- 临时 Figma cookie：`tmp_figma_cookies.sqlite`
- 一次性 Nginx 下载页修补脚本：`scripts/add_download_route.sh`
- 仓库内 `release_artifacts/`，已移到仓库外备份目录
- Gradle 本地缓存文件变更已恢复，避免 `.gradle` 锁文件进入提交

清理后仓库工作区保持干净。

---

## 当前风险与边界

- GitHub 未推送：生产已同步，但远端仓库还没有这 8 个提交，账号恢复后必须补推。
- APK 未同步：本轮刻意没有发布 APK，避免把旧 APK 当新版本分发。
- Web 缓存：Flutter Service Worker 可能导致用户短时间内看到旧页面。
- 真实支付未完成：当前是人工确认到账闭环，不是微信/支付宝自动回调；该事项已明确暂缓，不作为近期主线。
- 短信资质未完成：阿里云 SMS 正式资质与生产模板仍需完善。
- 监控薄弱：缺少 Crashlytics/Sentry/服务端告警等线上主动发现能力。
- Android Release 签名仍需正式化：需要生成并妥善备份 `huiyuyuan.jks`。

---

## 后续改进建议

### P0：远端与发版安全

1. GitHub 账号恢复后立即推送 `codex/ui-redesign-release-check`。
2. 在 GitHub 上创建 PR，保留本次部署记录、验证记录和回滚说明。
3. 给 `release_artifacts/`、`tmp_figma_cookies.sqlite`、`check_*.sh`、`test_ws*.sh` 等补 `.gitignore` 规则，防止再次误暂存。
4. 后续生产发布继续从干净 worktree/snapshot 执行，不直接从脏工作区发版。

### P1：内部试运行

1. 安排 3-5 天内部真实流程试运行：登录、浏览、收藏、下单、支付凭证、管理员确认到账、发货、评价。
2. 每天记录订单/支付/图片/AI/登录问题，形成复盘清单。
3. 针对 Web 用户明确提示“上线后如果页面没变，先强刷或清站点缓存”。

### P1：产品与人工支付闭环

1. 把首页从普通商品流升级为“甄选、鉴赏、信任、AI 顾问”入口。
2. 把商品详情升级为“一物一档”，补齐鉴赏理由、材质工艺、证书/凭证、适用场景和瑕疵说明。
3. 保留人工支付、上传凭证、后台确认到账模式，避免文案暗示已接入第三方自动支付。
4. 移除或增加环境保护到 `0.01` 测试订单自动确认逻辑。
5. 给支付、订单、库存变更增加关键审计日志与导出能力。

### P2：工程质量

1. 消化 `luxury_redesign_preview_screen.dart` 中的 const/info 级 lint，降低噪音。
2. 修复 `url_helper_web.dart` 的 web-only lint 结构，必要时封装成条件导入工具。
3. 将部署脚本的关键步骤拆成可单测函数或 smoke test，减少 PowerShell/SSH 边界问题。
4. 增加 Web 首屏 smoke test，自动验证新版 `main.dart.js` hash 和关键文案。

### P3：真实支付（暂缓）

1. 产品主线和人工支付闭环稳定后，再接入微信支付/支付宝正式回调与验签。
2. 接入前先确认商户资质、回调域名、订单幂等、退款流程、对账导出和异常补偿方案。
3. 不建议在当前产品质感尚未稳定前投入大量时间做真实支付。
