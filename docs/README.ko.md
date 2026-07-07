<p align="center">
  <a href="../README.md">English</a> • <b>한국어</b> • <a href="README.ja.md">日本語</a> • <a href="README.zh.md">中文</a>
</p>

<h1 align="center">
  <br>
  ⚡ fable-mode
  <br>
</h1>

<h3 align="center">
  Claude Fable 5는 Opus 4.8의 정확히 2배 가격이다 — 그런데 "Fable다움"의 절반은 그냥 지시문이다.<br>
  이 킷이 그걸 이식한다. <code>/plugin install fable-mode@jidonglab</code> → 다음 세션부터 끝.
</h3>

<p align="center">
  <img src="https://img.shields.io/badge/version-v1.4-blue?style=flat-square" alt="Version" />
  <img src="https://img.shields.io/badge/행동_충실도-64%25→97%25-brightgreen?style=flat-square" alt="Conduct" />
  <img src="https://img.shields.io/badge/비용-Fable의_0.72×-orange?style=flat-square" alt="Cost" />
  <img src="https://img.shields.io/badge/분기_테스트-14%2F14-brightgreen?style=flat-square" alt="Tests" />
</p>

---

```
  순정 Opus에 "왜 버그가 나?" 물으면     →   말없이 파일을 고치고, 실행도 안 한 결과를 단정한다
  순정 Opus에 "이것 좀 정리해줘" 하면    →   조사만 하고 "어떤 방식을 원하세요?" 하고 멈춘다
  Opus + fable-mode                     →   진단만 한다 · 안전한 디폴트는 실행한다 · 주장은 증명한다

  행동 충실도  64% → 97%      비용  Fable의 72%      산출물 등가성  80–95%
```

<h3 align="center">⬇️ Claude Code 세션 안에서 두 줄. 설정 없음.</h3>

```
/plugin marketplace add jee599/fable-mode-kit
/plugin install fable-mode@jidonglab
```

<p align="center">
  다음 세션부터 <b>모든 Opus 세션이 자동 감지</b>되어 Fable 5 행동 규범으로 돈다.<br>
  진짜 Fable 세션도 감지해서 건드리지 않는다. 유일한 요구사항: <code>jq</code>.
</p>

<details>
<summary>클래식 인스톨러 (플러그인 시스템이 없거나 <code>claude-fablelike</code> 래퍼까지 원할 때)</summary>

```bash
git clone https://github.com/jee599/fable-mode-kit && cd fable-mode-kit && ./install.sh
```

요구사항: Claude Code CLI, `jq`, bash (macOS/Linux). 멱등 설치이며 `~/.claude/settings.json`을
덮어쓰지 않고 병합하고, 먼저 백업하고, 끝나기 전에 훅 스모크 테스트를 돌린다.

> [!WARNING]
> 두 경로 중 **하나만** 선택한다. 둘 다 설치하면 훅이 이중 등록되어 규범이 턴마다 두 번
> 주입된다(무해하지만 낭비). `uninstall.sh`는 클래식 설치만, `/plugin uninstall`은 플러그인만 제거한다.

</details>

## 👀 차이를 직접 보기

아래 두 실패는 가정이 아니라 실측된 실제 런이다.

### 🔍 "왜 버그가 나?" 진단 요청 — 6/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ 순정 Opus 4.8**
```
말없이 파일을 수정한다.
실행 한 번 없이
"고쳐졌다"고 단정한다.

(질문을 했는데
 코드를 고쳐버렸다.)
```

</td>
<td width="50%">

**✅ fable-mode 적용**
```
수정 없이 진단만 한다.
코드를 직접 실행해
원인을 증명한다.

결론을 먼저 말하고
근거를 뒤에 붙인다.
```

</td>
</tr>
</table>

### 🧹 모호한 "로그 파일 좀 정리해줘" — 5/12 → 12/12

<table>
<tr>
<td width="50%">

**❌ 순정 Opus 4.8**
```
조사는 꼼꼼히 한다.
그리고 이렇게 끝낸다:
"어떤 방식을 원하세요?"

실행한 것: 없음.
```

</td>
<td width="50%">

**✅ fable-mode 적용**
```
비파괴 디폴트를 즉시
실행하고 검증한다.
파괴적인 단계만
사용자에게 넘긴다.
```

</td>
</tr>
</table>

## 📊 숫자 (체리피킹 없음)

**행동 충실도** — 동일 과제·동일 effort, 6차원 루브릭 36점 심판 채점:

| 조건 | 점수 | 충실도 |
|:---|:---:|:---:|
| 순정 Opus 4.8 | 23/36 | 64% |
| **Opus 4.8 + fable-mode** | **35/36** | **97%** |
| 진짜 Fable 5 (기준선) | 36/36 | 100% |

**비용 + 산출물 등가성** — 4과제 유형 × 3조건, 트랜스크립트 usage 실측 × 공식 단가
(Opus $5/$25, Fable $10/$50 per Mtok):

| 과제 | 순정 Opus | + 킷 | Fable 5 | 킷 vs Fable | 등가성 |
|:---|---:|---:|---:|:---:|:---:|
| 진단 | $0.23 | $0.28 | $0.49 | 57% | ~95% |
| 구현 | $0.34 | $0.45 | $0.49 | 💀 91% | ~90% |
| 모호한 정리 | $0.86 | $1.13 | $1.52 | 74% | ~80% |
| 단순 질문 | $0.12 | $0.13 | $0.27 | 🏆 49% | ~85% |
| **합계** | **$1.54** | **$1.99** | **$2.77** | **72%** | **80–95%** |

> [!NOTE]
> 불리한 숫자도 표에 남긴다. 구현 과제에서 킷의 비용 우위는 9%뿐이었다. 모호 과제에선
> 킷이 순정보다 **31% 더 썼다** — 행동을 사는 교정 턴의 값이다. Fable은 출력 토큰을
> 절반만 쓰고도(9.8k vs 20.0k) 단가 2× 때문에 비용에서 진다. 구현 산출물 3벌(순정/킷/Fable)은
> 같은 테스트 케이스에서 **전부 동일한 출력**을 냈다.

## 🆚 output style 하나면 되지 않나?

output style은 3층 중 한 층일 뿐이다 — 혼자서는 부족하다:

| | CLAUDE.md 규칙 | output style | **fable-mode 훅** |
|:---|:---:|:---:|:---:|
| 긴 컨텍스트 희석에서 살아남음 | ❌ | 🟡 | ✅ 매 턴 재주입 |
| 서브에이전트 커버 (빌트인·커스텀·워크플로) | ❌ | ❌ | ✅ SubagentStart |
| 턴 종료 자가검증 강제 | ❌ | ❌ | ✅ Stop `decision:block` |
| 결정론적 누설가드 (신뢰 대신 grep) | ❌ | ❌ | ✅ v1.4 |
| Opus 자동 감지, Fable 세션엔 자동 침묵 | ❌ | ❌ | ✅ |
| 주입 오버헤드 텔레메트리 | ❌ | ❌ | ✅ v1.4 |

## ⚙️ 동작 원리

셸 스크립트 4개가 세션 수명주기의 네 순간을 잡는다. 데몬도 프록시도 없다 —
상태는 빈 마커 파일이 전부다.

```
  ┌──────────────────────────────────────────────────────────────┐
  │  SessionStart      fable-detect.sh                           │
  │    "지금 Opus인가?" — 플래그 → settings → 트랜스크립트 폴백    │
  │           ↓                                                  │
  │  UserPromptSubmit  fable-context.sh            (매 턴)       │
  │    규범 13조항 재주입 — v1.4부터 적응형:                       │
  │    major 턴 = 풀 블록 · minor 턴 = −84% 리마인더              │
  │           ↓                                                  │
  │  SubagentStart     fable-subagent.sh           (스폰마다)     │
  │    서브에이전트는 매 턴 주입을 못 본다 → 스폰 순간에 주입       │
  │           ↓                                                  │
  │  Stop              fable-stop-verify.sh        (major 턴)    │
  │    종료를 1회 차단: 주장 검증·결론 우선 재마무리 →              │
  │    최종 텍스트를 grep해 규범 누설까지 잡는다                    │
  └──────────────────────────────────────────────────────────────┘
```

원리는 하나다. Fable의 우위는 **지시문**(텍스트 → 이식 가능)과 **웨이트**(추론 깊이 →
이식 불가)로 갈라진다. 훅이 지시문을 이식하고 앵커를 유지하며, 웨이트 갭은 라우팅으로
우회한다 — 얽힌 추론·장기 자율 런만 진짜 Fable로 보내거나 팬아웃 + 적대 검증으로 보정한다.

## 📈 오버헤드 관측

모든 주입이 기록된다. `/fable-mode status`가 킷의 실제 비용을 보고한다:

```bash
$ /fable-mode status
GLOBAL 마커: off · 이 세션: 자동 감지 (claude-opus-4-8)
주입: full 4회 × 1,377자 · lite 11회 × 214자
오버헤드 ≈ 이 세션 4,900토큰 (v1.3이었으면 ≈ 12,900토큰)
```

## 🛡️ 제어와 안전장치

| | |
|:---|:---|
| 🔴 `FABLE_MODE=0` | 킬스위치 — **모든 활성화 경로를 이긴다** (크론·원샷용) |
| 🟢 `FABLE_MODE=1` | 강제 활성화 (`claude-fablelike`가 export하는 것) |
| 🔍 진짜 Fable 세션 | 트랜스크립트에서 자동 감지 → 훅 **자동 침묵**, 이중 주입 없음 |
| 🔁 `/fable-mode on\|off\|status` | 수동 토글 + 텔레메트리 |
| 🏷️ 정체성 | 주입 블록이 "너는 Opus다"라고 고정 — 과제 출력에서 Fable 사칭 없음 |

> [!IMPORTANT]
> Stop 자가검증은 **major 프롬프트당 턴 하나를 더 쓴다**. 킷 비용의 대부분이 이것이고,
> 타임아웃 예산이 있는 헤드리스 런에서 `export FABLE_MODE=0`으로 꺼야 하는 이유다.

<details>
<summary>📦 설치되는 것 (8개)</summary>

| 구성 | 파일 | 역할 |
|---|---|---|
| SessionStart 훅 | `hooks/fable-detect.sh` | Opus 세션 자동 감지 → fable-mode 장전 |
| UserPromptSubmit 훅 | `hooks/fable-context.sh` | 매 턴 규범 재주입 — v1.4 적응형: major 턴·세션 첫 턴·5턴마다 풀 블록(~1.4k자), minor 턴은 리마인더(~0.2k자, −84%); 매 주입을 `state/fable-mode/stats/`에 기록 |
| SubagentStart 훅 | `hooks/fable-subagent.sh` | 모든 서브에이전트 스폰 시 정체성 중립 규범 블록 주입 |
| Stop 훅 | `hooks/fable-stop-verify.sh` | major 턴 1회 자가검증 + 결정론적 누설가드 (v1.4) |
| output style | `output-styles/fable-like.md` | 규범의 시스템 프롬프트 레벨 이식 |
| 스킬 | `skills/fable-mode/` | `/fable-mode on\|off\|status` 수동 토글 |
| 래퍼 | `bin/claude-fablelike` | 원샷: Opus + xhigh effort + output style + 훅 |
| 선택 | `agents/conduct-snippet.md` | SubagentStart 미지원 CLI용 폴백; 마커 보유 에이전트는 자동 스킵 |

</details>

## 📉 정직한 한계

- **97%는 행동 점수다** — 지능 벤치마크가 아니다. 표본: 4과제 유형 × 조건당 1런
  (진단·구현은 2026-07-07 v1.4로 재실측).
- 킷은 교정 턴으로 규범에 도달한다(한 과제에서 8턴 vs 4턴). Fable은 첫 시도에 도달한다.
  **품질이 아니라 턴으로 지불한다.**
- 얽힌 단일 패스 추론과 장기 자율 런의 갭은 남는다(3rd-party 벤치 ~5–11pt 추정).
  그 일감은 Fable 직행, 또는 팬아웃 + 적대 검증으로 보정(Fable 단독 대비 1–2.5× 추정).

## 📑 보고서

실측 덱과 원리 해설 덱 (한국어, 13 + 14 슬라이드, 브라우저에서 바로 열림):

- **[측정 보고 — v1.4 벤치마크](https://jee599.github.io/reports/posts/fable-mode-v14-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-v14-ir.pdf))
- **[동작 원리 해설](https://jee599.github.io/reports/posts/fable-mode-principles-ir.html)** ([PDF](https://jee599.github.io/reports/posts/fable-mode-principles-ir.pdf))

## 🧹 제거

```bash
./uninstall.sh          # 클래식 설치 — 파일 제거·훅 해제·상태 삭제
/plugin uninstall       # 플러그인 경로
```

## 📜 라이선스

MIT

---

<p align="center">
  <b>⚡ 절반 단가로 행동의 97% — 이식 못 하는 것이 무엇인지도 안다.</b>
</p>

<p align="center">
  <a href="https://github.com/jee599/fable-mode-kit">
    <img src="https://img.shields.io/badge/GitHub-⭐_Star_this_repo-yellow?style=for-the-badge&logo=github" alt="Star" />
  </a>
</p>
