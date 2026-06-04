extends Node
## Manajer audio sederhana (autoload "Audio"). Aset CC0 Kenney di assets/audio/.
## Presentasi murni: dipanggil UI/sinyal, tidak menyentuh logika game.

var _clips: Dictionary = {}
var _sfx_player: AudioStreamPlayer
var _jingle_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	_jingle_player = AudioStreamPlayer.new()
	_jingle_player.volume_db = -3.0
	add_child(_jingle_player)
	for key in ["click", "confirm", "error", "jingle_event", "jingle_win"]:
		_clips[key] = _load_clip(key + ".ogg")
	_start_music()

func _start_music() -> void:
	var music := _load_clip("music.ogg")
	if music == null:
		return
	# Pastikan loop (ogg vorbis punya properti loop).
	if music is AudioStreamOggVorbis:
		(music as AudioStreamOggVorbis).loop = true
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = music
	_music_player.volume_db = -14.0
	add_child(_music_player)
	_music_player.play()

func set_music_enabled(on: bool) -> void:
	if _music_player == null:
		return
	if on and not _music_player.playing:
		_music_player.play()
	elif not on:
		_music_player.stop()

func _load_clip(file_name: String) -> AudioStream:
	var path := "res://assets/audio/" + file_name
	if ResourceLoader.exists(path):
		return load(path)
	return null

## SFX pendek (klik, konfirmasi, error).
func play(key: String) -> void:
	var clip: AudioStream = _clips.get(key)
	if clip != null:
		_sfx_player.stream = clip
		_sfx_player.play()

## Jingle (event/menang) — kanal terpisah agar tidak terpotong SFX.
func jingle(key: String) -> void:
	var clip: AudioStream = _clips.get(key)
	if clip != null:
		_jingle_player.stream = clip
		_jingle_player.play()
