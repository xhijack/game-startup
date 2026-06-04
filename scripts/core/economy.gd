class_name Economy
extends RefCounted
## State ekonomi murni. TANPA referensi node/UI — bisa di-test berdiri sendiri.
## Satuan mata uang: "k" (ribu Rupiah). Angka balancing datang dari data/balance.json.

var cash: float = 0.0
var revenue_monthly: float = 0.0    # gross pendapatan per bulan
var burn_rate_monthly: float = 0.0  # total biaya per bulan (gaji + ops)

func _init(starting_cash: float = 0.0) -> void:
	cash = starting_cash

func net_monthly() -> float:
	return revenue_monthly - burn_rate_monthly

## Runway: berapa BULAN cash bertahan dengan net burn saat ini.
## Profit (net >= 0) -> runway tak terbatas.
func runway_months() -> float:
	var net := net_monthly()
	if net >= 0.0:
		return INF
	return cash / -net

## Terapkan arus kas untuk durasi `months` (boleh pecahan; 1 hari = 1/days_per_month).
func apply_period(months: float) -> void:
	cash += net_monthly() * months

func is_bankrupt() -> bool:
	return cash < 0.0
