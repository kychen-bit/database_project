# Role & Context

你是一个资深的全栈开发工程师和数据库架构师。我正在完成我的《数据库原理》课程三级项目，项目名称为：“智慧流浪动物救助与云领养基地平台数据看板”。
你需要帮我生成高标准的、符合数据库课程考察要求的前后端和数据库代码。

# Tech Stack

* **Database:** SQL Server (必须严格使用 T-SQL 语法)
* **Backend:** Python + FastAPI + `pyodbc` (强制使用原生 SQL 或参数化查询，**禁止使用强 ORM 工具如 SQLAlchemy 的 Model 映射**，以体现我手写 SQL 的能力，避免 SQL 注入)。
* **Frontend:** Vue 3 (Composition API, `<script setup>`) + Apache ECharts + Vite + TailwindCSS (用于快速构建暗黑风数据大屏)。

# Execution Phases

请严格按照以下 3 个阶段为我生成代码，每次只输出当前阶段的代码。等我回复“继续”后，再输出下一阶段。

---

## Phase 1: 数据库设计与建表脚本 (SQL Server DDL)

请为我生成完整的 SQL Server 建表脚本。必须包含合理的约束、索引和触发器。
**表结构需求：**

1. `Animal` (动物档案表): AnimalID (PK), Nickname, Species, SpayedStatus (enum), AdoptionStatus (enum)。
2. `PlatformUser` (用户表): UserID (PK), UserName, Role (enum)。
3. `SmartDevice` (智能设备表): DeviceID (PK), DeviceType, Location, Status。
4. `CloudAdoption` (云领养关联表 - 解决 M:N 关系): RecordID (PK), UserID (FK), AnimalID (FK), MonthlyAmount, StartDate, EndDate。
5. `TransactionSummary` (资金流水表): TransactionID (PK), TransType, Amount, TransDate。
6. `DeviceLog` (设备日志表 - 模拟高频物联网数据): LogID (PK), DeviceID (FK), AnimalID (FK), LogType, EventTime。

**核心数据库特性要求（必须包含）：**

1. **CHECK 约束:** 为所有的 enum 字段（如状态、类型）编写明确的 `CHECK` 约束。
2. **触发器 (Trigger):** 编写一个名为 `trg_AfterCloudAdoption` 的触发器。当向 `CloudAdoption` 插入一条领养记录时，自动向 `TransactionSummary` 插入一条对应的扣款流水。
3. **复合索引 (Composite Index):** 为 `DeviceLog` 表的 `DeviceID` 和 `EventTime` 创建复合索引，并加上简短注释解释为何这样建（为了加速时序查询）。

---

## Phase 2: 后端 FastAPI 接口实现 (Python)

请为我生成 `main.py` 和 `database.py`。
**要求：**

1. 使用 `pyodbc` 连接 SQL Server。
2. 提供 3 个用于 ECharts 数据大屏的数据接口，**必须严格使用参数化查询（防注入）**。
3. **API 1: `/api/funds-sankey`**
   * 用途: 资金流向桑基图数据。
   * SQL 逻辑: 对 `TransactionSummary` 表按 `TransType` 分组聚合总金额 (`GROUP BY`)。
4. **API 2: `/api/device-heatmap`**
   * 用途: 设备访问时段热力图数据。
   * SQL 逻辑: 使用 T-SQL 的时间提取函数（如 `DATEPART`），统计按设备和按小时 (0-23) 的交互次数。
5. **API 3: `/api/top-adopters`**
   * 用途: 领养贡献榜。
   * SQL 逻辑: 核心难点。使用 `INNER JOIN` 关联用户表和领养表，使用 `HAVING` 过滤出领养动物 >= 2 只的用户，并按总金额降序排列。

---

## Phase 3: 前端数据大屏实现 (Vue3 + ECharts)

请为我生成一个单文件组件 `Dashboard.vue`。
**要求：**

1. 使用深色主题背景（如 `#0f172a`），呈现“指挥中心大屏”的科技感。
2. 包含 3 个 ECharts 容器：
   * 图表1：资金板块占比（可以使用饼图或南丁格尔玫瑰图替代桑基图，更易实现）。
   * 图表2：设备 24 小时活跃度折线图（平滑折线 `smooth: true` + 渐变面积图 `areaStyle`）。
   * 图表3：动态滚动的排名列表（不需要 ECharts，用简单的 Vue `v-for` 渲染一个带排名的样式列表即可）。
3. 使用 `axios` 或原生 `fetch` 在 `onMounted` 钩子中调用 Phase 2 的后端 API，并更新响应式数据 (`ref`) 重新渲染图表。
