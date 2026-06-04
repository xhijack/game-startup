class_name DataLoader
extends RefCounted
## Memuat file JSON dari res://data/ menjadi Dictionary. Sumber kebenaran balancing.

const DATA_DIR := "res://data/"

static func load_json(file_name: String) -> Dictionary:
	var path := DATA_DIR + file_name
	if not FileAccess.file_exists(path):
		push_error("Data file tidak ditemukan: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON tidak valid (bukan object): %s" % path)
		return {}
	return parsed
