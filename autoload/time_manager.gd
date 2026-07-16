extends Node
## 게임 내 시간 관리 — v1 검증 패턴 그대로
## 1초 real time = 게임 내 X분. tick_advanced / day_changed / season_changed 시그널.

signal tick_advanced(game_time_min: int)
signal day_changed(day: int)
signal month_changed(month: int)
signal season_changed(season: String)

const SECONDS_PER_GAME_MINUTE := 1.0 / 60.0   # 1초 real = 60분 게임 (= 1시간) → 60초당 1일
const MINUTES_PER_HOUR := 60
const MINUTES_PER_DAY := 1440          # 24h
const DAYS_PER_MONTH := 30
const MONTHS_PER_YEAR := 12

var minutes_elapsed: int = 0    # 누적 게임 분
var day: int = 0
var month: int = 0
var year: int = 1
var auto_progress_enabled: bool = true   # 기본 ON (v1 결정)
var _accumulator: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not auto_progress_enabled:
		return
	if GameManager and not GameManager.is_playing():
		return
	if DecisionQueue and DecisionQueue.has_pending_critical():
		return
	_accumulator += delta
	while _accumulator >= SECONDS_PER_GAME_MINUTE:
		_accumulator -= SECONDS_PER_GAME_MINUTE
		advance_minutes(1)

## 시간 강제 진행 (검증/자동 진행 시뮬레이션용)
func advance_minutes(amount: int) -> void:
	var prev_day := day
	minutes_elapsed += amount
	day = minutes_elapsed / MINUTES_PER_DAY
	if day != prev_day:
		day_changed.emit(day)
		# 30일 = 1달
		var new_month: int = day / DAYS_PER_MONTH
		if new_month != month:
			month = new_month
			month_changed.emit(month)
			# 4계절 — 단순화: month % 12 → spring/summer/autumn/winter
			var seasons := ["spring", "summer", "autumn", "winter"]
			season_changed.emit(seasons[month % 4])
	tick_advanced.emit(minutes_elapsed)

func toggle_auto_progress() -> void:
	auto_progress_enabled = not auto_progress_enabled
	print("[TimeManager] auto_progress_enabled = %s" % str(auto_progress_enabled))

func save_state() -> Dictionary:
	return {
		"minutes_elapsed": minutes_elapsed,
		"day": day,
		"month": month,
		"year": year,
		"auto_progress_enabled": auto_progress_enabled,
	}

func load_state(data: Dictionary) -> void:
	minutes_elapsed = data.get("minutes_elapsed", 0)
	day = data.get("day", 0)
	month = data.get("month", 0)
	year = data.get("year", 1)
	auto_progress_enabled = data.get("auto_progress_enabled", true)
