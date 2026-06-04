extends GutTest
## Test untuk Market (core murni, statik).

var cfg := {
	"base_daily_acquisition": 30,
	"marketing_acquisition_per_skill": 8,
	"monthly_churn_rate": 0.05,
	"quality_retention_factor": 0.5,
	"rides_per_user_per_day": 0.4,
}

func test_new_users_scales_with_marketing() -> void:
	assert_eq(Market.daily_new_users(0, cfg), 30)
	assert_eq(Market.daily_new_users(5, cfg), 70)

func test_transactions_capped_by_capacity() -> void:
	assert_eq(Market.daily_transactions(1000, 100, cfg), 100)   # dibatasi kapasitas
	assert_eq(Market.daily_transactions(100, 1000, cfg), 40)    # dibatasi demand

func test_quality_reduces_churn() -> void:
	var low_quality := Market.daily_churn(3000, 0.0, cfg)
	var high_quality := Market.daily_churn(3000, 1.0, cfg)
	assert_true(high_quality < low_quality)
