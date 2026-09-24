extends Node2D

var cell: Vector2i
var tower = null
var hovered := false
var selected := false
var ghost: Texture2D
var _island: Texture2D


func _ready() -> void:
	_island = Art.map_tex("island")


func setup(next_cell: Vector2i) -> void:
	cell = next_cell
	position = Board.cell_center(cell)
	queue_redraw()


func _draw() -> void:
	var size := 60.0
	if hovered or selected:
		size = 64.0
	var tint := Color.WHITE
	if tower != null:
		tint = Color(0.92, 0.86, 0.8)
	elif hovered:
		tint = Color(1, 1, 0.92)
	if _island:
		draw_texture_rect(_island, Rect2(-size * 0.5, -size * 0.46, size, size), false, tint)
	else:
		draw_circle(Vector2(0, 2), 20.0, Color("#f4dcc4"))
	if tower == null:
		draw_line(Vector2(-7, -1), Vector2(7, -1), Color("#5a3d70"), 4.0)
		draw_line(Vector2(0, -8), Vector2(0, 6), Color("#5a3d70"), 4.0)
		draw_line(Vector2(-7, -2), Vector2(7, -2), Color("#fffaf2"), 2.0)
		draw_line(Vector2(0, -8), Vector2(0, 5), Color("#fffaf2"), 2.0)
		if ghost:
			draw_texture_rect(ghost, Rect2(-18, -22, 36, 36), false, Color(1, 1, 1, 0.6))
	if selected:
		draw_arc(Vector2(0, 2), 24.0, 0, TAU, 28, Color("#fff1a8"), 3.0, true)
	elif hovered:
		draw_arc(Vector2(0, 2), 24.0, 0, TAU, 28, Color(1, 1, 1, 0.85), 2.0, true)
