class_name Market
extends RefCounted
## Fungsi pertumbuhan pasar — MURNI & statik, tanpa state node.
## Semua koefisien dipasok lewat `cfg` (data/balance.json -> "market").

## User baru per hari, naik seiring skill marketing.
static func daily_new_users(marketing_skill: int, cfg: Dictionary) -> int:
	var base: float = float(cfg.get("base_daily_acquisition", 0.0))
	var per_skill: float = float(cfg.get("marketing_acquisition_per_skill", 0.0))
	return int(round(base + per_skill * marketing_skill))

## Churn harian; kualitas layanan tinggi menurunkan churn.
static func daily_churn(mau: int, quality: float, cfg: Dictionary) -> int:
	var monthly_rate: float = float(cfg.get("monthly_churn_rate", 0.0))
	var q_factor: float = float(cfg.get("quality_retention_factor", 0.0))
	var effective: float = monthly_rate * (1.0 - q_factor * quality)
	return int(round(mau * (effective / 30.0)))

## Transaksi (rides) per hari, dibatasi kapasitas. `demand_mult` untuk modifier
## musiman/event (mis. 1.3 saat Ramadhan, 0.85 saat musim hujan).
static func daily_transactions(mau: int, capacity: int, cfg: Dictionary, demand_mult: float = 1.0) -> int:
	var per_user: float = float(cfg.get("rides_per_user_per_day", 0.0))
	return int(min(float(capacity), mau * per_user * demand_mult))
