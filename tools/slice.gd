extends SceneTree
## Tool dev: susun montage tile (scaled, bergaris) dari spritesheet via Image ops
## (tanpa rendering, jalan headless). Untuk memetakan indeks tile.
##   SHEET=indoor godot --headless --path . -s res://tools/slice.gd
## Output: user://montage_<sheet>.png

const STRIDE := 17
const TILE := 16
const S := 4      # skala
const GAP := 4

func _initialize() -> void:
	var which := OS.get_environment("SHEET")
	var path := "res://assets/tiles/char_sheet.png" if which == "char" else "res://assets/tiles/indoor_sheet.png"
	var src := (load(path) as Texture2D).get_image()
	var cols := int(round((src.get_width() + 1.0) / STRIDE))
	var rows := int(round((src.get_height() + 1.0) / STRIDE))
	# Batasi kolom char (cukup kiri) agar montage tak kelebaran.
	if which == "char":
		cols = min(cols, 16)

	var cell := TILE * S + GAP
	var dst := Image.create(cols * cell + GAP, rows * cell + GAP, false, Image.FORMAT_RGBA8)
	dst.fill(Color(0.16, 0.17, 0.20))
	# Garis pemisah tiap 5 kolom/baris (warna terang) supaya gampang hitung.
	for r in rows:
		for c in cols:
			var region := src.get_region(Rect2i(c * STRIDE, r * STRIDE, TILE, TILE))
			region.resize(TILE * S, TILE * S, Image.INTERPOLATE_NEAREST)
			var dx := GAP + c * cell
			var dy := GAP + r * cell
			# tandai sel kelipatan 5 dengan border tipis biru.
			if c % 5 == 0 or r % 5 == 0:
				dst.fill_rect(Rect2i(dx - 1, dy - 1, TILE * S + 2, TILE * S + 2), Color(0.30, 0.45, 0.75))
			dst.blit_rect(region, Rect2i(0, 0, TILE * S, TILE * S), Vector2i(dx, dy))
	dst.save_png("user://montage_%s.png" % ("char" if which == "char" else "indoor"))
	print("[SLICE] %s cols=%d rows=%d -> montage saved" % [which, cols, rows])
	quit()
