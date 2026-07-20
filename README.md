# Last Banner

> **변방 영지 운영 로그라이크 전략** — Wesnoth 2D 픽토그램 양식 · CK3 정치 미학
> **Godot 4.7.1 + macOS 네이티브 전용** · 자동 진행 + 결정 큐 · 432 Wesnoth 자산

[![Godot](https://img.shields.io/badge/Engine-Godot%204.7.1-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-000?logo=apple&logoColor=white)](https://www.apple.com/macos)
[![Version](https://img.shields.io/badge/Version-v4.0.0-blue)](./CHANGELOG.md)
[![License](https://img.shields.io/badge/code-MIT-green)](./LICENSE)
[![Assets](https://img.shields.io/badge/assets-CC--BY--4.0%20%2F%20OFL-blue)](./docs/CREDITS.md)

---

## 🎮 게임 컨셉

**Last Banner**는 **Wesnoth 2D 픽토그램 + CK3/EU4 양식 정치 미학**의 변방 영지 운영 로그라이크 전략 게임입니다.

- **시각 톤**: Wesnoth 2D 픽토그램 양식 · 저판타지 political 미학 (마법은 subtle, fireball X)
- **메카닉**: 자원 변동 → 사건 생성 → 결정 큐 push → 모달 표시 → 자원 변동
- **자동 진행**:
  - **속도**: 1초 real time = 60분 game time (1시간) → **1일 = 60초**
  - **ON** (위임): LOW 3초 / MEDIUM·HIGH 5초 후 default 결정으로 자동 resolve
  - **OFF** (대기 모드): 모달 뜨면 사용자가 직접 결정할 때까지 무한 대기
- **재진입**: `user://save_*.json` 영속화 — Mac 종료 후 다시 열어도 같은 세션

---

## 🆕 v4.1.0-alpha 신규 기능 (진행 중)

### Phase B — 인디 완성

- **B-1. 튜토리얼 4단계 오버레이** — 새 게임 첫 진입 시 자동 표시, `GameManager.tutorial_seen` 1회 한정, "튜토리얼 다시보기" 버튼
  - 🤖 자동 진행 / 📜 결정 큐 11종 / 💰 자원 변동 / ⚔️ 4가지 시스템
- **B-2. 사운드 (BGM 4종 + SFX 6종)** — Wesnoth music (9.7 MB) + sparklinlabs RPG sfx (70 KB CC0)
  - 헤드리스 자동 가드 (`DisplayServer.get_name() == "headless"`) + 자산 가드 + 페이드 트윈 + SFX 풀링 8개
  - main.gd 9개 마커 통합 (모달 열기/닫기/결정/배틀/게임오버)
- **B-3. 게임 종료 조건 + 엔딩 화면** — 3종 패배
  - 💀 인구 멸망 (population ≤ 0 즉시)
  - 🌾 대기아 (food ≤ 0 연속 30일, 회복 시 리셋)
  - 👑 왕조 멸절 (court alive_count = 0 즉시)
  - CanvasLayer layer=120 게임 오버 화면 + 8종 통계 + 메인 메뉴 복귀
- **B-4. 모바일/태블릿 viewport 대응** — `MOBILE_VIEWPORT_THRESHOLD = 800`
  - 데스크탑 1280×720: 모달 ±360×±180
  - 모바일 414×896: 모달 viewport 90%×70% (offset 373×627)
  - 태블릿 768×1024: 모달 viewport 90%×70% (offset 691×717)
  - TopResourceBar 자식 Label에 `size_flags_horizontal=3` (FILL) + `clip_text=true` (overflow 방지)

### v4.0.0 Phase A

- **A-1. 용병 Roster** (9-class tier) — bowman / swordsman / pikeman / sergeant / fencer / crossbow / cavalry / captain / paladin
  - 시그널 3종 (`mercenary_joined/left/injured`)
  - 16시간마다 용병 자원 제안 (tier 가중치 60/30/10)
  - 충성도 < 30 자동 이탈 / 일급 자동 차감 / 식량 추가 소비
- **A-2. 왕조 / 후계자 (CK3 양식)** — 영주 1 + 후보 3 + 신하 1
  - 4종 스탯 (martial/stewardship/diplomacy/intrigue, 4~15)
  - 3일마다 후계자 감사 (loyalty ±5 / ambition ±3)
  - loyalty<25 && ambition>65 → CRITICAL 배신 사건
  - BETRAYAL_CRUSHER/BANISH/FORGIVE + SUCCESSION_KEEP/SWAP/NURTURE
- **A-3. 빌딩 시스템** — 4종 × max Lv 3
  - 시장 (tax +5/level) / 훈련장 (exp +2/level) / 창고 (food +10/level) / 성벽 (방어 mult -10%/level)
  - 12시간마다 업그레이드 제안 (LOW)
  - 비용 = base × (lvl+1) 곡선
- **A-4. 사건 4종 추가** — PEASANT_PETITION (LOW) / WINTER_PREPARATION (MEDIUM) / MERCHANT_CARAVAN (LOW) / PLAGUE (CRITICAL)

### UI v4.0.1
- **UITheme autoload** — 색상 팔레트 / 우선순위·자원·Tier·충성도 색상 매핑
- **결정 모달** — 우선순위별 제목 색상 + 선택지 버튼 톤 (LOW=회색 / MEDIUM=파랑 / HIGH=주황 / CRITICAL=빨강)
- **풍경도 시간대 그라디언트** — Dawn / Day / Dusk / Night 4구간 색 보간
- **라인 차트** — 7일 ring buffer + 그림자 + 두꺼운 라인 + 글리프 도트 + 범례

---

## 📦 스택

| 축 | 결정 | 이유 |
|---|---|---|
| 엔진 | Godot 4.7.1 stable | Wesnoth 2D 임포트 OK, GDScript 단순 |
| 빌드 | **macOS .app 전용** | v1 (Web export) = 텍스트만 보이는 회귀 → 로컬 우선 |
| 시각 | **2D 전용** | Wesnoth PNG 픽토그램. 3D GLB 폐기 |
| 자산 | Wesnoth 2D PNG (5 factions + portraits) | Wesnoth CC-BY-4.0 |
| 폰트 | NanumGothic.ttf (TTF) | SIL OFL 1.1, 한글 정상 |
| 영속화 | `user://save_*.json` | macOS = `~/Library/Application Support/` |
| 한국어 폰트 autoload | `korean_font.gd` | preload + theme 자동 적용 |

총 **432개 자산** (393 idle PNG + 39 portraits).

자세한 라이선스 표기: [`docs/CREDITS.md`](docs/CREDITS.md)
변경 이력: [`CHANGELOG.md`](CHANGELOG.md)

---

## 🚀 빠른 시작

### 게임 실행 (개발 모드)
```bash
cd ~/work/last-banner
godot --path .                    # 즉시 실행 (개발 모드)
```

### 정식 빌드 (.app)
```bash
cd ~/work/last-banner
godot --headless --export-release macOS    # → build/macos/Last Banner.app
open "build/macos/Last Banner.app"          # 더블클릭과 동일
```

빌드 산출물: `build/macos/Last Banner.app/` (≈168 MB, 432 PNG 포함)

### 헤드리스 검증 (LB_VERIFY=1)
```bash
cd ~/work/last-banner
LB_VERIFY=1 godot --headless    # 13+8단계 자동 검증 (~5~15초)
```

**검증 단계 (21종)**:
1. 새 게임 초기 상태 (gold=200 food=100 pop=50)
2. 1일 시뮬 (1440분)
3. 자원 변동
4. 6일 추가 → 결정 큐 자동 push
5. 자동 진행 ✓
6. 7일 후 자원 누적
7. save/load round-trip
8. 결과 적용 (VISITOR_WELCOME +30골드)
9. ManorDashboard 화면 검증 (sprite 5 + roster avatar 5)
10. 모달 자동 OFF 검증
11. 모달 자동 ON 검증
12. 전투 화면 검증
13. 차트 검증 (history 7일 + ChartCanvas + queue_redraw)
14. 타이틀 라운드트립
15. A-4 신규 사건 4종 push (PEASANT/MERCHANT/WINTER/PLAGUE)
16. A-1 용병 시스템 (9-class / 충성도 이탈 / round-trip)
17. A-2 왕조/후계자 (court 5명 / SWAP / NURTURE / BETRAYAL_CRUSHER)
18. A-3 빌딩 시스템 (4종 × Lv 1~3 / 비용 곡선 / round-trip)
19. **B-1 튜토리얼** 8단계 (시그널 / seen 플래그 / 단계 진행 / round-trip)
20. **B-2 사운드** 6단계 (BGM/SFX 자산 / 헤드리스 가드 / 9개 통합 마커)
21. **B-3 게임 오버** 11단계 (3종 패배 / 식량 회복 리셋 / round-trip)
22. **B-4 모바일 viewport** 9단계 (데스크탑/모바일/태블릿 offset 시뮬레이션)

---

## 🖼 화면 흐름

### 1. 타이틀 화면
```
🏰 LAST BANNER
변방 영지 운영 로그라이크

[▶ 새로 시작]       (항상 활성, 금톤)
[⏵ 이어하기]        (저장 파일 있을 때만 활성, 식량톤)
[✕ 게임 종료]        (위험톤)
```

### 2. 게임 모드
```
┌─────────────────────────────────────────────────────────────────────┐
│ TopResourceBar: 🕯 Day 25  20:24  |  ⏯ ON  💰 N  🌾 N  👥 N  ⭐ N   │ ← 자원별 색상
├─────────────────────────────────────────────────────────────────────┤
│ Manor Dashboard                          ┌────────────────────┐    │
│  ┌────────────────────────────┐         │ ⚔️ 용병 (5명)         │    │
│  │ 토르바르의 영지 — 황야의 변방 │         │ [🖼] 토르바르 · 영주   │    │
│  │ 풀밭 + 흙길 + 캐릭터 5명     │         │ [🖼] 에드윈 · 기사    │    │
│  │ (knight/swordsman/spearman/ │         │ 💰 12골드/일  ★ 80/100│    │
│  │  bowman/bandit PNG)        │         └────────────────────┘    │
│  │ 📈 자원 추이 (7일) 차트        │                                    │
│  └────────────────────────────┘                                    │
├─────────────────────────────────────────────────────────────────────┤
│ [⏯ 자동 진행]  [▶▶ +1일]  [💾 저장]  [📂 불러오기]  [🏠 타이틀로]      │
└─────────────────────────────────────────────────────────────────────┘
```

### 결정 모달 (별도 ModalLayer, layer=100)
```
┌────────────────────────────────────────┐
│ [우선순위] 방문객 도착                  │ ← 우선순위별 색상
│ "귀족이 영지를 방문했습니다..."          │
│ [환영 (+50골드)]  [거절 (명성 -2)]      │ ← 우선순위별 톤
└────────────────────────────────────────┘
```

---

## 🏗 아키텍처 (v4.0.0)

```
┌─────────────────────────────────────────────────┐
│  10개 autoload                                  │
│  GameManager · TimeManager · DecisionQueue       │
│  SaveManager · GameWorld · EventEngine           │
│  AssetRegistry · KoreanFont                      │
│  MercenaryData (NEW v4.0) · UITheme (NEW v4.0)  │
└─────────────────────────────────────────────────┘
            ↓
   ┌────────┴───────────────┐
   │  Scenes                │
   │  main.tscn             │
   │   ├─ TopResourceBar    │ ← 자원별 색상 라벨
   │   ├─ ManorLayer        │ (영지 풍경도 + Roster)
   │   ├─ BottomButtonRow   │ ← 4상태 스타일 버튼
   │   ├─ ModalLayer (z=100)| (결정 모달 + DimBG)
   │   ├─ TitleLayer        │ (시작 메뉴)
   │   └─ BattleLayer (z=90)| (전투 화면)
```

### 시그널 연결
```
TimeManager.tick_advanced ─┬─► SaveManager._on_tick  (60분마다 자동 저장)
                           ├─► EventEngine._on_tick  (사건 생성)
                           └─► UITheme 자동 적용
TimeManager.day_changed   ────► EventEngine._on_day  (일간 자원 변동 + history)
TimeManager.season_changed ──► EventEngine._on_season (겨울 진입 시 WINTER_PREPARATION)
GameWorld.mercenary_*     ────► Roster UI 자동 갱신
GameWorld.person_*        ────► Succession UI 자동 갱신
DecisionQueue.push(CRITICAL) ► GameManager.pause_for_decision()
```

### 게임 내 객체 통계 (v4.0.0)
- **자원 5종**: gold / food / population / prosperity / fortification_level
- **용병**: 초기 5명 (bowman×2 / swordsman / pikeman / sergeant) + tier 1~3 합쳐 9-class
- **인물 (왕조)**: 초기 5명 (영주 1 + 후보 3 + 신하 1) — 4종 스탯 + loyalty/ambition
- **건물 4종**: 시장 / 훈련장 / 창고 / 성벽 (각 max Lv 3)
- **결정 큐 사건 11종**: VISITOR / BANDIT_RAID / DIPLOMACY / FOOD_SHORTAGE / PEASANT_PETITION / WINTER_PREPARATION / MERCHANT_CARAVAN / PLAGUE / MERCENARY_OFFER / SUCCESSION_AUDIT / HEIR_BETRAYAL / BUILD_CONSTRUCTION
- **결과 핸들러 27+종**: GameWorld.RESULT_EFFECTS 통합 dict

### 4. 게임 오버 화면 (v4.1 신규)

```
┌────────────────────────────────────────────┐
│ 💀 인구 멸망 — 인구의 멸망                    │ ← 패배 아이콘 + 이유
│                                              │
│ "전쟁·역병·기근이 겹치며 백성이               │
│  뿔뿔이 흘어졌습니다. ..."                   │ ← REASON_DESCRIPTIONS
│                                              │
│ 생존 일수: 7일                                 │
│ 📊 종료 통계                                  │
│   💰 금: 990                                  │
│   🌾 식량: 50                                 │
│   👥 인구: 0                                  │
│   ⭐ 명성: 10                                 │
│   🏰 요새 Lv 1                               │
│   ⚔️ 생존 용병: 6명                           │
│   👑 생존 왕조 인물: 5명                      │
│                                              │
│ [🏠 메인 메뉴로]                              │
└────────────────────────────────────────────┘
+ DimBG (검은 반투명 0.88 alpha)
```

**3종 패배 조건**:
- 💀 **인구 멸망** — population ≤ 0 즉시
- 🌾 **대기아** — food ≤ 0 연속 30일 (회복 시 카운터 리셋)
- 👑 **왕조 멸절** — court alive_count = 0 즉시

---

## ⌨️ 단축키

| 키 | 동작 |
|---|---|
| **P** | 자동 진행 ON/OFF 토글 |
| **D** | (예정) 영지 대시보드 |
| **R** | (예정) 용병 명단 |

UI 버튼: P 토글 / +1일 진행 / 저장 / 불러오기 / 타이틀로

---

## 🛠 개발 워크플로

### 자산 갱신 (5 factions base idle PNG)
```bash
bash tools/setup-assets.sh    # idempotent — 풀 → 심볼릭 링크
```

새 faction 추가 시 `setup-assets.sh`에 `link_unit_faction "faction"` 한 줄 추가.

### LB_VERIFY
`scripts/main.gd`의 `_run_verify()`가 17단계 자동 검증. 변경 시 반드시 통과 확인:
```bash
LB_VERIFY=1 godot --headless    # 5~15초
```

### 알려진 함정
| 함정 | 해결 |
|---|---|
| `_ready` 함수와 `_ready` 멤버 충돌 → parse 에러 | `_manifest_ready` 같이 함수명 회피 |
| autoload 멤버 이름 `day` → local 변수 명시 접근 `TimeManager.day` | 멤버 shadowing 회피 |
| `assets/.gdignore`가 폰트까지 차단 | v2는 res:// 직접 사용 — setup-assets.sh에서 .gdignore 생성 안 함 |
| Godot 4.7은 TTF만 직접 로더 (OTF/TTC 미지원) | NanumGothic.ttf 사용 |
| ManorDashboard가 모달을 가림 | 모달을 별도 `ModalLayer` (layer=100) CanvasLayer로 분리 |
| `await get_tree().create_timer().timeout` 헤드리스 hang | LB_VERIFY는 동기 처리 |
| `@onready $SceneInstance` 인스턴스화 순서 | main.gd처럼 `var + call_deferred` 동적 검색 |
| PanelContainer 추가 시 anchor 미명시 → layout 깨짐 | tscn은 검증된 형태로 유지, 색상만 동적 적용 |

상세 패턴:
- `godot-game-bootstrap` 스킬 (Godot 부트스트랩)
- `incremental-game-design-last-banner-event-engine` 스킬 (자동 진행 + 결정 큐 실전 패턴)

---

## 🔄 v1 → v2 → v3 → v4 변경 이력 (요약)

| 버전 | 변경 |
|---|---|
| v1 (폐기) | Godot 4 + Vercel Web export + KayKit 3D GLB + lazy fetch → 검은 화면 |
| v2 | 클린 리셋 (단 1 commit) — Wesnoth 2D PNG (5 factions, 432 자산) + 결정 큐 모든 우선순위 모달 |
| v3.0 | 전투 화면 (BattleScene 3상태 + 그리드 + 손실 카드) |
| v3.1 | 라인 차트 + 호버 인터랙션 + 시간대 그라디언트 + 타이틀 화면 |
| v4.0 | **Phase A 4단계** (사건 4종 + 용병 9-class + 왕조 court + 빌딩 4종) + UI 1차 복귀 |
| v4.1 | **Phase B 4단계** (튜토리얼 + 사운드 + 게임 종료 + 모바일 viewport) — 진행 중 |

자세한 마이그레이션 로그는 [`CHANGELOG.md`](./CHANGELOG.md) 참조.

---

## 📜 라이선스

- **코드**: MIT ([LICENSE](LICENSE))
- **Wesnoth 자산**: CC-BY-4.0 ([docs/CREDITS.md](docs/CREDITS.md))
- **NanumGothic 폰트**: SIL OFL 1.1

---

## 🗺 로드맵 (Roadmap)

> **Last Banner**는 **v4.x 인디 로그라이크 완성 → v5.0 스토리 모드 + 메이저 리팩토링** 방향으로 진행됩니다.
> 각 마일스톤은 LB_VERIFY 회귀 + macOS .app 빌드 + GitHub Pages + git tag로 마감됩니다.

### 📍 현재 위치 (2026-07-20)

- ✅ **v4.0.0 완료** — Phase A 4단계 (사건/용병/왕조/빌딩) + UI 1차 복귀
- 🔄 **v4.1.0 진행 중** — B-1 튜토리얼 완료 / B-2 사운드 부분 / B-3 게임 종료 / B-4 모바일 viewport 미완
- 📦 **17개 LB_VERIFY 단계** 모두 통과, **macOS .app 170 MB**

### 🛤 마일스톤

```
v4.0.0 ✅ ─── v4.1.0 🔄 ─── v4.2.0 ─── v5.0.0
   Phase A       Phase B       Phase D       Phase E
   게임 깊이     인디 완성     스토리 +      메이저
                 + 사운드 +    씬 다양화     리팩토링
                 UX 마감
```

---

### 🔄 v4.1.0 — "인디 완성" (진행 중, 2026 Q3)

**목표**: 인디 게임 출시 가능 상태. BGM/SFX + 게임 종료 + 모바일 + UI 안전 카드화 + README/CHANGELOG 보강.

| # | 작업 | 상태 | 의존 |
|---|---|---|---|
| B-1 | 튜토리얼 4단계 오버레이 | ✅ 완료 | — |
| B-2 | 사운드 (BGM 4종 + SFX 6종 + 헤드리스 가드) | 🔄 부분 (자산 + AudioManager OK, main.gd 통합 미완) | 자산 ✓ |
| B-3 | 게임 종료 조건 (인구 0 / 식량 0 30일 / 후계자 전원 사망) + 엔딩 화면 | ⏳ | GameManager.GAME_OVER 상태 활용 |
| B-4 | 모바일/태블릿 viewport (anchor 비율 + 세로 레이아웃) | ⏳ | B-1 (튜토리얼 오버레이 모바일 호환) |
| UI-1 | UI 안전 카드화 (anchor 4개 명시 + 헤드리스 시각 검증) | ⏳ | v4.0.1 회귀 교훈 반영 |
| Infra | GitHub Actions CI (macOS + LB_VERIFY 자동 실행) | ⏳ | LB_VERIFY 안정 |
| Infra | Gut 단위 테스트 9 → 30+ 확장 | ⏳ | LB_VERIFY 보강 |
| Doc | README.md / CHANGELOG.md v4.1.0 갱신 | ⏳ | 모든 B 작업 완료 후 |
| Release | macOS .app 리빌드 + git tag v4.1.0 + GitHub Pages | ⏳ | Doc 완료 후 |

**v4.1.0 종료 기준 (DoD)**:
- LB_VERIFY [8.10] ~ [8.13] 모두 통과 (≥ 21단계)
- macOS .app 빌드 + 실행 + 시각 확인 (희정님 Mac 데스크탑)
- README/CHANGELOG v4.1.0
- git tag v4.1.0 + GitHub Release

---

### 📝 v4.2.0 — "씬 다양화 + 콘텐츠 확장" (2026 Q4)

**목표**: 같은 시스템 위에 **씬/시나리오/맵 다양화** + **콘텐츠 확장** (이벤트 풀, 인격 시스템, 기술 트리).

| # | 작업 | 설명 |
|---|---|---|
| D-1 | **맵 시스템** | 풍경도 1종 → **3~5종 맵** (변방/산림/해안/도시/눈덮힌) + 맵별 고유 이벤트 |
| D-2 | **인격 시스템** | 인물별 고유 행동 패턴 (용감/신중/야심/충성) + 충성도 영향 로직 강화 |
| D-3 | **기술 트리** | 영주/후계자가 배울 수 있는 12~20개 정책 (세수 증가 / 군사 강화 / 외교 / 마법약) |
| D-4 | **이벤트 풀 확장** | 현재 12종 → **30+종** 사건 (계절/페스트/왕국/종교/전쟁) |
| D-5 | **도주 / 항복 메커니즘** | 패배 시 다른 영지로 망명 / 게임 오버 vs 굴복 |
| D-6 | **통계 화면** | 누적 플레이 통계 (총 결정 / 평균 충성도 / 최대 명성 / 사망률) |
| D-7 | **UI 폴리시** | 안전 카드화 (UI-1) + 애니메이션 (호버/클릭 트윈) + 사운드 설정 화면 |
| D-8 | **LB_VERIFY 확장** | [8.14] 시나리오 자동 생성, [8.15] 맵/이벤트 검증, [8.16] 통계 정확도 |

**v4.2.0 종료 기준**:
- 맵 5종 / 사건 30+ / 기술 12+ / 인격 4종
- LB_VERIFY ≥ 25단계
- macOS .app 250 MB 이내 (맵/오디오 확장 감당)

---

### 🏰 v5.0.0 — "스토리 모드 + 메이저 리팩토링" (2027 Q1+)

**목표**: **스토리 기반 챕터 시스템** + **엔진 리팩토링** (모듈화, 자동화, 멀티플랫폼). **Last Banner 1.0 정식 출시**.

| # | 작업 | 설명 |
|---|---|---|
| E-1 | **스토리 모드** | 5~7개 챕터 캠페인 (예: "토르바르의 영지" / "왕조의 분열" / "변방의 봉인") |
| E-2 | **분기 내러티브** | 챕터 내 선택지 → 다음 챕터 영향 (CK3 way) |
| E-3 | **엔딩 시퀀스** | 챕터 종료 시 나래이션 + 화면 + 사운드 |
| E-4 | **엔진 리팩토링** | Godot 5.x 마이그레이션 (출시 시 안정화 시점) + 멀티플랫폼 (Windows/Linux) |
| E-5 | **모드 시스템** | "평화 모드" (결정 큐 없음) / "하드코어" (perma-death) / "역사" (실제 영지 이름) |
| E-6 | **클라우드 세이브** | (선택) GitHub Gist 또는 자체 백엔드 — 단일 사용자 크로스 디바이스 |
| E-7 | **번역** | 한국어 + 영어 (NanumGothic 외 폰트 자산 추가) |
| E-8 | **공식 빌드 인프라** | GitHub Actions + macOS/Windows/Linux 동시 빌드 + 코드 서명 + 공증 (선택) |

**v5.0.0 종료 기준**:
- 5+ 챕터 캠페인 (분기 포함)
- 3+ 모드 (기본/평화/하드코어)
- Godot 5.x 안정 빌드
- 3개 플랫폼 (macOS/Windows/Linux) .app/.exe
- LB_VERIFY ≥ 30단계
- README/CHANGELOG 다국어 (한/영)

---

### 🛑 의도적으로 제외 (로드맵에 없음)

- ❌ **멀티플레이어 / 온라인**: 인프라 부담 대비 인디 1인칭 게임 가치 낮음
- ❌ **P2P / 멀티 호스트**: 자동 진행 게임은 비동기 협업 어색
- ❌ **리더보드 / 클라우드 시점**: 인디 깊이 < 백엔드 운영 부담
- ❌ **Discord 통합**: 외부 의존 + 자동화 부담
- ❌ **DLC / 유료 콘텐츠**: 1차 무료 오픈소스
- ❌ **모바일 네이티브 빌드 (iOS/Android)**: Godot 4.7 호환성 + 스토어 수수료 부담

---

### 📅 타임라인 (추정)

```
2026 Q3 ██████████████ v4.1.0 (인디 완성)              [~2~4주]
2026 Q4 ███████████████████ v4.2.0 (씬 다양화)        [~6~10주]
2027 Q1+ ████████████████████████ v5.0.0 (스토리 + 리팩토링) [장기]
```

> ⚠️ **타임라인은 추정치**. LB_VERIFY 17→21→25→30 단계를 통한 점진적 안정화가 실제 진도 측정 기준. 기술 부채 / LB_VERIFY 회귀 / 시각 검증 실패 시 일정에 영향.

---

### 🤝 기여 (Contributing)

- **Phase D / E 기능 제안**: GitHub Issue로 등록
- **LB_VERIFY 단계 추가**: 5단계 단위로 PR 가능
- **자산**: Wesnoth CC-BY-4.0 / sparklinlabs CC0 — README 자산 추가 시 [CREDITS.md](docs/CREDITS.md) 동기화 필수

---

## 🔗 더 보기

- [Godot 4 문서](https://docs.godotengine.org/en/stable/)
- [Battle for Wesnoth](https://www.wesnoth.org/) — 자산 출처
- [Nanum Gothic 폰트](https://fonts.google.com/specimen/Nanum+Gothic)
- [변경 이력](./CHANGELOG.md)
- [로드맵](#-로드맵-roadmap) ← 현재 위치
- [라이선스](./docs/CREDITS.md)