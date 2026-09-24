extends Node2D

var highlight_set := {}
var stains: Array = []
var hurt := 0.0
var _twinkles: Array = []
var _space_tex: Texture2D
var _core_island_tex: Texture2D
var _core_tex: Texture2D
var _rift_tex: Texture2D


func _ready() -> void:
	add_to_group("map")
	Board.ensure()
	_space_tex = Art.map_tex("space")
	_core_island_tex = Art.map_tex("core_island")
	_core_tex = Art.map_tex("core")
	_rift_tex = Art.map_tex("rift")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for _i in 28:
		_twinkles.append({
			"p": Vector2(rng.randf_range(8, 1272), rng.randf_range(8, 700)),
			"phase": rng.randf_range(0.0, TAU),
		})
	if Game.has_signal("core_hit"):
		Game.core_hit.connect(func(_amount): hurt = 0.4)


func set_highlights(cells: Array) -> void:
	highlight_set = {}
	for cell in cells:
		highlight_set[cell] = true
	queue_redraw()


func add_stain(cell: Vector2i, color: Color, life: float) -> void:
	stains.append({"cell": cell, "color": color, "life": life, "max": life})
	if stains.size() > 140:
		stains.pop_front()


func _process(delta: float) -> void:
	if hurt > 0.0:
		hurt = max(0.0, hurt - delta)
	var kept: Array = []
	for stain in stains:
		stain["life"] = float(stain["life"]) - delta
		if float(stain["life"]) > 0.0:
			kept.append(stain)
	stains = kept
	queue_redraw()


func _draw() -> void:
	Board.ensure()
	_draw_space()
	for y in Board.ROWS:
		for x in Board.COLS:
			_draw_cell(Vector2i(x, y))
	_draw_roads()
	for y in Board.ROWS:
		for x in Board.COLS:
			_draw_cell_overlay(Vector2i(x, y))
	_draw_core()
	_draw_rifts()


func _draw_space() -> void:
	var view := Rect2(0, 0, 1280, 720)
	var tint_amount := Profile.map_tint_amount()
	var mod := Color.WHITE
	if tint_amount > 0.0:
		mod = Color.WHITE.lerp(Profile.map_tint(), tint_amount)
	if _space_tex:
		draw_texture_rect(_space_tex, view, false, mod)
	else:
		draw_rect(view, Color("#7a58b8"))
	var time := Time.get_ticks_msec() * 0.001
	for star in _twinkles:
		var alpha := 0.25 + 0.55 * (0.5 + 0.5 * sin(time * 2.2 + float(star["phase"])))
		draw_circle(star["p"], 1.6, Color(1, 0.98, 0.92, alpha))


func _draw_cell(cell: Vector2i) -> void:
	var rect := Board.cell_rect(cell)
	var lane := str(Board.path_info.get(cell, {}).get("lane", ""))
	draw_rect(rect, Color(1, 1, 1, 0.05))
	draw_rect(rect, Color(1, 1, 1, 0.14), false, 1.0)
	if lane == "":
		return
	var wash := Color("#7ad8ff")
	match lane:
		"b":
			wash = Color("#ff9ec8")
		"both", "core":
			wash = Color("#e4c4ff")
	wash.a = 0.16
	draw_rect(rect, wash)


func _draw_cell_overlay(cell: Vector2i) -> void:
	var rect := Board.cell_rect(cell)
	var info: Dictionary = Board.path_info.get(cell, {})
	var lane := str(info.get("lane", ""))
	for stain in stains:
		if stain["cell"] == cell:
			var alpha := clampf(float(stain["life"]) / float(stain["max"]), 0.0, 1.0)
			var color: Color = stain["color"]
			color.a *= alpha
			draw_rect(rect.grow(-8), color)
	if highlight_set.has(cell):
		var tint := Color(1, 0.9, 0.45, 0.28 if lane == "" else 0.2)
		draw_rect(rect, tint)
		draw_rect(rect, Color("#fff1a8"), false, 2.0)
	if lane != "" and lane != "core" and (cell.x + cell.y) % 2 == 0:
		_draw_arrow(cell, info.get("dir", Vector2i.ZERO))


func _draw_roads() -> void:
	var shared := _shared_count()
	var north: Array = Board.lane_a
	var south: Array = Board.lane_b
	var join_a := north.size() - shared
	var join_b := south.size() - shared
	_ribbon(_centers(north, 0, join_a), Color("#3ecfff"))
	_ribbon(_centers(south, 0, join_b), Color("#ff86c4"))
	if shared > 0:
		_ribbon(_centers(north, join_a, north.size() - 1), Color("#e7c6ff"))


func _shared_count() -> int:
	var north: Array = Board.lane_a
	var south: Array = Board.lane_b
	var count := 0
	while count < north.size() and count < south.size():
		if north[north.size() - 1 - count] != south[south.size() - 1 - count]:
			break
		count += 1
	return count


func _centers(cells: Array, start: int, end_inclusive: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var last := mini(end_inclusive, cells.size() - 1)
	for i in range(maxi(start, 0), last + 1):
		points.append(Board.cell_center(cells[i]))
	return points


func _ribbon(points: PackedVector2Array, color: Color) -> void:
	if points.size() < 2:
		return
	var edge := Color("#3a2460")
	edge.a = 0.55
	_stroke(points, edge, 26.0)
	var body := color
	body.a = 0.95
	_stroke(points, body, 16.0)
	_stroke(points, Color(1, 1, 1, 0.82), 5.0)


func _stroke(points: PackedVector2Array, color: Color, width: float) -> void:
	var radius := width * 0.5
	for point in points:
		draw_circle(point, radius, color)
	draw_polyline(points, color, width, true)


func _draw_arrow(cell: Vector2i, dir: Vector2i) -> void:
	if dir == Vector2i.ZERO:
		return
	var center := Board.cell_center(cell)
	var forward := Vector2(dir)
	var side := Vector2(-forward.y, forward.x)
	var tip := center + forward * 11.0
	var left := center - forward * 4.0 + side * 6.0
	var right := center - forward * 4.0 - side * 6.0
	draw_colored_polygon(PackedVector2Array([
		center + forward * 13.0,
		center - forward * 6.0 + side * 8.0,
		center - forward * 6.0 - side * 8.0,
	]), Color(0.25, 0.12, 0.4, 0.45))
	draw_colored_polygon(PackedVector2Array([tip, left, right]), Color("#fffaf4"))


func _draw_core() -> void:
	var rect := Board.cell_rect(Board.CORE)
	var center := Board.cell_center(Board.CORE)
	if _core_island_tex:
		var isle := 78.0
		draw_texture_rect(_core_island_tex, Rect2(center.x - isle * 0.5, center.y - isle * 0.42, isle, isle), false)
	if hurt > 0.0:
		draw_rect(rect, Color(1, 0.35, 0.5, hurt * 0.7))
	elif Game.core_hp < Game.core_max * 0.35:
		draw_circle(center, 20.0, Color(1, 0.4, 0.5, 0.22))
	if _core_tex:
		var pulse := 42.0 + sin(Time.get_ticks_msec() * 0.005) * 1.5
		draw_texture_rect(_core_tex, Rect2(center.x - pulse * 0.5, center.y - pulse * 0.5, pulse, pulse), false)


func _draw_rifts() -> void:
	if _rift_tex == null:
		return
	for cell in [Board.spawn_a, Board.spawn_b]:
		var center := Board.cell_center(cell)
		var s := 36.0
		draw_texture_rect(_rift_tex, Rect2(center.x - s * 0.5, center.y - s * 0.5, s, s), false, Color(1, 1, 1, 0.92))
