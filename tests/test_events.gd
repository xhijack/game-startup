extends GutTest
## Test untuk EventEngine (core murni, statik).

var events := [
	{ "id": "viral", "type": "positive", "effect": { "mau_pct": 0.25 } },
	{ "id": "ramadan", "type": "seasonal", "months": [4], "effect": { "demand_pct": 0.30 } },
	{ "id": "rainy", "type": "seasonal", "months": [11, 12, 1], "effect": { "demand_pct": -0.15 } },
]

func test_eligible_excludes_offseason() -> void:
	var june := EventEngine.eligible_events(events, 6)  # hanya viral (tanpa months)
	assert_eq(june.size(), 1)
	assert_eq(june[0]["id"], "viral")

func test_eligible_includes_seasonal_in_month() -> void:
	var april := EventEngine.eligible_events(events, 4)  # viral + ramadan
	assert_eq(april.size(), 2)

func test_pick_deterministic_bounds() -> void:
	assert_eq(EventEngine.pick(events, 0.0)["id"], "viral")
	assert_eq(EventEngine.pick(events, 0.99)["id"], "rainy")

func test_pick_empty_list() -> void:
	assert_true(EventEngine.pick([], 0.5).is_empty())
