# 组件设计（widgets/）

对应 `index.md` 架构分解中的 `widgets/` 层。跨页面复用的组件集中于此；页面私有的组件留在 `screens/<page>/` 子目录。每个组件一节：用途、属性、使用场景。

**复用规则**：两个以上页面复用才提升到 `widgets/`；仅一个页面使用的组件留在页面目录。

**精简说明**：随模块移出（入职包/交接/时间表/状态页 → 人事云/运营域）与复用规则，`TableCard`、`ChangeSubmitDialog`、`LoadingState`、`ErrorState` 已删除；`DepartmentTree`、`ChangeHistoryPanel`、编制表仅架构页使用，降级为架构页私有组件。

---

## navigation/ — 导航框架

### AppShell

**用途**：应用导航骨架，承载四个页面入口（首页/架构/成员/复盘）。

| 属性 | 类型 | 说明 |
|---|---|---|
| `currentIndex` | int | 当前选中项 |
| `onSelect` | (int) → void | 切换回调 |
| `children` | List\<Widget\> | 各页面内容 |

**行为**：
- Web/桌面：左侧导航栏（图标+文字）；移动端：底部导航栏
- 选中项高亮，未读提醒角标（首页聚合的数量可传给对应入口）

**使用页面**：全部页面。

---

## data/ — 数据展示类组件

### MemberCard

**用途**：成员信息卡（姓名/岗位/汇报对象/兼任标注）。

| 属性 | 类型 | 说明 |
|---|---|---|
| `member` | Member | 成员 |
| `positions` | List\<Position\> | 任职岗位（兼任时显示多岗位） |
| `onTap` | VoidCallback? | 点击回调 |

**使用页面**：成员页、健康度页（复盘详情）。

### StatusBadge

**用途**：状态徽章（正常/风险/待审批）。

| 属性 | 类型 | 说明 |
|---|---|---|
| `status` | enum | `normal` / `risk` / `pending` |
| `label` | String | 文案 |

**视觉约定**：`normal` 中性灰、`risk` 橙、`pending` 蓝（配合待审批变更、交接状态等展示）。

**使用页面**：首页、成员页、健康度页（复盘详情）。

---

## common/ — 通用基础组件

### RiskBadge

**用途**：单点风险标注（对应意图「关键人风险」）。

| 属性 | 类型 | 说明 |
|---|---|---|
| `risk` | enum | `singlePoint`（单人承担）/ `vacancy`（岗位空缺）/ 扩展风险类型 |
| `subject` | String | 风险对象（如「复盘组织者」「产品负责人」） |
| `alternatives` | List\<String\>? | 备选提示（提示备选人） |

**视觉约定**：橙色警告样式，hover/点击展开备选提示。

**使用页面**：首页（风险清单）、成员页（单点/空缺）、健康度页（复盘组织者单点）。

### EmptyState

**用途**：空态引导——无数据时提示如何开始。

| 属性 | 类型 | 说明 |
|---|---|---|
| `icon` | IconData | 图标 |
| `title` | String | 主文案 |
| `actionLabel` | String? | 引导按钮文案（如「新建复盘」） |
| `onAction` | VoidCallback? | 按钮回调 |

**使用页面**：全部页面。
