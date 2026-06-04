extends Node2D
## Orkestrator + bootstrap mode BeJek (P0). Hidup di scene bejek.tscn (bukan autoload).
## Loop MINGGUAN: tim kerja di fitur aktif (PRD→Dev→QA→Fix→Done) → rilis → revenue.

signal changed()
signal notify(msg: String)
signal game_over(reason: String)
signal game_won(users: int)
signal feature_released(info: Dictionary)   # reveal rilis (P2): rincian skor & dampak

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
var boost_pending: bool = false   # tawaran boost §6.4 menunggu keputusan pemain
var _boost_chance: float = 0.0
var versions: Array = []          # manifest versi (bejek_versions.json)
var version_idx: int = 0          # versi yang sedang terbuka
var proposing: bool = false       # sedang menggarap proposal versi berikutnya (§5)
var _proposal_progress: float = 0.0
var _proposal_req: float = 0.0

var _bal: Dictionary = {}
var _fcfg: Dictionary = {}
var _bj: Dictionary = {}
var _accum: float = 0.0
var _idc: int = 0
var _channels: Array = []      # channel rekrut (recruit_channels.json)
var _office_levels: Array = [] # tingkat kantor (office.json) — visual P2

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
	# Roadmap versi (§5). v1 langsung terbuka (tutorial); v2+ butuh proposal.
	versions = (DataLoader.load_json("bejek_versions.json").get("versions", []) as Array).duplicate()
	if versions.is_empty():
		versions = [{ "id": "v1", "label": "BeJek v1", "file": "bejek_v1.json", "proposal_effort": 0 }]
	version_idx = 0
	pool = (DataLoader.load_json(str(versions[0].get("file", "bejek_v1.json"))).get("features", []) as Array).duplicate()
	active = null
	assigned.clear()
	users = 0
	week = 1
	year = 1
	speed = 0
	running = true
	won = false
	boost_pending = false
	proposing = false
	_proposal_progress = 0.0
	_proposal_req = 0.0
	# Founder: Product + sedikit coding. Gaji Rp 1000 (founder kerja "gratis";
	# unit cash = ribuan Rp, jadi 1 = Rp 1.000).
	var f := _make("Kamu (Founder)", { "product": 4, "coding": 3 }, 1)
	talents.append(f)
	# Tingkat kantor (visual P2): tumbuh otomatis dari ukuran tim.
	_office_levels = (DataLoader.load_json("office.json").get("levels", []) as Array).duplicate()
	# Channel rekrut (§3.2). Batch awal gratis lewat "mulut ke mulut".
	_channels = (DataLoader.load_json("recruit_channels.json").get("channels", []) as Array).duplicate()
	candidates.clear()
	if not _channels.is_empty():
		_run_channel(_channel_by_id("mulut"))
	emit_signal("notify", "Bos, kita belum punya tim & produk. Pasang iklan buat rekrut, lalu develop fitur pertama!")
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
	var working := false
	var pskill := ""
	if proposing:
		working = true
		pskill = "product"
		_advance_proposal()
	elif active != null and not active.is_done():
		working = true
		var prev := active.phase
		active.apply_week(assigned, _fcfg, team_combo_mult())
		if active.phase != prev:
			emit_signal("notify", "%s → fase %s" % [active.label, active.phase_label()])
			if active.is_done():
				emit_signal("notify", "%s SIAP DIRILIS (skor %d%%) — klik Rilis!" % [active.label, int(active.score() * 100)])
		_maybe_offer_boost()
		pskill = _phase_skill()
	# Stamina: hanya yang BENAR-BENAR berkontribusi di fase ini (skill relevan > 0)
	# yang capek; sisanya (termasuk yang skill-nya tak dipakai fase ini) ikut pulih.
	var drain := float(_bj.get("stamina_drain", 9.0))
	var rec := float(_bj.get("stamina_recover", 18.0))
	var tired := float(_bj.get("tired_threshold", 30.0))
	for t in talents:
		var before: float = t.stamina
		var contributing: bool = working and assigned.has(t) and pskill != "" and int(t.get(pskill)) > 0
		if contributing:
			t.stamina = clampf(t.stamina - drain, 0.0, 100.0)
		else:
			t.stamina = clampf(t.stamina + rec, 0.0, 100.0)
		if before > tired and t.stamina <= tired:
			emit_signal("notify", "%s kelelahan 😴 — istirahatkan (Tarik) biar pulih!" % t.person_name)
	# Ekonomi & waktu mingguan: user organik dari fitur rilis, kas (revenue − burn),
	# maju 1 minggu, lalu cek runway (kas < 0 = kalah).
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

func _phase_skill() -> String:
	if active == null:
		return ""
	match active.phase:
		FeatureProject.PRD: return "product"
		FeatureProject.DEV, FeatureProject.FIX: return "coding"
		FeatureProject.QA: return "qa"
		_: return ""
	return ""

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
	boost_pending = false
	pool.erase(def)
	emit_signal("notify", "Mulai develop: %s (fase PRD — tugaskan Product!)" % active.label)
	emit_signal("changed")
	return true

# --- Proposal / versi v2+ (§5) ---

## Versi yang sedang terbuka.
func current_version_label() -> String:
	if versions.is_empty():
		return ""
	return str(versions[version_idx].get("label", ""))

## Ada versi berikutnya yang belum terbuka?
func has_next_version() -> bool:
	return version_idx < versions.size() - 1

func next_version_label() -> String:
	if not has_next_version():
		return ""
	return str(versions[version_idx + 1].get("label", ""))

## Boleh mulai proposal versi berikutnya: tak ada fitur aktif, backlog versi ini
## sudah habis (semua dirilis), dan masih ada versi lanjutan.
func can_propose() -> bool:
	return not proposing and active == null and pool.is_empty() and has_next_version()

## Progres proposal 0..1 (untuk progress bar UI).
func proposal_pct() -> float:
	if _proposal_req <= 0.0:
		return 0.0
	return clampf(_proposal_progress / _proposal_req, 0.0, 1.0)

func start_proposal() -> bool:
	if not can_propose():
		return false
	proposing = true
	_proposal_progress = 0.0
	_proposal_req = float(versions[version_idx + 1].get("proposal_effort", 50.0))
	assigned = talents.duplicate()
	boost_pending = false
	emit_signal("notify", "📝 Bikin proposal %s — tugaskan Product (PM)! Akumulasi visi sampai matang." % next_version_label())
	emit_signal("changed")
	return true

## Satu minggu kerja proposal: PM mengakumulasi product point (di-boost Management & combo).
func _advance_proposal() -> void:
	var coef := float(_fcfg.get("point_coef", 1.0)) * team_combo_mult()
	var mgmt := 1.0
	var P := 0.0
	for t in assigned:
		P += t.product * t.stamina_factor()
		mgmt += t.management * float(_fcfg.get("management_bonus_per_skill", 0.05))
	_proposal_progress += P * coef * mgmt
	if _proposal_progress >= _proposal_req:
		_unlock_next_version()

func _unlock_next_version() -> void:
	proposing = false
	version_idx += 1
	var v: Dictionary = versions[version_idx]
	pool = (DataLoader.load_json(str(v.get("file", ""))).get("features", []) as Array).duplicate()
	emit_signal("notify", "🎯 Proposal kelar! %s terbuka — %d fitur baru di backlog. Gas develop!" % [
		str(v.get("label", "")), pool.size()])
	emit_signal("changed")

# --- Boost: judi opt-in saat Development (§6.4) ---

## Sesekali, di tengah Development, tim menawarkan terobosan. Sekali per fitur.
func _maybe_offer_boost() -> void:
	if active == null or boost_pending or active.boost_used or active.boost_offered:
		return
	if active.phase != FeatureProject.DEV:
		return
	var bcfg: Dictionary = _fcfg.get("boost", {})
	if active.dev_progress() < float(bcfg.get("offer_at_progress", 0.25)):
		return
	if randf() >= float(bcfg.get("chance_per_week", 0.5)):
		return
	active.boost_offered = true
	boost_pending = true
	_boost_chance = active.boost_success_chance(assigned, bcfg)
	emit_signal("notify", "💡 %s nawarin terobosan buat %s — peluang sukses %d%%. Ambil risikonya?" % [
		_boost_proposer(), active.label, int(_boost_chance * 100)])
	emit_signal("changed")

func boost_chance() -> float:
	return _boost_chance

func _boost_proposer() -> String:
	for t in assigned:
		if t.coding > 0:
			return t.person_name
	return "Tim"

func accept_boost() -> void:
	if not boost_pending or active == null:
		return
	boost_pending = false
	active.boost_used = true
	var bcfg: Dictionary = _fcfg.get("boost", {})
	var success := randf() < _boost_chance
	active.resolve_boost(success, bcfg)
	if success:
		emit_signal("notify", "🚀 Terobosan BERHASIL! Development %s melonjak." % active.label)
	else:
		emit_signal("notify", "💥 Terobosan GAGAL — bug menumpuk di %s. (QA bakal sibuk)" % active.label)
	emit_signal("changed")

func decline_boost() -> void:
	if not boost_pending:
		return
	boost_pending = false
	if active != null:
		active.boost_used = true
	emit_signal("notify", "Main aman — terobosan ditolak.")
	emit_signal("changed")

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

# --- Team chemistry / combo (§9 P1+) — dihitung dari komposisi seluruh tim ---

func team_combo_info() -> Dictionary:
	return FeatureProject.team_combo(talents, _fcfg)

func team_combo_mult() -> float:
	return float(team_combo_info().mult)

func team_combo_label() -> String:
	return str(team_combo_info().label)

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
	# Development (fungsi inti) wajib penuh; sisanya boleh dikorbankan = rilis cepat (§6.2).
	if active == null or not active.can_release():
		return false
	boost_pending = false
	var rushed := not active.is_done()
	var sc := active.score()
	var review := int(round(sc * float(_bj.get("review_max", 40.0))))
	var rmult := _review_mult(review)
	economy.cash += sc * float(_bj.get("launch_bonus_per_score", 9000.0))
	var gained := int(round(sc * float(_bj.get("users_per_release", 4500.0)) * rmult))
	users += gained
	released.append({ "label": active.label, "score": sc, "review": review })
	var tag := " ⚡(cepat)" if rushed else ""
	emit_signal("notify", "📰 %s%s — Review %d/40 → %s +%s user" % [active.label, tag, review, _review_verdict(review), _group(gained)])
	var incident_lost := 0
	if rushed:
		incident_lost = _resolve_incident(active)
	# Reveal rilis (P2): kirim rincian ke UI untuk layar skor.
	emit_signal("feature_released", {
		"label": active.label, "review": review, "score": sc, "verdict": _review_verdict(review),
		"gained": gained, "rushed": rushed, "incident_lost": incident_lost,
		"ratios": active.dim_ratios(),
	})
	active = null
	assigned.clear()
	emit_signal("changed")
	# Backlog versi ini habis: menang bila versi terakhir, atau buka proposal versi lanjut.
	if pool.is_empty() and not won:
		if has_next_version():
			emit_signal("notify", "🎉 Semua fitur %s dirilis! Buat proposal %s untuk lanjut." % [
				current_version_label(), next_version_label()])
		else:
			won = true
			running = false
			speed = 0
			emit_signal("game_won", users)
	return true

## Risiko insiden rilis cepat (§6.2): makin tipis Security & makin banyak bug, makin
## besar peluang akun diretas / data bocor / server down → user kabur massal.
## Mengembalikan jumlah user yang kabur (0 bila tak ada insiden).
func _resolve_incident(feat) -> int:
	var rc: Dictionary = _bj.get("rush", {})
	var gap := 1.0 - feat.security_ratio()
	var chance := clampf(
		gap * float(rc.get("incident_per_security_gap", 0.6)) + feat.bugs * float(rc.get("incident_per_bug", 0.02)),
		0.0, float(rc.get("incident_max", 0.9)))
	if randf() >= chance:
		return 0
	var lost := int(round(users * float(rc.get("incident_user_loss_pct", 0.3))))
	users = maxi(0, users - lost)
	var fine := float(rc.get("incident_fine", 0.0))
	economy.cash -= fine
	emit_signal("notify", "⚠️ INSIDEN! %s kebobolan — %s user kabur. Akibat rilis kecepetan tanpa Security." % [feat.label, _group(lost)])
	return lost

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

# --- Hiring channels (§3.2): bayar iklan → batch pelamar (cost vs jumlah vs kualitas) ---

## Daftar channel (untuk UI: label, cost, dll).
func recruit_channels() -> Array:
	return _channels

func can_afford_channel(ch: Dictionary) -> bool:
	return economy.cash >= float(ch.get("cost", 0.0))

## Pasang iklan di channel: potong biaya, hasilkan batch pelamar baru (gantikan board).
func recruit(ch: Dictionary) -> bool:
	if ch.is_empty() or not can_afford_channel(ch):
		emit_signal("notify", "Kas belum cukup buat pasang %s." % str(ch.get("label", "iklan")))
		return false
	economy.cash -= float(ch.get("cost", 0.0))
	_run_channel(ch)
	emit_signal("notify", "%s: %d pelamar masuk! Cek skill & gaji, lalu rekrut." % [
		str(ch.get("label", "")), candidates.size()])
	emit_signal("changed")
	return true

# --- helper ---

func _channel_by_id(id: String) -> Dictionary:
	for ch in _channels:
		if str(ch.get("id", "")) == id:
			return ch
	return _channels[0] if not _channels.is_empty() else {}

## Isi `candidates` dengan batch baru sesuai distribusi channel.
func _run_channel(ch: Dictionary) -> void:
	candidates.clear()
	var cr: Array = ch.get("count", [1, 2])
	var n := randi_range(int(cr[0]), int(cr[1]))
	for i in n:
		candidates.append(_gen_candidate(ch))

func _gen_candidate(ch: Dictionary) -> Talent:
	const ROLES := ["Product", "Developer", "Designer", "QA", "Manajer"]
	var role: String = ROLES[randi() % ROLES.size()]
	var key: String = ROLE_SKILL.get(role, "coding")
	var lr: Array = ch.get("level", [4, 8])
	var lvl := randi_range(int(lr[0]), int(lr[1]))
	# Bintang: peluang langka untuk pelamar berkualitas tinggi (TV paling sering).
	if randf() < float(ch.get("star_chance", 0.0)):
		var sr: Array = ch.get("star_level", [8, 10])
		lvl = maxi(lvl, randi_range(int(sr[0]), int(sr[1])))
	var d := { key: lvl }
	d["coding"] = int(d.get("coding", 0)) + (1 if role != "Developer" else 0)  # skill sekunder kecil
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

## Skill dominan (untuk warna badge 5-peran di kantor) — P2 visualisasi.
func role_badge_type(t: Talent) -> String:
	var best := "coding"
	var mx := -1
	for key in ["product", "coding", "ui_ux", "qa", "management"]:
		var v: int = t.get(key)
		if v > mx:
			mx = v
			best = key
	return best

# --- Kantor (P2): tingkat ruangan tumbuh otomatis seiring ukuran tim ---

## Tingkat kantor 0..3 (Garasi→Menara) dari ukuran tim vs kapasitas tiap level.
func office_tier() -> int:
	for i in _office_levels.size():
		if talents.size() <= int(_office_levels[i].get("capacity", 9999)):
			return i
	return maxi(0, _office_levels.size() - 1)

func office_tier_name() -> String:
	var t := office_tier()
	return str(_office_levels[t].get("name", "")) if t < _office_levels.size() else ""

func office_capacity() -> int:
	var t := office_tier()
	return int(_office_levels[t].get("capacity", 12)) if t < _office_levels.size() else 12

## Ringkasan aktivitas kantor untuk banner in-world.
func activity_text() -> String:
	if proposing:
		return "📝 Proposal %s — %d%%" % [next_version_label(), int(proposal_pct() * 100)]
	if active != null:
		if active.is_done():
			return "✅ %s siap rilis (%d%%)" % [active.label, int(active.score() * 100)]
		return "🛠 %s — %s" % [active.label, active.phase_label()]
	if can_propose():
		return "Backlog habis — siap bikin proposal"
	return "Menunggu arahan Bos…"
