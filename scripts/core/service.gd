class_name Service
extends RefCounted
## Satu layanan/produk (mis. ride-hailing). Murni, tanpa node.

var id: String = ""
var label_id: String = ""
var label_en: String = ""
var rnd_cost: float = 0.0
var ops_cost_monthly: float = 0.0
var capacity: int = 0          # maksimum transaksi per hari
var quality: float = 0.5       # 0..1, memengaruhi retensi user
var fare: float = 0.0          # nilai per transaksi (kontribusi GMV)
var take_rate: float = 0.0     # porsi fare yang jadi revenue
var unlock_mau: int = 0
var active: bool = false

func _init(d: Dictionary = {}) -> void:
	if d.is_empty():
		return
	id = d.get("id", "")
	label_id = d.get("label_id", id)
	label_en = d.get("label_en", id)
	rnd_cost = float(d.get("rnd_cost", 0.0))
	ops_cost_monthly = float(d.get("ops_cost_monthly", 0.0))
	capacity = int(d.get("capacity", 0))
	quality = float(d.get("base_quality", 0.5))
	fare = float(d.get("fare", 0.0))
	take_rate = float(d.get("take_rate", 0.0))
	unlock_mau = int(d.get("unlock_mau", 0))

func revenue_per_transaction() -> float:
	return fare * take_rate
