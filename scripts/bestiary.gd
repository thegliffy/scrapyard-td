extends Control

const MENU := "res://scenes/main_menu.tscn"

var _font: Font


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

	var title := _label("Bestiary", 36, Color("#6a3d88"))
	title.position = Vector2(180, 14)
	title.size = Vector2(400, 48)
	add_child(title)

	var hint := _label("Critters stay a mystery until you meet them in Battle.", 16, Color("#7a6494"))
	hint.position = Vector2(520, 24)
	hint.size = Vector2(720, 28)
	add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 78)
	scroll.size = Vector2(1232, 620)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)

	for id in Balance.BESTIARY:
		grid.add_child(_card(id))


func _card(id: String) -> Panel:
	var data: Dictionary = Balance.ENEMIES[id]
	var seen := Profile.has_seen(id)
	var card := Panel.new()
	card.custom_minimum_size = Vector2(600, 148)
	card.size = Vector2(600, 148)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _card_style())

	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(12, 18)
	portrait.size = Vector2(112, 112)
	portrait.texture = Art.enemy_tex(id)
	if not seen:
		portrait.modulate = Color(0.08, 0.05, 0.14, 1)
	card.add_child(portrait)

	var name := _label("???" if not seen else str(data["name"]), 22, Color("#5a3d70"))
	name.position = Vector2(140, 10)
	name.size = Vector2(440, 32)
	card.add_child(name)

	var body := _label(_body(id, data) if seen else "Not seen yet.", 15, Color("#7a6494"))
	body.position = Vector2(140, 46)
	body.size = Vector2(440, 90)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(body)
	return card


func _body(id: String, data: Dictionary) -> String:
	var shield := int(data["shield"])
	var stats := "HP %d" % int(data["hp"])
	if shield > 0:
		stats += "   Shield %d" % shield
	stats += "   Speed %.2f" % float(data["speed"])
	stats += "\nGold %d   Leak %d" % [int(data["gold"]), int(data["leak"])]
	stats += "\n%s" % _traits(data)
	stats += "\n%s" % Balance.blurb(id)
	return stats


func _traits(data: Dictionary) -> String:
	var bits: PackedStringArray = PackedStringArray()
	bits.append("Flying" if bool(data.get("flying", false)) else "Ground")
	if int(data.get("shield", 0)) > 0:
		bits.append("Shield")
	if int(data.get("split", 0)) > 0:
		bits.append("Splits")
	if bool(data.get("boss", false)):
		bits.append("Boss")
	if bool(data.get("skitter", false)):
		bits.append("Skitter")
	return " · ".join(bits)


func _back() -> void:
	Sfx.play("ui")
	get_tree().change_scene_to_file(MENU)


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, bg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 20)
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(16)
	style.set_border_width_all(3)
	style.border_color = Color("#f0c4de")
	style.content_margin_left = 8
	style.content_margin_right = 8
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	return button


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffaf4")
	style.set_corner_radius_all(18)
	style.set_border_width_all(3)
	style.border_color = Color("#f0c4de")
	return style
