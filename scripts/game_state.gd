extends Node
## Orkestrator state game — autoload "GameState".
## Menyatukan core MURNI (Economy/Talent/Service/Market) dengan loop waktu + sinyal.
## UI HANYA membaca dari sini lewat sinyal; UI tidak menyimpan/menghitung balancing.

signal day_advanced(date: Dictionary)
signal state_changed()
signal game_over(reason: String)
signal funding_raised(label: String)
signal game_won(label: String, valuation: float, ownership: float)
signal event_fired(label: String, type: String)
signal feature_unlocked(label: String)
signal service_launched(label: String)
signal city_opened(label: String)
signal office_upgraded(name: String)
signal hire_blocked()

var economy: Economy
var funding: Funding
var competitor: Competitor
var talents: Array[Talent] = []
var services: Dictionary = {}        # id -> Service
var candidates: Array[Talent] = []   # job board

var mau: int = 0
var gmv: float = 0.0
var date: Dictionary = {"year": 2010, "month": 1, "day": 1}
var speed: int = 0                   # 0 pause, 1 normal, 2 fast, 3 faster
var running: bool = false
var won: bool = false
var overtime: bool = false           # mode lembur: output↑ tapi stamina↓
var is_new_game: bool = true         # untuk memicu intro/tutorial
var event_log: Array = []            # label event terbaru (maks 8)
var unlocked_features: Array = []    # id fitur R&D yang sudah dibangun
var opened_cities: Array = []        # id kota yang sudah dibuka (termasuk home)
var office_level: int = 0             # tingkat kantor (kapasitas karyawan)

var _balance: Dictionary = {}
var _talent_defs: Dictionary = {}
var _funding_defs: Dictionary = {}
var _events_defs: Dictionary = {}
var _features_defs: Dictionary = {}
var _cities_defs: Dictionary = {}
var _office_defs: Dictionary = {}
var _value_per_mau: float = 0.0
var _demand_mult: float = 1.0        # modifier demand musiman/event
var _demand_days_left: int = 0
var _acquisition_bonus: int = 0      # tambahan akuisisi harian dari fitur R&D
var _promo_active: bool = false
var _promo_days_left: int = 0
var _promo_acq_bonus: int = 0
var _promo_daily_cost: float = 0.0
var _accum: float = 0.0
var _id_counter: int = 0

func start_new_game() -> void:
	randomize()  # variasi nama kandidat & roll event antar sesi
	_balance = DataLoader.load_json("balance.json")
	_talent_defs = DataLoader.load_json("talents.json")
	_funding_defs = DataLoader.load_json("funding.json")
	_events_defs = DataLoader.load_json("events.json")
	_features_defs = DataLoader.load_json("features.json")
	_cities_defs = DataLoader.load_json("cities.json")
	_office_defs = DataLoader.load_json("office.json")
	var service_defs := DataLoader.load_json("services.json")

	economy = Economy.new(float(_balance.get("starting_cash", 0.0)))
	funding = Funding.new()
	var comp_cfg: Dictionary = _balance.get("competitor", {})
	competitor = Competitor.new()
	competitor.comp_name = str(comp_cfg.get("name", "Kompetitor"))
	competitor.mau = int(comp_cfg.get("start_mau", 0))
	_value_per_mau = float(_funding_defs.get("value_per_mau", 0.0))
	talents.clear()
	services.clear()
	candidates.clear()
	event_log.clear()
	unlocked_features.clear()
	opened_cities.clear()
	for c in _cities_defs.get("cities", []):
		if bool(c.get("home", false)):
			opened_cities.append(str(c.get("id", "")))
	office_level = 0
	mau = 0
	gmv = 0.0
	date = (_balance.get("start_date", {"year": 2010, "month": 1, "day": 1}) as Dictionary).duplicate()
	speed = 0
	running = true
	won = false
	overtime = false
	is_new_game = true
	_demand_mult = 1.0
	_demand_days_left = 0
	_acquisition_bonus = 0
	_promo_active = false
	_promo_days_left = 0
	_accum = 0.0

	# MVP/P0: hanya ride-hailing yang aktif. Layanan lain ada datanya tapi belum dibuka.
	for sid in service_defs.keys():
		if str(sid).begins_with("_"):
			continue
		var svc := Service.new(service_defs[sid])
		svc.id = sid
		svc.active = (sid == "ride_hailing")
		services[sid] = svc

	# Founder: 1 engineer awal.
	var founder := _make_candidate("engineer")
	founder.person_name = "Kamu (Founder)"
	talents.append(founder)

	_refresh_job_board()
	_recompute_finances()
	emit_signal("state_changed")

func set_speed(s: int) -> void:
	speed = clampi(s, 0, 3)
	emit_signal("state_changed")

func _process(delta: float) -> void:
	if not running or speed <= 0:
		return
	var spd: Dictionary = _balance.get("seconds_per_day", {})
	var seconds_per_day: float = float(spd.get(str(speed), 1.0))
	_accum += delta
	while _accum >= seconds_per_day:
		_accum -= seconds_per_day
		_advance_day()

func _advance_day() -> void:
	_tick_demand()
	# Tim bekerja: stamina, XP, naik level (sebelum hitung output).
	var tcfg: Dictionary = _balance.get("talent", {})
	for t in talents:
		t.work_day(overtime, tcfg)
	_recompute_finances()

	var comp_cfg: Dictionary = _balance.get("competitor", {})
	var active_list := _active_services()
	if not active_list.is_empty():
		var cfg: Dictionary = _balance.get("market", {})
		var new_users := Market.daily_new_users(_marketing_power(), cfg) + _acquisition_bonus
		new_users += Cities.sum_acquisition(_opened_city_defs())
		if _promo_active:
			new_users += _promo_acq_bonus
		var churn := Market.daily_churn(mau, _avg_active_quality(), cfg)
		churn += Competitor.pressure_churn(mau, competitor.mau, comp_cfg)
		mau = maxi(0, mau + new_users - churn)
		# Tiap layanan aktif memonetisasi basis MAU yang sama (super-app).
		for svc in active_list:
			gmv += Market.daily_transactions(mau, svc.capacity, cfg, _demand_mult) * svc.fare

	# Kompetitor selalu tumbuh.
	competitor.mau += Competitor.daily_growth(competitor.mau, comp_cfg)

	# Arus kas satu hari (biaya promo sudah masuk burn lewat _recompute_finances).
	var days_per_month := float(_balance.get("days_per_month", 30))
	economy.apply_period(1.0 / days_per_month)

	_tick_promo()

	var prev_month: int = date.month
	_advance_date()
	if date.month != prev_month:
		_maybe_fire_event()

	emit_signal("day_advanced", date)
	emit_signal("state_changed")

	if economy.is_bankrupt():
		running = false
		speed = 0
		emit_signal("game_over", "Runway habis — cash di bawah nol.")

## --- Promo / bakar duit ---

func start_promo() -> bool:
	if _promo_active:
		return false
	var p: Dictionary = _balance.get("promo", {})
	_promo_days_left = int(p.get("duration_days", 0))
	if _promo_days_left <= 0:
		return false
	_promo_acq_bonus = int(p.get("acquisition_bonus", 0))
	_promo_daily_cost = float(p.get("daily_cost", 0.0))
	_promo_active = true
	_recompute_finances()
	emit_signal("state_changed")
	return true

func is_promo_active() -> bool:
	return _promo_active

func promo_days_left() -> int:
	return _promo_days_left

func promo_daily_cost() -> float:
	return float(_balance.get("promo", {}).get("daily_cost", 0.0))

func _tick_promo() -> void:
	if _promo_active:
		_promo_days_left -= 1
		if _promo_days_left <= 0:
			_promo_active = false
			_recompute_finances()

## Modifier demand musiman/event meluruh ke normal setelah durasinya habis.
func _tick_demand() -> void:
	if _demand_days_left > 0:
		_demand_days_left -= 1
		if _demand_days_left == 0:
			_demand_mult = 1.0

## Dipanggil tiap pergantian bulan: peluang memunculkan & menerapkan satu event.
func _maybe_fire_event() -> void:
	if randf() >= float(_events_defs.get("monthly_chance", 0.0)):
		return
	var eligible := EventEngine.eligible_events(_events_defs.get("events", []), int(date.month))
	var e := EventEngine.pick(eligible, randf())
	if e.is_empty():
		return
	_apply_event(e)
	var label := str(e.get("label_id", e.get("id", "Event")))
	event_log.append(label)
	if event_log.size() > 8:
		event_log.pop_front()
	emit_signal("event_fired", label, str(e.get("type", "")))

## Terapkan efek event ke state. Aman dipanggil manual (untuk test).
func _apply_event(e: Dictionary) -> void:
	var fx: Dictionary = e.get("effect", {})
	if fx.has("mau_pct"):
		mau = maxi(0, int(round(mau * (1.0 + float(fx["mau_pct"])))))
	if fx.has("cash_delta"):
		economy.cash += float(fx["cash_delta"])
	if fx.has("quality_delta"):
		var svc := _active_service()
		if svc != null:
			svc.quality = clampf(svc.quality + float(fx["quality_delta"]), 0.0, 1.0)
	if fx.has("lose_talent"):
		_remove_talents(int(fx["lose_talent"]))
	if fx.has("demand_pct"):
		_demand_mult = 1.0 + float(fx["demand_pct"])
		_demand_days_left = int(fx.get("duration_days", 30))
	_recompute_finances()

## Lepas N talent dari paling akhir; founder (indeks 0) tidak pernah dilepas.
func _remove_talents(n: int) -> void:
	for i in n:
		if talents.size() <= 1:
			break
		talents.pop_back()

func _recompute_finances() -> void:
	var burn := 0.0
	for t in talents:
		burn += t.salary_monthly
	var revenue := 0.0
	var cfg: Dictionary = _balance.get("market", {})
	var days_per_month := float(_balance.get("days_per_month", 30))
	for sid in services:
		var svc: Service = services[sid]
		if svc.active:
			burn += svc.ops_cost_monthly
			var txns := Market.daily_transactions(mau, svc.capacity, cfg, _demand_mult)
			revenue += txns * svc.revenue_per_transaction() * days_per_month
	if _promo_active:
		burn += _promo_daily_cost * days_per_month
	burn += Cities.sum_ops(_opened_city_defs())
	economy.burn_rate_monthly = burn
	economy.revenue_monthly = revenue

func hire(candidate: Talent) -> bool:
	if candidate == null:
		return false
	# Kantor punya kapasitas meja; harus upgrade dulu kalau penuh.
	if talents.size() >= office_capacity():
		emit_signal("hire_blocked")
		return false
	talents.append(candidate)
	candidates.erase(candidate)
	_recompute_finances()
	emit_signal("state_changed")
	return true

## --- Tingkat & upgrade kantor ---

func office_levels() -> Array:
	return _office_defs.get("levels", [])

func office_capacity() -> int:
	var lv := office_levels()
	if lv.is_empty():
		return 9999
	return int(lv[clampi(office_level, 0, lv.size() - 1)].get("capacity", 9999))

func office_name() -> String:
	var lv := office_levels()
	if lv.is_empty():
		return "Kantor"
	return str(lv[clampi(office_level, 0, lv.size() - 1)].get("name", "Kantor"))

func next_office() -> Dictionary:
	var lv := office_levels()
	if office_level + 1 < lv.size():
		return lv[office_level + 1]
	return {}

func can_upgrade_office() -> bool:
	var nxt := next_office()
	if nxt.is_empty():
		return false
	return economy.cash >= float(nxt.get("upgrade_cost", 0.0))

func upgrade_office() -> bool:
	var nxt := next_office()
	if nxt.is_empty() or economy.cash < float(nxt.get("upgrade_cost", 0.0)):
		return false
	economy.cash -= float(nxt.get("upgrade_cost", 0.0))
	office_level += 1
	_recompute_finances()
	emit_signal("office_upgraded", office_name())
	emit_signal("state_changed")
	return true

## --- Multi-layanan (super-app): launch layanan baru ---

func services_list() -> Array:
	var out: Array = []
	for sid in services:
		out.append(services[sid])
	return out

func can_launch_service(svc: Service) -> bool:
	if svc == null or svc.active:
		return false
	if mau < svc.unlock_mau:
		return false
	return economy.cash >= svc.rnd_cost

func launch_service(svc: Service) -> bool:
	if not can_launch_service(svc):
		return false
	economy.cash -= svc.rnd_cost
	svc.active = true
	_recompute_finances()
	emit_signal("service_launched", svc.label_id)
	emit_signal("state_changed")
	return true

## --- Ekspansi kota ---

func cities_list() -> Array:
	return _cities_defs.get("cities", [])

func _opened_city_defs() -> Array:
	var out: Array = []
	for c in cities_list():
		if opened_cities.has(str(c.get("id", ""))):
			out.append(c)
	return out

func can_open_city(city: Dictionary) -> bool:
	if city.is_empty():
		return false
	if opened_cities.has(str(city.get("id", ""))):
		return false
	if mau < int(city.get("unlock_mau", 0)):
		return false
	return economy.cash >= float(city.get("open_cost", 0.0))

func open_city(city: Dictionary) -> bool:
	if not can_open_city(city):
		return false
	economy.cash -= float(city.get("open_cost", 0.0))
	opened_cities.append(str(city.get("id", "")))
	_recompute_finances()
	emit_signal("city_opened", str(city.get("label", "")))
	emit_signal("state_changed")
	return true

## --- R&D / Fitur (sistem kombinasi talent) ---

func features() -> Array:
	return _features_defs.get("features", [])

func can_build_feature(feature: Dictionary) -> bool:
	if feature.is_empty():
		return false
	if unlocked_features.has(str(feature.get("id", ""))):
		return false
	if economy.cash < float(feature.get("cost", 0.0)):
		return false
	return Research.meets_requirements(feature, talents)

func build_feature(feature: Dictionary) -> bool:
	if not can_build_feature(feature):
		return false
	economy.cash -= float(feature.get("cost", 0.0))
	unlocked_features.append(str(feature.get("id", "")))
	_apply_feature_effect(feature.get("effect", {}))
	_recompute_finances()
	emit_signal("feature_unlocked", str(feature.get("label", "")))
	emit_signal("state_changed")
	return true

func _apply_feature_effect(fx: Dictionary) -> void:
	var svc := _active_service()
	if svc != null and fx.has("quality_delta"):
		svc.quality = clampf(svc.quality + float(fx["quality_delta"]), 0.0, 1.0)
	if svc != null and fx.has("capacity_add"):
		svc.capacity += int(fx["capacity_add"])
	if svc != null and fx.has("revenue_take_delta"):
		svc.take_rate = clampf(svc.take_rate + float(fx["revenue_take_delta"]), 0.0, 1.0)
	if fx.has("acquisition_add"):
		_acquisition_bonus += int(fx["acquisition_add"])

func _find_feature(id: String) -> Dictionary:
	for f in features():
		if str(f.get("id", "")) == id:
			return f
	return {}

## Valuation startup saat ini (k) = MAU * value_per_mau.
func valuation() -> float:
	return mau * _value_per_mau

func funding_rounds() -> Array:
	return _funding_defs.get("rounds", [])

func next_funding_round() -> Dictionary:
	return funding.next_round(funding_rounds())

func can_raise_funding() -> bool:
	return funding.is_eligible(next_funding_round(), mau, valuation())

## Raih round berikutnya. IPO (is_ipo) => menang. Lainnya => suntik cash + dilusi.
func raise_funding() -> bool:
	var r := next_funding_round()
	if not funding.is_eligible(r, mau, valuation()):
		return false
	if bool(r.get("is_ipo", false)):
		funding.raise_round(r)
		won = true
		running = false
		speed = 0
		emit_signal("game_won", str(r.get("label", "IPO")), valuation(), funding.ownership)
		return true
	economy.cash += funding.raise_round(r)
	_recompute_finances()
	emit_signal("funding_raised", str(r.get("label", "")))
	emit_signal("state_changed")
	return true

func save_game() -> bool:
	return SaveManager.save(snapshot())

func load_game() -> bool:
	var data := SaveManager.load_state()
	if data.is_empty():
		return false
	start_new_game()
	is_new_game = false
	economy.cash = float(data.get("cash", economy.cash))
	mau = int(data.get("mau", 0))
	gmv = float(data.get("gmv", 0.0))
	date = data.get("date", date)
	talents.clear()
	for td in data.get("talents", []):
		talents.append(Talent.new(td))
	funding.ownership = float(data.get("ownership", 1.0))
	funding.raised_ids = data.get("raised_ids", [])
	competitor.mau = int(data.get("competitor_mau", competitor.mau))
	# Aktifkan kembali layanan yang sudah di-launch (service di-rebuild fresh saat load).
	for sid in data.get("active_services", []):
		if services.has(sid):
			services[sid].active = true
	if data.has("opened_cities"):
		opened_cities = data.get("opened_cities", [])
	office_level = int(data.get("office_level", 0))
	overtime = bool(data.get("overtime", false))
	# Re-apply efek fitur R&D yang sudah dibangun (service di-rebuild fresh saat load).
	unlocked_features.clear()
	_acquisition_bonus = 0
	for fid in data.get("unlocked_features", []):
		var fdef := _find_feature(str(fid))
		if not fdef.is_empty():
			unlocked_features.append(str(fid))
			_apply_feature_effect(fdef.get("effect", {}))
	_recompute_finances()
	emit_signal("state_changed")
	return true

func snapshot() -> Dictionary:
	var ts: Array = []
	for t in talents:
		ts.append(t.to_dict())
	var active_ids: Array = []
	for svc in _active_services():
		active_ids.append(svc.id)
	return {
		"cash": economy.cash, "mau": mau, "gmv": gmv, "date": date, "talents": ts,
		"ownership": funding.ownership, "raised_ids": funding.raised_ids,
		"unlocked_features": unlocked_features, "competitor_mau": competitor.mau,
		"active_services": active_ids, "opened_cities": opened_cities,
		"office_level": office_level, "overtime": overtime,
	}

# --- helper internal ---

func _refresh_job_board() -> void:
	candidates.clear()
	for type in ["engineer", "designer", "marketing"]:
		candidates.append(_make_candidate(type))

func _make_candidate(type: String) -> Talent:
	var types: Dictionary = _talent_defs.get("types", {})
	var def: Dictionary = types.get(type, {})
	var names: Array = _talent_defs.get("names", ["Talent"])
	_id_counter += 1
	var t := Talent.new()
	t.id = "t%d" % _id_counter
	t.person_name = names[randi() % names.size()]
	t.type = type
	t.skill = _rand_range_int(def.get("base_skill", [1, 5]))
	t.speed = _rand_range_int(def.get("base_speed", [1, 5]))
	t.salary_monthly = float(_rand_range_int(def.get("base_salary", [500, 1500])))
	return t

func _rand_range_int(r: Array) -> int:
	if r.size() < 2:
		return 1
	return randi_range(int(r[0]), int(r[1]))

func _active_service() -> Service:
	for sid in services:
		if services[sid].active:
			return services[sid]
	return null

func _active_services() -> Array:
	var out: Array = []
	for sid in services:
		if services[sid].active:
			out.append(services[sid])
	return out

func _avg_active_quality() -> float:
	var list := _active_services()
	if list.is_empty():
		return 0.5
	var sum := 0.0
	for svc in list:
		sum += svc.quality
	return sum / list.size()

## Kekuatan marketing = TOTAL skill EFEKTIF talent marketing (turun saat burnout).
## Membangun tim marketing adalah mesin pertumbuhan untuk mengalahkan kompetitor.
func _marketing_power() -> int:
	var total := 0
	for t in talents:
		if t.type == "marketing":
			total += t.effective_skill()
	return total

func toggle_overtime() -> void:
	overtime = not overtime
	emit_signal("state_changed")

## --- Latih skill talent (training berbayar) ---

func _talent_cfg() -> Dictionary:
	return _balance.get("talent", {})

func train_cost(t: Talent) -> float:
	return float(_talent_cfg().get("train_base_cost", 4000.0)) * t.skill

func can_train_talent(t: Talent) -> bool:
	if t == null:
		return false
	if t.skill >= int(_talent_cfg().get("max_skill", 10)):
		return false
	return economy.cash >= train_cost(t)

func train_talent(t: Talent) -> bool:
	if not can_train_talent(t):
		return false
	economy.cash -= train_cost(t)
	t.train(int(_talent_cfg().get("max_skill", 10)))
	_recompute_finances()
	emit_signal("state_changed")
	return true

func _advance_date() -> void:
	var dpm := int(_balance.get("days_per_month", 30))
	date.day += 1
	if date.day > dpm:
		date.day = 1
		date.month += 1
		if date.month > 12:
			date.month = 1
			date.year += 1
