extends Control

const MENU := "res://scenes/main_menu.tscn"

var _font: Font
var _picked := ""
var _status: Label
var _scrap: Label
var _gun_buttons := {}
var _slot_buttons: Array[Button] = []


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

	var title := _label("Unlocks", 36, Color("#6a3d88"))
	title.position = Vector2(180, 14)
	title.size = Vector2(400, 48)
	add_child(title)

	_scrap = _label("", 26, Color("#c47a20"))
	_scrap.position = Vector2(860, 18)
	_scrap.size = Vector2(390, 40)
	_scrap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_scrap)

	_status = _label("Click a gun, then a slot. Click a filled slot to clear it.", 16, Color("#7a6494"))
	_status.position = Vector2(24, 72)
	_status.size = Vector2(900, 28)
	add_child(_status)

	var guns_h := _label("Guns", 22, Color("#5c3d78"))
	guns_h.position = Vector2(24, 108)
	guns_h.size = Vector2(200, 30)
	add_child(guns_h)

	var maps_h := _label("Maps", 22, Color("#5c3d78"))
	maps_h.position = Vector2(860, 108)
	maps_h.size = Vector2(200, 30)
	add_child(maps_h)

	var y := 146
	for id in Profile.GUN_ORDER:
		var row := _gun_row(id)
		row.position = Vector2(24, y)
		add_child(row)
		y += 68

	y = 146
	for id in Profile.MAP_ORDER:
		var row := _map_row(id)
		row.position = Vector2(860, y)
		add_child(row)
		y += 88

	var load_h := _label("Battle loadout", 22, Color("#5c3d78"))
	load_h.position = Vector2(24, 500)
	load_h.size = Vector2(400, 30)
	add_child(load_h)

	var note := _label("Slots 1–3 are free. Slots 4 and 5 cost scrap.", 16, Color("#7a6494"))
	note.position = Vector2(280, 504)
	note.size = Vector2(700, 26)
	add_child(note)

	var slot_w := 140
	var gap := 16
	var total := Profile.LOADOUT_SIZE * slot_w + (Profile.LOADOUT_SIZE - 1) * gap
	var x := (1280 - total) / 2.0
	for i in Profile.LOADOUT_SIZE:
		var slot := _slot(i)
		slot.position = Vector2(x, 544)
		add_child(slot)
		x += slot_w + gap

	_refresh()


func _gun_row(id: String) -> Control:
	var row := Panel.new()
	row.size = Vector2(800, 62)
	row.add_theme_stylebox_override("panel", _card_style(Color("#fffaf4")))
	var icon := TextureRect.new()
	icon.texture = Art.tower_tex(id)
	icon.position = Vector2(10, 8)
	icon.size = Vector2(46, 46)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var name := _label(str(Balance.TOWERS[id]["name"]), 18, Color("#5a3d70"))
	name.position = Vector2(68, 16)
	name.size = Vector2(280, 30)
	row.add_child(name)
	var action := _button("", Color("#ffe9a8"), 180, 40)
	action.position = Vector2(600, 11)
	action.pressed.connect(_on_gun.bind(id))
	row.add_child(action)
	_gun_buttons[id] = action
	return row


func _map_row(id: String) -> Control:
	var row := Panel.new()
	row.size = Vector2(390, 80)
	row.add_theme_stylebox_override("panel", _card_style(Color("#fffaf4")))
	var data: Dictionary = Balance.MAPS[id]
	var name := _label(str(data["name"]), 18, Color("#5a3d70"))
	name.position = Vector2(12, 8)
	name.size = Vector2(220, 26)
	row.add_child(name)
	var blurb := _label(str(data["blurb"]), 13, Color("#7a6494"))
	blurb.position = Vector2(12, 36)
	blurb.size = Vector2(230, 36)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(blurb)
	var action := _button("", Color("#d7ecff"), 120, 36)
	action.position = Vector2(256, 22)
	action.pressed.connect(_on_map.bind(id))
	row.add_child(action)
	row.set_meta("action", action)
	return row


func _slot(index: int) -> Button:
	var button := _button("", Color("#fff6ee"), 16, 110)
	button.size = Vector2(140, 120)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.pressed.connect(_on_slot.bind(index))
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(42, 8)
	icon.size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	var lock := LockMark.new()
	lock.name = "Lock"
	lock.position = Vector2(54, 10)
	lock.size = Vector2(32, 32)
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(lock)
	var caption := _label("", 14, Color("#5a3d70"))
	caption.name = "Caption"
	caption.position = Vector2(4, 70)
	caption.size = Vector2(132, 42)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_child(caption)
	_slot_buttons.append(button)
	return button


func _refresh() -> void:
	_scrap.text = "SCRAP  %d" % Profile.scrap
	for id in _gun_buttons.keys():
		var button: Button = _gun_buttons[id]
		if Profile.has_gun(id):
			var mark := "  ●" if _picked == id else ""
			button.text = "Pick%s" % mark
			button.disabled = false
		else:
			var price := int(Profile.GUN_COST.get(id, 0))
			button.text = "Buy %d" % price
			button.disabled = Profile.scrap < price
	for id in Profile.MAP_ORDER:
		var row := _find_map_row(id)
		if row == null:
			continue
		var action: Button = row.get_meta("action")
		if Profile.has_map(id):
			action.text = "Owned"
			action.disabled = true
		else:
			var price := int(Profile.MAP_COST.get(id, 0))
			action.text = "Buy %d" % price
			action.disabled = Profile.scrap < price
	for i in _slot_buttons.size():
		_paint_slot(i)


func _find_map_row(id: String) -> Control:
	for child in get_children():
		if child is Panel and child.has_meta("action") and child.get_child(0) is Label:
			if child.get_child(0).text == str(Balance.MAPS[id]["name"]):
				return child
	return null


func _paint_slot(index: int) -> void:
	var button := _slot_buttons[index]
	var icon: TextureRect = button.get_node("Icon")
	var lock: Control = button.get_node("Lock")
	var caption: Label = button.get_node("Caption")
	if not Profile.slot_open(index):
		icon.texture = null
		lock.visible = true
		caption.text = "Locked\n%d scrap" % Profile.slot_cost(index)
		button.disabled = false
		button.text = ""
		return
	lock.visible = false
	button.disabled = false
	var id := Profile.loadout_at(index)
	if id == "":
		icon.texture = null
		caption.text = "Slot %d\nempty" % [index + 1]
	else:
		icon.texture = Art.tower_tex(id)
		caption.text = "%d  %s" % [index + 1, Balance.TOWERS[id]["short"]]


func _on_gun(id: String) -> void:
	if not Profile.has_gun(id):
		if Profile.try_buy_gun(id):
			Sfx.play("ui")
			_status.text = "Unlocked %s. Assign it to a free slot." % Balance.TOWERS[id]["name"]
		else:
			Sfx.play("error")
			_status.text = "Not enough scrap."
		_refresh()
		return
	_picked = "" if _picked == id else id
	Sfx.play("ui")
	if _picked == "":
		_status.text = "Click a gun, then a slot. Click a filled slot to clear it."
	else:
		_status.text = "Click a slot to equip %s." % Balance.TOWERS[id]["name"]
	_refresh()


func _on_map(id: String) -> void:
	if Profile.has_map(id):
		return
	if Profile.try_buy_map(id):
		Sfx.play("ui")
		_status.text = "Unlocked %s." % Balance.MAPS[id]["name"]
	else:
		Sfx.play("error")
		_status.text = "Not enough scrap."
	_refresh()


func _on_slot(index: int) -> void:
	if not Profile.slot_open(index):
		if index != Profile.open_slots:
			Sfx.play("error")
			_status.text = "Unlock slot %d first." % [Profile.open_slots + 1]
			return
		if Profile.try_unlock_slot(index):
			Sfx.play("ui")
			_status.text = "Slot %d is open." % [index + 1]
		else:
			Sfx.play("error")
			_status.text = "Need %d scrap to unlock slot %d." % [Profile.slot_cost(index), index + 1]
		_refresh()
		return
	if _picked != "":
		var from := -1
		for i in Profile.LOADOUT_SIZE:
			if Profile.loadout_at(i) == _picked:
				from = i
		if Profile.assign_loadout(index, _picked):
			Sfx.play("ui")
			if from >= 0 and from != index:
				_status.text = "Swapped."
			else:
				_status.text = "Equipped %s in slot %d." % [Balance.TOWERS[_picked]["short"], index + 1]
			_picked = ""
		_refresh()
		return
	if Profile.loadout_at(index) != "":
		Profile.clear_loadout(index)
		Sfx.play("ui")
		_status.text = "Cleared slot %d." % [index + 1]
		_refresh()


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
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#5a3d70"))
	button.add_theme_color_override("font_hover_color", Color("#3d2858"))
	button.add_theme_color_override("font_disabled_color", Color("#8a7a98"))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("#e7b4d0")
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = bg.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var disabled := style.duplicate()
	disabled.bg_color = Color("#efe6f2")
	button.add_theme_stylebox_override("disabled", disabled)
	return button


func _card_style(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("#f0c4de")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	return style


class LockMark extends Control:
	func _draw() -> void:
		var ink := Color("#5a3d70")
		draw_arc(Vector2(16, 14), 7.0, PI, TAU, 10, ink, 3.0, true)
		draw_rect(Rect2(7, 14, 18, 14), ink)
