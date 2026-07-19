extends Node
## v2 단순화: 자원 + 기본 변동만 (용병 roster / 왕조는 v3에서 추가)
## v1에서 검증된 17+ apply_result() 핸들러는 다음 단계에서 확장
## v3.2 — A-1: 용병 roster + 시그널 3종 + alive_mercenaries/총 일급 API

signal resource_changed(resource: String, value: int)
signal event_logged(message: String)
signal mercenary_joined(mercenary: Dictionary)
signal mercenary_left(mercenary: Dictionary, reason: String)
signal mercenary_injured(mercenary: Dictionary, days: int)
signal person_added(person: Dictionary)
signal person_removed(person: Dictionary, reason: String)
signal succession_changed(new_heir: Dictionary)

const SAVE_VERSION := 2
const MERCENARY_ID_START := 1000

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

# 일별 자원 히스토리 (라인 차트용)
const HISTORY_MAX_DAYS := 7
var history: Array = []   # [{day, gold, food}, ...] 오래된→최신, 최대 7일
var _last_history_day: int = -1

# 용병 roster — {id, name, class, tier, experience, loyalty, wage_demand, injured_days, alive}
var roster: Array = []
var _next_mercenary_id: int = MERCENARY_ID_START

# 왕조 / 인물 court — v3.3 A-2 (CK3 양식 4종 스탯)
const PERSON_ID_START := 2000
var court: Array = []   # 모든 인물 (영주 + 후보 + 신하)
var _next_person_id: int = PERSON_ID_START
var dynasty_name: String = ""

# v3.3 A-3: 빌딩 시스템 (4종 × max_level 3)
# market: 세수 +5/level / training_ground: 용병 exp +2/level
# granary: 식량 +10/level / walls: 피해 -10%/level
const BUILDING_MAX_LEVEL := 3
const BUILDING_DEFS := {
	"market": {
		"name": "시장",
		"icon": "🏪",
		"description": "세수 +5/level",
		"gold_cost_base": 50, "food_cost_base": 30,
		"effect_per_level": { "tax_bonus": 5 },
	},
	"training_ground": {
		"name": "훈련장",
		"icon": "⚔️",
		"description": "용병 경험 +2/level",
		"gold_cost_base": 40, "food_cost_base": 0,
		"effect_per_level": { "exp_bonus": 2 },
	},
	"granary": {
		"name": "창고",
		"icon": "🌾",
		"description": "식량 +10/level",
		"gold_cost_base": 30, "food_cost_base": 20,
		"effect_per_level": { "food_bonus": 10 },
	},
	"walls": {
		"name": "성벽",
		"icon": "🏰",
		"description": "약탈/역병 피해 -10%/level",
		"gold_cost_base": 80, "food_cost_base": 0,
		"effect_per_level": { "defense_bonus": 10 },
	},
}
var buildings: Dictionary = {}   # { building_id: level } — 0 = 미건설

# 인물 이름 풀 (Wesnoth 양식 fantasy)
const PERSON_FIRST_NAMES := [
	"아드리안", "엘리아", "카엘", "로한", "세바스찬", "베르나르", "율리안",
	"니콜라우스", "시릴", "레오", "안셀름", "발렌타인", "오스카", "피에르",
	"헨리", "라이몬드", "가브리엘", "카스퍼", "라이오넬", "스테판",
	"셀레스테", "이사벨라", "비비안", "로잘린드", "아드리아나",
]
const PERSON_TITLES := ["영주", "후계자", "신하", "원로", "기사단장", "원정대장"]

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

## 용병 roster API
func offer_mercenary(class_id: String) -> Dictionary:
	var m: Dictionary = MercenaryData.generate_mercenary(class_id, _next_mercenary_id)
	_next_mercenary_id += 1
	return m

func add_mercenary(m: Dictionary) -> void:
	roster.append(m)
	mercenary_joined.emit(m)
	log_event("%s (%s) 합류 — 일급 %d골드" % [m.name, m.class_label, m.wage_demand])
	print("[GameWorld] 용병 합류: %s (id=%d)" % [m.name, m.id])

func dismiss_mercenary(mercenary_id: int, reason: String = "해고") -> bool:
	for m in roster:
		if m.id == mercenary_id and m.alive:
			m.alive = false
			mercenary_left.emit(m, reason)
			log_event("%s %s — %s" % [m.name, m.class_label, reason])
			print("[GameWorld] 용병 이탈: %s — %s" % [m.name, reason])
			return true
	return false

func injure_mercenary(mercenary_id: int, days: int) -> bool:
	for m in roster:
		if m.id == mercenary_id and m.alive:
			m.injured_days = days
			mercenary_injured.emit(m, days)
			log_event("%s 부상 (%d일)" % [m.name, days])
			return true
	return false

func alive_mercenaries() -> Array:
	var result: Array = []
	for m in roster:
		if m.alive:
			result.append(m)
	return result

func get_mercenary_by_id(id: int) -> Dictionary:
	for m in roster:
		if m.id == id:
			return m
	return {}

func total_wage_burden() -> int:
	return MercenaryData.total_wage_burden(roster)

func reset_roster() -> void:
	roster.clear()
	_next_mercenary_id = MERCENARY_ID_START

## 왕조 court API — v3.3 A-2
func spawn_initial_court() -> void:
	court.clear()
	_next_person_id = PERSON_ID_START
	# 영주 (heir_rank=0)
	var lord: Dictionary = _create_person(PERSON_TITLES[0], 0, -1, 60, 30)
	court.append(lord)
	lord_name = lord.name
	dynasty_name = "%s 가문" % lord.name
	# 후보 3명 (heir_rank 1~3)
	var vassal_count: int = 0
	for i in range(3):
		var title: String = PERSON_TITLES[1]
		var heir: Dictionary = _create_person(title, i + 1, lord.id, 50 + randi() % 30, 25 + randi() % 30)
		court.append(heir)
	# 신하 1명 (heir_rank=-1)
	var vassal: Dictionary = _create_person(PERSON_TITLES[2], -1, lord.id, 70, 20)
	court.append(vassal)
	print("[GameWorld] court 초기화: %d명 (영주=%s)" % [court.size(), lord.name])

func _create_person(base_class: String, heir_rank: int, parent_id: int, age_base: int, loyalty_base: int) -> Dictionary:
	var p: Dictionary = {
		"id": _next_person_id,
		"name": PERSON_FIRST_NAMES[randi() % PERSON_FIRST_NAMES.size()],
		"class": base_class,
		"age": age_base + randi() % 20,
		"stats": {
			"martial": 4 + randi() % 12,       # 4~15
			"stewardship": 4 + randi() % 12,
			"diplomacy": 4 + randi() % 12,
			"intrigue": 4 + randi() % 12,
		},
		"loyalty": loyalty_base + randi() % 30,    # 0~100
		"ambition": 30 + randi() % 40,             # 30~70
		"alive": true,
		"spouse_id": -1,
		"parent_id": parent_id,
		"heir_rank": heir_rank,                    # 0=영주, 1=1순위, -1=신하
		"dynasty": dynasty_name,
		"portrait_index": randi() % 8,
	}
	_next_person_id += 1
	return p

func get_person_by_id(id: int) -> Dictionary:
	for p in court:
		if p.id == id:
			return p
	return {}

func get_lord() -> Dictionary:
	for p in court:
		if p.alive and p.heir_rank == 0:
			return p
	return {}

func get_heirs() -> Array:
	var heirs: Array = []
	for p in court:
		if p.alive and p.heir_rank > 0:
			heirs.append(p)
	heirs.sort_custom(func(a, b): return a["heir_rank"] < b["heir_rank"])
	return heirs

func get_vassals() -> Array:
	var result: Array = []
	for p in court:
		if p.alive and p.heir_rank < 0:
			result.append(p)
	return result

func set_heir_rank(person_id: int, new_rank: int) -> bool:
	var p: Dictionary = get_person_by_id(person_id)
	if p.is_empty() or not p.alive:
		return false
	var old_rank: int = p.heir_rank
	p.heir_rank = new_rank
	log_event("후계자 변경: %s (%d → %d)" % [p.name, old_rank, new_rank])
	succession_changed.emit(p)
	print("[GameWorld] 후계자 변경: %s (rank %d → %d)" % [p.name, old_rank, new_rank])
	return true

func kill_person(person_id: int, reason: String = "사망") -> bool:
	for p in court:
		if p.id == person_id and p.alive:
			p.alive = false
			person_removed.emit(p, reason)
			log_event("💀 %s %s — %s" % [p.name, p.class, reason])
			print("[GameWorld] 인물 사망: %s — %s" % [p.name, reason])
			return true
	return false

func reset_court() -> void:
	court.clear()
	_next_person_id = PERSON_ID_START
	dynasty_name = ""

## v3.3 A-3: 빌딩 API
func reset_buildings() -> void:
	buildings.clear()
	for b in BUILDING_DEFS:
		buildings[b] = 0   # 0 = 미건설

func get_building_level(building_id: String) -> int:
	return int(buildings.get(building_id, 0))

func can_upgrade(building_id: String) -> bool:
	if not BUILDING_DEFS.has(building_id):
		return false
	return get_building_level(building_id) < BUILDING_MAX_LEVEL

func upgrade_building(building_id: String) -> bool:
	if not can_upgrade(building_id):
		return false
	var cost: Dictionary = get_upgrade_cost(building_id)
	if gold < cost.gold or food < cost.food:
		return false
	modify_resource("gold", -int(cost.gold))
	modify_resource("food", -int(cost.food))
	buildings[building_id] = get_building_level(building_id) + 1
	log_event("🏗️ %s Lv %d 건설 완료" % [BUILDING_DEFS[building_id]["name"], get_building_level(building_id)])
	print("[GameWorld] %s → Lv %d" % [building_id, get_building_level(building_id)])
	return true

func get_upgrade_cost(building_id: String) -> Dictionary:
	if not BUILDING_DEFS.has(building_id):
		return { "gold": 0, "food": 0 }
	var lvl: int = get_building_level(building_id)
	var def: Dictionary = BUILDING_DEFS[building_id]
	# 비용 = base × (lvl+1)  — Lv 0→1 = base × 1, Lv 2→3 = base × 3
	return {
		"gold": int(def["gold_cost_base"]) * (lvl + 1),
		"food": int(def["food_cost_base"]) * (lvl + 1),
	}

func get_total_tax_bonus() -> int:
	var sum: int = 0
	for b in BUILDING_DEFS:
		var def: Dictionary = BUILDING_DEFS[b]
		if int(def["effect_per_level"].get("tax_bonus", 0)) > 0:
			sum += int(def["effect_per_level"]["tax_bonus"]) * get_building_level(b)
	return sum

func get_total_food_bonus() -> int:
	var sum: int = 0
	for b in BUILDING_DEFS:
		var def: Dictionary = BUILDING_DEFS[b]
		if int(def["effect_per_level"].get("food_bonus", 0)) > 0:
			sum += int(def["effect_per_level"]["food_bonus"]) * get_building_level(b)
	return sum

func get_total_exp_bonus() -> int:
	var sum: int = 0
	for b in BUILDING_DEFS:
		var def: Dictionary = BUILDING_DEFS[b]
		if int(def["effect_per_level"].get("exp_bonus", 0)) > 0:
			sum += int(def["effect_per_level"]["exp_bonus"]) * get_building_level(b)
	return sum

func get_defense_multiplier() -> float:
	# 1.0 = 기본, walls Lv 1 = 0.9, Lv 3 = 0.7
	var mult: float = 1.0
	for b in BUILDING_DEFS:
		var def: Dictionary = BUILDING_DEFS[b]
		if int(def["effect_per_level"].get("defense_bonus", 0)) > 0:
			mult -= float(def["effect_per_level"]["defense_bonus"]) / 100.0 * get_building_level(b)
	return max(0.5, mult)

## 일간 변동 — 세수/수확/월급/식량소비
func apply_daily_economy() -> void:
	# 세수 (시장 보너스 +)
	var tax: int = max(5, prosperity + population / 4) + get_total_tax_bonus()
	modify_resource("gold", tax)
	# 수확 (창고 보너스 +)
	var harvest: int = max(2, population / 4) + get_total_food_bonus()
	modify_resource("food", harvest)
	# 식량 소비 (인구 비례 + 용병 추가 소비 2/명)
	var consumed: int = population / 10 + alive_mercenaries().size() * 2
	modify_resource("food", -consumed)
	# 용병 월급
	var wage: int = total_wage_burden()
	if wage > 0:
		modify_resource("gold", -wage)
	# 부상 회복 + 훈련장 보너스 (exp +)
	for m in roster:
		if m.alive and m.injured_days > 0:
			m.injured_days -= 1
		if m.alive:
			m.experience += get_total_exp_bonus()
	# 일간 변화량 기록
	day_gold_change = tax - wage
	day_food_change = harvest - consumed
	print("[GameWorld] Day %d — gold %+d, food %+d (용병 %d명, 건물 보너스 tax+%d food+%d exp+%d)" % [
		TimeManager.day, day_gold_change, day_food_change, alive_mercenaries().size(),
		get_total_tax_bonus(), get_total_food_bonus(), get_total_exp_bonus()
	])

func log_event(message: String) -> void:
	var entry := {"day": TimeManager.day, "message": message}
	event_log.append(entry)
	if event_log.size() > 50:
		event_log.pop_front()
	event_logged.emit(message)

## 일별 스냅샷 — 라인 차트용 history ring buffer (최대 7일)
func record_day_snapshot(day: int) -> void:
	var snap := {
		"day": day,
		"gold": gold,
		"food": food,
	}
	if _last_history_day == day and not history.is_empty():
		history[-1] = snap   # 같은 날 중복 방지 — 갱신
	else:
		history.append(snap)
		_last_history_day = day
		while history.size() > HISTORY_MAX_DAYS:
			history.pop_front()

func reset_history() -> void:
	history.clear()
	_last_history_day = -1

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
	"PETITION_LOWER":        { "gold": -20, "prosperity": +3, "log": "세금 인하" },
	"PETITION_REJECT":       { "prosperity": -2, "log": "농민 호소 거절" },
	"WINTER_STOCKPILE":      { "gold": -50, "food": +40, "log": "겨울 식량 비축" },
	"WINTER_MUSTER":         { "food": -20, "population": +5, "log": "겨울 모병" },
	"WINTER_IGNORE":         { "log": "겨울 대비 무시" },
	"MERCHANT_BUY":          { "gold": -40, "food": +30, "log": "상인 식량 구매" },
	"MERCHANT_SEND_AWAY":    { "prosperity": -1, "log": "상인 돌려보냄" },
	"PLAGUE_MEDICINE":       { "gold": -80, "food": -10, "log": "역병 의학 동원" },
	"PLAGUE_QUARANTINE":     { "population": -10, "prosperity": -5, "log": "역병 봉쇄" },
	"PLAGUE_NOTHING":        { "population": -15, "prosperity": -10, "log": "역병 방치" },
	# v3.2 A-1: 용병 7종
	"ACCEPT_MERCENARY":      { "log": "용병 수용" },                  # payload.mercenary dict 필요 → add_mercenary 호출은 main.gd에서
	"REJECT_MERCENARY":      { "log": "용병 거절" },                  # payload.mercenary 무시
	"DISMISS_MERCENARY":     { "log": "용병 해고" },                  # payload.mercenary_id로 dismiss_mercenary 호출
	"MERCENARY_PAY_BONUS":   { "gold": -30, "prosperity": +5, "log": "용병 보너스 지급" },
	"MERCENARY_TRAINING":    { "gold": -20, "prosperity": +2, "log": "용병 훈련" },
	"MERCENARY_INJURY_HEAL": { "gold": -15, "log": "용병 부상 치료" },
	"MERCENARY_DESERTS":     { "log": "용병 이탈" },                  # 자동 — loyalty<30 발화
	# v3.3 A-2: 왕조/후계자 5종
	"BETRAYAL_CRUSHER":      { "prosperity": +5, "log": "후계자 처형" },   # payload.person_id → kill_person
	"BETRAYAL_BANISH":       { "prosperity": -3, "log": "후계자 추방" },   # payload.person_id → kill_person("추방")
	"BETRAYAL_FORGIVE":      { "prosperity": -8, "log": "후계자 용서" },   # payload.person_id → loyalty +20
	"SUCCESSION_KEEP":       { "log": "후계자 유지" },
	"SUCCESSION_SWAP":       { "log": "후계자 교체" },                     # payload.person_a_id ↔ payload.person_b_id
	"SUCCESSION_NURTURE":    { "gold": -30, "prosperity": +2, "log": "후계자 양육" },  # payload.person_id → loyalty +10
	# v3.3 A-3: 빌딩 2종
	"BUILD_UPGRADE":         { "log": "건물 건설" },                      # payload.building_id → upgrade_building 호출
	"BUILD_SKIP":            { "log": "건물 건설 보류" },                  # no-op
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
		"history": history.duplicate(),
		"_last_history_day": _last_history_day,
		"roster": roster.duplicate(true),
		"_next_mercenary_id": _next_mercenary_id,
		"court": court.duplicate(true),
		"_next_person_id": _next_person_id,
		"dynasty_name": dynasty_name,
		"buildings": buildings.duplicate(),
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
	history.clear()
	for h in data.get("history", []):
		history.append(h)
	_last_history_day = data.get("_last_history_day", -1)
	roster.clear()
	for m in data.get("roster", []):
		roster.append(m)
	_next_mercenary_id = data.get("_next_mercenary_id", MERCENARY_ID_START)
	court.clear()
	for p in data.get("court", []):
		court.append(p)
	_next_person_id = data.get("_next_person_id", PERSON_ID_START)
	dynasty_name = data.get("dynasty_name", "")
	buildings.clear()
	for b in data.get("buildings", {}):
		buildings[b] = data["buildings"][b]
