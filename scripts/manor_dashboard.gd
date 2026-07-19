extends Control
## manor_dashboard.gd v2.3 — Wesnoth 2D 풍경도 + 캐릭터 호버/클릭 + 시간대 그라디언트 + Roster

# 동적 노드
var scene_root: Node2D = null
var visitor_desc: Label = null
var stats_gold_change: Label = null
var stats_food_change: Label = null
var stats_days: Label = null
var roster_vbox: VBoxContainer = null
var manor_title: Label = null
# 시간대 그라디언트용 ColorRect 참조
var bg_color_rect: ColorRect = null
# 라인 차트
var chart_canvas: Control = null
var chart_title: Label = null
# 클릭 상세정보 패널
var detail_panel: PanelContainer = null
var detail_vbox: VBoxContainer = null
var detail_visible_default: bool = false   # 라벨은 처음에 숨김

# 캐릭터 5명 (time-of-day 그라디언트 색상도 저장)
var scene_characters: Array = []   # [{area, sprite, label, name, class, wage, loyalty, original_pos}]

const SCENE_SIZE := Vector2(720, 460)
const HOVER_SCALE_BOOST := 0.08
const SCENE_BG_DAY := Color(0.32, 0.36, 0.22, 1)
const SCENE_BG_NIGHT := Color(0.06, 0.07, 0.14, 1)
const SCENE_BG_DAWN := Color(0.32, 0.22, 0.22, 1)
const SCENE_BG_DUSK := Color(0.32, 0.18, 0.12, 1)
const GROUND_COLOR := Color(0.48, 0.42, 0.28, 1)
const GROUND_NIGHT := Color(0.22, 0.18, 0.14, 1)

# v4.0.0 차트 색상 (UITheme 동기화)
const CHART_GOLD := Color(0.95, 0.78, 0.2, 1.0)
const CHART_FOOD := Color(0.6, 0.85, 0.4, 1.0)
const CHART_GRID := Color(0.30, 0.25, 0.20, 0.4)
const CHART_BG := Color(0.05, 0.04, 0.03, 0.85)

# v4.0.0 스카이 톤 그라디언트 (시간대 색 좀 더 세련되게)
const SCENE_SKY_DAY := Color(0.40, 0.45, 0.30, 1.0)
const SCENE_SKY_DAWN := Color(0.45, 0.30, 0.25, 1.0)
const SCENE_SKY_DUSK := Color(0.42, 0.22, 0.18, 1.0)
const SCENE_SKY_NIGHT := Color(0.08, 0.09, 0.18, 1.0)
const GROUND_DAY := Color(0.55, 0.46, 0.30, 1.0)
const GROUND_NIGHT_2 := Color(0.18, 0.15, 0.12, 1.0)

const SCENE_UNITS := [
	{ "path": "res://assets/units/human-loyalists/general.png",   "pos": Vector2(360, 240), "scale": 2.0, "label": "영주",     "name": "토르바르", "class": "영주",    "wage": 0,  "loyalty": 100 },
	{ "path": "res://assets/units/human-loyalists/swordsman.png", "pos": Vector2(160, 260), "scale": 1.8, "label": "기사",     "name": "에드윈",   "class": "기사",    "wage": 12, "loyalty": 80 },
	{ "path": "res://assets/units/human-loyalists/spearman.png",  "pos": Vector2(240, 260), "scale": 1.8, "label": "보병",     "name": "린",       "class": "궁수",    "wage": 5,  "loyalty": 65 },
	{ "path": "res://assets/units/human-loyalists/bowman.png",    "pos": Vector2(440, 260), "scale": 1.8, "label": "궁수",     "name": "그림발트", "class": "모병대장", "wage": 15, "loyalty": 50 },
	{ "path": "res://assets/units/human-outlaws/bandit.png",      "pos": Vector2(540, 280), "scale": 1.6, "label": "모병",     "name": "엘가르",   "class": "정찰병",  "wage": 7,  "loyalty": 70 },
]

const ROSTER := [
	{ "name": "토르바르", "class": "영주",       "wage": 0,  "loyalty": 100, "img": "res://assets/units/human-loyalists/general.png" },
	{ "name": "에드윈",   "class": "기사",       "wage": 12, "loyalty": 80,  "img": "res://assets/units/human-loyalists/swordsman.png" },
	{ "name": "린",       "class": "궁수",       "wage": 5,  "loyalty": 65,  "img": "res://assets/units/human-loyalists/bowman.png" },
	{ "name": "그림발트", "class": "모병대장",   "wage": 15, "loyalty": 50,  "img": "res://assets/units/human-outlaws/bandit.png" },
	{ "name": "엘가르",   "class": "정찰병",     "wage": 7,  "loyalty": 70,  "img": "res://assets/units/human-loyalists/spearman.png" },
]

func _ready() -> void:
	_find_nodes()
	_apply_colors()
	_draw_manor_scene()
	_refresh_roster()
	_refresh_status()
	GameWorld.resource_changed.connect(_on_resource_changed)
	GameWorld.event_logged.connect(_on_event_logged)
	TimeManager.tick_advanced.connect(_on_tick)

func _apply_colors() -> void:
	# 색상만 입히기 — tscn 구조는 검증된 v3.1.6 그대로
	var bg: ColorRect = get_node_or_null("BG") as ColorRect
	if bg:
		bg.color = UITheme.BG_BASE
	# ManorTitle 라벨 색상
	if manor_title:
		manor_title.add_theme_color_override("font_color", UITheme.TEXT_TITLE)
	# ChartTitleLabel 색상
	var chart_title: Label = get_node_or_null("CenterRoot/LeftColumn/ChartRow/ChartTitleLabel") as Label
	if chart_title:
		chart_title.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	# Roster title 라벨
	var roster_title_label: Label = get_node_or_null("CenterRoot/RightColumn/RosterTitle/RosterTitleLabel") as Label
	if roster_title_label:
		roster_title_label.add_theme_color_override("font_color", UITheme.TEXT_TITLE)

func _find_nodes() -> void:
	scene_root = get_node_or_null("CenterRoot/LeftColumn/ManorScene/SceneHost/SceneRoot") as Node2D
	visitor_desc = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/VisitorCard/VisitorVBox/VisitorDesc") as Label
	stats_gold_change = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/QuickStatsCard/StatsVBox/StatsGoldChange") as Label
	stats_food_change = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/QuickStatsCard/StatsVBox/StatsFoodChange") as Label
	stats_days = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/QuickStatsCard/StatsVBox/StatsDays") as Label
	roster_vbox = get_node_or_null("CenterRoot/RightColumn/RosterList/RosterScroll/RosterVBox") as VBoxContainer
	manor_title = get_node_or_null("CenterRoot/LeftColumn/ManorTitle/TitleLabel") as Label
	detail_panel = get_node_or_null("CenterRoot/LeftColumn/ManorScene/SceneHost/DetailPanel") as PanelContainer
	if detail_panel:
		# 기본 숨김 — 호버할 때만 표시
		detail_panel.visible = false
		detail_vbox = detail_panel.get_node_or_null("VBox") as VBoxContainer
		if detail_vbox:
			detail_vbox.visible = false
	chart_canvas = get_node_or_null("CenterRoot/LeftColumn/ChartRow/ChartCard/ChartCanvas") as Control
	# chart_title은 차트 카드 밖 ChartRow의 ChartTitleLabel — 명시적 갱신은 _refresh_chart에서
	if chart_canvas:
		chart_canvas.draw.connect(_draw_chart)
		print("[Dashboard] 차트 캔버스 연결 완료 (텍스트는 차트 카드 위쪽 ChartRow Label)")
	var scene_state: String = "OK" if scene_root else "NULL"
	var detail_state: String = "OK" if detail_panel else "NULL"
	print("[Dashboard] 동적 노드 검색 완료 (scene_root=%s, detail_panel=%s)" % [scene_state, detail_state])

func _draw_manor_scene() -> void:
	if scene_root == null:
		push_error("[Dashboard] scene_root 없음")
		return
	# 배경 풀밭 (시작 색 = 낮 풀밭)
	bg_color_rect = ColorRect.new()
	bg_color_rect.color = SCENE_BG_DAY
	bg_color_rect.size = SCENE_SIZE
	bg_color_rect.position = Vector2.ZERO
	bg_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(bg_color_rect)

	# 흙길
	var ground := ColorRect.new()
	ground.color = GROUND_COLOR
	ground.size = Vector2(SCENE_SIZE.x, 140)
	ground.position = Vector2(0, 280)
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(ground)

	# 경계선
	var ridge := ColorRect.new()
	ridge.color = Color(0.32, 0.28, 0.16, 1)
	ridge.size = Vector2(SCENE_SIZE.x, 4)
	ridge.position = Vector2(0, 280)
	ridge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(ridge)

	# 영지 휘장 라벨
	var banner := Label.new()
	banner.text = "토르바르의 영지 — 황야의 변방"
	banner.position = Vector2(20, 20)
	banner.add_theme_font_size_override("font_size", 20)
	banner.add_theme_color_override("font_color", UITheme.TEXT_TITLE)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(banner)

	# 캐릭터 5명 (Area2D + Sprite2D)
	for unit in SCENE_UNITS:
		_add_unit_sprite(unit)

	print("[Dashboard] sprite loaded: 5 / 5 + 호버/클릭 인터랙션 ON")

func _add_unit_sprite(unit: Dictionary) -> void:
	var path: String = unit.get("path", "")
	if not ResourceLoader.exists(path):
		push_warning("[Dashboard] 자산 없음: %s" % path)
		return
	var tex: Texture2D = load(path)
	if tex == null or tex.get_width() == 0:
		push_warning("[Dashboard] 텍스처 로드 실패: %s" % path)
		return
	# TextureButton — Control 기반이라 Control 부모 (SceneHost)에서 마우스 이벤트 정상 작동
	var btn := TextureButton.new()
	btn.texture_normal = tex
	btn.texture_pressed = tex
	btn.texture_hover = tex
	btn.texture_focused = tex
	btn.ignore_texture_size = true
	btn.position = unit.get("pos", Vector2.ZERO) - Vector2(tex.get_width() * unit.get("scale", 1.0) / 2.0, tex.get_height() * unit.get("scale", 1.0) / 2.0)
	btn.size = Vector2(tex.get_width() * unit.get("scale", 1.0), tex.get_height() * unit.get("scale", 1.0))
	btn.custom_minimum_size = btn.size
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	scene_root.add_child(btn)

	# 라벨 (sprite 아래) — SceneHost의 자식 (TextureButton과 형제)으로 두면 클릭 방해 안 함
	var lbl := Label.new()
	lbl.text = unit.get("label", "")
	lbl.position = (unit.get("pos", Vector2.ZERO) + Vector2(-32, 70)) as Vector2
	lbl.size = Vector2(64, 22)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", UITheme.TEXT_TITLE)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_root.add_child(lbl)

	# 캐릭터 데이터 저장 (original_position = 처음 부착했을 때 위치)
	var character := {
		"area": btn,   # TextureButton (Control)
		"button": btn,
		"label": lbl,
		"name": unit.get("name", "?"),
		"class": unit.get("class", "?"),
		"wage": unit.get("wage", 0),
		"loyalty": unit.get("loyalty", 0),
		"original_scale": unit.get("scale", 1.0),
		"original_size": btn.size,
		"original_position": btn.position,
		"is_hovered": false,
	}
	scene_characters.append(character)
	btn.mouse_entered.connect(_on_character_hover.bind(character))
	btn.mouse_exited.connect(_on_character_unhover.bind(character))
	# 클릭 핸들러는 의도적으로 연결하지 않음 (호버만으로 인터랙션)

func _on_character_hover(character: Dictionary) -> void:
	character["is_hovered"] = true
	# size 키워도 중심점이 그대로 유지되도록 position 보정 (centered 효과)
	var btn: TextureButton = character.get("button")
	if btn:
		var orig: Vector2 = character.get("original_size", Vector2.ZERO)
		var orig_pos: Vector2 = character.get("original_position", btn.position)
		var boosted: Vector2 = orig * (1.0 + HOVER_SCALE_BOOST)
		# delta = boosted - orig, 중심점 보존 위해 position -= delta/2
		var delta: Vector2 = (boosted - orig) * 0.5
		btn.position = orig_pos - delta
		btn.size = boosted
		# 다음 unhover를 위해 original_position 저장
		character["original_position"] = orig_pos
	# 상태창 표시 + 캐릭터 정보 갱신
	if detail_panel:
		detail_panel.visible = true
	_show_character_detail(character)

func _on_character_unhover(character: Dictionary) -> void:
	character["is_hovered"] = false
	var btn: TextureButton = character.get("button")
	if btn:
		var orig: Vector2 = character.get("original_size", Vector2.ZERO)
		var orig_pos: Vector2 = character.get("original_position", btn.position)
		# 원래 위치 + 원래 크기 복귀
		btn.position = orig_pos
		btn.size = orig
	# 모든 캐릭터에서 hover 떠났으면 상태창 숨김 (다른 캐릭터 hover 중이 아닐 때)
	if detail_vbox:
		var any_hovered := false
		for c in scene_characters:
			if c.get("is_hovered", false):
				any_hovered = true
				break
		if not any_hovered:
			detail_vbox.visible = false
			if detail_panel:
				detail_panel.visible = false

func _show_character_detail(character: Dictionary) -> void:
	if detail_vbox == null:
		return
	# 헤더 라벨들 모두 제거 + 새로 채우기
	for child in detail_vbox.get_children():
		child.queue_free()
	var title := Label.new()
	title.text = "👤 %s · %s" % [character.get("name", "?"), character.get("class", "?")]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UITheme.TEXT_TITLE)
	detail_vbox.add_child(title)

	var wage := Label.new()
	wage.text = "💰 일급: %d 골드" % character.get("wage", 0)
	wage.add_theme_font_size_override("font_size", 14)
	wage.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	detail_vbox.add_child(wage)

	var loy: int = character.get("loyalty", 0)
	var loyalty := Label.new()
	loyalty.text = "★ 충성도: %d / 100" % loy
	loyalty.add_theme_font_size_override("font_size", 14)
	loyalty.add_theme_color_override("font_color", UITheme.loyalty_color(loy))
	detail_vbox.add_child(loyalty)

	var state := Label.new()
	if loy >= 70:
		state.text = "상태: 충실 — 이적 위험 낮음"
	elif loy >= 40:
		state.text = "상태: 보통 — 이적 가능성 있음"
	else:
		state.text = "상태: 불만 — 이적/탈영 위험"
	state.add_theme_font_size_override("font_size", 13)
	state.add_theme_color_override("font_color", UITheme.loyalty_color(loy))
	detail_vbox.add_child(state)

	# 닫기 힌트
	var hint := Label.new()
	hint.text = "(다른 캐릭터 호버 시 갱신)"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	detail_vbox.add_child(hint)

	detail_vbox.visible = true

func _refresh_roster() -> void:
	if roster_vbox == null:
		return
	for child in roster_vbox.get_children():
		child.queue_free()
	for merc in ROSTER:
		roster_vbox.add_child(_build_roster_row(merc))
	var roster_title_label := get_node_or_null("CenterRoot/RightColumn/RosterTitle/RosterTitleLabel") as Label
	if roster_title_label:
		roster_title_label.text = "⚔️ 용병 (%d명)" % ROSTER.size()

func _build_roster_row(merc: Dictionary) -> HBoxContainer:
	# v3.1.6 검증된 형태 — 단순 HBoxContainer (UITheme 색상만 입힘)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 56)
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_avatar(merc.get("img", "")))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = 3
	var name_lbl := Label.new()
	name_lbl.text = "%s · %s" % [merc.get("name", ""), merc.get("class", "")]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	info.add_child(name_lbl)
	var wage_lbl := Label.new()
	wage_lbl.text = "💰 %d/일  ★ %d/100" % [merc.get("wage", 0), merc.get("loyalty", 0)]
	wage_lbl.add_theme_font_size_override("font_size", 11)
	wage_lbl.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	info.add_child(name_lbl)
	info.add_child(wage_lbl)
	row.add_child(info)
	return row

func _make_avatar(path: String) -> Control:
	if path != "" and ResourceLoader.exists(path):
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = 1
		tex_rect.stretch_mode = 5
		var tex: Texture2D = load(path)
		if tex != null and tex.get_width() > 0:
			tex_rect.texture = tex
			return tex_rect
	var ph := ColorRect.new()
	ph.custom_minimum_size = Vector2(48, 48)
	ph.color = Color(0.3, 0.3, 0.3, 1)
	return ph

## 시간대 그라디언트 — 배경 + 흙길 색 보간
func _update_time_of_day_colors() -> void:
	if bg_color_rect == null:
		return
	var hour: int = (TimeManager.minutes_elapsed % 1440) / 60
	var bg: Color = SCENE_BG_DAY
	var ground: Color = GROUND_COLOR
	if hour >= 5 and hour < 8:        # 새벽 (5-8)
		var t: float = float(hour - 5) / 3.0
		bg = SCENE_BG_DAY.lerp(SCENE_BG_DAWN, t) if t < 0.5 else SCENE_BG_DAWN.lerp(Color(0.4, 0.32, 0.16, 1), (t - 0.5) * 2)
	elif hour >= 8 and hour < 17:    # 낮
		bg = SCENE_BG_DAY
	elif hour >= 17 and hour < 20:    # 노을
		var t2: float = float(hour - 17) / 3.0
		bg = SCENE_BG_DAY.lerp(SCENE_BG_DUSK, t2)
	elif hour >= 20 or hour < 4:      # 밤
		bg = SCENE_BG_NIGHT
		ground = GROUND_NIGHT
	else:
		bg = SCENE_BG_DAY
	bg_color_rect.color = bg
	# 흙길도 어두워짐 (씬에 흙길 ColorRect가 1번만 추가됨)
	var ground_node := scene_root.get_child(2) if scene_root and scene_root.get_child_count() > 2 else null
	if ground_node and ground_node is ColorRect:
		ground_node.color = ground

func _refresh_status() -> void:
	if manor_title:
		manor_title.text = "🏰 %s의 영지 — 황야의 변방" % GameWorld.lord_name
		manor_title.add_theme_color_override("font_color", UITheme.TEXT_TITLE)
	if stats_gold_change:
		var g: int = GameWorld.day_gold_change
		stats_gold_change.text = "💰 오늘 %s" % UITheme.format_change(g)
		stats_gold_change.add_theme_color_override("font_color", UITheme.change_color(g))
	if stats_food_change:
		var f: int = GameWorld.day_food_change
		stats_food_change.text = "🌾 오늘 %s" % UITheme.format_change(f)
		stats_food_change.add_theme_color_override("font_color", UITheme.change_color(f))
	if stats_days:
		stats_days.text = "📅 경과: %d일" % TimeManager.day
		stats_days.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	# VisitorDesc — 결정 큐 첫 항목 강조
	if visitor_desc:
		var pending: Array = DecisionQueue.get_all_pending()
		if pending.is_empty():
			visitor_desc.text = "대기 중인 결정 없음 — 평화로운 시간"
			visitor_desc.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		else:
			var first: Dictionary = pending[0]
			var pname: String = DecisionQueue.Priority.keys()[first.priority]
			visitor_desc.text = "[%s] %s" % [pname, first.payload.get("title", "")]
			visitor_desc.add_theme_color_override("font_color", UITheme.priority_color(first.priority))

func _on_resource_changed(_r: String, _v: int) -> void:
	_refresh_status()

func _on_event_logged(_msg: String) -> void:
	_refresh_status()

func _on_tick(_game_time: int) -> void:
	_update_time_of_day_colors()   # 매 tick마다 색 보간 (60초 = 1일, 색 변화 자연스러움)
	_refresh_chart()               # 자원 변동 시 차트 갱신

func _refresh_chart() -> void:
	if chart_canvas:
		chart_canvas.queue_redraw()

## 라인 차트 그리기 — Control._draw() 오버라이드 (실제로는 draw 시그널로)
## v4.0.0 — CHART_BG 배경 + 범례 + 두꺼운 라인 + 글리프 도트
func _draw_chart() -> void:
	if not chart_canvas:
		return
	var history: Array = GameWorld.history
	var size: Vector2 = chart_canvas.size
	var padding := Vector2(28, 16)
	var plot_w: float = max(size.x - padding.x * 2, 0.0)
	var plot_h: float = max(size.y - padding.y * 2 - 14, 0.0)   # 하단 범례 공간

	# 배경 (라운드 사각형 — 그라디언트 효과)
	chart_canvas.draw_rect(Rect2(Vector2.ZERO, size), CHART_BG)
	# 보더 라인
	chart_canvas.draw_line(Vector2(0, 0), Vector2(size.x, 0), CHART_GRID, 1.0)
	chart_canvas.draw_line(Vector2(0, size.y), Vector2(size.x, size.y), CHART_GRID, 1.0)

	if history.size() < 1:
		var default_font: Font = ThemeDB.fallback_font
		chart_canvas.draw_string(default_font,
			Vector2(size.x / 2 - 40, size.y / 2),
			"(데이터 누적 중)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.6, 0.6, 0.7))
		_draw_legend(size)
		return

	# max 정규화
	var max_gold: int = 1
	var max_food: int = 1
	for h in history:
		if int(h.get("gold", 0)) > max_gold: max_gold = int(h.get("gold", 0))
		if int(h.get("food", 0)) > max_food: max_food = int(h.get("food", 0))

	# 그리드 (수평선 4개)
	for i in range(5):
		var y: float = padding.y + plot_h * float(i) / 4.0
		chart_canvas.draw_line(
			Vector2(padding.x, y),
			Vector2(padding.x + plot_w, y),
			CHART_GRID, 1.0
		)

	# 골드 라인 (금색)
	_draw_series(history, "gold", CHART_GOLD,
		padding, plot_w, plot_h, max_gold)
	# 식량 라인 (연두)
	_draw_series(history, "food", CHART_FOOD,
		padding, plot_w, plot_h, max_food)
	# 범례
	_draw_legend(size)

	# 텍스트 라벨 (차트 Card 위쪽 — ChartRow/ChartTitleLabel)
	var chart_row_label: Label = get_node_or_null("CenterRoot/LeftColumn/ChartRow/ChartTitleLabel") as Label
	if chart_row_label and history.size() >= 1:
		var last_gold: int = int(history[-1].gold)
		var last_food: int = int(history[-1].food)
		chart_row_label.text = "📈 자원 추이 (%d일, 금 %d, 식량 %d)" % [history.size(), last_gold, last_food]


func _draw_legend(size: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font
	var y_base: float = size.y - 12
	# 골드 범례 (좌측)
	chart_canvas.draw_rect(Rect2(Vector2(8, y_base - 6), Vector2(10, 4)), CHART_GOLD)
	chart_canvas.draw_string(font, Vector2(22, y_base), "금", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, CHART_GOLD)
	# 식량 범례 (우측)
	chart_canvas.draw_rect(Rect2(Vector2(48, y_base - 6), Vector2(10, 4)), CHART_FOOD)
	chart_canvas.draw_string(font, Vector2(62, y_base), "식량", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, CHART_FOOD)


func _draw_series(history: Array, key: String, color: Color,
		padding: Vector2, plot_w: float, plot_h: float, max_val: int) -> void:
	var n: int = history.size()
	if n < 1:
		return
	var denom: float = float(max(max_val, 1))
	var points: Array = []
	for i in range(n):
		var x: float = padding.x + plot_w * (float(i) / max(float(n - 1), 1.0))
		var v: int = int(history[i].get(key, 0))
		var y: float = padding.y + plot_h * (1.0 - float(v) / denom)
		points.append(Vector2(x, y))
	# 그림자 (좀 더 진하게)
	for i in range(points.size() - 1):
		chart_canvas.draw_line(points[i] + Vector2(0, 1), points[i + 1] + Vector2(0, 1), Color(0, 0, 0, 0.5), 3.5)
	# 본 라인 (두껍게)
	for i in range(points.size() - 1):
		chart_canvas.draw_line(points[i], points[i + 1], color, 2.5)
	# 데이터 포인트 (글리프 도트)
	for p in points:
		chart_canvas.draw_circle(p, 3.5, color)
		chart_canvas.draw_arc(p, 3.5, 0, TAU, 12, Color(0, 0, 0, 0.4), 1.0)
