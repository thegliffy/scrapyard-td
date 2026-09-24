extends Control

## Stays awake while the tree is paused. Everything else is frozen.
## Mouse hits this full-screen control first, so the board and HUD cannot be clicked.


func _init() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


func _build() -> void:
	var font := Art.ui_font()
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.02, 0.09, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var card := Panel.new()
	card.name = "Card"
	card.position = Vector2(390, 220)
	card.size = Vector2(500, 280)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff6ee")
	style.border_color = Color("#f0b6d4")
	style.set_border_width_all(6)
	style.set_corner_radius_all(28)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var title := Label.new()
	title.text = "Paused"
	title.position = Vector2(40, 48)
	title.size = Vector2(420, 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color("#6a3d88"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)

	var hint := Label.new()
	hint.text = "P or Esc"
	hint.position = Vector2(40, 124)
	hint.size = Vector2(420, 32)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", font)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("#7a6494"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hint)

	var resume := Button.new()
	resume.name = "Resume"
	resume.text = "Resume"
	resume.focus_mode = Control.FOCUS_NONE
	resume.position = Vector2(125, 180)
	resume.size = Vector2(250, 56)
	resume.add_theme_font_override("font", font)
	resume.add_theme_font_size_override("font_size", 22)
	resume.add_theme_color_override("font_color", Color("#5a3d70"))
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("#b6f3c8")
	button_style.border_color = Color("#e7b4d0")
	button_style.set_border_width_all(4)
	button_style.set_corner_radius_all(16)
	resume.add_theme_stylebox_override("normal", button_style)
	var hover := button_style.duplicate()
	hover.bg_color = Color("#d4ffe4")
	resume.add_theme_stylebox_override("hover", hover)
	resume.add_theme_stylebox_override("pressed", hover)
	resume.pressed.connect(_resume)
	card.add_child(resume)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_resume()
			get_viewport().set_input_as_handled()


func _resume() -> void:
	var root := get_tree().get_first_node_in_group("game_root")
	if root and root.has_method("toggle_pause"):
		root.toggle_pause()
