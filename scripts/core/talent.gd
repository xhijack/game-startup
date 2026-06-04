class_name Talent
extends RefCounted
## Satu talent (SDM). Murni data + perilaku ringan, tanpa node.

var id: String = ""
var person_name: String = ""
var type: String = ""          # engineer | designer | marketing
var skill: int = 1
var speed: int = 1
var stamina: float = 100.0
var max_stamina: float = 100.0
var salary_monthly: float = 0.0
var level: int = 1
var xp: float = 0.0
var burnout: bool = false

# Skill BeJek (model baru): tiap skill berperan di fase pengembangan berbeda.
var product: int = 0      # → fase PRD (creativity & visi fitur)
var coding: int = 0       # → fase Development (fungsi) & perbaikan bug
var ui_ux: int = 0        # → dimensi UI/UX
var qa: int = 0           # → fase QA (menemukan bug) & Security
var management: int = 0   # → booster output seluruh tim

const BURNOUT_PENALTY := 0.4  # skill efektif saat kelelahan

func _init(d: Dictionary = {}) -> void:
	if d.is_empty():
		return
	id = d.get("id", "")
	person_name = d.get("person_name", "")
	type = d.get("type", "")
	skill = int(d.get("skill", 1))
	speed = int(d.get("speed", 1))
	max_stamina = float(d.get("max_stamina", 100.0))
	stamina = float(d.get("stamina", max_stamina))
	salary_monthly = float(d.get("salary_monthly", 0.0))
	level = int(d.get("level", 1))
	xp = float(d.get("xp", 0.0))
	burnout = bool(d.get("burnout", false))
	product = int(d.get("product", 0))
	coding = int(d.get("coding", 0))
	ui_ux = int(d.get("ui_ux", 0))
	qa = int(d.get("qa", 0))
	management = int(d.get("management", 0))

## Stamina sebagai faktor 0.2..1.0 untuk output kerja.
func stamina_factor() -> float:
	return clampf(stamina / 100.0, 0.2, 1.0)

## Skill efektif (turun saat burnout) — dipakai untuk output harian (mis. marketing).
func effective_skill() -> int:
	return int(ceil(skill * BURNOUT_PENALTY)) if burnout else skill

## Proses satu hari kerja: stamina, XP, naik level. Murni (cfg = balance.talent).
func work_day(overtime: bool, cfg: Dictionary) -> void:
	var drain := float(cfg.get("stamina_drain_overtime", 5.0))
	var recover := float(cfg.get("stamina_recover", 3.0))
	var burnout_th := float(cfg.get("burnout_threshold", 15.0))
	var max_skill := int(cfg.get("max_skill", 10))
	var xp_per_level := float(cfg.get("xp_per_level", 120.0))
	var base := float(cfg.get("base_xp_per_speed", 1.0))
	if overtime:
		stamina = clampf(stamina - drain, 0.0, max_stamina)
	else:
		stamina = clampf(stamina + recover, 0.0, max_stamina)
	burnout = stamina <= burnout_th
	if burnout:
		return  # kelelahan: tidak dapat XP
	xp += speed * base * (1.5 if overtime else 1.0)
	while skill < max_skill and xp >= xp_per_level * level:
		xp -= xp_per_level * level
		level += 1
		skill += 1

## Latih: naikkan skill +1 bila belum mentok. Murni.
func train(max_skill: int) -> bool:
	if skill >= max_skill:
		return false
	skill += 1
	return true

func to_dict() -> Dictionary:
	return {
		"id": id, "person_name": person_name, "type": type,
		"skill": skill, "speed": speed, "stamina": stamina,
		"max_stamina": max_stamina, "salary_monthly": salary_monthly,
		"level": level, "xp": xp, "burnout": burnout,
		"product": product, "coding": coding, "ui_ux": ui_ux, "qa": qa, "management": management,
	}
