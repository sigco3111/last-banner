extends Node
## 결정 큐 — v1 검증 패턴 (LOW/MEDIUM 알림, HIGH/CRITICAL 모달)

enum Priority { LOW, MEDIUM, HIGH, CRITICAL }

var _queue: Array = []
var _next_id: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func push(type_id: String, payload: Dictionary, priority: int = Priority.MEDIUM) -> int:
	var decision := {
		"id": _next_id,
		"type": type_id,
		"payload": payload,
		"priority": priority,
		"created_at_min": TimeManager.minutes_elapsed if TimeManager else 0,
		"resolved": false,
	}
	_next_id += 1
	_queue.append(decision)
	# CRITICAL이면 자동 정지
	if priority == Priority.CRITICAL and GameManager:
		GameManager.pause_for_decision()
	print("[DecisionQueue] push [%s] %s (id=%d, total=%d)" % [
		Priority.keys()[priority], type_id, decision.id, _queue.size()
	])
	return decision.id

func resolve(id: int, _choice: Dictionary) -> bool:
	for d in _queue:
		if d.id == id:
			d.resolved = true
			_queue.erase(d)
			print("[DecisionQueue] resolve id=%d (남은 큐=%d)" % [id, _queue.size()])
			return true
	return false

func get_all_pending() -> Array:
	return _queue.duplicate()

func has_any_pending() -> bool:
	return not _queue.is_empty()

func has_pending_critical() -> bool:
	for d in _queue:
		if d.priority == Priority.CRITICAL and not d.resolved:
			return true
	return false

func save_state() -> Dictionary:
	return {
		"next_id": _next_id,
		"queue": _queue.duplicate(),
	}

func load_state(data: Dictionary) -> void:
	_next_id = data.get("next_id", 1)
	_queue.clear()
	for d in data.get("queue", []):
		_queue.append(d)
