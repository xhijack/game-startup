extends Node2D
## Tampilan interior KANTOR (gaya Game Dev Story). Menyusun gambar via OfficeRenderer
## (sprite pixel Kenney CC0) jadi ImageTexture, dengan animasi kerja + speech bubble.
## Tingkat tampilan = office_level (sistem upgrade kantor). Presentasi murni.

const BUBBLES := ["Mantap! 🎉", "Nice!", "Gas!", "Cuan!", "Keren!", "🚀"]

var _char_img: Image
var _tex: ImageTexture
var _frame := 0
var _anim := 0.0
var _bubble_text := ""
var _bubble_worker := 0
var _bubble_t := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_char_img = (load("res://assets/tiles/char_sheet.png") as Texture2D).get_image()
	GameState.state_changed.connect(_recompose)
	GameState.funding_raised.connect(func(_l): _say())
	GameState.office_upgraded.connect(func(_n): _say_text("Pindah kantor! 🏢"))
	GameState.game_won.connect(func(_l, _v, _o): _say_text("🚀 IPO!"))
	GameState.event_fired.connect(func(_l, type):
		if type != "negative":
			_say())
	_recompose()

func _recompose() -> void:
	var specs: Array = []
	for t in GameState.talents:
		specs.append({ "type": t.type })
	var img := OfficeRenderer.compose(specs, GameState.office_level, _char_img, _frame, GameState.office_capacity())
	_tex = ImageTexture.create_from_image(img)
	_fit_camera(img.get_width(), img.get_height())
	queue_redraw()

## Sesuaikan zoom & geser kamera agar kantor muat & terpusat di area kiri
## (panel tab ada di kanan ~350px).
func _fit_camera(w: int, h: int) -> void:
	var cam := get_node_or_null("../Camera2D")
	if cam == null:
		return
	var z := clampf(minf(560.0 / w, 520.0 / h), 0.7, 2.6)
	cam.zoom = Vector2(z, z)
	# Geser kantor ke kiri agar tidak ketiban panel kanan.
	cam.position = Vector2(175.0 / z, 6.0)

func _process(dt: float) -> void:
	var redraw := false
	if _bubble_t > 0.0:
		_bubble_t -= dt
		redraw = true
	# Animasi kerja hanya saat waktu berjalan.
	if GameState.speed > 0:
		_anim += dt
		if _anim >= 0.5:
			_anim = 0.0
			_frame = 1 - _frame
			_recompose()
	if redraw:
		queue_redraw()

func _say() -> void:
	_say_text(BUBBLES[randi() % BUBBLES.size()])

func _say_text(txt: String) -> void:
	var n := GameState.talents.size()
	if n <= 0:
		return
	_bubble_worker = randi() % n
	_bubble_text = txt
	_bubble_t = 2.6
	queue_redraw()

func _draw() -> void:
	if _tex == null:
		return
	var sz := _tex.get_size()
	draw_texture(_tex, -sz * 0.5)
	# Papan nama kantor + kapasitas.
	var cap := "%s (%d/%d)" % [GameState.office_name(), GameState.talents.size(), GameState.office_capacity()]
	draw_string(ThemeDB.fallback_font, Vector2(-sz.x * 0.5 + 4, -sz.y * 0.5 - 5),
		"🏢 %s" % cap, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.92))
	# Speech bubble di atas kepala pekerja.
	if _bubble_t > 0.0 and _bubble_worker < GameState.talents.size():
		var hp := OfficeRenderer.head_pos(_bubble_worker)
		_draw_bubble(Vector2(-sz.x * 0.5 + hp.x, -sz.y * 0.5 + hp.y), _bubble_text)

func _draw_bubble(pos: Vector2, txt: String) -> void:
	var font := ThemeDB.fallback_font
	var fs := 9
	var alpha: float = clampf(_bubble_t / 0.6, 0.0, 1.0)  # fade-out
	var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pad := 4.0
	var bw := tw + pad * 2
	var bh := fs + pad * 2
	var r := Rect2(pos.x - bw * 0.5, pos.y - bh - 5, bw, bh)
	draw_rect(r, Color(1, 1, 1, 0.96 * alpha))
	draw_rect(r, Color(0, 0, 0, 0.4 * alpha), false, 1.0)
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-3, -5), pos + Vector2(3, -5), pos + Vector2(0, 0)]),
		Color(1, 1, 1, 0.96 * alpha))
	draw_string(font, Vector2(r.position.x + pad, r.position.y + pad + fs - 2),
		txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.1, 0.1, alpha))
