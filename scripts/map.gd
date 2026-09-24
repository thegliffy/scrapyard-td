extends Node2D

var highlight_set := {}
var stains: Array = []
var hurt := 0.0
var _stars: Array = []
var _core_tex: Texture2D
var _rift_tex: Texture2D


func _ready() -> void:
	add_to_group("map")
	Board.ensure()
	_core_tex = load("res://assets/sprites/map/core.png")
	_rift_tex = load("res://assets/sprites/map/rift.png")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for _i in 36:
		_stars.append({
			"p": Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720)),
			"r": rng.randf_range(1.4, 3.2),
			"c": Color(1, 0.98, 0.9, rng.randf_range(0.35, 0.7)) if rng.randf() > 0.5 else Color(1, 0.86, 0.95, rng.randf_range(0.3, 0.6)),
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
	draw_rect(Rect2(-80, -80, 1440, 900), Color("#f6ecff"))
	var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.003)
	for star in _stars:
		var color: Color = star["c"]
		color.a *= 0.75 + 0.25 * pulse
		draw_circle(star["p"], star["r"], color)
	var board := Rect2(Board.ORIGIN, Vector2(Board.COLS * Board.TILE, Board.ROWS * Board.TILE))
	draw_rect(Rect2(board.position.x - 10, board.position.y, 10, board.size.y), Color("#eadcff"))
	draw_rect(Rect2(board.position.x + board.size.x, board.position.y, 10, board.size.y), Color("#eadcff"))
	for y in Board.ROWS:
		for x in Board.COLS:
			_draw_cell(Vector2i(x, y))
	_draw_core()
	_draw_rifts()


func _draw_cell(cell: Vector2i) -> void:
	var rect := Board.cell_rect(cell)
	var info: Dictionary = Board.path_info.get(cell, {})
	var lane := str(info.get("lane", ""))
	var fill := Color("#fff6e8") if (cell.x + cell.y) % 2 == 0 else Color("#f3e4ff")
	match lane:
		"a":
			fill = Color("#8fd4ff")
		"b":
			fill = Color("#ffb7dc")
		"both":
			fill = Color("#dcc8ff")
		"core":
			fill = Color("#ffe08a")
	if cell == Board.spawn_a or cell == Board.spawn_b:
		fill = fill.lerp(Color("#e4b0ff"), 0.35)
	var tint_amount := Profile.map_tint_amount()
	if tint_amount > 0.0:
		fill = fill.lerp(Profile.map_tint(), tint_amount)
	draw_rect(rect, fill)
	for stain in stains:
		if stain["cell"] == cell:
			var alpha := clampf(float(stain["life"]) / float(stain["max"]), 0.0, 1.0)
			var color: Color = stain["color"]
			color.a *= alpha
			var inset := rect.grow(-6)
			draw_rect(inset, color)
	if highlight_set.has(cell):
		var tint := Color(1, 0.86, 0.35, 0.38 if lane != "" else 0.22)
		draw_rect(rect, tint)
	var border := Color("#ffffff") if lane != "" else Color("#eadcff")
	draw_rect(rect, border, false, 2.0)
	if lane != "" and lane != "core":
		_draw_arrow(cell, info.get("dir", Vector2i.ZERO))


func _draw_arrow(cell: Vector2i, dir: Vector2i) -> void:
	if dir == Vector2i.ZERO:
		return
	var center := Board.cell_center(cell)
	var forward := Vector2(dir)
	var side := Vector2(-forward.y, forward.x)
	var tip := center + forward * 11.0
	var left := center - forward * 4.0 + side * 6.0
	var right := center - forward * 4.0 - side * 6.0
	draw_colored_polygon(PackedVector2Array([tip, left, right]), Color("#7a5a98"))


func _draw_core() -> void:
	var rect := Board.cell_rect(Board.CORE)
	var center := Board.cell_center(Board.CORE)
	if hurt > 0.0:
		draw_rect(rect, Color(1, 0.35, 0.5, hurt))
	elif Game.core_hp < Game.core_max * 0.35:
		draw_rect(rect, Color(1, 0.4, 0.5, 0.18))
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
