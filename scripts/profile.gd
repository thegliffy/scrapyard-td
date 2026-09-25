extends Node

## Persistent meta profile. Gold is not stored here — it resets every Battle.

const SAVE_PATH := "user://profile.cfg"
const GUN_ORDER := ["pea", "glue", "spark", "flak", "needle", "boom", "stomper", "net", "fizz", "dual", "magnet", "orbit", "nova"]
const MAP_ORDER := ["yard_approach", "side_dock", "deep_yard"]
const STARTER_GUNS := ["pea", "glue"]
const STARTER_MAPS := ["yard_approach"]
const GUN_COST := {
	"spark": 40,
	"flak": 45,
	"needle": 55,
	"boom": 60,
	"net": 65,
	"dual": 70,
	"magnet": 80,
	"orbit": 90,
	"stomper": 60,
	"fizz": 75,
	"nova": 110,
}
const MAP_COST := {"side_dock": 50, "deep_yard": 100}
const LOADOUT_SIZE := 5
const FREE_SLOTS := 3
const SLOT_COST := {3: 30, 4: 50}

var scrap := 0
var guns: PackedStringArray = PackedStringArray()
var maps: PackedStringArray = PackedStringArray()
var loadout: PackedStringArray = PackedStringArray()
## Set only during a map-editor playtest. Never written to profile.cfg.
var playtest_loadout: PackedStringArray = PackedStringArray()
var open_slots := FREE_SLOTS
var seen: PackedStringArray = PackedStringArray()
var muted := false
## When on, each prep after wave 1 calls the next wave immediately, same as Call.
## Wave 1 always waits for Start.
var auto_call := false
var battle_map := "yard_approach"


func _ready() -> void:
	if OS.get_environment("SCRAPYARD_SMOKE") == "1":
		reset_for_smoke()
	else:
		load_profile()
	call_deferred("_apply_mute")


func _apply_mute() -> void:
	if is_instance_valid(Sfx):
		Sfx.muted = muted


func load_profile() -> void:
	_apply_defaults()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	scrap = maxi(0, int(cfg.get_value("profile", "scrap", 0)))
	muted = bool(cfg.get_value("profile", "muted", false))
	auto_call = bool(cfg.get_value("profile", "auto_call", false))
	guns = _kept(cfg.get_value("profile", "guns", STARTER_GUNS), GUN_ORDER)
	maps = _kept(cfg.get_value("profile", "maps", STARTER_MAPS), MAP_ORDER)
	for id in STARTER_GUNS:
		if not guns.has(id):
			guns.append(id)
	for id in STARTER_MAPS:
		if not maps.has(id):
			maps.append(id)
	battle_map = str(cfg.get_value("profile", "battle_map", "yard_approach"))
	if not has_map(battle_map):
		battle_map = "yard_approach"
	open_slots = clampi(int(cfg.get_value("profile", "open_slots", FREE_SLOTS)), FREE_SLOTS, LOADOUT_SIZE)
	seen = _kept(cfg.get_value("profile", "seen", []), Balance.BESTIARY)
	if cfg.has_section_key("profile", "loadout"):
		loadout = _sanitize_loadout(cfg.get_value("profile", "loadout", _starter_loadout()))
	else:
		loadout = _starter_loadout()


func save_profile() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "scrap", scrap)
	cfg.set_value("profile", "muted", muted)
	cfg.set_value("profile", "auto_call", auto_call)
	cfg.set_value("profile", "guns", guns)
	cfg.set_value("profile", "maps", maps)
	cfg.set_value("profile", "loadout", loadout)
	cfg.set_value("profile", "open_slots", open_slots)
	cfg.set_value("profile", "battle_map", battle_map)
	cfg.set_value("profile", "seen", seen)
	cfg.save(SAVE_PATH)


func reset_for_smoke() -> void:
	_apply_defaults()
	save_profile()


func _apply_defaults() -> void:
	scrap = 0
	muted = false
	auto_call = false
	guns = PackedStringArray(STARTER_GUNS)
	maps = PackedStringArray(STARTER_MAPS)
	loadout = _starter_loadout()
	open_slots = FREE_SLOTS
	seen = PackedStringArray()
	battle_map = "yard_approach"


func _kept(raw, allowed: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var values: Array = []
	if raw is PackedStringArray or raw is Array:
		values = Array(raw)
	for item in values:
		var id := str(item)
		if allowed.has(id) and not out.has(id):
			out.append(id)
	return out


func _starter_loadout() -> PackedStringArray:
	return PackedStringArray(["pea", "glue", "", "", ""])


func _sanitize_loadout(raw) -> PackedStringArray:
	var out := PackedStringArray(["", "", "", "", ""])
	var values: Array = []
	if raw is PackedStringArray or raw is Array:
		values = Array(raw)
	var used := {}
	for i in mini(LOADOUT_SIZE, values.size()):
		if not slot_open(i):
			continue
		var id := str(values[i])
		if id == "" or not has_gun(id) or used.has(id):
			continue
		out[i] = id
		used[id] = true
	return out


func mark_seen(id: String) -> void:
	if id == "" or not Balance.ENEMIES.has(id) or seen.has(id):
		return
	seen.append(id)
	save_profile()


func has_seen(id: String) -> bool:
	return seen.has(id)


func has_gun(id: String) -> bool:
	return guns.has(id)


func is_equipped(id: String) -> bool:
	if id == "":
		return false
	if not playtest_loadout.is_empty():
		return playtest_loadout.has(id)
	return loadout.has(id)


func slot_open(index: int) -> bool:
	return index >= 0 and index < open_slots


func slot_cost(index: int) -> int:
	return int(SLOT_COST.get(index, 0))


func loadout_at(index: int) -> String:
	var source: PackedStringArray = playtest_loadout if not playtest_loadout.is_empty() else loadout
	if index < 0 or index >= source.size():
		return ""
	return str(source[index])


## Playtest shows the starter bar without writing the saved loadout.
func use_starter_loadout() -> void:
	playtest_loadout = _starter_loadout()


func clear_starter_loadout() -> void:
	playtest_loadout = PackedStringArray()


func equipped_entries() -> Array:
	var out: Array = []
	for i in LOADOUT_SIZE:
		var id := loadout_at(i)
		if id != "":
			out.append({"slot": i, "id": id})
	return out


func has_map(id: String) -> bool:
	return maps.has(id)


func unlocked_guns() -> Array:
	var out: Array = []
	for id in GUN_ORDER:
		if guns.has(id):
			out.append(id)
	return out


func unlocked_maps() -> Array:
	var out: Array = []
	for id in MAP_ORDER:
		if maps.has(id):
			out.append(id)
	return out


func try_unlock_slot(index: int) -> bool:
	if slot_open(index) or index != open_slots or not SLOT_COST.has(index):
		return false
	var price := slot_cost(index)
	if scrap < price:
		return false
	scrap -= price
	open_slots += 1
	save_profile()
	return true


func assign_loadout(index: int, gun_id: String) -> bool:
	if not slot_open(index) or gun_id == "" or not has_gun(gun_id):
		return false
	var from := -1
	for i in LOADOUT_SIZE:
		if loadout[i] == gun_id:
			from = i
			break
	var occupant := loadout_at(index)
	if from == index:
		return true
	if from >= 0:
		loadout[from] = occupant if occupant != gun_id else ""
	elif occupant != "":
		loadout[index] = ""
	loadout[index] = gun_id
	save_profile()
	return true


func clear_loadout(index: int) -> void:
	if not slot_open(index):
		return
	loadout[index] = ""
	save_profile()


func try_buy_gun(id: String) -> bool:
	if has_gun(id) or not GUN_COST.has(id):
		return false
	var price := int(GUN_COST[id])
	if scrap < price:
		return false
	scrap -= price
	guns.append(id)
	save_profile()
	return true


func try_buy_map(id: String) -> bool:
	if has_map(id) or not MAP_COST.has(id):
		return false
	var price := int(MAP_COST[id])
	if scrap < price:
		return false
	scrap -= price
	maps.append(id)
	save_profile()
	return true


func set_muted(next: bool) -> void:
	muted = next
	if is_instance_valid(Sfx):
		Sfx.muted = muted
	save_profile()


func set_auto_call(next: bool) -> void:
	auto_call = next
	save_profile()


func choose_map(id: String) -> void:
	if has_map(id):
		battle_map = id
		save_profile()


func map_name() -> String:
	var data := _active_yard()
	if data != null:
		return data.map_name
	return str(Balance.MAPS.get(battle_map, {}).get("name", "Yard Approach"))


func map_hp_scale() -> float:
	var data := _active_yard()
	if data != null:
		return data.hp_scale
	return float(Balance.MAPS.get(battle_map, {}).get("hp_scale", 1.0))


func map_speed_scale() -> float:
	var data := _active_yard()
	if data != null:
		return data.speed_scale
	return float(Balance.MAPS.get(battle_map, {}).get("speed_scale", 1.0))


func map_tint() -> Color:
	var data := _active_yard()
	if data != null:
		return Color(data.tint)
	var hex := str(Balance.MAPS.get(battle_map, {}).get("tint", "#ffffff"))
	return Color(hex)


func map_tint_amount() -> float:
	var data := _active_yard()
	if data != null:
		return data.tint_amount
	return float(Balance.MAPS.get(battle_map, {}).get("tint_amount", 0.0))


func _active_yard() -> MapData:
	if Board.active != null:
		return Board.active
	if MapSession.override != null:
		return MapSession.override
	return MapLibrary.load_builtin(battle_map)


## A win pays 2 scrap per wave cleared. A loss pays 1 per wave cleared.
## The count is waves fully finished. The wave that darkens the core does not count.
func battle_scrap(won: bool, waves_cleared: int) -> int:
	return maxi(0, waves_cleared) * (2 if won else 1)


func award_battle(won: bool, waves_cleared: int) -> int:
	var amount := battle_scrap(won, waves_cleared)
	scrap += amount
	save_profile()
	return amount
