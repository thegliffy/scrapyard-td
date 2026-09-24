extends Node2D

var pops: Array = []
var texts: Array = []
var bolts: Array = []


func _ready() -> void:
	add_to_group("vfx")
	z_index = 400


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
	for item in texts:
		var alpha := clampf(float(item["life"]) / float(item["max"]), 0.0, 1.0)
		var color: Color = item["color"]
		color.a = alpha
		var text := str(item["text"])
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var pos: Vector2 = item["p"] - Vector2(width * 0.5, 0)
		draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.1, 0.06, 0.18, alpha))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
