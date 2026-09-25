class_name MapLibrary
extends RefCounted

## Loads built-in yards from res://maps and custom yards from user://maps.
## Built-in files are read-only. Custom maps never award meta scrap.

const BUILTIN := ["yard_approach", "side_dock", "deep_yard"]
const CUSTOM_DIR := "user://maps"


static func is_builtin(id: String) -> bool:
	return id in BUILTIN


static func load_builtin(id: String) -> MapData:
	var path := "res://maps/%s.json" % id
	if not FileAccess.file_exists(path):
		push_error("Missing built-in map %s" % path)
		return null
	var data := MapData.from_json(FileAccess.get_file_as_string(path))
	if data == null:
		push_error("Could not read %s" % path)
		return null
	data.builtin = true
	data.id = id
	return data


static func list_custom() -> PackedStringArray:
	var ids := PackedStringArray()
	if not DirAccess.dir_exists_absolute(CUSTOM_DIR):
		return ids
	var dir := DirAccess.open(CUSTOM_DIR)
	if dir == null:
		return ids
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			ids.append(file_name.trim_suffix(".json"))
		file_name = dir.get_next()
	dir.list_dir_end()
	ids.sort()
	return ids


static func load_custom(id: String) -> MapData:
	var path := "%s/%s.json" % [CUSTOM_DIR, id]
	if not FileAccess.file_exists(path):
		return null
	var data := MapData.from_json(FileAccess.get_file_as_string(path))
	if data == null:
		return null
	data.builtin = false
	if data.id == "":
		data.id = id
	return data


static func load_for_battle(id: String) -> MapData:
	if is_builtin(id):
		return load_builtin(id)
	return load_custom(id)


static func save_custom(data: MapData) -> String:
	if data == null:
		return "Nothing to save."
	if data.builtin or is_builtin(data.id):
		return "Built-in yards stay read-only. Use Save As."
	if data.id.strip_edges() == "":
		return "This yard needs an id. Use Save As."
	var problems := MapValidator.errors(data)
	if not problems.is_empty():
		return problems[0]
	DirAccess.make_dir_recursive_absolute(CUSTOM_DIR)
	data.builtin = false
	var file := FileAccess.open("%s/%s.json" % [CUSTOM_DIR, data.id], FileAccess.WRITE)
	if file == null:
		return "Could not write the map file."
	file.store_string(data.to_json())
	file.close()
	return ""


static func delete_custom(id: String) -> String:
	if is_builtin(id):
		return "Built-in yards cannot be deleted."
	var path := "%s/%s.json" % [CUSTOM_DIR, id]
	if not FileAccess.file_exists(path):
		return "That custom map is not on disk."
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		return "Could not delete the map file."
	return ""


static func unique_id(base: String) -> String:
	var slug := _slug(base)
	if slug == "" or is_builtin(slug):
		slug = "custom_yard"
	var candidate := slug
	var n := 2
	while is_builtin(candidate) or FileAccess.file_exists("%s/%s.json" % [CUSTOM_DIR, candidate]):
		candidate = "%s_%d" % [slug, n]
		n += 1
	return candidate


static func _slug(raw: String) -> String:
	var text := raw.strip_edges().to_lower()
	var out := ""
	for i in text.length():
		var ch := text[i]
		var code := ch.unicode_at(0)
		var ok := (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
		out += ch if ok else "_"
	while out.contains("__"):
		out = out.replace("__", "_")
	return out.trim_prefix("_").trim_suffix("_")
