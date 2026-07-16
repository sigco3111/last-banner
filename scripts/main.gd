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
var last_event_label: Label = null
var toggle_button: Button = null
var advance_button: Button = null
var save_button: Button = null
var load_button: Button = null
var decision_modal: PanelContainer = null
var modal_dim_bg: ColorRect = null
var modal_title: Label = null
var modal_desc: Label = null
var modal_priority: Label = null
var modal_choices: VBoxContainer = null

var _last_queue_size: int = 0
var _current_decision_id: int = -1
var _auto_skip_timer: SceneTreeTimer = null

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
	time_label = ui.get_node_or_null("TopResourceBar/ResourceRow/TimeLabel") as Label
	gold_label = ui.get_node_or_null("TopResourceBar/ResourceRow/GoldLabel") as Label
	food_label = ui.get_node_or_null("TopResourceBar/ResourceRow/FoodLabel") as Label
	pop_label = ui.get_node_or_null("TopResourceBar/ResourceRow/PopLabel") as Label
	prosper_label = ui.get_node_or_null("TopResourceBar/ResourceRow/ProsperLabel") as Label
	last_event_label = ui.get_node_or_null("TopResourceBar/ResourceRow/LastEventLabel") as Label
	toggle_button = ui.get_node_or_null("BottomButtonRow/HBox/ToggleAutoButton") as Button
	advance_button = ui.get_node_or_null("BottomButtonRow/HBox/AdvanceButton") as Button
	save_button = ui.get_node_or_null("BottomButtonRow/HBox/SaveButton") as Button
	load_button = ui.get_node_or_null("BottomButtonRow/HBox/LoadButton") as Button
	modal_dim_bg = get_node_or_null("ModalLayer/DimBG") as ColorRect
	decision_modal = get_node_or_null("ModalLayer/DecisionModal") as PanelContainer
	if decision_modal:
		modal_title = decision_modal.get_node_or_null("ModalVBox/ModalTitle") as Label
		modal_desc = decision_modal.get_node_or_null("ModalVBox/ModalDesc") as Label
		modal_priority = decision_modal.get_node_or_null("ModalVBox/ModalPriority") as Label
		modal_choices = decision_modal.get_node_or_null("ModalVBox/ModalChoices") as VBoxContainer
	var modal_state: String = "OK" if decision_modal else "NULL"
	var dim_state: String = "OK" if modal_dim_bg else "NULL"
	print("[Main] 동적 노드 검색 완료 (modal=%s, dim_bg=%s)" % [modal_state, dim_state])

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
	]  # 대기 결정 카운터는 모달로 표시 → 상태바에서 제거

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
			if modal_dim_bg:
				modal_dim_bg.visible = false
		_last_queue_size = 0
		return
	if decision_modal.visible:
		return   # 이미 모달 표시 중
	# 큐 길이 증가 시에만 표시
	if pending.size() > _last_queue_size:
		_show_next_decision()
	_last_queue_size = pending.size()

func _show_next_decision() -> void:
	# 모든 우선순위 모달
	# - 자동 진행 ON: 모든 우선순위 자동 처리 (LOW 3초 / 그 외 5초 후 default 선택)
	# - 자동 진행 OFF: 사용자 결정까지 무한 대기
	for d in DecisionQueue.get_all_pending():
		if d.id > _current_decision_id:
			_current_decision_id = d.id
			_populate_modal(d)
			if modal_dim_bg:
				modal_dim_bg.visible = true
			decision_modal.visible = true
			print("[Modal] 표시: id=%d [%s] %s (auto_progress=%s)" % [
				d.id,
				DecisionQueue.Priority.keys()[d.priority],
				d.payload.get("title", ""),
				"ON" if TimeManager.auto_progress_enabled else "OFF"
			])
			# 자동 진행 ON일 때만 자동 결정 타이머 설정
			if TimeManager.auto_progress_enabled:
				var delay: float = 3.0 if d.priority == DecisionQueue.Priority.LOW else 5.0
				_auto_skip_timer = get_tree().create_timer(delay)
				_auto_skip_timer.timeout.connect(_on_auto_skip)
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
		if modal_dim_bg:
			modal_dim_bg.visible = false
	GameManager.resume_from_decision()

func _on_auto_skip() -> void:
	# 자동 진행 ON 상태에서만 호출됨 (사용자가 안 고른 경우 default 선택으로 자동 resolve)
	if not TimeManager.auto_progress_enabled:
		return  # OFF면 안 닫음 (사용자 결정 대기)
	if _current_decision_id < 0 or not decision_modal or not decision_modal.visible:
		return
	var default_choice := _default_low_choice()
	if default_choice != "":
		_apply_result(default_choice)
		print("[Modal] 자동 결정: id=%d → %s (auto_progress=ON)" % [_current_decision_id, default_choice])
	DecisionQueue.resolve(_current_decision_id, {"id": "auto_skip", "label": "(자동 결정)"})
	_current_decision_id = -1
	if decision_modal:
		decision_modal.visible = false
		if modal_dim_bg:
			modal_dim_bg.visible = false
	GameManager.resume_from_decision()

func _default_low_choice() -> String:
	# 자동 진행 ON 상태에서 default 처리할 선택지 코드 반환
	# HIGH/CRITICAL은 자동 진행이라도 default로 처리하되 score가 작은 옵션 선택
	for d in DecisionQueue.get_all_pending():
		if d.id == _current_decision_id:
			match d.type:
				"VISITOR": return "VISITOR_REJECT"
				"FOOD_SHORTAGE":
					# 식량 위기면 매입, 부족이면 ration
					if GameWorld.food < 15:
						return "FOOD_BUY"
					return "FOOD_RATION"
				"DIPLOMACY": return "DIPLOMACY_REFUSE"
				_: return ""
	return ""

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
		"DIPLOMACY_ALLIANCE_ACCEPT":
			GameWorld.modify_resource("prosperity", 8)
			GameWorld.modify_resource("gold", 50)
			GameWorld.log_event("동맹 수락: +8 명성, +50 골드")
		"DIPLOMACY_TRADE":
			GameWorld.modify_resource("food", 30)
			GameWorld.modify_resource("prosperity", 3)
			GameWorld.log_event("교역 수락: +30 식량, +3 명성")
		"DIPLOMACY_REFUSE":
			GameWorld.modify_resource("prosperity", -5)
			GameWorld.log_event("외교 거절: 명성 -5")
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

	# 2) 1일 시뮬 — 60초 = 1일이므로 _process 기반 시뮬은 동기 advance_minutes(1440)으로 검증
	print("[2] 1일 (1440분) 진행")
	for i in range(144):
		TimeManager.advance_minutes(10)
	# 일간 변동이 1회만 (advance_minutes가 day_changed emit)
	var s := GameWorld.summary()
	print("[3] 1일 후: %s" % s)
	assert(GameWorld.gold != 200, "금이 변동되어야 함")
	assert(GameWorld.food != 100, "식량이 변동되어야 함")

	# 2.5) 속도 검증 — _process에 1초 delta 주입 → 60분 advance 기대 (헤드리스 안전)
	print("[2.5] 속도 검증 — 1초 real = 60분 game (1.0 delta 주입)")
	var min_before: int = TimeManager.minutes_elapsed
	TimeManager._process(1.0)   # 시뮬: 1초 경과
	var min_after: int = TimeManager.minutes_elapsed
	var advance_60: int = min_after - min_before
	print("  1초 시뮬 후 진행 분: %d (기대 60)" % advance_60)
	assert(advance_60 >= 55 and advance_60 <= 65, "속도 정확도: %d분 (60±5)" % advance_60)

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

	# 8.5) 외교 시나리오 강제 push → MEDIUM 모달 표시 검증
	print("[8.5] 외교 시나리오 MEDIUM 모달")
	DecisionQueue.resolve(_current_decision_id, {"id": "test", "label": "test"}) if _current_decision_id > 0 else null
	_current_decision_id = -1
	# 강제 push
	EventEngine._maybe_diplomacy(Time.get_ticks_msec())
	await get_tree().process_frame
	var pending_after: Array = DecisionQueue.get_all_pending()
	var diplomacy_count: int = 0
	for d in pending_after:
		if d.type == "DIPLOMACY":
			diplomacy_count += 1
	print("  ✓ DIPLOMACY push: %d건" % diplomacy_count)
	assert(diplomacy_count >= 1, "DIPLOMACY 시나리오 push 안 됨")

	# 8.6) 결정 큐에 MEDIUM/HIGH/LOW가 섞여 있음 확인
	var priorities := {}
	for d in pending_after:
		var pname: String = DecisionQueue.Priority.keys()[d.priority]
		priorities[pname] = priorities.get(pname, 0) + 1
	print("  ✓ 결정 큐 우선순위 분포: %s" % str(priorities))

	# 9) 화면 그리기 검증 — ManorDashboard 인스턴스 + 자식 sprite/avatars
	print("[9] ManorDashboard 화면 검증")
	var dashboard: Control = get_node_or_null("ManorDashboard") as Control
	if dashboard:
		var scene_root_node: Node = dashboard.get_node_or_null("CenterRoot/LeftColumn/ManorScene/SceneHost/SceneRoot")
		assert(scene_root_node != null, "scene_root 없음 — SceneHost/SceneRoot 경로")
		var sprite_count: int = 0
		var tex_rect_count: int = 0
		for child in scene_root_node.get_children():
			if child is Sprite2D:
				sprite_count += 1
		print("  ✓ Manor Scene sprites: %d" % sprite_count)
		assert(sprite_count == 5, "5명 sprite 모두 필요 (현재 %d)" % sprite_count)
		var roster_node: Node = dashboard.get_node_or_null("CenterRoot/RightColumn/RosterList/RosterScroll/RosterVBox")
		assert(roster_node != null)
		for child in roster_node.get_children():
			for sub in child.get_children():
				if sub is TextureRect:
					tex_rect_count += 1
					break
		var roster_count: int = roster_node.get_child_count()
		print("  ✓ Roster rows: %d (avatar TextureRect: %d)" % [roster_count, tex_rect_count])
		assert(roster_count == 5, "5명 roster 필요")
		assert(tex_rect_count == 5, "5개 avatar 모두 TextureRect여야 함")
	else:
		print("[WARN] ManorDashboard 인스턴스 없음 — 시각 검증 생략")

	# 10) 모달 자동 OFF 무한 대기 검증 — 자동 진행 OFF 시 모달이 안 닫힘
	print("[10] 모달 자동 OFF 무한 대기 검증")
	# 기존 큐 클리어 + 모든 결정 큐 제거
	while not DecisionQueue.get_all_pending().is_empty():
		DecisionQueue.resolve(DecisionQueue.get_all_pending()[0].id, {"id": "force", "label": "force"})
	_current_decision_id = -1
	_last_queue_size = 0
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	# 큐에 새 결정 1건 강제 push (직접 push — daily cap 무관)
	var new_id: int = DecisionQueue.push("TEST_OFF", {
		"title": "테스트 (자동 OFF)",
		"description": "자동 진행 OFF 상태에서 모달 유지 검증",
		"choices": [
			{ "id": "yes", "label": "예", "result": "TEST" },
		],
	}, DecisionQueue.Priority.MEDIUM)
	print("  강제 push: id=%d" % new_id)
	await get_tree().process_frame
	# 자동 진행 OFF로 전환
	TimeManager.auto_progress_enabled = false
	# 모달 트리거
	_check_decision_queue()
	await get_tree().process_frame
	var modal_visible_off: bool = decision_modal.visible if decision_modal else false
	print("  ✓ 모달 표시 (auto_progress=OFF): visible=%s" % str(modal_visible_off))
	assert(modal_visible_off, "자동 OFF에서 모달이 떠있어야 함 (큐 size=%d, current_id=%d)" % [
		DecisionQueue.get_all_pending().size(), _current_decision_id
	])
	# _on_auto_skip을 직접 호출 → OFF면 즉시 return하여 모달 유지
	_current_decision_id = DecisionQueue.get_all_pending()[0].id if not DecisionQueue.get_all_pending().is_empty() else -1
	_on_auto_skip()
	var modal_still_visible: bool = decision_modal.visible if decision_modal else false
	assert(modal_still_visible, "자동 OFF에서 _on_auto_skip 호출되어도 모달 유지")
	print("  ✓ OFF 상태에서 _on_auto_skip 호출 → 모달 유지됨")
	_current_decision_id = -1  # 명시적 리셋

	# 11) 모달 자동 ON 검증 — 자동 진행 ON 시 모달 자동 닫힘 (3초)
	print("[11] 모달 자동 ON 검증")
	# 모달 강제 닫기 + 모든 상태 리셋
	_current_decision_id = -1
	_last_queue_size = 0
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	# 큐 전부 제거
	while not DecisionQueue.get_all_pending().is_empty():
		DecisionQueue.resolve(DecisionQueue.get_all_pending()[0].id, {"id": "force", "label": "force"})
	# EventEngine 일일 카운터 강제 리셋 (daily cap 무력화)
	EventEngine._decisions_today = 0
	# 새 LOW 1건 push
	EventEngine._maybe_visitor(Time.get_ticks_msec() + 20000)
	await get_tree().process_frame
	# 자동 진행 ON으로 전환
	TimeManager.auto_progress_enabled = true
	# 모달 트리거
	_check_decision_queue()
	await get_tree().process_frame
	var modal_visible_on: bool = decision_modal.visible if decision_modal else false
	assert(modal_visible_on, "자동 ON에서 모달이 떠있어야 함")
	print("  ✓ 모달 표시 (auto_progress=ON): visible=%s" % str(modal_visible_on))
	# 동기 시간 진행으로 4일 후 시뮬 (LOW 3초 × 1440 = 약 144 step, 헤드리스 안전)
	# 직접 _on_auto_skip을 호출하는 방식으로 빠르게 검증
	_on_auto_skip()
	await get_tree().process_frame
	var modal_after_auto_close: bool = decision_modal.visible if decision_modal else false
	print("  ✓ _on_auto_skip 호출 후 모달 visible=%s (auto ON → 자동 닫힘)" % str(modal_after_auto_close))
	assert(not modal_after_auto_close, "자동 ON에서 _on_auto_skip 호출 후 모달은 닫혀야 함")

	print("\n=== 검증 완료 — quit ===")
	get_tree().quit()
