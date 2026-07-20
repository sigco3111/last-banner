extends Node
## 저장/로드 — v4.1.0 단순화: 단일 autosave 슬롯
## (v1~v4.0 다중 슬롯 → v4.1 단일 슬롯 — 자동 진행 게임의 본질)

const SAVE_VERSION := 2
const AUTO_SAVE_INTERVAL_MIN := 60
const SAVE_SLOT := "autosave"   # v4.1.0: 단일 슬롯 (이전 다중 슬롯 정책 폐기)

var auto_save_enabled: bool = true
var _last_auto_save_min: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TimeManager.tick_advanced.connect(_on_tick)
	# v4.1.0: 첫 실행 시 legacy verify_* 슬롯 정리 (다중 슬롯 시절 부산물)
	_cleanup_legacy_slots()

func _on_tick(_game_time: int) -> void:
	maybe_auto_save()

func maybe_auto_save() -> void:
	if not auto_save_enabled:
		return
	if GameManager.current_state == GameManager.State.BOOT:
		return
	var now := TimeManager.minutes_elapsed
	if now - _last_auto_save_min >= AUTO_SAVE_INTERVAL_MIN:
		if save_game(SAVE_SLOT):
			_last_auto_save_min = now

func _capture_state() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"created_at": Time.get_unix_time_from_system(),
		"slot": SAVE_SLOT,
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

## v4.1.0: 단일 슬롯 API (autosave만)
func save_game(_slot: String = SAVE_SLOT) -> bool:
	# v4.1.0: slot 인자는 호환성 위해 유지하지만 무시 (항상 SAVE_SLOT로 저장)
	var path := "user://save_%s.json" % SAVE_SLOT
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] cannot open: %s" % path)
		return false
	file.store_string(JSON.stringify(_capture_state(), "  "))
	file.close()
	print("[SaveManager] saved: %s" % path)
	return true

func load_game(_slot: String = SAVE_SLOT) -> bool:
	# v4.1.0: slot 인자는 호환성 위해 유지하지만 무시 (항상 SAVE_SLOT에서 로드)
	var path := "user://save_%s.json" % SAVE_SLOT
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

## v4.1.0: 단일 슬롯 — autosave 존재 여부만 반환
func has_save() -> bool:
	return FileAccess.file_exists("user://save_%s.json" % SAVE_SLOT)

## v4.1.0: list_saves 호환성 유지 (UI 표시용) — 0 또는 1개 반환
func list_saves() -> Array:
	if has_save():
		return [SAVE_SLOT]
	return []

## v4.1.0: 단일 슬롯 삭제 (새 게임 시작 시)
func delete_save() -> bool:
	var path := "user://save_%s.json" % SAVE_SLOT
	if not FileAccess.file_exists(path):
		return false
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("[SaveManager] delete 실패: %s (err=%d)" % [path, err])
		return false
	print("[SaveManager] deleted: %s" % path)
	return true

## v4.1.0: legacy 다중 슬롯 정리 (verify_* 등)
func _cleanup_legacy_slots() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	var cleaned: int = 0
	while name != "":
		# save_*.json 패턴이지만 SAVE_SLOT이 아니면 정리
		if name.begins_with("save_") and name.ends_with(".json"):
			var slot_name: String = name.trim_prefix("save_").trim_suffix(".json")
			if slot_name != SAVE_SLOT:
				var full_path: String = "user://" + name
				var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(full_path))
				if err == OK:
					cleaned += 1
					print("[SaveManager] legacy 정리: %s" % full_path)
		name = dir.get_next()
	dir.list_dir_end()
	if cleaned > 0:
		print("[SaveManager] legacy 슬롯 %d개 정리 완료" % cleaned)