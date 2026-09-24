extends Node2D

var velocity := Vector2.ZERO
var speed_px := 400.0
var damage := 0.0
var splash := 0.0
var slow_factor := 1.0
var slow_time := 0.0
var slow_splash := 0.0
var target = null
var life := 2.4
var kind := "pea"
var color := Color.WHITE
var texture: Texture2D
var impacted := false


func launch(data: Dictionary) -> void:
	kind = str(data.get("kind", "pea"))
	global_position = data["from"]
	target = data.get("target")
	damage = float(data.get("damage", 0))
	splash = float(data.get("splash", 0))
	slow_factor = float(data.get("slow_factor", 1))
	slow_time = float(data.get("slow_time", 0))
	slow_splash = float(data.get("slow_splash", 0))
	speed_px = float(data.get("speed", 10)) * float(Board.TILE)
	color = data.get("color", Color.WHITE)
	texture = Art.projectile_tex(kind)
	var aim := global_position + Vector2.RIGHT
	if is_instance_valid(target):
		aim = target.global_position
	velocity = (aim - global_position).normalized() * speed_px
	rotation = velocity.angle()
	z_index = 220


func _process(delta: float) -> void:
	if impacted or Game.ended:
		queue_free()
		return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if is_instance_valid(target) and target.alive:
		var to: Vector2 = target.global_position - global_position
		if to.length() <= 12.0:
			_impact()
			return
		var desired := to.normalized() * speed_px
		velocity = velocity.lerp(desired, clampf(delta * 9.0, 0.0, 1.0))
	global_position += velocity * delta
	if velocity.length_squared() > 4.0:
		rotation = velocity.angle()
	if is_instance_valid(target) and target.alive and global_position.distance_to(target.global_position) <= 14.0:
		_impact()
	queue_redraw()


func _impact() -> void:
	if impacted:
		return
	impacted = true
	var fx = get_tree().get_first_node_in_group("vfx")
	var hit_pos := global_position
	if is_instance_valid(target) and target.alive:
		hit_pos = target.global_position
	if splash > 0.0:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not _living(enemy):
				continue
			var dist: float = hit_pos.distance_to(enemy.global_position) / float(Board.TILE)
			if dist <= splash:
				enemy.take_damage(damage)
		if fx:
			fx.burst(hit_pos, color, 14)
			for cell in Board.cells_in_range(Board.world_to_cell(hit_pos), splash):
				fx.stain(cell, Color(color.r, color.g, color.b, 0.45), 0.28)
		Sfx.play("boom", randf_range(0.92, 1.05))
	else:
		if _living(target):
			target.take_damage(damage)
			if slow_factor < 0.99:
				target.apply_slow(slow_factor, slow_time)
			if fx:
				fx.burst(hit_pos, color, 6)
				fx.stain(target.current_cell(), Color(color.r, color.g, color.b, 0.4), slow_time if slow_time > 0.0 else 0.18)
		if slow_splash > 0.05:
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy == target or not _living(enemy):
					continue
				var dist: float = hit_pos.distance_to(enemy.global_position) / float(Board.TILE)
				if dist <= slow_splash:
					enemy.apply_slow(slow_factor, slow_time)
	queue_free()


func _living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.alive


func _draw() -> void:
	if texture == null:
		draw_circle(Vector2.ZERO, 6, color)
		return
	var s := 18.0
	draw_texture_rect(texture, Rect2(-s * 0.5, -s * 0.5, s, s), false)
