extends SceneTree
## Preview OfficeRenderer dengan tim demo (Image ops, headless). Verifiable via PNG.
##   TIER=2 godot --headless --path . -s res://tools/office_preview.gd
## Output: user://office_preview.png

func _initialize() -> void:
	var char_img := (load("res://assets/tiles/char_sheet.png") as Texture2D).get_image()
	var all := ["engineer", "designer", "marketing", "engineer", "marketing", "designer", "engineer", "marketing", "designer", "engineer"]
	var count := 10
	if OS.get_environment("COUNT") != "":
		count = int(OS.get_environment("COUNT"))
	var specs: Array = []
	for i in count:
		specs.append({ "type": all[i % all.size()] })
	var tier := 2
	if OS.get_environment("TIER") != "":
		tier = int(OS.get_environment("TIER"))
	var caps := [4, 8, 16, 30]
	var img := OfficeRenderer.compose(specs, tier, char_img, 0, caps[clampi(tier, 0, 3)])
	# Perbesar 3x (nearest) supaya jelas dilihat.
	img.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	img.save_png("user://office_preview.png")
	print("[PREVIEW] composed %dx%d, %d workers, tier %d" % [img.get_width(), img.get_height(), specs.size(), tier])
	quit()
