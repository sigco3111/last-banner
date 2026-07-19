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

## 🆕 v4.0.0 신규 기능

### Phase A — 게임 깊이 확장
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
LB_VERIFY=1 godot --headless    # 13+4단계 자동 검증 (~5~15초)
```

**검증 단계 (17종)**:
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
| v4.0 | **Phase A 4단계 (사건 4종 + 용병 9-class + 왕조 court + 빌딩 4종) + UI 1차 복귀** |

자세한 마이그레이션 로그는 [`CHANGELOG.md`](CHANGELOG.md) 참조.

---

## 📜 라이선스

- **코드**: MIT ([LICENSE](LICENSE))
- **Wesnoth 자산**: CC-BY-4.0 ([docs/CREDITS.md](docs/CREDITS.md))
- **NanumGothic 폰트**: SIL OFL 1.1

---

## 🔗 더 보기

- [Godot 4 문서](https://docs.godotengine.org/en/stable/)
- [Battle for Wesnoth](https://www.wesnoth.org/) — 자산 출처
- [Nanum Gothic 폰트](https://fonts.google.com/specimen/Nanum+Gothic)
- [변경 이력](./CHANGELOG.md)
- [라이선스](./docs/CREDITS.md)