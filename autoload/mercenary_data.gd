extends Node
## 용병 데이터 카탈로그 — 9-class tier 시스템 (v1 검증 복원)
## Last Banner v3.2 — A-1 용병 Roster

# 9개 클래스 (Tier 1~3)
# tier 1: bowman / swordsman / pikeman — 초급, 일급 4~5
# tier 2: sergeant / fencer / crossbow / cavalry — 중급, 일급 10~15
# tier 3: captain / paladin — 고급, 일급 30~35

const CLASSES := {
	"bowman":    { "tier": 1, "base_wage": 5,  "labels": ["궁수", "궁병"],        "portrait_faction": "humans" },
	"swordsman": { "tier": 1, "base_wage": 4,  "labels": ["검사", "병사"],        "portrait_faction": "humans" },
	"pikeman":   { "tier": 1, "base_wage": 5,  "labels": ["창병", "척후"],        "portrait_faction": "humans" },
	"sergeant":  { "tier": 2, "base_wage": 12, "labels": ["하사관"],              "portrait_faction": "humans" },
	"fencer":    { "tier": 2, "base_wage": 10, "labels": ["페렌스", "결투자"],    "portrait_faction": "humans" },
	"crossbow":  { "tier": 2, "base_wage": 11, "labels": ["석궁병"],              "portrait_faction": "humans" },
	"cavalry":   { "tier": 2, "base_wage": 15, "labels": ["기병"],                "portrait_faction": "humans" },
	"captain":   { "tier": 3, "base_wage": 30, "labels": ["선봉장", "대장"],      "portrait_faction": "humans" },
	"paladin":   { "tier": 3, "base_wage": 35, "labels": ["성기사"],              "portrait_faction": "humans" },
}

# 이름 생성 풀 (영지/인물 톤 — Wesnoth 양식 fantasy 이름)
const FIRST_NAMES := [
	"에드윈", "린", "그림발트", "엘가르", "토르바르", "아드리안", "엘리아",
	"카엘", "로한", "세바스찬", "베르나르", "율리안", "니콜라우스",
	"시릴", "레오", "안셀름", "발렌타인", "오스카", "피에르",
	"헨리", "라이몬드", "가브리엘", "카스퍼", "라이오넬", "스테판",
]
const TITLES_BY_TIER := {
	1: ["신참", "견습", "풋내기"],
	2: ["베테랑", "숙련", "경험자"],
	3: ["전설", "영웅", "명장"],
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 랜덤 용병 1명 생성 (GameWorld.roster에 append할 dict 반환)
func generate_mercenary(class_id: String, id_counter: int) -> Dictionary:
	if not CLASSES.has(class_id):
		class_id = "bowman"
	var class_info: Dictionary = CLASSES[class_id]
	var tier: int = class_info["tier"]
	var base_wage: int = class_info["base_wage"]
	var first_name: String = FIRST_NAMES[randi() % FIRST_NAMES.size()]
	var titles: Array = TITLES_BY_TIER[tier]
	var title: String = titles[randi() % titles.size()]
	var class_labels: Array = class_info["labels"]
	var label: String = class_labels[randi() % class_labels.size()]

	return {
		"id": id_counter,
		"name": "%s %s" % [title, first_name],
		"class": class_id,
		"class_label": label,
		"tier": tier,
		"experience": 0,
		"loyalty": 60 + randi() % 30,   # 60~89
		"wage_demand": base_wage,
		"injured_days": 0,
		"alive": true,
	}

## 등급별 색상 (UI 표준)
func tier_color(tier: int) -> Color:
	match tier:
		1: return Color(0.7, 0.7, 0.7)   # 회색
		2: return Color(0.4, 0.85, 1.0)  # 하늘색
		3: return Color(1.0, 0.85, 0.3)  # 금색
		_: return Color(1, 1, 1)

## 일급 총합 계산
func total_wage_burden(roster: Array) -> int:
	var total: int = 0
	for m in roster:
		if m.alive:
			total += int(m.wage_demand)
	return total