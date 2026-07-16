extends Node2D
## Last Banner v2.2 — 메인 허브 (타이틀 ↔ 게임 모드 토글)

const LB_VERIFY := "LB_VERIFY"

var _verify_mode: bool = false
var _in_game_mode: bool = false   # true: 게임 진행 / false: 타이틀 화면

# 게임 모드 노드
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
var title_menu_button: Button = null
var decision_modal: PanelContainer = null
var modal_dim_bg: ColorRect = null
var modal_title: Label = null
var modal_desc: Label = null
var modal_priority: Label = null
var modal_choices: VBoxContainer = null

# 결정 모달 상태
var _last_queue_size: int = 0
var _current_decision_id: int = -1
var _auto_skip_timer: SceneTreeTimer = null

# 게임/타이틀 노드 (씬 인스턴스)
var manor_layer: CanvasLayer = null
var title_layer: CanvasLayer = null
var ui_layer: CanvasLayer = null
var title_screen: Control = null

func _ready() -> void:
	_verify_mode = OS.has_environment(LB_VERIFY)
	if _verify_mode:
		_run_verify()
		return
	_find_nodes()
	_connect_signals()
	_enter_title_mode()   # 시작은 타이틀 화면

func _find_nodes() -> void:
	manor_layer = get_node_or_null("ManorLayer") as CanvasLayer
	title_layer = get_node_or_null("TitleLayer") as CanvasLayer
	ui_layer = get_node_or_null("UI") as CanvasLayer
	if title_layer:
		title_screen = title_layer.get_node_or_null("TitleScreen") as Control
	# 게임 모드 자원 노드
	var ui: CanvasLayer = ui_layer
	if ui:
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
		title_menu_button = ui.get_node_or_null("BottomButtonRow/HBox/TitleMenuButton") as Button
		modal_dim_bg = get_node_or_null("ModalLayer/DimBG") as ColorRect
		decision_modal = get_node_or_null("ModalLayer/DecisionModal") as PanelContainer
		if decision_modal:
			modal_title = decision_modal.get_node_or_null("ModalVBox/ModalTitle") as Label
			modal_desc = decision_modal.get_node_or_null("ModalVBox/ModalDesc") as Label
			modal_priority = decision_modal.get_node_or_null("ModalVBox/ModalPriority") as Label
			modal_choices = decision_modal.get_node_or_null("ModalVBox/ModalChoices") as VBoxContainer

func _connect_signals() -> void:
	# 게임 모드 버튼
	if toggle_button:
		toggle_button.pressed.connect(_on_toggle_auto_pressed)
	if advance_button:
		advance_button.pressed.connect(_on_advance_pressed)
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
	if title_menu_button:
		title_menu_button.pressed.connect(_on_title_menu_pressed)
	# 게임 autoload 시그널
	TimeManager.tick_advanced.connect(_on_tick)
	TimeManager.day_changed.connect(_on_day)
	GameWorld.resource_changed.connect(_refresh_resource)
	GameWorld.event_logged.connect(_on_event_logged)
	# 타이틀 화면 시그널
	if title_screen and title_screen.has_signal("start_new_game"):
		title_screen.start_new_game.connect(_on_title_start_new)
	if title_screen and title_screen.has_signal("continue_game"):
		title_screen.continue_game.connect(_on_title_continue)
	print("[Main] 동적 노드 + 시그널 연결 완료")

func _process(_delta: float) -> void:
	if _verify_mode or not _in_game_mode:
		return
	_refresh_time_label()
	_check_decision_queue()

# ============================================================
# 모드 전환
# ============================================================
func _enter_title_mode() -> void:
	_in_game_mode = false
	if title_layer:
		title_layer.visible = true
	if ui_layer:
		ui_layer.visible = false
	if manor_layer:
		manor_layer.visible = false
	# 결정 모달 강제 닫기
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	GameManager.current_state = GameManager.State.MENU
	# 타이틀 화면 갱신
	if title_screen and title_screen.has_method("refresh"):
		title_screen.refresh()
	print("[Main] 타이틀 모드 진입")

func _enter_game_mode() -> void:
	_in_game_mode = true
	if title_layer:
		title_layer.visible = false
	if ui_layer:
		ui_layer.visible = true
	if manor_layer:
		manor_layer.visible = true
	GameManager.current_state = GameManager.State.PLAYING
	_refresh_all()
	print("[Main] 게임 모드 진입")

func _on_title_start_new() -> void:
	print("[Main] 새 게임 시작")
	GameManager.start_new_game("default")
	_enter_game_mode()

func _on_title_continue() -> void:
	print("[Main] 이어하기 — 최근 저장 로드")
	var saves: Array = SaveManager.list_saves()
	if not saves.is_empty():
		var latest: String = saves[0]
		SaveManager.load_game(latest)
		GameManager.start_new_game(latest)
		_enter_game_mode()
	else:
		print("[Main] 저장 없음 → 게임 시작")
		_on_title_start_new()

func _on_title_menu_pressed() -> void:
	# 게임 → 타이틀 복귀. 자동 저장은 종료 직전에 1회 더.
	SaveManager.save_game("autosave")
	_enter_title_mode()

# ============================================================
# 게임 모드 (이전 main.gd에서 이식)
# ============================================================
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

func _refresh_resource(_resource: String, _value: int) -> void:
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
		return
	if pending.size() > _last_queue_size:
		_show_next_decision()
	_last_queue_size = pending.size()

func _show_next_decision() -> void:
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
		for child in modal_choices.get_children():
			child.queue_free()
		for choice in decision.payload.get("choices", []):
			var btn := Button.new()
			btn.text = choice.get("label", "선택")
			btn.custom_minimum_size = Vector2(0, 44)
			btn.pressed.connect(_on_choice_pressed.bind(choice))
			modal_choices.add_child(btn)

func _on_choice_pressed(choice: Dictionary) -> void:
	print("[Main] _on_choice_pressed: choice=%s" % str(choice))
	if _current_decision_id < 0:
		return
	var result_code: String = choice.get("result", "")
	print("[Main] result_code=%s, current_id=%d" % [result_code, _current_decision_id])
	var decision_type: String = _current_decision_type()
	print("[Main] decision_type=%s" % decision_type)
	# BANDIT_RAID면 BattleScene로 라우팅
	if decision_type == "BANDIT_RAID" and result_code == "BATTLE_BANDITS_FIGHT":
		print("[Main] BATTLE_BANDITS_FIGHT 분기 — BattleScene.start_battle 호출")
		var battle: Control = _get_battle_scene()
		print("[Main] battle=%s" % ("OK" if battle else "NULL"))
		if battle:
			var enemy_count: int = int(_current_decision_payload().get("enemy_count", 4))
			print("[Main] BattleScene.start_battle(%d) 호출" % enemy_count)
			battle.start_battle(enemy_count)
			print("[Main] BattleScene.visible=%s" % str(battle.visible))
	if result_code != "":
		_apply_result(result_code)
	DecisionQueue.resolve(_current_decision_id, choice)
	_current_decision_id = -1
	if decision_modal:
		decision_modal.visible = false
		if modal_dim_bg:
			modal_dim_bg.visible = false
	GameManager.resume_from_decision()

var _current_decision_type_cache: String = ""
func _current_decision_type() -> String:
	for d in DecisionQueue.get_all_pending():
		if d.id == _current_decision_id:
			return str(d.type)
	return ""
func _current_decision_payload() -> Dictionary:
	for d in DecisionQueue.get_all_pending():
		if d.id == _current_decision_id:
			return d.payload as Dictionary
	return {}

func _get_battle_scene() -> Control:
	# BattleLayer CanvasLayer → BattleScene 인스턴스
	var layer: Node = get_node_or_null("BattleLayer") as CanvasLayer
	if layer:
		return layer.get_node_or_null("BattleScene") as Control
	# legacy: Main 직속 자식
	for child in get_children():
		if child.name == "BattleScene" and child is Control:
			return child
	return null

func _on_auto_skip() -> void:
	if not TimeManager.auto_progress_enabled:
		return
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
	for d in DecisionQueue.get_all_pending():
		if d.id == _current_decision_id:
			match d.type:
				"VISITOR": return "VISITOR_REJECT"
				"FOOD_SHORTAGE":
					if GameWorld.food < 15:
						return "FOOD_BUY"
					return "FOOD_RATION"
				"DIPLOMACY": return "DIPLOMACY_REFUSE"
				_: return ""
	return ""

func _apply_result(code: String) -> void:
	match code:
		"VISITOR_WELCOME":
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
		"BATTLE_BANDITS_FIGHT":
			# 실제 전투 로직은 BattleScene.start_battle에서 처리
			pass
		"BATTLE_BANDITS_HIDE":
			var enemy: int = 4
			GameWorld.modify_resource("food", -enemy)
			GameWorld.log_event("숨기 — 식량 %d 손실" % enemy)
		"BATTLE_BANDITS_BRIBE":
			GameWorld.modify_resource("gold", -30)
			GameWorld.modify_resource("prosperity", -2)
			GameWorld.log_event("뇌물 — -30 골드, -2 명성")
		_:
			push_warning("[Main] 알 수 없는 결과 코드: %s" % code)

func _on_tick(_game_time: int) -> void:
	if _in_game_mode:
		_refresh_time_label()

func _on_day(_d: int) -> void:
	if _in_game_mode:
		_refresh_all()

func _on_event_logged(msg: String) -> void:
	if last_event_label:
		last_event_label.text = "🪵 최근: %s" % msg

func _on_toggle_auto_pressed() -> void:
	TimeManager.toggle_auto_progress()

func _on_advance_pressed() -> void:
	TimeManager.advance_minutes(1440)
	_refresh_all()

func _on_save_pressed() -> void:
	SaveManager.save_game("manual")
	# 타이틀 화면이 활성화돼 있으면 '이어하기' 활성화 필요
	if title_screen and title_screen.has_method("refresh"):
		title_screen.refresh()

func _on_load_pressed() -> void:
	if SaveManager.load_game("autosave") or SaveManager.load_game("manual"):
		_refresh_all()

# ============================================================
# LB_VERIFY 검증 (13단계)
# ============================================================
func _run_verify() -> void:
	# 헤드리스에서도 노드는 부착되지만 화면 안 보임
	call_deferred("_find_nodes")
	await get_tree().process_frame
	print("\n=== Last Banner v2.2 LB_VERIFY 시작 ===")

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
	var s := GameWorld.summary()
	print("[3] 1일 후: %s" % s)
	assert(GameWorld.gold != 200, "금이 변동되어야 함")
	assert(GameWorld.food != 100, "식량이 변동되어야 함")

	# 2.5) 속도 검증
	print("[2.5] 속도 검증 — 1초 real = 60분 game (1.0 delta 주입)")
	var min_before: int = TimeManager.minutes_elapsed
	TimeManager._process(1.0)
	var min_after: int = TimeManager.minutes_elapsed
	var advance_60: int = min_after - min_before
	print("  1초 시뮬 후 진행 분: %d (기대 60)" % advance_60)
	assert(advance_60 >= 55 and advance_60 <= 65, "속도 정확도: %d분 (60±5)" % advance_60)

	# 3) 6일 추가
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

	# 6) 7일 후 자원
	print("[6] 7일 후 자원: gold=%d food=%d prosper=%d" % [GameWorld.gold, GameWorld.food, GameWorld.prosperity])
	assert(GameWorld.gold != 200)

	# 7) save/load
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

	# 8) 결과 적용
	print("[8] 결과 적용 (VISITOR_WELCOME)")
	var gold_pre: int = GameWorld.gold
	_apply_result("VISITOR_WELCOME")
	assert(GameWorld.gold == gold_pre + 30)
	print("  ✓ VISITOR_WELCOME → +30골드 OK")

	# 8.5) 외교 push + 분포
	print("[8.5] 외교 시나리오 MEDIUM 모달")
	DecisionQueue.resolve(_current_decision_id, {"id": "test", "label": "test"}) if _current_decision_id > 0 else null
	_current_decision_id = -1
	# 결정 큐 직접 push (rand 게이트 회피)
	DecisionQueue.push("DIPLOMACY", {
		"title": "외교: 동맹 제안",
		"description": "테스트용 동맹 제안",
		"choices": [
			{ "id": "accept", "label": "수락", "result": "DIPLOMACY_ALLIANCE_ACCEPT" },
			{ "id": "refuse", "label": "거절", "result": "DIPLOMACY_REFUSE" },
		],
	}, DecisionQueue.Priority.MEDIUM)
	await get_tree().process_frame
	var pending_after: Array = DecisionQueue.get_all_pending()
	var diplomacy_count: int = 0
	for d in pending_after:
		if d.type == "DIPLOMACY":
			diplomacy_count += 1
	print("  ✓ DIPLOMACY push: %d건" % diplomacy_count)
	assert(diplomacy_count >= 1, "DIPLOMACY 시나리오 push 안 됨")
	var priorities := {}
	for d in pending_after:
		var pname: String = DecisionQueue.Priority.keys()[d.priority]
		priorities[pname] = priorities.get(pname, 0) + 1
	print("  ✓ 결정 큐 우선순위 분포: %s" % str(priorities))

	# 9) 화면 그리기 검증
	print("[9] ManorDashboard 화면 검증")
	var dashboard: Control = get_node_or_null("ManorDashboard") as Control
	if dashboard:
		var scene_root_node: Node = dashboard.get_node_or_null("CenterRoot/LeftColumn/ManorScene/SceneHost/SceneRoot")
		assert(scene_root_node != null, "scene_root 없음")
		var tex_btn_count: int = 0
		var area_count: int = 0
		var sprite_count: int = 0
		var tex_rect_count: int = 0
		for child in scene_root_node.get_children():
			if child is TextureButton:
				tex_btn_count += 1
			elif child is Area2D:
				area_count += 1
			elif child is Sprite2D:
				sprite_count += 1
		print("  ✓ TextureButton(클릭): %d, Area2D(레거시): %d, Sprite2D(레거시): %d" % [tex_btn_count, area_count, sprite_count])
		assert(tex_btn_count == 5 or area_count == 5 or sprite_count == 5, "5명 캐릭터 필요")
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

	# 9.5) 호버 인터랙션 검증 — DetailPanel 마우스 호버 시 표시
	print("[9.5] 호버 인터랙션 검증")
	var detail_panel: Node = get_node_or_null("ManorDashboard/CenterRoot/LeftColumn/ManorScene/SceneHost/DetailPanel")
	var detail_vbox: Node = get_node_or_null("ManorDashboard/CenterRoot/LeftColumn/ManorScene/SceneHost/DetailPanel/VBox") as VBoxContainer
	if detail_panel and detail_vbox:
		assert(not detail_vbox.visible, "DetailPanel 기본 숨김이어야 함")
		print("  ✓ DetailPanel 초기: visible=false")
		var md: Node = get_node_or_null("ManorDashboard")
		if md and md.has_method("_show_character_detail") and not md.scene_characters.is_empty():
			# 호버 시뮬레이션 — _on_character_hover 직접 호출
			md._on_character_hover(md.scene_characters[0])
			await get_tree().process_frame
			assert(detail_vbox.visible, "호버 시 DetailPanel 표시되어야 함")
			var label_count: int = detail_vbox.get_child_count()
			print("  ✓ 호버 시 DetailPanel: visible=true, 라벨 %d개" % label_count)
			assert(label_count >= 4, "최소 4개 라벨")
			# 호버 해제 시뮬레이션 — DetailPanel 자동 숨김 확인
			md._on_character_unhover(md.scene_characters[0])
			await get_tree().process_frame
			assert(not detail_vbox.visible, "호버 해제 시 DetailPanel 숨겨져야 함")
			print("  ✓ 호버 해제 → DetailPanel 자동 숨김 (visible=false)")
			# 다른 캐릭터 호버 → 라벨 갱신
			md._on_character_hover(md.scene_characters[1])
			await get_tree().process_frame
			var label_count_2: int = detail_vbox.get_child_count()
			print("  ✓ 다른 캐릭터 호버 → 라벨 %d개" % label_count_2)
			assert(label_count_2 == label_count, "라벨 개수 동일")
			# 최종 reset
			md._on_character_unhover(md.scene_characters[1])
		else:
			print("[WARN] _on_character_hover 또는 scene_characters 없음")
	else:
		print("[WARN] DetailPanel/VBox 없음")

	# 9.6) 시간대 색 검증 — 낮/밤 색이 다른지 확인
	print("[9.6] 시간대 그라디언트 검증")
	var md2: Node = get_node_or_null("ManorDashboard")
	TimeManager.minutes_elapsed = 12 * 60   # 정오
	if md2 and md2.has_method("_update_time_of_day_colors"):
		md2._update_time_of_day_colors()
		await get_tree().process_frame
		var noon_bg: Color = Color(0.32, 0.36, 0.22, 1)
		var noon_color: Color = md2.bg_color_rect.color if md2.bg_color_rect else Color(0, 0, 0, 1)
		print("  정오 배경: %s (기본 %s)" % [str(noon_color), str(noon_bg)])
		assert(noon_color == noon_bg, "정오 시 풀밭 색이어야 함")
		TimeManager.minutes_elapsed = 22 * 60   # 밤 (22시)
		md2._update_time_of_day_colors()
		await get_tree().process_frame
		var night_color: Color = md2.bg_color_rect.color
		print("  밤 배경: %s" % str(night_color))
		assert(noon_color != night_color, "낮과 밤 색은 달라야 함")
		assert(night_color.b < 0.15, "밤은 어두워야 함")
		print("  ✓ 시간대 색 정상 (낮: 풀밭 / 밤: 어두움)")
	else:
		print("[WARN] _update_time_of_day_colors 없음")

	# 10) 모달 OFF 무한 대기
	print("[10] 모달 자동 OFF 무한 대기 검증")
	while not DecisionQueue.get_all_pending().is_empty():
		DecisionQueue.resolve(DecisionQueue.get_all_pending()[0].id, {"id": "force", "label": "force"})
	_current_decision_id = -1
	_last_queue_size = 0
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	var new_id: int = DecisionQueue.push("TEST_OFF", {
		"title": "테스트 (자동 OFF)",
		"description": "자동 진행 OFF 상태에서 모달 유지 검증",
		"choices": [{ "id": "yes", "label": "예", "result": "TEST" }],
	}, DecisionQueue.Priority.MEDIUM)
	print("  강제 push: id=%d" % new_id)
	await get_tree().process_frame
	TimeManager.auto_progress_enabled = false
	_check_decision_queue()
	await get_tree().process_frame
	var modal_visible_off: bool = decision_modal.visible if decision_modal else false
	print("  ✓ 모달 표시 (auto_progress=OFF): visible=%s" % str(modal_visible_off))
	assert(modal_visible_off, "자동 OFF에서 모달이 떠있어야 함")
	_current_decision_id = DecisionQueue.get_all_pending()[0].id if not DecisionQueue.get_all_pending().is_empty() else -1
	_on_auto_skip()
	var modal_still_visible: bool = decision_modal.visible if decision_modal else false
	assert(modal_still_visible, "자동 OFF에서 _on_auto_skip 호출되어도 모달 유지")
	print("  ✓ OFF 상태에서 _on_auto_skip 호출 → 모달 유지됨")
	_current_decision_id = -1

	# 11) 모달 ON 자동 닫힘
	print("[11] 모달 자동 ON 검증")
	_current_decision_id = -1
	_last_queue_size = 0
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	while not DecisionQueue.get_all_pending().is_empty():
		DecisionQueue.resolve(DecisionQueue.get_all_pending()[0].id, {"id": "force", "label": "force"})
	EventEngine._decisions_today = 0
	# 결정 큐 우회 직접 push (rand 게이트 회피)
	var new_low_id: int = DecisionQueue.push("VISITOR", {
		"title": "방문객 도착",
		"description": "테스트용 LOW",
		"choices": [{ "id": "yes", "label": "환영", "result": "VISITOR_REJECT" }],
	}, DecisionQueue.Priority.LOW)
	print("  강제 LOW push: id=%d" % new_low_id)
	await get_tree().process_frame
	TimeManager.auto_progress_enabled = true
	_check_decision_queue()
	await get_tree().process_frame
	var modal_visible_on: bool = decision_modal.visible if decision_modal else false
	assert(modal_visible_on, "자동 ON에서 모달이 떠있어야 함")
	print("  ✓ 모달 표시 (auto_progress=ON): visible=%s" % str(modal_visible_on))
	_on_auto_skip()
	await get_tree().process_frame
	var modal_after_auto_close: bool = decision_modal.visible if decision_modal else false
	print("  ✓ _on_auto_skip 호출 후 모달 visible=%s (auto ON → 자동 닫힘)" % str(modal_after_auto_close))
	assert(not modal_after_auto_close, "자동 ON에서 _on_auto_skip 호출 후 모달은 닫혀야 함")

	# 12.5) 전투 화면 검증 — BattleScene 인스턴스 + 메서드 존재
	print("[12.5] 전투 화면 검증")
	var battle: Control = get_node_or_null("BattleScene") as Control
	if battle:
		print("  ✓ BattleScene 인스턴스: %s" % battle.scene_file_path)
		assert(battle.has_method("start_battle"), "start_battle 메서드 필요")
		assert(battle.has_method("_on_fight_pressed"), "_on_fight_pressed 메서드 필요")
		# 시뮬: 가짜 전투 시작
		battle.start_battle(4)
		await get_tree().process_frame
		assert(battle.visible, "BattleScene가 visible이어야 함")
		var allies_grid_node: Node = battle.get_node_or_null("GridRow/AlliesCard/AlliesVBox/AlliesGrid")
		var enemies_grid_node: Node = battle.get_node_or_null("GridRow/EnemiesCard/EnemiesVBox/EnemiesGrid")
		var allies_count: int = allies_grid_node.get_child_count() if allies_grid_node else 0
		var enemies_count: int = enemies_grid_node.get_child_count() if enemies_grid_node else 0
		print("  ✓ 전투 그리드: 아군 %d, 적군 %d" % [allies_count, enemies_count])
		assert(allies_count == 5, "아군 5명 필요")
		assert(enemies_count == 4, "적군 4명 필요")
		# 결정 큐에 BANDIT_RAID push
		DecisionQueue.push("BANDIT_RAID", {
			"title": "BANDIT_RAID test",
			"description": "전투 화면 검증",
			"enemy_count": 4,
			"choices": [
				{ "id": "fight", "label": "전투", "result": "BATTLE_BANDITS_FIGHT" },
				{ "id": "hide",  "label": "숨기", "result": "BATTLE_BANDITS_HIDE" },
				{ "id": "bribe", "label": "뇌물", "result": "BATTLE_BANDITS_BRIBE" },
			],
		}, DecisionQueue.Priority.HIGH)
		await get_tree().process_frame
		var bandit_count: int = 0
		for d in DecisionQueue.get_all_pending():
			if d.type == "BANDIT_RAID":
				bandit_count += 1
		print("  ✓ BANDIT_RAID 시나리오 push: %d건" % bandit_count)
		assert(bandit_count >= 1, "BANDIT_RAID 시나리오 push 안 됨")
		battle.visible = false   # 정리
	else:
		print("[WARN] BattleScene 인스턴스 없음")

	# 12.5.5) 차트 검증 — history ring buffer + chart canvas 그리기
	print("[12.5.5] 차트 검증")
	print("  history 크기: %d" % GameWorld.history.size())
	assert(GameWorld.history.size() >= 1, "history ≥1일 필요")
	assert(GameWorld.history.size() <= 7, "history ≤7일 ring buffer")
	var chart_canvas: Control = get_node_or_null("ManorDashboard/CenterRoot/LeftColumn/ChartRow/ChartCard/ChartCanvas") as Control
	if chart_canvas:
		print("  ✓ ChartCanvas 노드 존재: %s" % str(chart_canvas.size))
		# chart redraw 호출 → _draw_chart 시그널 발화
		chart_canvas.queue_redraw()
		await get_tree().process_frame
		print("  ✓ 차트 queue_redraw 호출 성공")
	else:
		print("[WARN] ChartCanvas 노드 없음")

	# 13) 타이틀 라운드트립
	print("[13] 타이틀 화면 라운드트립")
	var saves_before: Array = SaveManager.list_saves()
	print("  저장 파일: %s" % str(saves_before))
	if saves_before.is_empty():
		SaveManager.save_game("verify_title")
		saves_before = SaveManager.list_saves()
	var ts: Control = get_node_or_null("TitleLayer/TitleScreen") as Control
	if ts and ts.has_method("refresh"):
		ts.refresh()
		await get_tree().process_frame
		var continue_btn: Button = ts.get_node_or_null("CenterBox/ContinueButton") as Button
		if continue_btn:
			print("  ✓ TitleScreen '이어하기' 버튼 활성: disabled=%s" % str(continue_btn.disabled))
			assert(not continue_btn.disabled)
	_enter_title_mode()
	await get_tree().process_frame
	assert(not _in_game_mode)
	print("  ✓ 타이틀 진입: _in_game_mode=false")
	_on_title_start_new()
	await get_tree().process_frame
	assert(_in_game_mode)
	print("  ✓ 게임 진입: _in_game_mode=true")
	_on_title_menu_pressed()
	await get_tree().process_frame
	assert(not _in_game_mode)
	print("  ✓ 다시 타이틀: _in_game_mode=false")

	print("\n=== 검증 완료 — quit ===")
	get_tree().quit()
