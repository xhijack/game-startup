class_name OfficeRenderer
extends RefCounted
## Menyusun gambar interior kantor sebagai SATU Image (CPU blit), gaya Game Dev Story.
## Lantai/dinding/meja digambar prosedural; pekerja = sprite pixel Kenney (CC0).
## Murni Image ops → bisa di-preview headless & ditampilkan sebagai ImageTexture.

const STRIDE := 17   # char sheet: 16px tile + 1px spacing
const TILE := 16

# Kolam karakter villager Kenney (kolom,baris) yang sudah ber-wajah/rambut.
const CHAR_POOL := [
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(0, 6), Vector2i(1, 6),
	Vector2i(0, 7), Vector2i(1, 7), Vector2i(0, 8), Vector2i(1, 8),
	Vector2i(0, 9), Vector2i(1, 9), Vector2i(0, 10), Vector2i(1, 10),
	Vector2i(0, 11), Vector2i(1, 11),
]
const BADGE := {
	"engineer": Color(0.27, 0.53, 0.95),
	"designer": Color(0.85, 0.42, 0.80),
	"marketing": Color(0.96, 0.62, 0.22),
	# Peran BeJek (P2): badge berbeda per skill dominan.
	"product": Color(0.55, 0.45, 0.95),
	"coding": Color(0.27, 0.60, 0.95),
	"ui_ux": Color(0.92, 0.40, 0.72),
	"qa": Color(0.96, 0.62, 0.22),
	"management": Color(0.40, 0.80, 0.45),
}

# Palet tingkat kantor (garasi→menara).
const TIER_FLOOR := [Color(0.50, 0.43, 0.34), Color(0.58, 0.45, 0.32), Color(0.62, 0.58, 0.52), Color(0.46, 0.52, 0.60)]
const TIER_WALL := [Color(0.42, 0.38, 0.34), Color(0.80, 0.74, 0.62), Color(0.86, 0.88, 0.92), Color(0.58, 0.68, 0.82)]
const TIER_NAME := ["Garasi", "Ruko", "Kantor", "Menara"]

const PER_ROW := 4
const SPACING_X := 54
const SPACING_Y := 44
const MARGIN_X := 16
const MARGIN_Y := 14
const WALL_H := 26

## Posisi kepala pekerja ke-i (ruang gambar) — untuk menempel speech bubble.
static func head_pos(i: int) -> Vector2i:
	var dc: int = i % PER_ROW
	var dr: int = i / PER_ROW
	var cx: int = MARGIN_X + dc * SPACING_X + SPACING_X / 2
	var cy: int = WALL_H + MARGIN_Y + dr * SPACING_Y + 10
	return Vector2i(cx, cy - 24)

## worker_specs: Array of {type}. tier 0..3. capacity = jumlah meja (ukuran ruangan,
## ikut upgrade kantor). frame 0/1 animasi.
static func compose(worker_specs: Array, tier: int, char_img: Image, frame: int = 0, capacity: int = 12) -> Image:
	var n: int = worker_specs.size()
	# Jumlah meja = kapasitas kantor → ruangan membesar saat upgrade.
	var slots: int = maxi(n, maxi(1, capacity))
	var rows: int = int(ceil(slots / float(PER_ROW)))
	var w: int = MARGIN_X * 2 + PER_ROW * SPACING_X
	var h: int = WALL_H + MARGIN_Y + rows * SPACING_Y + 30
	var floor_col: Color = TIER_FLOOR[clampi(tier, 0, 3)]
	var wall_col: Color = TIER_WALL[clampi(tier, 0, 3)]

	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# Lantai (kayu) + garis papan.
	img.fill_rect(Rect2i(0, WALL_H, w, h - WALL_H), floor_col)
	for px in range(0, w, 18):
		img.fill_rect(Rect2i(px, WALL_H, 1, h - WALL_H), floor_col.darkened(0.12))
	for py in range(WALL_H, h, 18):
		img.fill_rect(Rect2i(0, py, w, 1), floor_col.darkened(0.06))
	# Dinding belakang + lis.
	img.fill_rect(Rect2i(0, 0, w, WALL_H), wall_col)
	img.fill_rect(Rect2i(0, WALL_H - 3, w, 3), wall_col.darkened(0.25))
	# Jendela.
	for wx in [int(w * 0.22), int(w * 0.5), int(w * 0.78)]:
		img.fill_rect(Rect2i(wx - 11, 6, 22, 13), Color(0.62, 0.86, 0.96))
		img.fill_rect(Rect2i(wx - 11, 6, 22, 13).grow(0), Color(0, 0, 0, 0))
		_border(img, Rect2i(wx - 11, 6, 22, 13), wall_col.darkened(0.35))
		img.fill_rect(Rect2i(wx - 1, 6, 2, 13), wall_col.darkened(0.3))

	_draw_decor(img, w, h)

	# Meja di setiap slot (kosong/terisi) + pekerja bila ada.
	for i in slots:
		var dc: int = i % PER_ROW
		var dr: int = i / PER_ROW
		var cx: int = MARGIN_X + dc * SPACING_X + SPACING_X / 2
		var cy: int = WALL_H + MARGIN_Y + dr * SPACING_Y + 10
		var occupied: bool = i < n
		_ellipse_shadow(img, cx, cy + 22)
		# Meja (lebih gelap bila kosong).
		var desk: Color = Color(0.42, 0.28, 0.18) if occupied else Color(0.34, 0.26, 0.20)
		img.fill_rect(Rect2i(cx - 19, cy + 8, 38, 15), desk)
		img.fill_rect(Rect2i(cx - 19, cy + 8, 38, 3), desk.lightened(0.12))
		# Monitor (mati bila kosong; menyala berkedip saat kerja).
		img.fill_rect(Rect2i(cx - 7, cy + 3, 14, 9), Color(0.12, 0.14, 0.18))
		var screen: Color = Color(0.20, 0.22, 0.24)
		if occupied:
			screen = Color(0.40, 0.78, 0.90) if (i + frame) % 2 == 0 else Color(0.32, 0.66, 0.82)
		img.fill_rect(Rect2i(cx - 6, cy + 4, 12, 7), screen)
		# Pekerja (sprite Kenney) di belakang meja, bob ngetik.
		if occupied:
			var spec: Dictionary = worker_specs[i]
			var bob: int = -1 if (i + frame) % 2 == 0 else 0
			var cell: Vector2i = CHAR_POOL[i % CHAR_POOL.size()]
			var sprite := char_img.get_region(Rect2i(cell.x * STRIDE, cell.y * STRIDE, TILE, TILE))
			sprite.resize(26, 26, Image.INTERPOLATE_NEAREST)
			if (i / CHAR_POOL.size()) % 2 == 1:
				sprite.flip_x()  # variasi: cermin → tampak beda
			img.blend_rect(sprite, Rect2i(0, 0, 26, 26), Vector2i(cx - 13, cy - 21 + bob))
			var bcol: Color = BADGE.get(spec.get("type", ""), Color(0.6, 0.6, 0.6))
			img.fill_rect(Rect2i(cx + 10, cy - 18, 5, 5), bcol)
	return img

static func _draw_decor(img: Image, w: int, h: int) -> void:
	var by: int = h - 12
	# Tanaman pot di dua sudut bawah.
	for px in [16, w - 16]:
		img.fill_rect(Rect2i(px - 5, by - 7, 10, 7), Color(0.20, 0.52, 0.26))  # daun
		img.fill_rect(Rect2i(px - 4, by - 9, 4, 3), Color(0.24, 0.58, 0.30))
		img.fill_rect(Rect2i(px - 3, by, 6, 6), Color(0.55, 0.32, 0.20))        # pot
	# Dispenser air dekat sudut kanan-bawah.
	var wx: int = w - 40
	img.fill_rect(Rect2i(wx - 4, by - 6, 9, 12), Color(0.86, 0.90, 0.95))
	img.fill_rect(Rect2i(wx - 3, by - 12, 7, 7), Color(0.55, 0.80, 0.95))
	# Karpet kecil di tengah bawah.
	img.fill_rect(Rect2i(w / 2 - 24, by - 3, 48, 9), Color(0.62, 0.30, 0.28))
	_border(img, Rect2i(w / 2 - 24, by - 3, 48, 9), Color(0.78, 0.42, 0.38))

static func _border(img: Image, r: Rect2i, col: Color) -> void:
	img.fill_rect(Rect2i(r.position.x, r.position.y, r.size.x, 1), col)
	img.fill_rect(Rect2i(r.position.x, r.position.y + r.size.y - 1, r.size.x, 1), col)
	img.fill_rect(Rect2i(r.position.x, r.position.y, 1, r.size.y), col)
	img.fill_rect(Rect2i(r.position.x + r.size.x - 1, r.position.y, 1, r.size.y), col)

static func _ellipse_shadow(img: Image, cx: int, cy: int) -> void:
	for dy in range(-3, 4):
		var ww: int = int(sqrt(maxf(0.0, 1.0 - (dy / 3.0) * (dy / 3.0))) * 16)
		for dx in range(-ww, ww):
			var p := Vector2i(cx + dx, cy + dy)
			if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
				img.set_pixel(p.x, p.y, img.get_pixel(p.x, p.y).darkened(0.18))
