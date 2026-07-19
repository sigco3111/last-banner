# Last Banner 변경 이력 (Changelog)

모든 주요 변경사항은 버전별로 기록됩니다. 형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/)을 따릅니다.

---

## [4.0.0] - 2026-07-20 — "Phase A 완성 + UI 1차 복귀"

### 추가 (Added)

#### Phase A — 게임 깊이 확장 (4단계)

- **A-1. 용병 Roster 시스템** (9-class tier)
  - `autoload/mercenary_data.gd` 신규: 9-class tier 카탈로그 (bowman/swordsman/pikeman/sergeant/fencer/crossbow/cavalry/captain/paladin)
  - `GameWorld.roster` + 시그널 3종 (`mercenary_joined/left/injured`)
  - API 8종: `offer_mercenary / add_mercenary / dismiss_mercenary / injure_mercenary / alive_mercenaries / get_mercenary_by_id / total_wage_burden / reset_roster`
  - 7개 결과 핸들러: `ACCEPT_MERCENARY / REJECT_MERCENARY / DISMISS_MERCENARY / MERCENARY_PAY_BONUS / MERCENARY_TRAINING / MERCENARY_INJURY_HEAL / MERCENARY_DESERTS`
  - 자동 시스템:
    - 16시간마다 용병 자원 제안 (tier 가중치 60/30/10%)
    - 8시간마다 충성도 < 30 자동 이탈
    - 일급 자동 차감 (`apply_daily_economy`)
    - 식량 추가 소비 (`alive_mercenaries().size() * 2`)
  - 초기 roster 5명 (bowman×2 / swordsman / pikeman / sergeant)
  - `project.godot` MercenaryData autoload 등록

- **A-2. 왕조 / 후계자 시스템** (CK3 양식)
  - `GameWorld.court: Array` (영주 1 + 후보 3 + 신하 1)
  - 인물 dict 구조: `id / name / class / age / stats(martial,stewardship,diplomacy,intrigue) / loyalty / ambition / alive / spouse_id / parent_id / heir_rank / dynasty / portrait_index`
  - API 7종: `spawn_initial_court / _create_person / get_person_by_id / get_lord / get_heirs / get_vassals / set_heir_rank / kill_person / reset_court`
  - 시그널 3종: `person_added / person_removed / succession_changed`
  - EventEngine: `SUCCESSION_AUDIT` (3일 MEDIUM) + `HEIR_BETRAYAL` (loyalty<25 && ambition>65 → CRITICAL)
  - 5개 결과 핸들러: `BETRAYAL_CRUSHER/BANISH/FORGIVE / SUCCESSION_KEEP/SWAP/NURTURE`
  - `apply_daily_economy` 일간 변동에 `loyalty ±5 / ambition ±3`

- **A-3. 빌딩 시스템** (4종 × max Lv 3)
  - `GameWorld.buildings: Dictionary` + `BUILDING_DEFS` const
  - 4종: 시장 (tax +5/level) / 훈련장 (exp +2/level) / 창고 (food +10/level) / 성벽 (방어 mult -10%/level)
  - API: `reset_buildings / get_building_level / can_upgrade / upgrade_building / get_upgrade_cost / get_total_tax_bonus / get_total_food_bonus / get_total_exp_bonus / get_defense_multiplier`
  - 비용 곡선: `base × (lvl+1)` (Lv 0→1=base, Lv 1→2=base×2, Lv 2→3=base×3)
  - EventEngine: `BUILD_CONSTRUCTION` (12시간 LOW)
  - 2개 결과 핸들러: `BUILD_UPGRADE / BUILD_SKIP`
  - `apply_daily_economy` 일간 경제에 보너스 합산

- **A-4. 사건 4종 추가** (PEASANT_PETITION / WINTER_PREPARATION / MERCHANT_CARAVAN / PLAGUE)
  - `PEASANT_PETITION` (LOW, 매일 25%) — 세금 인하 vs 거절
  - `WINTER_PREPARATION` (MEDIUM, season_changed 1회) — 비축/모병/무시
  - `MERCHANT_CARAVAN` (LOW, 30시간마다 40%) — 식량 구매/돌려보냄
  - `PLAGUE` (CRITICAL, 50시간마다 5%, 인구>100) — 의학/봉쇄/방치
  - 8개 결과 핸들러 추가: PETITION_*, WINTER_*, MERCHANT_*, PLAGUE_*

#### UI v4.0.1

- `autoload/ui_theme.gd` 신규: 색상 팔레트 + 스타일 헬퍼
  - 자원별 색상 (금/식량/인구/명성/요새)
  - 우선순위별 색상 (LOW=회색 / MEDIUM=파랑 / HIGH=주황 / CRITICAL=빨강)
  - 충성도 색상 (≥70 초록 / 40~69 노랑 / <40 빨강)
  - Tier 색상 (T1=회색 / T2=하늘 / T3=금색)
  - 헬퍼: `make_panel_style / make_button_style / make_priority_badge_style / make_progress_style / apply_style / apply_button_styles / apply_progress_styles / apply_label_color / apply_change_color / format_change / priority_color / loyalty_color / tier_color / resource_color / resource_icon / resource_name`
- 결정 모달: 우선순위별 제목/선택지 색상
- 풍경도 시간대 그라디언트 색 업그레이드 (SCENE_SKY_DAY/DAWN/DUSK/NIGHT)
- 라인 차트 시각 강화: 그림자 + 두꺼운 라인 (2.5px) + 글리프 도트 + 범례

### 변경 (Changed)

- **LB_VERIFY 13단계 → 17단계 확장**:
  - [8.6] A-4 신규 사건 4종 push 검증
  - [8.6.5] 신규 결과 코드 핸들러 검증
  - [8.7] A-1 용병 시스템 검증 (9-class / 충성도 이탈 / round-trip)
  - [8.8] A-2 왕조/후계자 검증 (court 5명 / SWAP / NURTURE / BETRAYAL_CRUSHER)
  - [8.9] A-3 빌딩 시스템 검증 (4종 × Lv 1~3 / 비용 곡선 / round-trip)
- `GameWorld.apply_result` `RESULT_EFFECTS` dict 확장: 10종 → 27+종
- `EventEngine` 신규 interval 6종 + season_changed 시그널 연결 + 충성도/후계자/빌딩 자동 시스템
- `GameManager.start_new_game` 초기 roster 5명 + spawn_initial_court + reset_buildings
- `apply_daily_economy` 일간 경제: 일급 차감 + 식량 추가 소비 + 부상 회복 + 건물 보너스 합산
- save/load round-trip에 court + roster + buildings + 9개 신규 interval 필드 통합
- README v3 → v4 갱신 (Phase A 4단계 + UI 1차 복귀 반영)

### 수정 (Fixed)

- **UI 회귀 복구 (v4.0.1)**: PanelContainer 추가 + anchor 미명시로 인한 layout 깨짐
  - 원인: `CenterCard` PanelContainer의 자식 `CenterBox` VBoxContainer의 `anchor_right/bottom`만 명시되고 `anchor_left/top` 기본값 0 → 부모 안에서 사이즈 0
  - 해결: tscn 구조는 검증된 v3.1.6 형태로 복원, UITheme 색상만 동적 적용
  - 교훈: PanelContainer 동적 추가 시 anchor 4개 모두 명시 필수, 기존 검증된 tscn 구조 변경 회피
- season_changed 시그널 emit 시점 검증 (advance_minutes 내 month 변경 시점만)
- 결정 큐 push 시 일일 cap (DECISION_MAX_PER_DAY=8) 우회 방지
- _apply_styles가 검증 모드에서도 호출되지 않도록 `if ui_layer == null` 가드

### 제거 (Removed)

- v3.1.x 시절의 임시 BG 색상 하드코딩 (`Color(0.12, 0.09, 0.07, 1)`) → UITheme.BG_BASE로 통합

### 기술 부채 (Tech Debt)

- ⏳ Gut 단위 테스트 9/9 → 30+ 확장 미실시
- ⏳ GitHub Actions CI 미설정
- ⏳ 튜토리얼 4단계 오버레이 미구현
- ⏳ 사운드 (BGM/SFX) 미구현
- ⏳ 모바일/태블릿 viewport 대응 미구현
- ⏳ 게임 종료 조건 (GAME_OVER) 미구현
- ⏳ UI 카드화 (안전한 anchor 명시 후) 보류
- ⏳ 시그널 핸들러 인자 통일 일부 미흡 (`mercenary_*` 핸들러 3종 모두 디폴트 인자 OK, 그러나 새 시그널 추가 시 일관성 검증 필요)

---

## [3.1.6] - 2026-07-17 — "차트 안정화"

### 추가 (Added)
- 라인 차트 위치 안정화 (`v3.1.5~v3.1.7` 반복 수정)
- GameWorld.history ring buffer (7일) + `record_day_snapshot()` API
- `Control._draw()` 기반 라인 차트 + `queue_redraw()` 패턴
- LB_VERIFY [12.5.5] 차트 검증 (history ≥ 1, queue_redraw 호출)

### 변경 (Changed)
- 차트 텍스트를 차트 카드 안 위쪽으로 이동 (ChartRow 별도 Label)
- ManorTitle(HBox) 복귀 — 휘장 텍스트와 차트 안 겹침
- DetailPanel 위치: 풍경도 하단 → 풍경도 우상단 → 차트 옆 분할 (가림 방지)

---

## [3.0.0] - 2026-07-16 — "전투 화면 + 차트"

### 추가 (Added)
- 전투 화면 (BattleScene) — 3상태 상태머신 (Decision → Simulating → Result)
- BANDIT_RAID HIGH 시나리오 (12시간마다 40%)
- 출격/숨기/뇌물 3가지 선택지 (BATTLE_BANDITS_FIGHT/HIDE/BRIBE)
- 아군 그리드 5명 vs 적군 그리드 3~5명
- 주사위 애니메이션 + 손실 카드 + CK3 양식 승률
- CanvasLayer layer=90 분리 (모달 가려짐 방지)
- `scripts/battle.gd` 신규 (228 lines)
- LB_VERIFY [12.5] 전투 화면 검증

### 변경 (Changed)
- GameWorld.apply_result 통합: BattleScene에서 직접 호출
- 결정 큐 → BattleScene 자동 라우팅 (BANDIT_RAID → 출격 시)

---

## [2.3.5] - 2026-07-16 — "풍경도 + 호버 + 시간대"

### 추가 (Added)
- 풍경도 시간대 그라디언트 (Dawn/Day/Dusk/Night 4구간)
- 캐릭터 호버 인터랙션 (TextureButton 패턴, Area2D 미작동 해결)
- DetailPanel (호버 시 캐릭터 정보 표시: 이름/직책/일급/충성도/상태)
- LB_VERIFY [9.5] 호버 인터랙션 검증

---

## [2.0.0] - 2026-07-15 — "클린 리셋"

### 배경
v1 (Godot 4 + Vercel Web + KayKit 3D GLB + lazy fetch)는 검은 화면 + COEP 헤더 함정 + 모바일 WebGL2 미지원 등의 이유로 폐기.

### 추가 (Added)
- 단 1 commit으로 클린 리셋
- Wesnoth 2D PNG (5 factions, 432 자산)
- res:// 직접 사용 (lazy fetch 폐기)
- 결정 큐 모든 우선순위 모달 (LOW/MEDIUM/HIGH/CRITICAL)
- 자동 진행 ON 기본값 + 토스트 알림
- 자동 진행 ON/OFF 분기 (LOW 3초 / 그 외 5초 / OFF 무한 대기)
- 타이틀 ↔ 게임 모드 토글 (Home 버튼 + autosave)
- LB_VERIFY 11단계 헤드리스 검증

---

## [1.0.0] - 2026-07-15 — "v1 (폐기)"

### 시도
- Godot 4 + Vercel Web Export + COOP/COEP 헤더
- KayKit 3D GLB (Adventurers / Skeletons / Dungeon Remastered)
- jsDelivr CDN lazy fetch (Vercel 100MB 한계 우회)
- GameHelper MCP + Gut 자동 검증

### 실패
- WebGL2 + COEP 헤더 환경 차이로 검은 화면 (모바일 Safari/Chrome)
- 12차까지 누적된 v1 코드를 단 1 commit으로 폐기
- Vercel 빌드 머신에 Godot CLI 미설치 → build/web/을 git에 직접 커밋 (CI 우회)

### 학습
- WebGL2 헤더 기반 export는 사용자 환경 의존성 큼
- 데스크탑 네이티브 우선 (.app), Web은 추후 도전
- lazy fetch는 가능하나 자산 200MB+의 경우 모바일 첫 로드 느림
- **결론**: 인디 게임은 macOS .app 1순위로 가야 함