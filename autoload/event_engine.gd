extends Node
## 사건 생성기 — v1 패턴 그대로
## v2 단순화: 하루 자장 이벤트 + 비상 식량 1종

const RECRUIT_VISITOR_INTERVAL_MIN := 1200  # 20시간마다 방문객
const FOOD_CHECK_INTERVAL_MIN := 2400        # 40시간마다 식량 체크
const DIPLOMACY_INTERVAL_MIN := 2400         # 40시간마다 외교 요청
const BANDIT_RAID_INTERVAL_MIN := 720         # 12시간마다 약탈자 습격 (HIGH)
const DECISION_MAX_PER_DAY := 8              # 하루 최대 8건 (자동 진행 빠른 속도에 맞춤)

var _decisions_today: int = 0
var _last_recruit_visitor: int = 0
var _last_food_check: int = 0
var _last_diplomacy: int = 0
var _last_bandit_raid: int = 0
var _current_day: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TimeManager.tick_advanced.connect(_on_tick)
	TimeManager.day_changed.connect(_on_day)

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

func _on_day(_d: int) -> void:
	_decisions_today = 0
	GameWorld.apply_daily_economy()
	GameWorld.record_day_snapshot(_d)   # 라인 차트용 history 기록
	print("[EventEngine] Day %d — 자원 변동: gold %+d, food %+d" % [
		_d, GameWorld.day_gold_change, GameWorld.day_food_change
	])
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

## 저장/로드는 SaveManager가 _capture_state/_apply_state로 처리
func save_state() -> Dictionary:
	return {
		"decisions_today": _decisions_today,
		"last_recruit_visitor": _last_recruit_visitor,
		"last_food_check": _last_food_check,
		"last_diplomacy": _last_diplomacy,
		"last_bandit_raid": _last_bandit_raid,
		"current_day": _current_day,
	}

func load_state(data: Dictionary) -> void:
	_decisions_today = data.get("decisions_today", 0)
	_last_recruit_visitor = data.get("last_recruit_visitor", 0)
	_last_food_check = data.get("last_food_check", 0)
	_last_diplomacy = data.get("last_diplomacy", 0)
	_last_bandit_raid = data.get("last_bandit_raid", 0)
	_current_day = data.get("current_day", -1)
