extends Node2D

const TOWER_SCENE := preload("res://scenes/towers/tower.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const SLOT_SCENE := preload("res://scenes/map/build_slot.tscn")

const AUTOPLAY_PLAN: Array = [
	[Vector2i(1, 2), "pea"],
	[Vector2i(1, 8), "pea"],
	[Vector2i(8, 2), "pea"],
	[Vector2i(7, 8), "pea"],
	[Vector2i(14, 8), "glue"],
	[Vector2i(14, 4), "spark"],
	[Vector2i(20, 6), "boom"],
	[Vector2i(9, 2), "magnet"],
]

@onready var slots_root: Node2D = $World/Slots
@onready var entities: Node2D = $World/Entities
@onready var projectiles: Node2D = $World/Projectiles
@onready var vfx: Node2D = $World/Vfx
@onready var wave: Node = $WaveDirector
@onready var camera: Camera2D = $Camera2D
@onready var map: Node2D = $World/Map
@onready var hud: Control = $UI/HUD

var slots := {}
var build_kind := ""
var selected_cell = null
var hover_cell := Vector2i(-99, -99)
var shake_left := 0.0
var shake_mag := 0.0
var auto_timer := 0.0
var auto_clock := 0.0


func _ready() -> void:
	add_to_group("game_root")
	get_tree().paused = false
	if hud.has_method("install_pause_overlay"):
		hud.install_pause_overlay()
	projectiles.add_to_group("projectiles")
	var yard := MapSession.battle_source()
	if yard != null:
		Board.apply(yard)
	else:
		Board.ensure()
	for err in Board.validate():
		push_error(err)
	Game.autoplay = OS.get_environment("SCRAPYARD_AUTOPLAY") == "1"
	Game.boot()
	if Game.autoplay:
		Engine.time_scale = 12.0
		Game.speed = 12.0
	for cell in Board.SLOTS:
		var slot = SLOT_SCENE.instantiate()
		slots_root.add_child(slot)
		slot.setup(cell)
		slots[cell] = slot
	Game.core_hit.connect(_on_core_hit)
	wave.start()
	hud.refresh_all()
	if OS.get_environment("SCRAPYARD_SMOKE") == "1":
		Profile.reset_for_smoke()
		_run_smoke()


func _process(delta: float) -> void:
	if shake_left > 0.0:
		shake_left = max(0.0, shake_left - delta)
		var falloff := shake_left / 0.24
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_mag * falloff
	else:
		camera.offset = Vector2.ZERO
	var cell := Board.world_to_cell(get_global_mouse_position())
	if cell != hover_cell:
		hover_cell = cell
		_refresh_hover_visuals()
		if not DisplayServer.get_name() == "headless":
			var shape := DisplayServer.CURSOR_POINTING_HAND if slots.has(cell) else DisplayServer.CURSOR_ARROW
			DisplayServer.cursor_set_shape(shape)
	if Game.autoplay:
		_autoplay(delta)


func _unhandled_input(event: InputEvent) -> void:
	if Game.autoplay:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click_cell(Board.world_to_cell(get_global_mouse_position()))
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				_select_hotkey(event.keycode - KEY_1)
			KEY_U:
				upgrade_selected()
			KEY_BACKSPACE:
				sell_selected()
			KEY_SPACE:
				call_early()
			KEY_F:
				Game.toggle_speed()
				hud.refresh_all()
			KEY_ESCAPE, KEY_P:
				toggle_pause()
			KEY_R:
				if Game.ended:
					restart()


func restart() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func toggle_pause() -> void:
	if Game.autoplay:
		return
	var tree := get_tree()
	if tree.paused:
		tree.paused = false
		if hud.has_method("set_pause_visible"):
			hud.set_pause_visible(false)
		Sfx.play("ui")
		return
	if hud.has_method("set_pause_visible"):
		hud.set_pause_visible(true)
	tree.paused = true


func call_early() -> void:
	wave.call_early()
	hud.refresh_all()


func _select_hotkey(index: int) -> void:
	var kind := Profile.loadout_at(index)
	if kind == "":
		return
	select_build(kind)


func select_build(kind: String) -> void:
	if Game.ended or not Profile.is_equipped(kind):
		return
	build_kind = "" if build_kind == kind else kind
	selected_cell = null
	_refresh_hover_visuals()
	hud.refresh_all()


func place_tower(cell: Vector2i, kind: String) -> bool:
	if Game.ended or not slots.has(cell):
		return false
	var slot = slots[cell]
	if slot.tower != null or not Profile.is_equipped(kind):
		return false
	if not Game.try_spend(Balance.cost(kind)):
		return false
	var tower = TOWER_SCENE.instantiate()
	entities.add_child(tower)
	tower.setup(kind, cell, Balance.cost(kind))
	slot.tower = tower
	Sfx.play("place")
	vfx.burst(slot.position, Color("#ffe08a"), 8)
	_refresh_hover_visuals()
	hud.refresh_all()
	return true


func upgrade_selected() -> void:
	var tower = _selected_tower()
	if tower == null or tower.tier >= 3:
		return
	var price: int = tower.upgrade_cost()
	if not Game.try_spend(price):
		Sfx.play("error")
		vfx.float_text(tower.position, "Need gold", Color("#ffb4c4"))
		return
	tower.invested += price
	tower.tier += 1
	tower.refresh_visual()
	Sfx.play("upgrade")
	vfx.burst(tower.position, Color("#fff1a8"), 8)
	_refresh_hover_visuals()
	hud.refresh_all()


func sell_selected() -> void:
	var tower = _selected_tower()
	if tower == null:
		return
	var refund := int(floor(float(tower.invested) * 0.6))
	Game.add_gold(refund)
	slots[tower.cell].tower = null
	vfx.float_text(tower.position, "+%d" % refund, Color("#ffe08a"))
	tower.queue_free()
	selected_cell = null
	Sfx.play("sell")
	_refresh_hover_visuals()
	hud.refresh_all()


func spawn_enemy(kind: String, lane_id: String, path_override = null, start_index: int = 0, hop: float = 0.0, tint: Color = Color.WHITE):
	var path_cells = path_override if path_override != null else Board.lane(lane_id)
	var enemy = ENEMY_SCENE.instantiate()
	entities.add_child(enemy)
	enemy.setup(kind, path_cells.duplicate(), start_index, hop, tint)
	return enemy


func tower_at(cell: Vector2i):
	if not slots.has(cell):
		return null
	return slots[cell].tower


func shake(amount: float) -> void:
	shake_mag = max(shake_mag, amount)
	shake_left = 0.24


func _selected_tower():
	if selected_cell == null:
		return null
	return tower_at(selected_cell)


func _click_cell(cell: Vector2i) -> void:
	if Game.ended:
		return
	if not slots.has(cell):
		selected_cell = null
		_refresh_hover_visuals()
		hud.refresh_all()
		return
	var slot = slots[cell]
	if slot.tower == null:
		if build_kind == "":
			Sfx.play("error")
			vfx.float_text(slot.position, "Pick a chip", Color("#fff6e4"))
			return
		if not place_tower(cell, build_kind):
			Sfx.play("error")
			vfx.float_text(slot.position, "Need gold", Color("#ffb4c4"))
		return
	selected_cell = cell
	build_kind = ""
	_refresh_hover_visuals()
	hud.refresh_all()


func _refresh_hover_visuals() -> void:
	var origin = null
	var radius := 0.0
	if build_kind != "" and slots.has(hover_cell) and slots[hover_cell].tower == null:
		origin = hover_cell
		radius = Balance.tier_value(build_kind, "range", 1)
	elif selected_cell != null and tower_at(selected_cell) != null:
		origin = selected_cell
		radius = tower_at(selected_cell).range_tiles()
	var cells: Array = []
	if origin != null:
		cells = Board.cells_in_range(origin, radius)
	map.set_highlights(cells)
	for cell in slots.keys():
		var slot = slots[cell]
		slot.hovered = cell == hover_cell
		slot.selected = selected_cell != null and cell == selected_cell
		slot.ghost = null
		if build_kind != "" and cell == hover_cell and slot.tower == null:
			slot.ghost = Art.tower_tex(build_kind)
		slot.queue_redraw()


func _on_core_hit(_amount: int) -> void:
	shake(8.0)
	hud.pulse_hurt()
	Sfx.play("leak")


func _autoplay(delta: float) -> void:
	if Game.ended:
		print("AUTOPLAY %s wave=%d hp=%d gold=%d kills=%d leaks=%d" % [
			Game.phase, Game.display_wave(), Game.core_hp, Game.gold, Game.kills, Game.leaks
		])
		get_tree().quit(0 if Game.phase == "win" else 3)
		return
	auto_clock += delta
	if auto_clock > 520.0:
		print("AUTOPLAY timeout wave=%d hp=%d gold=%d" % [Game.display_wave(), Game.core_hp, Game.gold])
		get_tree().quit(4)
		return
	auto_timer -= delta
	if auto_timer > 0.0:
		return
	auto_timer = 0.35
	for step in AUTOPLAY_PLAN:
		var cell: Vector2i = step[0]
		var kind: String = step[1]
		if tower_at(cell) != null or not Profile.is_equipped(kind):
			continue
		var price := Balance.cost(kind)
		if Game.gold >= price:
			place_tower(cell, kind)
			return
		if price - Game.gold > 35:
			var up = _auto_upgrade()
			if up != null:
				selected_cell = up.cell
				upgrade_selected()
				return
		_auto_call()
		return
	var upgrade = _auto_upgrade()
	if upgrade != null:
		selected_cell = upgrade.cell
		upgrade_selected()
		return
	_auto_call()


func _auto_upgrade():
	var best = null
	for cell in Board.SLOTS:
		var tower = tower_at(cell)
		if tower == null or tower.tier >= 3 or tower.kind == "magnet":
			continue
		if Game.gold < tower.upgrade_cost():
			continue
		if best == null or tower.tier < best.tier:
			best = tower
	return best


func _run_smoke() -> void:
	var failed := false
	if Game.phase != "prep":
		push_error("smoke: expected prep, got %s" % Game.phase)
		failed = true
	if not Game.is_first_prep() or Game.early_bonus() != 0:
		push_error("smoke: wave 1 prep should wait with no bonus")
		failed = true
	hud._refresh_live()
	var opening_call: Button = hud.get("call_button")
	var opening_status: Label = hud.get("status_label")
	if opening_call == null or opening_call.text != "Start" or "Next in" in opening_status.text:
		push_error("smoke: wave 1 HUD should say Start and hide the countdown")
		failed = true
	var opening_gold: int = Game.gold
	wave._process(40.0)
	if Game.phase != "prep" or Game.gold != opening_gold or Game.early_bonus() != 0:
		push_error("smoke: wave 1 prep expired or paid gold")
		failed = true
	if not place_tower(Vector2i(1, 2), "pea"):
		push_error("smoke: could not place Pea Blaster")
		failed = true
	elif Game.gold != Balance.START_GOLD - Balance.cost("pea"):
		push_error("smoke: gold did not drop")
		failed = true
	var squid = spawn_enemy("fast_skitter", "a")
	var start_cell: Vector2i = squid.from_cell
	squid._process(0.5)
	if squid.from_cell == start_cell:
		push_error("smoke: Fast Skitter did not hop a cell")
		failed = true
	var before: int = Game.gold
	squid.take_damage(9999)
	if Game.kills != 1 or Game.gold <= before:
		push_error("smoke: pop did not pay gold")
		failed = true
	if place_tower(Vector2i(1, 3), "spark"):
		push_error("smoke: locked Spark Arc was placed")
		failed = true
	if Profile.loadout_at(0) != "pea" or Profile.loadout_at(1) != "glue" or Profile.loadout_at(2) != "":
		push_error("smoke: starter loadout")
		failed = true
	if Profile.slot_open(3) or Profile.slot_open(4):
		push_error("smoke: extra loadout slots should start locked")
		failed = true
	if Profile.slot_cost(3) != 30 or Profile.slot_cost(4) != 50:
		push_error("smoke: slot costs")
		failed = true
	if Profile.assign_loadout(3, "pea") or Profile.assign_loadout(4, "glue"):
		push_error("smoke: equipped into a locked slot")
		failed = true
	if Profile.try_unlock_slot(4) or Profile.try_unlock_slot(3):
		push_error("smoke: unlocked a slot with no scrap")
		failed = true
	var unlocks: Control = load("res://scripts/unlocks.gd").new()
	add_child(unlocks)
	if unlocks._slot_buttons.size() != Profile.LOADOUT_SIZE:
		push_error("smoke: loadout bar size")
		failed = true
	else:
		var lock_a: Control = unlocks._slot_buttons[3].get_node("Lock")
		var lock_b: Control = unlocks._slot_buttons[4].get_node("Lock")
		var open_lock: Control = unlocks._slot_buttons[0].get_node("Lock")
		var cap_a: Label = unlocks._slot_buttons[3].get_node("Caption")
		var cap_b: Label = unlocks._slot_buttons[4].get_node("Caption")
		if not lock_a.visible or not lock_b.visible or open_lock.visible:
			push_error("smoke: lock icon on the wrong slots")
			failed = true
		if not cap_a.text.contains("30") or not cap_b.text.contains("50"):
			push_error("smoke: slot cost labels")
			failed = true
	unlocks.queue_free()
	var picker: Control = load("res://scripts/map_select.gd").new()
	add_child(picker)
	if picker._map_ids != ["yard_approach"]:
		push_error("smoke: map select listed a locked yard")
		failed = true
	picker.queue_free()
	var settings: Control = load("res://scripts/settings.gd").new()
	add_child(settings)
	settings.queue_free()
	Profile.scrap = 80
	if not Profile.try_unlock_slot(3) or Profile.scrap != 50 or not Profile.slot_open(3):
		push_error("smoke: slot 4 purchase")
		failed = true
	if Profile.slot_open(4) or not Profile.try_unlock_slot(4) or Profile.open_slots != 5 or Profile.scrap != 0:
		push_error("smoke: slot 5 purchase")
		failed = true
	if not Profile.assign_loadout(3, "glue") or Profile.loadout_at(3) != "glue" or Profile.loadout_at(1) != "":
		push_error("smoke: opened slot did not accept a gun")
		failed = true
	Profile.load_profile()
	if Profile.open_slots != 5 or Profile.scrap != 0 or Profile.loadout_at(3) != "glue":
		push_error("smoke: slot unlock did not persist")
		failed = true
	if Profile.battle_scrap(false, 99) != 99 or Profile.battle_scrap(false, 4) != 4 or Profile.battle_scrap(false, 0) != 0:
		push_error("smoke: loss scrap is not 1 per wave cleared")
		failed = true
	var saved_wave := Game.wave_index
	Game.wave_index = 9
	if Game.waves_cleared(false) != 9 or Game.waves_cleared(true) != 10:
		push_error("smoke: waves cleared count drifted")
		failed = true
	Game.wave_index = -1
	if Game.waves_cleared(false) != 0 or Game.waves_cleared(true) != 0:
		push_error("smoke: a battle with no wave paid scrap waves")
		failed = true
	Game.wave_index = saved_wave
	if Profile.battle_scrap(true, 21) != 42 or Profile.battle_scrap(true, 100) != 200 or Profile.battle_scrap(true, 0) != 0:
		push_error("smoke: win scrap is not 2 per wave cleared")
		failed = true
	if Profile.auto_call:
		push_error("smoke: auto-call should start off")
		failed = true
	Profile.set_auto_call(true)
	Profile.load_profile()
	if not Profile.auto_call:
		push_error("smoke: auto-call did not persist")
		failed = true
	Profile.set_auto_call(false)
	if Balance.WAVE_COUNT != 100 or Game.wave_total != 100 or Balance.WAVES.size() != 21:
		push_error("smoke: expected 100 waves with 21 handcrafted")
		failed = true
	if not Balance.wave_at(20).get("boss", false) or not Balance.wave_at(39).get("boss", false):
		push_error("smoke: missing boss at wave 21 or 40")
		failed = true
	if not Balance.wave_at(59).get("boss", false) or not Balance.wave_at(79).get("boss", false) or not Balance.wave_at(99).get("boss", false):
		push_error("smoke: missing later boss")
		failed = true
	if Balance.wave_at(21).get("boss", false) or str(Balance.wave_at(0)["title"]) != "Fast Skitters":
		push_error("smoke: intro or post-boss wave shape")
		failed = true
	var late_scale := Balance.wave_hp_scale(100)
	var mid_scale := Balance.wave_hp_scale(21)
	if late_scale <= mid_scale or mid_scale < Balance.wave_hp_scale(1):
		push_error("smoke: hp scale flattened")
		failed = true
	if int(Balance.enemy("chunky_tank")["split"]) != 3 or str(Balance.enemy("chunky_tank")["split_kind"]) != "tanklet":
		push_error("smoke: tank does not split")
		failed = true
	if int(Balance.enemy("tanklet")["split"]) != 0 or float(Balance.enemy("tanklet")["hp"]) >= float(Balance.enemy("chunky_tank")["hp"]):
		push_error("smoke: tanklet still splits or is not weaker")
		failed = true
	if int(Balance.enemy("shielded")["split"]) != 2 or int(Balance.enemy("open_shell")["split"]) != 0:
		push_error("smoke: shielded split")
		failed = true
	if str(Balance.enemy("elite_tank")["split_kind"]) != "chunky_tank" or int(Balance.enemy("swarmling")["split"]) != 0:
		push_error("smoke: elite chain or swarmling recursion")
		failed = true
	if not Balance.can_hit("pea", "small_flyer") or not Balance.can_hit("pea", "fast_skitter"):
		push_error("smoke: pea should hit ground and air")
		failed = true
	if Balance.can_hit("glue", "flyer") or Balance.can_hit("boom", "small_flyer") or Balance.can_hit("flak", "fast_skitter"):
		push_error("smoke: layer targeting leaked")
		failed = true
	if not Balance.can_hit("needle", "flyer") or not Balance.can_hit("dual", "chunky_tank") or not Balance.can_hit("orbit", "flying_boss"):
		push_error("smoke: new guns cannot hit their layers")
		failed = true
	if Balance.can_hit("magnet", "flyer") or Balance.can_hit("net", "fast_skitter") or not Balance.can_hit("spark", "flying_boss"):
		push_error("smoke: magnet, net, or spark layer")
		failed = true
	if not bool(Balance.enemy("small_flyer")["flying"]) or bool(Balance.enemy("fast_skitter")["flying"]):
		push_error("smoke: flying flags")
		failed = true
	if str(Balance.wave_at(13)["title"]) != "First Flight" or str(Balance.wave_at(49)["entries"][0]["kind"]) != "flying_boss":
		push_error("smoke: air intro or wave 50 flying boss")
		failed = true
	if str(Balance.wave_at(89)["entries"][0]["kind"]) != "flying_boss" or str(Balance.wave_at(20)["entries"][0]["kind"]) != "big_cute_boss":
		push_error("smoke: wave 90 flyer or ground finale")
		failed = true
	if Profile.GUN_ORDER.size() != 13 or int(Profile.GUN_COST["flak"]) != 45 or int(Profile.GUN_COST["orbit"]) != 90:
		push_error("smoke: gun roster or scrap costs")
		failed = true
	if int(Profile.GUN_COST["stomper"]) != 60 or int(Profile.GUN_COST["fizz"]) != 75 or int(Profile.GUN_COST["nova"]) != 110:
		push_error("smoke: new gun scrap costs")
		failed = true
	if Balance.can_hit("stomper", "small_flyer") or not Balance.can_hit("stomper", "fast_skitter"):
		push_error("smoke: stomper should be ground only")
		failed = true
	if Balance.can_hit("fizz", "fast_skitter") or not Balance.can_hit("fizz", "flyer"):
		push_error("smoke: fizz should be air only")
		failed = true
	if not Balance.can_hit("nova", "fast_skitter") or not Balance.can_hit("nova", "flying_boss"):
		push_error("smoke: nova should hit ground and air")
		failed = true
	if Balance.cost("nova") <= Balance.cost("orbit") or Balance.cost("stomper") >= Balance.cost("boom"):
		push_error("smoke: new gun gold costs drifted")
		failed = true
	var area_bug = spawn_enemy("fast_skitter", "a")
	var area_moth = spawn_enemy("small_flyer", "a")
	area_bug.global_position = Board.cell_center(Vector2i(8, 1))
	area_moth.global_position = Board.cell_center(Vector2i(8, 1)) + Vector2(0, -28)
	var bug_hp: float = area_bug.hp
	var moth_hp: float = area_moth.hp
	var stomper = TOWER_SCENE.instantiate()
	entities.add_child(stomper)
	stomper.setup("stomper", Vector2i(8, 2), 100)
	stomper._shoot(area_bug)
	if area_bug.hp >= bug_hp or area_moth.hp != moth_hp:
		push_error("smoke: stomper did not slam ground only")
		failed = true
	bug_hp = area_bug.hp
	var fizz = TOWER_SCENE.instantiate()
	entities.add_child(fizz)
	fizz.setup("fizz", Vector2i(8, 2), 110)
	fizz._shoot(area_moth)
	var clouds := get_tree().get_nodes_in_group("fizz_clouds")
	if clouds.is_empty():
		push_error("smoke: fizz did not lob a cloud")
		failed = true
	else:
		clouds[0]._process(0.2)
	if area_moth.hp >= moth_hp or area_bug.hp != bug_hp:
		push_error("smoke: fizz cloud did not tick flyers only")
		failed = true
	bug_hp = area_bug.hp
	moth_hp = area_moth.hp
	var nova = TOWER_SCENE.instantiate()
	entities.add_child(nova)
	nova.setup("nova", Vector2i(8, 2), 175)
	nova._shoot(area_bug)
	if area_bug.hp >= bug_hp or area_moth.hp >= moth_hp:
		push_error("smoke: nova missed a layer")
		failed = true
	stomper.queue_free()
	fizz.queue_free()
	nova.queue_free()
	for cloud in get_tree().get_nodes_in_group("fizz_clouds"):
		cloud.queue_free()
	area_bug.alive = false
	area_bug.queue_free()
	area_moth.alive = false
	area_moth.queue_free()
	var bird = spawn_enemy("small_flyer", "a")
	var ground_y := Board.cell_center(bird.current_cell()).y
	if not bird.flying or bird.global_position.y >= ground_y - 10.0 or not Profile.has_seen("small_flyer"):
		push_error("smoke: flyer lift or bestiary seen flag")
		failed = true
	if Profile.has_seen("flying_boss"):
		push_error("smoke: unseen boss was marked seen")
		failed = true
	bird.alive = false
	bird.queue_free()
	Game.wave_index = 3
	var mom = spawn_enemy("chunky_tank", "a")
	var mom_hp: float = mom.max_hp
	mom.take_damage(99999)
	var kids: Array = []
	for critter in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(critter) and critter.alive and str(critter.kind) == "tanklet":
			kids.append(critter)
	if kids.size() != 3 or float(kids[0].max_hp) >= mom_hp or int(kids[0].split_into) != 0:
		push_error("smoke: tank did not drop 3 weaker tanklets")
		failed = true
	Game.wave_index = 0
	var early = spawn_enemy("fast_skitter", "a")
	var early_hp: float = early.max_hp
	early.alive = false
	early.queue_free()
	Game.wave_index = 99
	var late = spawn_enemy("fast_skitter", "a")
	if late.max_hp <= early_hp * 3.0:
		push_error("smoke: wave 100 hp did not scale")
		failed = true
	var boss_late = spawn_enemy("big_cute_boss", "a")
	var boss_late_hp: float = boss_late.max_hp
	boss_late.alive = false
	boss_late.queue_free()
	late.alive = false
	late.queue_free()
	Game.wave_index = 20
	var boss_early = spawn_enemy("big_cute_boss", "a")
	if boss_late_hp <= boss_early.max_hp * 2.0:
		push_error("smoke: finale boss is not tougher than wave 21")
		failed = true
	boss_early.alive = false
	boss_early.queue_free()
	var toad = spawn_enemy("chunky_tank", "b")
	var hp_before: int = Game.core_hp
	toad.leak()
	if Game.core_hp != hp_before - 3:
		push_error("smoke: Chunky Tank leak damage")
		failed = true
	if place_tower(Vector2i(1, 2), "spark"):
		push_error("smoke: occupied cell accepted a tower")
		failed = true
	if Board.lane_a.size() != 27 or Board.lane_b.size() != 27 or Board.lane_a[0] != Vector2i(0, 1):
		push_error("smoke: yard lanes drifted")
		failed = true
	if Board.CORE != Vector2i(22, 5) or Board.SLOTS.size() != 36 or Board.COLS != 24 or Board.ROWS != 11:
		push_error("smoke: yard grid drifted")
		failed = true
	if Board.style_at(Vector2i(1, 2)) != "pink" or Board.style_at(Vector2i(8, 2)) != "teal":
		push_error("smoke: island styles drifted")
		failed = true
	if not MapValidator.ok(Board.active):
		push_error("smoke: built-in yard failed the map validator")
		failed = true
	if Board.active.backdrop != "deep_space" or MapData.blank("draft", "Draft").backdrop != "deep_space":
		push_error("smoke: deep space is not the default backdrop")
		failed = true
	if Art.backdrop_tex("deep_space") == null or Art.backdrop_tex("space") == null:
		push_error("smoke: backdrop art missing")
		failed = true
	var dock_yard := MapLibrary.load_builtin("side_dock")
	var deep_yard := MapLibrary.load_builtin("deep_yard")
	if dock_yard.backdrop != "deep_space" or deep_yard.backdrop != "deep_space":
		push_error("smoke: built-in yards left the old backdrop")
		failed = true
	if dock_yard.tint_amount > 0.25 or deep_yard.tint_amount > 0.35 or deep_yard.tint == "#b794f0":
		push_error("smoke: dock or deep tint would wash the dark plate")
		failed = true
	if not MapValidator.ok(dock_yard) or not MapValidator.ok(deep_yard):
		push_error("smoke: redesigned yard failed validation")
		failed = true
	if dock_yard.lanes.size() != 2 or deep_yard.lanes.size() != 3:
		push_error("smoke: dock or deep lane count")
		failed = true
	if dock_yard.lanes[0]["cells"].size() != 42 or dock_yard.lanes[1]["cells"].size() != 28:
		push_error("smoke: side dock lanes drifted")
		failed = true
	if deep_yard.lanes[0]["cells"].size() != 32 or deep_yard.lanes[1]["cells"].size() != 32 or deep_yard.lanes[2]["cells"].size() != 27:
		push_error("smoke: deep yard lanes drifted")
		failed = true
	if dock_yard.pods.size() != 8 or deep_yard.pods.size() != 7:
		push_error("smoke: dock or deep pod count")
		failed = true
	var home_pods := {}
	for pod in Board.active.pods:
		home_pods[pod["origin"]] = true
	for yard in [dock_yard, deep_yard]:
		if yard.lanes[0]["cells"] == Board.active.lanes[0]["cells"]:
			push_error("smoke: %s still copies Yard Approach" % yard.id)
			failed = true
		for pod in yard.pods:
			if home_pods.has(pod["origin"]):
				push_error("smoke: %s reused a Yard Approach pod" % yard.id)
				failed = true
	if "Same lanes" in dock_yard.blurb or "Same lanes" in deep_yard.blurb:
		push_error("smoke: yard blurb still says same lanes")
		failed = true
	if absf(dock_yard.hp_scale - 1.1) > 0.001 or absf(deep_yard.hp_scale - 1.18) > 0.001 or absf(deep_yard.speed_scale - 1.06) > 0.001:
		push_error("smoke: yard difficulty scales drifted")
		failed = true
	Board.apply(deep_yard)
	if Board.lane_ids.size() != 3 or Board.lane("c").is_empty() or Board.lane("c")[0] != Vector2i(0, 5):
		push_error("smoke: deep yard did not map lane c")
		failed = true
	if Board.lane("a")[0] != Vector2i(0, 0) or Board.lane("b")[0] != Vector2i(0, 10):
		push_error("smoke: deep yard a/b did not stay on the first two lanes")
		failed = true
	var solo := deep_yard.duplicate_map()
	solo.lanes = [solo.lanes[0]]
	Board.apply(solo)
	if Board.lane("b").is_empty() or Board.lane("b")[0] != Board.lane("a")[0]:
		push_error("smoke: one-lane yard did not reuse lane a for b")
		failed = true
	Board.apply(MapLibrary.load_builtin("yard_approach"))
	if Board.lane_a.size() != 27 or Board.CORE != Vector2i(22, 5) or Board.SLOTS.size() != 36:
		push_error("smoke: yard approach was not restored")
		failed = true
	if MapValidator.ok(MapData.blank("draft", "Draft")):
		push_error("smoke: empty yard should not validate")
		failed = true
	if MapLibrary.save_custom(Board.active) == "":
		push_error("smoke: built-in yard was saved over")
		failed = true
	if MapSession.blocks_scrap():
		push_error("smoke: a normal yard blocked scrap")
		failed = true
	var start_gold: int = Game.gold
	Profile.set_auto_call(true)
	wave._begin_prep(0)
	if not Game.is_first_prep():
		push_error("smoke: auto-call started wave 1")
		failed = true
	wave.call_early()
	if Game.phase != "combat" or Game.wave_index != 0 or Game.gold != start_gold:
		push_error("smoke: Start did not begin wave 1 for free")
		failed = true
	wave._begin_prep(1)
	if Game.phase != "combat" or Game.wave_index != 1 or Game.gold != start_gold + 9:
		push_error("smoke: auto-call skipped the second prep bonus")
		failed = true
	Profile.set_auto_call(false)
	wave._begin_prep(1)
	if Game.phase != "prep" or Game.is_first_prep() or Game.early_bonus() != 9:
		push_error("smoke: later prep lost its countdown bonus")
		failed = true
	hud._refresh_live()
	var later_call: Button = hud.get("call_button")
	var later_status: Label = hud.get("status_label")
	if later_call.text != "Call\n+9g" or "Next in" not in later_status.text:
		push_error("smoke: later prep HUD is not Call")
		failed = true
	var prep_before: float = Game.prep_left
	var scale_before := Engine.time_scale
	var speed_before: float = Game.speed
	var paused_critter = spawn_enemy("fast_skitter", "a")
	var paused_spot: Vector2 = paused_critter.global_position
	toggle_pause()
	var overlay: Control = hud.get("pause_overlay")
	if not get_tree().paused or overlay == null or not overlay.visible:
		push_error("smoke: pause did not freeze the tree")
		failed = true
	if Engine.time_scale != scale_before or Game.speed != speed_before or Game.prep_left != prep_before:
		push_error("smoke: pause changed speed or the prep clock")
		failed = true
	if paused_critter.global_position != paused_spot:
		push_error("smoke: pause moved a critter")
		failed = true
	if overlay == null or overlay.process_mode != Node.PROCESS_MODE_WHEN_PAUSED or overlay.mouse_filter != Control.MOUSE_FILTER_STOP:
		push_error("smoke: pause overlay is not a blocking when-paused layer")
		failed = true
	elif paused_critter.can_process() or wave.can_process() or can_process() or hud.can_process() or not overlay.can_process():
		push_error("smoke: pause left the battle running or slept the overlay")
		failed = true
	var resume := overlay.find_child("Resume", true, false) if overlay else null
	if resume == null or not resume.can_process():
		push_error("smoke: resume control is asleep while paused")
		failed = true
	toggle_pause()
	if get_tree().paused or overlay.visible or not paused_critter.can_process() or not wave.can_process():
		push_error("smoke: resume did not restore the battle")
		failed = true
	if Game.prep_left != prep_before or paused_critter.global_position != paused_spot:
		push_error("smoke: resume did not keep the same moment")
		failed = true
	if Engine.time_scale != scale_before or Game.speed != speed_before:
		push_error("smoke: resume changed the speed")
		failed = true
	paused_critter.alive = false
	paused_critter.queue_free()
	if failed or not Board.validate().is_empty():
		print("SMOKE_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_OK")
		get_tree().quit(0)


func _auto_call() -> void:
	if Game.phase != "prep":
		return
	if not Game.is_first_prep() and Game.prep_left < 1.2:
		return
	if tower_at(Vector2i(1, 2)) == null or tower_at(Vector2i(1, 8)) == null:
		return
	wave.call_early()
