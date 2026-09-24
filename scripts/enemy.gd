extends Node2D

var kind := ""
var display_name := ""
var path: Array = []
var from_cell := Vector2i.ZERO
var to_cell := Vector2i.ZERO
var step_index := 1
var hop_t := 0.0
var hp := 1.0
var max_hp := 1.0
var shield := 0.0
var max_shield := 0.0
var speed := 1.0
var gold := 0
var leak_damage := 1
var alive := true
var slow_factor := 1.0
var slow_left := 0.0
var hit_flash := 0.0
var anim := 0.0
var fit := 0.3
var skitter := false
var split_into := 0
var split_kind := ""
var baby_every := 0.0
var baby_count := 0
var baby_timer := 0.0
var tint := Color.WHITE
var body_color := Color.WHITE
var texture: Texture2D
var is_boss := false
var flying := false
var minion_kind := ""

const FLY_LIFT := 28.0


func setup(kind_id: String, path_cells: Array, start_index: int = 0, hop: float = 0.0, tint_color: Color = Color.WHITE) -> void:
	kind = kind_id
	var data := Balance.enemy(kind_id)
	display_name = str(data["name"])
	path = path_cells
	var wave_n := 1
	if Game.wave_index >= 0:
		wave_n = Game.wave_index + 1
	var hp_scale := Profile.map_hp_scale() * Balance.wave_hp_scale(wave_n)
	if bool(data.get("boss", false)):
		hp_scale *= Balance.boss_hp_scale(wave_n)
	max_hp = float(data["hp"]) * hp_scale
	hp = max_hp
	max_shield = float(data["shield"]) * hp_scale
	shield = max_shield
	speed = float(data["speed"]) * Profile.map_speed_scale()
	gold = int(data["gold"])
	leak_damage = int(data["leak"])
	fit = float(data["display"]) / float(data["tex"])
	skitter = bool(data["skitter"])
	split_into = int(data["split"])
	split_kind = str(data["split_kind"])
	baby_every = float(data["baby_every"])
	baby_count = int(data["babies"])
	baby_timer = baby_every
	is_boss = bool(data.get("boss", false))
	flying = bool(data.get("flying", false))
	minion_kind = str(data.get("minion_kind", ""))
	tint = tint_color
	body_color = Color(str(data["color"]))
	texture = Art.enemy_tex(kind)
	add_to_group("enemies")
	if is_boss:
		add_to_group("boss")
	if path.size() < 2:
		global_position = Board.cell_center(Board.CORE)
		leak()
		return
	var index := clampi(start_index, 0, path.size() - 2)
	from_cell = path[index]
	step_index = index + 1
	to_cell = path[step_index]
	hop_t = clampf(hop, 0.0, 0.95)
	_place_on_path()
	z_index = _z_for(from_cell)
	Profile.mark_seen(kind)
	queue_redraw()


func current_cell() -> Vector2i:
	if hop_t >= 0.55:
		return to_cell
	return from_cell


func tiles_remaining() -> float:
	var visual := _step_curve(hop_t)
	var after := path.size() - 1 - step_index
	return float(after) + (1.0 - visual)


func apply_slow(factor: float, duration: float) -> void:
	if not alive:
		return
	if slow_left <= 0.0 or factor < slow_factor:
		slow_factor = factor
	slow_left = max(slow_left, duration)


func take_damage(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	var left := amount
	if shield > 0.0:
		var absorbed := minf(shield, left)
		shield -= absorbed
		left -= absorbed
		if shield <= 0.0:
			shield = 0.0
			_break_shield()
	if left > 0.0:
		hp -= left
		hit_flash = 0.12
	else:
		hit_flash = 0.08
	if hp <= 0.0:
		die()


func die() -> void:
	if not alive:
		return
	alive = false
	Game.register_kill(gold)
	var fx = _fx()
	if fx:
		fx.burst(global_position, body_color, 12 if not is_boss else 24)
		fx.float_text(global_position + Vector2(0, -20), "+%d" % gold, Color("#ffe08a"))
		fx.stain(current_cell(), Color(body_color.r, body_color.g, body_color.b, 0.45), 0.25)
	Sfx.play("pop", randf_range(0.9, 1.15) if not is_boss else 0.75)
	for tower in get_tree().get_nodes_in_group("towers"):
		if is_instance_valid(tower) and tower.has_method("notify_kill"):
			tower.notify_kill(global_position)
	_spawn_splits()
	queue_free()


func leak() -> void:
	if not alive:
		return
	alive = false
	global_position = Board.cell_center(Board.CORE)
	var fx = _fx()
	if fx:
		fx.burst(global_position, Color("#ff8ab0"), 16)
		fx.float_text(global_position + Vector2(0, -28), "-%d" % leak_damage, Color("#ffb4c8"))
		fx.stain(Board.CORE, Color(1, 0.42, 0.55, 0.6), 0.45)
	Game.damage_core(leak_damage)
	queue_free()


func _process(delta: float) -> void:
	if not alive or Game.ended:
		return
	anim += delta
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)
	if slow_left > 0.0:
		slow_left -= delta
		if slow_left <= 0.0:
			slow_factor = 1.0
	hop_t += speed * slow_factor * delta
	while hop_t >= 1.0 and alive:
		hop_t -= 1.0
		from_cell = to_cell
		if from_cell == Board.CORE:
			global_position = Board.cell_center(Board.CORE)
			leak()
			return
		step_index += 1
		if step_index >= path.size():
			leak()
			return
		to_cell = path[step_index]
	_place_on_path()
	z_index = _z_for(current_cell())
	if baby_every > 0.0:
		baby_timer -= delta
		if baby_timer <= 0.0:
			baby_timer = baby_every
			_spawn_minions()
	queue_redraw()


func _place_on_path() -> void:
	var visual := _step_curve(hop_t)
	var pos := Board.cell_center(from_cell).lerp(Board.cell_center(to_cell), visual)
	if flying:
		pos.y -= FLY_LIFT
	global_position = pos


func _z_for(cell: Vector2i) -> int:
	var z := 120 + cell.y
	if flying:
		z += 30
	if is_boss:
		z += 40
	return z


func _step_curve(t: float) -> float:
	# Sit on the cell, then hop to the next. Gameplay stays on the grid line.
	if t < 0.2:
		return 0.0
	var u := clampf((t - 0.2) / 0.8, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _cell_index() -> int:
	if hop_t >= 0.55:
		return mini(step_index, path.size() - 1)
	return maxi(0, step_index - 1)


func _spawn_splits() -> void:
	if split_into <= 0 or split_kind == "":
		return
	var root := get_tree().get_first_node_in_group("game_root")
	if root == null:
		return
	var origin := _cell_index()
	var tints := [Color("#ffffff"), Color("#ffe7b0"), Color("#fff4d0")]
	for i in split_into:
		var back := maxi(0, origin - i)
		if back >= path.size() - 1:
			continue
		root.spawn_enemy(split_kind, "", path, back, 0.12 * i, tints[i % tints.size()])


func _spawn_minions() -> void:
	if minion_kind == "":
		return
	var root := get_tree().get_first_node_in_group("game_root")
	if root == null:
		return
	var origin := _cell_index()
	for i in baby_count:
		var back := maxi(0, origin - 1 - i)
		if back >= path.size() - 1:
			continue
		root.spawn_enemy(minion_kind, "", path, back, 0.0, Color("#ffe7b0"))


func _break_shield() -> void:
	Sfx.play("shield")
	var fx = _fx()
	if fx:
		fx.burst(global_position, Color("#9aefff"), 10)


func _fx():
	return get_tree().get_first_node_in_group("vfx")


func _draw() -> void:
	if flying:
		draw_set_transform(Vector2(0, FLY_LIFT), 0, Vector2(1.25, 0.42))
		draw_circle(Vector2.ZERO, 12 if not is_boss else 22, Color(0, 0, 0, 0.2))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	else:
		draw_set_transform(Vector2(0, 10), 0, Vector2(1.2, 0.42))
		draw_circle(Vector2.ZERO, 14 if not is_boss else 26, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var spin := sin(anim * (15.0 if skitter else 2.4)) * (0.2 if skitter else 0.045)
	var squash_y := 0.82 if hop_t > 0.82 else 1.0
	var squash_x := 1.0 + (1.0 - squash_y) * 0.8
	draw_set_transform(Vector2.ZERO, spin, Vector2(squash_x, squash_y))
	if texture:
		var w := texture.get_width() * fit
		var h := texture.get_height() * fit
		var mod := tint
		if slow_left > 0.0:
			mod = mod.lerp(Color("#b8ffd8"), 0.45)
		if hit_flash > 0.0:
			mod = mod.lerp(Color(1.6, 0.85, 0.9), clampf(hit_flash * 5.0, 0.0, 1.0))
		draw_texture_rect(texture, Rect2(-w * 0.5, -h * 0.5, w, h), false, mod)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# Glass bubble from the roster sheet. Boss shield stays a bar, not a second bubble.
	if shield > 0.0 and max_shield > 0.0 and not is_boss:
		var radius := 24.0 * (1.0 + sin(anim * 3.2) * 0.035)
		draw_circle(Vector2.ZERO, radius, Color(0.62, 0.93, 1.0, 0.2))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 36, Color("#d7f7ff"), 2.8, true)
		draw_arc(Vector2.ZERO, radius * 0.92, -0.9, 0.85, 12, Color(1, 1, 1, 0.9), 2.0, true)
		for i in 5:
			var angle := anim * 0.6 + float(i) * TAU / 5.0
			draw_circle(Vector2(cos(angle), sin(angle)) * radius, 2.1, Color("#fff6c8"))
	_draw_bar()


func _draw_bar() -> void:
	var width := 34.0 if not is_boss else 56.0
	var y := -28.0 if not is_boss else -48.0
	if hp >= max_hp and shield >= max_shield and not is_boss and kind != "chunky_tank":
		return
	draw_rect(Rect2(-width * 0.5, y, width, 4), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-width * 0.5, y, width * clampf(hp / max_hp, 0, 1), 4), Color("#7dffb0"))
	if max_shield > 0.0:
		draw_rect(Rect2(-width * 0.5, y - 4, width, 3), Color(0, 0, 0, 0.45))
		draw_rect(Rect2(-width * 0.5, y - 4, width * clampf(shield / max_shield, 0, 1), 3), Color("#9aefff"))
