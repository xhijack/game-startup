extends Node2D
## Bootstrap scene utama. World, Camera, dan UI sudah jadi child di main.tscn.
## GameState (autoload) di-start oleh UIRoot saat siap.

func _ready() -> void:
	# Orkestrasi state ada di GameState; UI memicu start_new_game().
	# Hook screenshot dev (hanya saat env SHOT=1) — tidak berpengaruh ke gameplay.
	if OS.get_environment("SHOT") == "1":
		await get_tree().create_timer(0.7).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_png("user://shot.png")
		get_tree().quit()
