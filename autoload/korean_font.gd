extends Node
## 한국어 폰트 자동 적용 — v1 함정 (모바일 Web fallback 글리프 깨짐) 방지
## v2는 macOS 네이티브만이지만 통일성을 위해 preload + theme 재귀 적용

const KOREAN_FONT_PATH := "res://assets/fonts/NanumGothic.ttf"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 폰트 preload (빌드 시 pck 포함, 런타임 fetch 불필요)
	if not ResourceLoader.exists(KOREAN_FONT_PATH):
		push_warning("[KoreanFont] 폰트 없음: %s" % KOREAN_FONT_PATH)
		return
	var theme := Theme.new()
	theme.default_font = load(KOREAN_FONT_PATH)
	theme.default_font_size = 18

	# SceneTree.root에 부착되는 모든 Control에 자동 적용
	get_tree().root.theme = theme
	print("[KoreanFont] 기본 테마 적용 완료 (size=18)")
