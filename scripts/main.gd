extends Node2D

const TOWER_SCENE := preload("res://scenes/towers/tower.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const SLOT_SCENE := preload("res://scenes/map/build_slot.tscn")

const AUTOPLAY_PLAN: Array = [
	[Vector2i(2, 0), "pea"],
	[Vector2i(2, 10), "pea"],
	[Vector2i(5, 2), "pea"],
	[Vector2i(6, 8), "pea"],
	[Vector2i(15, 8), "glue"],
	[Vector2i(15, 2), "spark"],
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
			KEY_1:
				select_build("pea")
			KEY_2:
				select_build("spark")
			KEY_3:
				select_build("glue")
			KEY_4:
				select_build("boom")
			KEY_5:
				select_build("magnet")
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


func select_build(kind: String) -> void:
	if Game.ended:
		return
	build_kind = "" if build_kind == kind else kind
	selected_cell = null
	_refresh_hover_visuals()
	hud.refresh_all()


func place_tower(cell: Vector2i, kind: String) -> bool:
	if Game.ended or not slots.has(cell):
		return false
	var slot = slots[cell]
	if slot.tower != null:
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
		vfx.float_text(tower.position, "Need scrap", Color("#ffb4c4"))
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
	Game.add_scrap(refund)
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
			vfx.float_text(slot.position, "Need scrap", Color("#ffb4c4"))
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
		print("AUTOPLAY %s wave=%d hp=%d scrap=%d kills=%d leaks=%d" % [
			Game.phase, Game.display_wave(), Game.core_hp, Game.scrap, Game.kills, Game.leaks
		])
		get_tree().quit(0 if Game.phase == "win" else 3)
		return
	auto_clock += delta
	if auto_clock > 520.0:
		print("AUTOPLAY timeout wave=%d hp=%d scrap=%d" % [Game.display_wave(), Game.core_hp, Game.scrap])
		get_tree().quit(4)
		return
	auto_timer -= delta
	if auto_timer > 0.0:
		return
	auto_timer = 0.35
	for step in AUTOPLAY_PLAN:
		var cell: Vector2i = step[0]
		var kind: String = step[1]
		if tower_at(cell) != null:
			continue
		var price := Balance.cost(kind)
		if Game.scrap >= price:
			place_tower(cell, kind)
			return
		if price - Game.scrap > 35:
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
		if Game.scrap < tower.upgrade_cost():
			continue
		if best == null or tower.tier < best.tier:
			best = tower
	return best


func _run_smoke() -> void:
	var failed := false
	if Game.phase != "prep":
		push_error("smoke: expected prep, got %s" % Game.phase)
		failed = true
	if not place_tower(Vector2i(2, 0), "pea"):
		push_error("smoke: could not place Pea Blaster")
		failed = true
	elif Game.scrap != Balance.START_SCRAP - Balance.cost("pea"):
		push_error("smoke: scrap did not drop")
		failed = true
	var squid = spawn_enemy("eye_squid", "a")
	var start_cell: Vector2i = squid.from_cell
	squid._process(0.5)
	if squid.from_cell == start_cell:
		push_error("smoke: Eye-Squid did not hop a cell")
		failed = true
	var before: int = Game.scrap
	squid.take_damage(9999)
	if Game.kills != 1 or Game.scrap <= before:
		push_error("smoke: pop did not pay scrap")
		failed = true
	var toad = spawn_enemy("star_toad", "b")
	var hp_before: int = Game.core_hp
	toad.leak()
	if Game.core_hp != hp_before - 3:
		push_error("smoke: Star-Toad leak damage")
		failed = true
	if place_tower(Vector2i(2, 0), "spark"):
		push_error("smoke: occupied cell accepted a tower")
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
	if tower_at(Vector2i(2, 0)) == null or tower_at(Vector2i(2, 10)) == null:
		return
	wave.call_early()
