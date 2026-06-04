class_name Cities
extends RefCounted
## Ekspansi geografis — helper MURNI. Menjumlah kontribusi kota yang sudah dibuka.
## `opened` = Array of Dictionary definisi kota.

## Total tambahan akuisisi harian dari semua kota yang dibuka.
static func sum_acquisition(opened: Array) -> int:
	var s := 0
	for c in opened:
		s += int(c.get("acquisition_bonus", 0))
	return s

## Total biaya operasional bulanan dari semua kota yang dibuka.
static func sum_ops(opened: Array) -> float:
	var s := 0.0
	for c in opened:
		s += float(c.get("ops_cost_monthly", 0.0))
	return s
