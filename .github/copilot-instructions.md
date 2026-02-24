# GitHub Copilot 自定义指令 — 汇玉源项目

## 项目概述
汇玉源（HuiYuYuan）是一个 Flutter 跨平台珠宝智能交易平台，后端 FastAPI，部署于阿里云 ECS。

## 技术栈
- **前端**: Flutter (Dart) — Android / iOS / Web
- **后端**: FastAPI (Python) + Gunicorn + Nginx
- **数据库**: PostgreSQL 14 + Redis
- **AI**: DashScope Qwen-VL (图片识别), DeepSeek (文本对话)
- **部署**: 阿里云 ECS, 静态资源 Nginx 托管

## 编码规范
- Dart: 遵循 `analysis_options.yaml`，使用 Riverpod 状态管理
- Python: 遵循 PEP8，使用 async/await
- 提交消息使用中文，格式 `类型: 描述`
