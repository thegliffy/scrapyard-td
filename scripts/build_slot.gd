extends Node2D

var cell: Vector2i
var tower = null
var hovered := false
var selected := false
var ghost: Texture2D


func setup(next_cell: Vector2i) -> void:
	cell = next_cell
	position = Board.cell_center(cell)
	queue_redraw()


func _draw() -> void:
	var half := float(Board.TILE) * 0.5
	var inset := 7.0
	var pad := Rect2(-half + inset, -half + inset, float(Board.TILE) - inset * 2.0, float(Board.TILE) - inset * 2.0)
	var fill := Color("#ffd36a")
	if tower != null:
		fill = Color("#e6b44a")
	elif hovered:
		fill = Color("#ffe7a8")
	draw_rect(pad, fill)
	draw_rect(pad, Color("#2a2048"), false, 3.0)
	if tower == null:
		draw_line(Vector2(-7, 0), Vector2(7, 0), Color("#2a2048"), 3.0)
		draw_line(Vector2(0, -7), Vector2(0, 7), Color("#2a2048"), 3.0)
		if ghost:
			draw_texture_rect(ghost, Rect2(-18, -20, 36, 36), false, Color(1, 1, 1, 0.6))
	var full := Rect2(-half, -half, float(Board.TILE), float(Board.TILE))
	if selected:
		draw_rect(full, Color("#fff6d2"), false, 4.0)
	elif hovered:
		draw_rect(full, Color("#ffffffcc"), false, 2.0)
