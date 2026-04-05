# 汇玉源生产部署检查清单

> 最后更新: 2026-03-17

---

## 安全配置

### 1. API Key 管理
- [ ] 将 `lib/config/secrets.dart` 中的 `_localOpenRouterApiKey` 替换为生产密钥，或改为仅通过 `--dart-define` 注入
- [ ] 生产构建使用 `--dart-define=OPENROUTER_API_KEY=sk-or-v1-xxx`
- [ ] 后端 `huiyuyuan_app/backend/.env` 中配置 `OPENROUTER_API_KEY`
- [ ] 核对 `OPENROUTER_MODEL` 是否为 `nvidia/nemotron-nano-12b-v2-vl:free`
- [ ] 为 OpenRouter 调用设置额度与异常告警

### 2. 应用与网络
- [ ] `lib/config/api_config.dart` 中 `useMockApi` 为 `false`
- [ ] 前后端地址已切换为正式环境
- [ ] Nginx / 反向代理已启用 HTTPS
- [ ] Debug 开关与开发日志已关闭或降级

### 3. 凭据与存储
- [ ] 管理员密码、验证码等开发默认值已移除或改为环境注入
- [ ] Token 和敏感信息仅存储在安全存储中
- [ ] `.env`、`secrets.dart`、日志文件未被提交到版本控制

---

## AI 服务

### 1. 文本对话
- [ ] Flutter 客户端能够正常访问 OpenRouter `chat/completions`
- [ ] 流式输出可用，失败时能回退到离线回复
- [ ] 商品上下文注入后，推荐内容仍能正常输出 `[PRODUCT:ID]`

### 2. 图片识别
- [ ] `/api/ai/analyze-image` 可成功返回结构化 JSON
- [ ] 大于 10MB 的图片会被正确拦截
- [ ] 后端 `.env` 已被自动加载，且不依赖手动导出环境变量
- [ ] 图片识别失败时前端能展示明确错误或降级提示

---

## 部署验证

### 1. 基础检查
- [ ] 后端健康检查 `/api/health` 正常
- [ ] 登录、商品列表、下单、聊天、图片识别均可用
- [ ] OSS 上传、短信、通知等非 AI 关键能力未受本次改动影响

### 2. 回归检查
- [ ] AI 助手文本对话正常
- [ ] 聊天页上传图片后能得到视觉分析补充信息
- [ ] 商品图片选择组件的 AI 分析能正常工作
- [ ] 离线兜底回复仍可触发

---

## 备注

项目内仍有部分 `archive/`、历史规划和 Agent 资料保留旧提供方记录；上线时以当前代码与本清单为准。