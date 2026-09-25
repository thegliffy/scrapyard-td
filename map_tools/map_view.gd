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

## One cyan road. Outer layer is a soft glow, then the body, then a
## brighter cyan core. Same outer width as the old ribbon. No second hue.
const _ROAD_LAYERS := [
	{"width": 22.0, "color": Color(0.18, 0.72, 0.98, 0.42)},
	{"width": 14.0, "color": Color(0.12, 0.84, 1.0, 1.0)},
	{"width": 5.0, "color": Color(0.45, 0.96, 1.0, 1.0)},
]
const _CORNER_RADIUS := 18.0

var _core_island_tex: Texture2D
var _backdrop_cache := {}
var _core_tex: Texture2D
var _rift_tex: Texture2D
var _islands := {}


func _ready() -> void:
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


func _backdrop_texture(backdrop_id: String) -> Texture2D:
	if _backdrop_cache.has(backdrop_id):
		return _backdrop_cache[backdrop_id]
	var source := Art.backdrop_tex(backdrop_id)
	if source == null:
		return null
	# The 1920 plate's imported texture draws blank in the compatibility
	# renderer. A plain ImageTexture of the same pixels does not.
	var image := source.get_image()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var tex := ImageTexture.create_from_image(image)
	_backdrop_cache[backdrop_id] = tex
	return tex


func _draw_space() -> void:
	var view := Rect2(0, 0, 1280, 720)
	var backdrop_id := "deep_space"
	if Board.active != null and str(Board.active.backdrop) != "":
		backdrop_id = str(Board.active.backdrop)
	var tex := _backdrop_texture(backdrop_id)
	if tex:
		draw_texture_rect(tex, view, false)
	else:
		draw_rect(view, Color("#070b24"))
	# A white-lerp multiply barely shows on this dark plate, and a strong
	# lavender mix turns it pink. A short overlay keeps Dock cool and Deep violet.
	var tint_amount := Profile.map_tint_amount()
	if tint_amount > 0.0:
		var wash := Profile.map_tint()
		wash.a = clampf(tint_amount * 0.45, 0.0, 0.14)
		draw_rect(view, wash)


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


## One continuous cyan stroke per lane. Shared segments are drawn by the
## first lane only, so a merge does not stack a second bright copy.
func _draw_roads() -> void:
	for stroke in _road_strokes():
		var points := _smooth_centers(stroke["cells"])
		if points.size() < 2:
			continue
		_draw_neon(points, bool(stroke["trim_start"]), bool(stroke["trim_end"]))


func _road_strokes() -> Array:
	var covered := {}
	var strokes: Array = []
	for lane in Board.lanes:
		var cells: Array = lane
		if cells.size() < 2:
			continue
		var run: Array[Vector2i] = []
		var trim_start := false
		for i in range(cells.size() - 1):
			var a: Vector2i = cells[i]
			var b: Vector2i = cells[i + 1]
			var key := _segment_key(a, b)
			if covered.has(key):
				if run.size() >= 2:
					strokes.append({"cells": run.duplicate(), "trim_start": trim_start, "trim_end": true})
				run = []
				trim_start = true
				continue
			covered[key] = true
			if run.is_empty():
				run = [a, b]
			else:
				run.append(b)
		if run.size() >= 2:
			strokes.append({"cells": run, "trim_start": trim_start, "trim_end": false})
	return strokes


func _segment_key(a: Vector2i, b: Vector2i) -> String:
	if a.x > b.x or (a.x == b.x and a.y > b.y):
		var swap := a
		a = b
		b = swap
	return "%d,%d,%d,%d" % [a.x, a.y, b.x, b.y]


func _smooth_centers(cells: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	if cells.is_empty():
		return points
	points.append(Board.cell_center(cells[0]))
	for i in range(1, cells.size() - 1):
		var prev := Board.cell_center(cells[i - 1])
		var curr := Board.cell_center(cells[i])
		var next := Board.cell_center(cells[i + 1])
		var into := curr - prev
		var out := next - curr
		if into.length_squared() < 1.0 or out.length_squared() < 1.0:
			points.append(curr)
			continue
		into = into.normalized()
		out = out.normalized()
		if into.dot(out) > 0.99 or into.dot(out) < -0.5:
			continue
		var radius := minf(_CORNER_RADIUS, prev.distance_to(curr) * 0.45)
		radius = minf(radius, curr.distance_to(next) * 0.45)
		var start := curr - into * radius
		var end := curr + out * radius
		var arc_center := start + out * radius
		var from_angle := (-out).angle()
		var sweep := wrapf(into.angle() - from_angle, -PI, PI)
		points.append(start)
		for step in range(1, 8):
			var angle := from_angle + sweep * (float(step) / 8.0)
			points.append(arc_center + Vector2.from_angle(angle) * radius)
		points.append(end)
	points.append(Board.cell_center(cells[-1]))
	return points


func _draw_neon(points: PackedVector2Array, trim_start: bool, trim_end: bool) -> void:
	for layer in _ROAD_LAYERS:
		var width := float(layer["width"])
		var color: Color = layer["color"]
		var drawn := points
		if trim_start:
			drawn = _trim_end(drawn, width * 0.5, true)
		if trim_end:
			drawn = _trim_end(drawn, width * 0.5, false)
		if drawn.size() < 2:
			continue
		draw_polyline(drawn, color, width, true)
		if not trim_start:
			draw_circle(drawn[0], width * 0.5, color)
		if not trim_end:
			draw_circle(drawn[drawn.size() - 1], width * 0.5, color)


func _trim_end(points: PackedVector2Array, amount: float, from_start: bool) -> PackedVector2Array:
	var out := points.duplicate()
	if from_start:
		out.reverse()
	var remain := amount
	while out.size() >= 2 and remain > 0.01:
		var a: Vector2 = out[out.size() - 2]
		var b: Vector2 = out[out.size() - 1]
		var dist := a.distance_to(b)
		if dist <= 0.01:
			out.remove_at(out.size() - 1)
			continue
		if dist > remain:
			out[out.size() - 1] = b + (a - b).normalized() * remain
			remain = 0.0
		else:
			out.remove_at(out.size() - 1)
			remain -= dist
	if from_start:
		out.reverse()
	return out


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
		draw_texture_rect(_rift_tex, Rect2(center.x - s * 0.5, center.y - s * 0.5, s, s), false, Color(0.85, 1.0, 1.0, 0.95))
