class_name EventEngine
extends RefCounted
## Pemilihan event — MURNI & statik. Aplikasi efek dilakukan orchestrator (GameState).
## Dipisah supaya logika seleksi bisa di-test deterministik (nilai acak di-inject).

## Event yang berlaku di `month`. "months" kosong/absen = berlaku semua bulan;
## "months" berisi = hanya bulan tersebut (event musiman).
static func eligible_events(events: Array, month: int) -> Array:
	var out: Array = []
	for e in events:
		var months: Array = e.get("months", [])
		if months.is_empty() or months.has(month):
			out.append(e)
	return out

## Pilih satu event dari daftar berdasar nilai acak 0..1. {} bila daftar kosong.
static func pick(eligible: Array, roll_pick: float) -> Dictionary:
	if eligible.is_empty():
		return {}
	var idx := int(clampf(roll_pick, 0.0, 0.9999) * eligible.size())
	return eligible[idx]
