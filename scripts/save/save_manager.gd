class_name SaveManager
extends RefCounted
## Save/load lokal sederhana (user:// JSON). Offline-first.

const SAVE_PATH := "user://savegame.json"

static func save(state: Dictionary) -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Gagal membuka save file untuk ditulis.")
		return false
	f.store_string(JSON.stringify(state, "\t"))
	return true

static func load_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
