extends CanvasLayer
## tutorial.gd — v4.1 신규 진입 튜토리얼 오버레이
## 4단계 카드 (자동 진행 / 결정 큐 / 시스템 4종 / 마무리)
## 자동 7초 진행 + 사용자 클릭 즉시 다음 단계

signal tutorial_finished
signal tutorial_skipped

const STEPS := [
	{
		"icon": "🤖",
		"title": "자동 진행 + 위임",
		"message": "게임이 알아서 시간이 흐르고 자원이 변합니다.\n\n결정이 필요하면 모달이 자동으로 뜹니다.\n\n위임하지 않고 싶다면 P 키로 일시정지할 수 있습니다.",
		"hint": "(P: 자동 진행 토글)"
	},
	{
		"icon": "📜",
		"title": "결정 큐",
		"message": "11종 사건이 쌓입니다:\n• VISITOR (방문객) · MERCENARY_OFFER (용병)\n• BANDIT_RAID (약탈자, HIGH) · SUCCESSION_AUDIT (후계자)\n• FOOD_SHORTAGE (식량 위기) · PLAGUE (역병, CRITICAL)\n\n우선순위 LOW 3초 / 그 외 5초 후 default 결정으로 자동 resolve.\nCRITICAL은 게임을 즉시 멈춥니다.",
		"hint": "(결정 큐 우선순위: LOW / MEDIUM / HIGH / CRITICAL)"
	},
	{
		"icon": "💰",
		"title": "자원 변동 + 차트",
		"message": "5종 자원이 일간 변동합니다:\n• 💰 금 — 세수 + 용병 일급\n• 🌾 식량 — 수확 + 인구/용병 소비\n• 👥 인구 — 페스트/역병/외교 영향\n• ⭐ 명성 — 외교/사건 결과\n• 🏰 요새 — Lv 1~5\n\n우상단 차트는 7일 ring buffer + 골드/식량 시계열.",
		"hint": "(자원 추이 차트는 ManorTitle 옆에 표시)"
	},
	{
		"icon": "⚔️",
		"title": "4가지 시스템",
		"message": "Last Banner는 4가지 시스템을 동시에 운영합니다:\n\n⚔️ 용병 — 9-class tier (bowman~paladin)\n👑 왕조 — CK3 양식 후계자 + 배신\n🏗️ 빌딩 — 4종 × max Lv 3 (시장/훈련장/창고/성벽)\n📈 차트 — Control._draw() 라인 차트 (그림자 + 범례)\n\n각 시스템은 결정 큐 / 일간 변동 / 시그널로 자동 연동됩니다.",
		"hint": "(튜토리얼을 완료하면 게임을 시작합니다)"
	}
]

# 동적 노드
var dim_bg: ColorRect = null
var card: PanelContainer = null
var step_icon: Label = null
var step_title: Label = null
var step_message: Label = null
var step_hint: Label = null
var progress_label: Label = null
var next_button: Button = null
var skip_button: Button = null

var _active: bool = false
var _current_step: int = 0
var _auto_timer: SceneTreeTimer = null

const AUTO_ADVANCE_SEC := 8.0

func _ready() -> void:
	layer = 15   # 모달(100)보다 아래, UI(10)보다 위
	visible = false
	_find_nodes()
	_connect_signals()

func _find_nodes() -> void:
	dim_bg = get_node_or_null("DimBG") as ColorRect
	card = get_node_or_null("Card") as PanelContainer
	if card:
		step_icon = card.get_node_or_null("Margin/VBox/HeaderRow/IconLabel") as Label
		step_title = card.get_node_or_null("Margin/VBox/HeaderRow/TitleLabel") as Label
		progress_label = card.get_node_or_null("Margin/VBox/ProgressLabel") as Label
		step_message = card.get_node_or_null("Margin/VBox/MessageLabel") as Label
		step_hint = card.get_node_or_null("Margin/VBox/HintLabel") as Label
		next_button = card.get_node_or_null("Margin/VBox/ButtonRow/NextButton") as Button
		skip_button = card.get_node_or_null("Margin/VBox/ButtonRow/SkipButton") as Button

func _connect_signals() -> void:
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	# 배경 클릭도 다음 단계
	if dim_bg:
		dim_bg.gui_input.connect(_on_dim_gui_input)

func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_next_pressed()

func start_tutorial(force: bool = false) -> void:
	# GameManager.tutorial_seen 체크 (force=true면 무시)
	if not force and GameManager.tutorial_seen:
		print("[Tutorial] 이미 봤음 — skip")
		emit_signal("tutorial_skipped")
		return
	_current_step = 0
	_active = true
	visible = true
	# 입력 차단: 모달보다 위지만 자식들이 마우스 받음
	if dim_bg:
		dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_show_step(_current_step)
	_schedule_auto_advance(AUTO_ADVANCE_SEC)
	print("[Tutorial] 시작 (%d 단계)" % STEPS.size())

func _show_step(idx: int) -> void:
	if idx < 0 or idx >= STEPS.size():
		return
	var step: Dictionary = STEPS[idx]
	if step_icon:
		step_icon.text = step["icon"]
		step_icon.add_theme_font_size_override("font_size", 56)
	if step_title:
		step_title.text = step["title"]
	if step_message:
		step_message.text = step["message"]
	if step_hint:
		step_hint.text = step["hint"]
	if progress_label:
		progress_label.text = "%d / %d" % [idx + 1, STEPS.size()]
	if next_button:
		if idx == STEPS.size() - 1:
			next_button.text = "🎮 시작하기"
		else:
			next_button.text = "다음 (%d/%d) →" % [idx + 2, STEPS.size()]

func _on_next_pressed() -> void:
	if not _active:
		return
	_cancel_auto_advance()
	_current_step += 1
	if _current_step >= STEPS.size():
		_finish_tutorial()
	else:
		_show_step(_current_step)
		_schedule_auto_advance(AUTO_ADVANCE_SEC)

func _on_skip_pressed() -> void:
	if not _active:
		return
	_finish_tutorial()

func _finish_tutorial() -> void:
	_active = false
	visible = false
	GameManager.tutorial_seen = true
	print("[Tutorial] 완료")
	emit_signal("tutorial_finished")

func _schedule_auto_advance(seconds: float) -> void:
	_cancel_auto_advance()
	_auto_timer = get_tree().create_timer(seconds)
	_auto_timer.timeout.connect(_on_auto_advance)

func _cancel_auto_advance() -> void:
	if _auto_timer != null and _auto_timer.timeout.is_connected(_on_auto_advance):
		_auto_timer.timeout.disconnect(_on_auto_advance)
	_auto_timer = null

func _on_auto_advance() -> void:
	if _active:
		_on_next_pressed()

func is_active() -> bool:
	return _active