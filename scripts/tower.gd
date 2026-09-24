extends Node2D

const PROJECTILE_SCENE := preload("res://scenes/projectiles/projectile.tscn")

var kind := ""
var tier := 1
var invested := 0
var cell := Vector2i.ZERO
var cooldown := 0.0
var magnet_wait := 1.2
var recoil := 0.0
var anim := 0.0
var texture: Texture2D


func setup(kind_id: String, at: Vector2i, spent: int) -> void:
	kind = kind_id
	cell = at
	invested = spent
	position = Board.cell_center(at)
	texture = Art.tower_tex(kind)
	add_to_group("towers")
	z_index = 110 + cell.y
	queue_redraw()


func range_tiles() -> float:
	return Balance.tier_value(kind, "range", tier)


func upgrade_cost() -> int:
	return Balance.upgrade_cost(kind, tier)


func refresh_visual() -> void:
	queue_redraw()


func notify_kill(at: Vector2) -> void:
	if kind != "magnet" or Game.ended:
		return
	var dist := global_position.distance_to(at) / float(Board.TILE)
	if dist > range_tiles():
		return
	var bonus := int(Balance.tier_value(kind, "bonus", tier))
	if bonus <= 0:
		return
	Game.add_gold(bonus)
	var fx = get_tree().get_first_node_in_group("vfx")
	if fx:
		fx.float_text(global_position + Vector2(8, -16), "+%d" % bonus, Color("#fff1b0"))


func _process(delta: float) -> void:
	if Game.ended:
		return
	anim += delta
	if recoil > 0.0:
		recoil = max(0.0, recoil - delta)
	if kind == "magnet":
		magnet_wait -= delta
		if magnet_wait <= 0.0:
			magnet_wait = Balance.tier_value(kind, "income_every", tier)
			var gain := int(Balance.tier_value(kind, "income", tier))
			Game.add_gold(gain)
			var fx = get_tree().get_first_node_in_group("vfx")
			if fx:
				fx.float_text(global_position + Vector2(0, -18), "+%d" % gain, Color("#ffe08a"))
			Sfx.play("scrap", randf_range(0.96, 1.04))
		queue_redraw()
		return
	cooldown -= delta
	if cooldown <= 0.0:
		var target = _pick_target()
		if target != null:
			_shoot(target)
			cooldown = 1.0 / Balance.tier_value(kind, "rate", tier)
	queue_redraw()


func _pick_target():
	var best = null
	var best_left := 100000.0
	var boss = null
	var reach := range_tiles()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _living(enemy) or not _can_hit(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position) / float(Board.TILE)
		if dist > reach + 0.05:
			continue
		if enemy.is_in_group("boss"):
			boss = enemy
		var left: float = enemy.tiles_remaining()
		if left < best_left:
			best_left = left
			best = enemy
	# Focus Big Cute Boss unless something else is about to cuddle the core.
	if boss != null and best != null and boss.tiles_remaining() < best_left + 3.5:
		return boss
	return best


func _shoot(target) -> void:
	recoil = 0.12
	if kind == "spark":
		_shoot_spark(target)
		return
	if kind == "stomper" or kind == "nova":
		_pulse(target)
		return
	if kind == "fizz":
		_lob_fizz()
		return
	var fx_parent := get_tree().get_first_node_in_group("projectiles")
	if fx_parent == null:
		fx_parent = get_parent()
	var shot = PROJECTILE_SCENE.instantiate()
	fx_parent.add_child(shot)
	var slow := 1.0
	var slow_for := 0.0
	var slow_radius := 0.0
	var splash := 0.0
	var color := Color("#b6e86a")
	var layer := Balance.tower_target(kind)
	var slow_layer := layer
	if kind == "glue" or kind == "net":
		slow = Balance.tier_value(kind, "slow", tier)
		slow_for = Balance.tier_value(kind, "slow_time", tier)
		slow_radius = Balance.tier_value(kind, "slow_splash", tier)
		color = Color("#5ee0d4") if kind == "glue" else Color("#b6f0c0")
		if kind == "net" and tier >= 3:
			slow_layer = "both"
		Sfx.play("glue", randf_range(0.94, 1.06))
	elif kind == "boom" or kind == "flak" or kind == "orbit":
		splash = Balance.tier_value(kind, "splash", tier)
		color = Color("#ff9848") if kind != "orbit" else Color("#ffe08a")
		Sfx.play("boom", randf_range(0.92, 1.05))
	elif kind == "dual":
		color = Color("#ffd0ea")
		Sfx.play("spark", randf_range(0.96, 1.08))
	else:
		Sfx.play("pea", randf_range(0.94, 1.08))
	shot.launch({
		"kind": kind,
		"from": global_position,
		"target": target,
		"damage": Balance.tier_value(kind, "damage", tier),
		"splash": splash,
		"slow_factor": slow,
		"slow_time": slow_for,
		"slow_splash": slow_radius,
		"speed": Balance.tier_value(kind, "shot_speed", tier) if kind != "spark" else 10.0,
		"color": color,
		"layer": layer,
		"slow_layer": slow_layer,
	})


func _pulse(_target) -> void:
	var radius := range_tiles()
	var layer := Balance.tower_target(kind)
	var amount := Balance.tier_value(kind, "damage", tier)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _living(enemy) or not Balance.layer_matches(layer, bool(enemy.flying)):
			continue
		var dist: float = global_position.distance_to(enemy.global_position) / float(Board.TILE)
		if dist <= radius + 0.05:
			enemy.take_damage(amount)
	var fx = get_tree().get_first_node_in_group("vfx")
	if kind == "stomper":
		if fx:
			fx.stomp_ring(global_position, radius)
		Sfx.play("boom", randf_range(0.78, 0.9))
	else:
		if fx:
			fx.nova_ring(global_position, radius)
		Sfx.play("spark", randf_range(0.7, 0.84))


func _lob_fizz() -> void:
	var reach := range_tiles()
	var cluster: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _living(enemy) or not bool(enemy.flying):
			continue
		var dist: float = global_position.distance_to(enemy.global_position) / float(Board.TILE)
		if dist <= reach + 0.05:
			cluster.append(enemy)
	if cluster.is_empty():
		return
	var aim := Vector2.ZERO
	for enemy in cluster:
		aim += enemy.global_position
	aim /= float(cluster.size())
	var cloud := Node2D.new()
	cloud.set_script(load("res://scripts/fizz_cloud.gd"))
	var parent := get_tree().get_first_node_in_group("projectiles")
	if parent == null:
		parent = get_parent()
	parent.add_child(cloud)
	cloud.setup(aim, {
		"radius": Balance.tier_value(kind, "radius", tier),
		"damage": Balance.tier_value(kind, "damage", tier),
		"tick": Balance.tier_value(kind, "tick", tier),
		"linger": Balance.tier_value(kind, "linger", tier),
	})
	Sfx.play("glue", randf_range(1.08, 1.2))


func _shoot_spark(first) -> void:
	var hits: Array = [first]
	var current = first
	var jumps := int(Balance.tier_value(kind, "chains", tier))
	var chain_reach := Balance.tier_value(kind, "chain_range", tier)
	for _i in jumps:
		var nxt = _nearest(current, hits, chain_reach)
		if nxt == null:
			break
		hits.append(nxt)
		current = nxt
	var points := PackedVector2Array()
	points.append(global_position)
	var amount := Balance.tier_value(kind, "damage", tier)
	var falloff := Balance.tier_value(kind, "falloff", tier)
	var fx = get_tree().get_first_node_in_group("vfx")
	for enemy in hits:
		if _living(enemy):
			points.append(enemy.global_position)
			enemy.take_damage(amount)
			if fx and _living(enemy):
				fx.stain(enemy.current_cell(), Color(0.7, 0.95, 1, 0.45), 0.16)
		amount *= falloff
	if fx:
		fx.lightning(points, Color("#fff1a0"))
	Sfx.play("spark", randf_range(0.92, 1.08))


func _nearest(from_enemy, excluded: Array, reach: float):
	var best = null
	var best_dist := reach
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy in excluded or not _living(enemy) or not _can_hit(enemy):
			continue
		var dist: float = from_enemy.global_position.distance_to(enemy.global_position) / float(Board.TILE)
		if dist <= best_dist and dist > 0.05:
			best_dist = dist
			best = enemy
	return best


func _living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.alive


func _can_hit(enemy) -> bool:
	return Balance.can_hit(kind, str(enemy.kind))


func _draw() -> void:
	draw_set_transform(Vector2(0, 12), 0, Vector2(1.1, 0.4))
	draw_circle(Vector2.ZERO, 12, Color(0.55, 0.35, 0.7, 0.16))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var squash := 1.0 - recoil * 1.4
	var widen := 1.0 + recoil
	draw_set_transform(Vector2(0, recoil * 6.0), sin(anim * 2.0) * 0.03, Vector2(widen, squash))
	if texture:
		var scale := (40.0 + float(tier - 1) * 3.0) / float(texture.get_width())
		var w := texture.get_width() * scale
		var h := texture.get_height() * scale
		draw_texture_rect(texture, Rect2(-w * 0.5, -h * 0.5, w, h), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	for i in 3:
		var pip := Vector2(-10 + i * 10, 18)
		var on := i < tier
		draw_circle(pip, 3.2, Color("#ffe08a") if on else Color(1, 1, 1, 0.55))
		draw_arc(pip, 3.2, 0, TAU, 10, Color("#c9844a"), 1.2, true)
