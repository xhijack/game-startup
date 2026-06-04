class_name Competitor
extends RefCounted
## Kompetitor AI: punya basis user sendiri & menekan pangsa pasar kita. MURNI, tanpa node.

var comp_name: String = ""
var mau: int = 0

## Pertumbuhan user kompetitor per hari — LOGISTIC: melambat mendekati plafon
## pasar (max_mau) supaya tidak meledak eksponensial tanpa batas.
static func daily_growth(comp_mau: int, cfg: Dictionary) -> int:
	var base: float = float(cfg.get("daily_growth", 0.0))
	var rate: float = float(cfg.get("growth_rate", 0.0))
	var cap: float = float(cfg.get("max_mau", 0.0))
	var raw := base + comp_mau * rate
	if cap > 0.0:
		raw *= maxf(0.0, 1.0 - comp_mau / cap)
	return int(round(raw))

## Tambahan churn user KITA akibat tekanan kompetitor.
## Makin besar pangsa lawan, makin banyak user kita lari.
static func pressure_churn(my_mau: int, comp_mau: int, cfg: Dictionary) -> int:
	var total := my_mau + comp_mau
	if total <= 0:
		return 0
	var their_share := float(comp_mau) / float(total)
	return int(round(my_mau * their_share * float(cfg.get("pressure", 0.0))))

## Pangsa pasar kita (0..1) relatif kompetitor.
static func our_share(my_mau: int, comp_mau: int) -> float:
	var total := my_mau + comp_mau
	if total <= 0:
		return 1.0
	return float(my_mau) / float(total)
