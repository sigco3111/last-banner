extends Control
## manor_dashboard.gd — Wesnoth 2D 풍경도 (SubViewport 없이) + 용병 roster + 방문객 알림

# 동적 노드
var scene_root: Node2D = null       # Node2D (Control의 자식) — Sprite + ColorRect + Label 부모
var visitor_desc: Label = null
var stats_gold_change: Label = null
var stats_food_change: Label = null
var stats_days: Label = null
var roster_vbox: VBoxContainer = null
var manor_title: Label = null

const SCENE_BG_COLOR := Color(0.32, 0.36, 0.22, 1)
const GROUND_COLOR := Color(0.48, 0.42, 0.28, 1)
const SCENE_SIZE := Vector2(720, 460)   # 풍경도 영역 픽셀 크기 (PanelContainer 따라 자동 stretch)

# 5명 idle PNG — 실제 파일 검증된 이름
const SCENE_UNITS := [
	{ "path": "res://assets/units/human-loyalists/general.png",   "pos": Vector2(360, 240), "scale": 2.0, "label": "영주" },
	{ "path": "res://assets/units/human-loyalists/swordsman.png", "pos": Vector2(160, 260), "scale": 1.8, "label": "기사" },
	{ "path": "res://assets/units/human-loyalists/spearman.png",  "pos": Vector2(240, 260), "scale": 1.8, "label": "보병" },
	{ "path": "res://assets/units/human-loyalists/bowman.png",    "pos": Vector2(440, 260), "scale": 1.8, "label": "궁수" },
	{ "path": "res://assets/units/human-outlaws/bandit.png",      "pos": Vector2(540, 280), "scale": 1.6, "label": "모병" },
]

# Roster — 5명 (모두 같은 idle PNG 사용, 이름/직책 다양화)
const ROSTER := [
	{ "name": "토르바르", "class": "영주",       "wage": 0,  "loyalty": 100, "img": "res://assets/units/human-loyalists/general.png" },
	{ "name": "에드윈",   "class": "기사",       "wage": 12, "loyalty": 80,  "img": "res://assets/units/human-loyalists/swordsman.png" },
	{ "name": "린",       "class": "궁수",       "wage": 5,  "loyalty": 65,  "img": "res://assets/units/human-loyalists/bowman.png" },
	{ "name": "그림발트", "class": "모병대장",   "wage": 15, "loyalty": 50,  "img": "res://assets/units/human-outlaws/bandit.png" },
	{ "name": "엘가르",   "class": "정찰병",     "wage": 7,  "loyalty": 70,  "img": "res://assets/units/human-loyalists/spearman.png" },
]

func _ready() -> void:
	_find_nodes()
	_draw_manor_scene()
	_refresh_roster()
	_refresh_status()
	GameWorld.resource_changed.connect(_on_resource_changed)
	GameWorld.event_logged.connect(_on_event_logged)

func _find_nodes() -> void:
	# 새 경로 — SubViewport 없이 SceneHost/SceneRoot 직접 참조
	scene_root = get_node_or_null("CenterRoot/LeftColumn/ManorScene/SceneHost/SceneRoot") as Node2D
	visitor_desc = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/VisitorCard/VisitorVBox/VisitorDesc") as Label
	stats_gold_change = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/QuickStatsCard/StatsVBox/StatsGoldChange") as Label
	stats_food_change = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/QuickStatsCard/StatsVBox/StatsFoodChange") as Label
	stats_days = get_node_or_null("CenterRoot/LeftColumn/BottomRowInColumn/QuickStatsCard/StatsVBox/StatsDays") as Label
	roster_vbox = get_node_or_null("CenterRoot/RightColumn/RosterList/RosterScroll/RosterVBox") as VBoxContainer
	manor_title = get_node_or_null("CenterRoot/LeftColumn/ManorTitle/TitleLabel") as Label
	print("[Dashboard] 동적 노드 검색 완료 (scene_root=%s)" % ("OK" if scene_root else "NULL"))

func _draw_manor_scene() -> void:
	if scene_root == null:
		push_error("[Dashboard] scene_root 없음 — 씬 구조 오류")
		return

	# 배경 — 풀밭 (스크린 전체)
	var bg := ColorRect.new()
	bg.color = SCENE_BG_COLOR
	bg.size = SCENE_SIZE
	bg.position = Vector2.ZERO
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(bg)

	# 흙길 (가로 띠)
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

	# 캐릭터 5명
	var load_count := 0
	for unit in SCENE_UNITS:
		if _add_unit_sprite(unit):
			load_count += 1
	print("[Dashboard] sprite loaded: %d / 5" % load_count)

	# 영지 휘장 라벨 (좌상단)
	var banner := Label.new()
	banner.text = "토르바르의 영지 — 황야의 변방"
	banner.position = Vector2(20, 20)
	banner.add_theme_font_size_override("font_size", 20)
	banner.add_theme_color_override("font_color", Color(0.94, 0.86, 0.62))
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(banner)

	# 풍경도 갱신
	scene_root.queue_redraw()

func _add_unit_sprite(unit: Dictionary) -> bool:
	var path: String = unit.get("path", "")
	if not ResourceLoader.exists(path):
		push_warning("[Dashboard] 자산 없음: %s" % path)
		return false
	var tex: Texture2D = load(path)
	# Sprite가 비었으면 (가져오기 실패) print warning
	if tex == null or tex.get_width() == 0:
		push_warning("[Dashboard] 텍스처 로드 실패: %s" % path)
		return false
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	var pos: Vector2 = unit.get("pos", Vector2.ZERO)
	sprite.position = pos
	var sc: float = unit.get("scale", 1.0)
	sprite.scale = Vector2(sc, sc)
	scene_root.add_child(sprite)

	# 이름 라벨 (캐릭터 아래)
	var lbl := Label.new()
	lbl.text = unit.get("label", "")
	lbl.position = pos + Vector2(-32, 70)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_root.add_child(lbl)
	return true

func _refresh_roster() -> void:
	if roster_vbox == null:
		return
	for child in roster_vbox.get_children():
		child.queue_free()
	for merc in ROSTER:
		roster_vbox.add_child(_build_roster_row(merc))

	# 상단 카운트 자동 갱신
	var roster_title_label := get_node_or_null("CenterRoot/RightColumn/RosterTitle/RosterTitleLabel") as Label
	if roster_title_label:
		roster_title_label.text = "⚔️ 용병 (%d명)" % ROSTER.size()

func _build_roster_row(merc: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 56)
	row.add_theme_constant_override("separation", 8)
	row.add_child(_make_avatar(merc.get("img", "")))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = 3
	var name_lbl := Label.new()
	name_lbl.text = "%s · %s" % [merc.get("name", ""), merc.get("class", "")]
	name_lbl.add_theme_font_size_override("font_size", 13)
	var wage_lbl := Label.new()
	wage_lbl.text = "💰 %d/일  ★ %d/100" % [merc.get("wage", 0), merc.get("loyalty", 0)]
	wage_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(name_lbl)
	info.add_child(wage_lbl)
	row.add_child(info)
	return row

func _make_avatar(path: String) -> Control:
	if path != "" and ResourceLoader.exists(path):
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = 1   # IGNORE_SIZE
		tex_rect.stretch_mode = 5  # KEEP_ASPECT_CENTERED
		var tex: Texture2D = load(path)
		if tex != null and tex.get_width() > 0:
			tex_rect.texture = tex
			return tex_rect
	# fallback
	var ph := ColorRect.new()
	ph.custom_minimum_size = Vector2(48, 48)
	ph.color = Color(0.3, 0.3, 0.3, 1)
	return ph

func _refresh_status() -> void:
	if manor_title:
		manor_title.text = "🏰 영지: %s의 옥새관" % GameWorld.lord_name
	if stats_gold_change:
		var g: int = GameWorld.day_gold_change
		stats_gold_change.text = "💰 오늘: %s%d" % ["+" if g > 0 else "", g]
	if stats_food_change:
		var f: int = GameWorld.day_food_change
		stats_food_change.text = "🌾 오늘: %s%d" % ["+" if f > 0 else "", f]
	if stats_days:
		stats_days.text = "📅 경과: %d일" % TimeManager.day
	if visitor_desc:
		var pending: Array = DecisionQueue.get_all_pending()
		if pending.is_empty():
			visitor_desc.text = "대기 중인 방문객 없음"
		else:
			var first: Dictionary = pending[0]
			var pname: String = DecisionQueue.Priority.keys()[first.priority]
			visitor_desc.text = "[%s] %s" % [pname, first.payload.get("title", "")]

func _on_resource_changed(_r: String, _v: int) -> void:
	_refresh_status()

func _on_event_logged(_msg: String) -> void:
	_refresh_status()
