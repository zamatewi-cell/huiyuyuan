# Chrome DevTools MCP 综合规则体系

## 一、全局规则

### R00 — 工具调用前置条件
- **必须先用 `tool_search_tool_regex` 加载工具**: 所有 `mcp_io_github_chr_*` 工具属于延迟加载工具，调用前必须先搜索加载
- **搜索模式**: `^mcp_io_github_chr_` 一次性加载所有 Chrome DevTools MCP 工具
- **加载后可直接调用**: 无需重复搜索

### R01 — 页面生命周期管理
1. 任何操作前，先 `list_pages` 检查已有页面
2. 若无页面，`new_page` 创建新页面
3. 操作完成后，不主动关闭页面（保留供后续使用）
4. 仅在明确需要时才 `close_page`

### R02 — 等待优先原则
- 每次 `navigate_page` 后必须 `wait_for`（network_idle 或 element selector）
- 每次 `click` 后必须 `wait_for`（若预期有页面变化）
- 每次 `fill` / `fill_form` 后建议 `take_screenshot` 验证

### R03 — 失败恢复策略
- 元素定位失败 → `take_snapshot` 重新获取 DOM → 更新选择器 → 重试
- 网络超时 → `list_network_requests` 检查原因 → `take_screenshot` 记录状态
- 脚本执行错误 → `list_console_messages` 获取详细错误信息

---

## 二、技能调用规则

### R10 — 导航规则
```
IF 需要访问页面:
  1. list_pages → 有目标页面? → select_page
  2. 无目标页面 → new_page → navigate_page(url)
  3. wait_for(type: "network_idle", timeout: 30000)
  4. take_screenshot → 确认页面已加载
```

### R11 — 交互规则
```
IF 需要点击元素:
  1. wait_for(type: "selector", value: "目标选择器")
  2. click(selector: "目标选择器")
  3. IF 预期跳转 → wait_for(type: "url", value: "目标URL")
  4. IF 预期内容变化 → wait_for(type: "selector", value: "新出现的元素")

IF 需要填写表单:
  1. take_snapshot → 获取表单结构
  2. 单字段 → fill(selector, value)
  3. 多字段 → fill_form({selector1: value1, selector2: value2})
  4. take_screenshot → 验证填写结果
```

### R12 — 调试规则
```
IF 需要调试问题:
  1. list_console_messages → 筛选 error/warning
  2. list_network_requests → 筛选失败请求 (4xx/5xx)
  3. get_network_request(id) → 获取失败请求详情
  4. evaluate_script → 检查页面状态变量
  5. take_screenshot → 截图记录问题状态
```

### R13 — 性能规则
```
IF 需要性能分析:
  1. performance_start_trace
  2. 执行目标操作（导航、点击等）
  3. performance_stop_trace
  4. performance_analyze_insight → 获取洞察
  5. take_screenshot → 截图记录
```

---

## 三、优先级与冲突解决

### 优先级矩阵

| 场景 | 优先使用技能 | 原因 |
|------|-------------|------|
| 定位元素 | S09 (DOM快照) > S08 (截图) | 快照提供结构化数据 |
| 验证结果 | S08 (截图) > S09 (快照) | 截图更直观 |
| 检查请求 | S12 (网络分析) > S11 (控制台) | 请求数据更精确 |
| 检查异常 | S11 (控制台) > S12 (网络分析) | 控制台含完整错误栈 |
| 等待加载 | network_idle > selector > timeout | 按可靠性递减 |

### 冲突解决
- **截图 vs 快照冲突**: 默认先快照（获取选择器）再截图（记录状态）
- **多页面冲突**: 操作前必须 `select_page` 确认当前活动页面
- **性能追踪冲突**: 同一时间只能有一个追踪在进行

---

## 四、安全规则

### R20 — 敏感数据保护
- `evaluate_script` 不得注入含真实密码/密钥的代码
- `fill` / `fill_form` 中的密码字段仅用测试值（如 admin123, op123456）
- 截图中若含敏感信息需标注说明

### R21 — 操作限制
- 不在生产环境执行破坏性 `evaluate_script`
- 不修改服务器端数据库内容
- 不自动处理支付相关对话框（需人工确认）

---

## 五、日志与报告规则

### R30 — 操作日志
每次技能调用需记录：
1. **技能编号** (如 S01, S12)
2. **输入参数** (URL, 选择器等)
3. **执行结果** (成功/失败)
4. **耗时** (如适用)

### R31 — 报告输出格式
```
=== 测试报告 ===
时间: YYYY-MM-DD HH:MM
场景: [场景名称]
步骤:
  1. [步骤描述] → [结果]
  2. [步骤描述] → [结果]
结论: [通过/失败]
截图: [截图引用]
```
