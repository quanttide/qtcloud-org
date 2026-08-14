# 数据模型设计（models/）

对应 `index.md` 架构分解中的 `models/` 层。本文档是实现的直接依据：字段、规则、示例数据逐项定义。

按意图「数据层先行」原则，模型只承载工作台需要展示的组织本体事实；**版本历史由数据层（git 提交与 `ChangeRecord` 链）推导，不设容器模型**。入职包、交接、时间表、状态页等模型已随模块移出（见 `index.md` 边界协议）。

## 通用约定

- **不可变纯数据**：所有模型为不可变对象（Dart 中以 `final` 字段 + `copyWith` 表达），无持久化逻辑，零依赖
- **标识**：`id` 全局唯一（UUID 或 slug）；跨文件引用用 `id`，不用名称
- **时间**：统一 ISO 8601 字符串（数据层为文本文件，便于 git diff）
- **状态枚举**：模型内状态字段取值固定，见各模型定义
- **写操作**：模型不可直接修改；任何变更构造 `ChangeRecord` 提交回数据层
- **示例数据**：与数据层文件格式一致（Markdown frontmatter / YAML），原型阶段直接用作内存示例
- **成员变动事实**：`Member.status = departed` 由人事云事件经数据层写入；工作台消费该事实，重算岗位空缺与单点风险，不实现离职流程

## 组织架构（models/org/）

> 版本与历史不设容器模型：架构版本由数据层 git 提交推导，`ChangeRecord` 链即版本史。

### Department — 部门

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 部门标识 |
| `name` | String | 部门名称 |
| `parentId` | String? | 上级部门（null = 顶级） |
| `leaderId` | String? | 负责人成员 id |
| `status` | enum | `active` / `archived` |

**规则**：编制/归属的唯一权威源——归属不清时以此表为准；部门调整（新建/合并/撤销/负责人变更）走审批流。

### Position — 岗位（编制）

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 岗位标识 |
| `departmentId` | String | 所属部门 |
| `name` | String | 岗位名称 |
| `headcount` | int | 编制数 |
| `filled` | int | 已占用数（派生，由成员岗位统计） |
| `status` | enum | `active` / `frozen` |

**规则**：编制管控——`filled > headcount` 时界面警示超编；编制调整必须走审批流；`frozen` 岗位不再新任职。成员 `departed` 后其岗位计入空缺（`filled` 减少），由数据层事实更新。

### ReportRelation — 汇报链路

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 关系标识 |
| `memberId` | String | 成员 id |
| `positionId` | String | 该汇报关系对应的岗位（兼任时区分） |
| `reportsToId` | String | 汇报对象（成员或岗位 id） |
| `active` | bool | 是否当前生效 |

**规则**：一人多岗时每个岗位各自一条汇报关系；链路可由关系链推导，可追溯到每次调整。

## 成员与职责（models/member/）

### Member — 成员

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 成员标识 |
| `name` | String | 姓名 |
| `positions` | List\<String\> | 岗位 id 列表（兼任 = 多个岗位） |
| `reportsToId` | String? | 直接汇报对象 |
| `status` | enum | `active` / `departed` |

**规则**：
- 一人多岗 = 同一成员的多个 `positions`，归属与边界由岗位（`Position.departmentId`）显式定义，不再凭记忆
- `departed` 由人事云事件经数据层写入；工作台据此展示岗位空缺、职责悬空，并重算单点风险（见下）
- 成员是单点风险分析的输入：**岗位仅一人承担**（该岗位只有一个 `active` 成员）时标注风险

```yaml
id: member-zhang
name: 张三
positions: [pos-founder, pos-product]
reportsToId: null
status: active
```

## 复盘（models/retrospective/）

### Retrospective — 复盘记录

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 复盘标识 |
| `scheduleDate` | String | 复盘日程 |
| `organizerId` | String | 组织者成员 id |
| `participantIds` | List\<String\> | 参与人 id |
| `conclusions` | List\<String\> | 结论沉淀（要点列表） |
| `status` | enum | `scheduled` / `held` / `cancelled` |

**规则**：组织者 = 单人且无备选时自动标注单点风险并提示备选；组织者变更自动提醒重新指定。复盘是组织云「体检纠偏、推动变革」的机制载体。

## 变更记录（models/change_record.dart）

### ChangeRecord — 通用变更记录

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | String | 变更标识 |
| `authorId` | String | 作者 |
| `timestamp` | String | 时间 |
| `approval` | enum | `pending` / `approved` / `rejected` / `auto` |
| `commitId` | String? | 数据层 git 提交 id |
| `summary` | String | 变更说明（为什么改） |
| `changes` | List\<Change\> | 变更内容（对象/字段/旧值/新值） |

**规则**：所有写操作的统一表达——审批留痕与版本历史都由 `ChangeRecord` 承载；编制等受控变更 `approval` 为 `pending` 待数据层审批。**阶段一取值只用 `pending` / `auto`**（提交即落记录，审批流在数据层）。

## 边界与数据流

```
人事云流程（入职/离职/交接）→ 数据层事实更新
    ├── Member.status = departed
    ├── Position.filled 重算（岗位空缺）
    └── 单点风险重算（岗位单人 / 复盘组织者单人 / 职责悬空）
工作台只读事实与风险结论，不实现流程、不持有流程状态
```

- **工作台不含**：入职材料、交接单、任务时间表、项目状态等模型（归属人事云/运营域）
- **事实来源**：数据层 git 仓库（`data/` 子模块）；原型阶段用内存示例替代
