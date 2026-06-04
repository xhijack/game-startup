extends Control
## UI mode BeJek. Baca BejekGame (grup "bejek_game"). Presentasi murni.

var _game: Node
var _hud: Label
var _secretary: Label
var _active_box: VBoxContainer
var _pool_box: VBoxContainer
var _team_box: VBoxContainer
var _cand_box: VBoxContainer
var _overlay: Control
var _overlay_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game = get_tree().get_first_node_in_group("bejek_game")
	_build_hud()
	_build_secretary()
	_build_panel()
	_build_overlay()
	if _game:
		_game.changed.connect(_refresh)
		_game.notify.connect(_on_notify)
		_game.game_over.connect(_on_game_over)
		_game.game_won.connect(_on_game_won)
	_refresh()

func _build_hud() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 44)
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	bar.add_child(hb)
	_hud = _lbl(hb, "")
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	_btn(hb, "❚❚", func(): _game.set_speed(0))
	_btn(hb, "▶", func(): _game.set_speed(1))
	_btn(hb, "▶▶", func(): _game.set_speed(2))
	_btn(hb, "▶▶▶", func(): _game.set_speed(3))
	_btn(hb, "🏠", func(): get_tree().change_scene_to_file("res://scenes/main/menu.tscn"))

func _build_secretary() -> void:
	var p := PanelContainer.new()
	p.position = Vector2(8, 52)
	p.custom_minimum_size = Vector2(440, 0)
	add_child(p)
	var hb := HBoxContainer.new()
	p.add_child(hb)
	_lbl(hb, "👩‍💼 Sekretaris:")
	_secretary = _lbl(hb, "...")
	_secretary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_secretary.custom_minimum_size = Vector2(360, 0)

func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -360
	panel.offset_right = -6
	panel.offset_top = 50
	panel.offset_bottom = -6
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	scroll.add_child(v)

	_lbl(v, "🛠 Fitur sedang dikembangkan:")
	_active_box = VBoxContainer.new()
	v.add_child(_active_box)
	v.add_child(HSeparator.new())
	_lbl(v, "📋 Backlog fitur (pilih untuk develop):")
	_pool_box = VBoxContainer.new()
	v.add_child(_pool_box)
	v.add_child(HSeparator.new())
	_lbl(v, "👥 Tim:")
	_team_box = VBoxContainer.new()
	v.add_child(_team_box)
	v.add_child(HSeparator.new())
	var jr := HBoxContainer.new()
	v.add_child(jr)
	_lbl(jr, "🧑‍💻 Job Board:")
	_btn(jr, "🔄", func(): _game.refresh_job_board())
	_cand_box = VBoxContainer.new()
	v.add_child(_cand_box)

func _refresh() -> void:
	if _game == null or _game.economy == null:
		return
	_hud.text = "📅 Mgg %d Th.%d   💰 %s   ⏳ %s   👥 %s user   🚀 %d fitur   📈 %s/mgg" % [
		_game.week, _game.year, _money(_game.economy.cash), _runway(_game.runway_weeks()),
		_grp(_game.users), _game.released.size(), _money(_game.weekly_revenue() - _game.weekly_burn())]
	_refresh_active()
	_refresh_pool()
	_refresh_team()
	_refresh_cand()

func _refresh_active() -> void:
	for c in _active_box.get_children():
		c.queue_free()
	# Mode proposal versi (§5): PM mengakumulasi visi sebelum fitur baru terbuka.
	if _game.proposing:
		_lbl(_active_box, "📝 Proposal: %s" % _game.next_version_label())
		var pl := _lbl(_active_box, "   Progres visi: %d%%" % int(_game.proposal_pct() * 100))
		pl.add_theme_color_override("font_color", Color(0.5, 0.85, 1))
		var ph := _lbl(_active_box, "   → butuh: Product (PM) merumuskan roadmap")
		ph.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
		_assign_roster()
		return
	var a = _game.active
	if a == null:
		if _game.can_propose():
			_lbl(_active_box, "(backlog %s habis — buat proposal versi berikutnya ↓)" % _game.current_version_label())
		else:
			_lbl(_active_box, "(belum ada — pilih dari backlog)")
		return
	_lbl(_active_box, "%s — fase: %s" % [a.label, a.phase_label()])
	if not a.is_done():
		var hint := _lbl(_active_box, "   → butuh: %s" % _game.phase_need())
		hint.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
		# Mode fokus (cepat ↔ matang).
		var mrow := HBoxContainer.new()
		_active_box.add_child(mrow)
		_lbl(mrow, "Mode:")
		for m in [["normal", "Normal"], ["kebut", "Kebut"], ["matang", "Matang"], ["riset", "Riset"]]:
			var mm: String = m[0]
			var b := _btn(mrow, ("●" if a.focus_mode == mm else "") + m[1], func(): _game.set_focus_mode(mm))
			if a.focus_mode == mm:
				b.add_theme_color_override("font_color", Color(0.4, 1, 0.5))
	for dim in [["creativity", "Creativity"], ["ui_ux", "UI/UX"], ["security", "Security"], ["development", "Development"]]:
		_lbl(_active_box, "   %s: %d" % [dim[1], int(a.dims[dim[0]])])
	if a.bugs_found > 0.5:
		_lbl(_active_box, "   🐞 Bug ditemukan: %d" % int(a.bugs_found))
	# Boost (§6.4): tawaran judi opt-in di tengah Development.
	if _game.boost_pending:
		var bl := _lbl(_active_box, "💡 Terobosan ditawarkan! Sukses %d%% → lonjakan Dev · gagal → bug." % int(_game.boost_chance() * 100))
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		var brow := HBoxContainer.new()
		_active_box.add_child(brow)
		var ab := _btn(brow, "✅ Ambil", func(): _game.accept_boost())
		ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var db := _btn(brow, "❌ Tolak", func(): _game.decline_boost())
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if a.is_done():
		var b := _btn(_active_box, "🚀 RILIS (skor %d%%)" % int(a.score() * 100), func(): _game.release())
		b.add_theme_color_override("font_color", Color(0.4, 1, 0.5))
	else:
		# Rilis cepat (§6.2): aktif begitu Development penuh, walau belum matang.
		if a.can_release():
			var rb := _btn(_active_box, "⚡ Rilis Cepat (skor %d%% — berisiko)" % int(a.score() * 100), func(): _game.release())
			rb.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
		# Roster: tugaskan / tarik employee dari fitur ini (tombol full-width).
		_assign_roster()

## Roster tugaskan/tarik tim — dipakai fase develop fitur & proposal versi.
func _assign_roster() -> void:
	_lbl(_active_box, "Tugaskan tim:")
	for t in _game.talents:
		var on: bool = _game.is_assigned(t)
		var tired := " 😴" if t.stamina <= 30 else ""
		var ct: Talent = t
		_btn(_active_box, "%s %s ⚡%d%%%s — %s" % [
			"✅" if on else "⬜", t.person_name, int(t.stamina), tired,
			"Tarik" if on else "Tugaskan"], func(): _game.toggle_assign(ct))

func _refresh_pool() -> void:
	for c in _pool_box.get_children():
		c.queue_free()
	_lbl(_pool_box, "Versi aktif: %s" % _game.current_version_label())
	if _game.proposing:
		_lbl(_pool_box, "(proposal versi berikutnya sedang digarap…)")
		return
	if _game.active != null:
		_lbl(_pool_box, "(selesaikan fitur aktif dulu)")
		return
	for fd in _game.pool:
		var cf: Dictionary = fd
		_btn(_pool_box, "▶ Develop: %s (%d)" % [str(fd.get("label", "")), int(fd.get("dev", 50))],
			func(): _game.develop(cf))
	# Proposal versi lanjutan (§5) — muncul saat backlog versi ini habis.
	if _game.can_propose():
		var nb := _btn(_pool_box, "📝 Buat Proposal: %s" % _game.next_version_label(), func(): _game.start_proposal())
		nb.add_theme_color_override("font_color", Color(0.5, 0.85, 1))

func _refresh_team() -> void:
	for c in _team_box.get_children():
		c.queue_free()
	for t in _game.talents:
		var tired := " 😴" if t.stamina <= 30 else ""
		_lbl(_team_box, "• %s · %s · ⚡%d%%%s · %s/bln" % [
			t.person_name, _skills(t), int(t.stamina), tired, _money(t.salary_monthly)])

func _refresh_cand() -> void:
	for c in _cand_box.get_children():
		c.queue_free()
	for cand in _game.candidates:
		_lbl(_cand_box, "%s · %s · %s · %s/bln" % [cand.person_name, cand.type, _skills(cand), _money(cand.salary_monthly)])
		var c2: Talent = cand
		_btn(_cand_box, "✚ Hire %s" % cand.person_name, func(): _game.hire(c2))

## Skill non-nol ringkas, mis. "Prod 7 · Code 3".
func _skills(t: Talent) -> String:
	var parts: Array = []
	for pair in [["product", "Prod"], ["coding", "Code"], ["ui_ux", "UI"], ["qa", "QA"], ["management", "Mgmt"]]:
		var v: int = t.get(pair[0])
		if v > 0:
			parts.append("%s %d" % [pair[1], v])
	return " · ".join(parts) if not parts.is_empty() else "—"

func _on_notify(msg: String) -> void:
	if _secretary:
		_secretary.text = msg
	Audio.play("confirm")

func _on_game_over(reason: String) -> void:
	_overlay_label.text = "💀 GAME OVER\n%s" % reason
	_overlay.visible = true
	Audio.play("error")

func _on_game_won(u: int) -> void:
	_overlay_label.text = "🎉 %s SUKSES!\nSemua versi dirilis · %s user · %s" % [
		_game.current_version_label(), _grp(u), _money(_game.economy.cash)]
	_overlay.visible = true
	Audio.jingle("jingle_win")

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(cc)
	var pan := PanelContainer.new()
	cc.add_child(pan)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	pan.add_child(vb)
	_overlay_label = Label.new()
	_overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overlay_label.add_theme_font_size_override("font_size", 24)
	vb.add_child(_overlay_label)
	_btn(vb, "🔄 Main Lagi", func(): _overlay.visible = false; _game.start_new())
	_btn(vb, "🏠 Menu", func(): get_tree().change_scene_to_file("res://scenes/main/menu.tscn"))

# helpers
func _lbl(parent: Node, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l

func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(func(): Audio.play("click"))
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _money(v: float) -> String:
	var rp := absf(v) * 1000.0
	var s := ""
	if rp >= 1e12: s = _num(rp / 1e12) + " T"
	elif rp >= 1e9: s = _num(rp / 1e9) + " M"
	elif rp >= 1e6: s = _num(rp / 1e6) + " jt"
	elif rp >= 1e3: s = "%d rb" % int(round(rp / 1e3))
	else: s = "%d" % int(round(rp))
	return ("-Rp " if v < 0 else "Rp ") + s

func _num(x: float) -> String:
	var r := snappedf(x, 0.1)
	return "%d" % int(r) if is_equal_approx(r, floor(r)) else ("%.1f" % r).replace(".", ",")

func _runway(w: float) -> String:
	return "Profit ✅" if w == INF else "Runway %d mgg" % int(w)

func _grp(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	return out
