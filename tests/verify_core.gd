extends SceneTree
## Verifikasi assertion core via Godot asli, TANPA addon eksternal.
## Mirror dari test_economy.gd & test_market.gd (yang dipakai bila GUT terpasang).
##   godot --headless --path . -s res://tests/verify_core.gd

var _pass := 0
var _fail := 0

func _ok(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: %s" % label)

func _eq(a, b, label: String) -> void:
	_ok(a == b, "%s (got %s, want %s)" % [label, str(a), str(b)])

func _almost(a: float, b: float, eps: float, label: String) -> void:
	_ok(abs(a - b) <= eps, "%s (got %s, want ~%s)" % [label, str(a), str(b)])

func _initialize() -> void:
	# --- Economy ---
	var e := Economy.new(1000.0)
	e.revenue_monthly = 500.0; e.burn_rate_monthly = 800.0
	_eq(e.net_monthly(), -300.0, "net_monthly")

	e = Economy.new(900.0); e.burn_rate_monthly = 300.0
	_eq(e.runway_months(), 3.0, "runway_when_burning")

	e = Economy.new(600.0); e.revenue_monthly = 100.0; e.burn_rate_monthly = 400.0
	_eq(e.runway_months(), 2.0, "runway_uses_net_burn")

	e = Economy.new(1000.0); e.revenue_monthly = 1000.0; e.burn_rate_monthly = 400.0
	_eq(e.runway_months(), INF, "runway_infinite_when_profit")

	e = Economy.new(1000.0); e.burn_rate_monthly = 300.0; e.apply_period(1.0)
	_eq(e.cash, 700.0, "apply_period_full_month")

	e = Economy.new(1000.0); e.burn_rate_monthly = 300.0; e.apply_period(1.0 / 30.0)
	_almost(e.cash, 990.0, 0.01, "apply_partial_period")

	e = Economy.new(100.0); e.burn_rate_monthly = 300.0; e.apply_period(1.0)
	_ok(e.is_bankrupt(), "bankrupt_detection")

	# --- Market ---
	var cfg := {
		"base_daily_acquisition": 30, "marketing_acquisition_per_skill": 8,
		"monthly_churn_rate": 0.05, "quality_retention_factor": 0.5,
		"rides_per_user_per_day": 0.4,
	}
	_eq(Market.daily_new_users(0, cfg), 30, "new_users_base")
	_eq(Market.daily_new_users(5, cfg), 70, "new_users_with_marketing")
	_eq(Market.daily_transactions(1000, 100, cfg), 100, "txns_capped_by_capacity")
	_eq(Market.daily_transactions(100, 1000, cfg), 40, "txns_limited_by_demand")
	_eq(Market.daily_transactions(100, 1000, cfg, 2.0), 80, "txns_demand_multiplier")
	_eq(Market.daily_transactions(100, 1000, cfg, 0.5), 20, "txns_demand_reduced")
	_ok(Market.daily_churn(3000, 1.0, cfg) < Market.daily_churn(3000, 0.0, cfg), "quality_reduces_churn")

	# --- Events ---
	var evs := [
		{ "id": "viral", "effect": { "mau_pct": 0.25 } },
		{ "id": "ramadan", "months": [4], "effect": { "demand_pct": 0.30 } },
		{ "id": "rainy", "months": [11, 12, 1], "effect": { "demand_pct": -0.15 } },
	]
	_eq(EventEngine.eligible_events(evs, 6).size(), 1, "events_offseason_excluded")
	_eq(EventEngine.eligible_events(evs, 4).size(), 2, "events_seasonal_included")
	_eq(EventEngine.pick(evs, 0.0)["id"], "viral", "events_pick_low")
	_eq(EventEngine.pick(evs, 0.99)["id"], "rainy", "events_pick_high")
	_ok(EventEngine.pick([], 0.5).is_empty(), "events_pick_empty")

	# --- Funding ---
	var rounds := [
		{ "id": "seed", "require_mau": 1500, "amount": 150000, "dilution": 0.15 },
		{ "id": "series_a", "require_mau": 8000, "amount": 750000, "dilution": 0.18 },
		{ "id": "ipo", "require_mau": 120000, "require_valuation": 5000000, "is_ipo": true },
	]
	var f := Funding.new()
	_eq(f.next_round(rounds)["id"], "seed", "funding_next_first")
	_ok(not f.is_eligible(rounds[0], 1000, 0.0), "funding_ineligible_low_mau")
	_ok(f.is_eligible(rounds[0], 1500, 0.0), "funding_eligible_at_threshold")
	var cash := f.raise_round(rounds[0])
	_eq(cash, 150000.0, "funding_cash_injection")
	_almost(f.ownership, 0.85, 0.0001, "funding_dilution_15pct")
	_eq(f.next_round(rounds)["id"], "series_a", "funding_advances_after_raise")
	_ok(not f.is_eligible(rounds[2], 120000, 4000000.0), "ipo_needs_valuation")
	_ok(f.is_eligible(rounds[2], 120000, 5000000.0), "ipo_eligible_when_met")

	# --- Research (kombinasi talent) ---
	var team := [Talent.new({ "type": "engineer", "skill": 6 }), Talent.new({ "type": "designer", "skill": 5 })]
	_eq(Research.team_total_skill(team), 11, "research_total_skill")
	_ok(Research.team_has_types(team, ["engineer", "designer"]), "research_has_types")
	_ok(not Research.team_has_types(team, ["marketing"]), "research_missing_type")
	_ok(Research.meets_requirements({ "requires": { "types": ["engineer", "designer"], "min_team_skill": 10 } }, team), "research_meets_req")
	_ok(not Research.meets_requirements({ "requires": { "types": ["engineer"], "min_team_skill": 50 } }, team), "research_skill_gate")

	# --- Competitor ---
	var ccfg := { "daily_growth": 12, "growth_rate": 0.01, "max_mau": 50000, "pressure": 0.04 }
	_eq(Competitor.daily_growth(1000, ccfg), 22, "competitor_daily_growth")
	_ok(Competitor.daily_growth(49000, ccfg) < Competitor.daily_growth(1000, ccfg), "competitor_logistic_saturates")
	_eq(Competitor.daily_growth(50000, ccfg), 0, "competitor_capped_at_max")
	_eq(Competitor.pressure_churn(1000, 0, ccfg), 0, "competitor_no_pressure_alone")
	_ok(Competitor.pressure_churn(1000, 3000, ccfg) > Competitor.pressure_churn(1000, 200, ccfg), "competitor_pressure_scales")
	_almost(Competitor.our_share(750, 250), 0.75, 0.0001, "competitor_our_share")
	_eq(Competitor.our_share(0, 0), 1.0, "competitor_share_empty")

	# --- Cities ---
	var opened := [
		{ "id": "bandung", "acquisition_bonus": 0, "ops_cost_monthly": 0 },
		{ "id": "jakarta", "acquisition_bonus": 25, "ops_cost_monthly": 5000 },
	]
	_eq(Cities.sum_acquisition(opened), 25, "cities_sum_acquisition")
	_eq(Cities.sum_ops(opened), 5000.0, "cities_sum_ops")
	_eq(Cities.sum_acquisition([]), 0, "cities_sum_empty")

	# --- Talent aktif (level/XP/stamina/burnout) ---
	var tcfg := {
		"xp_per_level": 10, "max_skill": 10, "stamina_drain_overtime": 50,
		"stamina_recover": 3, "burnout_threshold": 15, "base_xp_per_speed": 1.0,
	}
	var t := Talent.new({ "type": "engineer", "skill": 2, "speed": 5, "stamina": 100, "level": 1 })
	t.work_day(false, tcfg)  # +5 xp
	t.work_day(false, tcfg)  # +5 xp → 10 ≥ 10*1 → level 2, skill 3
	_eq(t.level, 2, "talent_levels_up")
	_eq(t.skill, 3, "talent_skill_increases")
	# Burnout: stamina terkuras saat lembur → skill efektif turun, tak dapat XP.
	var t2 := Talent.new({ "type": "marketing", "skill": 10, "speed": 5, "stamina": 30, "level": 1 })
	t2.work_day(true, tcfg)  # drain 50 → stamina 0 ≤ 15 → burnout
	_ok(t2.burnout, "talent_burnout_when_drained")
	_ok(t2.effective_skill() < t2.skill, "talent_effective_skill_drops")
	# Pulih saat tidak lembur.
	t2.work_day(false, tcfg)  # +3 stamina → masih burnout? 3 ≤ 15 ya. cukup uji tak crash.
	_ok(t2.stamina > 0.0, "talent_recovers_stamina")
	# Latih: skill +1 sampai mentok.
	var t3 := Talent.new({ "type": "engineer", "skill": 4 })
	_ok(t3.train(10), "talent_train_increments")
	_eq(t3.skill, 5, "talent_train_skill_up")
	var t4 := Talent.new({ "type": "engineer", "skill": 10 })
	_ok(not t4.train(10), "talent_train_capped")

	# --- BeJek: FeatureProject (alur bertahap PRD→Dev→QA→Fix→Done) ---
	var fcfg := { "point_coef": 1.0, "management_bonus_per_skill": 0.05, "bug_rate": 0.08, "qa_find_rate": 0.6, "fix_rate": 0.6 }
	var pm := Talent.new({ "product": 8, "stamina": 100 })
	var dev := Talent.new({ "coding": 10, "stamina": 100 })
	var qa := Talent.new({ "qa": 8, "stamina": 100 })
	var feat := FeatureProject.new({ "id": "form", "label": "Form", "dev": 50 })
	# Fase PRD: hanya PM yang produktif → creativity naik.
	_eq(feat.phase, FeatureProject.PRD, "feat_starts_prd")
	for w in 10:
		feat.apply_week([pm], fcfg)
		if feat.phase != FeatureProject.PRD:
			break
	_eq(feat.phase, FeatureProject.DEV, "feat_advances_to_dev")
	_ok(feat.dims.creativity > 0.0, "feat_prd_adds_creativity")
	# Fase Development: coder isi development sampai cukup → masuk QA, bug muncul.
	for w in 12:
		feat.apply_week([dev], fcfg)
		if feat.phase != FeatureProject.DEV:
			break
	_eq(feat.phase, FeatureProject.QA, "feat_advances_to_qa")
	_ok(feat.bugs > 0.0, "feat_dev_introduces_bugs")
	# Fase QA: temukan bug → masuk FIX.
	for w in 12:
		feat.apply_week([qa], fcfg)
		if feat.phase != FeatureProject.QA:
			break
	_ok(feat.phase == FeatureProject.FIX or feat.phase == FeatureProject.DONE, "feat_qa_then_fix_or_done")
	# Fase Fix: coder bersihkan bug → DONE.
	for w in 20:
		feat.apply_week([dev], fcfg)
		if feat.is_done():
			break
	_eq(feat.phase, FeatureProject.DONE, "feat_done_after_fix")
	_ok(feat.bugs_found <= 0.5, "feat_bugs_fixed")
	_ok(feat.score() > 0.0 and feat.score() <= 1.0, "feat_score_in_range")
	# Management mem-boost output PRD.
	var feat2 := FeatureProject.new({ "id": "x", "dev": 50 })
	feat2.apply_week([Talent.new({ "product": 10, "stamina": 100 }), Talent.new({ "management": 4, "stamina": 100 })], fcfg)
	_almost(feat2.dims.creativity, 12.0, 0.01, "feat_management_boost")

	# --- BeJek: Rilis cepat (§6.2) — Development wajib penuh, sisanya konsekuensi ---
	var fr := FeatureProject.new({ "id": "r", "dev": 50 })
	_ok(not fr.can_release(), "rush_blocked_when_dev_empty")
	fr.dims.development = 50.0
	_ok(fr.can_release(), "rush_ok_when_dev_full")
	fr.dims.security = 0.0
	_almost(fr.security_ratio(), 0.0, 0.001, "rush_security_ratio_empty")
	fr.dims.security = 25.0  # dev_req*0.5 = 25 → ratio penuh
	_almost(fr.security_ratio(), 1.0, 0.001, "rush_security_ratio_full")

	# --- BeJek: Boost (§6.4) — peluang dari coding, sukses naikkan Dev, gagal tambah bug ---
	var bcfg := { "base_success": 0.3, "success_per_coding": 0.05, "max_success": 0.9, "success_gain": 0.5, "fail_bugs": 0.6 }
	var fb := FeatureProject.new({ "id": "b", "dev": 50 })
	_almost(fb.boost_success_chance([Talent.new({ "coding": 8, "stamina": 100 })], bcfg), 0.7, 0.001, "boost_chance_from_coding")
	_almost(fb.boost_success_chance([Talent.new({ "coding": 20, "stamina": 100 })], bcfg), 0.9, 0.001, "boost_chance_capped")
	fb.dims.development = 10.0
	fb.resolve_boost(true, bcfg)
	_almost(fb.dims.development, 35.0, 0.001, "boost_success_raises_dev")
	var fb2 := FeatureProject.new({ "id": "b2", "dev": 50 })
	fb2.resolve_boost(false, bcfg)
	_almost(fb2.bugs, 30.0, 0.001, "boost_fail_adds_bugs")

	# --- BeJek: roadmap versi (§5) — manifest valid & tiap versi punya file fitur ---
	var vman: Array = DataLoader.load_json("bejek_versions.json").get("versions", [])
	_ok(vman.size() >= 1, "versions_manifest_loaded")
	_eq(float(vman[0].get("proposal_effort", -1.0)), 0.0, "version_v1_is_tutorial")
	for v in vman:
		var feats_v: Array = DataLoader.load_json(str(v.get("file", ""))).get("features", [])
		_ok(feats_v.size() > 0, "version_%s_has_features" % str(v.get("id", "?")))

	# --- BeJek: channel rekrut (§3.2) — manifest valid, ada opsi gratis ---
	var chans: Array = DataLoader.load_json("recruit_channels.json").get("channels", [])
	_ok(chans.size() >= 1, "channels_loaded")
	var free_found := false
	for ch in chans:
		var cnt: Array = ch.get("count", [])
		var lvl: Array = ch.get("level", [])
		_ok(cnt.size() == 2 and int(cnt[0]) <= int(cnt[1]), "channel_%s_count_valid" % str(ch.get("id", "?")))
		_ok(lvl.size() == 2 and int(lvl[0]) <= int(lvl[1]), "channel_%s_level_valid" % str(ch.get("id", "?")))
		if float(ch.get("cost", -1.0)) == 0.0:
			free_found = true
	_ok(free_found, "channels_have_free_option")

	print("[VERIFY] PASS=%d FAIL=%d" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
