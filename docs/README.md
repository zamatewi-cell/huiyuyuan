# 📚 汇玉源项目文档中心

> 所有项目文档统一管理于此目录。
> 最后更新: 2026-04-08

---

## 📁 目录结构

```text
docs/
├── planning/                    # 📋 规划文档（活跃维护）
│   ├── v4_master_plan.md           # ★ v4.0 总规划（多Agent协同，当前主文档）
│   └── task.md                     # 任务清单与进度
├── guides/                      # 📖 操作指南
│   ├── ai_service_guide.md         # AI 服务架构（DashScope + 离线兜底）
│   ├── deployment_guide_updated.md # ★ 当前权威生产部署指南
│   ├── deployment_guide.md         # 已归并到 deployment_guide_updated.md
│   ├── production_security_checklist_v2.md # ★ 当前权威安全清单
│   ├── production_security_checklist_20260402.md # 已归并到 production_security_checklist_v2.md
│   ├── production_checklist.md     # 生产部署检查清单
│   ├── payment_guide.md            # 支付集成指南
│   ├── testing_guide.md            # 测试指南
│   ├── device_test_cases.md        # 设备测试用例
│   └── 快速启动指南.md              # Windows/Android/Web 本地运行方法
├── design/                      # 🎨 设计文档
│   └── design_system.md            # Liquid Glass 设计系统（含 Flutter 实现规范）
├── agent_a_docs/                # 🤖 Agent A - 后端架构师
├── agent_b_docs/                # 🤖 Agent B - 前端质量工程师
├── agent_c_docs/                # 🤖 Agent C - 测试与安全专家
├── agent_d_docs/                # 🤖 Agent D - DevOps 运维
├── agent_e_docs/                # 🤖 Agent E - 生产发布工程师
└── reference/                   # 📦 归档参考（历史版本，不再维护）
    ├── v3_implementation_plan.md        # v3.0 实施计划
    ├── v3_task.md                       # v3.0 任务清单
    ├── v3.0_feature_matrix_20260201.csv # v3.0 功能矩阵
    ├── UI优化方案.md                    # v2→v3 UI 优化方案（已落地）
    ├── 项目评估报告.md                  # v2.0 评估报告（历史快照）
    └── archive/                         # 更早期规划归档
        ├── v3.1_upgrade_plan.md
        ├── v3.2_upgrade_plan.md
        ├── v3.3_enterprise_plan.md
        ├── implementation_plan.md
        ├── next_steps_action_plan.md
        └── next_dev_prompt.md
```

---

## 🔗 快速跳转

| 文档 | 说明 | 状态 |
|------|------|------|
| [v4 总规划](planning/v4_master_plan.md) | 多Agent协同、后端模块化、PostgreSQL、安全加固 | 🔄 当前主规划 |
| [任务清单](planning/task.md) | 项目待办/进行中/已完成任务 | 🔄 活跃维护 |
| [生产部署指南](guides/deployment_guide_updated.md) | 一键部署、CI/CD、服务器运维 | ✅ 当前权威 |
| [生产安全清单](guides/production_security_checklist_v2.md) | 服务器与应用层安全基线 | ✅ 当前权威 |
| [AI 服务指南](guides/ai_service_guide.md) | DashScope 接入、接口说明、离线兜底 | ✅ 已定稿 |
| [设计系统](design/design_system.md) | Liquid Glass 风格规范 + Flutter 实现代码 | ✅ 已定稿 |
| [测试指南](guides/testing_guide.md) | 功能测试用例、AI 降级测试 | ✅ 可参考 |
| [设备测试](guides/device_test_cases.md) | 真机测试用例集 | ✅ 可参考 |
| [快速启动](guides/快速启动指南.md) | 本地环境搭建与运行 | ✅ 可参考 |
| [部署清单](guides/production_checklist.md) | 上线前完整检查清单 | 📋 待执行 |
| [支付指南](guides/payment_guide.md) | 微信/支付宝支付集成指南 | 📋 待执行 |

### Agent 工作文档

| Agent | 角色 | 文档 |
|-------|------|------|
| A | 后端架构师 | [identity](agent_a_docs/identity.md) / [changelog](agent_a_docs/change_log.md) / [roadmap](agent_a_docs/roadmap.md) |
| B | 前端质量工程师 | [identity](agent_b_docs/identity.md) / [changelog](agent_b_docs/change_log.md) / [roadmap](agent_b_docs/roadmap.md) |
| C | 测试与安全专家 | [identity](agent_c_docs/identity.md) / [changelog](agent_c_docs/change_log.md) / [roadmap](agent_c_docs/roadmap.md) |
| D | DevOps 运维 | [identity](agent_d_docs/identity.md) / [changelog](agent_d_docs/change_log.md) / [roadmap](agent_d_docs/roadmap.md) |
| E | 生产发布工程师 | [identity](agent_e_docs/identity.md) / [changelog](agent_e_docs/change_log.md) / [roadmap](agent_e_docs/roadmap.md) |

---

## 📊 项目状态速览 (2026-04-08)

| 指标 | 数值 |
|------|------|
| 当前版本 | v4.0 稳定化收尾 |
| 页面/屏幕 | 23+ |
| 测试状态 | ✅ backend `167 passed` / flutter `490 passed` |
| 静态检查 | ✅ `dart analyze lib test tool --no-fatal-warnings` |
| 服务器 | ✅ xn--lsws2cdzg.top 运行中 |
| 多Agent协同 | A(后端) B(前端) C(测试) D(运维) E(发布) |
| 主规划文档 | `planning/v4_master_plan.md` |

---

## 🗂️ 文档归并说明（2026-04-08）

- `guides/deployment_guide_updated.md` 为当前唯一生产部署权威文档；`guides/deployment_guide.md` 已保留为旧链接跳转说明。
- `guides/production_security_checklist_v2.md` 为当前唯一安全基线文档；`guides/production_security_checklist_20260402.md` 已保留为归并说明。
- `CLAUDE.md` 与 `AGENTS.md` 已同步到同一修复基线，后续状态更新应保持同日同步。
