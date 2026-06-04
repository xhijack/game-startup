extends Node2D
## Tool dev: render spritesheet diperbesar + grid + nomor kolom/baris untuk
## memetakan indeks tile. Jalankan: godot --path . res://tools/atlas_view.tscn
## Output: user://atlas.png. BUKAN bagian game.

const STRIDE := 17  # 16px tile + 1px spacing (format Kenney roguelike)
const SCALE := 2.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	await get_tree().create_timer(0.3).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://atlas.png")
	get_tree().quit()

func _draw() -> void:
	var which := OS.get_environment("SHEET")
	if which == "test":
		draw_rect(Rect2(20, 20, 80, 80), Color(0.8, 0.2, 0.2))  # kontrol: kotak merah
		# A) CompressedTexture2D hasil import.
		var tex: Texture2D = load("res://assets/tiles/office.png")
		draw_texture_rect(tex, Rect2(120, 20, tex.get_width() * 3, tex.get_height() * 3), false)
		# B) ImageTexture dari Image runtime (jalur yang terbukti di montage).
		var img := (load("res://assets/tiles/office.png") as Texture2D).get_image()
		var itex := ImageTexture.create_from_image(img)
		draw_texture_rect(itex, Rect2(400, 20, img.get_width() * 3, img.get_height() * 3), false)
		# C) ImageTexture dari char sheet.
		var cimg := (load("res://assets/tiles/char_sheet.png") as Texture2D).get_image()
		var citex := ImageTexture.create_from_image(cimg)
		draw_texture_rect(citex, Rect2(20, 240, cimg.get_width(), cimg.get_height()), false)
		return
	var path := "res://assets/tiles/char_sheet.png" if which == "char" else "res://assets/tiles/indoor_sheet.png"
	_draw_sheet(load(path), Vector2(28, 24))

func _draw_sheet(tex: Texture2D, origin: Vector2) -> void:
	draw_texture_rect(tex, Rect2(origin, tex.get_size() * SCALE), false)
	var cols := int(round((tex.get_width() + 1.0) / STRIDE))
	var rows := int(round((tex.get_height() + 1.0) / STRIDE))
	var font := ThemeDB.fallback_font
	for c in cols + 1:
		var x := origin.x + c * STRIDE * SCALE
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + rows * STRIDE * SCALE), Color(1, 0, 0, 0.35))
		if c < cols:
			draw_string(font, Vector2(x + 1, origin.y - 2), str(c), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 0))
	for r in rows + 1:
		var y := origin.y + r * STRIDE * SCALE
		draw_line(Vector2(origin.x, y), Vector2(origin.x + cols * STRIDE * SCALE, y), Color(1, 0, 0, 0.35))
		if r < rows:
			draw_string(font, Vector2(origin.x - 16, y + 12), str(r), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 0))
