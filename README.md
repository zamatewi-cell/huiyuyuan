# 汇玉源珠宝智能交易平台 v3.0.0

<p align="center">
  <strong>🌟 Liquid Glass 设计风格 | DeepSeek AI 驱动 | 跨平台支持</strong>
</p>

---

## 🎯 项目概述

**汇玉源**是一款面向珠宝行业的智能交易平台，集成了 DeepSeek AI 技术，为珠宝商家提供智能化的销售、客服和管理体验。

### 核心功能
| 功能 | 描述 | 状态 |
|------|------|------|
| 🛒 **智能商城** | 浏览和购买精选珠宝产品 | ✅ 完成 |
| 🤖 **AI 助手** | 基于 DeepSeek 的智能客服"玉小助" | ✅ 完成 |
| 💳 **收款管理** | 多渠道收款账户管理 | ✅ 完成 |
| 📊 **管理后台** | 数据分析和系统管理 | ✅ 完成 |
| 👔 **商务工作台** | 店铺管理和 AI 话术生成 | ✅ 完成 |
| 🥽 **AR 试戴** | 虚拟珠宝试戴体验 | 🔄 开发中 |

---

## 🚀 快速开始

### 1. 环境要求
- Flutter SDK 3.27+
- Dart 3.6+
- Android Studio / VS Code
- Android SDK 34+ (兼容 Android 5.0+)
- Node.js (可选，仅用于 Web 开发)

### 2. 安装依赖
```bash
cd huiyuanyuan_app/
flutter pub get
```

### 3. 运行应用
```bash
# 在浏览器中运行 (推荐快速预览)
flutter run -d edge
flutter run -d chrome

# 在 Android 设备/模拟器上运行
flutter run

# 在 Windows 上运行 (需要 Visual Studio C++ 工具链)
flutter run -d windows
```

### 4. 测试账号
| 角色 | 账号 | 密码 | 验证码 |
|------|------|------|--------|
| **管理员** | 18937766669 | admin123 | 8888 |
| **操作员** | 1-10 (任意数字) | op123456 | - |

---

## 🎨 设计系统

本项目采用 **"Liquid Glass"** (流体玻璃) 设计风格，营造高端珠宝品牌的视觉体验：

### 设计特点
- **毛玻璃效果 (Glassmorphism)**：半透明磨砂质感
- **深色主题**：`#0D1B2A` 深邃背景
- **翡翠绿主色**：`#2E8B57` 品牌色
- **金色点缀**：`#D4AF37` 高光装饰
- **柔和渐变**：主色渐变 + 光晕阴影
- **流畅动画**：微交互提升体验

### 应用范围
- ✅ 底部导航栏 (玻璃态)
- ✅ AI 助手对话气泡
- ✅ 收款账户卡片
- ✅ 登录页面背景

---

## 🏗️ 项目结构

```
huiyuanyuan_project/
├── docs/                         # 📚 文档中心
│   ├── planning/                 #   规划: 任务列表、实施计划
│   ├── guides/                   #   指南: 部署/支付/测试
│   ├── design/                   #   设计: Liquid Glass 规范
│   └── reference/                #   归档: 历史参考文档
└── huiyuanyuan_app/              # 📱 Flutter 应用
    ├── lib/
    │   ├── config/               # 配置 (API/密钥)
    │   ├── data/                 # 静态数据 (商品/店铺)
    │   ├── l10n/                 # 国际化 (中/英/繁)
    │   ├── models/               # 数据模型 (4个)
    │   ├── providers/            # Riverpod 状态管理 (3个)
    │   ├── screens/              # 页面 (19个, 按功能模块)
    │   ├── services/             # 服务层 (12个, 单例)
    │   ├── themes/               # 主题 (颜色/Material)
    │   └── widgets/              # 通用组件
    └── test/                     # 测试 (16个测试文件)
```

> 📖 详细架构请查阅 [flutter-dev SKILL](.agent/skills/flutter-dev/SKILL.md)

---

## 🤖 AI 服务

### DeepSeek 集成
应用集成了 DeepSeek API，提供智能对话能力：

| 功能 | 说明 |
|------|------|
| 智能客服 | 回答珠宝相关问题 |
| 话术生成 | 自动生成商务邀约话术 |
| 产品描述 | AI 优化产品文案 |
| 聊天分析 | 意图识别 + 情感分析 |
| 敏感词过滤 | 符合《广告法》合规要求 |

### 离线兜底
当 API 不可用时，应用会自动切换到**离线回复模式**，确保用户体验不中断。

---

## 🔧 配置说明

### 1. API 配置
```dart
// lib/config/app_config.dart
class AppConfig {
  static const String deepseekApiKey = 'sk-xxx...';  // DeepSeek API Key
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String backendUrl = 'http://localhost:8000';  // 后端地址
}
```

### 2. 生产环境配置
部署到生产环境前，请确保：
- [ ] 替换 `deepseekApiKey` 为正式 Key
- [ ] 配置正式后端服务器地址
- [ ] 启用 HTTPS
- [ ] 关闭 Debug 模式

---

## 📦 构建与发布

### Android APK
```bash
# Debug 版本
flutter build apk --debug

# Release 版本 (需要签名配置)
flutter build apk --release
```

### Web 版本
```bash
flutter build web --release
```

### Windows 版本
```bash
# 需要 Visual Studio C++ 工具链
flutter build windows --release
```

---

## 📋 更新日志

### v3.0.2 (2026-02-14)
**代码质量 & 项目整理**
- 🧹 代码清理：0 error, 0 warning
- 🌐 多语言国际化完成 (中/英/繁)
- 📁 文档结构整理至 `docs/` 统一管理
- 🛠️ 创建企业级开发技能 (flutter-dev SKILL)
- 📷 商品图片选择集成

### v3.0.0 (2026-02-03)
**Liquid Glass 设计升级版**
- ✨ 收款账户管理、AI 助手重构、快捷操作
- 🎨 毛玻璃导航栏、玻璃态对话气泡、动态渐变
- 🔧 国际化修复、intl 升级、flutter_localizations

### v2.0.0 (2026-01-31)
- 后端对接 (FastAPI)
- DeepSeek AI 集成
- 视觉升级 (高清图片)

---

## 📖 文档导航

| 文档 | 路径 |
|------|------|
| 任务列表 | [`docs/planning/task.md`](../docs/planning/task.md) |
| 实施计划 | [`docs/planning/implementation_plan.md`](../docs/planning/implementation_plan.md) |
| 部署清单 | [`docs/guides/production_checklist.md`](../docs/guides/production_checklist.md) |
| 设计规范 | [`docs/design/design_system.md`](../docs/design/design_system.md) |
| 开发技能 | [`.agent/skills/flutter-dev/SKILL.md`](.agent/skills/flutter-dev/SKILL.md) |

---

*文档版本: 3.0.2 | 最后更新: 2026-02-14*
