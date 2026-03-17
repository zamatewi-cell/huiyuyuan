# 汇玉源 - AI 服务架构指南

> 最后更新: 2026-03-17

---

## 概述

汇玉源当前将文本对话与图片识别统一到 **OpenRouter**，并固定使用同一个免费多模态模型：

- 提供方：`OpenRouter`
- 模型：`nvidia/nemotron-nano-12b-v2-vl:free`
- 文本对话：Flutter 客户端直连 OpenRouter
- 图片识别：FastAPI 后端代理 `/api/ai/analyze-image`
- 兜底策略：远程模型不可用时回退到本地离线回复

---

## 配置位置

### Flutter 客户端

文件：`huiyuanyuan_app/lib/config/secrets.dart`

```dart
class Secrets {
  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: 'sk-or-v1-xxxxxxxx',
  );
}
```

### FastAPI 后端

文件：`huiyuanyuan_app/backend/.env`

```env
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxx
OPENROUTER_MODEL=nvidia/nemotron-nano-12b-v2-vl:free
OPENROUTER_SITE_URL=https://huiyuanyuan.local
OPENROUTER_APP_NAME=汇玉源
```

### 生产构建推荐

```bash
flutter build apk --release \
  --dart-define=OPENROUTER_API_KEY=sk-or-v1-your-key
```

---

## 运行逻辑

### 1. 文本对话

入口：`huiyuanyuan_app/lib/services/ai_service.dart`

- 使用 OpenRouter OpenAI-compatible `chat/completions`
- 支持普通对话和 SSE 流式输出
- 附带珠宝行业 system prompt 与商品上下文
- 失败时回退到本地离线话术

### 2. 图片识别

入口：`huiyuanyuan_app/backend/services/ai_service.py`

- 通过 `/api/ai/analyze-image` 上传图片
- 后端将图片转成 `data:` URL 后发送到 OpenRouter
- 返回结构化字段：`description`、`material`、`category`、`tags`、`quality_score`、`suggestion`

### 3. Flutter 图片分析组件

入口：`huiyuanyuan_app/lib/services/gemini_image_service.dart`

- 保留旧类名以兼容现有页面
- 实际实现已改为复用后端 `/api/ai/analyze-image`
- 不再直连 Gemini

---

## 常见问题

### Q: AI 一直走离线模式？

按顺序检查：

1. `lib/config/secrets.dart` 中的 `OPENROUTER_API_KEY` 是否有效
2. 当前网络是否能访问 `https://openrouter.ai`
3. 免费模型是否临时限流或排队
4. 后端图片识别是否已加载 `backend/.env`

### Q: 图片识别不工作？

按顺序检查：

1. `huiyuanyuan_app/backend/.env` 是否存在 `OPENROUTER_API_KEY`
2. 服务是否已重启
3. 使用 `curl -X POST http://localhost:8000/api/ai/analyze-image -F 'file=@test.jpg'` 自测
4. 图片体积是否超过 10MB

---

## 备注

项目中的部分 `archive/`、历史规划和 Agent 文档仍保留旧的 DeepSeek / Gemini / DashScope 记录，这些属于历史材料，不代表当前运行配置。