class_name MapSession
extends RefCounted

## Handoff between the editor, Battle, and the custom-map picker.
## Playtests and custom yards do not award meta scrap. Built-in yards do.

static var override: MapData
static var playtest := false
static var editor_json := ""


static func blocks_scrap() -> bool:
	if playtest:
		return true
	if override != null and not override.builtin:
		return true
	return false


static func begin_playtest(data: MapData) -> void:
	override = data.duplicate_map()
	playtest = true
	editor_json = data.to_json()
	Profile.use_starter_loadout()


static func begin_custom_battle(data: MapData) -> void:
	override = data.duplicate_map()
	playtest = false
	editor_json = ""


static func clear_override() -> void:
	override = null
	playtest = false
	editor_json = ""
	Profile.clear_starter_loadout()


static func battle_source() -> MapData:
	if override != null:
		return override
	return MapLibrary.load_builtin(Profile.battle_map)
