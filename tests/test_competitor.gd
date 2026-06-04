extends GutTest
## Test untuk Competitor (core murni, statik).

var cfg := { "daily_growth": 12, "growth_rate": 0.01, "max_mau": 50000, "pressure": 0.04 }

func test_daily_growth() -> void:
	# (12 + 1000*0.01) * (1 - 1000/50000) = 22 * 0.98 ≈ 22
	assert_eq(Competitor.daily_growth(1000, cfg), 22)

func test_growth_capped_at_max() -> void:
	assert_eq(Competitor.daily_growth(50000, cfg), 0)
	assert_true(Competitor.daily_growth(49000, cfg) < Competitor.daily_growth(1000, cfg))

func test_pressure_churn_zero_when_no_competitor() -> void:
	assert_eq(Competitor.pressure_churn(1000, 0, cfg), 0)

func test_pressure_churn_scales_with_share() -> void:
	var small := Competitor.pressure_churn(1000, 200, cfg)
	var big := Competitor.pressure_churn(1000, 3000, cfg)
	assert_true(big > small)

func test_our_share() -> void:
	assert_almost_eq(Competitor.our_share(750, 250), 0.75, 0.0001)
	assert_eq(Competitor.our_share(0, 0), 1.0)
