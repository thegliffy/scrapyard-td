extends Control

const MENU := "res://scenes/main_menu.tscn"
const RUN := "res://scenes/main.tscn"

var _font: Font
var _map_ids: Array[String] = []


func _ready() -> void:
	_font = Art.ui_font()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#f6ecff")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var back := _button("Back", Color("#ffe0f0"), 140, 44)
	back.position = Vector2(24, 16)
	back.pressed.connect(_back)
	add_child(back)

	var title := _label("Choose a yard", 36, Color("#6a3d88"))
	title.position = Vector2(180, 14)
	title.size = Vector2(700, 48)
	add_child(title)

	var scrap := _label("SCRAP  %d" % Profile.scrap, 26, Color("#c47a20"))
	scrap.position = Vector2(860, 18)
	scrap.size = Vector2(390, 40)
	scrap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(scrap)

	var hint := _label("Pick an unlocked yard. More yards are on the Unlocks screen.", 16, Color("#7a6494"))
	hint.position = Vector2(24, 78)
	hint.size = Vector2(1000, 28)
	add_child(hint)

	var y := 130.0
	for id in Profile.unlocked_maps():
		_map_ids.append(id)
		var card := _map_card(id)
		card.position = Vector2(240, y)
		add_child(card)
		y += 150


func _map_card(id: String) -> Button:
	var data: Dictionary = Balance.MAPS[id]
	var button := _button("", Color("#fffaf4"), 800, 132)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var name := _label(str(data["name"]), 26, Color("#5a3d70"))
	name.position = Vector2(24, 18)
	name.size = Vector2(520, 36)
	button.add_child(name)
	var blurb := _label(str(data["blurb"]), 16, Color("#7a6494"))
	blurb.position = Vector2(24, 58)
	blurb.size = Vector2(520, 52)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_child(blurb)
	var go := _label("Battle", 20, Color("#2f6b45"))
	go.position = Vector2(620, 46)
	go.size = Vector2(150, 36)
	go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_child(go)
	button.pressed.connect(_start.bind(id))
	return button


func _start(id: String) -> void:
	Profile.choose_map(id)
	Sfx.play("ui")
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(RUN)


func _back() -> void:
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


func _button(text: String, bg: Color, width: int, height: int) -> Button:
	var button := Button.new()
	button.text = text
	button.size = Vector2(width, height)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#5a3d70"))
	button.add_theme_color_override("font_hover_color", Color("#3d2858"))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("#e7b4d0")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = bg.lightened(0.08)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button
