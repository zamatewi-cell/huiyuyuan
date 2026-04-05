# 汇玉源发布清单（Release Checklist）

> 适用范围：Android APK / AAB 正式发布、iOS TestFlight、Web 静态资源

---

## 1. 发布前检查

### 1.1 代码质量

- [ ] `flutter analyze` 全绿（无 error / warning）
- [ ] `flutter test` 全部通过
- [ ] `pytest backend/tests/` 全部通过
- [ ] 无未解决的 merge conflict
- [ ] `dart analyze --fatal-infos` 通过

### 1.2 多语言

- [ ] 运行 i18n guard：`scripts/run_huiyuyuan_i18n_guard.ps1`
- [ ] 新增 UI 文字已添加 zh_CN / en / zh_TW 三语翻译
- [ ] 无新增中文字面量硬编码

### 1.3 版本号（统一工具）

- [ ] 运行 `python tool/version_manager.py check` 确认三处版本一致
- [ ] 使用 `python tool/version_manager.py set <version> <build>` 统一设置版本号
- [ ] 验证输出：`python tool/version_manager.py get` 显示三处一致
- [ ] `APP_RELEASE_NOTES` 已更新为本版本的变更说明
- [ ] `APP_RELEASED_AT` 已更新为发布时间

> **重要**：不要再手动修改三处版本文件。统一使用 `tool/version_manager.py` 管理版本。

### 1.4 安全

- [ ] `config/secrets.dart` 不包含真实 API Key（本地开发用 `.env.json`）
- [ ] `.env` 未提交到 Git
- [ ] `key.properties` 和 `*.jks` 未提交到 Git
- [ ] CI 安全扫描通过（credentials scan + SAST）

---

## 2. Android 发布

### 2.1 签名配置（首次或密钥变更后）

- [ ] 已运行 `scripts/generate_keystore.ps1` 生成 `huiyuyuan.jks`
- [ ] `android/key.properties` 已填写正确的密码和路径
- [ ] `android/app/build.gradle.kts` 的 signingConfigs 已生效（构建日志显示 `✓ key.properties found`）
- [ ] `huiyuyuan.jks` 已备份到安全位置（至少两个独立存储介质）

### 2.2 构建

- [ ] `flutter clean && flutter pub get`
- [ ] `flutter build apk --release --dart-define=DASHSCOPE_API_KEY=sk-xxx`
- [ ] 确认 APK 签名正确：`jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk`
- [ ] （可选）`flutter build appbundle --release` 生成 AAB 用于 Play Store

### 2.3 分发

- [ ] APK 已上传到服务器：`scp app-release.apk root@47.112.98.191:/var/www/huiyuyuan/downloads/huiyuyuan-latest.apk`
- [ ] 下载链接可访问：`curl -I https://xn--lsws2cdzg.top/downloads/huiyuyuan-latest.apk`
- [ ] 版本号接口已更新：`curl https://xn--lsws2cdzg.top/api/app/version?platform=android`

### 2.4 验证

- [ ] 在一台 Android 设备上安装 APK 并验证：
  - 启动正常
  - 登录正常
  - 首页数据加载正常
  - AI 对话正常
  - 版本检查提示正常（若版本号递增）

---

## 3. iOS 发布（TestFlight）

### 3.1 准备工作

- [ ] Apple Developer Program 会员有效
- [ ] Bundle ID `com.huiyuyuan.app` 已注册
- [ ] Provisioning Profile 已配置
- [ ] App Icon 和 Launch Screen 已更新
- [ ] `Info.plist` 权限说明已完善（相机、相册、网络等）

### 3.2 构建

- [ ] `flutter build ios --release --no-codesign`
- [ ] 在 Xcode 中打开 `ios/Runner.xcworkspace`
- [ ] 设置签名团队和 Bundle Identifier
- [ ] Archive：Product → Archive
- [ ] Distribute App → App Store Connect → Upload

### 3.3 TestFlight

- [ ] 在 App Store Connect 中确认构建已出现
- [ ] 填写 TestFlight 测试说明
- [ ] 添加内部测试员
- [ ] （如需外部测试）提交 Beta 审核

---

## 4. Web 发布

- [ ] `flutter build web --release --no-tree-shake-icons`
- [ ] `scripts/deploy.ps1 -Target web` 执行成功
- [ ] 公网可访问：`curl -I https://xn--lsws2cdzg.top/`
- [ ] 页面加载正常，无白屏
- [ ] 浏览器控制台无 JS 错误

---

## 5. 后端发布

- [ ] `scripts/deploy.ps1 -Target backend` 执行成功
- [ ] Alembic 迁移已应用：`alembic upgrade head`
- [ ] 健康检查通过：`curl https://xn--lsws2cdzg.top/api/health`
- [ ] 后端日志无异常：`journalctl -u huiyuyuan-backend -n 50`

---

## 6. 发布后验证

### 6.1 冒烟测试（Smoke Test）

| 场景 | 预期 | 结果 |
|------|------|------|
| 管理员登录 | 成功进入 AdminDashboard | ☐ |
| 操作员登录 | 成功进入 OperatorHome | ☐ |
| 用户注册+登录 | 验证码正常，登录成功 | ☐ |
| 浏览商品 | 列表和详情正常 | ☐ |
| 下单支付 | 可创建订单，显示收款码 | ☐ |
| 管理员确认到账 | 订单状态变更为 paid | ☐ |
| AI 对话 | 正常回复，无错误 | ☐ |
| 通知系统 | 未读角标正常 | ☐ |
| 版本检查 | 版本号接口返回正确 | ☐ |

### 6.2 服务器状态

- [ ] `systemctl status huiyuyuan-backend` — active (running)
- [ ] `systemctl status nginx` — active (running)
- [ ] 磁盘空间充足：`df -h /`
- [ ] 内存使用正常：`free -h`

---

## 7. 回滚准备

### 7.1 后端回滚

- [ ] 已知可用快照：`ssh root@47.112.98.191 "ls -dt /opt/huiyuyuan/snapshots/*"`
- [ ] 回滚命令就绪：`deploy.ps1 -Target backend -Rollback <snapshot_name>`

### 7.2 Web 回滚

- [ ] 发布前已备份：`ssh root@47.112.98.191 "cp -a /var/www/huiyuyuan/. /opt/huiyuyuan/web-snapshots/<timestamp>/"`
- [ ] 回滚命令就绪：`ssh root@47.112.98.191 "cp -a /opt/huiyuyuan/web-snapshots/<timestamp>/. /var/www/huiyuyuan/ && systemctl reload nginx"`

---

## 8. CI/CD Secrets 清单

以下 GitHub Secrets 需要在仓库 Settings → Secrets and variables → Actions 中配置：

| Secret | 说明 | 是否必填 |
|--------|------|----------|
| `SERVER_HOST` | 生产服务器 IP | 是 |
| `SERVER_USER` | SSH 用户名（root） | 是 |
| `SERVER_SSH_KEY` | SSH 私钥 | 是 |
| `DASHSCOPE_API_KEY` | 阿里云 DashScope API Key | 是 |
| `ANDROID_KEYSTORE_BASE64` | huiyuyuan.jks 的 Base64 编码 | 推荐 |
| `ANDROID_STORE_PASSWORD` | Keystore 密码 | 推荐 |
| `ANDROID_KEY_PASSWORD` | Key 密码 | 推荐 |
| `ANDROID_KEY_ALIAS` | Key 别名（默认 huiyuyuan） | 推荐 |

---

## 9. 发布记录

每次发布后填写：

| 字段 | 值 |
|------|-----|
| 发布日期 | |
| 版本号 | |
| 构建号 | |
| 发布人 | |
| 变更摘要 | |
| 后端迁移 | ☐ 是 / ☐ 否 |
| 冒烟测试 | ☐ 通过 / ☐ 未通过 |
| 遗留问题 | |
| 回滚记录 | |
