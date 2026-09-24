extends Node2D

## A lobbed cloud. It sits on a flyer cluster and ticks air-only damage.

var radius := 1.5
var damage := 4.0
var tick := 0.4
var life := 2.0
var wait := 0.12
var texture: Texture2D
var anim := 0.0

## Cloud art's opaque radius inside the 256 canvas.
const _EDGE := 100.0 / 128.0


func setup(at: Vector2, data: Dictionary) -> void:
	global_position = at
	radius = float(data.get("radius", 1.5))
	damage = float(data.get("damage", 4.0))
	tick = float(data.get("tick", 0.4))
	life = float(data.get("linger", 2.0))
	texture = Art.fx_tex("fizz_cloud_tinted")
	z_index = 180
	add_to_group("fizz_clouds")


func _process(delta: float) -> void:
	if Game.ended:
		queue_free()
		return
	anim += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	wait -= delta
	if wait <= 0.0:
		wait += tick
		_tick()
	queue_redraw()


func _tick() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy.alive:
			continue
		if not bool(enemy.flying):
			continue
		var dist: float = global_position.distance_to(enemy.global_position) / float(Board.TILE)
		if dist <= radius + 0.05:
			enemy.take_damage(damage)


func _draw() -> void:
	if texture == null:
		return
	var pulse := 1.0 + sin(anim * 5.0) * 0.04
	var span := radius * float(Board.TILE) / _EDGE * pulse
	var fade := clampf(life / 0.35, 0.0, 1.0)
	draw_texture_rect(texture, Rect2(-span, -span, span * 2.0, span * 2.0), false, Color(1, 1, 1, 0.92 * fade))
