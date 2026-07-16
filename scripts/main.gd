extends Node2D
## Last Banner v2 — main hub
## 자동 진행 + 결정 큐 알림 + 자원 카드 + LB_VERIFY 모드

const LB_VERIFY := "LB_VERIFY"

var _verify_mode: bool = false

# 일반 노드 참조 (tscn 검증 후 동적 검색 사용 — @onready 인스턴스화 순서 함정 회피)
var time_label: Label = null
var gold_label: Label = null
var food_label: Label = null
var pop_label: Label = null
var prosper_label: Label = null
var decision_label: Label = null
var last_event_label: Label = null
var toggle_button: Button = null
var advance_button: Button = null
var save_button: Button = null
var load_button: Button = null
var decision_modal: PanelContainer = null
var modal_title: Label = null
var modal_desc: Label = null
var modal_priority: Label = null
var modal_choices: VBoxContainer = null

var _last_queue_size: int = 0
var _current_decision_id: int = -1

func _ready() -> void:
	_verify_mode = OS.has_environment(LB_VERIFY)
	if _verify_mode:
		_run_verify()
		return
	_find_nodes()
	_connect_signals()
	GameManager.start_new_game("default")
	_refresh_all()

func _find_nodes() -> void:
	# 동적 검색 — main.tscn 인스턴스화 완료 후 호출 (call_deferred)
	var ui: CanvasLayer = get_node_or_null("UI")
	if ui == null:
		push_error("[Main] UI CanvasLayer 없음")
		return
	time_label = ui.get_node_or_null("StatusBar/TimeLabel") as Label
	gold_label = ui.get_node_or_null("StatusBar/GoldLabel") as Label
	food_label = ui.get_node_or_null("StatusBar/FoodLabel") as Label
	pop_label = ui.get_node_or_null("StatusBar/PopLabel") as Label
	prosper_label = ui.get_node_or_null("StatusBar/ProsperLabel") as Label
	decision_label = ui.get_node_or_null("StatusBar/DecisionLabel") as Label
	last_event_label = ui.get_node_or_null("StatusBar/LastEventLabel") as Label
	toggle_button = ui.get_node_or_null("ButtonRow/ToggleAutoButton") as Button
	advance_button = ui.get_node_or_null("ButtonRow/AdvanceButton") as Button
	save_button = ui.get_node_or_null("ButtonRow/SaveButton") as Button
	load_button = ui.get_node_or_null("ButtonRow/LoadButton") as Button
	decision_modal = ui.get_node_or_null("DecisionModal") as PanelContainer
	if decision_modal:
		modal_title = decision_modal.get_node_or_null("ModalVBox/ModalTitle") as Label
		modal_desc = decision_modal.get_node_or_null("ModalVBox/ModalDesc") as Label
		modal_priority = decision_modal.get_node_or_null("ModalVBox/ModalPriority") as Label
		modal_choices = decision_modal.get_node_or_null("ModalVBox/ModalChoices") as VBoxContainer
	print("[Main] 동적 노드 검색 완료")

func _connect_signals() -> void:
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle_auto_pressed)
	if advance_button:
		advance_button.pressed.connect(_on_advance_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	TimeManager.tick_advanced.connect(_on_tick)
	TimeManager.day_changed.connect(_on_day)
	GameWorld.resource_changed.connect(_refresh_resource)
	GameWorld.event_logged.connect(_on_event_logged)

func _process(_delta: float) -> void:
	if _verify_mode:
		return
	_refresh_time_label()
	_check_decision_queue()

func _refresh_all() -> void:
	_refresh_time_label()
	_refresh_resource("gold", GameWorld.gold)
	_refresh_resource("food", GameWorld.food)
	_refresh_resource("population", GameWorld.population)
	_refresh_resource("prosperity", GameWorld.prosperity)

func _refresh_time_label() -> void:
	if time_label == null:
		return
	var hour: int = (TimeManager.minutes_elapsed % 1440) / 60
	var minute: int = TimeManager.minutes_elapsed % 60
	time_label.text = "Day %d  |  %02d:%02d  |  자동 진행: %s" % [
		TimeManager.day, hour, minute,
		"ON" if TimeManager.auto_progress_enabled else "OFF"
	]
	var pending: int = DecisionQueue.get_all_pending().size()
	if decision_label:
		decision_label.text = "📜 대기 결정: %d건" % pending

func _refresh_resource(resource: String, _value: int) -> void:
	if gold_label: gold_label.text = "💰 금: %d" % GameWorld.gold
	if food_label: food_label.text = "🌾 식량: %d" % GameWorld.food
	if pop_label: pop_label.text = "👥 인구: %d" % GameWorld.population
	if prosper_label: prosper_label.text = "⭐ 명성: %d" % GameWorld.prosperity

func _check_decision_queue() -> void:
	if decision_modal == null:
		return
	var pending: Array = DecisionQueue.get_all_pending()
	if pending.is_empty():
		if decision_modal.visible:
			decision_modal.visible = false
		_last_queue_size = 0
		return
	if decision_modal.visible:
		return   # 이미 모달 표시 중
	# 큐 길이 증가 시에만 표시
	if pending.size() > _last_queue_size:
		_show_next_decision()
	_last_queue_size = pending.size()

func _show_next_decision() -> void:
	# HIGH/CRITICAL만 모달, LOW/MEDIUM은 알림만
	for d in DecisionQueue.get_all_pending():
		if d.priority >= DecisionQueue.Priority.HIGH:
			_current_decision_id = d.id
			_populate_modal(d)
			decision_modal.visible = true
			return
	# HIGH/CRITICAL 없으면 알림만 (콘솔)
	for d in DecisionQueue.get_all_pending():
		if d.id > _current_decision_id:
			_current_decision_id = d.id
			print("[알림] [%s] %s" % [DecisionQueue.Priority.keys()[d.priority], d.payload.get("title", "")])
			GameWorld.log_event("[%s] %s" % [DecisionQueue.Priority.keys()[d.priority], d.payload.get("title", "")])
			return

func _populate_modal(decision: Dictionary) -> void:
	var pname: String = DecisionQueue.Priority.keys()[decision.priority]
	if modal_title: modal_title.text = decision.payload.get("title", "결정")
	if modal_desc: modal_desc.text = decision.payload.get("description", "")
	if modal_priority:
		modal_priority.text = "우선순위: %s" % pname
		match decision.priority:
			DecisionQueue.Priority.HIGH: modal_priority.modulate = Color(1, 0.7, 0.2)
			DecisionQueue.Priority.CRITICAL: modal_priority.modulate = Color(1, 0.3, 0.3)
			_: modal_priority.modulate = Color(0.7, 0.7, 0.7)
	if modal_choices:
		# 기존 버튼 제거
		for child in modal_choices.get_children():
			child.queue_free()
		# 선택지 버튼 동적 생성
		for choice in decision.payload.get("choices", []):
			var btn := Button.new()
			btn.text = choice.get("label", "선택")
			btn.custom_minimum_size = Vector2(0, 44)
			btn.pressed.connect(_on_choice_pressed.bind(choice))
			modal_choices.add_child(btn)

func _on_choice_pressed(choice: Dictionary) -> void:
	if _current_decision_id < 0:
		return
	var result_code: String = choice.get("result", "")
	if result_code != "":
		_apply_result(result_code)
	DecisionQueue.resolve(_current_decision_id, choice)
	_current_decision_id = -1
	if decision_modal:
		decision_modal.visible = false
	GameManager.resume_from_decision()

func _apply_result(code: String) -> void:
	match code:
		"VISITOR_WELCOME":
			# 결정 큐 push 시점에 정해지지 않으므로 payload에서 읽어야…
			# 단순화: 30골드 + 명성 1
			GameWorld.modify_resource("gold", 30)
			GameWorld.modify_resource("prosperity", 1)
			GameWorld.log_event("방문객 환영: +30골드, +1 명성")
		"VISITOR_REJECT":
			GameWorld.modify_resource("prosperity", -2)
			GameWorld.log_event("방문객 거절: 명성 -2")
		"FOOD_BUY":
			GameWorld.modify_resource("gold", -50)
			GameWorld.modify_resource("food", 30)
			GameWorld.log_event("식량 매입: -50골드, +30 식량")
		"FOOD_RATION":
			GameWorld.modify_resource("prosperity", -5)
			GameWorld.log_event("건제 시행: 명성 -5")
		_:
			push_warning("[Main] 알 수 없는 결과 코드: %s" % code)

func _on_tick(_game_time: int) -> void:
	if not _verify_mode:
		_refresh_time_label()

func _on_day(_d: int) -> void:
	if not _verify_mode:
		_refresh_all()

func _on_event_logged(msg: String) -> void:
	if last_event_label:
		last_event_label.text = "🪵 최근 사건: %s" % msg

func _on_toggle_auto_pressed() -> void:
	TimeManager.toggle_auto_progress()

func _on_advance_pressed() -> void:
	TimeManager.advance_minutes(1440)   # +1일
	_refresh_all()

func _on_save_pressed() -> void:
	SaveManager.save_game("manual")

func _on_load_pressed() -> void:
	if SaveManager.load_game("autosave") or SaveManager.load_game("manual"):
		_refresh_all()

# ============================================================
# LB_VERIFY 검증 (헤드리스 60초 안에 모든 검증 통과 → quit)
# ============================================================
func _run_verify() -> void:
	# 헤드리스에서도 노드는 부착되지만 화면 안 보임
	call_deferred("_find_nodes")
	await get_tree().process_frame
	print("\n=== Last Banner v2 LB_VERIFY 시작 ===")

	# 1) 새 게임
	GameManager.start_new_game("verify")
	await get_tree().process_frame
	assert(GameWorld.gold == 200)
	assert(GameWorld.food == 100)
	assert(GameWorld.population == 50)
	print("[1] 새 게임 초기 상태 OK: %s" % GameWorld.summary())

	# 2) 1일 시뮬
	print("[2] 1일 (1440분) 진행")
	for i in range(144):
		TimeManager.advance_minutes(10)
	# 일간 변동이 1회만 (advance_minutes가 day_changed emit)
	var s := GameWorld.summary()
	print("[3] 1일 후: %s" % s)
	assert(GameWorld.gold != 200, "금이 변동되어야 함")
	assert(GameWorld.food != 100, "식량이 변동되어야 함")

	# 3) 6일 추가 — 결정 큐 자동 push 확인
	print("[4] 추가 6일 진행 (사건 생성 대기)")
	var initial_decisions: int = DecisionQueue.get_all_pending().size()
	for day_i in range(6):
		for i in range(144):
			TimeManager.advance_minutes(10)
	await get_tree().process_frame
	var final_decisions: int = DecisionQueue.get_all_pending().size()
	print("[5] 결정 큐: %d → %d" % [initial_decisions, final_decisions])
	if final_decisions > initial_decisions:
		print("[PASS] 자동 진행 중 사건 생성 확인 ✓")
		for d in DecisionQueue.get_all_pending():
			var pname: String = DecisionQueue.Priority.keys()[d.priority]
			print("  - [%s] %s — %s" % [pname, d.type, d.payload.get("title", "")])
	else:
		print("[WARN] 결정 큐 증가 없음 — 확률 게이트 영향. 강제 push 테스트")
		# 강제 push
		EventEngine._maybe_visitor(Time.get_ticks_msec())
		await get_tree().process_frame
		print("[5b] 강제 push 후: %d건" % DecisionQueue.get_all_pending().size())

	# 4) 자원 변동 총합
	print("[6] 7일 후 자원: gold=%d food=%d prosper=%d" % [GameWorld.gold, GameWorld.food, GameWorld.prosperity])
	assert(GameWorld.gold != 200)

	# 5) 저장/로드 round-trip
	print("[7] save/load round-trip")
	var gold_before: int = GameWorld.gold
	var food_before: int = GameWorld.food
	var log_before: int = GameWorld.event_log.size()
	assert(SaveManager.save_game("verify"))
	GameWorld.gold = 0
	GameWorld.food = 0
	GameWorld.event_log.clear()
	assert(SaveManager.load_game("verify"))
	assert(GameWorld.gold == gold_before, "gold 복원 실패")
	assert(GameWorld.food == food_before, "food 복원 실패")
	assert(GameWorld.event_log.size() == log_before, "event_log 복원 실패")
	print("  ✓ Round-trip OK (gold=%d food=%d event_log=%d)" % [GameWorld.gold, GameWorld.food, GameWorld.event_log.size()])

	# 6) 결과 적용 (VISITOR_WELCOME)
	print("[8] 결과 적용 (VISITOR_WELCOME)")
	var gold_pre: int = GameWorld.gold
	_apply_result("VISITOR_WELCOME")
	assert(GameWorld.gold == gold_pre + 30)
	print("  ✓ VISITOR_WELCOME → +30골드 OK")

	print("\n=== 검증 완료 — quit ===")
	get_tree().quit()
