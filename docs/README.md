# 汇玉源文档中心

> 最后更新：2026-04-28
> 说明：所有当前有效的项目文档统一放在 `docs/` 下；`docs/reference/` 和 `docs/reference/archive/` 仅作历史参考。

---

## 当前必读

| 文档 | 说明 | 状态 |
|------|------|------|
| [项目状态总览 2026-04-28](project_status_20260428.md) | UI 重构上线后的真实状态、验证结果、风险和后续建议 | 当前权威 |
| [当前状态速览](current_status_20260402.md) | 历史状态速览，已补充 2026-04-28 最新结论 | 当前可读 |
| [生产部署指南](guides/deployment_guide_updated.md) | 服务器路径、部署命令、验证与排障 | 当前权威 |
| [生产安全清单](guides/production_security_checklist_v2.md) | 生产安全基线、账号、JWT、CORS、数据库等检查 | 当前权威 |
| [AI 服务指南](guides/ai_service_guide.md) | DashScope 文本/视觉能力、前后端配置方式 | 当前权威 |
| [设计系统](design/design_system.md) | Liquid Glass 视觉规范与 Flutter 落地规则 | 当前权威 |
| [Figma UI 重构交接](design/figma_ui_redesign_handoff.md) | Figma/视觉继续设计时的方向与范围 | 当前可用 |

---

## 目录结构

```text
docs/
├── project_status_20260428.md        # 最新项目状态总览
├── current_status_20260402.md        # 状态速览，含历史复盘
├── README.md                         # 文档入口
├── design/                           # 设计系统与 Figma 交接
├── guides/                           # 部署、测试、安全、AI、支付等指南
├── planning/                         # 规划、任务清单、技术债
├── reference/                        # 历史参考资料
└── reference/archive/                # 更早版本归档
```

---

## 常用链接

### 发版与运维

| 文档 | 用途 |
|------|------|
| [生产部署指南](guides/deployment_guide_updated.md) | 日常发版入口，包含 `scripts/deploy.ps1` 用法 |
| [回滚指南](guides/rollback_guide.md) | 生产异常时回滚后端或静态资源 |
| [生产检查清单](guides/production_checklist.md) | 上线前后人工检查项 |
| [域名与 SSL 指南](guides/domain_and_ssl_setup_guide.md) | 域名、HTTPS、证书相关排障 |

### 产品与设计

| 文档 | 用途 |
|------|------|
| [设计系统](design/design_system.md) | 色彩、玻璃态、字体、组件规范 |
| [Figma UI 重构交接](design/figma_ui_redesign_handoff.md) | 后续继续补 Figma 设计时使用 |
| [UI 优化指南](ui_optimization_guide.md) | 局部页面优化方法 |
| [UI 优化策略](ui_optimization_strategies.md) | 更完整的视觉优化策略 |

### 开发与测试

| 文档 | 用途 |
|------|------|
| [快速启动指南](guides/快速启动指南.md) | Windows / Chrome / Android 启动方式 |
| [测试指南](guides/testing_guide.md) | 前后端测试命令与场景 |
| [设备测试用例](guides/device_test_cases.md) | 真机与多端测试清单 |
| [AI 服务指南](guides/ai_service_guide.md) | DashScope 配置和降级策略 |
| [支付指南](guides/payment_guide.md) | 支付接入方向与约束 |

### 规划

| 文档 | 用途 |
|------|------|
| [v4 总体规划](planning/v4_master_plan.md) | v4 架构与协作总览 |
| [任务清单](planning/task.md) | 当前任务、已完成事项和待办 |
| [后续任务](planning/follow_up_tasks.md) | 后续迭代候选池 |

---

## 当前项目状态摘要

- 生产站点已部署：`https://xn--lsws2cdzg.top`
- 服务器：`47.112.98.191`
- 后端：FastAPI + PostgreSQL + Redis，systemd 服务 `huiyuyuan-backend`
- 前端：Flutter Web 已完成 Liquid Glass UI 重构并上线
- AI：DashScope 千问文本与视觉能力，前端/后端均有离线兜底
- 支付：当前为人工确认到账闭环，未接入第三方自动回调
- GitHub：账号申诉中，本地提交尚未推送远端

更多细节见：[项目状态总览 2026-04-28](project_status_20260428.md)。
