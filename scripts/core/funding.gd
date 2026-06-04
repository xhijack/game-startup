class_name Funding
extends RefCounted
## State pendanaan murni: kepemilikan (ownership) & round yang sudah diraih.
## TANPA node/UI. Angka round datang dari data/funding.json.

var ownership: float = 1.0   # 1.0 = founder pegang 100%
var raised_ids: Array = []   # id round yang sudah diraih (urut)

func has_raised(id: String) -> bool:
	return raised_ids.has(id)

## Round berikutnya = round pertama (urutan array) yang belum diraih.
## Mengembalikan {} bila semua sudah diraih.
func next_round(rounds: Array) -> Dictionary:
	for r in rounds:
		if not has_raised(str(r.get("id", ""))):
			return r
	return {}

## Layak raih? Cek threshold MAU & valuation. Urutan dijaga oleh next_round().
func is_eligible(round: Dictionary, mau: int, valuation: float) -> bool:
	if round.is_empty():
		return false
	if mau < int(round.get("require_mau", 0)):
		return false
	if valuation < float(round.get("require_valuation", 0.0)):
		return false
	return true

## Raih round: tandai, dilusi kepemilikan, kembalikan suntikan cash (k).
func raise_round(round: Dictionary) -> float:
	raised_ids.append(str(round.get("id", "")))
	ownership *= (1.0 - float(round.get("dilution", 0.0)))
	return float(round.get("amount", 0.0))
