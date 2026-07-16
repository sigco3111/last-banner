extends Node
## v2 단순화: 자원 + 기본 변동만 (용병 roster / 왕조는 v3에서 추가)
## v1에서 검증된 17+ apply_result() 핸들러는 다음 단계에서 확장

signal resource_changed(resource: String, value: int)
signal event_logged(message: String)

const SAVE_VERSION := 2

# 자원 (int 필드 — null 가드 불필요)
var gold: int = 200
var food: int = 100
var population: int = 50
var prosperity: int = 10
var fortification_level: int = 1

# 일간 변동 누적
var day_gold_change: int = 0
var day_food_change: int = 0

# 이벤트 로그 (저장 필수)
var event_log: Array = []   # [{day: int, message: String}, ...]

var lord_name: String = "토르바르 오크슬레이어"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func modify_resource(resource: String, delta: int) -> void:
	match resource:
		"gold": gold += delta; resource_changed.emit("gold", gold)
		"food": food += delta; resource_changed.emit("food", food)
		"population": population += delta; resource_changed.emit("population", population)
		"prosperity": prosperity = clamp(prosperity + delta, 0, 100); resource_changed.emit("prosperity", prosperity)
		"fortification_level": fortification_level = clamp(fortification_level + delta, 1, 5); resource_changed.emit("fortification_level", fortification_level)
		_:
			push_warning("[GameWorld] unknown resource: %s" % resource)

## 일간 변동 — 세수/수확/월급/식량소비 (간소화, 용병 없으므로 식량소비 = 인구/10)
func apply_daily_economy() -> void:
	# 세수
	var tax: int = max(5, prosperity + population / 4)
	modify_resource("gold", tax)
	# 수확
	var harvest: int = max(2, population / 4)
	modify_resource("food", harvest)
	# 식량 소비 (인구 비례)
	var consumed: int = population / 10
	modify_resource("food", -consumed)
	# 일간 변화량 기록
	day_gold_change = tax
	day_food_change = harvest - consumed
	print("[GameWorld] Day %d — gold %+d, food %+d" % [TimeManager.day, day_gold_change, day_food_change])

func log_event(message: String) -> void:
	var entry := {"day": TimeManager.day, "message": message}
	event_log.append(entry)
	if event_log.size() > 50:
		event_log.pop_front()
	event_logged.emit(message)

## 결과 코드 처리 — main.gd의 _apply_result와 동일 효과
## 전투 화면 등 GameWorld 외부에서 호출 가능
## v3.0 BattleScene에서 사용
const RESULT_EFFECTS := {
	"VISITOR_WELCOME":       { "gold": +30, "prosperity": +1, "log": "방문객 환영" },
	"VISITOR_REJECT":        { "prosperity": -2, "log": "방문객 거절" },
	"FOOD_BUY":              { "gold": -50, "food": +30, "log": "식량 매입" },
	"FOOD_RATION":           { "prosperity": -5, "log": "건제 시행" },
	"DIPLOMACY_ALLIANCE_ACCEPT": { "gold": +50, "prosperity": +8, "log": "동맹 수락" },
	"DIPLOMACY_TRADE":       { "food": +30, "prosperity": +3, "log": "교역" },
	"DIPLOMACY_REFUSE":      { "prosperity": -5, "log": "외교 거절" },
	"BATTLE_BANDITS_HIDE":   { "log": "숨기 — 식량 손실" },
	"BATTLE_BANDITS_BRIBE":  { "gold": -30, "prosperity": -2, "log": "뇌물" },
}

func apply_result(result_code: String, _payload: Dictionary = {}) -> void:
	# GameWorld 모듈 자체에서 자원 변동 적용 (main.gd의 _apply_result와 동등)
	var effects: Dictionary = RESULT_EFFECTS.get(result_code, {})
	for resource_name in effects:
		if resource_name == "log":
			continue
		if effects[resource_name] is int:
			modify_resource(resource_name, int(effects[resource_name]))
	if effects.has("log"):
		log_event(effects["log"])
	print("[GameWorld] apply_result(%s) 적용" % result_code)

func summary() -> String:
	return "lord=%s gold=%d food=%d pop=%d prosper=%d fort=%d" % [
		lord_name, gold, food, population, prosperity, fortification_level
	]

func save_state() -> Dictionary:
	return {
		"lord_name": lord_name,
		"gold": gold,
		"food": food,
		"population": population,
		"prosperity": prosperity,
		"fortification_level": fortification_level,
		"day_gold_change": day_gold_change,
		"day_food_change": day_food_change,
		"event_log": event_log.duplicate(),
	}

func load_state(data: Dictionary) -> void:
	lord_name = data.get("lord_name", "영주")
	gold = data.get("gold", 200)
	food = data.get("food", 100)
	population = data.get("population", 50)
	prosperity = data.get("prosperity", 10)
	fortification_level = data.get("fortification_level", 1)
	day_gold_change = data.get("day_gold_change", 0)
	day_food_change = data.get("day_food_change", 0)
	event_log.clear()
	for e in data.get("event_log", []):
		event_log.append(e)
