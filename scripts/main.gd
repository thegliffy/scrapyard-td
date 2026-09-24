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
			KEY_ESCAPE:
				build_kind = ""
				selected_cell = null
				_refresh_hover_visuals()
				hud.refresh_all()
			KEY_R:
				if Game.ended:
					restart()


func restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


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
	if Profile.battle_scrap(false, 99) != 1 or Profile.battle_scrap(false, 0) != 1:
		push_error("smoke: loss scrap is not flat 1")
		failed = true
	if Profile.battle_scrap(true, 21) != 42 or Profile.battle_scrap(true, 100) != 200 or Profile.battle_scrap(true, 0) != 0:
		push_error("smoke: win scrap is not 2 per wave cleared")
		failed = true
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
	if Profile.GUN_ORDER.size() != 10 or int(Profile.GUN_COST["flak"]) != 45 or int(Profile.GUN_COST["orbit"]) != 90:
		push_error("smoke: gun roster or scrap costs")
		failed = true
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
	if MapValidator.ok(MapData.blank("draft", "Draft")):
		push_error("smoke: empty yard should not validate")
		failed = true
	if MapLibrary.save_custom(Board.active) == "":
		push_error("smoke: built-in yard was saved over")
		failed = true
	if MapSession.blocks_scrap():
		push_error("smoke: a normal yard blocked scrap")
		failed = true
	if failed or not Board.validate().is_empty():
		print("SMOKE_FAIL")
		get_tree().quit(1)
	else:
		print("SMOKE_OK")
		get_tree().quit(0)


func _auto_call() -> void:
	if Game.phase != "prep" or Game.prep_left < 1.2:
		return
	if tower_at(Vector2i(1, 2)) == null or tower_at(Vector2i(1, 8)) == null:
		return
	wave.call_early()
