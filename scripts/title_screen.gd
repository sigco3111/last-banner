extends Control
## title_screen.gd — 타이틀 화면 (시작 / 이어하기 / 종료 / 튜토리얼 다시보기)
## SaveManager.list_saves()로 저장 파일 존재 여부 확인 → '이어하기' 버튼 활성/비활성

signal start_new_game
signal continue_game
signal quit_game_requested
signal retutorial_requested

var start_button: Button = null
var continue_button: Button = null
var tutorial_button: Button = null
var quit_button: Button = null
var status_label: Label = null

func _ready() -> void:
	_find_nodes()
	_connect_signals()
	_apply_styles()
	_refresh_continue_button()

func _find_nodes() -> void:
	start_button = get_node_or_null("CenterBox/StartButton") as Button
	continue_button = get_node_or_null("CenterBox/ContinueButton") as Button
	tutorial_button = get_node_or_null("CenterBox/TutorialButton") as Button
	quit_button = get_node_or_null("CenterBox/QuitButton") as Button
	status_label = get_node_or_null("CenterBox/StatusLabel") as Label
	print("[Title] 동적 노드 검색 완료")

func _apply_styles() -> void:
	# 타이틀 배경
	var bg: ColorRect = get_node_or_null("BG") as ColorRect
	if bg:
		bg.color = UITheme.BG_BASE
	# 타이틀 로고 / 태그라인 색상
	var logo: Label = get_node_or_null("CenterBox/Logo") as Label
	if logo:
		logo.add_theme_color_override("font_color", UITheme.TEXT_TITLE)
	var tagline: Label = get_node_or_null("CenterBox/Tagline") as Label
	if tagline:
		tagline.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	# 버튼 색상 (모든 4상태)
	UITheme.apply_button_styles(start_button, UITheme.BG_BUTTON.lerp(UITheme.COLOR_GOLD, 0.18))
	UITheme.apply_button_styles(continue_button, UITheme.BG_BUTTON.lerp(UITheme.COLOR_FOOD, 0.12))
	UITheme.apply_button_styles(tutorial_button, UITheme.BG_BUTTON.lerp(UITheme.COLOR_POPULATION, 0.10))
	UITheme.apply_button_styles(quit_button, UITheme.BG_BUTTON.lerp(UITheme.TEXT_DANGER, 0.15))
	# 상태 라벨
	if status_label:
		status_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)

func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if tutorial_button:
		tutorial_button.pressed.connect(_on_tutorial_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _refresh_continue_button() -> void:
	var saves: Array = SaveManager.list_saves()
	if continue_button:
		if saves.is_empty():
			continue_button.disabled = true
			continue_button.text = "⏵ 이어하기 (저장 없음)"
		else:
			continue_button.disabled = false
			# 가장 최근 저장 표시
			continue_button.text = "⏵ 이어하기 (%d개 저장)" % saves.size()
			if status_label:
				status_label.text = "마지막 저장: %s" % saves[0]

func _on_start_pressed() -> void:
	print("[Title] 새로 시작")
	emit_signal("start_new_game")

func _on_continue_pressed() -> void:
	print("[Title] 이어하기 — 최근 저장 파일 로드")
	emit_signal("continue_game")

func _on_quit_pressed() -> void:
	print("[Title] 게임 종료")
	emit_signal("quit_game_requested")
	get_tree().quit()

func _on_tutorial_pressed() -> void:
	print("[Title] 튜토리얼 다시보기")
	emit_signal("retutorial_requested")

## 외부에서 '이어하기' 가능 상태 강제 갱신 (save 후 등)
func refresh() -> void:
	_refresh_continue_button()
