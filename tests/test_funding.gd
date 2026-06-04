extends GutTest
## Test untuk Funding (core murni).

var rounds := [
	{ "id": "seed", "label": "Seed", "require_mau": 1500, "amount": 150000, "dilution": 0.15 },
	{ "id": "series_a", "label": "Series A", "require_mau": 8000, "amount": 750000, "dilution": 0.18 },
	{ "id": "ipo", "label": "IPO", "require_mau": 120000, "require_valuation": 5000000, "amount": 0, "dilution": 0.0, "is_ipo": true },
]

func test_next_round_is_first_unraised() -> void:
	var f := Funding.new()
	assert_eq(f.next_round(rounds)["id"], "seed")
	f.raise_round(rounds[0])
	assert_eq(f.next_round(rounds)["id"], "series_a")

func test_eligibility_by_mau() -> void:
	var f := Funding.new()
	assert_false(f.is_eligible(rounds[0], 1000, 0.0))
	assert_true(f.is_eligible(rounds[0], 1500, 0.0))

func test_eligibility_by_valuation() -> void:
	var f := Funding.new()
	# IPO butuh MAU >= 120000 DAN valuasi >= 5_000_000
	assert_false(f.is_eligible(rounds[2], 120000, 4000000.0))
	assert_true(f.is_eligible(rounds[2], 120000, 5000000.0))

func test_raise_dilutes_ownership() -> void:
	var f := Funding.new()
	var cash := f.raise_round(rounds[0])  # dilusi 15%
	assert_eq(cash, 150000.0)
	assert_almost_eq(f.ownership, 0.85, 0.0001)
	f.raise_round(rounds[1])              # dilusi 18% berikutnya
	assert_almost_eq(f.ownership, 0.85 * 0.82, 0.0001)

func test_all_rounds_done_returns_empty() -> void:
	var f := Funding.new()
	for r in rounds:
		f.raise_round(r)
	assert_true(f.next_round(rounds).is_empty())
