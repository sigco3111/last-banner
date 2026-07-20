extends Node
## AudioManager v4.1 — BGM 4종 + SFX 6종 + 헤드리스 자동 가드 + 페이드 트윈
## Last Banner: Wesnoth BGM + sparklinlabs RPG SFX (CC0)

const BGM_TRACKS := {
	"menu":  "res://assets/audio/music/menu.ogg",
	"game":  "res://assets/audio/music/game.ogg",
	"battle": "res://assets/audio/music/battle.ogg",
	"modal": "res://assets/audio/music/modal.ogg",
}

const SFX_TRACKS := {
	"modal_open":     "res://assets/audio/sfx/modal_open.ogg",
	"modal_close":    "res://assets/audio/sfx/modal_close.ogg",
	"choice_confirm": "res://assets/audio/sfx/choice_confirm.ogg",
	"dice_roll":      "res://assets/audio/sfx/dice_roll.ogg",
	"battle_start":   "res://assets/audio/sfx/battle_start.ogg",
	"victory":        "res://assets/audio/sfx/victory.ogg",
}

# 볼륨 (0.0 ~ 1.0)
const BGM_VOLUME := 0.65
const SFX_VOLUME := 0.85
const FADE_DURATION := 1.5   # BGM 교체 시 페이드 시간

# 동적
var _bgm_player: AudioStreamPlayer = null
var _sfx_players: Array = []   # 다중 동시 재생 풀 (8개)
var _sfx_index: int = 0
var _current_bgm: String = ""
var _enabled: bool = true
var _fade_tween: Tween = null
var _asset_available: bool = false   # 자산 없으면 false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 헤드리스 가드: CI/검증 환경에서 비활성화
	_enabled = _is_running_with_display()
	_asset_available = _check_assets()
	if not _enabled:
		print("[AudioManager] 헤드리스 모드 — 사운드 비활성화")
		return
	if not _asset_available:
		print("[AudioManager] 자산 없음 — 사운드 비활성화")
		_enabled = false
		return
	_setup_players()
	print("[AudioManager] v4.1 사운드 시스템 활성화 (BGM %d종, SFX %d종)" % [BGM_TRACKS.size(), SFX_TRACKS.size()])

func _is_running_with_display() -> bool:
	return DisplayServer.get_name() != "headless"

func _check_assets() -> bool:
	# 핵심 자산 하나만 확인
	return ResourceLoader.exists(BGM_TRACKS["menu"])

func _setup_players() -> void:
	# BGM 단일 플레이어 (페이드 트윈 사용)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = linear_to_db(BGM_VOLUME)
	add_child(_bgm_player)
	# SFX 다중 플레이어 (풀링 — 동시 8개 재생 가능)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = linear_to_db(SFX_VOLUME)
		add_child(p)
		_sfx_players.append(p)

## BGM 재생 (페이드 트윈으로 부드러운 교체)
func play_bgm(name: String, fade: bool = true) -> void:
	if not _enabled:
		return
	if name == _current_bgm and _bgm_player and _bgm_player.playing:
		return   # 이미 같은 곡 재생 중
	if not BGM_TRACKS.has(name):
		push_warning("[AudioManager] 알 수 없는 BGM: %s" % name)
		return
	var path: String = BGM_TRACKS[name]
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM 자산 없음: %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_current_bgm = name
	if fade and _bgm_player.playing:
		_fade_switch_bgm(stream)
	else:
		_bgm_player.stream = stream
		_bgm_player.play()
		print("[AudioManager] BGM 재생: %s" % name)

func _fade_switch_bgm(new_stream: AudioStream) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	# 페이드아웃 → 교체 → 페이드인
	_fade_tween = create_tween()
	_fade_tween.tween_property(_bgm_player, "volume_db", -40.0, FADE_DURATION * 0.4)
	_fade_tween.tween_callback(func():
		_bgm_player.stream = new_stream
		_bgm_player.play()
	)
	_fade_tween.tween_property(_bgm_player, "volume_db", linear_to_db(BGM_VOLUME), FADE_DURATION * 0.6)

## BGM 정지 (페이드)
func stop_bgm(fade: bool = true) -> void:
	if not _enabled or _bgm_player == null:
		return
	if not _bgm_player.playing:
		return
	if fade:
		if _fade_tween != null and _fade_tween.is_valid():
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_bgm_player, "volume_db", -40.0, FADE_DURATION * 0.5)
		_fade_tween.tween_callback(func():
			if _bgm_player: _bgm_player.stop()
		)
	else:
		_bgm_player.stop()
	_current_bgm = ""

## SFX 재생 (동시 다발 — 풀링)
func play_sfx(name: String) -> void:
	if not _enabled:
		return
	if not SFX_TRACKS.has(name):
		push_warning("[AudioManager] 알 수 없는 SFX: %s" % name)
		return
	var path: String = SFX_TRACKS[name]
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if _sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	player.stream = stream
	player.play()
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()

## 일시정지 / 재개 (모달 등장 시 일시정지, 닫힐 때 재개)
func pause_bgm() -> void:
	if _enabled and _bgm_player and _bgm_player.playing:
		_bgm_player.stream_paused = true

func resume_bgm() -> void:
	if _enabled and _bgm_player:
		_bgm_player.stream_paused = false

## 외부 헬퍼
func is_enabled() -> bool:
	return _enabled

func is_asset_available() -> bool:
	return _asset_available

func get_current_bgm() -> String:
	return _current_bgm