# 汇玉源 - AI 服务架构指南

> 最后更新: 2026-03-17
> ⚠️ 2026-03-25 更正：旧 OpenRouter 文案已过时，当前主链路为 DashScope / 千问（Qwen）

---

## 概述

汇玉源当前将文本对话与图片识别分别通过 **DashScope（阿里云百炼）** 接入千问（Qwen）系列模型：

- 提供方：`DashScope / 阿里云百炼`
- 文本对话模型：`qwen-plus`（`AppConfig.dashScopeModel`）
- 图片识别模型：`qwen-vl-plus-latest`（`DASHSCOPE_VISION_MODEL`）
- 基地址：`https://dashscope.aliyuncs.com/compatible-mode/v1`
- 文本对话：Flutter 客户端经 `AIDashScopeService` 直连 DashScope
- 图片识别：FastAPI 后端代理 `/api/ai/analyze-image`
- 兜底策略：DashScope 不可用时回退到本地离线回复

---

## 配置位置

### Flutter 客户端

文件：`huiyuyuan_app/lib/config/secrets.dart`

```dart
class Secrets {
  static const String dashScopeApiKey = String.fromEnvironment(
    'DASHSCOPE_API_KEY',
    defaultValue: '',
  );
}
```

读取逻辑见 `lib/config/app_config.dart`：优先读 `DASHSCOPE_API_KEY`，兼容旧 `OPENROUTER_API_KEY` 作为回退；密钥须以 `sk-` 开头且不得以 `sk-or-` 开头。

### FastAPI 后端

文件：`huiyuyuan_app/backend/.env`

```env
DASHSCOPE_API_KEY=sk-xxxxxxxx
DASHSCOPE_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
DASHSCOPE_VISION_MODEL=qwen-vl-plus-latest
```

后端 `config.py` 以 `DASHSCOPE_API_KEY` 为主键名读取；若缺失则回退读 `OPENROUTER_API_KEY`（兼容旧环境）。

### 生产构建推荐

```bash
flutter build apk --release \
  --dart-define=DASHSCOPE_API_KEY=sk-your-dashscope-key
```

---

## 运行逻辑

### 1. 文本对话

入口：`huiyuyuan_app/lib/services/ai_service.dart`

- 通过 `AIDashScopeService` 调用 DashScope `chat/completions`
- 支持普通对话（`createChatCompletion`）和 SSE 流式输出（`createChatCompletionStream`）
- 附带珠宝行业 system prompt 与商品上下文
- DashScope 返回空或抛出异常时回退到本地离线话术

### 2. 图片识别

入口：`huiyuyuan_app/backend/services/ai_service.py`

- 通过 `/api/ai/analyze-image` 上传图片
- 后端将图片转成 `data:` URL 后发送到 DashScope（模型：`qwen-vl-plus-latest`）
- 返回结构化字段：`description`、`material`、`category`、`tags`、`quality_score`、`suggestion`

### 3. Flutter 图片分析组件

入口：`huiyuyuan_app/lib/services/gemini_image_service.dart`

- 保留旧类名以兼容现有页面
- 实际实现已改为复用后端 `/api/ai/analyze-image`
- 不再直连 Gemini

---

## 常见问题

### Q: AI 一直走离线模式？

按顺序检查：

1. `AppConfig.dashScopeApiKeyIssue` 是否为 null（可在 debug 控制台打印）
2. `DASHSCOPE_API_KEY` 是否已通过 `--dart-define` 或 `.env.json` 注入且以 `sk-` 开头
3. 当前网络是否能访问 `https://dashscope.aliyuncs.com`
4. 检查 DashScope 账号配额或限流状态

### Q: 图片识别不工作？

按顺序检查：

1. `huiyuyuan_app/backend/.env` 是否存在 `DASHSCOPE_API_KEY`
2. 服务是否已重启（`systemctl restart huiyuyuan-backend`）
3. 使用 `curl -X POST http://localhost:8000/api/ai/analyze-image -F 'file=@test.jpg'` 自测
4. 图片体积是否超过 10MB

---

## 备注

项目中的部分 `archive/`、历史规划和 Agent 文档仍保留旧的 DeepSeek / Gemini / OpenRouter 记录，这些属于历史材料，不代表当前运行配置。当前权威配置以本文档和 `app_config.dart` / `backend/config.py` 为准。