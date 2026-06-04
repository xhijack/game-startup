class_name FeatureProject
extends RefCounted
## Pengembangan fitur BeJek — ALUR BERTAHAP per-peran (docs/BeJek_CoreSystems.md §6.0):
##   PRD (Product) → Development (Coder) → QA (cari bug) → Fix (Coder) → Done → Released
## 4 dimensi nilai: creativity, ui_ux, security, development.
## Bug muncul saat dev, ditemukan QA, dibersihkan saat fix. MURNI, tanpa node.

const PRD := "prd"
const DEV := "dev"
const QA := "qa"
const FIX := "fix"
const DONE := "done"
const RELEASED := "released"

const PHASE_LABEL := {
	PRD: "Bikin PRD", DEV: "Development", QA: "QA / Testing",
	FIX: "Perbaiki Bug", DONE: "Siap Rilis", RELEASED: "Dirilis",
}

var id: String = ""
var label: String = ""
var phase: String = PRD
var dims: Dictionary = { "creativity": 0.0, "ui_ux": 0.0, "security": 0.0, "development": 0.0 }
var bugs: float = 0.0          # bug belum diperbaiki
var bugs_found: float = 0.0    # bug yang sudah ditemukan QA (perlu fix)

var focus_mode: String = "normal"   # normal | kebut | matang | riset
var _prd_progress: float = 0.0
var _qa_progress: float = 0.0
var dev_req: float = 50.0      # ukuran fitur (effort Development)

const MODE_LABEL := { "normal": "Normal", "kebut": "Kebut Rilis", "matang": "Matang", "riset": "Riset" }

func _init(d: Dictionary = {}) -> void:
	if d.is_empty():
		return
	id = str(d.get("id", ""))
	label = str(d.get("label", id))
	dev_req = float(d.get("dev_req", d.get("dev", 50.0)))

func _prd_req() -> float: return dev_req * 0.4
func _qa_req() -> float: return dev_req * 0.35

## Satu minggu kerja dari `talents` yang ditugaskan. cfg = balance.feature_dev.
func apply_week(talents: Array, cfg: Dictionary) -> void:
	if phase == DONE or phase == RELEASED:
		return
	var coef := float(cfg.get("point_coef", 1.0))
	var mgmt := 1.0 + _mgmt_bonus(talents, cfg)
	# Multiplier mode fokus (cepat-vs-matang).
	var mode: Dictionary = (cfg.get("modes", {}) as Dictionary).get(focus_mode, {})
	var dmult := float(mode.get("dev", 1.0))
	var qmult := float(mode.get("quality", 1.0))
	var bmult := float(mode.get("bug", 1.0))
	var P := _sum(talents, "product") * coef * mgmt
	var C := _sum(talents, "coding") * coef * mgmt
	var U := _sum(talents, "ui_ux") * coef * mgmt
	var Qp := _sum(talents, "qa") * coef * mgmt

	match phase:
		PRD:
			# PM merumuskan visi: creativity + sketsa UI/UX awal.
			_prd_progress += P
			dims.creativity += P * qmult
			dims.ui_ux += U * 0.5 * qmult
			if _prd_progress >= _prd_req():
				phase = DEV
		DEV:
			# Developer bikin fungsi; designer poles UI/UX; coding menimbulkan bug.
			dims.development += C * dmult
			dims.ui_ux += U * qmult
			bugs += C * float(cfg.get("bug_rate", 0.08)) * bmult
			if dims.development >= dev_req:
				phase = QA
		QA:
			# QA menemukan bug + menaikkan security.
			_qa_progress += Qp
			dims.security += Qp * qmult
			var newly := minf(bugs - bugs_found, Qp * float(cfg.get("qa_find_rate", 0.5)))
			bugs_found += maxf(0.0, newly)
			if _qa_progress >= _qa_req():
				phase = FIX if bugs_found > 0.5 else DONE
		FIX:
			# Developer memperbaiki bug temuan QA; hardening security.
			var fixed := C * float(cfg.get("fix_rate", 0.6))
			bugs_found = maxf(0.0, bugs_found - fixed)
			bugs = maxf(0.0, bugs - fixed)
			dims.security += C * 0.2 * qmult
			if bugs_found <= 0.5:
				phase = DONE

func _sum(talents: Array, key: String) -> float:
	var s := 0.0
	for t in talents:
		s += t.get(key) * t.stamina_factor()
	return s

func _mgmt_bonus(talents: Array, cfg: Dictionary) -> float:
	var m := 0
	for t in talents:
		m += t.management
	return m * float(cfg.get("management_bonus_per_skill", 0.05))

func is_done() -> bool:
	return phase == DONE or phase == RELEASED

func phase_label() -> String:
	return PHASE_LABEL.get(phase, phase)

func mode_label() -> String:
	return MODE_LABEL.get(focus_mode, focus_mode)

## Skor rilis 0..1 dari 4 dimensi (dinormalisasi ke ukuran fitur) − penalti bug.
func score() -> float:
	var scale := maxf(1.0, dev_req)
	var cre := clampf(dims.creativity / (scale * 0.6), 0.0, 1.0)
	var ux := clampf(dims.ui_ux / (scale * 0.6), 0.0, 1.0)
	var sec := clampf(dims.security / (scale * 0.5), 0.0, 1.0)
	var dev := clampf(dims.development / scale, 0.0, 1.0)
	var q := (cre + ux + sec + dev) / 4.0
	var bug_pen := clampf(bugs_found / (scale * 0.3), 0.0, 1.0) * 0.4
	return clampf(q - bug_pen, 0.0, 1.0)
