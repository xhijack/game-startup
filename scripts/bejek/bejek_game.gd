extends Node2D
## Orkestrator + bootstrap mode BeJek (P0). Hidup di scene bejek.tscn (bukan autoload).
## Loop MINGGUAN: tim kerja di fitur aktif (PRD→Dev→QA→Fix→Done) → rilis → revenue.

signal changed()
signal notify(msg: String)
signal game_over(reason: String)
signal game_won(users: int)

var economy: Economy
var talents: Array = []        # Array[Talent]
var candidates: Array = []
var pool: Array = []           # definisi fitur belum dikerjakan
var active: FeatureProject = null
var assigned: Array = []       # talent yang DITUGASKAN ke fitur aktif (sisanya idle tapi tetap digaji)
var released: Array = []       # { "label": String, "score": float }
var users: int = 0             # MAU — tumbuh dari rilis fitur bagus
var week: int = 1
var year: int = 1
var speed: int = 0
var running: bool = false
var won: bool = false

var _bal: Dictionary = {}
var _fcfg: Dictionary = {}
var _bj: Dictionary = {}
var _accum: float = 0.0
var _idc: int = 0

const ROLE_SKILL := {
	"Product": "product", "Developer": "coding", "Designer": "ui_ux",
	"QA": "qa", "Manajer": "management",
}
const NAMES := ["Andi", "Bima", "Citra", "Dewi", "Eka", "Fajar", "Gita", "Hadi", "Indah", "Joko", "Kirana", "Lutfi", "Putri", "Rini"]

func _enter_tree() -> void:
	# Daftar grup lebih dulu (parent _enter_tree jalan sebelum _ready anak),
	# supaya World & UI bisa menemukan & konek saat _ready mereka.
	add_to_group("bejek_game")

func _ready() -> void:
	randomize()
	start_new()
	if OS.get_environment("SHOT") == "1":
		if OS.get_environment("SHOT_DEV") == "1":
			for c in candidates.duplicate():
				hire(c)
			develop(pool[0])
			var guard := 0
			while not active.is_done() and guard < 120:
				_advance_week()
				guard += 1
			release()
			for i in 4:
				_advance_week()
		await get_tree().create_timer(0.7).timeout
		get_viewport().get_texture().get_image().save_png("user://shot.png")
		get_tree().quit()

func start_new() -> void:
	_bal = DataLoader.load_json("balance.json")
	_fcfg = _bal.get("feature_dev", {})
	_bj = _bal.get("bejek", {})
	economy = Economy.new(float(_bj.get("start_cash", 80000.0)))
	talents.clear()
	candidates.clear()
	released.clear()
	pool = (DataLoader.load_json("bejek_v1.json").get("features", []) as Array).duplicate()
	active = null
	assigned.clear()
	users = 0
	week = 1
	year = 1
	speed = 0
	running = true
	won = false
	# Founder: Product + sedikit coding. Gaji Rp 1000 (founder kerja "gratis";
	# unit cash = ribuan Rp, jadi 1 = Rp 1.000).
	var f := _make("Kamu (Founder)", { "product": 4, "coding": 3 }, 1)
	talents.append(f)
	_refresh_candidates()
	emit_signal("notify", "Bos, kita belum punya tim & produk. Rekrut tim, lalu develop fitur pertama!")
	emit_signal("changed")

func set_speed(s: int) -> void:
	speed = clampi(s, 0, 3)
	emit_signal("changed")

func _process(dt: float) -> void:
	if not running or speed <= 0:
		return
	var spw := float((_bj.get("seconds_per_week", {}) as Dictionary).get(str(speed), 1.0))
	_accum += dt
	while _accum >= spw:
		_accum -= spw
		_advance_week()

func _advance_week() -> void:
	var working := active != null and not active.is_done()
	if working:
		var prev := active.phase
		active.apply_week(assigned, _fcfg)
		if active.phase != prev:
			emit_signal("notify", "%s → fase %s" % [active.label, active.phase_label()])
			if active.is_done():
				emit_signal("notify", "%s SIAP DIRILIS (skor %d%%) — klik Rilis!" % [active.label, int(active.score() * 100)])
	# Stamina: hanya yang BENAR-BENAR berkontribusi di fase ini (skill relevan > 0)
	# yang capek; sisanya (termasuk yang skill-nya tak dipakai fase ini) ikut pulih.
	var drain := float(_bj.get("stamina_drain", 9.0))
	var rec := float(_bj.get("stamina_recover", 18.0))
	var tired := float(_bj.get("tired_threshold", 30.0))
	var pskill := _phase_skill()
	for t in talents:
		var before: float = t.stamina
		var contributing: bool = working and assigned.has(t) and pskill != "" and int(t.get(pskill)) > 0
		if contributing:
			t.stamina = clampf(t.stamina - drain, 0.0, 100.0)
		else:
			t.stamina = clampf(t.stamina + rec, 0.0, 100.0)
		if before > tired and t.stamina <= tired:
			emit_signal("notify", "%s kelelahan 😴 — istirahatkan (Tarik) biar pulih!" % t.person_name)

func _phase_skill() -> String:
	if active == null:
		return ""
	match active.phase:
		FeatureProject.PRD: return "product"
		FeatureProject.DEV, FeatureProject.FIX: return "coding"
		FeatureProject.QA: return "qa"
		_: return ""
	# Pertumbuhan user organik dari fitur yang sudah dirilis (makin bagus makin tumbuh).
	users += int(round(_released_score_sum() * float(_bj.get("organic_per_score", 40.0))))
	economy.cash += weekly_revenue() - weekly_burn()
	week += 1
	if week > int(_bj.get("weeks_per_year", 52)):
		week = 1
		year += 1
	emit_signal("changed")
	if economy.cash < 0.0:
		running = false
		speed = 0
		emit_signal("game_over", "Runway habis — kas di bawah nol.")

# --- keuangan mingguan ---

func weekly_burn() -> float:
	var b := float(_bj.get("weekly_ops", 2000.0))
	for t in talents:
		b += t.salary_monthly / 4.33
	return b

func weekly_revenue() -> float:
	# Revenue = jumlah user × ARPU mingguan. User tumbuh dari rilis fitur bagus.
	return users * float(_bj.get("arpu_weekly", 0.5))

func _released_score_sum() -> float:
	var s := 0.0
	for f in released:
		s += f.score
	return s

func runway_weeks() -> float:
	var net := weekly_burn() - weekly_revenue()
	if net <= 0.0:
		return INF
	return economy.cash / net

# --- aksi pemain ---

func develop(def: Dictionary) -> bool:
	if active != null or def.is_empty():
		return false
	active = FeatureProject.new(def)
	assigned = talents.duplicate()  # default: semua ditugaskan
	pool.erase(def)
	emit_signal("notify", "Mulai develop: %s (fase PRD — tugaskan Product!)" % active.label)
	emit_signal("changed")
	return true

func set_focus_mode(m: String) -> void:
	if active != null:
		active.focus_mode = m
		emit_signal("notify", "Mode fokus: %s" % active.mode_label())
		emit_signal("changed")

func toggle_assign(t: Talent) -> void:
	if assigned.has(t):
		assigned.erase(t)
	else:
		assigned.append(t)
	emit_signal("changed")

func is_assigned(t: Talent) -> bool:
	return assigned.has(t)

## Skill yang dibutuhkan fase aktif (petunjuk untuk pemain).
func phase_need() -> String:
	if active == null:
		return ""
	match active.phase:
		FeatureProject.PRD: return "Product (bikin PRD → Creativity)"
		FeatureProject.DEV: return "Developer / Coding (fungsi)"
		FeatureProject.QA: return "QA (cari bug + Security)"
		FeatureProject.FIX: return "Developer (perbaiki bug)"
		_: return "siap rilis"

func release() -> bool:
	if active == null or not active.is_done():
		return false
	var sc := active.score()
	var review := int(round(sc * float(_bj.get("review_max", 40.0))))
	var rmult := _review_mult(review)
	economy.cash += sc * float(_bj.get("launch_bonus_per_score", 9000.0))
	var gained := int(round(sc * float(_bj.get("users_per_release", 4500.0)) * rmult))
	users += gained
	released.append({ "label": active.label, "score": sc, "review": review })
	emit_signal("notify", "📰 %s — Review %d/40 → %s +%s user" % [active.label, review, _review_verdict(review), _group(gained)])
	active = null
	assigned.clear()
	emit_signal("changed")
	# Menang: seluruh fitur BeJek v1 dirilis.
	if pool.is_empty() and not won:
		won = true
		running = false
		speed = 0
		emit_signal("game_won", users)
	return true

func _review_mult(r: int) -> float:
	if r >= int(_bj.get("review_viral_at", 34)): return float(_bj.get("review_mult_viral", 1.8))
	if r >= int(_bj.get("review_good_at", 28)): return float(_bj.get("review_mult_good", 1.3))
	if r >= int(_bj.get("review_ok_at", 20)): return float(_bj.get("review_mult_ok", 1.0))
	return float(_bj.get("review_mult_flop", 0.6))

func _review_verdict(r: int) -> String:
	if r >= int(_bj.get("review_viral_at", 34)): return "VIRAL! 🔥"
	if r >= int(_bj.get("review_good_at", 28)): return "disukai 🎉"
	if r >= int(_bj.get("review_ok_at", 20)): return "lumayan 🙂"
	return "kurang laku 😕"

func _group(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	return out

func hire(c: Talent) -> bool:
	if c == null:
		return false
	talents.append(c)
	candidates.erase(c)
	emit_signal("changed")
	return true

func refresh_job_board() -> void:
	_refresh_candidates()
	emit_signal("changed")

# --- helper ---

func _refresh_candidates() -> void:
	candidates.clear()
	for role in ["Product", "Developer", "Designer", "QA"]:
		candidates.append(_make_role(role))

func _make_role(role: String) -> Talent:
	var key: String = ROLE_SKILL.get(role, "coding")
	var lvl := randi_range(4, 8)
	var d := { key: lvl }
	# skill sekunder kecil
	d["coding"] = int(d.get("coding", 0)) + (1 if role != "Developer" else 0)
	var salary := 1000 + lvl * 320
	return _make(NAMES[randi() % NAMES.size()], d, salary, role)

func _make(person_name: String, skills: Dictionary, salary: float, role := "") -> Talent:
	_idc += 1
	var d := skills.duplicate()
	d["id"] = "t%d" % _idc
	d["person_name"] = person_name
	d["type"] = role
	d["salary_monthly"] = salary
	d["stamina"] = 100
	return Talent.new(d)

## Peran dominan (untuk warna sprite di kantor).
func role_color_type(t: Talent) -> String:
	var best := "engineer"
	var mx := -1
	for pair in [["product", "designer"], ["coding", "engineer"], ["ui_ux", "designer"], ["qa", "marketing"], ["management", "marketing"]]:
		var v: int = t.get(pair[0])
		if v > mx:
			mx = v
			best = pair[1]
	return best
