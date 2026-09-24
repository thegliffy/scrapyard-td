extends Control

const MENU := "res://scenes/main_menu.tscn"

var _font: Font
var _mute: Button


func _ready() -> void:
	_font = Art.ui_font()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#f6ecff")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var back := _button("Back", Color("#ffe0f0"))
	back.position = Vector2(24, 16)
	back.size = Vector2(140, 44)
	back.pressed.connect(_back)
	add_child(back)

	var title := _label("Settings", 36, Color("#6a3d88"))
	title.position = Vector2(180, 14)
	title.size = Vector2(500, 48)
	add_child(title)

	var card := Panel.new()
	card.position = Vector2(340, 180)
	card.size = Vector2(600, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffaf4")
	style.border_color = Color("#f0c4de")
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	var heading := _label("Sound", 22, Color("#5c3d78"))
	heading.position = Vector2(28, 28)
	heading.size = Vector2(240, 32)
	card.add_child(heading)

	var note := _label("Mute stays on this machine.", 16, Color("#7a6494"))
	note.position = Vector2(28, 68)
	note.size = Vector2(360, 28)
	card.add_child(note)

	_mute = _button("")
	_mute.position = Vector2(28, 120)
	_mute.size = Vector2(240, 56)
	_mute.pressed.connect(_toggle_mute)
	card.add_child(_mute)
	_refresh()


func _refresh() -> void:
	_mute.text = "Sound off" if Profile.muted else "Sound on"


func _toggle_mute() -> void:
	if Profile.muted:
		Profile.set_muted(false)
		Sfx.play("ui")
	else:
		Sfx.play("ui")
		Profile.set_muted(true)
	_refresh()


func _back() -> void:
	if not Profile.muted:
		Sfx.play("ui")
	get_tree().change_scene_to_file(MENU)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, bg: Color = Color("#efe4ff")) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#5a3d70"))
	button.add_theme_color_override("font_hover_color", Color("#3d2858"))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("#e7b4d0")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = style.bg_color.lightened(0.08)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button
