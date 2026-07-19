extends Node
## 사건 생성기 — v1 패턴 그대로
## v2 단순화: 하루 자장 이벤트 + 비상 식량 1종

const RECRUIT_VISITOR_INTERVAL_MIN := 1200  # 20시간마다 방문객
const FOOD_CHECK_INTERVAL_MIN := 2400        # 40시간마다 식량 체크
const DIPLOMACY_INTERVAL_MIN := 2400         # 40시간마다 외교 요청
const BANDIT_RAID_INTERVAL_MIN := 720         # 12시간마다 약탈자 습격 (HIGH)
const MERCHANT_CARAVAN_INTERVAL_MIN := 1800  # 30시간마다 상인 caravan (LOW)
const PLAGUE_CHECK_INTERVAL_MIN := 3000      # 50시간마다 역병 체크 (CRITICAL, 인구>100)
const PEASANT_PETITION_INTERVAL_MIN := 1440  # 매일(24h) 농민 호소 (LOW)
const MERCENARY_OFFER_INTERVAL_MIN := 960    # 16시간마다 용병 자원 제안 (LOW, 9-class)
const MERCENARY_INJURY_INTERVAL_MIN := 480   # 8시간마다 부상 회복 체크
const SUCCESSION_AUDIT_INTERVAL_MIN := 4320 # 3일마다 후계자 감사 (MEDIUM)
const BUILD_CONSTRUCTION_INTERVAL_MIN := 720 # 12시간마다 건물 건설 제안 (LOW)
const DECISION_MAX_PER_DAY := 8              # 하루 최대 8건 (자동 진행 빠른 속도에 맞춤)

# 겨울 진입 감지 — month_changed에서 1회만 push하기 위한 플래그
var _winter_push_pending: bool = false
var _last_season: String = ""

var _decisions_today: int = 0
var _last_recruit_visitor: int = 0
var _last_food_check: int = 0
var _last_diplomacy: int = 0
var _last_bandit_raid: int = 0
var _last_merchant_caravan: int = 0
var _last_plague_check: int = 0
var _last_peasant_petition: int = 0
var _last_mercenary_offer: int = 0
var _last_mercenary_injury: int = 0
var _last_succession_audit: int = 0
var _last_build_construction: int = 0
var _current_day: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TimeManager.tick_advanced.connect(_on_tick)
	TimeManager.day_changed.connect(_on_day)
	TimeManager.season_changed.connect(_on_season)
	# 시즌 초기값은 빈 문자열 — _on_season 콜백이 처음 발화하면 채워짐
	_last_season = ""

func _on_tick(game_time: int) -> void:
	# 방문객 제안
	if game_time - _last_recruit_visitor >= RECRUIT_VISITOR_INTERVAL_MIN:
		_last_recruit_visitor = game_time
		_maybe_visitor(game_time)
	# 식량 체크
	if game_time - _last_food_check >= FOOD_CHECK_INTERVAL_MIN:
		_last_food_check = game_time
		_maybe_food_event(game_time)
	# 외교 요청
	if game_time - _last_diplomacy >= DIPLOMACY_INTERVAL_MIN:
		_last_diplomacy = game_time
		_maybe_diplomacy(game_time)
	# 약탈자 습격 (HIGH)
	if game_time - _last_bandit_raid >= BANDIT_RAID_INTERVAL_MIN:
		_last_bandit_raid = game_time
		_maybe_bandit_raid(game_time)
	# 상인 caravan (LOW)
	if game_time - _last_merchant_caravan >= MERCHANT_CARAVAN_INTERVAL_MIN:
		_last_merchant_caravan = game_time
		_maybe_merchant_caravan(game_time)
	# 역병 체크 (CRITICAL 조건부)
	if game_time - _last_plague_check >= PLAGUE_CHECK_INTERVAL_MIN:
		_last_plague_check = game_time
		_maybe_plague(game_time)
	# 농민 호소 (LOW, 매일)
	if game_time - _last_peasant_petition >= PEASANT_PETITION_INTERVAL_MIN:
		_last_peasant_petition = game_time
		_maybe_peasant_petition(game_time)
	# 용병 자원 제안 (LOW, 9-class)
	if game_time - _last_mercenary_offer >= MERCENARY_OFFER_INTERVAL_MIN:
		_last_mercenary_offer = game_time
		_maybe_mercenary_offer(game_time)
	# 용병 부상 회복 체크 (8시간마다)
	if game_time - _last_mercenary_injury >= MERCENARY_INJURY_INTERVAL_MIN:
		_last_mercenary_injury = game_time
		_check_mercenary_loyalty()
	# 후계자 감사 (3일마다)
	if game_time - _last_succession_audit >= SUCCESSION_AUDIT_INTERVAL_MIN:
		_last_succession_audit = game_time
		_maybe_succession_audit(game_time)
	# 건물 건설 제안 (12시간마다)
	if game_time - _last_build_construction >= BUILD_CONSTRUCTION_INTERVAL_MIN:
		_last_build_construction = game_time
		_maybe_build_construction(game_time)

func _on_day(_d: int) -> void:
	_decisions_today = 0
	GameWorld.apply_daily_economy()
	GameWorld.record_day_snapshot(_d)   # 라인 차트용 history 기록
	print("[EventEngine] Day %d — 자원 변동: gold %+d, food %+d" % [
		_d, GameWorld.day_gold_change, GameWorld.day_food_change
	])

func _on_season(season: String) -> void:
	# winter 진입 시 1회만 WINTER_PREPARATION push
	if season == "winter" and _last_season != "winter":
		_winter_push_pending = true
		_maybe_winter_preparation()
	_last_season = season

## 방문객 — 자원/명성 modest 증진 (수용/거절)
func _maybe_visitor(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if randf() > 0.7:   # 70% 확률
		return
	var gold_offer: int = 30 + randi() % 50
	var is_noble: bool = randf() > 0.5
	DecisionQueue.push("VISITOR", {
		"title": "방문객 도착",
		"description": "%s가(이) 영지를 방문했습니다. %d골드를 제공하며 하룻밤을 원합니다." % [
			"귀족" if is_noble else "여행자", gold_offer
		],
		"choices": [
			{ "id": "welcome", "label": "환영 (%d골드 획득)" % gold_offer, "result": "VISITOR_WELCOME" },
			{ "id": "reject", "label": "거절 (명성 -2)", "result": "VISITOR_REJECT" },
		],
		"gold_offer": gold_offer,
	}, DecisionQueue.Priority.LOW)
	_decisions_today += 1

## 약탈자 습격 (HIGH) — 출격/숨기/뇌물 선택
func _maybe_bandit_raid(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if randf() > 0.4:   # 40% 확률
		return
	var enemy_count: int = 3 + randi() % 3   # 3~5명
	DecisionQueue.push("BANDIT_RAID", {
		"title": "약탈자 습격!",
		"description": "약탈자 %d명이 영지를 습격했습니다. 출격 / 숨기 / 뇌물 중 하나를 선택하세요." % enemy_count,
		"enemy_count": enemy_count,
		"choices": [
			{ "id": "fight", "label": "⚔️ 출격 (전투로 해결)", "result": "BATTLE_BANDITS_FIGHT" },
			{ "id": "hide",  "label": "🛡 숨기 (식량 손실)",    "result": "BATTLE_BANDITS_HIDE" },
			{ "id": "bribe", "label": "💰 뇌물 (골드 손실)",   "result": "BATTLE_BANDITS_BRIBE" },
		],
	}, DecisionQueue.Priority.HIGH)
	_decisions_today += 1

## 외교 요청 — 동맹/교역/거절 선택지
func _maybe_diplomacy(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if randf() > 0.3:   # 30% 확률
		return
	var offer_type: int = randi() % 2   # 0=동맹, 1=교역
	if offer_type == 0:
		DecisionQueue.push("DIPLOMACY", {
			"title": "외교: 동맹 제안",
			"description": "이웃 영주가 동맹을 제안했습니다. 명성 +8, 골드 +50.",
			"choices": [
				{ "id": "accept", "label": "수락 (+8명성, +50골드)", "result": "DIPLOMACY_ALLIANCE_ACCEPT" },
				{ "id": "refuse", "label": "거절 (-5명성)",          "result": "DIPLOMACY_REFUSE" },
			],
		}, DecisionQueue.Priority.MEDIUM)
	else:
		DecisionQueue.push("DIPLOMACY", {
			"title": "외교: 교역 제안",
			"description": "교역로 개설. 식량 +30, 명성 +3.",
			"choices": [
				{ "id": "accept", "label": "수락 (+30식량, +3명성)", "result": "DIPLOMACY_TRADE" },
				{ "id": "refuse", "label": "거절 (-5명성)",          "result": "DIPLOMACY_REFUSE" },
			],
		}, DecisionQueue.Priority.MEDIUM)
	_decisions_today += 1

## 식량 위기 — 식량이 적을 때 매수/건제
func _maybe_food_event(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if GameWorld.food > 50:
		return
	var priority := DecisionQueue.Priority.CRITICAL if GameWorld.food < 15 else DecisionQueue.Priority.MEDIUM
	var food_need: int = 30
	var gold_cost: int = 50 + (15 - min(GameWorld.food, 15)) * 4
	DecisionQueue.push("FOOD_SHORTAGE", {
		"title": "식량 부족" if priority == DecisionQueue.Priority.MEDIUM else "🚨 식량 위기",
		"description": "식량이 %d밖에 남지 않았습니다. 시장에서 사거나 건제를 시행하세요." % GameWorld.food,
		"choices": [
			{ "id": "buy", "label": "시장에서 매입 (%d골드)" % gold_cost, "result": "FOOD_BUY" },
			{ "id": "ration", "label": "건제 시행 (명성 -5)", "result": "FOOD_RATION" },
		],
		"food_need": food_need,
		"gold_cost": gold_cost,
	}, priority)
	_decisions_today += 1

## 농민 호소 (LOW) — 세금 인하 vs 거절 (매일 25%)
func _maybe_peasant_petition(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if randf() > 0.25:   # 25% 확률
		return
	DecisionQueue.push("PEASANT_PETITION", {
		"title": "농민 호소",
		"description": "농민들이 세금 인하를 호소하고 있습니다. 인하하면 명성이 오르고, 거절하면 관계가 헐어집니다.",
		"choices": [
			{ "id": "lower", "label": "💰 세금 인하 (골드 -20, 명성 +3)", "result": "PETITION_LOWER" },
			{ "id": "reject", "label": "🚫 거절 (명성 -2)", "result": "PETITION_REJECT" },
		],
	}, DecisionQueue.Priority.LOW)
	_decisions_today += 1

## 겨울 준비 (MEDIUM) — season_changed 시 1회, 식량 비축/모병/무시
func _maybe_winter_preparation() -> void:
	if not _winter_push_pending:
		return
	_winter_push_pending = false
	# 게임 시작 직후 season_changed 콜백이 올 수 있으니 day_changed와 동일한 cap 적용
	if _decisions_today >= DECISION_MAX_PER_DAY:
		# 다음 날로 미루지 않고 일단 push (겨울 진입은 1년에 1번이라 정보 가치 큼)
		pass
	var food_need: int = 40
	var gold_cost: int = 50
	DecisionQueue.push("WINTER_PREPARATION", {
		"title": "❄️ 겨울이 다가옵니다",
		"description": "겨울을 맞아 식량 비축, 모병, 또는 무시 중 선택하세요. 무시하면 겨울 동안 식량 소비가 2배가 됩니다.",
		"choices": [
			{ "id": "stockpile", "label": "🌾 식량 비축 (+%d 식량, -%d 골드)" % [food_need, gold_cost], "result": "WINTER_STOCKPILE" },
			{ "id": "muster", "label": "⚔️ 모병 (식량 -20, 인구 +5)", "result": "WINTER_MUSTER" },
			{ "id": "ignore", "label": "🤷 무시 (겨울 식량 2배 소비)", "result": "WINTER_IGNORE" },
		],
	}, DecisionQueue.Priority.MEDIUM)

## 상인 caravan (LOW) — 30시간마다 40%, 식량 사고팔기
func _maybe_merchant_caravan(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if randf() > 0.4:   # 40% 확률
		return
	var gold_to_food: int = 30
	var gold_cost: int = 40
	DecisionQueue.push("MERCHANT_CARAVAN", {
		"title": "🚚 상인 caravan 도착",
		"description": "떠돌이 상인이 도착했습니다. 식량 +%d을(를) 골드 %d에 살 수 있습니다." % [gold_to_food, gold_cost],
		"choices": [
			{ "id": "buy", "label": "🛒 식량 구매 (-%d 골드, +%d 식량)" % [gold_cost, gold_to_food], "result": "MERCHANT_BUY" },
			{ "id": "send_away", "label": "✋ 돌려보내기 (명성 -1)", "result": "MERCHANT_SEND_AWAY" },
		],
	}, DecisionQueue.Priority.LOW)
	_decisions_today += 1

## 역병 (CRITICAL) — 50시간마다 5%, 인구 > 100일 때만 발화
func _maybe_plague(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if GameWorld.population < 100:
		return   # 인구 충분치 않으면 역병 위험 낮음
	if randf() > 0.05:   # 5% 확률
		return
	DecisionQueue.push("PLAGUE", {
		"title": "☠️ 역병 발생!",
		"description": "영지에 역병이 돌기 시작했습니다. 즉시 의학을 동원하거나 봉쇄 정책을 시행하세요.",
		"choices": [
			{ "id": "medicine", "label": "💊 의학 동원 (골드 -80, 식량 -10, 사망 방지)", "result": "PLAGUE_MEDICINE" },
			{ "id": "quarantine", "label": "🚧 봉쇄 (인구 -10, 명성 -5)", "result": "PLAGUE_QUARANTINE" },
			{ "id": "nothing", "label": "😱 아무것도 안 함 (인구 -15, 명성 -10)", "result": "PLAGUE_NOTHING" },
		],
	}, DecisionQueue.Priority.CRITICAL)
	_decisions_today += 1

## 용병 자원 제안 (LOW, 16시간마다 60%) — 9-class tier 시스템
func _maybe_mercenary_offer(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if GameWorld.alive_mercenaries().size() >= 12:
		return   # 만원
	if randf() > 0.6:   # 60% 확률
		return
	# 9-class 중 랜덤 선택 (tier 1이 60%, tier 2가 30%, tier 3이 10% 확률)
	var tier_roll: float = randf()
	var class_pool: Array
	if tier_roll < 0.6:
		class_pool = ["bowman", "swordsman", "pikeman"]
	elif tier_roll < 0.9:
		class_pool = ["sergeant", "fencer", "crossbow", "cavalry"]
	else:
		class_pool = ["captain", "paladin"]
	var class_id: String = class_pool[randi() % class_pool.size()]
	var m: Dictionary = GameWorld.offer_mercenary(class_id)
	DecisionQueue.push("MERCENARY_OFFER", {
		"title": "⚔️ 용병 자원 도착",
		"description": "%s (%s, Tier %d)가 합류를 제안합니다. 일급 %d골드, 충성도 %d." % [
			m.name, m.class_label, m.tier, m.wage_demand, m.loyalty
		],
		"choices": [
			{ "id": "accept", "label": "✅ 수용 (일급 %d골드)" % m.wage_demand, "result": "ACCEPT_MERCENARY" },
			{ "id": "reject", "label": "❌ 거절", "result": "REJECT_MERCENARY" },
		],
		"mercenary": m,   # payload로 함께 전달 (메인에서 add_mercenary 호출)
	}, DecisionQueue.Priority.LOW)
	_decisions_today += 1

## 충성도 체크 (8시간마다) — loyalty<30이면 자동 이탈
func _check_mercenary_loyalty() -> void:
	var deserter_ids: Array = []
	for m in GameWorld.roster:
		if m.alive and m.loyalty < 30:
			deserter_ids.append(m.id)
	for id in deserter_ids:
		var m: Dictionary = GameWorld.get_mercenary_by_id(id)
		if not m.is_empty():
			GameWorld.dismiss_mercenary(id, "충성도 저하로 이탈")
			GameWorld.log_event("⚠️ %s 이탈 (충성도 %d)" % [m.name, m.loyalty])
			print("[EventEngine] 용병 자동 이탈: %s (loyalty=%d)" % [m.name, m.loyalty])

## 후계자 감사 (3일마다 MEDIUM) — loyalty ±5 / ambition ±3 변동 후 배신 위험 감지
func _maybe_succession_audit(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	var heirs: Array = GameWorld.get_heirs()
	if heirs.is_empty():
		return
	# 매 감사마다 loyalty ±5, ambition ±3 변동
	for h in heirs:
		h.loyalty = clamp(h.loyalty + randi() % 11 - 5, 0, 100)
		h.ambition = clamp(h.ambition + randi() % 7 - 3, 0, 100)
	# 1순위 후보 표시
	var top_heir: Dictionary = heirs[0]
	DecisionQueue.push("SUCCESSION_AUDIT", {
		"title": "👑 후계자 감사",
		"description": "1순위 후보 %s (충성도 %d, 야망 %d) — 유지 / 교체 / 양육 중 선택하세요." % [top_heir.name, top_heir.loyalty, top_heir.ambition],
		"choices": [
			{ "id": "keep", "label": "✓ 유지", "result": "SUCCESSION_KEEP" },
			{ "id": "swap", "label": "🔄 1↔2 교체", "result": "SUCCESSION_SWAP" },
			{ "id": "nurture", "label": "💝 양육 (골드 -30, 충성도 +10)", "result": "SUCCESSION_NURTURE" },
		],
		"person_id": top_heir.id,
	}, DecisionQueue.Priority.MEDIUM)
	_decisions_today += 1
	# 배신 위험 감지 → CRITICAL 결정 큐 push
	for h in heirs:
		if h.loyalty < 25 and h.ambition > 65 and randf() > 0.5:
			_maybe_heir_betrayal(h)
			return

## 후계자 배신 (CRITICAL) — 처형 / 추방 / 용서 선택지
func _maybe_heir_betrayal(heir: Dictionary) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	DecisionQueue.push("HEIR_BETRAYAL", {
		"title": "⚠️ 후계자 배신!",
		"description": "%s이(가) 왕조를 위협하고 있습니다 (충성도 %d, 야망 %d). 즉시 처형 / 추방 / 용서 중 선택하세요." % [heir.name, heir.loyalty, heir.ambition],
		"choices": [
			{ "id": "crusher", "label": "⚔️ 처형 (명성 +5)", "result": "BETRAYAL_CRUSHER" },
			{ "id": "banish",  "label": "🚪 추방 (명성 -3)", "result": "BETRAYAL_BANISH" },
			{ "id": "forgive", "label": "🕊️ 용서 (충성도 +20, 명성 -8)", "result": "BETRAYAL_FORGIVE" },
		],
		"person_id": heir.id,
	}, DecisionQueue.Priority.CRITICAL)
	_decisions_today += 1

## 건물 건설 제안 (LOW, 12시간마다 50%) — 업그레이드 가능한 건물 중 랜덤
func _maybe_build_construction(_game_time: int) -> void:
	if _decisions_today >= DECISION_MAX_PER_DAY:
		return
	if randf() > 0.5:   # 50% 확률
		return
	# 업그레이드 가능한 건물 목록 (max_level 미만)
	var upgradable: Array = []
	for b in GameWorld.BUILDING_DEFS:
		if GameWorld.can_upgrade(b):
			upgradable.append(b)
	if upgradable.is_empty():
		return   # 모든 건물 max
	var building_id: String = upgradable[randi() % upgradable.size()]
	var def: Dictionary = GameWorld.BUILDING_DEFS[building_id]
	var lvl: int = GameWorld.get_building_level(building_id)
	var cost: Dictionary = GameWorld.get_upgrade_cost(building_id)
	DecisionQueue.push("BUILD_CONSTRUCTION", {
		"title": "🏗️ %s Lv %d → Lv %d" % [def["name"], lvl, lvl + 1],
		"description": "%s (현재 효과: %s)\n건설 비용: %d골드 + %d식량" % [
			def["description"], def["description"], cost["gold"], cost["food"]
		],
		"choices": [
			{ "id": "upgrade", "label": "🔨 건설 (골드 -%d, 식량 -%d)" % [cost["gold"], cost["food"]], "result": "BUILD_UPGRADE" },
			{ "id": "skip", "label": "⏭️ 보류", "result": "BUILD_SKIP" },
		],
		"building_id": building_id,
	}, DecisionQueue.Priority.LOW)
	_decisions_today += 1

## 저장/로드는 SaveManager가 _capture_state/_apply_state로 처리
func save_state() -> Dictionary:
	return {
		"decisions_today": _decisions_today,
		"last_recruit_visitor": _last_recruit_visitor,
		"last_food_check": _last_food_check,
		"last_diplomacy": _last_diplomacy,
		"last_bandit_raid": _last_bandit_raid,
		"last_merchant_caravan": _last_merchant_caravan,
		"last_plague_check": _last_plague_check,
		"last_peasant_petition": _last_peasant_petition,
		"last_mercenary_offer": _last_mercenary_offer,
		"last_mercenary_injury": _last_mercenary_injury,
		"last_succession_audit": _last_succession_audit,
		"last_build_construction": _last_build_construction,
		"current_day": _current_day,
		"winter_push_pending": _winter_push_pending,
		"last_season": _last_season,
	}

func load_state(data: Dictionary) -> void:
	_decisions_today = data.get("decisions_today", 0)
	_last_recruit_visitor = data.get("last_recruit_visitor", 0)
	_last_food_check = data.get("last_food_check", 0)
	_last_diplomacy = data.get("last_diplomacy", 0)
	_last_bandit_raid = data.get("last_bandit_raid", 0)
	_last_merchant_caravan = data.get("last_merchant_caravan", 0)
	_last_plague_check = data.get("last_plague_check", 0)
	_last_peasant_petition = data.get("last_peasant_petition", 0)
	_last_mercenary_offer = data.get("last_mercenary_offer", 0)
	_last_mercenary_injury = data.get("last_mercenary_injury", 0)
	_last_succession_audit = data.get("last_succession_audit", 0)
	_last_build_construction = data.get("last_build_construction", 0)
	_current_day = data.get("current_day", -1)
	_winter_push_pending = data.get("winter_push_pending", false)
	_last_season = data.get("last_season", "")
