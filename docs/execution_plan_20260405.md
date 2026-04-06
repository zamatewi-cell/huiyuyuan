# 汇玉源执行总规划（2026-04-05）

## 1. 目的

这份文档用于把后续工作从“零散修补”切换成“按阶段交付”。

目标不是继续堆功能，而是把当前系统收敛成一条可交付、可测试、可发布、可接手的正式路线。

---

## 2. 当前基线

截至 2026-04-05，已经完成的关键基线如下：

### 2.1 账号与登录

- 已支持注册、密码登录、验证码登录、找回密码、修改密码、注销账号
- 用户账号信息已存储到服务端
- 已补主机名校验、登录限流、安全响应头等基础安全措施
- Android 端已支持服务端版本检查和更新提示

### 2.2 支付闭环

- 已支持平台统一收款账户
- 订单已可绑定收款账户
- 支付页已可展示收款二维码
- 已改成管理员确认到账后再变更订单状态

### 2.3 多语言治理

- `app_strings.dart` 的历史中文字面量兼容 key 已清空
- i18n 审计和测试守卫已建立
- 主用户链路的多语言脏点已大幅清理
- 通知、后台活动、订单物流等 key + args 结构已逐步统一

### 2.4 通知链路

- 通知列表、推送缓存、后台通知接口、订单 websocket 已基本对齐为结构化文案
- 前端 websocket 客户端已接入通知状态
- 主导航、商城、个人中心、管理员、操作员的未读角标已接入
- 通知相关测试基座已建立

### 2.5 工程治理

- 已建立 i18n guard
- 已补若干关键 widget / provider / service 测试
- 已逐步压掉用户侧和后台若干高噪声 analyze 问题

---

## 3. 现阶段真实问题

虽然基线已经比最初稳很多，但离“可交差的企业级项目”还有几个关键差距：

### 3.1 产品层

- 用户侧通知体验还缺少更完整的跨入口联动回归
- 设置、提醒、通知、更新之间的体验还没有完全统一
- 支付闭环还缺对账、异常单、取消支付、退款/撤销等边角流程

### 3.2 安全层

- 还缺图形验证码/滑块验证
- 还缺设备登录记录、异地登录提醒、会话治理
- 还缺更完整的云侧 WAF / CDN / Anti-DDoS / 备份告警

### 3.3 发布层

- Android 还没有正式签名与正式发版链
- iOS 还没有 TestFlight / App Store 正式交付路径
- 线上发布还缺更正式的 smoke checklist 和 rollback 手册

### 3.4 工程层

- 还有部分测试样板和场景工具需要继续抽象
- 后台与运营端仍有一些历史代码面债务
- 仍需把“不会回退到脏状态”变成更强的 CI 门禁

---

## 4. 总体执行原则

后续不再按“看到哪里坏就补哪里”的方式推进，而是按下面四条原则执行：

### 4.1 先收口，再扩展

如果某条业务链主流程还没完全稳定，不继续往外长新功能。

### 4.2 先用户链路，再后台增强

优先保证登录、商城、订单、支付、通知、我的这些一线链路稳定。

### 4.3 先可测，再发布

没有测试支撑的改动，不进入正式发布批次。

### 4.4 先阶段交付，再汇总发布

每一阶段都有明确边界、验收口径和是否上线的判断，不再混成一锅。

---

## 5. 后续阶段规划

下面是建议的执行顺序。除非你中途改变方向，否则后续就按这个顺序推进。

---

## Phase A：通知与主壳层完全收口

### 目标

把通知链从“已经能用”推进到“主入口全覆盖、回归可依赖、后续可维护”。

### 范围

- 统一通知相关测试工具
- 补齐主壳层、用户入口、后台入口、操作员入口的联动场景
- 验证进入通知中心、标记已读、返回上层后角标同步变化
- 清理通知链剩余重复样板和低质量测试实现

### 交付物

- 共享通知测试工具层
- 入口级联动测试
- 统一的未读角标断言方式

### 验收标准

- 主导航、商城、我的、管理员、操作员通知入口均有回归测试
- 不再通过“直接改状态”绕过 UI 操作
- 相关测试通过，analyze 通过，i18n guard 通过

### 预计结果

完成后，通知这一块就不再是“局部修好”，而是一条稳定的产品基础设施。

---

## Phase B：用户账号安全增强

### 目标

把当前账号体系从“基础可用”提升到“安全上可交代”。

### 范围

- 图形验证码或滑块验证
- 短信发送频控细化
- 密码强度与异常登录提示优化
- 设备登录记录
- 会话管理与退出其它设备
- 异地/新设备登录提醒

### 交付物

- 前后端安全校验补全
- 设置页中的登录设备管理入口
- 安全相关的提示文案与通知模板
- 对应测试与安全清单更新

### 验收标准

- 短时间内频繁请求验证码会被限制
- 新设备登录可记录与提示
- 用户可查看并管理登录设备或会话
- 核心账号接口具备更明确的风控门槛

---

## Phase C：支付链深化到可运营

### 目标

把现有“管理员确认到账”的闭环，从内部演练级推进到内部运营级。

### 范围

- 支付待确认 / 已确认 / 已取消 / 已超时状态细化
- 异常订单处理
- 订单支付备注、打款说明、凭证上传
- 管理员对账视图
- 支付通知与审计日志
- 取消支付、重复支付、超时未付等边界场景

### 交付物

- 订单支付状态机增强
- 管理员支付处理页/对账页
- 测试清单和内部演练流程文档更新

### 验收标准

- 管理员可明确区分“待确认到账”和“异常待处理”
- 支付异常不会把订单推进到错误状态
- 订单支付记录具备基本可追溯性

---

## Phase D：发布与更新体系正式化

### 目标

让 Android / iOS 的分发链路不再停留在“能打包”，而是可正式交付。

### 范围

#### Android

- release keystore 正式签名
- 版本号策略固化
- 更新下载与提示体验打磨
- 手动检查更新与自动提醒联动

#### iOS

- TestFlight 发布准备
- 签名、Bundle、图标、权限文案核对
- App Store Connect 提交流程清单

### 交付物

- Android 正式签名流程
- iOS 测试发布说明
- 发布 checklist
- 版本回滚说明

### 验收标准

- Android 能输出正式签名包
- iOS 能进入 TestFlight 测试链路
- 更新机制与版本接口对齐

---

## Phase E：基础设施与安全加固

### 目标

把“应用层安全”继续推进到“运维层安全”。

### 范围

- WAF / CDN / Anti-DDoS 接入建议与落地
- SSH 运维账户收口
- fail2ban 持续维护
- 备份、日志、监控、告警
- 密钥和环境变量管理流程

### 交付物

- 生产安全清单 v2
- 运维收口建议
- 基础设施改造脚本或操作说明

### 验收标准

- 至少一套外层防护方案明确落地
- SSH 权限模型收紧
- 备份和告警链可执行

---

## Phase F：后台/运营端工程面收尾

### 目标

把前面为了赶主链路而暂缓的后台和运营端工程面债务系统清理掉。

### 范围

- 后台高噪声 analyze 信息继续压缩
- 历史注释、重复测试样板、脏文案继续清理
- 测试工具层沉淀
- 通知/活动/运营看板的多语言与结构统一

### 交付物

- 工程减噪
- 共享测试工具
- 更完整的 CI 门禁

### 验收标准

- 重点后台文件不再反复刷屏
- 测试样板和 helper 收口
- 回归失败时更容易定位

---

## Phase G：正式发布前总验收

### 目标

在真正对外或对更大范围内部使用之前，做一次完整收官。

### 范围

- 三语言人工 smoke
- 多角色账号回归
- 支付演练
- 通知演练
- 更新演练
- 安全演练
- 数据库迁移核验
- 发布快照与回滚包准备

### 交付物

- 最终验收清单
- 发布说明
- 回滚说明
- 接手文档更新版

### 验收标准

- 有清单、有结果、有残留问题说明
- 不再靠口头同步项目状态

---

## 6. 发线上详细步骤（标准 SOP）

这一节不是阶段目标，而是下次真正要发线上时可以直接照着走的操作手册。

默认本地工作目录：

`D:\huiyuyuan_project`

### 6.1 线上固定信息

| 项目 | 值 |
|------|------|
| 生产服务器 | `47.112.98.191` |
| SSH 用户 | `root` |
| 主域名 | `xn--lsws2cdzg.top` |
| 后端目录 | `/srv/huiyuyuan/backend/` |
| 生产环境变量 | `/srv/huiyuyuan/backend/.env` |
| 前端静态目录 | `/var/www/huiyuyuan/` |
| systemd 服务 | `huiyuyuan-backend` |
| Nginx 配置 | `/etc/nginx/conf.d/huiyuyuan.conf` |
| Nginx 代理片段 | `/etc/nginx/snippets/proxy_params.conf` |
| 后端快照目录 | `/opt/huiyuyuan/snapshots/` |
| 脚本入口 | `scripts/deploy.ps1` |

### 6.2 SSH 前置检查

日常发版脚本 `scripts/deploy.ps1` 默认直接调用系统 `ssh/scp`，不会额外传 `-i` 参数。

所以要保证下面至少满足一条：

- 私钥已经放在默认位置，例如 `%USERPROFILE%\.ssh\id_rsa` 或 `%USERPROFILE%\.ssh\id_ed25519`
- 或者已经通过 `ssh-agent` 加载了对应私钥
- 或者已经在 `%USERPROFILE%\.ssh\config` 里配好默认身份

先执行这些命令确认：

```powershell
cd D:\huiyuyuan_project
Get-ChildItem $env:USERPROFILE\.ssh
ssh root@47.112.98.191 "echo CONNECTED"
```

如果最后一条能返回 `CONNECTED`，说明后续发布脚本才能正常工作。

如果 SSH 失败，优先检查：

- 阿里云安全组是否放行 `22`
- 当前电脑私钥是否和服务器 `authorized_keys` 匹配
- 服务器是否仍允许 root 密钥登录

### 6.3 本地发布前固定动作

发版前统一先做这几步：

```powershell
cd D:\huiyuyuan_project
git status --short
```

如果本次包含用户可见前端改动，再跑：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_huiyuyuan_i18n_guard.ps1
```

如果本次涉及后端逻辑或数据库迁移，再补：

```powershell
cd D:\huiyuyuan_project\huiyuyuan_app
python -m pytest backend\tests\test_admin.py -q
python -m pytest backend\tests\test_orders.py -q
python -m pytest backend\tests\test_notifications.py -q
```

注意：

- 如果只是局部改动，可以替换成对应模块的定向测试
- 不能在“本地没有跑通”的情况下直接发线上

### 6.4 标准发布方式

#### A. 全量发布：后端 + Nginx + 前端

适用于一次把主功能完整发上去：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1
```

这会自动做：

1. SSH 连通性检查
2. 可选 `dart analyze`
3. 可选 `flutter build web --release`
4. 后端代码同步到 `/srv/huiyuyuan/backend`
5. `pip install -r requirements.txt`
6. `alembic upgrade head`
7. 重启 `huiyuyuan-backend`
8. 下发 Nginx 配置并 `nginx -t`
9. 上传前端构建产物到 `/var/www/huiyuyuan/`
10. 校验后端健康检查

#### B. 只发布后端

适用于：

- FastAPI 逻辑改动
- 数据库迁移
- 支付、通知、登录等后端接口修改

命令：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target backend
```

#### C. 只发布前端 Web

适用于：

- Flutter Web 页面改动
- 多语言修复
- 视觉或交互修复

命令：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target web
```

#### D. 只发布 Nginx

适用于：

- 反代配置调整
- 静态资源缓存
- TLS / 反向代理 / 限流配置修改

命令：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target nginx
```

#### E. 初始化数据库

只在新环境或明确需要 bootstrap 时使用：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target db-init
```

### 6.5 当前推荐的安全发版顺序

如果不是小修补，而是正式发一批内容，建议按这个顺序：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target backend
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target nginx
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target web
powershell -ExecutionPolicy Bypass -File .\scripts\verify_public_ingress.ps1
```

这种拆开发的好处是：

- 后端失败时更容易定位
- Nginx 问题不会和前端构建问题混在一起
- Web 静态资源上线时间更可控

### 6.6 脏工作区时的 Web 发布方式

如果当前仓库有很多未整理改动，不要直接在脏工作区发 Web。

推荐做法：

1. 从当前仓库 `HEAD` 建一个干净快照目录，例如：

```powershell
cd D:\huiyuyuan_project
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$releaseDir = "D:\huiyuyuan_project\.release\web_$stamp"
git clone --no-hardlinks . $releaseDir
git -C $releaseDir checkout HEAD
```

2. 只把本次需要上线的文件覆盖进这个快照
3. 在快照目录里跑检查和构建
4. 在快照目录里执行发布脚本

示例：

```powershell
cd $releaseDir
powershell -ExecutionPolicy Bypass -File .\scripts\run_huiyuyuan_i18n_guard.ps1
cd .\huiyuyuan_app
flutter build web --no-tree-shake-icons --release
cd ..
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target web -SkipAnalyze -SkipBuild
```

### 6.7 发版后立即验收

#### 本地验收

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\verify_public_ingress.ps1
```

#### 服务器验收

```powershell
ssh root@47.112.98.191
systemctl status huiyuyuan-backend --no-pager
systemctl status nginx --no-pager
curl http://127.0.0.1:8000/api/health
nginx -t
journalctl -u huiyuyuan-backend -n 50 --no-pager
tail -n 50 /var/log/nginx/huiyuyuan_error.log
```

#### Web 静态资源时间戳验收

```powershell
ssh root@47.112.98.191 "stat -c '%y %n' /var/www/huiyuyuan/index.html /var/www/huiyuyuan/main.dart.js"
```

#### 公网快速验收

```powershell
curl.exe -I https://xn--lsws2cdzg.top/
curl.exe -I https://xn--lsws2cdzg.top/api/health
```

### 6.8 回滚方式

#### 后端回滚

`deploy.ps1` 已内建后端快照回滚。

先看可用快照：

```powershell
ssh root@47.112.98.191 "ls -dt /opt/huiyuyuan/snapshots/*"
```

然后执行：

```powershell
cd D:\huiyuyuan_project
powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Target backend -Rollback 20260403_123456
```

#### Web 回滚

脚本目前没有自动化 Web 回滚。

所以下次发 Web 前，建议先手工备份：

```powershell
ssh root@47.112.98.191 "stamp=\$(date +%Y%m%d_%H%M%S); mkdir -p /opt/huiyuyuan/web-snapshots/\$stamp; cp -a /var/www/huiyuyuan/. /opt/huiyuyuan/web-snapshots/\$stamp/"
```

需要恢复时：

```powershell
ssh root@47.112.98.191 "cp -a /opt/huiyuyuan/web-snapshots/20260403_234202/. /var/www/huiyuyuan/ && systemctl reload nginx"
```

### 6.9 常见故障先看哪里

#### SSH 连不上

- 本机先执行：`ssh root@47.112.98.191 "echo CONNECTED"`
- 检查 22 端口、安全组、私钥、root 登录权限

#### 后端启动失败

```powershell
ssh root@47.112.98.191 "journalctl -u huiyuyuan-backend -n 100 --no-pager"
```

#### Alembic 失败

```powershell
ssh root@47.112.98.191 "bash -lc 'cd /srv/huiyuyuan/backend && source venv/bin/activate && alembic current && alembic heads'"
```

#### Nginx 配置异常

```powershell
ssh root@47.112.98.191 "nginx -t"
```

#### HTTPS 正常但接口异常

先看：

```powershell
ssh root@47.112.98.191 "cat /srv/huiyuyuan/backend/.env | grep ALLOWED_ORIGINS"
```

### 6.10 当前权威入口

下次发线上时，优先看这三个文件，不要凭记忆操作：

- [scripts/deploy.ps1](/D:/huiyuyuan_project/scripts/deploy.ps1)
- [scripts/verify_public_ingress.ps1](/D:/huiyuyuan_project/scripts/verify_public_ingress.ps1)
- [deployment_guide_updated.md](/D:/huiyuyuan_project/docs/guides/deployment_guide_updated.md)

---

## 7. 推荐执行顺序

建议后续按下面顺序推进，不再来回切题：

1. Phase A：通知与主壳层完全收口
2. Phase B：用户账号安全增强
3. Phase C：支付链深化到可运营
4. Phase D：发布与更新体系正式化
5. Phase E：基础设施与安全加固
6. Phase F：后台/运营端工程面收尾
7. Phase G：正式发布前总验收

---

## 8. 每阶段固定输出格式

后续每个阶段结束时，统一按下面格式汇报，不再“挤牙膏”：

### 7.1 已完成

- 本阶段做了什么
- 改了哪些链路
- 关键文件在哪里

### 7.2 已验证

- 跑了哪些测试
- 哪些 analyze / audit 通过
- 是否做了线上验证

### 7.3 未做项

- 本阶段刻意没做的内容
- 为什么没做

### 7.4 下一阶段

- 下一阶段的明确目标
- 会动哪些模块
- 是否涉及发布

---

## 9. 接下来默认执行策略

除非你明确改方向，否则后续我会按这个节奏推进：

### 当前默认下一阶段

优先完成 Phase A，也就是：

- 继续把通知测试工具层抽象完整
- 把通知入口联动测试覆盖到更多真实入口
- 把“入口 -> 通知中心 -> 已读 -> 返回上层角标同步”的场景收成稳定基座

### 这一阶段完成后再切换

只有 Phase A 进入“测试稳定 + 代码干净 + 守卫全绿”的状态，才进入 Phase B。

---

## 10. 结论

从现在开始，后续工作不再按碎片化对话推进，而是按：

**通知收口 -> 账号安全 -> 支付深化 -> 发版体系 -> 基础设施安全 -> 工程收尾 -> 总验收**

这条主线执行。

如果没有新的业务优先级插队，就严格按这个计划推进。
