extends Node
## UITheme — Last Banner v4.0.0 시각 개선 표준
## 모든 화면이 공유하는 색상 팔레트 / 스타일 헬퍼

# ─── 배경 ─────────────────────────────────────────
const BG_BASE := Color(0.10, 0.07, 0.05, 1.0)            # 베이지-다크 (만국 공통)
const BG_PANEL := Color(0.16, 0.12, 0.09, 0.95)          # PanelContainer 배경
const BG_PANEL_LIGHT := Color(0.22, 0.17, 0.13, 0.92)    # 강조 Panel
const BG_PANEL_DARK := Color(0.08, 0.06, 0.04, 0.95)     # 깊은 패널 (대시보드 카드)
const BG_MODAL := Color(0.12, 0.08, 0.06, 0.97)          # 모달 카드
const BG_RESOURCE_CARD := Color(0.20, 0.15, 0.10, 0.85)  # 자원 카드
const BG_BUTTON := Color(0.30, 0.24, 0.18, 0.95)         # 일반 버튼
const BG_BUTTON_HOVER := Color(0.42, 0.34, 0.26, 0.95)
const BG_BUTTON_PRESS := Color(0.20, 0.16, 0.12, 0.95)

# ─── 텍스트 ───────────────────────────────────────
const TEXT_PRIMARY := Color(0.95, 0.92, 0.85, 1.0)       # 본문 (거의 흰색-베이지)
const TEXT_SECONDARY := Color(0.78, 0.72, 0.60, 1.0)     # 보조
const TEXT_DIM := Color(0.55, 0.50, 0.42, 1.0)           # 흐림
const TEXT_TITLE := Color(0.98, 0.92, 0.70, 1.0)         # 제목 (금빛)
const TEXT_DANGER := Color(1.00, 0.55, 0.45, 1.0)        # 위험 (빨강)
const TEXT_SUCCESS := Color(0.55, 0.85, 0.55, 1.0)       # 성공 (초록)
const TEXT_NEGATIVE := Color(1.00, 0.65, 0.50, 1.0)      # 음수 변화량
const TEXT_POSITIVE := Color(0.65, 0.90, 0.65, 1.0)      # 양수 변화량

# ─── 자원 색상 ────────────────────────────────────
const COLOR_GOLD := Color(1.00, 0.85, 0.30, 1.0)         # 💰 금
const COLOR_FOOD := Color(0.65, 0.85, 0.40, 1.0)         # 🌾 식량
const COLOR_POPULATION := Color(0.50, 0.75, 0.95, 1.0)   # 👥 인구
const COLOR_PROSPERITY := Color(0.95, 0.80, 0.50, 1.0)    # ⭐ 명성
const COLOR_FORTIFICATION := Color(0.75, 0.65, 0.55, 1.0) # 🏰 요새

# ─── 우선순위 색상 ─────────────────────────────────
const PRIORITY_LOW := Color(0.65, 0.65, 0.70, 1.0)       # 회색
const PRIORITY_MEDIUM := Color(0.50, 0.75, 0.95, 1.0)    # 파랑
const PRIORITY_HIGH := Color(1.00, 0.75, 0.30, 1.0)      # 주황
const PRIORITY_CRITICAL := Color(1.00, 0.40, 0.40, 1.0)  # 빨강
const PRIORITY_LOW_BG := Color(0.25, 0.25, 0.28, 0.95)
const PRIORITY_MEDIUM_BG := Color(0.18, 0.25, 0.35, 0.95)
const PRIORITY_HIGH_BG := Color(0.35, 0.25, 0.12, 0.95)
const PRIORITY_CRITICAL_BG := Color(0.40, 0.15, 0.15, 0.95)

# ─── 용병 Tier 색상 ────────────────────────────────
const TIER_1_COLOR := Color(0.70, 0.70, 0.70, 1.0)       # 회색
const TIER_2_COLOR := Color(0.45, 0.85, 1.00, 1.0)       # 하늘색
const TIER_3_COLOR := Color(1.00, 0.85, 0.35, 1.0)       # 금색

# ─── 충성도 색상 ───────────────────────────────────
const LOYALTY_HIGH := Color(0.55, 0.85, 0.55, 1.0)       # ≥70 초록
const LOYALTY_MID := Color(0.95, 0.85, 0.45, 1.0)        # 40~69 노랑
const LOYALTY_LOW := Color(0.95, 0.55, 0.45, 1.0)        # <40 빨강

# ─── 차트 색상 ─────────────────────────────────────
const CHART_BG := Color(0.06, 0.05, 0.04, 0.95)
const CHART_GRID := Color(0.30, 0.25, 0.20, 0.4)
const CHART_GOLD_LINE := COLOR_GOLD
const CHART_FOOD_LINE := COLOR_FOOD
const CHART_TEXT := TEXT_SECONDARY

# ─── 구분선 / 보더 ─────────────────────────────────
const BORDER_SUBTLE := Color(0.40, 0.32, 0.22, 0.6)
const BORDER_ACCENT := Color(0.70, 0.55, 0.30, 0.8)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[UITheme] v4.0.0 테마 로드 완료")

## 자원별 색상 매핑
func resource_color(resource: String) -> Color:
	match resource:
		"gold": return COLOR_GOLD
		"food": return COLOR_FOOD
		"population": return COLOR_POPULATION
		"prosperity": return COLOR_PROSPERITY
		"fortification_level": return COLOR_FORTIFICATION
		_: return TEXT_PRIMARY

## 자원 이모지 매핑
func resource_icon(resource: String) -> String:
	match resource:
		"gold": return "💰"
		"food": return "🌾"
		"population": return "👥"
		"prosperity": return "⭐"
		"fortification_level": return "🏰"
		_: return "•"

## 자원 라벨 매핑
func resource_name(resource: String) -> String:
	match resource:
		"gold": return "금"
		"food": return "식량"
		"population": return "인구"
		"prosperity": return "명성"
		"fortification_level": return "요새"
		_: return resource

## 우선순위 색상
func priority_color(priority: int) -> Color:
	match priority:
		0: return PRIORITY_LOW           # LOW
		1: return PRIORITY_MEDIUM        # MEDIUM
		2: return PRIORITY_HIGH          # HIGH
		3: return PRIORITY_CRITICAL      # CRITICAL
		_: return PRIORITY_LOW

func priority_bg(priority: int) -> Color:
	match priority:
		0: return PRIORITY_LOW_BG
		1: return PRIORITY_MEDIUM_BG
		2: return PRIORITY_HIGH_BG
		3: return PRIORITY_CRITICAL_BG
		_: return PRIORITY_LOW_BG

func priority_label(priority: int) -> String:
	match priority:
		0: return "LOW"
		1: return "MEDIUM"
		2: return "HIGH"
		3: return "CRITICAL"
		_: return "?"

## 충성도 색상
func loyalty_color(loyalty: int) -> Color:
	if loyalty >= 70: return LOYALTY_HIGH
	elif loyalty >= 40: return LOYALTY_MID
	else: return LOYALTY_LOW

## Tier 색상
func tier_color(tier: int) -> Color:
	match tier:
		1: return TIER_1_COLOR
		2: return TIER_2_COLOR
		3: return TIER_3_COLOR
		_: return Color.WHITE

## 변화량 포맷 (+12 / -8 등) — 색상 인라인
func format_change(delta: int) -> String:
	if delta > 0:
		return "+%d" % delta
	elif delta < 0:
		return "%d" % delta
	else:
		return "0"

## 변화량 색상
func change_color(delta: int) -> Color:
	if delta > 0: return TEXT_POSITIVE
	elif delta < 0: return TEXT_NEGATIVE
	return TEXT_DIM

## PanelContainer용 StyleBoxFlat 생성
func make_panel_style(bg: Color = BG_PANEL, border: Color = BORDER_SUBTLE, border_w: int = 1, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

## 버튼용 StyleBoxFlat (일반)
func make_button_style(bg: Color = BG_BUTTON, border: Color = BORDER_ACCENT, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

## 우선순위 배지용 StyleBoxFlat (선명한 배경)
func make_priority_badge_style(bg: Color, fg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = fg
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

## ProgressBar 스타일 — 충성도/식량 막대
func make_progress_style(fg: Color, bg: Color = Color(0.10, 0.08, 0.06, 1.0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fg
	style.set_corner_radius_all(2)
	return style

func make_progress_bg_style(bg: Color = Color(0.10, 0.08, 0.06, 1.0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(2)
	return style

## 노드 한 곳에 StyleBoxFlat 일괄 적용 (Control)
func apply_style(control: Control, style: StyleBoxFlat) -> void:
	if control and style:
		control.add_theme_stylebox_override("panel", style)

## Button에 hover/pressed/normal 스타일 적용
func apply_button_styles(button: Button, base: Color = BG_BUTTON) -> void:
	if button == null:
		return
	var normal_style := make_button_style(base)
	var hover_style := make_button_style(base.lerp(Color.WHITE, 0.15), BORDER_ACCENT.lerp(Color.WHITE, 0.2))
	var pressed_style := make_button_style(base.lerp(Color.BLACK, 0.2))
	var disabled_style := make_button_style(base.lerp(Color.BLACK, 0.5), BORDER_SUBTLE.lerp(Color.BLACK, 0.5))
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", TEXT_TITLE)
	button.add_theme_color_override("font_pressed_color", TEXT_TITLE)
	button.add_theme_color_override("font_disabled_color", TEXT_DIM)

## ProgressBar 스타일 적용
func apply_progress_styles(pb: ProgressBar, fg: Color) -> void:
	if pb == null:
		return
	pb.add_theme_stylebox_override("fill", make_progress_style(fg))
	pb.add_theme_stylebox_override("background", make_progress_bg_style())
	pb.add_theme_color_override("font_color", TEXT_PRIMARY)

## Label 기본 텍스트 색상 적용
func apply_label_color(label: Label, color: Color) -> void:
	if label:
		label.add_theme_color_override("font_color", color)

## 자원 변화량 라벨 색상 적용 (delta 부호 기반)
func apply_change_color(label: Label, delta: int) -> void:
	apply_label_color(label, change_color(delta))