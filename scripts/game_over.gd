extends CanvasLayer
## game_over.gd — v4.1 B-3 게임 오버 화면
## 3가지 패배 조건 (인구 멸망 / 대기아 / 왕조 멸절) + 종료 통계 + 메인 메뉴 복귀

signal return_to_title_requested

const REASON_LABELS := {
	"POPULATION_EXTINCTION": "인구 멸망",
	"FOOD_FAMINE": "대기아 (식량 0 연속 30일)",
	"DYNASTY_EXTINCTION": "왕조 멸절",
}

const REASON_DESCRIPTIONS := {
	"POPULATION_EXTINCTION": "영지의 인구가 모두 사라졌습니다.\n전쟁·역병·기근이 겹치며 백성이 뿔뿔이 흘어졌습니다.\n당신의 영지는 이제 텅 빈 폐허입니다.",
	"FOOD_FAMINE": "30일 연속으로 식량이 바닥났습니다.\n마을은 텅 비고, 아이들이 울음을 멈췄습니다.\n마지막 창고가 비어가는 날, 영지도 함께 무너졌습니다.",
	"DYNASTY_EXTINCTION": "영주와 모든 후보·신하가 사망했습니다.\n가문의 마지막 이름이 역사에서 지워졌습니다.\n영지를 누가 이을 것인지는 이제 아무도 모릅니다.",
}

# 동적 노드
var dim_bg: ColorRect = null
var card: PanelContainer = null
var reason_icon: Label = null
var reason_title: Label = null
var reason_desc: Label = null
var stats_vbox: VBoxContainer = null
var day_label: Label = null
var return_button: Button = null

func _ready() -> void:
	layer = 120   # 모달(100)보다 위, 튜토리얼(15)보다 위
	visible = false
	_find_nodes()
	_connect_signals()

func _find_nodes() -> void:
	dim_bg = get_node_or_null("DimBG") as ColorRect
	card = get_node_or_null("Card") as PanelContainer
	if card:
		reason_icon = card.get_node_or_null("Margin/VBox/HeaderRow/IconLabel") as Label
		reason_title = card.get_node_or_null("Margin/VBox/HeaderRow/TitleLabel") as Label
		reason_desc = card.get_node_or_null("Margin/VBox/DescriptionLabel") as Label
		day_label = card.get_node_or_null("Margin/VBox/DayLabel") as Label
		stats_vbox = card.get_node_or_null("Margin/VBox/StatsVBox") as VBoxContainer
		return_button = card.get_node_or_null("Margin/VBox/ButtonRow/ReturnButton") as Button

func _connect_signals() -> void:
	if return_button:
		return_button.pressed.connect(_on_return_pressed)
	# 배경 클릭도 닫기
	if dim_bg:
		dim_bg.gui_input.connect(_on_dim_gui_input)

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_return_pressed()

func show_game_over(reason: String, day: int, stats: Dictionary) -> void:
	visible = true
	# 아이콘 + 제목
	var reason_text: String = REASON_LABELS.get(reason, "패배")
	var reason_icon_text: String = ""
	match reason:
		"POPULATION_EXTINCTION": reason_icon_text = "💀"
		"FOOD_FAMINE": reason_icon_text = "🌾"
		"DYNASTY_EXTINCTION": reason_icon_text = "👑"
		_: reason_icon_text = "⚰️"
	if reason_icon:
		reason_icon.text = reason_icon_text
		reason_icon.add_theme_font_size_override("font_size", 56)
	if reason_title:
		reason_title.text = "%s — %s" % [reason_icon_text, reason_text]
	# 설명
	if reason_desc:
		reason_desc.text = REASON_DESCRIPTIONS.get(reason, "영지가 무너졌습니다.")
	# 생존 일수
	if day_label:
		day_label.text = "생존 일수: %d일" % day
	# 통계 (stats_vbox 안에 라벨 동적 생성)
	if stats_vbox:
		for child in stats_vbox.get_children():
			child.queue_free()
		var stat_labels := [
			"💰 금: %d" % int(stats.get("gold", 0)),
			"🌾 식량: %d" % int(stats.get("food", 0)),
			"👥 인구: %d" % int(stats.get("population", 0)),
			"⭐ 명성: %d" % int(stats.get("prosperity", 0)),
			"🏰 요새 Lv %d" % int(stats.get("fortification_level", 1)),
			"⚔️ 생존 용병: %d명" % int(stats.get("roster_count", 0)),
			"👑 생존 왕조 인물: %d명" % int(stats.get("court_count", 0)),
		]
		for s in stat_labels:
			var lbl := Label.new()
			lbl.text = s
			lbl.add_theme_font_size_override("font_size", 14)
			stats_vbox.add_child(lbl)
	print("[GameOver] %s (Day %d)" % [reason, day])

func _on_return_pressed() -> void:
	print("[GameOver] 메인 메뉴로 복귀")
	emit_signal("return_to_title_requested")