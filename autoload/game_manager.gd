extends Node
## 상태머신 — v1 패턴 그대로
## GameWorld.apply_result()가 호출되므로 동적 호출 가능

enum State { BOOT, MENU, PLAYING, PAUSED, DECISION_PENDING, GAME_OVER }

var current_state: int = State.BOOT
var save_slot: String = "default"
var tutorial_seen: bool = false   # v4.1 튜토리얼 1회 표시 플래그

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_new_game(slot: String = "default") -> void:
	current_state = State.PLAYING
	save_slot = slot
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

func is_playing() -> bool:
	return current_state == State.PLAYING

func save_state() -> Dictionary:
	return {
		"current_state": State.keys()[current_state],
		"save_slot": save_slot,
		"tutorial_seen": tutorial_seen,
	}

func load_state(data: Dictionary) -> void:
	var state_str: String = data.get("current_state", "BOOT")
	current_state = State[state_str] if state_str in State.keys() else State.BOOT
	save_slot = data.get("save_slot", "default")
	tutorial_seen = data.get("tutorial_seen", false)
