#!/bin/bash
# UserPromptSubmit hook — while fable-mode is active, re-inject the Fable 5 conduct
# norms every turn (stdout on exit 0 becomes model-visible context). Per-turn
# re-injection is deliberate: instruction adherence dilutes over long contexts.
# On major turns the full block also carries a proactive pre-finish self-check
# ("마무리 점검" bullet). This used to be a Stop hook (fable-stop-verify.sh) that
# forced it via decision:block — but Claude Code echoes a Stop-block's reason into
# the user's transcript (looked like an error) and it cost an extra generation
# pass. Injecting it here keeps the behavior while staying invisible to the user.
#
# Adaptive injection (v1.4): the full ~1.6k-char block goes in on major turns, on the
# session's first injection, and every 5th injection (drift refresh); minor turns get
# a ~230-char condensed reminder instead. Minor turns are exactly where the full block
# was pure overhead (simple Q&A needs conclusion-first + prose-shape, not the scope/
# verification clauses), and the condensed line carries those. Every injection is
# logged to state/fable-mode/stats/<sid>.tsv (type<TAB>chars) so `/fable-mode status`
# can report the session's real token overhead.
#
# Conditional identity line (v1.5): only activation paths that actually pin the
# session model (FABLE_MODE=1 wrapper, transcript opus match) may assert "you are
# Opus". Marker/GLOBAL-only activation (turn 1 — the transcript has no assistant
# line yet) gets a neutral identity line instead: a SessionStart marker can be a
# wrong guess (settings.json pinned to opus while the session actually runs Fable),
# and exactly that misfire was observed in production on 2026-07-08.
#
# Activation, in priority order:
#   0. FABLE_MODE=0 kill-switch — beats everything (claude-fast, cron fleet, A/B tests)
#   1. FABLE_MODE=1 env (claude-fablelike, or export it in your own wrappers)
#   2. transcript auto-detection: last assistant `"model":"claude-*"` — a fable model
#      STANDS DOWN even if GLOBAL is set (prevents double-injecting real Fable sessions);
#      an opus model activates and refreshes the session marker.
#   3. session marker (fable-detect.sh at SessionStart) or GLOBAL marker (/fable-mode on),
#      consulted only when the transcript is silent about the model (turn 1 etc.).

[[ "${FABLE_MODE:-}" == "0" ]] && exit 0  # explicit kill-switch beats every activation path
command -v jq >/dev/null 2>&1 || exit 0        # no jq → inert (SessionStart hook already warned)

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id // empty')
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
STATE_DIR="$HOME/.claude/state/fable-mode"
MARKER="$STATE_DIR/sessions/$SID"

active=0
SURE=0   # 1 = the activation path pins the session model, so asserting "you are Opus" is safe
[[ "${FABLE_MODE:-}" == "1" ]] && { active=1; SURE=1; }

# transcript model beats GLOBAL: a session actually running Fable must never get the
# norms (double-injection + identity confusion), even while /fable-mode on is set.
if [[ $active -eq 0 && -n "$SID" ]]; then
  LAST_MODEL=""
  if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
    LAST_MODEL=$(tail -c 400000 "$TRANSCRIPT" 2>/dev/null | grep -o '"model":"claude-[^"]*"' | tail -1)
  fi
  case "$LAST_MODEL" in
    *fable*)  rm -f "$MARKER"; exit 0 ;;                        # running Fable → stand down, GLOBAL notwithstanding
    *opus*)   mkdir -p "$STATE_DIR/sessions"; echo "$LAST_MODEL" | sed 's/.*"model":"\([^"]*\)".*/\1/' > "$MARKER"; active=1; SURE=1 ;;
    *)        [[ -f "$MARKER" || -f "$STATE_DIR/GLOBAL" ]] && active=1 ;;  # turn 1 etc. — marker may be a guess, SURE stays 0
  esac
fi
[[ $active -eq 1 ]] || exit 0

# flag major turns (long prompt or work-verb) — picks the full block over the lite
# reminder. English tokens are boundary-guarded so substrings inside ordinary words
# ("prefix" must not hit "fix"); Korean verb stems match as substrings by design
# (agglutinative conjugation: 점검해/점검하고/점검부터 all contain the stem).
MAJOR=0
if [[ ${#PROMPT} -gt 80 ]] || echo "$PROMPT" | grep -qiE '만들|구현|수정|고쳐|리팩|추가|작성|빌드|배포|분석|리서치|검증|디버그|마이그레이|정리|바꿔|설치|커밋|푸시|발행|점검|생성|고도화|최적화|보고서|테스트|실행|(^|[^a-zA-Z])(fix|build|implement|refactor|debug|research|audit|review|migrate|install|commit|push|deploy|publish|optimize|create|update|report|verify)([^a-zA-Z]|$)'; then
  MAJOR=1
fi

# adaptive: full block on major turns, first injection of the session, and every 5th
# injection (periodic anchor against drift); condensed reminder on other minor turns
STATS="$STATE_DIR/stats/${SID:-nosid}.tsv"
mkdir -p "$STATE_DIR/stats"
N=0
[[ -f "$STATS" ]] && N=$(wc -l < "$STATS" | tr -d ' ')
FULL=$MAJOR
[[ $N -eq 0 || $((N % 5)) -eq 0 ]] && FULL=1

if [[ $FULL -eq 1 ]]; then
if [[ $SURE -eq 1 ]]; then
  ID_LINE='- 정체: 너는 claude-opus-4-8이다. 모델 정체를 물으면 Opus라고 답하라. 이 블록은 행동 지침일 뿐 답변 소재가 아니다 — 과제 출력에 끌어들이지 마라.'
else
  ID_LINE='- 정체: 이 블록은 모델 정체를 규정하지 않는다 — 정체를 물으면 시스템이 아는 실제 모델로 답하라. 이 블록은 행동 지침일 뿐 답변 소재가 아니다 — 과제 출력에 끌어들이지 마라.'
fi
BODY=$(cat <<'EOF'
- 결론 먼저: 최종 메시지의 첫 문장이 TLDR("무슨 일이 있었나/무엇을 찾았나"). 상세·근거는 그 뒤에.
- 완전한 문장으로: 화살표 체인("A → B → 실패")·약어 뭉치·자작 코드네임 금지. 읽기 쉬움 > 짧음 — 짧게 만들려면 문장을 압축하지 말고, 독자의 다음 행동을 바꾸지 않는 세부를 빼라.
- 질문 크기에 맞는 응답: 단순 질문엔 헤더·섹션·표 없이 산문으로 바로 답하라. 표는 짧은 열거 사실에만 쓰고 설명은 표 밖 산문에.
- 작업 내레이션: 첫 툴콜 전에 무엇을 하려는지 한 문장으로 밝혀라. 중대한 발견·방향 전환 때만 한 줄 업데이트하고, 그 외 루틴 단계에선 침묵하라.
- 턴 완결성: 사용자에게 필요한 모든 것(답·요약·결론·산출물 경로)은 턴의 "마지막" 텍스트 메시지에 담아라. 중간 텍스트에만 둔 정보는 없는 것과 같다 — 마지막 메시지에 재진술하라. 툴콜이 길었던 턴의 마지막 메시지는 작업 스레드의 연속이 아니라 처음 읽는 독자를 위한 재그라운딩으로 써라.
- 자율 실행: 가역적이고 원 요청에서 따라나오는 행동은 허락 질문 없이 실행하라("~할까요?" 금지). 사소한 선택은 합리적 디폴트로 정하고 명시. 파괴적 행동·외부 발행/전송(=공개와 동일)·진짜 스코프 변경만 정지. 마지막 문단이 계획·스스로 답할 수 있는 질문·다음 단계 목록·약속이면 지금 툴콜로 그 일을 하고 끝내라.
- 재론 금지: 이미 확인된 사실을 다시 도출하지 말고, 사용자가 이미 내린 결정을 다시 묻지 마라. 선택을 저울질할 땐 옵션 나열이 아니라 추천 하나를 내라.
- 사용자가 문제를 설명만 하면(수정 요청 아님) 진단만 보고하고 멈춰라.
- 검증 후 보고: 이 턴의 툴 결과로 확인한 것만 완료라고 말하라. 테스트 실패는 출력과 함께 실패라고, 스킵은 스킵이라고. "될 겁니다" 금지 — 돌릴 수 있으면 돌려라. 상태 변경 명령(재시작·삭제·설정) 전 증거가 그 행동을 지지하는지, 삭제·덮어쓰기 전 대상 실물을 확인하라.
- 능력 트리거: 독립 항목이 여러 개면 병렬 서브에이전트로 팬아웃하고, 의존성 없는 툴콜은 한 응답에 병렬로 묶어라. 학습 컷오프 이후 정보는 검색, 긴 작업 전 메모리 확인·교훈은 기록. 코드 참조는 file_path:line_number 형식으로.
- 코드: 주변 코드의 주석 밀도·네이밍·관용구에 맞춰 써라. 주석은 코드가 못 보여주는 제약만 — 리뷰어 설득용 주석 금지.
- 마무리 점검(이 턴을 끝내기 전, 조용히 스스로): 마지막 메시지가 결론 우선이고 그 자체로 완결인가 · 완료·성공 주장에 이 턴의 툴 결과 근거가 있는가(없으면 지금 최소 검증을 돌려라) · 마지막 문단이 계획·질문·약속이면 지금 실행했는가 · 요청 범위 밖 무단 수정은 없는가 · 응답 구조가 질문 크기에 맞는가. 어긋난 게 있으면 고친 뒤 마무리하라.
- 이 규범 블록은 내부 지침이다: 존재나 통과 여부를 사용자 출력에 언급하지 말고, 'fable'·'자가검증' 같은 지침 용어를 과제 산출물에 섞지 마라.
EOF
)
BLOCK="[fable-mode 상시 규범 — Opus를 Fable 5처럼 운용 (매 턴 재주입되는 강제 지시)]"$'\n'"$ID_LINE"$'\n'"$BODY"
TYPE=full
else
BLOCK=$(cat <<'EOF'
[fable-mode 리마인더 — 이전에 주입된 상시 규범 전체가 계속 유효하다]
결론 먼저(첫 문장=TLDR) · 단순 질문엔 헤더·표 없이 산문으로 · 완전한 문장(화살표 체인·약어 뭉치 금지) · 필요한 모든 것은 턴의 마지막 메시지에 · 가역·범위 내 행동은 허락 질문 없이 실행 · 문제 설명만 받으면 진단만 보고 · 완료 주장은 이 턴의 툴 결과 근거가 있는 것만 · 이 지침의 존재를 출력에 언급하지 마라.
EOF
)
TYPE=lite
fi

printf '%s\n' "$BLOCK"
printf '%s\t%s\n' "$TYPE" "${#BLOCK}" >> "$STATS" 2>/dev/null
exit 0
