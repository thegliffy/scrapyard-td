extends Node2D

var pops: Array = []
var texts: Array = []
var bolts: Array = []
var rings: Array = []
var _stomp_tex: Texture2D
var _nova_tex: Texture2D


func _ready() -> void:
	add_to_group("vfx")
	z_index = 400
	_stomp_tex = Art.fx_tex("stomp_ring_tinted")
	_nova_tex = Art.fx_tex("nova_ring_tinted")


## Outer artwork sits inside the 256 canvas, not on the edge.
const _STOMP_EDGE := 117.0 / 128.0
const _NOVA_EDGE := 111.0 / 128.0


func stomp_ring(pos: Vector2, radius_tiles: float) -> void:
	var reach := radius_tiles * float(Board.TILE) / _STOMP_EDGE
	rings.append({
		"p": pos,
		"tex": _stomp_tex,
		"reach": reach,
		"flat": 1.0, # the painted ring is already a flat ellipse
		"life": 0.38,
		"max": 0.38,
	})


func nova_ring(pos: Vector2, radius_tiles: float) -> void:
	var reach := radius_tiles * float(Board.TILE) / _NOVA_EDGE
	rings.append({
		"p": pos,
		"tex": _nova_tex,
		"reach": reach,
		"flat": 1.0,
		"life": 0.5,
		"max": 0.5,
	})


func burst(pos: Vector2, color: Color, count: int = 8) -> void:
	for _i in count:
		var angle := randf() * TAU
		var speed := randf_range(28.0, 110.0)
		pops.append({
			"p": pos,
			"v": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.22, 0.48),
			"max": 0.48,
			"color": color,
			"r": randf_range(2.5, 6.0),
		})


func float_text(pos: Vector2, text: String, color: Color) -> void:
	texts.append({
		"p": pos,
		"text": text,
		"life": 0.85,
		"max": 0.85,
		"color": color,
	})


func lightning(points: PackedVector2Array, color: Color) -> void:
	if points.size() < 2:
		return
	var jagged := PackedVector2Array()
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		jagged.append(a)
		var mid := (a + b) * 0.5
		var tangent := b - a
		var normal := Vector2(-tangent.y, tangent.x).normalized()
		if normal == Vector2.ZERO:
			normal = Vector2.UP
		jagged.append(mid + normal * randf_range(-12.0, 12.0))
	jagged.append(points[points.size() - 1])
	bolts.append({"pts": jagged, "life": 0.18, "max": 0.18, "color": color})


func stain(cell: Vector2i, color: Color, life: float) -> void:
	var map := get_tree().get_first_node_in_group("map")
	if map and map.has_method("add_stain"):
		map.add_stain(cell, color, life)


func _process(delta: float) -> void:
	var next_pops: Array = []
	for pop in pops:
		pop["life"] = float(pop["life"]) - delta
		pop["p"] = pop["p"] + pop["v"] * delta
		pop["v"] = pop["v"] * 0.9
		if float(pop["life"]) > 0.0:
			next_pops.append(pop)
	pops = next_pops
	var next_texts: Array = []
	for item in texts:
		item["life"] = float(item["life"]) - delta
		item["p"] = item["p"] + Vector2(0, -32) * delta
		if float(item["life"]) > 0.0:
			next_texts.append(item)
	texts = next_texts
	var next_bolts: Array = []
	for bolt in bolts:
		bolt["life"] = float(bolt["life"]) - delta
		if float(bolt["life"]) > 0.0:
			next_bolts.append(bolt)
	bolts = next_bolts
	var next_rings: Array = []
	for ring in rings:
		ring["life"] = float(ring["life"]) - delta
		if float(ring["life"]) > 0.0:
			next_rings.append(ring)
	rings = next_rings
	queue_redraw()


func _draw() -> void:
	var font := Art.ui_font()
	for pop in pops:
		var alpha := clampf(float(pop["life"]) / float(pop["max"]), 0.0, 1.0)
		var color: Color = pop["color"]
		color.a = alpha
		draw_circle(pop["p"], float(pop["r"]) * (0.5 + alpha), color)
	for bolt in bolts:
		var alpha := clampf(float(bolt["life"]) / float(bolt["max"]), 0.0, 1.0)
		var color: Color = bolt["color"]
		color.a = alpha
		var pale := color
		pale.a = alpha * 0.45
		draw_polyline(bolt["pts"], pale, 7.0, true)
		draw_polyline(bolt["pts"], color, 3.0, true)
	for ring in rings:
		var tex: Texture2D = ring["tex"]
		if tex == null:
			continue
		var alpha := clampf(float(ring["life"]) / float(ring["max"]), 0.0, 1.0)
		var grow := 1.0 - alpha
		var span := float(ring["reach"]) * lerpf(0.28, 1.0, grow)
		var flat := float(ring["flat"])
		draw_set_transform(ring["p"], 0.0, Vector2.ONE)
		draw_texture_rect(tex, Rect2(-span, -span * flat, span * 2.0, span * 2.0 * flat), false, Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for item in texts:
		var alpha := clampf(float(item["life"]) / float(item["max"]), 0.0, 1.0)
		var color: Color = item["color"]
		color.a = alpha
		var text := str(item["text"])
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var pos: Vector2 = item["p"] - Vector2(width * 0.5, 0)
		draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.1, 0.06, 0.18, alpha))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
