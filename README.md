# Last Banner

> **변방 영지 운영 로그라이크 전략** — Wesnoth 2D 픽토그램 양식 · CK3 정치 미학
> **Godot 4.7.1 + macOS 네이티브 전용** · 자동 진행 + 결정 큐 · 432 Wesnoth 자산

[![Godot](https://img.shields.io/badge/Engine-Godot%204.7.1-478CBF?logo=godot-engine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-000?logo=apple)](https://www.apple.com/macos)
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
- **이벤트 간격** (fast 속도에 맞춤): 방문객 20h마다 / 식량·외교 40h마다 / 하루 최대 8건
- **재진입**: `user://save_*.json` 영속화 — Mac 종료 후 다시 열어도 같은 세션

---

## 🖼 화면 구성 (1280×720)

```
┌─────────────────────────────────────────────────────────────────────┐
│ TopResourceBar: Day N | HH:MM | 자동 진행 | 💰 N | 🌾 N | 🪵 사건  │
├─────────────────────────────────────────────────────────────────────┤
│ Manor Dashboard                          ┌────────────────────┐    │
│  ┌────────────────────────────┐         │ ⚔️ 용병 (5명)         │    │
│  │ 토르바르의 영지 — 황야의 변방 │         │ [🖼] 토르바르 · 영주   │    │
│  │ 풀밭 + 흙길 + 캐릭터 5명     │         │   💰 0  ★ 100      │    │
│  │ (knight/swordsman/spearman/ │         │ [🖼] 에드윈 · 기사    │    │
│  │  bowman/bandit PNG)        │         │ ...                 │    │
│  └────────────────────────────┘         └────────────────────┘    │
│  ┌─────────────────┐  ┌──────────────┐                            │
│  │ 📜 방문객 (다음 결정) │  📊 일간 변동  │                            │
│  └─────────────────┘  └──────────────┘                            │
├─────────────────────────────────────────────────────────────────────┤
│ [P: 자동 진행]  [+1일 진행]  [💾 저장]  [📂 불러오기]                  │
└─────────────────────────────────────────────────────────────────────┘

결정 모달 (별도 CanvasLayer, layer=100):
  ┌────────────────────────────────────────┐
  │ [우선순위] 방문객 도착                  │
  │ "귀족이 영지를 방문했습니다..."          │
  │ [환영 (+50골드)]  [거절 (명성 -2)]      │
  └────────────────────────────────────────┘
  + DimBG (검은 반투명 0.7 alpha)
```

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
게임 디자인 노트: [`docs/GAMEDESIGN.md`](docs/GAMEDESIGN.md)

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
LB_VERIFY=1 godot --headless    # 자동 진행 + 결정 큐 + save/load + 화면 + 타이틀 라운드트립 12단계 자동 검증
```

12단계:
1. 새 게임 초기 상태 OK (gold=200 food=100 pop=50)
2. 1일 시뮬 (1440분)
3. 자원 변동
4. 6일 추가 → 결정 큐 자동 push (자동 진행 사건 생성)
5. PASS — 자동 진행 ✓
6. 7일 후 자원 누적
7. save/load round-trip
8. 결과 적용 (VISITOR_WELCOME +30골드)
9. ManorDashboard 화면 검증 (sprite 5 + roster avatar 5)
10. 모달 자동 OFF 검증 — `auto_progress=OFF`에서 모달 유지됨
11. 모달 자동 ON 검증 — `auto_progress=ON`에서 자동 결정 → 모달 닫힘
12. 타이틀 라운드트립 — 저장 존재 시 '이어하기' 활성 + 게임↔타이틀 토글

---

## 🖼 화면 흐름

### 1. 타이틀 화면 (시작 시)

```
🏰 LAST BANNER
변방 영지 운영 로그라이크

[▶ 새로 시작]       (항상 활성)
[⏵ 이어하기]        (저장 파일 있을 때만 활성, '⏵ 이어하기 (N개 저장)')
[✕ 게임 종료]
```

### 2. 게임 모드 (새 게임 / 이어하기 후)

```
┌─────────────────────────────────────────────────────────────────────┐
│ TopResourceBar: Day N | HH:MM | 자동 진행 | 💰 N | 🌾 N | 🪵 ...   │
├─────────────────────────────────────────────────────────────────────┤
│ Manor Dashboard                          ┌────────────────────┐    │
│  ┌────────────────────────────┐         │ ⚔️ 용병 (5명)         │    │
│  │ 토르바르의 영지 — 황야의 변방 │         │ [🖼] 토르바르 · 영주   │    │
│  │ 풀밭 + 흙길 + 캐릭터 5명     │         │   💰 0  ★ 100      │    │
│  └────────────────────────────┘         └────────────────────┘    │
│  ┌─────────────────┐  ┌──────────────┐                            │
│  │ 📜 방문객 (다음 결정) │  📊 일간 변동  │                            │
│  └─────────────────┘  └──────────────┘                            │
├─────────────────────────────────────────────────────────────────────┤
│ [P: 자동 진행]  [+1일]  [💾 저장]  [📂 불러오기]  [🏠 타이틀로]      │
└─────────────────────────────────────────────────────────────────────┘

결정 모달 (별도 ModalLayer, layer=100):
  + DimBG (검은 반투명 0.7) + 제목/설명/선택지 버튼
  - 자동 ON: LOW 3초 / 그 외 5초 후 default 결정으로 자동 resolve
  - 자동 OFF: 사용자 결정까지 무한 대기
```

### 3. 모드 토글 흐름

```
[타이틀] ──새로 시작──► [게임] ──🏠 타이틀로──► [타이틀 (저장 후)]
[타이틀] ──이어하기────► [게임 (저장 복원)]
[타이틀] ──게임 종료────► [게임 종료 (quit)]
```

---

## 🏗 아키텍처

```
┌─────────────────────────────────────────────┐
│ GameManager (state machine)                 │
├─────────────────────────────────────────────┤
│ TimeManager       (자동 진행 시계)           │
│ DecisionQueue     (LOW/MED/HIGH/CRITICAL)   │
│ SaveManager       (user://save_*.json)      │
│ AssetRegistry     (res:// 경로 단순화)       │
│ GameWorld         (자원 + 이벤트 로그)      │
│ EventEngine       (4h/8h 주기 사건)          │
│ KoreanFont        (preload + theme 적용)     │
└─────────────────────────────────────────────┘
            ↓
   ┌────────┴───────────────┐
   │  Scenes (UI Canvas)    │
   │  main.tscn             │
   │   ├─ TopResourceBar    │
   │   ├─ ManorLayer        │ (영지 풍경도 + Roster)
   │   ├─ BottomButtonRow   │
   │   └─ ModalLayer (z=100)| (결정 모달 + DimBG)
```

8 autoload + 메인 허브 화면. 모든 autoload는 `process_mode = Node.PROCESS_MODE_ALWAYS`로 일시정지 무관 동작.

### 시그널 연결

```
TimeManager.tick_advanced ─┬─► SaveManager._on_tick  (60분마다 자동 저장)
                           └─► EventEngine._on_tick  (4h/8h/12h 주기 사건)
TimeManager.day_changed   ────►► EventEngine._on_day  (일간 자원 변동)

DecisionQueue.push(priority=CRITICAL) ──► GameManager.pause_for_decision()
                                          (자동 진행 일시정지 신호)
```

### 결정 큐 자동 진행 동작 (v2 핵심)

```gdscript
# TimeManager.auto_progress_enabled:
#   ON:  LOW 3초 / MEDIUM·HIGH·CRITICAL 5초 후 default 결정으로 자동 resolve
#   OFF: 타이머 미설정 → 사용자가 결정할 때까지 모달 유지
```

**5가지 사건 타입 (모두 자동 진행 ON 시 자동 처리)**:

| 타입 | 우선순위 | 자동 default | 트리거 |
|---|---|---|---|
| `VISITOR` (방문객) | LOW | `VISITOR_REJECT` (명성 -2) | 20시간마다 70% 확률 |
| `FOOD_SHORTAGE` (식량 위기) | CRITICAL (food<15) / MEDIUM | `FOOD_BUY` / `FOOD_RATION` | 40시간마다 food<50 |
| `DIPLOMACY` (동맹/교역) | MEDIUM | `DIPLOMACY_REFUSE` (명성 -5) | 40시간마다 30% |

**하루 최대 8건** — 빠른 자동 진행에서도 사용자가 미쳐 결정할 일 없게.

---

## ⌨️ 단축키

| 키 | 동작 |
|---|---|
| **P** | 자동 진행 ON/OFF 토글 |
| **D** | (예정) 영지 대시보드 |
| **R** | (예정) 용병 명단 |

UI 버튼: P 토글 / +1일 진행 / 저장 / 불러오기

---

## 🛠 개발 워크플로

### 자산 갱신 (5 factions base idle PNG)

```bash
bash tools/setup-assets.sh    # idempotent — 풀 → 심볼릭 링크
```

새 faction 추가 시 `setup-assets.sh`에 `link_unit_faction "faction"` 한 줄 추가.

### LB_VERIFY

`scripts/main.gd`의 `_run_verify()`가 11단계 자동 검증. 변경 시 반드시 통과 확인:

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

상세 패턴:
- `godot-game-bootstrap` 스킬 (Godot 부트스트랩)
- `incremental-game-design-last-banner-event-engine` 스킬 (자동 진행 + 결정 큐 실전 패턴)

---

## 🔄 v1 → v2 변경 이력

| v1 (폐기) | v2 (현재) |
|---|---|
| Godot 4 + Vercel Web export | Godot 4 + macOS .app 전용 |
| KayKit 3D GLB (5 heroes + 4 skeletons + ~50 props) | Wesnoth 2D PNG (5 factions, 432 자산) |
| lazy fetch (jsDelivr CDN) | res:// 직접 |
| 검은 화면 (WebGL2 + COEP 헤더 함정) | 1280×720 매너 대시보드 즉시 표시 |
| 12차까지 누적된 v1 코드 | 클린 리셋 (단 1 commit = v2.0.0) |
| 결정 큐 알림만 (LOW/MEDIUM 안 보임) | 모든 우선순위 모달 + 자동 진행 분기 |

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
