extends Node
## 상태머신 — v1 패턴 그대로
## GameWorld.apply_result()가 호출되므로 동적 호출 가능

enum State { BOOT, MENU, PLAYING, PAUSED, DECISION_PENDING, GAME_OVER }

var current_state: int = State.BOOT
var save_slot: String = "default"

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
	GameWorld.lord_name = "토르바르 오크슬레이어"
	DecisionQueue._queue.clear()
	print("[GameManager] 새 게임 시작 (slot=%s)" % slot)

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
	}

func load_state(data: Dictionary) -> void:
	var state_str: String = data.get("current_state", "BOOT")
	current_state = State[state_str] if state_str in State.keys() else State.BOOT
	save_slot = data.get("save_slot", "default")
