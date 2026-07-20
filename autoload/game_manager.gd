extends Node
## 상태머신 — v1 패턴 그대로
## GameWorld.apply_result()가 호출되므로 동적 호출 가능
## v4.1 B-3: 게임 오버 조건 + 시그널

signal game_ended(reason: String, stats: Dictionary)

enum State { BOOT, MENU, PLAYING, PAUSED, DECISION_PENDING, GAME_OVER }

const CONSECUTIVE_FOOD_ZERO_DAYS_LIMIT := 30   # 식량 0 이 30일 연속 → 아사 게임 오버
const POPULATION_EXTINCTION_THRESHOLD := 0    # 인구 0 → 멸망 게임 오버

var current_state: int = State.BOOT
var save_slot: String = "default"
var tutorial_seen: bool = false   # v4.1 튜토리얼 1회 표시 플래그

# v4.1 게임 오버 (B-3)
var end_reason: String = ""          # "POPULATION_EXTINCTION" / "FOOD_FAMINE" / "DYNASTY_EXTINCTION"
var end_day: int = 0                # 종료 시점 게임 일수
var end_stats: Dictionary = {}      # 종료 시점 통계 (gold/food/pop/prosperity/wall_level/roster_count/court_count)
var consecutive_food_zero_days: int = 0  # 식량 0 연속 일수 추적

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game(slot: String = "default") -> void:
	current_state = State.PLAYING
	save_slot = slot
	# v4.1 B-3: 새 게임 = 게임 오버 상태 리셋
	reset_end_state()
	GameWorld.gold = 200
	GameWorld.food = 100
	GameWorld.population = 50
	GameWorld.prosperity = 10
	GameWorld.fortification_level = 1
	GameWorld.reset_history()        # 새 게임은 히스토리 리셋
	GameWorld.reset_roster()         # v3.2 A-1: 새 게임은 roster 리셋
	GameWorld.reset_court()          # v3.3 A-2: 새 게임은 court 리셋
	GameWorld.spawn_initial_court()  # v3.3 A-2: 영주 1 + 후보 3 + 신하 1
	GameWorld.reset_buildings()      # v3.3 A-3: 새 게임은 buildings 리셋
	# 초기 용병 5명 (bowman 2, swordsman 1, pikeman 1, sergeant 1)
	var seed_classes := ["bowman", "bowman", "swordsman", "pikeman", "sergeant"]
	for c in seed_classes:
		var m: Dictionary = GameWorld.offer_mercenary(c)
		GameWorld.add_mercenary(m)
	DecisionQueue._queue.clear()
	print("[GameManager] 새 게임 시작 (slot=%s, 용병=%d명, court=%d명)" % [slot, GameWorld.alive_mercenaries().size(), GameWorld.court.size()])

func pause_for_decision() -> void:
	if current_state == State.PLAYING:
		current_state = State.DECISION_PENDING
		print("[GameManager] 결정 대기로 전환")

func resume_from_decision() -> void:
	if current_state == State.DECISION_PENDING:
		current_state = State.PLAYING
		print("[GameManager] 결정 완료, 게임 진행 재개")

## v4.1 게임 오버 (B-3)
func check_game_over_conditions() -> bool:
	# 이미 GAME_OVER면 다시 평가 안 함
	if current_state == State.GAME_OVER:
		return true
	# 조건 1: 인구 멸망
	if GameWorld.population <= POPULATION_EXTINCTION_THRESHOLD:
		end_game("POPULATION_EXTINCTION")
		return true
	# 조건 2: 식량 0 연속 30일
	if GameWorld.food <= 0:
		consecutive_food_zero_days += 1
		if consecutive_food_zero_days >= CONSECUTIVE_FOOD_ZERO_DAYS_LIMIT:
			end_game("FOOD_FAMINE")
			return true
	else:
		consecutive_food_zero_days = 0
	# 조건 3: 왕조 멸절 (영주 + 후보 + 신하 모두 사망)
	var alive_court: int = 0
	for p in GameWorld.court:
		if p.alive:
			alive_court += 1
	if alive_court == 0:
		end_game("DYNASTY_EXTINCTION")
		return true
	return false

func end_game(reason: String) -> void:
	if current_state == State.GAME_OVER:
		return   # 중복 호출 방지
	end_reason = reason
	end_day = TimeManager.day
	end_stats = {
		"gold": GameWorld.gold,
		"food": GameWorld.food,
		"population": GameWorld.population,
		"prosperity": GameWorld.prosperity,
		"fortification_level": GameWorld.fortification_level,
		"roster_count": GameWorld.alive_mercenaries().size(),
		"court_count": GameWorld.court.size(),
		"buildings": GameWorld.buildings.duplicate(),
		"history_days": GameWorld.history.size(),
	}
	current_state = State.GAME_OVER
	print("[GameManager] 게임 오버: %s (Day %d, %d일 생존)" % [reason, end_day, end_day])
	game_ended.emit(reason, end_stats)

func reset_end_state() -> void:
	end_reason = ""
	end_day = 0
	end_stats.clear()
	consecutive_food_zero_days = 0
	current_state = State.PLAYING

func get_end_reason_label() -> String:
	match end_reason:
		"POPULATION_EXTINCTION": return "인구 멸망"
		"FOOD_FAMINE": return "대기아 (식량 0 연속 30일)"
		"DYNASTY_EXTINCTION": return "왕조 멸절"
		_: return "알 수 없음"

func is_playing() -> bool:
	return current_state == State.PLAYING

func save_state() -> Dictionary:
	return {
		"current_state": State.keys()[current_state],
		"save_slot": save_slot,
		"tutorial_seen": tutorial_seen,
		"end_reason": end_reason,
		"end_day": end_day,
		"end_stats": end_stats.duplicate(true),
		"consecutive_food_zero_days": consecutive_food_zero_days,
	}

func load_state(data: Dictionary) -> void:
	var state_str: String = data.get("current_state", "BOOT")
	current_state = State[state_str] if state_str in State.keys() else State.BOOT
	save_slot = data.get("save_slot", "default")
	tutorial_seen = data.get("tutorial_seen", false)
	end_reason = data.get("end_reason", "")
	end_day = data.get("end_day", 0)
	end_stats.clear()
	for k in data.get("end_stats", {}):
		end_stats[k] = data["end_stats"][k]
	consecutive_food_zero_days = data.get("consecutive_food_zero_days", 0)
