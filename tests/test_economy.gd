extends GutTest
## Test untuk Economy (core murni). Jalankan via GUT.

func test_net_monthly() -> void:
	var e := Economy.new(1000.0)
	e.revenue_monthly = 500.0
	e.burn_rate_monthly = 800.0
	assert_eq(e.net_monthly(), -300.0)

func test_runway_when_burning() -> void:
	var e := Economy.new(900.0)
	e.revenue_monthly = 0.0
	e.burn_rate_monthly = 300.0
	assert_eq(e.runway_months(), 3.0)

func test_runway_uses_net_burn() -> void:
	var e := Economy.new(600.0)
	e.revenue_monthly = 100.0
	e.burn_rate_monthly = 400.0  # net burn = 300
	assert_eq(e.runway_months(), 2.0)

func test_runway_infinite_when_profit() -> void:
	var e := Economy.new(1000.0)
	e.revenue_monthly = 1000.0
	e.burn_rate_monthly = 400.0
	assert_eq(e.runway_months(), INF)

func test_apply_period_reduces_cash() -> void:
	var e := Economy.new(1000.0)
	e.burn_rate_monthly = 300.0
	e.apply_period(1.0)  # satu bulan
	assert_eq(e.cash, 700.0)

func test_apply_partial_period() -> void:
	var e := Economy.new(1000.0)
	e.burn_rate_monthly = 300.0
	e.apply_period(1.0 / 30.0)  # satu hari
	assert_almost_eq(e.cash, 990.0, 0.01)

func test_bankrupt_detection() -> void:
	var e := Economy.new(100.0)
	e.burn_rate_monthly = 300.0
	e.apply_period(1.0)
	assert_true(e.is_bankrupt())
