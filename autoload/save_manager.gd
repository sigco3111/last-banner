extends Node
## 저장/로드 — v1 패턴 그대로 (user://save_*.json, 60분 주기 자동 저장)

const SAVE_VERSION := 2
const AUTO_SAVE_INTERVAL_MIN := 60

var auto_save_enabled: bool = true
var _last_auto_save_min: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TimeManager.tick_advanced.connect(_on_tick)

func _on_tick(_game_time: int) -> void:
	maybe_auto_save()

func maybe_auto_save() -> void:
	if not auto_save_enabled:
		return
	if GameManager.current_state == GameManager.State.BOOT:
		return
	var now := TimeManager.minutes_elapsed
	if now - _last_auto_save_min >= AUTO_SAVE_INTERVAL_MIN:
		if save_game("autosave"):
			_last_auto_save_min = now

func _capture_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"created_at": Time.get_unix_time_from_system(),
		"game": GameManager.save_state(),
		"time": TimeManager.save_state(),
		"world": GameWorld.save_state(),
		"decisions": DecisionQueue.save_state(),
		"events": EventEngine.save_state(),
	}

func _apply_state(data: Dictionary) -> void:
	if data.has("game"): GameManager.load_state(data["game"])
	if data.has("time"): TimeManager.load_state(data["time"])
	if data.has("world"): GameWorld.load_state(data["world"])
	if data.has("decisions"): DecisionQueue.load_state(data["decisions"])
	if data.has("events"): EventEngine.load_state(data["events"])
	_last_auto_save_min = TimeManager.minutes_elapsed

func save_game(slot: String) -> bool:
	var path := "user://save_%s.json" % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] cannot open: %s" % path)
		return false
	file.store_string(JSON.stringify(_capture_state(), "  "))
	file.close()
	print("[SaveManager] saved: %s" % path)
	return true

func load_game(slot: String) -> bool:
	var path := "user://save_%s.json" % slot
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] invalid JSON: %s" % path)
		return false
	_apply_state(parsed)
	print("[SaveManager] loaded: %s" % path)
	return true

func list_saves() -> Array:
	var result: Array = []
	var dir := DirAccess.open("user://")
	if dir == null:
		return result
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("save_") and name.ends_with(".json"):
			result.append(name.trim_prefix("save_").trim_suffix(".json"))
		name = dir.get_next()
	dir.list_dir_end()
	return result
