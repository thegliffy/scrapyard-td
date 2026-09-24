class_name MapView
extends Node2D

## Draws whatever Board.apply last loaded. Battle and the map editor share
## this so the neon road, islands, and core island cannot drift apart.

var highlight_set := {}
var stains: Array = []
var hurt := 0.0
var show_slot_marks := false
var hover_cell := Vector2i(-99, -99)
## Battle flashes the core from Game. The editor turns this off so a finished
## playtest cannot leave the editing core looking damaged.
var live_core := true

var _space_tex: Texture2D
var _path_tex: Texture2D
var _core_island_tex: Texture2D
var _core_tex: Texture2D
var _rift_tex: Texture2D
var _islands := {}


func _ready() -> void:
	_space_tex = Art.map_tex("space")
	_path_tex = Art.map_tex("path_tile")
	_core_island_tex = Art.map_tex("core_island")
	_core_tex = Art.map_tex("core")
	_rift_tex = Art.map_tex("rift")
	_islands = {
		"pink": Art.map_tex("island_a"),
		"teal": Art.map_tex("island_b"),
		"crystal": Art.map_tex("island_c"),
	}


func _draw() -> void:
	Board.ensure()
	_draw_space()
	for y in Board.ROWS:
		for x in Board.COLS:
			_draw_cell(Vector2i(x, y))
	_draw_roads()
	_draw_islands()
	_draw_core()
	_draw_rifts()
	for y in Board.ROWS:
		for x in Board.COLS:
			_draw_cell_overlay(Vector2i(x, y))
	if show_slot_marks:
		_draw_slot_marks()
	if hover_cell.x >= 0 and Board.is_inside(hover_cell):
		draw_rect(Board.cell_rect(hover_cell), Color(1, 1, 1, 0.85), false, 2.0)


func _draw_space() -> void:
	var view := Rect2(0, 0, 1280, 720)
	var tint_amount := Profile.map_tint_amount()
	var mod := Color.WHITE
	if tint_amount > 0.0:
		mod = Color.WHITE.lerp(Profile.map_tint(), tint_amount)
	if _space_tex:
		draw_texture_rect(_space_tex, view, false, mod)
	else:
		draw_rect(view, Color("#241448"))


func _draw_cell(cell: Vector2i) -> void:
	draw_rect(Board.cell_rect(cell), Color(1, 1, 1, 0.07), false, 1.0)


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


func _draw_roads() -> void:
	if _path_tex == null:
		return
	if Board.lanes.size() == 2:
		var shared := _shared_count()
		_stamp_lane(Board.lane_a, Board.lane_a.size() - 1)
		var south_end := Board.lane_b.size() - 1 - shared
		if south_end < 1:
			south_end = Board.lane_b.size() - 1
		_stamp_lane(Board.lane_b, south_end)
		return
	var seen := {}
	for lane in Board.lanes:
		_stamp_lane_once(lane, seen)


func _shared_count() -> int:
	var north: Array = Board.lane_a
	var south: Array = Board.lane_b
	var count := 0
	while count < north.size() and count < south.size():
		if north[north.size() - 1 - count] != south[south.size() - 1 - count]:
			break
		count += 1
	return count


func _stamp_lane(cells: Array, last_index: int) -> void:
	var last := mini(last_index, cells.size() - 1)
	for i in range(last):
		_stamp_segment(Board.cell_center(cells[i]), Board.cell_center(cells[i + 1]))
		if i + 1 < last:
			var into: Vector2i = cells[i + 1] - cells[i]
			var out: Vector2i = cells[i + 2] - cells[i + 1]
			if into != out:
				_stamp_joint(Board.cell_center(cells[i + 1]))


func _stamp_lane_once(cells: Array, seen: Dictionary) -> void:
	var last := cells.size() - 1
	for i in range(last):
		var a: Vector2i = cells[i]
		var b: Vector2i = cells[i + 1]
		var key := "%d,%d,%d,%d" % [a.x, a.y, b.x, b.y]
		if not seen.has(key):
			seen[key] = true
			_stamp_segment(Board.cell_center(a), Board.cell_center(b))
		if i + 1 < last:
			var into: Vector2i = cells[i + 1] - cells[i]
			var out: Vector2i = cells[i + 2] - cells[i + 1]
			if into != out:
				_stamp_joint(Board.cell_center(cells[i + 1]))


func _stamp_joint(center: Vector2) -> void:
	var size := 100.0
	for angle in [0.0, PI * 0.5]:
		draw_set_transform(center, angle, Vector2.ONE)
		draw_texture_rect(_path_tex, Rect2(-size * 0.5, -size * 0.5, size, size), false)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _stamp_segment(a: Vector2, b: Vector2) -> void:
	var delta := b - a
	var length := delta.length()
	if length < 1.0:
		return
	var mid := (a + b) * 0.5
	var width := (length + 36.0) * (128.0 / 115.0)
	var height := 88.0
	draw_set_transform(mid, delta.angle(), Vector2.ONE)
	draw_texture_rect(_path_tex, Rect2(-width * 0.5, -height * 0.5, width, height), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_islands() -> void:
	for cell in Board.SLOTS:
		var texture := _island_texture(Board.style_at(cell))
		if texture == null:
			continue
		var center := Board.cell_center(cell)
		var size := 54.0
		draw_texture_rect(texture, Rect2(center.x - size * 0.5, center.y - size * 0.46, size, size), false)


func _draw_slot_marks() -> void:
	for cell in Board.SLOTS:
		var center := Board.cell_center(cell)
		draw_line(center + Vector2(-7, -2), center + Vector2(7, -2), Color("#fffaf2"), 2.0)
		draw_line(center + Vector2(0, -8), center + Vector2(0, 5), Color("#fffaf2"), 2.0)


func _draw_core() -> void:
	var rect := Board.cell_rect(Board.CORE)
	var center := Board.cell_center(Board.CORE)
	if _core_island_tex:
		var isle := 112.0
		draw_texture_rect(_core_island_tex, Rect2(center.x - isle * 0.5, center.y - isle * 0.46, isle, isle), false)
	if live_core and hurt > 0.0:
		draw_rect(rect, Color(1, 0.35, 0.5, hurt * 0.7))
	elif live_core and Game.core_hp < Game.core_max * 0.35:
		draw_circle(center, 20.0, Color(1, 0.4, 0.5, 0.22))
	if _core_tex:
		var pulse := 42.0 + sin(Time.get_ticks_msec() * 0.005) * 1.5
		draw_texture_rect(_core_tex, Rect2(center.x - pulse * 0.5, center.y - pulse * 0.5, pulse, pulse), false)


func _island_texture(style: String) -> Texture2D:
	if _islands.has(style):
		return _islands[style]
	if style == "island_b":
		return _islands.get("teal")
	if style == "island_c":
		return _islands.get("crystal")
	return _islands.get("pink")


func _draw_rifts() -> void:
	if _rift_tex == null:
		return
	var spawns: Array[Vector2i] = []
	for lane in Board.lanes:
		if lane.is_empty():
			continue
		var cell: Vector2i = lane[0]
		if cell not in spawns:
			spawns.append(cell)
	for cell in spawns:
		var center := Board.cell_center(cell)
		var s := 36.0
		draw_texture_rect(_rift_tex, Rect2(center.x - s * 0.5, center.y - s * 0.5, s, s), false, Color(1, 1, 1, 0.92))
