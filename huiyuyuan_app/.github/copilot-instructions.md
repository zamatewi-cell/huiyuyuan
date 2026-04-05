# GitHub Copilot 自定义指令 — 汇玉源项目

## 项目概述
汇玉源（HuiYuYuan）— Flutter 跨平台珠宝智能交易平台 v3.0。前端 Flutter (Dart)，后端 FastAPI (Python) 单文件 `backend/main.py`（1800+ 行），部署于阿里云 ECS `47.98.188.141`。

## 核心模式
- **服务层单例**: 所有 `services/` 使用 `factory` + `static _instance` 模式
- **AI 三级降级**: DeepSeek → Gemini → 离线预设回复，新增 AI 功能须保持此链
- **API URL 平台感知**: `api_config.dart` 中 `baseUrl` 按 `kIsWeb` 分支，Web 走 Nginx 同源代理
- **Riverpod 状态管理**: 不引入 Provider/Bloc 等其他方案
- **多语言**: `l10n/app_strings.dart` Map 方式维护，新增文案须同时添加 zh_CN/en/zh_TW
- **设计风格**: "Liquid Glass" 毛玻璃，使用 `JewelryColors` 和 `JewelryTheme`
- **密钥管理**: API Key 放 `config/secrets.dart`（已 gitignore）

详细指令见项目根目录 `.github/copilot-instructions.md`。
