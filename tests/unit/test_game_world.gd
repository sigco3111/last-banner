extends GutTest
## GameWorld.apply_daily_economy + modify_resource + save_state/load_state 단위 테스트
## LB_VERIFY는 통합 검증, Gut은 함수 단위 — Last Banner v2 (2026-07-16)

const TEST_SLOT := "gut_test_slot"

func before_each() -> void:
    # 테스트 간 상태 격리
    GameWorld.gold = 200
    GameWorld.food = 100
    GameWorld.population = 50
    GameWorld.prosperity = 10
    GameWorld.fortification_level = 1
    GameWorld.event_log.clear()

func test_modify_resource_gold_increments_and_emits() -> void:
    var captured: Array = []
    GameWorld.resource_changed.connect(func(r, v): captured.append({"r": r, "v": v}))
    GameWorld.modify_resource("gold", 50)
    assert_eq(GameWorld.gold, 250, "gold +50 → 250")
    assert_eq(captured.size(), 1, "시그널 1회 emit")
    assert_eq(captured[0]["r"], "gold")
    assert_eq(captured[0]["v"], 250)

func test_modify_resource_prosperity_clamped_0_to_100() -> void:
    GameWorld.prosperity = 95
    GameWorld.modify_resource("prosperity", 50)  # 145 → 100으로 clamp
    assert_eq(GameWorld.prosperity, 100, "prosperity 100 cap")
    GameWorld.modify_resource("prosperity", -150)  # 100 → -50 → 0
    assert_eq(GameWorld.prosperity, 0, "prosperity 0 floor")

func test_modify_resource_fortification_clamped_1_to_5() -> void:
    GameWorld.modify_resource("fortification_level", 10)
    assert_eq(GameWorld.fortification_level, 5, "fortification 5 cap")
    GameWorld.modify_resource("fortification_level", -100)
    assert_eq(GameWorld.fortification_level, 1, "fortification 1 floor")

func test_modify_resource_unknown_pushes_warning() -> void:
    # 에러 안 나고 경고만 — 알 수 없는 자원은 silent drop
    var before_gold: int = GameWorld.gold
    GameWorld.modify_resource("coffee", 100)
    assert_eq(GameWorld.gold, before_gold, "unknown resource는 gold에 영향 X")

func test_apply_daily_economy_basic_population_50() -> void:
    # population=50, prosperity=10
    #   tax     = max(5, 10 + 50/4) = max(5, 22) = 22
    #   harvest = max(2, 50/4)      = 12
    #   consumed = 50/10 = 5
    var gold_before: int = GameWorld.gold
    GameWorld.apply_daily_economy()
    assert_eq(GameWorld.gold - gold_before, 22, "일일 +22 gold")
    assert_eq(GameWorld.food, 100 + 12 - 5, "일일 +7 food (12 - 5)")
    assert_eq(GameWorld.day_gold_change, 22)

func test_apply_daily_economy_low_population_min_taxes() -> void:
    GameWorld.population = 0
    GameWorld.prosperity = 0
    #   tax     = max(5, 0 + 0/4) = 5 (최소)
    #   harvest = max(2, 0/4)    = 2 (최소)
    #   consumed = 0/10 = 0
    GameWorld.apply_daily_economy()
    assert_eq(GameWorld.day_gold_change, 5, "min 세수 5")
    assert_eq(GameWorld.day_food_change, 2, "min 수확 2")

func test_log_event_appends_and_caps_at_50() -> void:
    GameWorld.event_log.clear()
    for i in range(60):
        GameWorld.log_event("evt-%d" % i)
    assert_eq(GameWorld.event_log.size(), 50, "ring buffer 50 한도")
    assert_eq(GameWorld.event_log[0]["message"], "evt-10", "오래된 10개 evict")

func test_save_state_round_trip() -> void:
    GameWorld.gold = 1234
    GameWorld.food = 567
    GameWorld.event_log.append({"day": 5, "message": "test"})
    var state: Dictionary = GameWorld.save_state()

    # 망가뜨리고
    GameWorld.gold = 0
    GameWorld.food = 0
    GameWorld.event_log.clear()

    GameWorld.load_state(state)
    assert_eq(GameWorld.gold, 1234, "load 후 gold 복원")
    assert_eq(GameWorld.food, 567, "load 후 food 복원")
    assert_eq(GameWorld.event_log.size(), 1)
    assert_eq(GameWorld.event_log[0]["message"], "test")

func test_summary_format_includes_lord_name() -> void:
    GameWorld.lord_name = "테스트 영주"
    var s: String = GameWorld.summary()
    assert_true(s.contains("테스트 영주"), "영주 이름 포함")
    assert_true(s.contains("gold=200"), "자원 gold 포함")
