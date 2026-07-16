# Last Banner

> **변방 영지 운영 로그라이크 전략** — Wesnoth 2D 픽토그램 양식 + 저판타지 정치 미학
> Godot 4.7.1 · **macOS 네이티브 전용** · 자동 진행 + 결정 큐

![Godot](https://img.shields.io/badge/Engine-Godot%204.7.1-478CBF?logo=godot-engine&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-macOS-000?logo=apple)
![License](https://img.shields.io/badge/code-MIT-green)
![Assets](https://img.shields.io/badge/assets-CC--BY--4.0%20%2F%20OFL-blue)

---

## 🎮 게임 컨셉

**Last Banner**는 **Wesnoth 2D 픽토그램 양식 + CK3/EU4 양식 정치 미학**의 변방 영지 운영 로그라이크 전략 게임입니다.

- **시각 톤**: Wesnoth 2D 픽토그램 양식 · 저판타지 political 미학 (마법은 subtle, fireball X)
- **메카닉**: 자원 변동 → 사건 생성 → 결정 큐 push → 사용자 결정 → 자동 진행
- **자동 진행**: 위임하면 게임이 알아서 진행. CRITICAL 결정 시에만 정지
- **재진입**: `user://save_*.json` 영속화 — 종료 후 다시 열어도 같은 세션

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

→ 1280×720 윈도우에 Last Banner 타이틀바 + 자원 카드 5개 + 자동 진행 토글 + 결정 모달.

### 정식 빌드 (.app)

```bash
cd ~/work/last-banner
godot --headless --export-release macOS    # → build/macos/Last Banner.app
open "build/macos/Last Banner.app"          # 더블클릭과 동일
```

빌드 산출물: `build/macos/Last Banner.app/` (≈163 MB)

### 헤드리스 검증

```bash
cd ~/work/last-banner
LB_VERIFY=1 godot --headless    # 자동 진행 + 결정 큐 + 저장/로드 round-trip 자동 검증 (5~15초)
```

검증 8단계:
1. 새 게임 초기 상태 OK
2. 1일 시뮬 (1440분)
3. 자원 변동 확인
4. 6일 추가 진행 → 결정 큐 자동 push
5. PASS — 사건 생성 ✓
6. 7일 후 자원 누적
7. save/load round-trip
8. 결과 적용 (VISITOR_WELCOME +30골드)

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
   ┌────────┴────────┐
   │  Scenes (UI)    │
   │  main.tscn      │
```

8 autoload + `main.tscn` 상태 허브. 모든 autoload는 `process_mode = Node.PROCESS_MODE_ALWAYS`로 일시정지 무관 동작.

### 시그널 연결 고리

```
TimeManager (autoload, _process)
   │
   ├─ tick_advanced.emit(game_time)
   │     ├─► SaveManager._on_tick   → maybe_auto_save (60분)
   │     └─► EventEngine._on_tick    → 4h/8h 주기 사건
   │
   └─ day_changed.emit(day)
         └─► EventEngine._on_day    → apply_daily_economy
```

---

## ⌨️ 단축키

| 키 | 동작 |
|---|---|
| **P** | 자동 진행 ON/OFF 토글 |
| **D** | (예정) 영지 대시보드 |
| **R** | (예정) 용병 명단 |

UI 버튼으로 P 토글 + +1일 진행 + 저장 + 불러오기 가능.

---

## 🛠 개발 워크플로

### 자산 갱신 (5 factions base idle PNG)

```bash
bash tools/setup-assets.sh    # idempotent — 풀 → 심볼릭 링크
```

새 faction 추가 시 `setup-assets.sh`에 `link_unit_faction "엘프스"` 한 줄 추가.

### Verifying with LB_VERIFY

`scripts/main.gd`의 `_run_verify()`가 8단계 자동 검증. 변경 시 반드시 통과 확인.

### 알려진 함정

| 함정 | 해결 |
|---|---|
| `_ready` 함수와 `_ready` 멤버 충돌 → parse 에러 | `_manifest_ready` 같이 함수명 회피 |
| autoload의 멤버 이름 `day` → local 변수 명시 접근 `TimeManager.day` | 멤버 shadowing 회피 |
| `assets/.gdignore`가 폰트까지 차단 | 폰트는 .gdignore 없이 import |
| Godot 4.7은 TTF만 직접 로더 (OTF/TTC 미지원) | NanumGothic.ttf 사용 |

상세 함정 + 검증 패턴:
- `incremental-game-design-last-banner-event-engine` 스킬 (GameWorld/EventEngine/DecisionQueue 실전 패턴)
- `godot-game-bootstrap` 스킬 (Godot 부트스트랩 + 멀티플랫폼 export)
- `godot-game-bootstrap/references/godot-4-headless-bootstrap.md`

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
