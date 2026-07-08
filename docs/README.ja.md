<p align="center">
  <a href="../README.md">English</a> • <a href="README.ko.md">한국어</a> • <b>日本語</b> • <a href="README.zh.md">中文</a>
</p>

<h1 align="center">
  <br>
  ⚡ fable-mode
  <br>
</h1>

<h3 align="center">
  Claude Fable 5 の料金は Opus 4.8 のちょうど2倍 — だが「Fable らしさ」の半分は単なる指示文だ。<br>
  このキットがそれを移植する。<code>/plugin install fable-mode@jidonglab</code> → 次のセッションから完了。
</h3>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.5-blue?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/conduct_fidelity-64%25→97%25-brightgreen?style=flat-square" alt="Conduct" />
  <img src="https://img.shields.io/badge/cost-0.72×_Fable-orange?style=flat-square" alt="Cost" />
</p>

---

```
  素の Opus に「なぜバグる?」と聞くと      →   黙ってファイルを編集し、未実行の結果を断定する
  素の Opus に「これを整理して」と頼むと    →   調査だけして「どの方式がいいですか?」で止まる
  Opus + fable-mode                       →   診断のみ · 安全なデフォルトは実行 · 主張は証明する

  行動忠実度  64% → 97%      コスト  Fable の 72%      成果物の同等性  80–95%
```

<h3 align="center">⬇️ Claude Code セッション内で2行。設定不要。</h3>

```
/plugin marketplace add jee599/fable-mode-kit
/plugin install fable-mode@jidonglab
```

<p align="center">
  次のセッションから <b>すべての Opus セッションが自動検出</b>され、Fable 5 の行動規範で動く。<br>
  本物の Fable セッションも検出して手を触れない。唯一の要件: <code>jq</code>。
</p>

<details>
<summary>クラシックインストーラ (プラグインシステムがない、または <code>claude-fablelike</code> ラッパーが欲しい場合)</summary>

```bash
git clone https://github.com/jee599/fable-mode-kit && cd fable-mode-kit && ./install.sh
```

要件: Claude Code CLI、`jq`、bash (macOS/Linux)。冪等インストールで `~/.claude/settings.json` を
上書きせずマージし、先にバックアップし、終了前にフックのスモークテストを実行する。

> [!WARNING]
> **どちらか一方**を選ぶ。両方入れるとフックが二重登録され、規範がターンごとに二重注入される
> (無害だが無駄)。`uninstall.sh` はクラシックのみ、`/plugin uninstall` はプラグインのみ削除する。

</details>

## 👀 違いを見る

以下の2つの失敗は仮定ではなく、実測された実際の実行だ。

### 🔍「なぜこのバグが起きる?」— 6/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ 素の Opus 4.8**
```
黙ってファイルを編集する。
一度も実行せずに
「直った」と断定する。

(質問したのに
 コードを書き換えた。)
```

</td>
<td width="50%">

**✅ fable-mode 適用**
```
編集せず診断のみ。
コードを実際に実行して
根本原因を証明する。

結論を先に述べ
根拠を後に付ける。
```

</td>
</tr>
</table>

### 🧹 曖昧な「ログファイルを整理して」— 5/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ 素の Opus 4.8**
```
調査は徹底的にやる。
そして最後にこう言う:
「どの方式がいいですか?」

実行したこと: なし。
```

</td>
<td width="50%">

**✅ fable-mode 適用**
```
非破壊的なデフォルトを
即座に実行し検証する。
破壊的な部分だけを
ユーザーに委ねる。
```

</td>
</tr>
</table>

## 📊 数字 (チェリーピッキングなし)

**行動忠実度** — 同一タスク・同一 effort、6次元ルーブリック36点で採点:

| 条件 | スコア | 忠実度 |
|:---|:---:|:---:|
| 素の Opus 4.8 | 23/36 | 64% |
| **Opus 4.8 + fable-mode** | **35/36** | **97%** |
| 本物の Fable 5 (基準線) | 36/36 | 100% |

**コスト + 成果物の同等性** — 4タスク × 3条件、トランスクリプトの usage を実測 × 公式料金
(Opus $5/$25、Fable $10/$50 per Mtok):

| タスク | 素の Opus | + キット | Fable 5 | キット vs Fable | 同等性 |
|:---|---:|---:|---:|:---:|:---:|
| 診断 | $0.23 | $0.28 | $0.49 | 57% | ~95% |
| 実装 | $0.34 | $0.45 | $0.49 | 💀 91% | ~90% |
| 曖昧な整理 | $0.86 | $1.13 | $1.52 | 74% | ~80% |
| 単純な質問 | $0.12 | $0.13 | $0.27 | 🏆 49% | ~85% |
| **合計** | **$1.54** | **$1.99** | **$2.77** | **72%** | **80–95%** |

> セルは1実行あたりの丸め値。合計と × 比率は丸め前の生値から計算しているため、表示セルから
> 再計算すると末尾桁で ±1 ずれることがある。

> [!NOTE]
> 不利な数字も表に残す。実装タスクでのキットのコスト優位はわずか9%だった。曖昧なタスクでは
> キットが素の Opus より **31% 多く**使った — 行動を買う自己修正ターンの代償だ。Fable は
> 出力トークンを半分しか使わない(9.8k vs 20.0k)のに単価2倍のためコストで負ける。実装成果物の
> 3つ(素/キット/Fable)は共有テストケースで **すべて同一の出力**を生成した。この数字は v1.4 での
> 実測で、v1.5 は major ターンでの Stop フックの追加生成パスを除去したため、コストは同等かそれ以下だ。

## 🆚 output style だけで十分では?

output style は3層のうちの1層にすぎない — 単独では不足だ:

| | CLAUDE.md ルール | output style | **fable-mode フック** |
|:---|:---:|:---:|:---:|
| 長いコンテキストの希釈に耐える | ❌ | 🟡 | ✅ ターンごとの再注入 |
| サブエージェントをカバー (ビルトイン・カスタム・ワークフロー) | ❌ | ❌ | ✅ SubagentStart |
| major ターンごとの仕上げ前自己点検 | ❌ | ❌ | ✅ コンテキスト内に注入 (追加パスなし) |
| 規範リークを出力に出さない | ❌ | ❌ | ✅ リーク経路を根元で除去 |
| Opus 自動検出、Fable では自動待機 | ❌ | ❌ | ✅ |
| 注入オーバーヘッドのテレメトリ | ❌ | ❌ | ✅ v1.4 |

## ⚙️ 仕組み

4つのシェルスクリプトがセッションライフサイクルの4つの瞬間を捉える。デーモンもプロキシもなく、
状態は空のマーカーファイルだけ。

```
  ┌──────────────────────────────────────────────────────────────┐
  │  SessionStart      fable-detect.sh                           │
  │    「今 Opus か?」                                            │
  │    入力 .model → 祖先の --model フラグ → settings.json         │
  │    (settings は推測 → 中立に告知)                             │
  │           ↓                                                  │
  │  UserPromptSubmit  fable-context.sh          (毎ターン)      │
  │    行動規範を再注入 + トランスクリプトから毎ターンモデル再判定。 │
  │    v1.4 から適応型 — major = フルブロック(末尾に仕上げ点検) ·   │
  │    minor = −86% リマインダ                                    │
  │           ↓                                                  │
  │  SubagentStart     fable-subagent.sh         (スポーン毎)     │
  │    サブエージェントは毎ターン注入を見ない → スポーン時に注入     │
  │           ↓                                                  │
  │  Stop              fable-stop-verify.sh      (引退・スタブ)   │
  │    v1.5 で無効化 (no-op)。登録は維持 →                          │
  │    復活は1ファイルの git revert                                │
  └──────────────────────────────────────────────────────────────┘
```

原理は一つ。Fable の強みは **指示文**(テキスト → 移植可能)と **重み**(推論の深さ →
移植不可)に分かれる。フックが指示文を移植してアンカーを保ち、重みのギャップはルーティングで
迂回する — 絡み合った推論と長時間の自律実行だけを本物の Fable へ回すか、ファンアウト +
敵対的検証で補正する。

## 📈 オーバーヘッドを見る

すべての注入が記録される。`/fable-mode status` がキットの実コストを報告する:

```bash
$ /fable-mode status
GLOBAL マーカー: off · このセッション: 自動検出 (claude-opus-4-8)
注入: full 4回 × 1,636字 · lite 11回 × 234字
オーバーヘッド ≈ このセッション 5,700トークン (v1.3 なら ≈ 15,300)
```

セッションごとの stats は `state/fable-mode/stats/<sid>.tsv` に貯まり、full/lite の回数と
文字数の合計を持つ。トークンは文字数 ÷ 1.6 で概算する(full ≈ 1,020 · lite ≈ 146 トークン)。

## 🛡️ 制御と安全装置

| | |
|:---|:---|
| 🔴 `FABLE_MODE=0` | キルスイッチ — **すべての有効化経路に勝つ** (cron・ワンショット用) |
| 🟢 `FABLE_MODE=1` | 強制有効化 (`claude-fablelike` が export するもの) |
| 🔍 本物の Fable セッション | トランスクリプトから自動検出 → フックは**待機**、二重注入なし |
| 🔁 `/fable-mode on\|off\|status` | 手動トグル + テレメトリ |
| 🏷️ 条件付きアイデンティティ | セッションモデルを固定する経路(`FABLE_MODE=1`・トランスクリプトの opus 一致)でだけ「あなたは Opus」と主張。マーカーだけの推測起動には中立のアイデンティティ行を出す — settings の誤爆で Fable セッションに Opus を名乗らせない。タスク出力での Fable なりすましもなし |

> [!IMPORTANT]
> v1.5 では仕上げ前の自己点検が Stop フックから毎ターンの注入(フルブロック末尾の点検項目)へ
> 移った — ユーザーには見えず、追加の生成パスもない。Stop スクリプトは no-op スタブとして
> 登録だけ残り、復活は1ファイルの git revert で済む。

<details>
<summary>📦 インストールされるもの (8個)</summary>

| 構成 | ファイル | 役割 |
|---|---|---|
| SessionStart フック | `hooks/fable-detect.sh` | Opus セッションを自動検出 → fable-mode を装填 |
| UserPromptSubmit フック | `hooks/fable-context.sh` | 毎ターン規範を再注入 — v1.4 から適応型: major ターン・セッション初回・5ターンごとにフルブロック(~1.6k字)、minor ターンはリマインダ(~0.23k字、−86%); 全注入を `state/fable-mode/stats/` に記録 |
| SubagentStart フック | `hooks/fable-subagent.sh` | 全サブエージェントのスポーン時にアイデンティティ中立の規範ブロックを注入 |
| Stop フック | `hooks/fable-stop-verify.sh` | 引退した no-op スタブ (v1.5) — 登録だけ残し、1ファイルの git revert で自己検証パスを復活できる |
| output style | `output-styles/fable-like.md` | 規範のシステムプロンプトレベル移植 |
| スキル | `skills/fable-mode/` | `/fable-mode on\|off\|status` 手動トグル |
| ラッパー | `bin/claude-fablelike` | ワンショット: Opus + xhigh effort + output style + フック |
| 任意 | `docs/conduct-snippet.md` | SubagentStart 非対応 CLI (旧 CLI・最小 -p 構成) 用フォールバック |

</details>

## 📉 正直な限界

- **97% は行動スコア**であり、知能ベンチマークではない。サンプル: 4タスク × 条件あたり1実行
  (診断・実装は 2026-07-07 に v1.4 で再測定)。
- キットは修正ターンで規範に到達する(あるタスクで8ターン vs 4ターン)。Fable は初回で到達する。
  **品質ではなくターンで支払う。**
- 絡み合った初回推論と長時間の自律実行のギャップは残る(3rd-party ベンチ ~5–11pt 推定)。
  それらは Fable へ回すか、ファンアウト + 敵対的検証で補正する(Fable 単独比 1–2.5× 推定)。

## 📑 レポート

実測デッキと原理解説デッキ (韓国語、13 + 14 スライド、ブラウザで直接開ける):

- **[測定レポート — v1.4 ベンチマーク](https://jee599.github.io/reports/posts/fable-mode-v14-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-v14-ir.pdf))
- **[仕組みの解説](https://jee599.github.io/reports/posts/fable-mode-principles-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-principles-ir.pdf))

## 🧹 アンインストール

```bash
./uninstall.sh          # クラシックインストール — ファイル削除・フック解除・状態削除
/plugin uninstall       # プラグイン経路
```

## 📜 ライセンス

MIT

---

<p align="center">
  <b>⚡ 半額の単価で行動の97% — 移植できないものが何かも分かっている。</b>
</p>

<p align="center">
  <a href="https://github.com/jee599/fable-mode-kit">
    <img src="https://img.shields.io/badge/GitHub-⭐_Star_this_repo-yellow?style=for-the-badge&logo=github" alt="Star" />
  </a>
</p>
