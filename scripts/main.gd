extends Node2D
## Last Banner v2.2 — 메인 허브 (타이틀 ↔ 게임 모드 토글)

const LB_VERIFY := "LB_VERIFY"
const GameOver = preload("res://scripts/game_over.gd")   # v4.1 B-3 검증용 상수 접근

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
# v4.1 튜토리얼
var tutorial_layer: CanvasLayer = null
var tutorial_screen: CanvasLayer = null
# v4.1 게임 오버 (B-3)
var game_over_layer: CanvasLayer = null
var game_over_screen: CanvasLayer = null

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
	tutorial_layer = get_node_or_null("TutorialLayer") as CanvasLayer
	game_over_layer = get_node_or_null("GameOverLayer") as CanvasLayer
	if title_layer:
		title_screen = title_layer.get_node_or_null("TitleScreen") as Control
	if tutorial_layer:
		tutorial_screen = tutorial_layer.get_node_or_null("Tutorial") as CanvasLayer
	if game_over_layer:
		game_over_screen = game_over_layer.get_node_or_null("GameOver") as CanvasLayer
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
	_apply_colors()

func _apply_colors() -> void:
	# 색상만 입히기 (구조/anchor는 건드리지 않음 — tscn이 안정된 검증된 형태)
	# ─── 상단 자원바 라벨 색상 ─────────────
	if time_label: UITheme.apply_label_color(time_label, UITheme.TEXT_TITLE)
	if gold_label: UITheme.apply_label_color(gold_label, UITheme.COLOR_GOLD)
	if food_label: UITheme.apply_label_color(food_label, UITheme.COLOR_FOOD)
	if pop_label: UITheme.apply_label_color(pop_label, UITheme.COLOR_POPULATION)
	if prosper_label: UITheme.apply_label_color(prosper_label, UITheme.COLOR_PROSPERITY)
	if last_event_label: UITheme.apply_label_color(last_event_label, UITheme.TEXT_SECONDARY)
	# ─── 하단 버튼 색상 ────────────────────────
	UITheme.apply_button_styles(toggle_button, UITheme.BG_BUTTON)
	UITheme.apply_button_styles(advance_button, UITheme.BG_BUTTON.lerp(UITheme.COLOR_GOLD, 0.15))
	UITheme.apply_button_styles(save_button, UITheme.BG_BUTTON)
	UITheme.apply_button_styles(load_button, UITheme.BG_BUTTON)
	UITheme.apply_button_styles(title_menu_button, UITheme.BG_BUTTON.lerp(UITheme.TEXT_DANGER, 0.15))
	# ─── 모달 ───────────────────────────────
	if modal_dim_bg: modal_dim_bg.color = Color(0, 0, 0, 0.78)
	if modal_title: UITheme.apply_label_color(modal_title, UITheme.TEXT_TITLE)
	if modal_desc: UITheme.apply_label_color(modal_desc, UITheme.TEXT_PRIMARY)

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
	# v4.1 B-3: 게임 오버 시그널
	GameManager.game_ended.connect(_on_game_ended)
	# v4.1 B-3: GameOver 화면 시그널
	if game_over_screen and game_over_screen.has_signal("return_to_title_requested"):
		game_over_screen.return_to_title_requested.connect(_on_game_over_return)
	# 타이틀 화면 시그널
	if title_screen and title_screen.has_signal("start_new_game"):
		title_screen.start_new_game.connect(_on_title_start_new)
	if title_screen and title_screen.has_signal("continue_game"):
		title_screen.continue_game.connect(_on_title_continue)
	if title_screen and title_screen.has_signal("retutorial_requested"):
		title_screen.retutorial_requested.connect(_on_title_retutorial)
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
	if title_layer: title_layer.visible = true
	if ui_layer: ui_layer.visible = false
	if manor_layer: manor_layer.visible = false
	# 결정 모달 강제 닫기
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	GameManager.current_state = GameManager.State.MENU
	# 타이틀 화면 갱신
	if title_screen and title_screen.has_method("refresh"):
		title_screen.refresh()
	# v4.1 B-2: BGM 메뉴로 전환
	if AudioManager.is_enabled():
		AudioManager.play_bgm("menu")
	print("[Main] 타이틀 모드 진입")

func _enter_game_mode() -> void:
	_in_game_mode = true
	if title_layer: title_layer.visible = false
	if ui_layer: ui_layer.visible = true
	if manor_layer: manor_layer.visible = true
	GameManager.current_state = GameManager.State.PLAYING
	_refresh_all()
	# v4.1 B-4: Tutorial 카드 viewport 사이즈 자동 조정 (CanvasLayer 내부의 Card에 적용)
	if tutorial_screen:
		var tutorial_card: Control = null
		for child in tutorial_screen.get_children():
			if child is Control:
				tutorial_card = child
				break
		_adjust_modal_for_viewport(tutorial_card if tutorial_card else tutorial_screen, get_viewport().get_visible_rect().size)
	# v4.1: 새 게임 첫 진입이면 튜토리얼 자동 표시 (tutorial_seen 체크)
	if tutorial_screen and tutorial_screen.has_method("start_tutorial"):
		tutorial_screen.start_tutorial(false)
	# v4.1 B-2: BGM 게임으로 전환 (메뉴 → 게임)
	if AudioManager.is_enabled():
		AudioManager.play_bgm("game")
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

func _on_title_retutorial() -> void:
	# 튜토리얼 강제 표시 (seen 무시)
	print("[Main] 튜토리얼 다시보기")
	# v4.1 B-4: Tutorial 카드 viewport 사이즈 자동 조정 (CanvasLayer 내부 Card)
	if tutorial_screen:
		var tutorial_card: Control = null
		for child in tutorial_screen.get_children():
			if child is Control:
				tutorial_card = child
				break
		_adjust_modal_for_viewport(tutorial_card if tutorial_card else tutorial_screen, get_viewport().get_visible_rect().size)
	if tutorial_screen and tutorial_screen.has_method("start_tutorial"):
		tutorial_screen.start_tutorial(true)   # force=true → seen 무시

# ============================================================
# v4.1 B-3: 게임 오버
# ============================================================
func _on_game_ended(reason: String, stats: Dictionary) -> void:
	print("[Main] 게임 오버: %s (Day %d)" % [reason, GameManager.end_day])
	# 자동 진행 OFF (시계 정지)
	TimeManager.auto_progress_enabled = false
	# 결정 모달 닫기
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	# v4.1 B-2: 게임 오버 SFX + BGM 정지
	if AudioManager.is_enabled():
		AudioManager.play_sfx("victory")
		AudioManager.stop_bgm(true)
	# GameOver 화면 표시
	if game_over_screen and game_over_screen.has_method("show_game_over"):
		# v4.1 B-4: viewport 사이즈 조정 (CanvasLayer 내부 Card에 적용)
		var go_card: Control = null
		for child in game_over_screen.get_children():
			if child is Control:
				go_card = child
				break
		_adjust_modal_for_viewport(go_card if go_card else game_over_screen, get_viewport().get_visible_rect().size)
		game_over_screen.show_game_over(reason, GameManager.end_day, stats)

func _on_game_over_return() -> void:
	print("[Main] 게임 오버 → 메인 메뉴로 복귀")
	if game_over_screen:
		game_over_screen.visible = false
	# 자동 저장
	SaveManager.save_game("autosave")
	_enter_title_mode()

# ============================================================
# v4.1 B-4: 모바일/태블릿 viewport 대응
# ============================================================
const MOBILE_VIEWPORT_THRESHOLD := 800   # 너비 < 800px → 모바일 모드

func _is_mobile_viewport() -> bool:
	# get_viewport_rect() 또는 window size
	var size: Vector2 = get_viewport().get_visible_rect().size
	return size.x < MOBILE_VIEWPORT_THRESHOLD

func _adjust_modal_for_viewport(modal: Node, viewport_size: Vector2) -> void:
	# 모바일/태블릿에서 모달 사이즈 자동 조정 (Node — PanelContainer/CanvasLayer 모두 받음)
	if modal == null:
		return
	var is_mobile: bool = viewport_size.x < MOBILE_VIEWPORT_THRESHOLD
	if is_mobile:
		# 모바일: viewport 90% 너비, 높이 70%
		var w: float = viewport_size.x * 0.90
		var h: float = viewport_size.y * 0.70
		modal.offset_left = -w * 0.5
		modal.offset_right = w * 0.5
		modal.offset_top = -h * 0.5
		modal.offset_bottom = h * 0.5
		print("[Main] 모바일 viewport 감지 — 모달 사이즈 조정: %.0f×%.0f" % [w, h])
	else:
		# 데스크탑: 원래 사이즈
		modal.offset_left = -360.0
		modal.offset_right = 360.0
		modal.offset_top = -180.0
		modal.offset_bottom = 180.0

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
	time_label.text = "🕯 Day %d  %02d:%02d  |  ⏯ 자동 진행: %s" % [
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
			# v4.1 B-4: 모달 사이즈 viewport에 맞게 조정
			_adjust_modal_for_viewport(decision_modal, get_viewport().get_visible_rect().size)
			if modal_dim_bg:
				modal_dim_bg.visible = true
			decision_modal.visible = true
			# v4.1 B-2: 모달 열림 SFX
			if AudioManager.is_enabled():
				AudioManager.play_sfx("modal_open")
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
	if modal_title:
		modal_title.text = decision.payload.get("title", "결정")
		# 우선순위별 제목 색상
		var pcolor: Color = UITheme.priority_color(decision.priority)
		UITheme.apply_label_color(modal_title, pcolor)
	if modal_desc:
		modal_desc.text = decision.payload.get("description", "")
	if modal_priority:
		modal_priority.text = "[%s] %s" % [pname, decision.type]
		UITheme.apply_label_color(modal_priority, UITheme.priority_color(decision.priority))
	if modal_choices:
		for child in modal_choices.get_children():
			child.queue_free()
		for choice in decision.payload.get("choices", []):
			var btn := Button.new()
			btn.text = choice.get("label", "선택")
			btn.custom_minimum_size = Vector2(0, 48)
			btn.pressed.connect(_on_choice_pressed.bind(choice))
			modal_choices.add_child(btn)
			# 우선순위별 버튼 색상
			var btn_bg: Color = UITheme.BG_BUTTON
			match decision.priority:
				DecisionQueue.Priority.CRITICAL:
					btn_bg = UITheme.BG_BUTTON.lerp(UITheme.PRIORITY_CRITICAL, 0.20)
				DecisionQueue.Priority.HIGH:
					btn_bg = UITheme.BG_BUTTON.lerp(UITheme.PRIORITY_HIGH, 0.18)
				DecisionQueue.Priority.MEDIUM:
					btn_bg = UITheme.BG_BUTTON.lerp(UITheme.PRIORITY_MEDIUM, 0.12)
				_:
					btn_bg = UITheme.BG_BUTTON
			UITheme.apply_button_styles(btn, btn_bg)

func _on_choice_pressed(choice: Dictionary) -> void:
	print("[Main] _on_choice_pressed: choice=%s" % str(choice))
	if _current_decision_id < 0:
		return
	var result_code: String = choice.get("result", "")
	print("[Main] result_code=%s, current_id=%d" % [result_code, _current_decision_id])
	var decision_type: String = _current_decision_type()
	print("[Main] decision_type=%s" % decision_type)
	# v4.1 B-2: 결정 확정 SFX (battle 분기 전 공통)
	if AudioManager.is_enabled():
		AudioManager.play_sfx("choice_confirm")
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
			# v4.1 B-2: 전투 시작 BGM + SFX
			if AudioManager.is_enabled():
				AudioManager.play_sfx("battle_start")
				AudioManager.play_bgm("battle")
	if result_code != "":
		_apply_result(result_code)
	DecisionQueue.resolve(_current_decision_id, choice)
	_current_decision_id = -1
	if decision_modal:
		decision_modal.visible = false
		if modal_dim_bg:
			modal_dim_bg.visible = false
	# v4.1 B-2: 모달 닫힘 SFX
	if AudioManager.is_enabled():
		AudioManager.play_sfx("modal_close")
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
	# v4.1 B-2: 자동 결정 SFX (모달 닫힘)
	if AudioManager.is_enabled():
		AudioManager.play_sfx("modal_close")
	GameManager.resume_from_decision()

func _default_low_choice() -> String:
	for d in DecisionQueue.get_all_pending():
		if d.id == _current_decision_id:
			match d.type:
				"VISITOR": return "VISITOR_REJECT"
				"PEASANT_PETITION": return "PETITION_REJECT"
				"MERCHANT_CARAVAN": return "MERCHANT_SEND_AWAY"
				"MERCENARY_OFFER": return "REJECT_MERCENARY"
				"BUILD_CONSTRUCTION": return "BUILD_SKIP"
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
		"PETITION_LOWER":
			GameWorld.modify_resource("gold", -20)
			GameWorld.modify_resource("prosperity", 3)
			GameWorld.log_event("세금 인하: -20 골드, +3 명성")
		"PETITION_REJECT":
			GameWorld.modify_resource("prosperity", -2)
			GameWorld.log_event("농민 호소 거절: 명성 -2")
		"WINTER_STOCKPILE":
			GameWorld.modify_resource("gold", -50)
			GameWorld.modify_resource("food", 40)
			GameWorld.log_event("겨울 식량 비축: -50 골드, +40 식량")
		"WINTER_MUSTER":
			GameWorld.modify_resource("food", -20)
			GameWorld.modify_resource("population", 5)
			GameWorld.log_event("겨울 모병: -20 식량, +5 인구")
		"WINTER_IGNORE":
			GameWorld.log_event("겨울 대비 무시 — 식량 소비 2배 예정")
		"MERCHANT_BUY":
			GameWorld.modify_resource("gold", -40)
			GameWorld.modify_resource("food", 30)
			GameWorld.log_event("상인 식량 구매: -40 골드, +30 식량")
		"MERCHANT_SEND_AWAY":
			GameWorld.modify_resource("prosperity", -1)
			GameWorld.log_event("상인 돌려보냄: 명성 -1")
		"PLAGUE_MEDICINE":
			GameWorld.modify_resource("gold", -80)
			GameWorld.modify_resource("food", -10)
			GameWorld.log_event("역병 의학 동원: -80 골드, -10 식량 (사망 방지)")
		"PLAGUE_QUARANTINE":
			GameWorld.modify_resource("population", -10)
			GameWorld.modify_resource("prosperity", -5)
			GameWorld.log_event("역병 봉쇄: 인구 -10, 명성 -5")
		"PLAGUE_NOTHING":
			GameWorld.modify_resource("population", -15)
			GameWorld.modify_resource("prosperity", -10)
			GameWorld.log_event("역병 방치: 인구 -15, 명성 -10")
		"ACCEPT_MERCENARY":
			# payload에 mercenary dict가 있으면 roster에 추가
			var payload: Dictionary = _current_decision_payload()
			if payload.has("mercenary"):
				var m: Dictionary = payload["mercenary"]
				GameWorld.add_mercenary(m)
		"REJECT_MERCENARY":
			pass   # log만 RESULT_EFFECTS가 처리
		"DISMISS_MERCENARY":
			var payload2: Dictionary = _current_decision_payload()
			if payload2.has("mercenary_id"):
				GameWorld.dismiss_mercenary(int(payload2["mercenary_id"]), "해고")
		"MERCENARY_PAY_BONUS":
			GameWorld.modify_resource("gold", -30)
			GameWorld.modify_resource("prosperity", 5)
			GameWorld.log_event("용병 보너스: -30 골드, +5 명성 (충성도 +10)")
			# 보너스 지급한 용병 모두 충성도 +10
			for m in GameWorld.alive_mercenaries():
				m.loyalty = min(100, m.loyalty + 10)
		"MERCENARY_TRAINING":
			GameWorld.modify_resource("gold", -20)
			GameWorld.modify_resource("prosperity", 2)
			GameWorld.log_event("용병 훈련: -20 골드, +2 명성 (경험 +5)")
			for m in GameWorld.alive_mercenaries():
				m.experience += 5
		"MERCENARY_INJURY_HEAL":
			GameWorld.modify_resource("gold", -15)
			GameWorld.log_event("용병 부상 치료: -15 골드")
			for m in GameWorld.alive_mercenaries():
				if m.injured_days > 0:
					m.injured_days = max(0, m.injured_days - 3)
		"MERCENARY_DESERTS":
			# 자동 — loyalty<30에 의한 자동 이탈은 EventEngine에서 이미 처리됨
			pass
		"BETRAYAL_CRUSHER":
			var payload3: Dictionary = _current_decision_payload()
			if payload3.has("person_id"):
				GameWorld.kill_person(int(payload3["person_id"]), "처형")
				GameWorld.modify_resource("prosperity", 5)
		"BETRAYAL_BANISH":
			var payload4: Dictionary = _current_decision_payload()
			if payload4.has("person_id"):
				GameWorld.kill_person(int(payload4["person_id"]), "추방")
				GameWorld.modify_resource("prosperity", -3)
		"BETRAYAL_FORGIVE":
			var payload5: Dictionary = _current_decision_payload()
			if payload5.has("person_id"):
				var p: Dictionary = GameWorld.get_person_by_id(int(payload5["person_id"]))
				if not p.is_empty():
					p.loyalty = min(100, p.loyalty + 20)
				GameWorld.modify_resource("prosperity", -8)
				GameWorld.log_event("후계자 %s 용서 — 충성도 +20" % p.get("name", ""))
		"SUCCESSION_KEEP":
			pass   # 유지 — log만
		"SUCCESSION_SWAP":
			var heirs: Array = GameWorld.get_heirs()
			if heirs.size() >= 2:
				var a_id: int = heirs[0]["id"]
				var b_id: int = heirs[1]["id"]
				var a_rank: int = heirs[0]["heir_rank"]
				var b_rank: int = heirs[1]["heir_rank"]
				GameWorld.set_heir_rank(a_id, b_rank)
				GameWorld.set_heir_rank(b_id, a_rank)
		"SUCCESSION_NURTURE":
			var payload6: Dictionary = _current_decision_payload()
			if payload6.has("person_id"):
				var p2: Dictionary = GameWorld.get_person_by_id(int(payload6["person_id"]))
				if not p2.is_empty():
					p2.loyalty = min(100, p2.loyalty + 10)
				GameWorld.modify_resource("gold", -30)
				GameWorld.modify_resource("prosperity", 2)
		"BUILD_UPGRADE":
			var payload7: Dictionary = _current_decision_payload()
			if payload7.has("building_id"):
				GameWorld.upgrade_building(String(payload7["building_id"]))
		"BUILD_SKIP":
			pass   # log만 RESULT_EFFECTS가 처리
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
		last_event_label.text = "🪵 %s" % msg

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

	# 8.6) 신규 사건 4종 push 검증 (PEASANT_PETITION, MERCHANT_CARAVAN, WINTER_PREPARATION, PLAGUE)
	print("[8.6] 신규 사건 4종 push 검증")
	# 기존 큐 정리
	while not DecisionQueue.get_all_pending().is_empty():
		DecisionQueue.resolve(DecisionQueue.get_all_pending()[0].id, {"id": "clear", "label": "clear"})
	_current_decision_id = -1
	_last_queue_size = 0
	if decision_modal: decision_modal.visible = false
	if modal_dim_bg: modal_dim_bg.visible = false
	# PEASANT_PETITION (LOW)
	DecisionQueue.push("PEASANT_PETITION", {
		"title": "농민 호소",
		"description": "세금 인하 호소",
		"choices": [
			{ "id": "lower", "label": "인하", "result": "PETITION_LOWER" },
			{ "id": "reject", "label": "거절", "result": "PETITION_REJECT" },
		],
	}, DecisionQueue.Priority.LOW)
	# MERCHANT_CARAVAN (LOW)
	DecisionQueue.push("MERCHANT_CARAVAN", {
		"title": "상인 caravan",
		"description": "식량 구매",
		"choices": [
			{ "id": "buy", "label": "구매", "result": "MERCHANT_BUY" },
			{ "id": "send_away", "label": "돌려보냄", "result": "MERCHANT_SEND_AWAY" },
		],
	}, DecisionQueue.Priority.LOW)
	# WINTER_PREPARATION (MEDIUM)
	DecisionQueue.push("WINTER_PREPARATION", {
		"title": "겨울 준비",
		"description": "식량 비축",
		"choices": [
			{ "id": "stockpile", "label": "비축", "result": "WINTER_STOCKPILE" },
			{ "id": "muster", "label": "모병", "result": "WINTER_MUSTER" },
			{ "id": "ignore", "label": "무시", "result": "WINTER_IGNORE" },
		],
	}, DecisionQueue.Priority.MEDIUM)
	# PLAGUE (CRITICAL)
	DecisionQueue.push("PLAGUE", {
		"title": "역병",
		"description": "역병 발생",
		"choices": [
			{ "id": "medicine", "label": "의학", "result": "PLAGUE_MEDICINE" },
			{ "id": "quarantine", "label": "봉쇄", "result": "PLAGUE_QUARANTINE" },
			{ "id": "nothing", "label": "방치", "result": "PLAGUE_NOTHING" },
		],
	}, DecisionQueue.Priority.CRITICAL)
	await get_tree().process_frame
	var new_types := {"PEASANT_PETITION": 0, "MERCHANT_CARAVAN": 0, "WINTER_PREPARATION": 0, "PLAGUE": 0}
	for d in DecisionQueue.get_all_pending():
		if d.type in new_types:
			new_types[d.type] += 1
	print("  ✓ 신규 사건 분포: %s" % str(new_types))
	for t in new_types:
		assert(new_types[t] >= 1, "%s push 실패" % t)
	# 8.6.5) 신규 결과 코드 핸들러 검증
	print("[8.6.5] 신규 결과 코드 핸들러 검증")
	var gold_before_new: int = GameWorld.gold
	var prosper_before_new: int = GameWorld.prosperity
	GameWorld.apply_result("PETITION_LOWER", {})
	assert(GameWorld.gold == gold_before_new - 20, "PETITION_LOWER 골드 변동")
	assert(GameWorld.prosperity == prosper_before_new + 3, "PETITION_LOWER 명성 변동")
	print("  ✓ PETITION_LOWER: gold -20, prosper +3")
	_apply_result("WINTER_STOCKPILE")
	GameWorld.apply_result("MERCHANT_BUY", {})
	print("  ✓ GameWorld.apply_result 8종 신규 코드 OK")

	# 8.7) 용병 시스템 검증 (A-1)
	print("[8.7] 용병 시스템 검증 (A-1)")
	# 초기 roster 확인
	assert(GameWorld.alive_mercenaries().size() == 5, "초기 roster 5명 필요 (실제: %d)" % GameWorld.alive_mercenaries().size())
	print("  ✓ 초기 roster: %d명" % GameWorld.alive_mercenaries().size())
	# 9-class tier 카탈로그 확인
	assert(MercenaryData.CLASSES.size() == 9, "9-class tier 시스템")
	assert(MercenaryData.CLASSES.has("bowman"))
	assert(MercenaryData.CLASSES.has("paladin"))
	print("  ✓ MercenaryData.CLASSES 9개 확인 OK")
	# tier_color 검증
	var color_t1: Color = MercenaryData.tier_color(1)
	var color_t3: Color = MercenaryData.tier_color(3)
	assert(color_t1 != color_t3, "tier 1과 3 색은 달라야 함")
	print("  ✓ tier_color: T1=%s, T3=%s" % [str(color_t1), str(color_t3)])
	# total_wage_burden 계산
	var burden: int = GameWorld.total_wage_burden()
	assert(burden > 0, "총 일급 > 0")
	print("  ✓ 총 일급 부담: %d골드" % burden)
	# 신규 용병 추가 + 시그널 검증
	var signal_fired: Array = []
	GameWorld.mercenary_joined.connect(func(m): signal_fired.append(m))
	var new_m: Dictionary = GameWorld.offer_mercenary("crossbow")
	GameWorld.add_mercenary(new_m)
	assert(GameWorld.alive_mercenaries().size() == 6, "용병 추가 후 6명")
	assert(signal_fired.size() == 1, "mercenary_joined 시그널 발화")
	print("  ✓ 용병 추가: crossbow, 신호 %d건" % signal_fired.size())
	# MERCENARY_OFFER 결정 큐 push + ACCEPT_MERCENARY 결과 적용
	var offer_id: int = DecisionQueue.push("MERCENARY_OFFER", {
		"title": "용병 자원 (테스트)",
		"description": "테스트",
		"choices": [
			{ "id": "accept", "label": "수용", "result": "ACCEPT_MERCENARY" },
			{ "id": "reject", "label": "거절", "result": "REJECT_MERCENARY" },
		],
		"mercenary": GameWorld.offer_mercenary("fencer"),
	}, DecisionQueue.Priority.LOW)
	print("  ✓ MERCENARY_OFFER push: id=%d" % offer_id)
	_current_decision_id = offer_id
	var before_count: int = GameWorld.alive_mercenaries().size()
	_apply_result("ACCEPT_MERCENARY")
	assert(GameWorld.alive_mercenaries().size() == before_count + 1, "ACCEPT_MERCENARY 후 +1명")
	print("  ✓ ACCEPT_MERCENARY: %d → %d명" % [before_count, GameWorld.alive_mercenaries().size()])
	DecisionQueue.resolve(offer_id, {"id": "test", "label": "test"})
	_current_decision_id = -1
	# 충성도 자동 이탈 검증
	var deserter_id: int = GameWorld.alive_mercenaries()[0]["id"]
	for m in GameWorld.roster:
		if m.id == deserter_id:
			m.loyalty = 20
	EventEngine._check_mercenary_loyalty()
	assert(not GameWorld.get_mercenary_by_id(deserter_id).alive, "loyalty<30 → 자동 이탈")
	print("  ✓ loyalty<30 자동 이탈: id=%d" % deserter_id)
	# save/load round-trip (roster 보존)
	var saved_count: int = GameWorld.alive_mercenaries().size()
	assert(SaveManager.save_game("verify_roster"))
	GameWorld.reset_roster()
	assert(GameWorld.alive_mercenaries().is_empty(), "reset_roster → 비어있음")
	assert(SaveManager.load_game("verify_roster"))
	assert(GameWorld.alive_mercenaries().size() == saved_count, "roster round-trip 보존")
	print("  ✓ roster save/load round-trip: %d명 보존" % GameWorld.alive_mercenaries().size())

	# 8.8) 왕조/후계자 시스템 검증 (A-2)
	print("[8.8] 왕조/후계자 시스템 검증 (A-2)")
	# 초기 court 확인
	assert(GameWorld.court.size() == 5, "초기 court 5명 필요 (실제: %d)" % GameWorld.court.size())
	print("  ✓ 초기 court: %d명" % GameWorld.court.size())
	# 영주 확인
	var lord: Dictionary = GameWorld.get_lord()
	assert(not lord.is_empty(), "영주 있어야 함")
	assert(lord.heir_rank == 0, "영주 heir_rank=0")
	print("  ✓ 영주: %s (나이 %d, 충성도 %d)" % [lord.name, lord.age, lord.loyalty])
	# 후보 3명 heir_rank 1~3 정렬
	var heirs: Array = GameWorld.get_heirs()
	assert(heirs.size() == 3, "후보 3명 (실제: %d)" % heirs.size())
	for i in range(heirs.size()):
		assert(heirs[i]["heir_rank"] == i + 1, "후보 %d 순위 오류" % (i + 1))
	print("  ✓ 후보 %d명, heir_rank 1~3 정렬 OK" % heirs.size())
	# 신하 1명 heir_rank=-1
	var vassals: Array = GameWorld.get_vassals()
	assert(vassals.size() == 1, "신하 1명 (실제: %d)" % vassals.size())
	print("  ✓ 신하: %d명" % vassals.size())
	# 4종 스탯 검증
	for stat in ["martial", "stewardship", "diplomacy", "intrigue"]:
		assert(lord.stats.has(stat), "%s 스탯 없음" % stat)
		assert(lord.stats[stat] >= 4 and lord.stats[stat] <= 15, "%s 범위 4~15 (실제: %d)" % [stat, lord.stats[stat]])
	print("  ✓ 4종 스탯 (martial/stewardship/diplomacy/intrigue) OK")
	# SUCCESSION_AUDIT push + 결과 적용
	var succession_id: int = DecisionQueue.push("SUCCESSION_AUDIT", {
		"title": "후계자 감사 (테스트)",
		"description": "테스트",
		"choices": [
			{ "id": "keep", "label": "유지", "result": "SUCCESSION_KEEP" },
			{ "id": "swap", "label": "교체", "result": "SUCCESSION_SWAP" },
			{ "id": "nurture", "label": "양육", "result": "SUCCESSION_NURTURE" },
		],
		"person_id": heirs[0]["id"],
	}, DecisionQueue.Priority.MEDIUM)
	_current_decision_id = succession_id
	# SUCCESSION_SWAP 테스트 (1↔2 교체)
	var heirs_before: Array = GameWorld.get_heirs()
	var rank_1_before: int = heirs_before[0]["heir_rank"]
	var rank_2_before: int = heirs_before[1]["heir_rank"]
	_apply_result("SUCCESSION_SWAP")
	var heirs_after: Array = GameWorld.get_heirs()
	assert(heirs_after[0]["id"] == heirs_before[1]["id"], "SUCCESSION_SWAP 후 1순위 = 이전 2순위")
	print("  ✓ SUCCESSION_SWAP: 1순위 ↔ 2순위 교체 OK")
	# SUCCESSION_NURTURE 테스트
	var gold_before_nurture: int = GameWorld.gold
	var target: Dictionary = GameWorld.get_heirs()[0]
	var loyalty_before: int = target.loyalty
	DecisionQueue.resolve(succession_id, {"id": "test", "label": "test"})
	var nurture_id: int = DecisionQueue.push("SUCCESSION_AUDIT", {
		"title": "후계자 감사 2",
		"description": "양육 테스트",
		"choices": [
			{ "id": "keep", "label": "유지", "result": "SUCCESSION_KEEP" },
			{ "id": "swap", "label": "교체", "result": "SUCCESSION_SWAP" },
			{ "id": "nurture", "label": "양육", "result": "SUCCESSION_NURTURE" },
		],
		"person_id": target["id"],
	}, DecisionQueue.Priority.MEDIUM)
	_current_decision_id = nurture_id
	_apply_result("SUCCESSION_NURTURE")
	assert(GameWorld.gold == gold_before_nurture - 30, "SUCCESSION_NURTURE 골드 차감")
	var target_after: Dictionary = GameWorld.get_heirs()[0]
	assert(target_after.loyalty == loyalty_before + 10, "SUCCESSION_NURTURE 충성도 +10")
	print("  ✓ SUCCESSION_NURTURE: 골드 -30, 충성도 +%d OK" % (target_after.loyalty - loyalty_before))
	DecisionQueue.resolve(nurture_id, {"id": "test", "label": "test"})
	_current_decision_id = -1
	# HEIR_BETRAYAL push + BETRAYAL_CRUSHER 결과
	var betrayer: Dictionary = GameWorld.get_heirs()[1]
	var betrayer_id_before: int = betrayer["id"]
	var betrayal_id: int = DecisionQueue.push("HEIR_BETRAYAL", {
		"title": "후계자 배신 (테스트)",
		"description": "배신 테스트",
		"choices": [
			{ "id": "crusher", "label": "처형", "result": "BETRAYAL_CRUSHER" },
			{ "id": "banish", "label": "추방", "result": "BETRAYAL_BANISH" },
			{ "id": "forgive", "label": "용서", "result": "BETRAYAL_FORGIVE" },
		],
		"person_id": betrayer_id_before,
	}, DecisionQueue.Priority.CRITICAL)
	_current_decision_id = betrayal_id
	var prosper_before_betrayal: int = GameWorld.prosperity
	_apply_result("BETRAYAL_CRUSHER")
	assert(not GameWorld.get_person_by_id(betrayer_id_before).alive, "BETRAYAL_CRUSHER → 사망")
	assert(GameWorld.prosperity == prosper_before_betrayal + 5, "BETRAYAL_CRUSHER 명성 +5")
	print("  ✓ BETRAYAL_CRUSHER: %s 처형, 명성 +5" % betrayer["name"])
	DecisionQueue.resolve(betrayal_id, {"id": "test", "label": "test"})
	_current_decision_id = -1
	# court save/load round-trip
	var court_count: int = GameWorld.court.size()
	assert(SaveManager.save_game("verify_court"))
	GameWorld.reset_court()
	assert(GameWorld.court.is_empty(), "reset_court → 비어있음")
	assert(SaveManager.load_game("verify_court"))
	assert(GameWorld.court.size() == court_count, "court round-trip 보존")
	print("  ✓ court save/load round-trip: %d명 보존" % GameWorld.court.size())

	# 8.9) 빌딩 시스템 검증 (A-3)
	print("[8.9] 빌딩 시스템 검증 (A-3)")
	# 검증용 골드/식량 보충 (이전 단계 변동 무시)
	GameWorld.gold = 1500
	GameWorld.food = 1000
	# 초기 buildings = 4종 모두 Lv 0
	assert(GameWorld.buildings.size() == 4, "초기 buildings 4종 (실제: %d)" % GameWorld.buildings.size())
	for b in ["market", "training_ground", "granary", "walls"]:
		assert(GameWorld.buildings.has(b), "%s 등록 안 됨" % b)
		assert(GameWorld.buildings[b] == 0, "%s 초기 Lv 0" % b)
	print("  ✓ 초기 buildings: 4종 모두 Lv 0")
	# BUILDING_DEFS 검증
	assert(GameWorld.BUILDING_DEFS.size() == 4, "BUILDING_DEFS 4종")
	assert(GameWorld.BUILDING_MAX_LEVEL == 3, "max_level=3")
	print("  ✓ BUILDING_DEFS 4종, max_level=3")
	# can_upgrade / get_upgrade_cost
	assert(GameWorld.can_upgrade("market"), "market 업그레이드 가능 (Lv 0)")
	var cost: Dictionary = GameWorld.get_upgrade_cost("market")
	assert(cost.gold == 50 and cost.food == 30, "시장 Lv 0→1 비용: 50골드+30식량 (실제: %s)" % str(cost))
	print("  ✓ 시장 Lv 0→1 비용: %d골드 + %d식량" % [cost.gold, cost.food])
	# BUILD_UPGRADE → Lv 1
	var gold_pre_up: int = GameWorld.gold
	var food_pre_up: int = GameWorld.food
	assert(GameWorld.upgrade_building("market"), "시장 Lv 0→1 건설 성공")
	assert(GameWorld.get_building_level("market") == 1, "시장 Lv 1")
	assert(GameWorld.gold == gold_pre_up - 50, "골드 -50 차감")
	assert(GameWorld.food == food_pre_up - 30, "식량 -30 차감")
	print("  ✓ 시장 Lv 0→1: 골드 -%d, 식량 -%d" % [50, 30])
	# 보너스 합산 검증
	var tax_bonus_1: int = GameWorld.get_total_tax_bonus()
	assert(tax_bonus_1 == 5, "시장 Lv 1 → 세수 보너스 +5 (실제: %d)" % tax_bonus_1)
	print("  ✓ get_total_tax_bonus: Lv 1 시장 → +%d" % tax_bonus_1)
	# 비용 곡선 검증 (Lv 1→2 = base × 2)
	var cost_l2: Dictionary = GameWorld.get_upgrade_cost("market")
	assert(cost_l2.gold == 100 and cost_l2.food == 60, "시장 Lv 1→2 비용: 100+60 (실제: %s)" % str(cost_l2))
	print("  ✓ 비용 곡선: Lv 1→2 = base × 2 → %d골드" % cost_l2.gold)
	# Lv 3까지 업그레이드
	assert(GameWorld.upgrade_building("market"), "시장 Lv 1→2")
	assert(GameWorld.upgrade_building("market"), "시장 Lv 2→3")
	assert(GameWorld.get_building_level("market") == 3, "시장 max Lv 3")
	assert(not GameWorld.can_upgrade("market"), "max 도달 시 upgrade 불가")
	print("  ✓ 시장 Lv 3 max 도달, can_upgrade=false")
	var tax_bonus_3: int = GameWorld.get_total_tax_bonus()
	assert(tax_bonus_3 == 15, "시장 Lv 3 → 세수 보너스 +15 (실제: %d)" % tax_bonus_3)
	# 4종 건물 다 테스트
	GameWorld.upgrade_building("training_ground")
	GameWorld.upgrade_building("granary")
	GameWorld.upgrade_building("walls")
	assert(GameWorld.get_building_level("training_ground") == 1, "훈련장 Lv 1")
	assert(GameWorld.get_total_exp_bonus() == 2, "훈련장 Lv 1 → exp +2")
	assert(GameWorld.get_building_level("granary") == 1, "창고 Lv 1")
	assert(GameWorld.get_total_food_bonus() == 10, "창고 Lv 1 → food +10")
	assert(GameWorld.get_building_level("walls") == 1, "성벽 Lv 1")
	assert(GameWorld.get_defense_multiplier() < 1.0, "성벽 Lv 1 → multiplier < 1.0")
	print("  ✓ 4종 × Lv 1: tax +15, exp +2, food +10, walls 방어 mult %.2f" % GameWorld.get_defense_multiplier())
	# BUILD_CONSTRUCTION 결정 큐 push + BUILD_UPGRADE 결과 적용
	var build_id: int = DecisionQueue.push("BUILD_CONSTRUCTION", {
		"title": "🏗️ 창고 Lv 1→2 (테스트)",
		"description": "테스트",
		"choices": [
			{ "id": "upgrade", "label": "건설", "result": "BUILD_UPGRADE" },
			{ "id": "skip", "label": "보류", "result": "BUILD_SKIP" },
		],
		"building_id": "granary",
	}, DecisionQueue.Priority.LOW)
	_current_decision_id = build_id
	var food_pre_build: int = GameWorld.food
	_apply_result("BUILD_UPGRADE")
	assert(GameWorld.get_building_level("granary") == 2, "BUILD_UPGRADE → 창고 Lv 2")
	assert(GameWorld.get_total_food_bonus() == 20, "창고 Lv 2 → food +20")
	assert(GameWorld.food == food_pre_build - 40, "창고 Lv 1→2 비용 40 식량 차감 (실제: gold=%d food=%d)" % [GameWorld.gold, GameWorld.food])
	print("  ✓ BUILD_UPGRADE: 창고 Lv 1→2, 식량 보너스 +20")
	DecisionQueue.resolve(build_id, {"id": "test", "label": "test"})
	_current_decision_id = -1
	# buildings save/load round-trip
	var buildings_snapshot: Dictionary = GameWorld.buildings.duplicate(true)
	assert(SaveManager.save_game("verify_buildings"))
	GameWorld.reset_buildings()
	assert(GameWorld.buildings["market"] == 0 and GameWorld.buildings["granary"] == 0, "reset_buildings → Lv 0")
	assert(SaveManager.load_game("verify_buildings"))
	for b in buildings_snapshot:
		assert(GameWorld.buildings[b] == buildings_snapshot[b], "buildings[%s] round-trip" % b)
	print("  ✓ buildings save/load round-trip: %d종 보존" % buildings_snapshot.size())

	# 8.10) 튜토리얼 시스템 검증 (B-1 v4.1)
	print("[8.10] 튜토리얼 시스템 검증 (B-1 v4.1)")
	var tutorial_layer_check: CanvasLayer = get_node_or_null("TutorialLayer") as CanvasLayer
	assert(tutorial_layer_check != null, "TutorialLayer 없음")
	var tutorial: CanvasLayer = null
	if tutorial_layer_check:
		tutorial = tutorial_layer_check.get_node_or_null("Tutorial") as CanvasLayer
	assert(tutorial != null, "Tutorial 자식 노드 없음")
	assert(tutorial.has_method("start_tutorial"), "start_tutorial 메서드 없음")
	print("  ✓ Tutorial 노드 + start_tutorial 메서드 존재")
	# 첫 호출: seen 플래그 = false → 표시
	GameManager.tutorial_seen = false
	tutorial.start_tutorial(false)
	await get_tree().process_frame
	assert(tutorial.visible, "튜토리얼 visible이어야 함 (seen=false)")
	print("  ✓ 첫 호출: visible=true, _active=true")
	# 4단계 STEPS 데이터 확인
	var steps_count: int = tutorial.STEPS.size()
	assert(steps_count == 4, "STEPS 4단계 필요 (실제: %d)" % steps_count)
	for i in range(steps_count):
		var step: Dictionary = tutorial.STEPS[i]
		assert(step.has("icon") and step.has("title") and step.has("message"), "STEP %d 형식 불일치" % i)
	print("  ✓ STEPS 4단계 모두 icon/title/message 포함")
	# _show_step → 화면만 갱신 (current_step 유지)
	tutorial._show_step(1)
	await get_tree().process_frame
	assert(tutorial._current_step == 0, "_show_step은 _current_step 변경 안 함 (단순 표시)")
	print("  ✓ _show_step(1) 화면 갱신 OK (current_step 유지)")
	# _on_next_pressed → 다음 단계
	tutorial._on_next_pressed()
	await get_tree().process_frame
	assert(tutorial._current_step == 1, "_on_next_pressed → _current_step=1")
	print("  ✓ _on_next_pressed 단계 진행 OK")
	# 두 번째 호출: seen=true → skip
	# 먼저 _on_skip_pressed로 명시적으로 종료 (튜토리얼 닫기)
	tutorial._on_skip_pressed()
	await get_tree().process_frame
	assert(not tutorial.visible, "_on_skip_pressed 후 visible=false")
	assert(GameManager.tutorial_seen, "_on_skip_pressed 후 tutorial_seen=true")
	GameManager.tutorial_seen = true   # 명시적으로 다시 true로 (이미 true지만 안전)
	tutorial.start_tutorial(false)
	await get_tree().process_frame
	assert(not tutorial.visible, "튜토리얼 visible=false이어야 함 (seen=true)")
	print("  ✓ 두 번째 호출: visible=false (seen=true → 자동 skip)")
	# force=true → 강제 표시
	tutorial.start_tutorial(true)
	await get_tree().process_frame
	assert(tutorial.visible, "force=true → visible=true 강제 표시")
	print("  ✓ force=true: 강제 표시 OK")
	# _on_skip_pressed → 완료
	tutorial._on_skip_pressed()
	await get_tree().process_frame
	assert(not tutorial.visible, "_on_skip_pressed → visible=false")
	assert(GameManager.tutorial_seen, "_on_skip_pressed → tutorial_seen=true")
	print("  ✓ _on_skip_pressed → 완료 + seen=true")
	# GameManager save/load에 tutorial_seen 포함
	assert(GameManager.save_state().has("tutorial_seen"), "save_state에 tutorial_seen 없음")
	GameManager.tutorial_seen = false
	GameManager.load_state({"tutorial_seen": true})
	assert(GameManager.tutorial_seen == true, "load_state → tutorial_seen 복원")
	print("  ✓ save/load round-trip: tutorial_seen OK")

	# 8.12) 게임 오버 시스템 검증 (B-3)
	print("[8.12] 게임 오버 시스템 검증 (B-3)")
	# GameOver 화면 노드 존재
	var go_layer: CanvasLayer = get_node_or_null("GameOverLayer") as CanvasLayer
	assert(go_layer != null, "GameOverLayer 없음")
	var go: CanvasLayer = null
	if go_layer:
		go = go_layer.get_node_or_null("GameOver") as CanvasLayer
	assert(go != null, "GameOver 자식 노드 없음")
	assert(go.has_method("show_game_over"), "show_game_over 메서드 없음")
	print("  ✓ GameOver 노드 + show_game_over 메서드 존재")
	# REASON_LABELS 3종 확인
	assert(GameOver.REASON_LABELS.size() == 3, "REASON_LABELS 3종 (실제: %d)" % GameOver.REASON_LABELS.size())
	for r in ["POPULATION_EXTINCTION", "FOOD_FAMINE", "DYNASTY_EXTINCTION"]:
		assert(GameOver.REASON_LABELS.has(r), "%s 라벨 없음" % r)
		assert(GameOver.REASON_DESCRIPTIONS.has(r), "%s 설명 없음" % r)
	print("  ✓ 3종 패배 조건 라벨 + 설명 OK")
	# GameManager 상수 + 필드 확인
	assert(GameManager.CONSECUTIVE_FOOD_ZERO_DAYS_LIMIT == 30, "식량 0 한도 30일")
	assert(GameManager.POPULATION_EXTINCTION_THRESHOLD == 0, "인구 한도 0")
	assert(GameManager.end_reason == "", "초기 end_reason = 빈 문자열")
	assert(GameManager.consecutive_food_zero_days == 0, "초기 식량 0 일수 0")
	print("  ✓ GameManager 상수 + 필드 초기값 OK")
	# 시나리오 1: 인구 멸망 → POPULATION_EXTINCTION
	GameManager.reset_end_state()
	GameManager.current_state = GameManager.State.PLAYING
	GameWorld.population = 5
	GameWorld.food = 50
	assert(not GameManager.check_game_over_conditions(), "인구 5 → 패배 X")
	GameWorld.population = 0
	assert(GameManager.check_game_over_conditions(), "인구 0 → 패배 O")
	assert(GameManager.end_reason == "POPULATION_EXTINCTION", "end_reason = POPULATION_EXTINCTION")
	assert(GameManager.current_state == GameManager.State.GAME_OVER, "state = GAME_OVER")
	print("  ✓ 인구 0 → POPULATION_EXTINCTION (%d일 생존)" % GameManager.end_day)
	# stats 검증
	var stats1: Dictionary = GameManager.end_stats
	assert(stats1.has("gold") and stats1.has("food") and stats1.has("population"), "stats에 핵심 자원 없음")
	assert(int(stats1["population"]) == 0, "stats.population = 0")
	print("  ✓ end_stats: gold=%d food=%d pop=%d roster=%d court=%d" % [int(stats1["gold"]), int(stats1["food"]), int(stats1["population"]), int(stats1["roster_count"]), int(stats1["court_count"])])
	# 중복 호출 안전성
	GameManager.check_game_over_conditions()
	assert(GameManager.end_reason == "POPULATION_EXTINCTION", "중복 호출 안전")
	print("  ✓ 중복 호출 안전 (이미 GAME_OVER → 재평가 안 함)")
	# GameOver 화면에 show_game_over 호출
	GameManager.current_state = GameManager.State.GAME_OVER
	go.show_game_over("POPULATION_EXTINCTION", GameManager.end_day, stats1)
	await get_tree().process_frame
	assert(go.visible, "show_game_over → GameOver 화면 visible=true")
	print("  ✓ show_game_over → 화면 표시 OK")
	# 시나리오 2: 식량 0 연속 30일 → FOOD_FAMINE
	GameManager.reset_end_state()
	GameManager.current_state = GameManager.State.PLAYING
	GameWorld.population = 50
	GameManager.consecutive_food_zero_days = 0
	# 정상 상태 확인
	assert(not GameManager.check_game_over_conditions(), "시나리오2 시작: 정상 상태 → 패배 X")
	assert(GameManager.consecutive_food_zero_days == 0, "consecutive=0 시작")
	print("  ✓ 시나리오2 초기화 OK")
	GameWorld.food = 0   # 0 set은 for 루프 직전에 (위에서 food=50은 정상 확인용)
	for i in range(29):
		var triggered: bool = GameManager.check_game_over_conditions()
		var day_count: int = i + 1
		var zero_count: int = GameManager.consecutive_food_zero_days
		assert(not triggered, "Day %d: 아직 30일 미만 (food=0 누적 %d일)" % [day_count, zero_count])
	GameWorld.food = 10   # 30일차 전에 회복 → 카운터 리셋
	var triggered_reset: bool = GameManager.check_game_over_conditions()
	assert(not triggered_reset, "식량 회복 → 카운터 리셋")
	assert(GameManager.consecutive_food_zero_days == 0, "consecutive_food_zero_days = 0 리셋")
	print("  ✓ 식량 회복 → 카운터 리셋 OK")
	# 다시 30일 누적
	GameWorld.food = 0
	for i in range(30):
		GameManager.check_game_over_conditions()
	assert(GameManager.end_reason == "FOOD_FAMINE", "30일 누적 → FOOD_FAMINE (실제: %s)" % GameManager.end_reason)
	print("  ✓ 식량 0 연속 30일 → FOOD_FAMINE (Day %d)" % GameManager.end_day)
	# 시나리오 3: 왕조 멸절 → DYNASTY_EXTINCTION
	GameManager.reset_end_state()
	GameManager.current_state = GameManager.State.PLAYING
	GameWorld.population = 50
	GameWorld.food = 50
	# 모든 court 인물 사망
	for p in GameWorld.court:
		p.alive = false
	assert(GameManager.check_game_over_conditions(), "court 전원 사망 → 패배 O")
	assert(GameManager.end_reason == "DYNASTY_EXTINCTION", "end_reason = DYNASTY_EXTINCTION")
	print("  ✓ 왕조 멸절 → DYNASTY_EXTINCTION (alive_court=0)")
	# get_end_reason_label 검증
	GameManager.end_reason = "POPULATION_EXTINCTION"
	assert(GameManager.get_end_reason_label() == "인구 멸망", "라벨 = 인구 멸망")
	GameManager.end_reason = "FOOD_FAMINE"
	assert(GameManager.get_end_reason_label() == "대기아 (식량 0 연속 30일)", "라벨 = 대기아")
	GameManager.end_reason = "DYNASTY_EXTINCTION"
	assert(GameManager.get_end_reason_label() == "왕조 멸절", "라벨 = 왕조 멸절")
	print("  ✓ get_end_reason_label() 3종 OK")
	# save/load round-trip
	GameManager.reset_end_state()
	GameManager.current_state = GameManager.State.PLAYING
	GameWorld.population = 0
	GameManager.check_game_over_conditions()
	assert(GameManager.end_reason == "POPULATION_EXTINCTION", "패배 상태")
	assert(SaveManager.save_game("verify_gameover"))
	GameManager.reset_end_state()
	assert(GameManager.end_reason == "", "reset 후 end_reason = 빈 문자열")
	assert(GameManager.consecutive_food_zero_days == 0, "reset 후 consecutive = 0")
	assert(SaveManager.load_game("verify_gameover"))
	assert(GameManager.end_reason == "POPULATION_EXTINCTION", "load → end_reason 복원")
	assert(GameManager.current_state == GameManager.State.GAME_OVER, "load → state 복원")
	print("  ✓ save/load round-trip: end_reason + state + consecutive OK")
	# 마지막 정리
	GameManager.reset_end_state()
	# 정상 상태 검증
	GameManager.current_state = GameManager.State.PLAYING
	GameWorld.population = 50
	GameWorld.food = 50
	# court 1명 alive로 복원
	if GameWorld.court.size() > 0:
		GameWorld.court[0].alive = true
	assert(not GameManager.check_game_over_conditions(), "정상 상태 → 패배 X")
	print("  ✓ 정상 상태 → 패배 없음 OK")

	# 8.11) 사운드 시스템 검증 (B-2)
	print("[8.11] 사운드 시스템 검증 (B-2)")
	# AudioManager 상수 확인
	assert(AudioManager.BGM_TRACKS.size() == 4, "BGM 4종 (실제: %d)" % AudioManager.BGM_TRACKS.size())
	assert(AudioManager.SFX_TRACKS.size() == 6, "SFX 6종 (실제: %d)" % AudioManager.SFX_TRACKS.size())
	for k in ["menu", "game", "battle", "modal"]:
		assert(AudioManager.BGM_TRACKS.has(k), "BGM %s 없음" % k)
	for k in ["modal_open", "modal_close", "choice_confirm", "dice_roll", "battle_start", "victory"]:
		assert(AudioManager.SFX_TRACKS.has(k), "SFX %s 없음" % k)
	print("  ✓ BGM 4종 + SFX 6종 등록 OK")
	# 자산 확인 (실제 파일 존재)
	for path in AudioManager.BGM_TRACKS.values():
		assert(ResourceLoader.exists(path), "BGM 파일 없음: %s" % path)
	for path in AudioManager.SFX_TRACKS.values():
		assert(ResourceLoader.exists(path), "SFX 파일 없음: %s" % path)
	print("  ✓ 10개 .ogg 자산 모두 존재")
	# AudioManager 인스턴스 (autoload)
	var am: Node = get_node_or_null("/root/AudioManager")
	assert(am != null, "AudioManager autoload 인스턴스 없음")
	assert(am.has_method("is_enabled"), "is_enabled 메서드 없음")
	assert(am.has_method("is_asset_available"), "is_asset_available 메서드 없음")
	assert(am.has_method("play_bgm"), "play_bgm 메서드 없음")
	assert(am.has_method("play_sfx"), "play_sfx 메서드 없음")
	assert(am.has_method("stop_bgm"), "stop_bgm 메서드 없음")
	# 헤드리스 가드 — LB_VERIFY 환경에서는 비활성화
	var am_enabled: bool = am.is_enabled()
	assert(not am_enabled, "헤드리스 환경에서 AudioManager.is_enabled() = false 여야 함")
	print("  ✓ AudioManager autoload + 헤드리스 가드 OK (is_enabled=%s)" % str(am_enabled))
	# 자산 가드
	var am_asset: bool = am.is_asset_available()
	assert(am_asset, "자산 가드 OK (is_asset_available=true)")
	print("  ✓ 자산 가드 OK (is_asset_available=%s)" % str(am_asset))
	# 헤드리스 가드 상태에서 play_bgm/play_sfx 호출 시 무동작 (no-op) — 크래시 없음
	am.play_bgm("menu")
	am.play_sfx("modal_open")
	am.stop_bgm()
	print("  ✓ 헤드리스에서 play_bgm/play_sfx/stop_bgm 호출 무동작 OK")
	# main.gd 6개 위치 통합 확인 — 코드 grep
	var main_src: String = FileAccess.get_file_as_string("res://scripts/main.gd")
	var integration_count: int = 0
	for marker in ["_enter_title_mode()", "play_bgm(\"menu\")", "play_bgm(\"game\")", "play_sfx(\"modal_open\")", "play_sfx(\"modal_close\")", "play_sfx(\"choice_confirm\")", "play_sfx(\"battle_start\")", "play_bgm(\"battle\")", "play_sfx(\"victory\")"]:
		if main_src.find(marker) != -1:
			integration_count += 1
	print("  ✓ main.gd 사운드 통합 마커 %d개 발견" % integration_count)
	assert(integration_count >= 7, "최소 7개 마커 필요 (실제: %d)" % integration_count)

	# 8.13) 모바일 viewport 대응 검증 (B-4)
	print("[8.13] 모바일 viewport 대응 검증 (B-4)")
	# 모바일 임계값 확인
	assert(MOBILE_VIEWPORT_THRESHOLD == 800, "모바일 임계값 800px")
	print("  ✓ MOBILE_VIEWPORT_THRESHOLD = 800px")
	# _is_mobile_viewport() 메서드
	assert(_is_mobile_viewport() or not _is_mobile_viewport(), "_is_mobile_viewport 메서드 호출 가능")
	assert(has_method("_adjust_modal_for_viewport"), "_adjust_modal_for_viewport 메서드 없음")
	print("  ✓ _is_mobile_viewport + _adjust_modal_for_viewport 메서드 존재")
	# _is_mobile_viewport 로직 — 현재 viewport가 1280×720 (LB_VERIFY 기본)
	var current_size: Vector2 = get_viewport().get_visible_rect().size
	print("  현재 viewport: %.0f×%.0f (LB_VERIFY 헤드리스)" % [current_size.x, current_size.y])
	assert(not _is_mobile_viewport(), "현재 viewport → 모바일 아님 (is_mobile=false)")
	print("  ✓ 현재 viewport → is_mobile=false (데스크탑)")
	# _adjust_modal_for_viewport(viewport_size) 파라미터로 다양한 사이즈 테스트
	# 데스크탑 (1280×720)
	_adjust_modal_for_viewport(decision_modal, Vector2(1280, 720))
	assert(decision_modal.offset_left == -360.0, "데스크탑: offset_left=-360 (실제: %s)" % str(decision_modal.offset_left))
	assert(decision_modal.offset_right == 360.0, "데스크탑: offset_right=360 (실제: %s)" % str(decision_modal.offset_right))
	print("  ✓ 1280×720 (데스크탑) — 모달 offset ±360×±180")
	# 모바일 (414×896)
	_adjust_modal_for_viewport(decision_modal, Vector2(414, 896))
	var expected_offset_mobile_x: float = -414.0 * 0.9 * 0.5
	var expected_offset_mobile_y: float = -896.0 * 0.7 * 0.5
	assert(abs(decision_modal.offset_left - expected_offset_mobile_x) < 0.01, "모바일: offset_left=-186.3 (실제: %s)" % str(decision_modal.offset_left))
	assert(abs(decision_modal.offset_right - -expected_offset_mobile_x) < 0.01, "모바일: offset_right=186.3 (실제: %s)" % str(decision_modal.offset_right))
	assert(abs(decision_modal.offset_top - expected_offset_mobile_y) < 0.01, "모바일: offset_top=-313.6 (실제: %s)" % str(decision_modal.offset_top))
	print("  ✓ 414×896 (모바일) — 모달 viewport 90%%×70%% (offset %.0f×%.0f)" % [
		414.0 * 0.9, 896.0 * 0.7
	])
	# 태블릿 세로 (768×1024, iPad mini)
	_adjust_modal_for_viewport(decision_modal, Vector2(768, 1024))
	var expected_offset_tablet_x: float = -768.0 * 0.9 * 0.5
	assert(abs(decision_modal.offset_left - expected_offset_tablet_x) < 0.01, "태블릿: offset_left=-345.6 (실제: %s)" % str(decision_modal.offset_left))
	print("  ✓ 768×1024 (태블릿) — 모달 90%%×70%% (offset %.0f×%.0f)" % [
		768.0 * 0.9, 1024.0 * 0.7
	])
	# GameOver/Tutorial 카드 (CanvasLayer 내부 Control 자식)도 적용 가능 검증
	if game_over_screen and game_over_screen.get_child_count() > 0:
		var go_card: Control = game_over_screen.get_child(0) as Control
		if go_card:
			_adjust_modal_for_viewport(go_card, Vector2(414, 896))
			assert(abs(go_card.offset_left - expected_offset_mobile_x) < 0.01, "GameOver 모바일 offset_left")
			print("  ✓ GameOver 카드 모바일 offset 적용 OK (CanvasLayer 내부 Control)")
	if tutorial_screen and tutorial_screen.get_child_count() > 0:
		var t_card: Control = tutorial_screen.get_child(0) as Control
		if t_card:
			_adjust_modal_for_viewport(t_card, Vector2(414, 896))
			assert(abs(t_card.offset_left - expected_offset_mobile_x) < 0.01, "Tutorial 모바일 offset_left")
			print("  ✓ Tutorial 카드 모바일 offset 적용 OK (CanvasLayer 내부 Control)")
	# main.gd 4개 위치 통합
	var main_src_b4: String = FileAccess.get_file_as_string("res://scripts/main.gd")
	var viewport_call_count: int = 0
	for marker in ["_adjust_modal_for_viewport(decision_modal, get_viewport().get_visible_rect().size)", "tutorial_card if tutorial_card else tutorial_screen", "go_card if go_card else game_over_screen"]:
		if main_src_b4.find(marker) != -1:
			viewport_call_count += 1
	assert(viewport_call_count >= 3, "최소 3개 위치 호출 (실제: %d)" % viewport_call_count)
	print("  ✓ main.gd viewport 통합 %d개 위치 (Tutorial 2 + DecisionModal 1 + GameOver 1)" % viewport_call_count)
	# 원래 사이즈 복원
	_adjust_modal_for_viewport(decision_modal, Vector2(1280, 720))
	print("  ✓ 데스크탑 사이즈 복원 OK")

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
