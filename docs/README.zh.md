<p align="center">
  <a href="../README.md">English</a> • <a href="README.ko.md">한국어</a> • <a href="README.ja.md">日本語</a> • <b>中文</b>
</p>

<h1 align="center">
  <br>
  ⚡ fable-mode
  <br>
</h1>

<h3 align="center">
  Claude Fable 5 的价格恰好是 Opus 4.8 的 2 倍 — 但「Fable 特质」的一半只是指令。<br>
  这个工具包把它移植过来。<code>/plugin install fable-mode@jidonglab</code> → 下个会话即生效。
</h3>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.5-blue?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/conduct_fidelity-64%25→97%25-brightgreen?style=flat-square" alt="Conduct" />
  <img src="https://img.shields.io/badge/cost-0.72×_Fable-orange?style=flat-square" alt="Cost" />
</p>

---

```
  问原生 Opus「为什么会有这个 bug?」    →   默默修改你的文件，断言未经运行的结果
  让原生 Opus「清理一下这些」          →   只调查，然后停下来问「你想用哪种方式?」
  Opus + fable-mode                   →   只诊断 · 对安全的默认操作直接执行 · 主张必先证明

  行为保真度  64% → 97%      成本  Fable 的 72%      产出等价性  80–95%
```

<h3 align="center">⬇️ 在任意 Claude Code 会话中输入两行。零配置。</h3>

```
/plugin marketplace add jee599/fable-mode-kit
/plugin install fable-mode@jidonglab
```

<p align="center">
  从下个会话起，<b>每个 Opus 会话都会被自动检测</b>并在 Fable 5 行为规范下运行。<br>
  真正的 Fable 会话也会被检测到并保持原样。唯一要求：<code>jq</code>。
</p>

<details>
<summary>经典安装器 (没有插件系统，或想安装 <code>claude-fablelike</code> 包装器时)</summary>

```bash
git clone https://github.com/jee599/fable-mode-kit && cd fable-mode-kit && ./install.sh
```

要求：Claude Code CLI、`jq`、bash (macOS/Linux)。幂等安装，合并而非覆盖你的
`~/.claude/settings.json`，先备份，并在结束前对钩子做冒烟测试。

> [!WARNING]
> **只选一条路**。两个都装会导致钩子重复注册，规范每轮注入两次(无害但浪费)。
> `uninstall.sh` 只移除经典安装，`/plugin uninstall` 只移除插件。

</details>

## 👀 看看差别

下面两个失败不是假设，而是实测的真实运行。

### 🔍 问「为什么会有这个 bug?」— 6/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ 原生 Opus 4.8**
```
默默修改文件。
一次都没运行
就断言「已修复」。

(你问了个问题，
 它改了你的代码。)
```

</td>
<td width="50%">

**✅ 启用 fable-mode**
```
不修改，只诊断。
直接运行代码
证明根本原因。

先给结论，
再附上依据。
```

</td>
</tr>
</table>

### 🧹 含糊的「清理一下日志文件」— 5/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ 原生 Opus 4.8**
```
调查得很彻底。
然后这样收尾：
「你想用哪种方式?」

实际执行：无。
```

</td>
<td width="50%">

**✅ 启用 fable-mode**
```
立即执行非破坏性
默认操作并验证。
只把破坏性的部分
留给用户决定。
```

</td>
</tr>
</table>

## 📊 数字 (不挑好的说)

**行为保真度** — 相同任务、相同 effort，按 6 维度评分标准打分(满分 36):

| 条件 | 得分 | 保真度 |
|:---|:---:|:---:|
| 原生 Opus 4.8 | 23/36 | 64% |
| **Opus 4.8 + fable-mode** | **35/36** | **97%** |
| 真正的 Fable 5 (基准线) | 36/36 | 100% |

**成本 + 产出等价性** — 4 类任务 × 3 条件，从 transcript 的 usage 实测 × 官方单价
(Opus $5/$25、Fable $10/$50 每 Mtok):

| 任务 | 原生 Opus | + 工具包 | Fable 5 | 工具包 vs Fable | 等价性 |
|:---|---:|---:|---:|:---:|:---:|
| 诊断 | $0.23 | $0.28 | $0.49 | 57% | ~95% |
| 实现 | $0.34 | $0.45 | $0.49 | 💀 91% | ~90% |
| 含糊清理 | $0.86 | $1.13 | $1.52 | 74% | ~80% |
| 简单提问 | $0.12 | $0.13 | $0.27 | 🏆 49% | ~85% |
| **合计** | **$1.54** | **$1.99** | **$2.77** | **72%** | **80–95%** |

> 单元格是四舍五入后的单次运行值;合计与 × 比率用未取整的原始值算，所以拿显示的单元格
> 重新推算，末位可能有 ±1 的差。

> [!NOTE]
> 难看的数字也留在表里。实现任务上工具包对 Fable 的成本优势只有 9%。含糊任务上工具包比原生
> Opus **多花了 31%** — 这是买来行为的自我修正回合的代价。Fable 只写一半的输出 token
> (9.8k vs 20.0k)，却因单价 2 倍在成本上落败。三份实现产出(原生/工具包/Fable)在共享测试用例上
> 输出**完全一致**。以上为 v1.4 实测;v1.5 移除了 Stop 钩子在 major 回合的额外生成回合，
> 因此成本持平或更低。

## 🆚 光用 output style 不够吗?

output style 只是三层中的一层 — 单独不够:

| | CLAUDE.md 规则 | output style | **fable-mode 钩子** |
|:---|:---:|:---:|:---:|
| 在长上下文稀释中存活 | ❌ | 🟡 | ✅ 每轮重新注入 |
| 覆盖子代理 (内置·自定义·工作流) | ❌ | ❌ | ✅ SubagentStart |
| 每个 major 回合的收尾前自我检查 | ❌ | ❌ | ✅ 随上下文注入(无额外回合) |
| 规范用语不外泄到输出 | ❌ | ❌ | ✅ 泄漏源头已直接移除 |
| 自动检测 Opus，遇 Fable 会话自动待命 | ❌ | ❌ | ✅ |
| 注入开销遥测 | ❌ | ❌ | ✅ v1.4 |

## ⚙️ 工作原理

三个活跃钩子抓住会话生命周期的三个时刻;第四个(Stop)是已退役的空操作桩。
没有守护进程，没有代理 — 状态就是空的标记文件。

```
  ┌──────────────────────────────────────────────────────────────┐
  │  SessionStart      fable-detect.sh                           │
  │    「现在是 Opus 吗?」— 输入 .model → 祖先进程 --model 参数    │
  │    → settings.json (推测 → 中性通告)                          │
  │           ↓                                                  │
  │  UserPromptSubmit  fable-context.sh          (每轮)         │
  │    每轮 transcript 检测(会话中途 /model 切换·Fable 待命)      │
  │    + 重新注入行为规范 — 自适应: major = 完整块 · minor =       │
  │    −86% 提醒块。完整块的最后一条就是收尾前自我检查             │
  │    (随上下文注入，无额外生成回合)                             │
  │           ↓                                                  │
  │  SubagentStart     fable-subagent.sh         (每次生成)      │
  │    子代理看不到 UserPromptSubmit → 在生成时刻注入              │
  │                                                              │
  │  Stop              fable-stop-verify.sh      (已退役的桩)     │
  │    空操作 — 保持注册，重新启用只需一次单文件 git revert;       │
  │    它过去强制的自我检查现在活在上面的完整块里                   │
  └──────────────────────────────────────────────────────────────┘
```

原理只有一条。Fable 的优势分为**指令**(文本 → 可移植)和**权重**(推理深度 → 不可移植)。
钩子移植指令并保持锚定，权重差距靠路由绕过 — 只把纠缠的推理和长时间自主运行交给真正的
Fable，或用扇出 + 对抗式验证来补偿。

## 📈 观测开销

每次注入都会被记录。`/fable-mode status` 报告工具包实际花了你多少:

```bash
$ /fable-mode status
GLOBAL 标记: off · 本会话: 自动检测 (claude-opus-4-8)
注入: full 4 × 1,636 字 · lite 11 × 234 字
本会话开销 ≈ 5,700 tokens (tokens ≈ 字数 ÷ 1.6; 若每轮都用完整块则 ≈ 15,300)
```

每个会话的统计逐行写入 `state/fable-mode/stats/<sid>.tsv`(每行 `类型<TAB>字数`)，
`status` 据此汇总 full/lite 次数与字数总计。完整块 1,636 字 ≈ 1,020 tokens，
lite 提醒块 234 字 ≈ 146 tokens — lite 比 full 省 **−86%**;节奏不变(major 回合 +
会话首次注入 + 每 5 轮 = 完整块)。

## 🛡️ 控制与安全

| | |
|:---|:---|
| 🔴 `FABLE_MODE=0` | 终止开关 — **胜过所有激活路径** (用于 cron·一次性运行) |
| 🟢 `FABLE_MODE=1` | 强制启用 (`claude-fablelike` 导出的值) |
| 🔍 真正的 Fable 会话 | 从 transcript 自动检测 → 钩子**待命**，无双重注入 |
| 🔁 `/fable-mode on\|off\|status` | 手动切换 + 遥测 |
| 🏷️ 身份 | 只有锁定了会话模型的激活路径(`FABLE_MODE=1`、transcript 命中 opus)才注入「你是 Opus」;仅凭标记激活(可能误判)时改注入中性身份行 — 任务输出中不冒充 Fable |
| ✅ 收尾前自我检查 | 完整块的最后一条随每轮注入，对用户不可见，不再多花生成回合 |

> [!IMPORTANT]
> v1.5 退役了 Stop 钩子(现为空操作桩)—收尾前自我检查改由每轮注入承载，因此不再为每个
> major 提示多花一个生成回合，比 v1.4 更省。无头运行仍可 `export FABLE_MODE=0` 完全关闭注入。

<details>
<summary>📦 安装内容 (8 项)</summary>

| 组件 | 文件 | 作用 |
|---|---|---|
| SessionStart 钩子 | `hooks/fable-detect.sh` | 自动检测 Opus 会话 → 装载 fable-mode |
| UserPromptSubmit 钩子 | `hooks/fable-context.sh` | 每轮重新注入行为规范 — v1.4 起自适应: major 回合·会话首轮·每 5 轮用完整块(~1.6k 字), minor 回合用提醒块(~0.2k 字, −86%); 每次注入记入 `state/fable-mode/stats/` |
| SubagentStart 钩子 | `hooks/fable-subagent.sh` | 每次生成子代理时注入身份中性的规范块 |
| Stop 钩子 | `hooks/fable-stop-verify.sh` | 已退役的空操作桩 — 保持注册，重新启用只需一次单文件 git revert |
| output style | `output-styles/fable-like.md` | 规范的系统提示级移植 |
| 技能 | `skills/fable-mode/` | `/fable-mode on\|off\|status` 手动切换 |
| 包装器 | `bin/claude-fablelike` | 一次性: Opus + xhigh effort + output style + 钩子 |
| 可选 | `docs/conduct-snippet.md` | 无 SubagentStart 支持的 CLI 的回退方案;定义里已带 `fable-like-conduct` 标记的代理会自动跳过(无双重注入) |

</details>

## 📉 诚实的局限

- **97% 是行为分**，不是智能基准。样本: 4 类任务 × 每条件 1 次运行
  (诊断·实现于 2026-07-07 用 v1.4 重新测量)。
- 工具包靠修正回合达到规范(某任务 8 回合 vs 4 回合)。Fable 首次尝试即达到。
  **你付的是回合，不是质量。**
- 纠缠的首次推理和长时间自主运行的差距仍然存在(第三方基准 ~5–11pt 估计)。
  这类任务交给 Fable，或用扇出 + 对抗式验证补偿(相对单次 Fable 运行 1–2.5× 估计)。

## 📑 报告

实测幻灯片和原理讲解幻灯片 (韩语、13 + 14 页，浏览器可直接打开):

- **[测量报告 — v1.4 基准](https://jee599.github.io/reports/posts/fable-mode-v14-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-v14-ir.pdf))
- **[工作原理讲解](https://jee599.github.io/reports/posts/fable-mode-principles-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-principles-ir.pdf))

## 🧹 卸载

```bash
./uninstall.sh          # 经典安装 — 移除文件·注销钩子·删除状态
/plugin uninstall       # 插件路径
```

## 📜 许可证

MIT

---

<p align="center">
  <b>⚡ 用一半的单价换来 97% 的行为 — 而且它清楚自己移植不了什么。</b>
</p>

<p align="center">
  <a href="https://github.com/jee599/fable-mode-kit">
    <img src="https://img.shields.io/badge/GitHub-⭐_Star_this_repo-yellow?style=for-the-badge&logo=github" alt="Star" />
  </a>
</p>
