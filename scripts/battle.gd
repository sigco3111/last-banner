extends Control
## 전투 화면 — 3단계 상태머신
## v3.0 (Last Banner) — CK3 양식 전투 시각화
##
## State transition:
##   DECISION (출격/숨기/뇌물 버튼) → SIMULATING (주사위 3회 굴림 + 비교)
##   → RESULT (승/패 + 손실 카드) → 5초 후 자동 종료

enum State { DECISION, SIMULATING, RESULT }

signal battle_finished(outcome: String)

var state: int = State.DECISION
var allies_power: int = 0
var enemies_power: int = 0
var roll_count: int = 0
var rolls: Array = []

# 노드
var title_label: Label = null
var subtitle_label: Label = null
var allies_grid: GridContainer = null
var enemies_grid: GridContainer = null
var status_label: Label = null
var dice_label: Label = null
var choices_row: HBoxContainer = null
var fight_button: Button = null
var hide_button: Button = null
var bribe_button: Button = null
var result_label: Label = null
var close_button: Button = null

const DICE_ICONS := ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]
const ROLES := [
	{ "path": "res://assets/units/human-loyalists/swordsman.png", "name": "에드윈" },
	{ "path": "res://assets/units/human-loyalists/spearman.png",  "name": "린" },
	{ "path": "res://assets/units/human-loyalists/bowman.png",    "name": "그림발트" },
	{ "path": "res://assets/units/human-outlaws/bandit.png",      "name": "엘가르" },
	{ "path": "res://assets/units/human-loyalists/lieutenant.png", "name": "보조" },
]
const ENEMY_TYPES := [
	{ "path": "res://assets/units/orcs/grunt.png",                        "name": "오크 전사" },
	{ "path": "res://assets/units/undead-skeletal/banebow.png",           "name": "해골 병사" },
	{ "path": "res://assets/units/orcs/warlord.png",                      "name": "약탈자 두목" },
	{ "path": "res://assets/units/undead-skeletal/bone-shooter-bob-1.png","name": "강령 궁수" },
	{ "path": "res://assets/units/orcs/assassin.png",                     "name": "오크 암살자" },
]

func _ready() -> void:
	_find_nodes()
	_connect_signals()
	reset_state(5, 4)

func _find_nodes() -> void:
	title_label = get_node_or_null("TopBar/TopVBox/TitleLabel") as Label
	subtitle_label = get_node_or_null("TopBar/TopVBox/SubtitleLabel") as Label
	allies_grid = get_node_or_null("GridRow/AlliesCard/AlliesVBox/AlliesGrid") as GridContainer
	enemies_grid = get_node_or_null("GridRow/EnemiesCard/EnemiesVBox/EnemiesGrid") as GridContainer
	status_label = get_node_or_null("BottomCard/BottomVBox/StatusLabel") as Label
	dice_label = get_node_or_null("BottomCard/BottomVBox/DiceLabel") as Label
	choices_row = get_node_or_null("BottomCard/BottomVBox/ChoicesRow") as HBoxContainer
	fight_button = get_node_or_null("BottomCard/BottomVBox/ChoicesRow/FightButton") as Button
	hide_button = get_node_or_null("BottomCard/BottomVBox/ChoicesRow/HideButton") as Button
	bribe_button = get_node_or_null("BottomCard/BottomVBox/ChoicesRow/BribeButton") as Button
	result_label = get_node_or_null("BottomCard/BottomVBox/ResultLabel") as Label
	close_button = get_node_or_null("CloseButton") as Button
	print("[Battle] 노드 검색 완료 (state=DECISION, fight_button=%s)" % ("OK" if fight_button else "NULL"))

func _connect_signals() -> void:
	if fight_button:
		fight_button.pressed.connect(_on_fight_pressed)
	if hide_button:
		hide_button.pressed.connect(_on_hide_pressed)
	if bribe_button:
		bribe_button.pressed.connect(_on_bribe_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	print("[Battle] 시그널 연결 완료")

## 외부에서 호출 — 전투 화면 표시
func start_battle(enemy_count: int = 4) -> void:
	print("[Battle] start_battle(%d) 호출됨" % enemy_count)
	reset_state(5, enemy_count)
	visible = true
	state = State.DECISION
	rolls.clear()
	roll_count = 0
	_update_status("상태: 결정 대기 — 출격/숨기/뇌물 중 선택")
	if result_label:
		result_label.text = ""
	if choices_row:
		choices_row.visible = true
	if dice_label:
		dice_label.text = "🎲 —"

func reset_state(allies_count: int, enemies_count: int) -> void:
	_populate_grid(allies_grid, ROLES, allies_count, Color(0.55, 0.6, 0.7))
	_populate_grid(enemies_grid, ENEMY_TYPES, enemies_count, Color(0.7, 0.3, 0.3))
	allies_power = allies_count * 10 + GameWorld.prosperity
	enemies_power = enemies_count * 12
	print("[Battle] 아군 %d (전투력 %d) vs 적군 %d (전투력 %d)" % [allies_count, allies_power, enemies_count, enemies_power])

func _populate_grid(grid: GridContainer, role_pool: Array, count: int, modulate: Color) -> void:
	for child in grid.get_children():
		child.queue_free()
	var picks: Array = role_pool.slice(0, min(count, role_pool.size()))
	for r in picks:
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(48, 48)
		tex_rect.expand_mode = 1
		tex_rect.stretch_mode = 5
		tex_rect.modulate = modulate
		var tex: Texture2D = load(r["path"])
		if tex != null and tex.get_width() > 0:
			tex_rect.texture = tex
		grid.add_child(tex_rect)

func _update_status(msg: String) -> void:
	if status_label:
		status_label.text = msg

# ============================================================
# 입력 핸들러
# ============================================================
func _on_fight_pressed() -> void:
	print("[Battle] 출격 클릭! 현재 state=%d" % state)
	if state != State.DECISION:
		print("[Battle] state가 DECISION이 아니어서 무시")
		return
	state = State.SIMULATING
	_update_status("상태: 전투 진행 중")
	if choices_row:
		choices_row.visible = false
	rolls.clear()
	roll_count = 0
	_simulate_dice_sync()

func _on_hide_pressed() -> void:
	print("[Battle] 숨기 클릭!")
	if state != State.DECISION:
		return
	GameWorld.modify_resource("food", -enemies_power)
	GameWorld.log_event("숨기 선택 — 식량 %d 손실" % enemies_power)
	GameWorld.apply_result("BATTLE_BANDITS_HIDE", {})
	_finish("HIDE")

func _on_bribe_pressed() -> void:
	print("[Battle] 뇌물 클릭!")
	if state != State.DECISION:
		return
	var cost: int = 30
	GameWorld.modify_resource("gold", -cost)
	GameWorld.modify_resource("prosperity", -2)
	GameWorld.log_event("뇌물 지급 — -%d 골드, -2 명성" % cost)
	GameWorld.apply_result("BATTLE_BANDITS_BRIBE", {})
	_finish("BRIBE")

# ============================================================
# 주사위 시뮬레이션 (race-free synchronous + 타이머만 await)
# ============================================================
func _simulate_dice_sync() -> void:
	# 한 번에 다 굴리고 타이머로만 단계 분리 (recurse 위험 X)
	for i in range(3):
		var roll: int = randi() % 6 + 1
		rolls.append(roll)
		roll_count += 1
		_update_status("상태: 전투 진행 중 (%d/3)" % roll_count)
	# UI 표시 (모든 굴림 완료 후)
	if dice_label:
		var dice_str := ""
		for r in rolls:
			dice_str += DICE_ICONS[r - 1] + " "
		dice_label.text = "🎲 " + dice_str
	print("[Battle] 주사위 굴림 완료: %s" % str(rolls))
	# 결과 적용 (즉시)
	state = State.RESULT
	var bonus: int = sum_rolls()
	if allies_power + bonus >= enemies_power:
		_victory_now(bonus)
	else:
		_defeat_now(bonus)

func sum_rolls() -> int:
	var s := 0
	for r in rolls:
		s += r
	return s

func _victory_now(bonus: int) -> void:
	if result_label:
		result_label.text = "✅ 승리! (%d + 보정 %d = %d vs %d)" % [allies_power, bonus, allies_power + bonus, enemies_power]
	_update_status("상태: 승리 — 5초 후 자동 종료")
	GameWorld.log_event("전투 승리 — 약탈자 퇴치 (전투력 %d + 보정 %d)" % [allies_power, bonus])
	GameWorld.apply_result("BATTLE_BANDITS_FIGHT", {})
	# 5초 후 자동 종료
	await get_tree().create_timer(5.0).timeout
	_finish("FIGHT_WIN")

func _defeat_now(bonus: int) -> void:
	if result_label:
		result_label.text = "❌ 패배... (%d + 보정 %d = %d < %d) — 식량 %d 손실" % [
			allies_power, bonus, allies_power + bonus, enemies_power,
			enemies_power * 2
		]
	_update_status("상태: 패배 — 5초 후 자동 종료")
	GameWorld.modify_resource("food", -enemies_power * 2)
	GameWorld.log_event("전투 패배 — 식량 %d 손실" % (enemies_power * 2))
	GameWorld.apply_result("BATTLE_BANDITS_FIGHT", {})
	# 5초 후 자동 종료
	await get_tree().create_timer(5.0).timeout
	_finish("FIGHT_LOSE")

func _finish(outcome: String) -> void:
	state = State.DECISION
	if choices_row:
		choices_row.visible = true
	emit_signal("battle_finished", outcome)
	# 자동 종료 (외부에서 안 닫으면)
	await get_tree().create_timer(2.0).timeout
	if visible:
		visible = false
		print("[Battle] 7초 후 자동 종료 (outcome=%s)" % outcome)

func _on_close_pressed() -> void:
	if visible:
		visible = false
		print("[Battle] 사용자가 X로 닫음")
