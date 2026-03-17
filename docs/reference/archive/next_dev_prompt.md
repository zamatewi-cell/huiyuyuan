# 汇玉源 - 下次开发完整提示词

> 复制以下内容，在新对话中发送给 AI 即可继续开发。

---

## 提示词

```
你好！请继续开发「汇玉源珠宝智能交易平台」Flutter 应用。

## 📍 项目位置
- 工作区：d:\huiyuanyuan_project
- Flutter 应用：d:\huiyuanyuan_project\huiyuanyuan_app
- 文档中心：d:\huiyuanyuan_project\docs

## 📋 上次完成的工作 (2026-02-25)
1. ✅ 搜索功能完全重写（search_screen.dart）— 真实商品搜索，支持名称/材质/分类/编号/产地多维搜索，实时联想、分类过滤、排序、关键词高亮
2. ✅ 通知系统新建（notification_screen.dart）— Tab 分类（全部/订单/活动/系统）、未读标记、一键已读
3. ✅ 轮播图完全重写（promotional_banner.dart）— 4 页自动轮播、动画圆点指示器
4. ✅ 交互修复 8 项：购物车结算/立即购买/搜索通知按钮/操作员开关/个人中心编辑/提醒持久化/错误页重试
5. ✅ 性能优化：BackendService → ApiConfig.baseUrl + Auth token 拦截器、SystemChrome postFrameCallback、图片 memCacheWidth
6. ✅ 库存管理模块（inventory_screen.dart + inventory_model.dart + inventory_provider.dart）
7. ✅ 部署上线 — flutter build web → scp 至 47.98.188.141, nginx reload, health check 通过

## 🎯 下次开发目标（按优先级）

### 第一优先级 — 上线阻塞项
1. **HTTPS 配置**：域名 `api.huiyuanyuan.com` 解析 + Let's Encrypt 证书配置
2. **阿里云 SMS 正式接入**：填入真实 AccessKey/Secret/模板 Code，替换测试模式
3. **数据云端化**：购物车/收藏/订单列表从 API 拉取（替换本地 Mock）
4. **Android 签名密钥生成**：`huiyuanyuan.jks` + Release 签名配置

### 第二优先级 — 首发版本
5. **支付系统**：微信支付/支付宝支付接口对接（资质就绪后）
6. **图片上传服务**：阿里云 OSS 对接，商品/头像图片上传
7. **客服系统**：WebSocket 实时聊天 + AI 自动分流

## 📁 关键文件路径
- 任务清单：docs/planning/task.md
- 实施计划：docs/planning/implementation_plan.md
- AI 服务：lib/services/ai_service.dart（已含 DeepSeek+Gemini 三级降级）
- API 配置：lib/config/app_config.dart + lib/config/secrets.dart
- 密钥文件：lib/config/secrets.dart（已含 DeepSeek + Gemini API Key）
- 前端 Mock 开关：lib/config/api_config.dart（useMockApi=true，登录正常）
- 主题系统：lib/themes/jewelry_theme.dart + lib/themes/colors.dart
- 国际化：lib/l10n/app_strings.dart + lib/l10n/l10n_provider.dart
- 后端服务：huiyuanyuan_app/backend/（FastAPI + main.py）

## ⚙️ 技术栈
- Flutter 3.x + Dart
- 状态管理：Riverpod 2.x
- 网络请求：Dio
- AI：DeepSeek API（优先）+ Google Gemini API（备用）+ DashScope 千问VL（图片识别），均支持 SSE 流式输出
- 设计风格：Liquid Glass（毛玻璃+渐变）
- 后端：FastAPI + PostgreSQL 14 + Redis，已部署于阿里云 ECS 47.98.188.141

## ⚠️ 注意事项
- **登录**：useMockApi=true，万能验证码 8888，管理员账号 18937766669/admin123
- **AI 降级**：DeepSeek → Gemini → 离线，三级自动切换，无需手动干预
- **一键部署**：完成开发后运行 `.\scripts\deploy.ps1` 或按 Ctrl+Shift+B 自动部署到服务器
- 深色模式已全面适配，新页面使用 `context.adaptiveBackground`、`context.adaptiveCard` 等扩展方法
- AI 服务 SSE 解析使用 `utf8.decode` + `json.decode`，请勿回退到旧方式
- 多语言使用 `ref.tr('key')` 模式，新增文案同步到 app_strings.dart 三种语言
- 密钥管理：`String.fromEnvironment` + 本地回退，生产构建用 `--dart-define`
- 所有代码注释使用中文

请先阅读 docs/planning/task.md 了解完整进度，然后从第一优先级开始开发。每完成一个任务，请更新 task.md，然后运行部署脚本同步到服务器。
```

---

*生成时间: 2026-02-25*
