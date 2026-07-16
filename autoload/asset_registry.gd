extends Node
## v2 단순화: lazy fetch 제거 (Vercel 배포 안 함)
## 단순히 res:// 절대 경로 + 카테고리 카탈로그만 제공

const CATEGORIES := {
	"heroes": "res://assets/units/human-loyalists/",
	"mercenaries": "res://assets/units/human-outlaws/",
	"allies": "res://assets/units/dunefolk/",
	"enemies": "res://assets/units/undead-skeletal/",
	"orcs": "res://assets/units/orcs/",
	"portraits": "res://assets/portraits/",
}

var _manifest_ready: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_manifest_ready = true
	print("[AssetRegistry] v2 단순화 모드 (res:// 직접)")

## 자산 절대 경로 (없으면 빈 문자열 반환)
func path(category: String, filename: String) -> String:
	if not category in CATEGORIES:
		return ""
	return CATEGORIES[category] + filename

## 카테고리 디렉터리에 파일이 존재하는지 확인
func has_file(category: String, filename: String) -> bool:
	var p := path(category, filename)
	return p != "" and ResourceLoader.exists(p)

func is_ready() -> bool:
	return _manifest_ready
