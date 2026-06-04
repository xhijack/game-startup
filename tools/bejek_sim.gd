extends SceneTree
## Simulasi loop BeJek P0 (alur bertahap): tim develop fitur v1 lewat fase
## PRD→Dev→QA→Fix→Done, lalu rilis. Validasi pacing & dampak pemilihan employee.
##   godot --headless --path . -s res://tools/bejek_sim.gd

func _initialize() -> void:
	var fcfg: Dictionary = DataLoader.load_json("balance.json").get("feature_dev", {})
	var feats: Array = DataLoader.load_json("bejek_v1.json").get("features", [])

	# Tim seimbang: PM, 2 coder, designer, QA, manajer.
	var team := [
		Talent.new({ "person_name": "Putri", "product": 7, "stamina": 100 }),
		Talent.new({ "person_name": "Andi", "coding": 8, "stamina": 100 }),
		Talent.new({ "person_name": "Budi", "coding": 6, "stamina": 100 }),
		Talent.new({ "person_name": "Cinta", "ui_ux": 7, "stamina": 100 }),
		Talent.new({ "person_name": "Dodi", "qa": 7, "stamina": 100 }),
		Talent.new({ "person_name": "Eka", "management": 5, "stamina": 100 }),
	]
	print("[SIM] tim: PM + 2 coder + designer + QA + manajer")
	var total := 0
	for fd in feats:
		var feat := FeatureProject.new(fd)
		var w := 0
		var trace := ""
		var last := ""
		while not feat.is_done() and w < 100:
			feat.apply_week(team, fcfg)
			w += 1
			if feat.phase != last:
				trace += "%s(%d) " % [feat.phase_label(), w]
				last = feat.phase
		total += w
		print("[SIM] %-22s %2d mgg | skor %d%% | bug sisa %d | cre%d ux%d sec%d dev%d" % [
			feat.label, w, int(feat.score() * 100), int(feat.bugs_found),
			int(feat.dims.creativity), int(feat.dims.ui_ux), int(feat.dims.security), int(feat.dims.development)])
	print("[SIM] TOTAL v1 (6 fitur): %d minggu (~%.1f bulan)" % [total, total / 4.0])

	# Bandingkan: tim TANPA QA (skor lebih jelek karena bug menumpuk).
	var no_qa := [
		Talent.new({ "product": 7, "stamina": 100 }),
		Talent.new({ "coding": 8, "stamina": 100 }),
		Talent.new({ "coding": 6, "stamina": 100 }),
		Talent.new({ "ui_ux": 7, "stamina": 100 }),
	]
	var f := FeatureProject.new(feats[0])
	var ww := 0
	while not f.is_done() and ww < 100:
		f.apply_week(no_qa, fcfg); ww += 1
	print("[SIM] '%s' TANPA QA: %d mgg | skor %d%% | bug sisa %d (pemilihan employee = kunci!)" % [
		f.label, ww, int(f.score() * 100), int(f.bugs_found)])
	quit()
