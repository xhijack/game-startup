extends Control
## Main menu: Main Baru / Lanjutkan (bila ada save) / Keluar.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.12, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	center.add_child(v)

	_title(v, "STARTUP STORY", 40, Color(1, 0.85, 0.3))
	_title(v, "Bangun startup dari garasi sampai IPO", 16, Color(0.8, 0.82, 0.86))
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 24)
	v.add_child(sp)

	_menu_button(v, "🚀  Main BeJek (baru)", func(): _bejek())
	_menu_button(v, "▶  Mode Tycoon (lama)", func(): _new_game())
	if SaveManager.has_save():
		_menu_button(v, "📂  Lanjutkan Tycoon", func(): _continue())
	_menu_button(v, "✕  Keluar", func(): get_tree().quit())

	_title(v, "Aset CC0 Kenney & OpenGameArt · prototipe", 11, Color(0.5, 0.52, 0.56))

func _bejek() -> void:
	Audio.play("click")
	get_tree().change_scene_to_file("res://scenes/bejek/bejek.tscn")

func _new_game() -> void:
	Audio.play("click")
	GameState.start_new_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _continue() -> void:
	Audio.play("click")
	GameState.load_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _title(parent: Node, text: String, size: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)

func _menu_button(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(280, 46)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(cb)
	parent.add_child(b)
