extends SceneTree
## Smoke runner headless: jalankan loop GameState 24 bulan via GDScript asli.
## Bukan unit test GUT — ini bukti loop orchestrator hidup. Jalankan:
##   godot --headless --path . -s res://tests/smoke_run.gd

func _initialize() -> void:
	# Autoload global tak tersedia di mode -s; instansiasi langsung (tanpa scene tree).
	var gs: Node = load("res://scripts/game_state.gd").new()
	gs.start_new_game()
	var start_cash: float = gs.economy.cash
	var min_cash: float = start_cash
	var bankrupt_day := -1
	for d in range(1, 24 * 30 + 1):
		gs._advance_day()
		min_cash = min(min_cash, gs.economy.cash)
		if not gs.running:
			bankrupt_day = d
			break
	print("[SMOKE] start_cash=%.0fk min_cash=%.0fk end_cash=%.0fk MAU=%d GMV=%.0fk runway_now=%s bankrupt_day=%d talents=%d candidates=%d" % [
		start_cash, min_cash, gs.economy.cash, gs.mau, gs.gmv,
		str(gs.economy.runway_months()), bankrupt_day,
		gs.talents.size(), gs.candidates.size()])
	# Uji jalur funding: paksa MAU lewat threshold seed, lalu raise.
	gs.mau = 2000
	var before_owner: float = gs.funding.ownership
	var before_cash: float = gs.economy.cash
	var ok_raise: bool = gs.raise_funding()
	print("[SMOKE] raise_seed=%s cash_delta=%.0fk owner %.2f->%.2f next=%s" % [
		str(ok_raise), gs.economy.cash - before_cash, before_owner, gs.funding.ownership,
		str(gs.next_funding_round().get("id", "-"))])

	# Uji efek event: mau_pct (viral) & cash_delta (grant).
	gs.mau = 1000
	gs._apply_event({ "effect": { "mau_pct": 0.25 } })
	var cash_pre_grant: float = gs.economy.cash
	gs._apply_event({ "effect": { "cash_delta": 20000 } })
	print("[SMOKE] event viral: mau 1000->%d | grant: cash +%.0fk | demand event:" % [
		gs.mau, gs.economy.cash - cash_pre_grant])
	gs._apply_event({ "effect": { "demand_pct": 0.30, "duration_days": 2 } })
	print("[SMOKE]   demand_mult=%.2f days_left=%d" % [gs._demand_mult, gs._demand_days_left])

	# Uji R&D: tim lengkap + cash, build semua fitur.
	gs.economy.cash = 200000.0
	gs.talents.clear()
	gs.talents.append(Talent.new({ "type": "engineer", "skill": 6 }))
	gs.talents.append(Talent.new({ "type": "designer", "skill": 6 }))
	gs.talents.append(Talent.new({ "type": "marketing", "skill": 6 }))
	var built: Array = []
	for f in gs.features():
		if gs.build_feature(f):
			built.append(f.get("id"))
	var svc: Service = gs._active_service()
	print("[SMOKE] features built=%s acq_bonus=%d ride_take=%.2f ride_cap=%d quality=%.2f" % [
		str(built), gs._acquisition_bonus, svc.take_rate, svc.capacity, svc.quality])

	# Uji kompetitor & promo.
	print("[SMOKE] competitor %s mau=%d share=%.0f%%" % [
		gs.competitor.comp_name, gs.competitor.mau,
		Competitor.our_share(gs.mau, gs.competitor.mau) * 100.0])
	var burn_pre_promo: float = gs.economy.burn_rate_monthly
	var promo_ok: bool = gs.start_promo()
	print("[SMOKE] promo started=%s active=%s days=%d burn %.0fk->%.0fk" % [
		str(promo_ok), str(gs.is_promo_active()), gs.promo_days_left(),
		burn_pre_promo, gs.economy.burn_rate_monthly])

	# Uji kapasitas & upgrade kantor.
	gs.economy.cash = 100000.0
	var cap0: int = gs.office_capacity()
	while gs.talents.size() < cap0:
		gs.talents.append(Talent.new({ "type": "engineer", "skill": 3, "salary_monthly": 1000 }))
	var hire_full: bool = gs.hire(Talent.new({ "type": "engineer", "skill": 3 }))  # harus gagal (penuh)
	var up_ok: bool = gs.upgrade_office()
	print("[SMOKE] office cap0=%d hire_when_full=%s upgraded=%s newcap=%d level=%d" % [
		cap0, str(hire_full), str(up_ok), gs.office_capacity(), gs.office_level])

	# Uji multi-layanan: locked saat MAU rendah, launchable & nambah revenue saat cukup.
	gs.mau = 500
	var food: Service = gs.services["food_delivery"]
	var locked_ok: bool = not gs.can_launch_service(food)
	gs.mau = 6000
	gs.economy.cash = 100000.0
	gs._recompute_finances()
	var rev_before_food: float = gs.economy.revenue_monthly
	var food_ok: bool = gs.launch_service(food)
	print("[SMOKE] svc locked@500=%s launch_food@6000=%s active=%s rev %.0fk->%.0fk active_count=%d" % [
		str(locked_ok), str(food_ok), str(food.active),
		rev_before_food, gs.economy.revenue_monthly, gs._active_services().size()])

	# Uji ekspansi kota: home kebuka, buka Jakarta saat MAU & cash cukup.
	var jkt: Dictionary = {}
	for c in gs.cities_list():
		if c.get("id") == "jakarta":
			jkt = c
	var burn_pre_city: float = gs.economy.burn_rate_monthly
	gs.mau = 6000
	gs.economy.cash = 100000.0
	var city_ok: bool = gs.open_city(jkt)
	print("[SMOKE] cities home_open=%s open_jakarta=%s opened_count=%d burn %.0fk->%.0fk" % [
		str(gs.opened_cities.has("bandung")), str(city_ok), gs.opened_cities.size(),
		burn_pre_city, gs.economy.burn_rate_monthly])

	# Uji save/load round-trip (ownership + fitur re-apply + competitor + layanan + kota).
	var ok_save: bool = gs.save_game()
	var ok_load: bool = gs.load_game()
	var svc2: Service = gs._active_service()
	print("[SMOKE] save=%s load=%s after_load_cash=%.0fk owner=%.2f features=%d ride_cap=%d comp_mau=%d active_svc=%d cities=%d" % [
		str(ok_save), str(ok_load), gs.economy.cash, gs.funding.ownership,
		gs.unlocked_features.size(), svc2.capacity, gs.competitor.mau,
		gs._active_services().size(), gs.opened_cities.size()])
	gs.free()

	# === Skenario 2: MAIN AKTIF AGRESIF (tim marketing + fitur + promo + raise funding) ===
	var gp: Node = load("res://scripts/game_state.gd").new()
	gp.start_new_game()
	gp.talents.append(Talent.new({ "type": "designer", "skill": 6, "salary_monthly": 2000 }))
	for i in 8:  # tim marketing besar (menumpuk → mesin pertumbuhan untuk kalahkan kompetitor)
		gp.talents.append(Talent.new({ "type": "marketing", "skill": 6, "salary_monthly": 2000 }))
	gp._recompute_finances()
	for d in range(1, 60 * 30 + 1):
		if d % 30 == 1:
			for f in gp.features():
				if gp.can_build_feature(f):
					gp.build_feature(f)
			if not gp.is_promo_active() and gp.economy.cash > 20000:
				gp.start_promo()
			if gp.can_raise_funding():
				gp.raise_funding()
		gp._advance_day()
		if not gp.running:
			break
	print("[SMOKE2] agresif: end_cash=%.0fk MAU=%d comp=%d share=%.0f%% rounds=%d features=%d bankrupt=%s won=%s" % [
		gp.economy.cash, gp.mau, gp.competitor.mau,
		Competitor.our_share(gp.mau, gp.competitor.mau) * 100.0,
		gp.funding.raised_ids.size(), gp.unlocked_features.size(),
		str(not gp.running and not gp.won), str(gp.won)])
	gp.free()
	quit()
