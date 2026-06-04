extends Control
## HUD + panel bertab (rapi, tak tumpuk). MEMBACA GameState, update via sinyal.
## Presentasi murni: tidak menyimpan/menghitung balancing.

# HUD
var _date_label: Label
var _cash_label: Label
var _runway_label: Label
var _mau_label: Label
var _gmv_label: Label
# Tab Tim
var _talent_list: VBoxContainer
var _overtime_btn: Button
var _candidate_list: VBoxContainer
# Tab Bisnis
var _service_list: VBoxContainer
var _research_list: VBoxContainer
# Tab Modal
var _val_label: Label
var _own_label: Label
var _round_label: Label
var _raise_btn: Button
var _office_label: Label
var _office_up_btn: Button
# Tab Pasar
var _comp_label: Label
var _promo_btn: Button
var _cities_list: VBoxContainer
# Tab Event
var _event_log_list: VBoxContainer
# Overlays
var _overlay: Control
var _overlay_label: Label
var _intro: Control
var _pause: Control
var _music_on := true

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_build_tabs()
	_build_overlay()
	_build_intro()
	_build_pause()

	GameState.state_changed.connect(_refresh)
	GameState.game_over.connect(_on_game_over)
	GameState.game_won.connect(_on_game_won)
	GameState.event_fired.connect(_on_event_fired)
	GameState.office_upgraded.connect(func(_n): Audio.play("confirm"))
	GameState.hire_blocked.connect(func(): Audio.play("error"))
	if GameState.economy == null:
		GameState.start_new_game()
	_refresh()
	if GameState.is_new_game and OS.get_environment("NOINTRO") != "1":
		_intro.visible = true

# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 44)
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	bar.add_child(hb)
	_date_label = _add_label(hb, "")
	_cash_label = _add_label(hb, "")
	_runway_label = _add_label(hb, "")
	_mau_label = _add_label(hb, "")
	_gmv_label = _add_label(hb, "")
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(spacer)
	_add_button(hb, "❚❚", func(): GameState.set_speed(0))
	_add_button(hb, "▶", func(): GameState.set_speed(1))
	_add_button(hb, "▶▶", func(): GameState.set_speed(2))
	_add_button(hb, "▶▶▶", func(): GameState.set_speed(3))
	_add_button(hb, "🎵", func(): _toggle_music())
	_add_button(hb, "☰", func(): _show_pause())

# ---------------------------------------------------------------- Tabs

func _build_tabs() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -344
	panel.offset_right = -6
	panel.offset_top = 50
	panel.offset_bottom = -6
	add_child(panel)
	var tabs := TabContainer.new()
	tabs.add_theme_constant_override("icon_max_width", 0)
	panel.add_child(tabs)

	_build_tab_team(_make_tab(tabs, "Tim"))
	_build_tab_business(_make_tab(tabs, "Bisnis"))
	_build_tab_capital(_make_tab(tabs, "Modal"))
	_build_tab_market(_make_tab(tabs, "Pasar"))
	_build_tab_events(_make_tab(tabs, "Event"))

func _make_tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	scroll.add_child(v)
	tabs.add_child(scroll)
	return v

func _build_tab_team(v: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	v.add_child(row)
	_add_label(row, "Tim:")
	_overtime_btn = _add_button(row, "Lembur: OFF", func(): GameState.toggle_overtime())
	_talent_list = VBoxContainer.new()
	v.add_child(_talent_list)
	v.add_child(HSeparator.new())
	_add_label(v, "Job Board (rekrut):")
	_candidate_list = VBoxContainer.new()
	v.add_child(_candidate_list)

func _build_tab_business(v: VBoxContainer) -> void:
	_add_label(v, "🏢 Layanan (super-app):")
	_service_list = VBoxContainer.new()
	v.add_child(_service_list)
	v.add_child(HSeparator.new())
	_add_label(v, "🔬 R&D / Fitur (kombinasi talent):")
	_research_list = VBoxContainer.new()
	_research_list.add_theme_constant_override("separation", 8)
	v.add_child(_research_list)

func _build_tab_capital(v: VBoxContainer) -> void:
	_add_label(v, "🏢 Kantor:")
	_office_label = _add_label(v, "")
	_office_up_btn = _add_button(v, "Upgrade", func(): GameState.upgrade_office())
	v.add_child(HSeparator.new())
	_add_label(v, "💼 Funding:")
	_val_label = _add_label(v, "")
	_own_label = _add_label(v, "")
	_round_label = _add_label(v, "")
	_round_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_raise_btn = _add_button(v, "Raise", func(): GameState.raise_funding())

func _build_tab_market(v: VBoxContainer) -> void:
	_add_label(v, "🆚 Kompetitor:")
	_comp_label = _add_label(v, "")
	_comp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_promo_btn = _add_button(v, "🔥 Promo", func(): GameState.start_promo())
	v.add_child(HSeparator.new())
	_add_label(v, "🗺️ Ekspansi Kota:")
	_cities_list = VBoxContainer.new()
	v.add_child(_cities_list)

func _build_tab_events(v: VBoxContainer) -> void:
	_add_label(v, "📰 Event Log:")
	_event_log_list = VBoxContainer.new()
	v.add_child(_event_log_list)

# ---------------------------------------------------------------- Refresh

func _refresh() -> void:
	if GameState.economy == null:
		return
	_date_label.text = "📅 %s" % _fmt_date(GameState.date)
	_cash_label.text = "💰 %s" % _fmt_money(GameState.economy.cash)
	_runway_label.text = "⏳ %s" % _fmt_runway(GameState.economy.runway_months())
	_mau_label.text = "👥 MAU %s" % _group(GameState.mau)
	_gmv_label.text = "📈 GMV %s" % _fmt_money(GameState.gmv)
	_refresh_team()
	_refresh_business()
	_refresh_capital()
	_refresh_market()
	_refresh_event_log()

func _refresh_team() -> void:
	_overtime_btn.text = "Lembur: %s" % ("ON 🔥" if GameState.overtime else "OFF")
	for c in _talent_list.get_children():
		c.queue_free()
	for t in GameState.talents:
		var tired := " ⚠burnout" if t.burnout else ""
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		_talent_list.add_child(box)
		_add_label(box, "• %s · %s L%d" % [t.person_name, t.type, t.level])
		var row := HBoxContainer.new()
		box.add_child(row)
		_add_label(row, "   Sk%d · ⚡%d%%%s" % [t.skill, int(t.stamina), tired])
		var ct: Talent = t
		var tb := _add_button(row, "⬆ Latih %s" % _fmt_money(GameState.train_cost(t)),
			func(): GameState.train_talent(ct))
		tb.disabled = not GameState.can_train_talent(t)
	var full := GameState.talents.size() >= GameState.office_capacity()
	for c in _candidate_list.get_children():
		c.queue_free()
	for cand in GameState.candidates:
		var row := HBoxContainer.new()
		_candidate_list.add_child(row)
		_add_label(row, "%s · %s · Sk%d · %s" % [
			cand.person_name, cand.type, cand.skill, _fmt_money(cand.salary_monthly)])
		var captured := cand
		var btn := _add_button(row, "Hire", func(): GameState.hire(captured))
		btn.disabled = full
	if full:
		_add_label(_candidate_list, "⚠ Kantor penuh — upgrade di tab Modal.")

func _refresh_business() -> void:
	for c in _service_list.get_children():
		c.queue_free()
	for svc in GameState.services_list():
		if svc.active:
			_add_label(_service_list, "✅ %s · kap %s · Q%d%%" % [
				svc.label_id, _group(svc.capacity), int(svc.quality * 100)])
		elif GameState.mau >= svc.unlock_mau:
			var row := HBoxContainer.new()
			_service_list.add_child(row)
			_add_label(row, "%s (R&D %s)" % [svc.label_id, _fmt_money(svc.rnd_cost)])
			var cs: Service = svc
			var b := _add_button(row, "Launch", func(): GameState.launch_service(cs))
			b.disabled = not GameState.can_launch_service(svc)
		else:
			_add_label(_service_list, "🔒 %s · buka di MAU %s" % [svc.label_id, _group(svc.unlock_mau)])
	_add_label(_service_list, "Burn %s/bln · Rev %s/bln" % [
		_fmt_money(GameState.economy.burn_rate_monthly), _fmt_money(GameState.economy.revenue_monthly)])
	# R&D
	for c in _research_list.get_children():
		c.queue_free()
	for f in GameState.features():
		var fid := str(f.get("id", ""))
		var unlocked: bool = GameState.unlocked_features.has(fid)
		var box := VBoxContainer.new()
		_research_list.add_child(box)
		_add_label(box, "%s %s" % ["✅" if unlocked else "•", str(f.get("label", ""))])
		var req: Dictionary = f.get("requires", {})
		_add_label(box, "   %s · tim≥%d · %s" % [
			" + ".join(req.get("types", [])), int(req.get("min_team_skill", 0)),
			_fmt_money(float(f.get("cost", 0.0)))])
		if not unlocked:
			var cf: Dictionary = f
			var b := _add_button(box, "Build", func(): GameState.build_feature(cf))
			b.disabled = not GameState.can_build_feature(f)

func _refresh_capital() -> void:
	# Kantor
	var used := GameState.talents.size()
	var cap := GameState.office_capacity()
	_office_label.text = "%s — meja %d/%d%s" % [
		GameState.office_name(), used, cap, "  ⚠ PENUH" if used >= cap else ""]
	var nxt := GameState.next_office()
	if nxt.is_empty():
		_office_up_btn.visible = false
	else:
		_office_up_btn.visible = true
		_office_up_btn.text = "⬆ %s · kap %d · %s" % [
			str(nxt.get("name", "")), int(nxt.get("capacity", 0)), _fmt_money(float(nxt.get("upgrade_cost", 0.0)))]
		_office_up_btn.disabled = not GameState.can_upgrade_office()
	# Funding
	_val_label.text = "Valuasi %s" % _fmt_money(GameState.valuation())
	_own_label.text = "Kepemilikan %.1f%%" % (GameState.funding.ownership * 100.0)
	var r := GameState.next_funding_round()
	if r.is_empty():
		_round_label.text = "Semua round selesai 🎉"
		_raise_btn.disabled = true
		_raise_btn.text = "—"
		return
	var req := "MAU %s" % _group(int(r.get("require_mau", 0)))
	if float(r.get("require_valuation", 0.0)) > 0.0:
		req += " · Valuasi %s" % _fmt_money(float(r.get("require_valuation", 0.0)))
	var is_ipo: bool = bool(r.get("is_ipo", false))
	var reward := "IPO 🚀" if is_ipo else "+%s · dilusi %d%%" % [
		_fmt_money(float(r.get("amount", 0.0))), int(float(r.get("dilution", 0.0)) * 100.0)]
	_round_label.text = "Berikut: %s\nSyarat: %s\n%s" % [str(r.get("label", "")), req, reward]
	var eligible := GameState.can_raise_funding()
	_raise_btn.disabled = not eligible
	_raise_btn.text = ("Go IPO!" if is_ipo else "Raise %s" % str(r.get("label", ""))) if eligible else "Belum memenuhi syarat"

func _refresh_market() -> void:
	var comp := GameState.competitor
	var share := Competitor.our_share(GameState.mau, comp.mau) * 100.0
	_comp_label.text = "%s — MAU %s · Pangsa kita %.0f%%" % [comp.comp_name, _group(comp.mau), share]
	if GameState.is_promo_active():
		_promo_btn.disabled = true
		_promo_btn.text = "🔥 Promo aktif (%d hari)" % GameState.promo_days_left()
	else:
		_promo_btn.disabled = false
		_promo_btn.text = "🔥 Promo (bakar %s/hari)" % _fmt_money(GameState.promo_daily_cost())
	for c in _cities_list.get_children():
		c.queue_free()
	for city in GameState.cities_list():
		var cid := str(city.get("id", ""))
		var opened: bool = GameState.opened_cities.has(cid)
		var label := str(city.get("label", ""))
		var acq := int(city.get("acquisition_bonus", 0))
		if opened:
			var tag := " (home)" if bool(city.get("home", false)) else ""
			_add_label(_cities_list, "✅ %s%s · +%d/hari" % [label, tag, acq])
		elif GameState.mau >= int(city.get("unlock_mau", 0)):
			var row := HBoxContainer.new()
			_cities_list.add_child(row)
			_add_label(row, "%s · +%d/hr · %s" % [label, acq, _fmt_money(float(city.get("open_cost", 0.0)))])
			var cc: Dictionary = city
			var b := _add_button(row, "Buka", func(): GameState.open_city(cc))
			b.disabled = not GameState.can_open_city(city)
		else:
			_add_label(_cities_list, "🔒 %s · MAU %s" % [label, _group(int(city.get("unlock_mau", 0)))])

func _refresh_event_log() -> void:
	for c in _event_log_list.get_children():
		c.queue_free()
	var log: Array = GameState.event_log
	if log.is_empty():
		_add_label(_event_log_list, "(belum ada kejadian)")
		return
	for i in range(log.size() - 1, -1, -1):
		_add_label(_event_log_list, "• %s" % str(log[i]))

# ---------------------------------------------------------------- Overlays

func _build_overlay() -> void:
	var m := _make_modal(26)
	_overlay = m.root
	_overlay_label = m.label
	_add_button(m.row, "🔄 Main Lagi", func(): _restart())
	_add_button(m.row, "🏠 Menu", func(): get_tree().change_scene_to_file("res://scenes/main/menu.tscn"))

func _build_intro() -> void:
	var m := _make_modal(15)
	_intro = m.root
	m.label.text = "Selamat datang di STARTUP STORY! 🚀\n\n" + \
		"Tujuan: bawa startup-mu dari garasi sampai IPO.\n\n" + \
		"• Klik ▶ untuk menjalankan waktu\n" + \
		"• Tab Tim → Hire talent (kantor terisi)\n" + \
		"• Tab Bisnis → buka layanan & fitur R&D\n" + \
		"• Tab Modal → raih funding & upgrade kantor\n" + \
		"• Tab Pasar → promo & ekspansi kota\n" + \
		"• Jaga runway jangan habis & kalahkan kompetitor!\n\n" + \
		"💡 Lembur bikin tim cepat naik level, tapi awas burnout."
	_add_button(m.row, "Mulai! ▶", func(): _intro.visible = false)

func _build_pause() -> void:
	var m := _make_modal(22)
	_pause = m.root
	m.label.text = "⏸  Jeda"
	_add_button(m.row, "Lanjut", func(): _pause.visible = false)
	_add_button(m.row, "💾 Simpan", func(): GameState.save_game())
	_add_button(m.row, "🏠 Menu", func(): get_tree().change_scene_to_file("res://scenes/main/menu.tscn"))

func _make_modal(msg_size: int) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var panel := PanelContainer.new()
	cc.add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", msg_size)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(440, 0)
	v.add_child(lbl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	return { "root": root, "label": lbl, "row": row }

func _show_pause() -> void:
	GameState.set_speed(0)
	_pause.visible = true

func _restart() -> void:
	_overlay.visible = false
	GameState.start_new_game()
	_refresh()
	_intro.visible = true

func _on_game_over(reason: String) -> void:
	_overlay_label.text = "💀 GAME OVER\n%s" % reason
	_overlay.visible = true
	Audio.play("error")

func _on_game_won(label: String, valuation: float, ownership: float) -> void:
	_overlay_label.text = "🚀 %s SUKSES!\nValuasi %s · Kamu pegang %.1f%%" % [
		label, _fmt_money(valuation), ownership * 100.0]
	_overlay.visible = true
	Audio.jingle("jingle_win")

func _on_event_fired(_label: String, type: String) -> void:
	_refresh_event_log()
	Audio.play("error" if type == "negative" else "confirm")

func _toggle_music() -> void:
	_music_on = not _music_on
	Audio.set_music_enabled(_music_on)

# ---------------------------------------------------------------- Helpers

func _add_label(parent: Node, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l

func _add_button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func(): Audio.play("click"))
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

## Nilai internal `v` dalam satuan ribuan Rupiah → tampil rapi: rb / jt / M / T.
func _fmt_money(v: float) -> String:
	var rp := absf(v) * 1000.0
	var s := ""
	if rp >= 1e12:
		s = _num(rp / 1e12) + " T"
	elif rp >= 1e9:
		s = _num(rp / 1e9) + " M"
	elif rp >= 1e6:
		s = _num(rp / 1e6) + " jt"
	elif rp >= 1e3:
		s = "%d rb" % int(round(rp / 1e3))
	else:
		s = "%d" % int(round(rp))
	return ("-Rp " if v < 0 else "Rp ") + s

## Angka 1 desimal, buang ",0", pakai koma desimal (gaya Indonesia).
func _num(x: float) -> String:
	var r := snappedf(x, 0.1)
	if is_equal_approx(r, floor(r)):
		return "%d" % int(r)
	return ("%.1f" % r).replace(".", ",")

func _fmt_runway(m: float) -> String:
	if m == INF:
		return "Profit ✅"
	return "Runway %.1f bln" % m

func _fmt_date(d: Dictionary) -> String:
	return "%02d/%02d/%d" % [int(d.day), int(d.month), int(d.year)]

func _group(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if n < 0 else "") + out
