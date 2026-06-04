extends Node2D
## Render kantor BeJek — reuse OfficeRenderer, baca tim dari BejekGame.

var _char_img: Image
var _tex: ImageTexture
var _game: Node
var _frame := 0
var _anim := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_char_img = (load("res://assets/tiles/char_sheet.png") as Texture2D).get_image()
	_game = get_tree().get_first_node_in_group("bejek_game")
	if _game:
		_game.changed.connect(_recompose)
	_recompose()

func _recompose() -> void:
	if _game == null:
		return
	var specs: Array = []
	for t in _game.talents:
		specs.append({ "type": _game.role_badge_type(t) })
	# Tingkat kantor tumbuh dari ukuran tim (Garasi→Menara) — visual P2.
	var tier: int = _game.office_tier()
	var cap: int = maxi(_game.office_capacity(), _game.talents.size())
	_tex = ImageTexture.create_from_image(OfficeRenderer.compose(specs, tier, _char_img, _frame, cap))
	_fit_camera()
	queue_redraw()

func _process(dt: float) -> void:
	if _game == null or _game.speed <= 0:
		return
	_anim += dt
	if _anim >= 0.5:
		_anim = 0.0
		_frame = 1 - _frame
		_recompose()

func _fit_camera() -> void:
	var cam := get_node_or_null("../Camera2D")
	if cam == null or _tex == null:
		return
	var sz := _tex.get_size()
	var z := clampf(minf(560.0 / sz.x, 520.0 / sz.y), 0.7, 2.6)
	cam.zoom = Vector2(z, z)
	cam.position = Vector2(175.0 / z, 6.0)

func _draw() -> void:
	if _tex == null:
		return
	var sz := _tex.get_size()
	draw_texture(_tex, -sz * 0.5)
	var top := -sz.y * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(-sz.x * 0.5 + 4, top - 18),
		"🏢 Kantor BeJek — %s (%d/%d)" % [_game.office_tier_name(), _game.talents.size(), _game.office_capacity()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.92))
	draw_string(ThemeDB.fallback_font, Vector2(-sz.x * 0.5 + 4, top - 5),
		_game.activity_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.92, 1.0, 0.92))
