# Last Banner v2 — 게임 디자인 노트

> v1 (KayKit 3D + Vercel)에서 **Wesnoth 2D + Godot 4 로컬**으로 컨셉 재정리.
> 결정적 핵심 = 자동 진행 + 결정 큐 + 영지 운영 로그라이크. 어디서든 같은 게임(IndexedDB).

## 컨셉 (불변)

- **장르**: 변방 영지 운영 로그라이크 전략 게임
- **시각 톤**: Wesnoth 2D 픽토그램 양식 + 저판타지 정치 미학 (CK3/EU4 인스피레이션)
- **매직 톤**: 신관/용의자문의 *subtle* 매직 (fireball X)
- **호러/매직 과다**: 비선호
- **메카닉**: 용병 모집 → 계약 → 모험 → 명성 축적 → 다음 계절
- **자동 진행**: 사용자가 위임하면 게임이 알아서 진행, 결정 큐가 차면 알림
- **재진입**: 같은 게임 = 세션 무관. Mac 데스크탑 → 종료 → 다시 열어도 같은 세계.

## 기술 스택 (v2 결정)

| 축 | 결정 | 이유 |
|---|---|---|
| 엔진 | Godot 4.7.1 (stable) | v1에서 검증됨, Wesnoth 2D 임포트 OK, GDScript 단순 |
| 빌드 타겟 | **macOS .app 전용** | v1 Web export = 텍스트만 보이는 회귀. 로컬 우선. |
| 빌드 호스팅 | **로컬 파일 시스템만** | Vercel 배포 보류 (생각중). 우선 실행 가능한 빌드 확보. |
| 2D/3D | **2D 전용** | Wesnoth 자산 = PNG 픽토그램. 3D GLB 폐기. |
| 자산 라인업 | Wesnoth 2D PNG (5 factions) | Wesnoth CC-BY-4.0 |
| 포맷 | PNG idle pose + portrait webp | Godot 4 native import |
| 영속화 | `user://save_*.json` | macOS = `~/Library/Application Support/...` |
| UI 한글 | UnDotum.ttf preload + theme 자동 적용 | v1 함정: 모바일 Web fallback 글리프 깨짐 → 2D에서 재현 X지만 통일 |

## 폐기

- ❌ KayKit GLB (5종 heroes + 4종 skeletons + ~50 dungeon props)
- ❌ Vercel Web export 파이프라인 (`build/web/`, `vercel.json`, `inject-debug-pane.sh`, `disable-service-worker.sh`)
- ❌ lazy fetch / AssetRegistry CDN 모드
- ❌ `last-banner/` 디렉터리 전체 (assets/ + scripts/ + scenes/ + autoload/ + build/)
- ❌ 모든 HTML/JS 도구 (해당 없음)

## 보존 (스킬/지식)

- ✅ `incremental-game-design-last-banner-event-engine` 스킬 — GameWorld + EventEngine + DecisionQueue 8-autoload 패턴
- ✅ `godot-game-bootstrap` 스킬 — Wesnoth 자산 라인업 패턴
- ✅ LB_VERIFY=1 헤드리스 검증 패턴

## 5개 Faction 라인업 (초안)

| ID | 출처 | 분위기 |
|---|---|---|
| `human_loyalists` | wesnoth/units/human-loyalists | 플레이어 진영. 정규 기사/보병/궁수 |
| `human_outlaws` | wesnoth/units/human-outlaws | 모병/유격대. 가챠/숙련 단가 |
| `dunefolk` | wesnoth/units/dunefolk | 이국 용병. 동맹 가능 |
| `undead_skeletal` | wesnoth/units/undead-skeletal | 적 기본. 사악하지만 subtle |
| `orcs` | wesnoth/units/orcs | 적 엘리트 |

이후 `goblins`, `elves-wood`, `dwarves`, `monsters` 등은 카테고리 확장 시 추가.

## 자동 진행 + 결정 큐 (v1 검증 패턴 계승)

```
TimeManager (autoload, _process)
   │
   ├─ tick_advanced.emit(game_time)
   │     ├─► SaveManager._on_tick    → maybe_auto_save (60분 주기)
   │     └─► EventEngine._on_tick    → 4h/8h/10h/12h 주기 사건
   │
   ├─ day_changed.emit(day)
   │     └─► EventEngine._on_day     → apply_daily_economy + apply_weekly_bill
   │
   └─ season_changed.emit(season)
         └─► EventEngine._on_season   → 계절별 특별 이벤트
```

`DecisionQueue.push()`: priority == CRITICAL이면 `GameManager.pause_for_decision()` 자동 호출.
P 키 = 자동 진행 토글. CRITICAL 결정 시 자동 정지.

## 다음 단계

1. `last-banner-v2/` 디렉터리 + Godot 4 프로젝트 파일 (`project.godot`)
2. 8종 autoload 골격
3. `setup-assets.sh` — 풀 → 게임 심볼릭 링크
4. 헤드리스 부팅 검증 (`godot --headless --quit-after 200`)
5. LB_VERIFY=1 자동 진행 시뮬레이션
6. macOS .app 빌드 (`godot --headless --export-release macOS`)
7. 로컬 실행 → 자동 진행 동작 + 결정 큐 push 확인
