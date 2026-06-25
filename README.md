# 数据分析助理（知识库 + Claude Skill）

![Claude Skill](https://img.shields.io/badge/Claude-Skill-d97757) ![knowledge](https://img.shields.io/badge/knowledge-56%20files%20%2F%2010%20boards-blue) ![living doc](https://img.shields.io/badge/living%20doc-%E6%8C%81%E7%BB%AD%E6%8A%95%E5%96%82%E8%BF%AD%E4%BB%A3-brightgreen) ![code: MIT](https://img.shields.io/badge/code-MIT-blue) ![content: CC BY-SA 4.0](https://img.shields.io/badge/content-CC%20BY--SA%204.0-lightgrey)

一个开源的**数据分析方法论**知识库，同时是一个 **Claude Skill**——帮你（或任意 AI）做指标体系设计、分析方法选型、数据异动解读、复盘报告、BI 取数。

> **第一次打开这个仓库（无论你是人，还是某个 AI），请先读完本文件——它告诉你这是什么、你该干什么。**

## 这是什么
一个开源的**数据分析方法论**知识库，同时是一个 **Claude Skill**。它指导 AI 充当数据分析助理：设计指标体系、选择分析方法、解读数据异动、做复盘与报告、为 BI 取数提炼好问题与口径。

它有两种"身份"：
- **对 Claude**：一个会被自动识别、自动触发的 **Skill**（入口 `SKILL.md`）。
- **对任何其他 AI / 人**：`reference/` 目录与 `通用知识包.md` 是**纯文本知识**，可以直接读、直接用。

> **远期场景**：配合开源 BI 工具 **knot**（自然语言→SQL→图表+洞察）使用。knot 当前尚未接入 skill 能力，本仓库现阶段作为独立 Skill / 知识库使用。

---

## 安装 / 使用

这是一个标准的 **Claude Agent Skill**（入口即 `SKILL.md`），**任何人都能装来用**，不限于本仓库作者；同一份内容也能脱离 Claude、作为纯知识库给任意 AI 用。

**① 作为 Claude Code 的 Skill（自动触发）**
```bash
git clone https://github.com/kkleonnnn/da-asst.git
ln -s "$(pwd)/da-asst" ~/.claude/skills/data-analysis-assistant   # 软链到个人 skills 目录
```
之后在 Claude Code 里聊到「指标体系 / AB 实验 / 数据异动 / 取数 / 复盘 / 经营分析」等话题，它会**自动触发**，用 `reference/` 的知识帮你分析。（也可把仓库放进某项目的 `.claude/skills/` 下，只在该项目生效。）

**② 作为 claude.ai / Claude Desktop 的 Skill**
在支持「Skills」的 Claude 客户端里，按其 Skills 入口添加本仓库（含 `SKILL.md`）即可，触发逻辑同上。

**③ 作为纯知识库（任意 AI / 人，不限 Claude）**
把 [`通用知识包.md`](通用知识包.md)（由 `reference/` 自动生成的单文件整合版）当上下文喂给任意模型；或按板块直接浏览 [`reference/`](reference/)。

**④ 想投喂资料 / 贡献** → 见 [`CONTRIBUTING.md`](CONTRIBUTING.md)。

> ⚠️ **关于"通用"**：「skill」是**运行环境（harness）的功能，不是模型的功能**。`SKILL.md` 的自动触发由 Claude 生态（Claude Code / claude.ai / Desktop / Agent SDK）支持——**ChatGPT、Gemini 等别家 App 不会自动识别 `SKILL.md`**。在非 Claude 模型上请走方式 ③：把 `通用知识包.md` 当知识库喂入；或在自建 agent 里自行写加载器（用 `description` 路由、注入正文与 `reference/`）。**内容本身与模型无关，任何模型都能读。**
>
> 另：想让**非 Claude 模型**也遵守本仓库的「**应答原则**」（回答方案 / 决策类问题时不铺平全套、保留你的判断权）？把 [`决策应答原则-可粘贴提示词.md`](决策应答原则-可粘贴提示词.md) 里那段整段粘进它的 system prompt 即可（Claude skill 触发时已自动生效，无需粘贴）。

---

## 这是一个公开仓库——关于资料来源（重要）

本知识库的内容来自对外部文章与实践经验的**消化、改写与再组织**；仓库里只保留**改写后的自有表述**，做不到这点的内容不进库。具体机制：

- **原始资料一律不入库**：投喂用的 `inbox/` 整个被 `.gitignore`，原文只留在本地。
- **只收录改写重述后的知识**：消化时抽取事实与方法，用自己的话重写，不照搬原句、原结构、原案例编号。
- **不保留任何来源指纹**：知识文件不写出处、作者、平台、链接、二维码、截图；元信息只留 `适用范围 / 时效 / 可信度 / 方法论标签`。
- **自动禁词扫描**：`scripts/scrub_check.sh` 在生成 / 提交前扫描 `reference/` 与通用包，命中来源指纹即报错拦截（真实禁词清单留本地、不入库）。

> 为什么这样做：事实与方法本身不受版权保护，受保护的是具体"表达"。改写消化既是把知识转化为自有资产的正当方式，也保证内容干净、可开源、且**无法被反向溯源到原始出处**。

---

## 谁干什么（三种角色，请对号入座）

| 角色 | 谁 / 什么工具 | 能做什么 |
|---|---|---|
| **喂料 + 第一遍消化** | 任何人、**任何模型** | 把外部资料放进 `inbox/`，可先粗消化成结构化 `.md`（**只留本地，不入库**） |
| **最终整合**（inbox → reference） | 建议 **Opus 4.8+** 把关 | **改写、脱敏** + 校对核实规范化后写进 `reference/`、跑 scrub、审 PR 合并 main |
| **消费**（读 reference 干活） | **任何 AI 模型** | 读 `reference/` 或 `通用知识包.md` 回答分析问题、设计指标、出复盘 / 报告 |

> ⚠️ **两遍消化制**：第一遍人人可做（任何模型把资料粗消化成 `.md`，留本地减负）；**最终整合并入 `reference/` 是质量 + 防溯源关口**——彻底改写、抹除来源指纹、交叉核实，建议 Opus 4.8+。**其他人 / 弱模型不直接改 `reference/`**，否则会污染知识库、留下溯源痕迹。
>
> ⚠️ **防溯源的关键约束**：因本仓库公开 + 资料敏感，**第一遍 `.md` 只留本地、绝不提交**（它还没脱敏），只有最终整合后的 `reference/` 文本才入库——这点由 `.gitignore`（inbox 全量不入库）强制保证。

---

## 正式工作流程（一条龙）

```
①喂料 + 第一遍消化         ②最终整合(改写+脱敏)        ③PR → 合并 main        ④生成 + 消费
外部资料粗消化成 .md   →   改写脱敏 + 核实规范化   →   跑 scrub → 审核    →   重新生成
丢进 inbox/(任何模型)       并入 reference/            并入 main           通用知识包.md，
(只留本地、不提交)         (建议 Opus 4.8+)          = 正式迭代生效       任何 AI 都能用
```

**关键：inbox 里的内容不会自动生效。** 必须经 ②最终整合并入 `reference/`（改写 + 脱敏 + scrub）→ ③PR 合并 main，才算"正式迭代"进知识库。

---

## 目录结构

```
da-asst/
├─ README.md          ← 你正在读的总入口
├─ SKILL.md           ← Claude 专用入口（Skill 定义；其他 AI 可忽略）
├─ CONTRIBUTING.md    ← 怎么喂料、怎么消化脱敏、怎么提 PR
├─ 通用知识包.md        ← 由 reference/ 自动生成，给任何 AI / 人直接读用（勿手改）
├─ scripts/
│   ├─ build_pack.sh         ← 重新生成「通用知识包.md」（生成后自动跑禁词扫描）
│   ├─ scrub_check.sh        ← 来源指纹 / 禁词扫描，命中即报错（提交前自检）
│   └─ .scrub_wordlist.example ← 禁词清单模板（复制为 .local 填真实词，.local 不入库）
├─ reference/         ← ★单一知识源（已消化、已改写、已脱敏）
│   ├─ _消化日志.md     ← 消化进度（不写来源身份）
│   └─ 01-入门与认知/ … 10-AI辅助分析/  ← 10 个板块（见 reference/README.md）
├─ templates/
│   └─ 知识文件模板.md   ← 每个知识文件的写法（强制无来源元信息）
└─ inbox/             ← 投喂外部资料（整个目录不入库，原文只留本地）
```

---

## 板块（10 个）
`reference/` 按 10 个板块组织：入门与认知 / 分析思维与方法 / 指标体系 / 统计基础 / 实验与因果推断 / 预测与机器学习 / 业务场景实战 / 取数与工具 / 数据治理与数仓 / AI辅助分析。明细见 [`reference/README.md`](reference/README.md)；板块可随投喂演进。

---

## 给「非 Claude AI」的使用说明
如果你是 ChatGPT、Gemini 或其他 AI，被用来辅助数据分析：
1. **你的知识来源 = `reference/` 里的内容（或整合好的 `通用知识包.md`）。** 优先以它为准，它是已核实、已脱敏的。
2. **你可以做"第一遍消化"**（把资料粗消化成 `.md` 放 `inbox/`，留本地不提交），但**不要直接改 `reference/`**——并入 reference 是最终整合（改写脱敏 + 核实，建议 Opus 4.8+）。你也可以把内容当上下文来回答、分析、起草报告。
3. 你可以帮用户：设计指标、选分析方法、解读数据异动、写复盘 / 分析报告、为 BI 取数提炼好问题——依据就是 reference 的知识。

## 给 Claude 的说明
见 `SKILL.md`。简言之：被触发后用 `reference/` 的知识办事；**"消化 inbox"分两遍——任何模型可做第一遍（粗消化成 `.md`，留本地不提交）；并入 `reference/` 是最终整合（必须改写 + 脱敏 + 跑 scrub，建议 Opus 4.8+），走 PR 合并 main。**

---

## 现状（2026-06-24）
- ✅ **知识库**：**56 篇知识文件 / 10 板块**（社群文章 + 出版书籍精炼；已按"一原理一知识点"跨来源归并、统一知识点式命名，见 `reference/`）；`通用知识包.md` 同步生成。
- ✅ **双层脱敏**：①防溯源（原始资料不入库、抹除来源指纹、`scripts/scrub_check.sh` 扫描）；②防隐私（匿名化公司 / 产品名与可识别项目数据，保留分析方法）。
- ✅ **可持续迭代**：丢资料进 `inbox/` → 消化 → 重生成通用包，详见 `CONTRIBUTING.md`。

---

## 授权 License
本仓库**双授权**：
- **代码**（`scripts/` 工具脚本）—— [MIT](LICENSE)
- **知识内容**（`reference/`、`通用知识包.md`）—— [CC BY-SA 4.0](LICENSE-CONTENT)：可自由使用、改编、再分发，但须**署名**并以**相同方式共享**。

> 内容为对公开行业资料与实践经验的消化、改写与再组织（见上文「关于资料来源」）。
