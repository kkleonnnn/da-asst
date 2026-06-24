# SQL 数据查询（取数从入门到进阶 + 概念辨析与业务真题）

> 所属板块：08-取数与工具
> 类型：方法论 / 清单 / 案例提炼

---

## 元信息
- **适用范围**：面向用 SQL 做日常取数、口径校准、业务分析的数据分析师，以及准备 SQL 笔试 / 面试者。覆盖三大块：① 从基础查询到窗口函数、行列转换、典型业务取数套路与查询优化的体系化原理；② 高频概念辨析（聚合与 NULL、过滤关键字执行位置、连接方式、排序窗口函数差异、执行顺序）；③ 业务场景真题（留存、同时在线、连续签到积分、收入摊销、活跃分级、统计量等）与一个「重复下单去重还原真实需求量」的进阶实例。不适用于纯数据库开发/运维（建表、事务、权限治理等只作概念了解，不展开）。
- **时效**：整理日 2026-06-22；内容时效 长期有效（SQL 语法与窗口函数原理稳定）；个别函数/语法（日期函数、`!=` 连接、`with rollup`、`PIVOT` 等）在 MySQL、Hive、Spark SQL、Presto 等引擎间有差异，以实际引擎文档为准。
- **可信度**：中 —— 基于关系型查询与窗口函数的通用原理，逻辑自洽、示例可运行；具体语法/性能在各引擎间有差别，跨引擎使用前需校验。其中「重复下单」一节为讨论中给出的实现思路，逻辑自洽但未在真实数据上完整验证，落地前需用样例数据核对。
- **方法论标签**：#取数工具 #SQL #窗口函数 #行列转换 #数仓分层 #查询优化 #业务取数 #面试题 #连续问题 #留存 #同时在线 #统计量

---

## 正文

> 以下为改写后的自有表述。示例均用中性造数表名与字段名。

### 一句话方法论
对数据分析师而言，SQL 的难点几乎不在语法（基础语法就六个关键词），而在「数据存在哪张表、字段含义是什么、口径怎么对齐」。把取数当成「从某张表里，按某个条件，要某几个字段」这件事来拆，再把窗口函数这类进阶工具补齐，绝大多数取数需求都能解决。面试题看似花样繁多，真正的考点也有限：**聚合与 NULL 的边界、过滤关键字的执行位置、连接方式的取舍、排序/分组窗口函数、以及把业务口径翻译成「先打标 → 再聚合」的两段式取数**——吃透这些底层套路，绝大多数题都是变体。

---

## 第一部分：取数从入门到进阶（原理与体系）

### 一、SQL 是什么，分析师为什么要学

SQL（结构化查询语言）是专门用来管理和查询关系型数据库的语言，设计目标是让人用接近自然语言的声明式写法，高效地从结构化数据里查、增、改、删。它诞生于关系模型理论，如今几乎所有主流数据库（MySQL、PostgreSQL、Oracle、SQL Server）和大数据查询引擎（Hive、Presto、Spark SQL）都支持它。

对分析师来说，学 SQL 的核心理由有两个：
- **数据量级**：Excel 处理几千上万行尚可，一旦到十几万、上百万行就会卡死，而这正是数据库的日常量级。能力边界决定了取数必须落到数据库里。
- **业务口径**：分析的本质难度从来不在写出语句，而在搞清楚「数据存在哪、字段口径对不对」。同一个「活跃用户」在不同表、不同设计下含义可能不同，分析师的价值恰恰在于把口径对齐。

SQL 是声明式而非命令式：你只需说「要满足什么条件的哪些数据」，不必描述「具体怎么一步步取」。对比 Python/Java 这类命令式语言要手写循环、逐条遍历，SQL 把执行细节交给引擎自动处理，因此学习曲线更平缓、对数据库操作更高效。代价是它专精于数据查询与操作，处理复杂业务逻辑时不如通用语言灵活。

---

### 二、基础语法：六个关键词解决大半问题

把一句 SQL 想成一句话：「选哪些字段（SELECT）— 从哪张表来（FROM）— 满足什么条件（WHERE）」。最简单的三段式：

```sql
SELECT col_a
FROM dm.user_event
WHERE col_a = 1;
```

其中表名（如 `dm.user_event`）由数据库管理员或数仓团队定义好，分析师通常无需关心物理存储，只要知道它是哪张表即可。执行后界面给出一版结果，可导出为 Excel 或 CSV。

用 `AS` 可以给字段重命名（别名含空格需加引号）：

```sql
SELECT col_a, col_b, col_c AS amount_total
FROM dm.user_event
WHERE col_a = 1;
```

整套基础语法其实只有六个关键词，覆盖绝大多数取数：

| 关键词 | 作用 | 示例 |
|---|---|---|
| SELECT | 选字段（`SELECT *` 表示选全部列） | `SELECT col1, col2 FROM t` |
| WHERE | 行过滤 | `SELECT * FROM t WHERE condition` |
| ORDER BY | 排序 | `SELECT * FROM t ORDER BY col ASC` |
| GROUP BY | 按某列分组 | `SELECT col, COUNT(*) FROM t GROUP BY col` |
| HAVING | 对分组后的结果再过滤 | `SELECT col, COUNT(*) FROM t GROUP BY col HAVING COUNT(*) > 1` |
| JOIN | 关联两张及以上的表 | `SELECT cols FROM t1 JOIN t2 ON t1.k = t2.k` |

常用聚合函数：`COUNT / SUM / AVG / MIN / MAX`。子查询（在查询里嵌另一段查询）也很常见。

---

### 三、跨引擎差异：同一需求的不同写法

实际工作中会接触多种计算引擎，针对不同数据规模与查询类型各有取舍。常见对照：

| 引擎 | 类型 | 特点与场景 |
|---|---|---|
| MySQL | 关系型 DBMS | 适合在线事务处理（OLTP），网站应用常用 |
| PostgreSQL | 关系型 DBMS | 扩展性强，OLTP/OLAP 皆宜 |
| Oracle | 商业关系型 DBMS | 企业级整体方案，事务能力强 |
| SQL Server | 关系型 DBMS | 微软生态，BI 工具配套丰富 |
| Hive | Hadoop 上的数仓 | 把 SQL 转成 MapReduce / Tez / Spark 作业跑大数据 |
| Presto | 分布式查询引擎 | 面向分析负载，跨多数据源快速查询 |
| Spark SQL | Spark 上的查询引擎 | 内存计算，适合复杂大数据分析 |

各引擎主要在性能优化、数据源兼容、扩展性上有差别，对分析师而言最常踩到的是**日期/区间写法的差异**。同一个「查某月销售额」的需求：

```sql
-- 标准 BETWEEN 写法（MySQL / Hive / Spark SQL 直接可用）
SELECT SUM(amount) FROM sales WHERE date BETWEEN '2021-01-01' AND '2021-01-31';

-- PostgreSQL / SQL Server 倾向用 >= 和 < 半开区间，避免边界含混
SELECT SUM(amount) FROM sales WHERE date >= '2021-01-01' AND date < '2021-02-01';

-- Oracle 需把字符串显式转日期
SELECT SUM(amount) FROM sales
WHERE date BETWEEN TO_DATE('2021-01-01','YYYY-MM-DD') AND TO_DATE('2021-01-31','YYYY-MM-DD');

-- Presto 日期类型要加 DATE 关键字
SELECT SUM(amount) FROM sales WHERE date BETWEEN DATE '2021-01-01' AND DATE '2021-01-31';
```

要点：`BETWEEN` 是闭区间（含两端），跨月统计时容易把次月 1 号或漏掉月末末尾时刻，工程上更稳妥的是用 `>= 月初 AND < 次月初` 的半开区间。

---

### 四、数仓分层：ODS / DWD / DWS

取数时表名里常带分层前缀（如 `ods.` / `dwd.` / `dws.`），理解分层有助于选对表：

| 层级 | 含义 | 特点 | 用途 |
|---|---|---|---|
| ODS（操作数据存储） | 贴源层，原始数据接入，基本不加工 | 接近实时，仅做清洗/转换 | 日常明细查询、问题溯源 |
| DWD（数仓明细层） | 经清洗、规范化后的明细数据 | 保留明细粒度，口径统一 | 明细分析、上层汇总的基础 |
| DWS（数仓汇总层） | 在 DWD 之上按主题做的高层次汇总 | 预聚合指标，查询性能好 | 报表、看板、高频高层分析 |

经验法则：要明细、要溯源走 DWD/ODS；要现成指标、要快走 DWS。

> 补充概念——全量表 vs 增量表：全量表含某天的完整全部记录，完整性好但量大、更新成本高；增量表只含当天新增/变化的记录，量小但需配合复杂的同步逻辑才能还原完整状态。

---

### 五、窗口函数（开窗）：分析师必须吃透

窗口函数和 `GROUP BY` 都在做「分组」，但有本质区别：**`GROUP BY` 折叠行（多行聚成一行），窗口函数保留每一行、把聚合结果作为新列附加上去。**

正常写法是 `over(被开窗字段) (PARTITION BY 分组字段 ORDER BY 排序字段)`：先按 `PARTITION BY` 分组，组内按 `ORDER BY` 排序，再在窗口范围内做计算。

直观对比，同一张员工薪资表：

```sql
-- GROUP BY：每个部门折成一行，丢失明细
SELECT dept_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;

-- 窗口函数：保留每个员工的明细，额外多出一列部门均值
SELECT emp_id, dept_id, salary,
       AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg
FROM employees;
```

打个比方：`GROUP BY` 像把每个部门压成一行汇总值；窗口函数像在每行旁边贴一张「所在部门的汇总值」，明细一行不少。

**窗口函数的价值**在于把「行内信息」和「跨行/组内信息」同时挂到每一行上，便于做行间计算（环比、移动平均、排名、累计、跨状态间隔计算等）。性能上也常优于等价子查询——子查询可能多次扫表，窗口函数往往一次扫描即可，现代引擎对其做了专门优化。

**常用窗口/分析函数清单**（按学习优先级分三梯队）：

第一梯队（必须掌握）：
- `OVER`：开窗的载体，定义分组与排序。
- `LAG / LEAD`：取前 N 行 / 后 N 行的值，做环比、差异、移动平滑的基础。
- `LATERAL VIEW`（Hive）：配合 `explode` 把数组/JSON 等复杂类型一行炸成多行。
- 时间日期函数：`DATEDIFF / DATE_ADD / DATE_SUB / QUARTER` 等。

第二梯队（要能认识、用时查得到）：
- `ROW_NUMBER`：组内唯一行号，用于取 Top N、去重。
- `RANK / DENSE_RANK`：排名（`RANK` 跳号，`DENSE_RANK` 连续不跳号）。
- `CASE WHEN`：条件分支，相当于 Excel 的 IF。
- `JSON_EXTRACT`：取 JSON 字段。
- `GROUPING SETS`：一次出多种分组组合的汇总。
- `COALESCE / IFNULL`：取第一个非空值，空值兜底。

第三梯队（偏冷门，了解即可）：
- `PIVOT`：行转列。
- `ROLLUP`：层级小计 + 总计。
- `CONCAT / LIKE`：字符串拼接与模糊匹配。

---

### 六、几个高频窗口套路（带可运行示例）

**1）组内排名 / Top N**

```sql
-- 每个部门内按薪资降序排名
SELECT dept_id, emp_id, salary,
       ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rn
FROM employees;
```

**2）累计值**

```sql
-- 每个部门按 emp_id 顺序的累计薪资
SELECT dept_id, salary,
       SUM(salary) OVER (PARTITION BY dept_id ORDER BY emp_id) AS cum_salary
FROM employees;
```

**3）移动平均**（`ROWS BETWEEN ... PRECEDING AND CURRENT ROW` 控制窗口宽度）

```sql
-- 每个商品近 10 天移动平均销量
SELECT product_id, sale_date, quantity,
       AVG(quantity) OVER (PARTITION BY product_id ORDER BY sale_date
                           ROWS BETWEEN 9 PRECEDING AND CURRENT ROW) AS ma10
FROM sales;
```

**4）LAG/LEAD 算环比与变化率**

`LEAD` 把后一行的值「拉上来」并列到当前行，`LAG` 反之把前一行的值「拉下来」。完整参数：`LAG/LEAD(expression [, offset [, default]]) OVER ([PARTITION BY ...] ORDER BY ...)`。`offset` 是偏移行数（默认 1），`default` 是越界时的兜底值（默认 NULL）。

```sql
-- 销售额环比与变化率
SELECT date, sales,
       sales - LAG(sales) OVER (ORDER BY date) AS sales_change,
       (sales - LAG(sales) OVER (ORDER BY date)) / LAG(sales) OVER (ORDER BY date) * 100 AS change_rate
FROM sales;
```

提示：用 `LAG/LEAD` 算变化率时，建议给 `default` 一个非空兜底（或外层 `WHERE` 过滤掉首行的 NULL），否则除以 NULL 会出空值。

**5）跨状态的时间间隔计算**（如「物品在库周转时长」）

思路：用 `LEAD` 把同一物品的下一条「出库」时间拉到「入库」那行旁边，再做时间差。

```sql
WITH time_diff AS (
  SELECT item_id, status, date_time AS in_time,
         LEAD(date_time) OVER (PARTITION BY item_id ORDER BY date_time) AS out_time
  FROM inventory_records
)
SELECT item_id, in_time, out_time,
       (unix_timestamp(out_time) - unix_timestamp(in_time)) / 60.0 AS turnover_minutes
FROM time_diff
WHERE out_time IS NOT NULL;
```

> 在 Python 中，`shift()` 对应 `LAG/LEAD`，`rolling(window=n).mean()` 对应移动平均，`expanding()` 对应累计，`groupby() + 上述` 对应 `PARTITION BY` 的开窗。

**6）窗口帧（滑动窗口）的精确控制**

当「移动 N 行/N 天」用 `LAG` 逐行相加很繁琐时，直接用帧定义：

```sql
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING   -- 前一行、当前行、后一行（共 3 行）
ROWS UNBOUNDED PRECEDING                    -- 分区首行到当前行（=累计）
ROWS 6 PRECEDING                            -- 当天+前 6 天（日期连续且不重复时）
RANGE INTERVAL 6 DAY PRECEDING              -- 近一周（按日期值，允许日期不连续）
RANGE BETWEEN 10 PRECEDING AND 5 FOLLOWING  -- 值落在 [n-10, n+5] 区间
```

区别：`ROWS` 按物理行数，`RANGE` 按排序字段的值范围。近一周日均若只有 5 天有数据，用 `SUM(...) RANGE INTERVAL 6 DAY PRECEDING / 7`。

**7）累计指标的几种变体**

```sql
SUM(c)  OVER (ORDER BY b)                                  -- 累计求和（不分组）
SUM(SUM(cnt)) OVER (PARTITION BY uid ORDER BY month)       -- 先聚合再累计
AVG(c)  OVER (PARTITION BY a ORDER BY b)                   -- 累计均值
ROUND(SUM(c) OVER (PARTITION BY a ORDER BY b) / SUM(c) OVER (PARTITION BY a), 2)  -- 累计占比
```

---

### 七、进阶实例：用窗口函数识别重复下单、还原真实需求单量

> 这是一个把窗口函数用于「按多维度键 + 时间窗口去重」的完整业务实例。注意：以下为讨论中提出的实现思路，逻辑自洽但未在真实数据上完整验证，上线前务必用小批样例数据手工核对结果。

**问题原型**：一张订单表，含 `订单id`、`用户id`、`订单创建时间`（精确到秒，如 `2024-08-30 12:01:04`）、`配送起点`、`配送终点`。业务定义：同一用户、在 1 小时内、对**完全相同的起点和终点**多次下单，只能算作一次「真实需求」；其余视为「重复单」。目标是统计「真实需求订单量」。本质上这是「先给每条订单打上『是不是重复单』的标记，再按标记聚合」的口径问题。

**核心思路：用窗口函数找时间上的邻居**。判断一条订单是否与「同用户、同起终点」的另一条订单挨得足够近（1 小时内），关键是拿到它在时间序列上的前一条 / 后一条订单的时间，再比较时间差：

- **分区（PARTITION BY）**：按「用户 id + 起点 + 终点」分组，保证只在「同一个人、同一条行程」内部比较。
- **排序（ORDER BY）**：按订单创建时间升序，让同一分区内的订单排成时间序列。
- `LEAD(创建时间)`：取**后一条**订单的创建时间；`LAG(创建时间)`：取**前一条**订单的创建时间。
- 把时间转成时间戳（如 `UNIX_TIMESTAMP`）后做差，1 小时 = 3600 秒，即可判断邻居是否落在窗口内。

打标逻辑（两侧都看，避免漏判）：
- 若「后一条」减「本条」≤ 3600 秒 → 本条与后面的单挨得很近，打标记 A；
- 若「本条」减「前一条」≤ 3600 秒（等价于前一条减本条 ≥ −3600 秒）→ 本条与前面的单挨得很近，打标记 B。

**从标记到口径**：拿到 A、B 两个标记后，按「用户 + 起终点」再聚合一次，定义两个计数：
- **真实需求单量**：在一串挨得很近的重复单里，只保留「能算作真实需求」的那一笔。一种可行口径是：把「与后面的单很近 或 与前面的单很近」的订单都纳入候选，再按用户去重计数，得到「同一需求」下应保留的订单数。
- **重复单量**：只统计「与后面的单很近」的那一类，即一连串重复中除末单外的前序订单数。

> 提示：真实需求 / 重复单的精确归属（究竟保留最早一笔还是最晚一笔）取决于业务定义。原始问题里倾向「创建时间最晚的为真实需求单，其余为重复单」。落地时应先和业务对齐「保留首单还是尾单」，再决定标记如何映射到计数，避免一头一尾都被算进或都被漏掉。

**参考写法**（中性造数，按需调整字段名与时间窗口）：外层做聚合，内层用窗口函数打标，最里层先对原始订单去重，结构是「三层嵌套」。

```sql
SELECT SUM(real_demand_cnt) AS 真实需求单量,
       SUM(repeat_cnt)      AS 重复单量
FROM (
  SELECT user_id,
         begin_area,
         end_area,
         -- 真实需求：与前后任一近邻在窗口内即纳入，按订单去重计数
         COUNT(DISTINCT CASE WHEN near_next = 1 OR near_prev = 1
                             THEN order_id END) AS real_demand_cnt,
         -- 重复单：只数与后一条挨得很近的
         COUNT(DISTINCT CASE WHEN near_next = 1
                             THEN order_id END) AS repeat_cnt
  FROM (
    SELECT order_id, user_id, create_time, begin_area, end_area,
           CASE WHEN UNIX_TIMESTAMP(
                      LEAD(create_time) OVER (
                        PARTITION BY user_id, begin_area, end_area
                        ORDER BY create_time)
                    ) - UNIX_TIMESTAMP(create_time) <= 3600
                THEN 1 ELSE 0 END AS near_next,
           CASE WHEN UNIX_TIMESTAMP(
                      LAG(create_time) OVER (
                        PARTITION BY user_id, begin_area, end_area
                        ORDER BY create_time)
                    ) - UNIX_TIMESTAMP(create_time) >= -3600
                THEN 1 ELSE 0 END AS near_prev
    FROM (
      SELECT DISTINCT order_id, user_id, create_time, begin_area, end_area
      FROM 订单表
    ) t
  ) a
  GROUP BY user_id, begin_area, end_area
) b;
```

**另一种思路：行号 + 时间差，更直白**。若觉得 LEAD/LAG 的「前后双标记 + 计数映射」绕，也可换一条更易读的路线：
1. 仍按「用户 id + 起点 + 终点」分区、按时间排序，用 `ROW_NUMBER` 给每条订单编序号；
2. 通过自关联或窗口取到前一条的时间，比较时间差是否 < 1 小时；时间差在窗口内的标记为「重复（0）」，否则标记为「真实需求（1）」；
3. 最后按「用户 + 起终点 + 真实需求标记」分组去重计数，即得同一需求下的订单数量。

这条路线胜在每一步含义清楚、便于自查，缺点是步骤略多。两种写法殊途同归，按团队习惯择一即可。

**本实例的专属坑**：
- **前后都要看**：只用 LEAD（看后一条）或只用 LAG（看前一条）容易把一串重复里的首单或尾单漏标，导致真实需求数偏多或偏少。
- **保留首单还是尾单要先定义**：业务若规定「最晚一笔为真实需求」，标记到计数的映射方式会不同；不对齐就会出现重复计数或漏计。
- **去重要趁早**：若原始表本身有完全重复的行（同一 order_id 多次出现），应在最里层先 `DISTINCT`，否则窗口比较会被脏数据干扰。
- **时间字段类型**：做时间差前要统一转成时间戳或可比的数值，直接对字符串时间相减会出错；1 小时窗口对应 3600 秒，阈值需按业务定义调整。
- **边界值含义**：「≤ 1 小时」是否含正好 1 小时、以及窗口是「滑动相邻」还是「绝对起算」，会影响临界订单的归属，需与业务确认后固定口径。

---

### 八、CTE（WITH AS）：让复杂查询可读

`WITH AS` 用来定义临时结果集（公用表表达式 / CTE），把复杂查询拆成多个有名字的逻辑块，从上到下串起来。基本语法 `WITH cte_name AS (子查询) SELECT * FROM cte_name`。适用场景：

- **提升可读性**：把多步逻辑拆成命名小块，整段查询更易读。
- **避免重复子查询**：同一段逻辑被多次引用时，定义一次 CTE 复用。
- **递归查询**：处理树形/层级数据（需引擎支持）。

注意 CTE 通常只在本次查询内有效。它不一定提性能，主要解决可维护性。

---

### 九、行列转换

行列转换是高频业务需求而非单一公式，本质是用聚合 + 条件表达式重排数据。

**行转列（长表变宽表）—— `CASE WHEN` + 聚合**

设有长表 `sales_table(product_id, month, sales)`，要把每月销售额拆成独立列：

```sql
SELECT product_id,
       MAX(CASE WHEN month = '1月' THEN sales ELSE 0 END) AS sales_jan,
       MAX(CASE WHEN month = '2月' THEN sales ELSE 0 END) AS sales_feb
FROM sales_table
GROUP BY product_id;
```

原理：`CASE WHEN` 只在月份匹配时取值、否则给 0，再用 `MAX`（或 `SUM`）在分组内把该列的有效值聚出来。若想聚成 JSON/map 形式，可在外层套 `map()` / `to_json()`。

**列转行（宽表变长表）—— Hive 用 `LATERAL VIEW explode`**

设有 `sales_table(product_id, month_sales_array)`，`month_sales_array` 是装着每月销售的数组：

```sql
SELECT product_id, month_sales.month, month_sales.sales
FROM sales_table
LATERAL VIEW explode(month_sales_array) t AS month_sales;
```

`explode()` 把数组/集合炸成多行，`LATERAL VIEW` 把炸出来的结果与原表横向拼接成新视图。注意执行顺序：`LATERAL VIEW` 在 `FROM` 阶段就已展开，因此 `WHERE` 过滤要写在 `LATERAL VIEW` 之后，才能筛到炸开后的新字段。

`explode` 边界提醒：作用于含 NULL 的数组时不会为 NULL 生成行（影响行数，统计要注意）；它会成倍放大行数，大数据量下注意性能与资源。

> SQL 执行顺序（理解行列转换与各种过滤位置的关键，详见「第二部分·概念辨析」第 10 条）：
> `FROM`（含 JOIN）→ `WHERE` → `GROUP BY` → `HAVING` → `SELECT` → `ORDER BY` → `LIMIT`。

---

### 十、典型业务取数套路（连续问题与取值问题）

这些是分析师面试与实战都高频的场景，套路价值高于死记语法。更多面向行为日志的业务真题见「第三部分」。

**1）连续登录 / 连续签到**

需求：求连续登录满 N 天的用户、求积分、求连续活跃天数。
套路：先按用户分组、按日期排序打 `dense_rank()`（同一天多次登录用 `dense_rank` 去重）；用「日期减去序号天数」得到一个锚点日期，连续登录的行锚点相同，再按锚点分组计数即可。

```sql
SELECT uid, dt, rn, date_sub(dt, INTERVAL rn DAY) AS anchor,
       dense_rank() OVER (PARTITION BY uid, date_sub(dt, INTERVAL rn DAY) ORDER BY dt) AS continue_sign
FROM (
  SELECT uid, dt, dense_rank() OVER (PARTITION BY uid ORDER BY dt) AS rn
  FROM user_info
) t;
-- 连续活跃 > N 天即 MAX(continue_sign) > N
```

**2）连续得分 / 连续事件**

需求：求连续 N 次得分（中间不能被别人打断）的成员。
套路：与连续登录同源——「整体排序」减「分组内排序」得到的差值恒定，则这几次是连续的。

```sql
SELECT team, member, COUNT(1)
FROM (
  SELECT team, member,
         RANK() OVER (PARTITION BY team, member ORDER BY score_time) AS rn,
         RANK() OVER (PARTITION BY team ORDER BY score_time) AS rn_all
  FROM score_info
) t
GROUP BY team, member, (rn_all - rn)
HAVING COUNT(1) > 2;
```

> 只判「恰好连续三次」也可用 `LAG(number, 1)` 和 `LAG(number, 2)`，偏移两次仍是同一人即可。

**3）去掉最高最低后求平均**（评委打分式）

```sql
-- 去掉单个极值
SELECT dept,
       (SUM(salary) - MAX(salary) - MIN(salary)) / (COUNT(1) - 2) AS trimmed_avg
FROM emp
GROUP BY dept;

-- 去掉所有并列极值：用正序/倒序 dense_rank 把排名为 1 的全去掉
SELECT dept, AVG(salary)
FROM (
  SELECT dept, salary,
         dense_rank() OVER (PARTITION BY dept ORDER BY salary)      AS rk_asc,
         dense_rank() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk_desc
  FROM emp
) a
WHERE rk_asc > 1 AND rk_desc > 1
GROUP BY dept;
```

**4）分类排名中取特定值**（如每个区域销量最大的门店、每个品类利润最高的商品）

```sql
-- 每组按 b 升序取最小那行的 c
SELECT a, c
FROM (
  SELECT a, b, c, ROW_NUMBER() OVER (PARTITION BY a ORDER BY b) AS rn
  FROM t
) x
WHERE rn = 1;

-- 同时取每组最小值与最大值对应的 c
SELECT a,
       MIN(IF(asc_rn = 1, c, NULL)) AS min_c,
       MAX(IF(desc_rn = 1, c, NULL)) AS max_c
FROM (
  SELECT a, b, c,
         ROW_NUMBER() OVER (PARTITION BY a ORDER BY b)      AS asc_rn,
         ROW_NUMBER() OVER (PARTITION BY a ORDER BY b DESC) AS desc_rn
  FROM t
) x
WHERE asc_rn = 1 OR desc_rn = 1
GROUP BY a;
```

> 取前两小/前两大可用 `GROUP_CONCAT(CASE WHEN asc_rn <= 2 THEN c END)` 把对应字段拼出来。

---

### 十一、查询优化（以 Hive/大数据引擎为主）

优化有两个目标：提升可读性、提升运行效率。对分析师，效率优化在面试和大数据日常都用得上。

**理解执行层**：Hive 把 SQL 翻成 MapReduce/Tez 等作业在集群上跑，数据存于 HDFS。优化要从存储格式（Parquet/ORC 列存、压缩、分区）、计算（MapReduce/Tez 工作方式、集群资源）、网络传输三方面入手。从写 SQL 角度，最常用两点：

**a）善用分区**
分区把表数据按某字段（如日期、地区、用户 ID）拆到不同目录，查询时只扫命中分区。
- 看分区字段：用 `DESCRIBE FORMATTED 表名` 查 Partition Information；分区字段一般在表结构末尾。
- 建表：单字段 `CREATE TABLE orders (...) PARTITIONED BY (order_date DATE)`；多级 `PARTITIONED BY (order_date DATE, region STRING)`。
- 动态分区：插入时按数据值自动建分区，减少手动负担；静态分区：插入时手动指定分区值，已知目标分区时更稳。
- 查询时务必带上分区过滤（`WHERE dt = '...'`），筛全量表是否还是大宽表对成本影响很大。

**b）选对 JOIN 策略**（大数据下尤其关键）
- **Map Join（广播 JOIN）**：当至少一张表很小，把小表放进每个节点内存，与大表在内存里直接匹配，省去网络传输，效率高。适用「小表 JOIN 大表」。
- **Shuffle Join（重分布 JOIN）**：两张大表之间，按 key 做网络重分布让相同 key 落到同节点；通用但易受数据倾斜与网络拖累。
- **Sort-Merge Join**：两大表各自排序后归并；对已排序数据高效，预排序成本较高。

**数据倾斜及应对**：某些 key 的数据量远超其他 key，导致处理它的节点负载过重、拖慢整体。成因有键分布不均、业务逻辑导致集中（如对某字段单独处理）、大量值集中在少数 key。应对：
- 重设计键值（加随机前缀/盐打散）。
- Salting：JOIN 前给键值加随机后缀，JOIN 后再去掉，使分布更均匀。
- 广播 JOIN：小表广播到各节点，减少 Shuffle。
- 提前过滤：JOIN 之前先过滤掉不需要的数据，减小参与量。
- 动态调整并行度：按数据实际分布调整任务的分区数与并行度。

**几个常用调参方向**（不同平台参数名不同，作了解）：
- 调内存：调高每个 reducer 处理的数据量，缓解任务受内存影响。
- 并行执行：开启作业间并行，缩短总时长。
- 启用压缩：对中间结果与输出压缩，减少存储与网络传输。
- 启用 CBO（基于成本的优化）：先采集统计信息，让引擎据此选更优执行计划。

---

## 第二部分：高频概念辨析（笔试简答常考）

> 本部分侧重「面试/笔试常考点 + 概念边界」，与第一部分的原理体系互补。

#### 1）`COUNT(1)` / `COUNT(*)` / `COUNT(列)` / `COUNT(DISTINCT 列)`
- `COUNT(1)`、`COUNT(*)`：统计行数，**包含该列为 NULL 或空字符串的行**，二者结果一致（实现上 `COUNT(*)` 不取具体列值，通常更直接）。
- `COUNT(列)`：只统计该列**非 NULL** 的行数，重复值仍计入。
- `COUNT(DISTINCT 列)`：去重后统计非 NULL 的不同值个数。

举例，某列取值序列为 `(0, NULL, '', 11)`：`COUNT(1)` 与 `COUNT(*)` 都得 4（如实计行），`COUNT(列)` 得 3（NULL 不计），`COUNT(DISTINCT 列)` 得 3。要点：**即使某行该列是 NULL，`COUNT(1)` 仍按行计数，但 `COUNT(列)` 会把这行排除**。

#### 2）空字符串 `''` / `0` / `NULL` / `FALSE` 的区别
- `''`（空字符串）：值是**存在的**，只是长度为 0。
- `0`：合法的数值，参与运算。
- `NULL`：表示「未知 / 不存在」，**不能比较大小或相等**，与任何值（包括自身）比较结果都不是 TRUE，参与算术运算结果为 NULL。
- `FALSE`：布尔值，底层等价于 0；布尔列常用 1/0 表示 TRUE/FALSE。

关键影响：在 `COUNT(列)` 这类聚合里，`''`、`0`、`FALSE` 都会被统计到，**唯独 NULL 不会**。因此良好习惯是「确实需要被统计的项不要存成 NULL，确实表示缺失的才用 NULL」。

#### 3）`ON` / `WHERE` / `HAVING` 三种过滤的位置差异
- `ON`：连接条件，内连接里 `ON` 与 `WHERE` 效果接近；但**外连接里 `ON` 在连接前生效、`WHERE` 在连接后生效**——这点决定了外连接补 NULL 的行能否被保留，是高频坑。
- `WHERE`：对行过滤，**不能用聚合函数**。
- `HAVING`：对分组后的结果过滤，常与 `GROUP BY` 搭配，**可以用聚合函数**。
- 引擎差异：部分计算引擎（如 Hive）`ON` 里只支持等值连接（`a = b`），不支持不等式连接（`a > b`），而 MySQL 可以。

#### 4）`IN` 与 `EXISTS`
- `IN`：主查询的某列是否等于子查询结果集中的**任一值**，只能比较单列。
- `EXISTS`：判断子查询是否有返回行，逐行关联判断，能表达多列匹配。
- 性能经验：子查询结果集小、主表大且有索引 → 倾向 `IN`；外层主查询小、子查询表大且有索引 → 倾向 `EXISTS`。

#### 5）`UNION` 与 `UNION ALL`
- `UNION` 自动去重（需排序，较慢）；`UNION ALL` 保留全部行（更快）。确认结果不含重复行时优先 `UNION ALL`。

#### 6）`LIKE` 与 `RLIKE`
- `LIKE`：通配符匹配，`_` 匹配单个字符、`%` 匹配任意多字符。
- `RLIKE`（即 `REGEXP`）：正则匹配，能力更强。例：从混杂字符串里只抽小写字母，可用 `regexp_replace(s, '[^a-z]', '')`。
- 提醒：`LIKE '%xxx'` 前置通配会导致全表扫描，代价高。

#### 7）几组排序窗口函数的区别（极高频）
按某分数降序为例，对并列值的处理不同：
- `ROW_NUMBER()`：1 2 3 4… 强制唯一行号，并列也分先后。
- `RANK()`：1 2 2 4… 并列同名次，之后**跳号**（俗称美式/竞技排名）。
- `DENSE_RANK()`：1 2 2 3… 并列同名次，之后**不跳号**（俗称中式排名，可理解为对类别计数）。
- `PERCENT_RANK()`：按位置算百分位，公式 `(RANK-1)/(N-1)`，结果落在 0~1。

坑：`RANK()` 的返回是无符号整型，两个名次相减出负数会报错，需先 `CAST(rk AS SIGNED)` 再相减。

#### 8）`PARTITION BY` 与 `GROUP BY`
`GROUP BY` 折叠行（多行聚成一行）；`PARTITION BY` 用于窗口函数，**不减少行数**，而是给每行附加一个组内聚合值。

#### 9）连接方式与笛卡尔积
- 连接类型：内连接（取交集）、左/右连接（保留左/右全部，缺失补 NULL）、全连接、自连接、交叉连接。记忆口诀：**想保留哪边的全部信息，就用哪边的外连接；只要交集就内连接**。
- 笛卡尔积：无连接条件时两表所有行任意组合，结果集急剧膨胀。常见诱因：JOIN 忘写连接条件、子查询引入不相关表、多维表连接。规避：每个 JOIN 都明确且正确地给出连接条件。
- `ON` 与 `USING` 的差别：`USING(列)` 要求两表列名相同且只能连两表，结果里同名列**只保留一份**；`ON` 更灵活、可写复杂条件，结果里两表列都保留（同名会加表前缀）。

#### 10）SQL 逻辑执行顺序（纠正书写思维的关键）
书写顺序是 `SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT`，但**逻辑执行顺序**是：

```
FROM / JOIN（构造源表）
→ ON（连接条件）
→ WHERE（行过滤）
→ GROUP BY（分组）
→ HAVING（分组后过滤）
→ SELECT（含窗口函数计算）
→ ORDER BY（排序）
→ LIMIT（截断）
```

含窗口函数时，窗口计算发生在 `SELECT` 阶段（`HAVING` 之后、最终 `ORDER BY` 之前）：先 `PARTITION BY` 分区、再组内 `ORDER BY`、再定帧、再算函数值。理解这个顺序后读别人代码会很快——先看 `FROM` 哪些表，再看做了什么筛选，最后看选了什么。

---

### 单表/多表练习题：高频套路（造数：学生 / 课程 / 成绩）

> 设有学生表 `student(sid, sname, gender, class_id, s_birth)`、班级表 `class(cid, caption)`、课程表 `course(course_id, cname, teacher_id)`、教师表 `teacher(tid, tname)`、成绩表 `score(student_id, course_id, num)`。

**1）日期类筛选与「过了生日加一岁」的年龄**
```sql
-- 本周过生日人数
SELECT COUNT(*) FROM student WHERE WEEK(s_birth) = WEEK('2023-05-15');
-- 真实年龄（按生日是否已过）
SELECT sname, TIMESTAMPDIFF(YEAR, s_birth, NOW()) AS age FROM student;
```
要点：年龄不要简单用 `YEAR(NOW()) - YEAR(s_birth)`（会忽略今年生日是否已过），`TIMESTAMPDIFF(YEAR, ...)` 自动按完整年数计。

**2）「占比 / 概率」用聚合套条件表达式**
```sql
-- 男生占比（升序）
SELECT caption,
       COUNT(CASE WHEN gender = '男' THEN 1 END) / COUNT(1) AS male_ratio
FROM student s JOIN class c ON c.cid = s.class_id
GROUP BY caption ORDER BY 2;
```
等价写法 `AVG(gender = '男')`（把布尔当 0/1 求均值）在 MySQL 可用，Hive 常不支持，跨引擎慎用。

**3）`HAVING` 处理「分组后再筛」**
```sql
-- 至少选两门课的学生
SELECT student_id, COUNT(1) num
FROM score GROUP BY student_id HAVING num >= 2;
-- 被超过 3 人选修的课程
SELECT cname, COUNT(1) cnt
FROM score s JOIN course c USING(course_id)
GROUP BY cname HAVING cnt > 3;
```

**4）「选了 A 但没选 B」与「与某人完全相同」类集合题**
- 「选了课 1 但没选课 2」：`WHERE course_id = 1 AND student_id NOT IN (子查询取选了课 2 的人)`，或用自连接。
- 「与学号 2 选课**完全相同**」：先用 `HAVING COUNT(1) = (学号2的选课数)` 筛出课程数相同的人，再 `HAVING` 确认与学号 2 的课程集合一一对应，本质是「课程数相等 + 交集等于全集」。

**5）成绩分级、排名分页、第 N 名**
```sql
-- 分级人数（CASE WHEN 分桶）
SELECT CASE WHEN num < 60 THEN 'E' WHEN num < 70 THEN 'D'
            WHEN num < 80 THEN 'C' WHEN num < 90 THEN 'B' ELSE 'A' END AS grade,
       COUNT(1)
FROM score WHERE course_id = 1 GROUP BY 1;
-- 排名后分页：每页 3 人，看第 3 页
... RANK() OVER (ORDER BY num DESC) rk ... LIMIT 6, 3;
-- 第 7 名（不考虑并列）
... ORDER BY num DESC LIMIT 1 OFFSET 6;
```

**6）「每门课成绩最高 / 前三」= 分区排名取 Top**
```sql
-- 每门课最高分学生（考虑并列用 RANK）
SELECT cname, sname, num FROM (
  SELECT cname, sname, num,
         RANK() OVER (PARTITION BY cname ORDER BY num DESC) rk
  FROM score JOIN course USING(course_id) JOIN student ON ...
) t WHERE rk = 1;
-- 每门课前三（同分都要 → DENSE_RANK）
... DENSE_RANK() OVER (PARTITION BY cname ORDER BY num DESC) rk ... WHERE rk < 4;
```
口径辨析：「前三名」是否含并列，决定用 `RANK` / `DENSE_RANK` / `ROW_NUMBER`，面试要主动确认。

**7）`UNION` 合并不同实体 + `WITH ROLLUP` 小计**
- 把学生与教师按编号奇偶各取一半再合并、统一排序，用 `UNION`。
- `GROUP BY gender WITH ROLLUP` 会多出一行「总体」汇总，配合 `IFNULL(gender,'总体')` 命名；如只要男生+总体两行，可在 `HAVING` 里写 `gender = '男' OR gender IS NULL`（ROLLUP 的小计行该列为 NULL）。

**8）「课程 1 比课程 2 高」的两种实现**
```sql
-- 透视法：把两门课的分各转成一列再比较
SELECT student_id,
       MAX(CASE course_id WHEN 1 THEN num ELSE 0 END) s1,
       MAX(CASE course_id WHEN 2 THEN num ELSE 0 END) s2
FROM score GROUP BY student_id HAVING s1 > s2 AND s2 != 0;
-- 自连接法（在 ON 里筛课程，计算量更小）
SELECT a.student_id, a.num, b.num
FROM score a JOIN score b
  ON a.student_id = b.student_id AND a.course_id = 1 AND b.course_id = 2
WHERE a.num > b.num;
```

> 增删改部分对分析师够用即可：会建表（含字段注释、外键约束）、`INSERT ... SELECT` 灌数、`UPDATE ... WHERE`、`DELETE ... WHERE NOT IN (子查询)` 即可，其余可临时查。

---

## 第三部分：业务场景真题（笔试综合题，价值最高）

> 大量真题共用一张行为日志表 `user_log(id, uid, artical_id, in_time, out_time, sign_in)`：每行是一次浏览（进入/离开时间），`artical_id = 0` 表示非内容页。下面按场景给套路。连续登录、连续得分、去极值平均、分类排名取他值等套路已在第一部分第十节给出，这里补充行为日志类与更复杂的场景。

**1）人均浏览时长**
```sql
SELECT DATE_FORMAT(in_time, '%Y-%m-%d') AS dt,
       ROUND(SUM(TIMESTAMPDIFF(SECOND, in_time, out_time)) / COUNT(DISTINCT uid), 1) AS avg_sec
FROM user_log
WHERE artical_id != 0 AND DATE_FORMAT(out_time, '%Y-%m') = '2021-11'
GROUP BY 1 ORDER BY 2;
```
坑：分母是「去重用户数」`COUNT(DISTINCT uid)`，不是行数。

**2）同一时刻最大在线人数（极高频，变种多）**
思路：把进入、离开两列**用 `UNION ALL` 拍成一列事件流**，进入记 `+1`、离开记 `-1`，按时间累加求当前在线数，取最大值。同一时刻先增后减（`ORDER BY tm, num DESC`）。
```sql
SELECT artical_id, MAX(uv) AS max_uv FROM (
  SELECT artical_id,
         SUM(num) OVER (PARTITION BY artical_id ORDER BY tm, num DESC) AS uv
  FROM (
    SELECT artical_id, in_time  AS tm,  1 AS num FROM user_log
    UNION ALL
    SELECT artical_id, out_time AS tm, -1 AS num FROM user_log
  ) t
) t1
GROUP BY artical_id ORDER BY 2 DESC;
```
同模板可扩展：求「同时在线 > N」用 `WHERE uv > N`；适用直播在线、课程在线、付款中人数、文章在看等。

**3）次日留存率（含跨天活跃口径）**
口径：当天新增用户中，第二天又活跃的占比；若进入/离开跨天，则两天都算活跃。
```sql
SELECT DATE(t1.tm) AS dt,
       ROUND(COUNT(DISTINCT t2.uid) / COUNT(DISTINCT t1.uid), 2) AS retention
FROM (SELECT uid, MIN(in_time) AS tm FROM user_log GROUP BY uid) t1   -- 新用户首次活跃
LEFT JOIN (
  SELECT uid, in_time  AS tm FROM user_log
  UNION ALL
  SELECT uid, out_time AS tm FROM user_log                            -- 进入+离开都算活跃
) t2 ON t1.uid = t2.uid AND DATEDIFF(t2.tm, t1.tm) = 1
GROUP BY dt ORDER BY dt;
```
通用化（T+1 / T+3 / T+n）：把自连接的 `DATEDIFF = n` 换成对应天数；多列展示用 `COUNT(DISTINCT CASE WHEN DATEDIFF = 1 ...)`、`... = 7 ...` 并排。更高效的工程做法是用一个数组字段记录用户历史登录日期，再用 `array_contains` 判断 T+1 是否在内。

**4）日活与新客占比**
```sql
SELECT dt, COUNT(uid) AS dau,
       ROUND(AVG(first_day = dt), 2) AS new_ratio
FROM (
  SELECT uid, DATE(in_time) AS dt FROM user_log
  UNION                                  -- 同一天进入/离开去重，故用 UNION 而非 UNION ALL
  SELECT uid, DATE(out_time) AS dt FROM user_log
) t1
JOIN (SELECT uid, MIN(DATE(in_time)) AS first_day FROM user_log GROUP BY uid) t2 USING(uid)
GROUP BY dt ORDER BY dt;
```
口径：新客占比 = 当天新增用户 ÷ 当天日活；`UNION`（去重）这里很关键，否则同日多次活跃会重复计数。

**5）用户活跃分级占比**
按「最近一次活跃距今天数」与「是否新增」给用户打级：近 7 天且非新增=忠实、近 7 天新增=新晋、7~30 天=沉睡、>30 天=流失。先按 `uid` 聚出 `min(活跃)`、`max(活跃)`，再用 `DATEDIFF(今天, …)` 落桶，最后按等级算占比。注意「今天」取数据中最大日期，且 `select from t1, t2` 的隐式交叉写法在 Hive 里应改写成显式 JOIN。

**6）连续签到积分（连续问题的核心套路）**
规则示例：每日签到 +1 分，连续第 3、7 天额外 +2、+6 分；连续满 7 天后重新计数。
套路：**「日期 − 行号 = 锚点」**，连续日期的锚点恒定（与第一部分「连续登录」同源，这里加入按天给分）。
```sql
WITH t1 AS (
  SELECT DISTINCT uid, DATE(in_time) AS dt,
         RANK() OVER (PARTITION BY uid ORDER BY DATE(in_time)) AS n   -- 同日去重后编号
  FROM user_log
  WHERE DATE(in_time) BETWEEN '2021-07-07' AND '2021-10-31'
    AND artical_id = 0 AND sign_in = 1
),
t2 AS (
  SELECT uid, dt,
         RANK() OVER (PARTITION BY uid, DATE_SUB(dt, INTERVAL n DAY) ORDER BY dt) % 7 AS day_in_streak
  FROM t1
)
SELECT uid, DATE_FORMAT(dt, '%Y%m') AS month,
       SUM(CASE day_in_streak WHEN 3 THEN 3 WHEN 0 THEN 7 ELSE 1 END) AS coin
FROM t2 GROUP BY 1, 2 ORDER BY 1, 2;
```
关键：用 `DATE_SUB(dt, INTERVAL 序号 DAY)` 得到锚点把每段连续区间分到同一分区；再对区间内排序、`% 7` 还原「这是连续第几天」据此给分。跨天签到只记 `in_time` 当日。

**7）反超时刻（分差变号）**
求每次帮本队反超比分的球员：先用 `SUM() OVER(ORDER BY 时间)` 累计两队比分得到实时分差，再用 `LAG` 取前一行分差，**当前分差与前一分差异号（乘积 < 0）即发生反超**；若前一行分差为 0，则与前两行比较。

**8）新客判定**
```sql
-- 首次活跃即新增
IF(active_time = MIN(active_time) OVER (PARTITION BY uid), 1, 0) AS is_new
-- 进阶：与上次活跃间隔超过 N 天也算新增（回流当新客）
SELECT uid FROM (
  SELECT uid, active_day,
         LAG(active_day) OVER (PARTITION BY uid ORDER BY active_day) AS prev
  FROM active_log WHERE ...
) t WHERE prev IS NULL OR DATEDIFF(active_day, prev) > 180;
```

**9）行为路径序列匹配**
- 「A 操作紧邻 B」：用 `LAG/LEAD` 取相邻操作，判断 `opr = 'A' AND 下一个 = 'B'`。
- 「路径含 A…B…D，且 B 与 D 之间不能有 C」：用 `GROUP_CONCAT(opr ORDER BY 时间)` 把当日操作拼成路径串，再 `HAVING path LIKE 'A%B%D' AND path NOT LIKE 'A%B%C%D'` 做模式匹配。

**10）电商店铺指标**（造数：销售表 `sales(sales_date, user_id, item_id, sales_num, sales_price)` + 商品表 `product(item_id, style_id, tag_price, inventory)`）
- 客单价 = 总收入 / 去重用户数：`SUM(sales_price) / COUNT(DISTINCT user_id)`。
- 折扣率 = GMV / 吊牌金额：`SUM(sales_price) / SUM(tag_price * sales_num)`。
- 动销率 = 有销售 SKU 数 / 在售 SKU 数；售罄率 = GMV / 备货值（吊牌价 × 库存）。先在销售表按 `item_id` 聚出销量与 GMV，再与商品表按 `style_id` 汇总。
- 连续 N 天到店：同「连续问题」套路，`DENSE_RANK` 编号后 `日期 − 序号` 锚点分组计数。

**11）会员收入按天摊销**（造数：`user_pay(user_id, begin_date, end_date, pay_amount)`）
需求：把每笔会员费按有效天数均摊到每一天，统计某区间各月摊销收入。
套路：**生成一张日历表（数字辅助表交叉相乘造日期序列），把日历与支付明细按 `日历日期 BETWEEN begin AND end` 关联，每天分摊 `pay_amount / 有效天数`**，再按月汇总。
```sql
SELECT DATE_FORMAT(d.date, '%Y-%m') AS month,
       ROUND(SUM(p.pay_amount / (DATEDIFF(p.end_date, p.begin_date) + 1)), 2) AS monthly_income
FROM user_pay p
JOIN calendar d ON d.date BETWEEN p.begin_date AND p.end_date     -- calendar 为生成的日期序列
WHERE d.date BETWEEN '2021-01-01' AND '2021-06-30'
GROUP BY month;
```
坑：`BETWEEN ... AND 日期` 中，若右界只精确到天则默认 `00:00:00`，当天带时分秒的数据会漏掉，需对边界做处理（如右界 +1 天取半开区间，或对时间截断到天）。

**12）统计量（中位数 / 众数）**
- 中位数：组内 `ROW_NUMBER()` 排名 + 总数 `COUNT(*) OVER(...)`，取「排名与总数对称」的中间 1~2 行求平均。
- 众数：先 `COUNT() OVER(PARTITION BY 维度, 取值)` 算各取值频次，再 `RANK() OVER(... ORDER BY 频次 DESC)`，取 `rank = 1`。

---

### 常见坑与边界
- `BETWEEN` 是闭区间，跨期/带时间戳统计优先用 `>= AND <` 半开区间，避免重复或漏算月末末刻、边界时刻。
- 窗口函数能保留明细、避免多次扫表，但 `ORDER BY` + 帧范围（`ROWS BETWEEN`）写错会让结果悄悄出错，移动平均/累计要核对帧定义；`ROWS` 按物理行数、`RANGE` 按值范围，别混用。
- `LAG/LEAD` 在边界处返回 NULL，参与除法/比例计算时记得兜底或过滤首尾行。
- `explode`/`LATERAL VIEW` 会成倍放大行数，且对 NULL 数组不产行，做计数统计时要核对口径；过滤要写在 `LATERAL VIEW` 之后。
- 占比/留存的分母多为「去重用户数」`COUNT(DISTINCT uid)`，别误用行数。
- 同一天多次记录会让「连续天数」「日活」算错——连续问题先 `DISTINCT`/`DENSE_RANK` 去重，日活合并进出时用 `UNION` 去重。
- 「连续」类题的统一内核：**构造一个对连续区间恒定的锚点**（连续登录用「日期−序号」，连续得分用「整体排序−个人排序」），再按锚点分区聚合；但要先处理「同一天多次记录」的去重，否则连续天数会算错。
- 排名题先确认口径再选函数：要唯一名次 `ROW_NUMBER`、并列跳号 `RANK`、并列不跳号 `DENSE_RANK`；`RANK` 相减要先 `CAST(... AS SIGNED)`。
- 外连接里过滤条件写 `ON` 还是 `WHERE` 结果不同：`ON` 在连接前、`WHERE` 在连接后；想保留补 NULL 的行，过滤要放对位置。
- 各引擎日期、空值、字符串函数语法有差异：Hive 的 `ON` 不支持不等式连接、不支持 `AVG(布尔)` 这类隐式转换，`隐式交叉 + 条件` 在大数据引擎应改写成显式 JOIN；跨引擎迁移 SQL 前先小数据验证。
- 大数据查询务必带分区过滤，否则一次全表扫描成本极高；JOIN 前先想清是否会数据倾斜。
- `WITH ROLLUP` 产生的小计行，被汇总的维度列值为 NULL，配合 `IFNULL` 命名、`HAVING ... IS NULL` 取小计行。
