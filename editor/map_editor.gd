extends Node2D

## Thin editor shell. The yard itself lives in MapData. Battle never includes
## this scene. Deleting this file and scenes/map_editor.tscn leaves the
## loader, validator, brushes, and MapView in place for Adventure.

const MENU := "res://scenes/main_menu.tscn"
const RUN := "res://scenes/main.tscn"
const MIN_COLS := 8
const MAX_COLS := 25
const MIN_ROWS := 6
const MAX_ROWS := 11
const MAX_LANES := 4
const LANE_IDS := ["a", "b", "c", "d"]
const LANE_NAMES := ["North", "South", "West", "East"]
const TINTS := [
	["Yard", "#ffffff", 0.0],
	["Dock", "#7eb6ff", 0.22],
	["Deep", "#6a62d8", 0.3],
]
const BACKDROPS := [
	["Night", "deep_space"],
	["Dusk", "space"],
]

var view: MapView
var data: MapData
var tool := "path"
var lane_index := 0
var style := "pink"
var undo_stack: Array[String] = []
var redo_stack: Array[String] = []
var status := ""
var problems := PackedStringArray()

var _ui: CanvasLayer
var _name_edit: LineEdit
var _status_label: Label
var _error_label: Label
var _grid_label: Label
var _lane_box: HBoxContainer
var _open_panel: Control
var _open_list: VBoxContainer
var _tool_buttons := {}
var _style_buttons := {}
var _tint_buttons := {}
var _backdrop_buttons := {}
var _save_button: Button
var _save_as_button: Button
var _play_button: Button
var _delete_button: Button
var _undo_button: Button
var _redo_button: Button
var _name_lock := false
var _stroke := false
var _stroke_before := ""


func _ready() -> void:
	view = MapView.new()
	view.show_slot_marks = true
	view.live_core = false
	add_child(view)
	Profile.clear_starter_loadout()
	if MapSession.editor_json != "":
		var restored := MapData.from_json(MapSession.editor_json)
		MapSession.playtest = false
		if restored != null:
			show_map(restored)
		else:
			_new_map()
	else:
		_new_map()
	_build_ui()
	_refresh()


func show_map(next: MapData) -> void:
	data = next.duplicate_map()
	lane_index = mini(lane_index, maxi(0, data.lanes.size() - 1))
	undo_stack.clear()
	redo_stack.clear()
	status = "%s  ·  %s" % [data.map_name, "built-in, Save As to copy" if data.builtin else data.id]
	_apply_view()
	if _name_edit != null:
		_sync_name_field()
		_rebuild_lanes()
		_refresh_labels()


func _new_map() -> void:
	var fresh := MapData.blank(MapLibrary.unique_id("untitled"), "Untitled yard")
	fresh.builtin = false
	lane_index = 0
	show_map(fresh)
	status = "New yard. Paint a lane from a spawn to the core."


func _process(_delta: float) -> void:
	if data == null or view == null:
		return
	var cell := Board.world_to_cell(get_global_mouse_position())
	var next := cell if data.is_inside(cell) else Vector2i(-99, -99)
	if next != view.hover_cell:
		view.hover_cell = next
		view.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _open_panel != null and _open_panel.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_close_open()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z and event.ctrl_pressed:
			_undo()
		elif event.keycode == KEY_Y and event.ctrl_pressed:
			_redo()
		elif event.keycode == KEY_S and event.ctrl_pressed:
			if event.shift_pressed:
				_save_as()
			else:
				_save()
		elif event.keycode == KEY_ESCAPE:
			_back()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(event.pressed)
		return
	if event is InputEventMouseMotion and _stroke:
		_on_drag()


func _on_click(pressed: bool) -> void:
	if data == null:
		return
	var cell := Board.world_to_cell(get_global_mouse_position())
	if pressed:
		if not data.is_inside(cell):
			return
		_stroke = tool == "path" or tool == "erase"
		_stroke_before = data.to_json()
		var err := _apply_tool(cell)
		if err != "":
			data = MapData.from_json(_stroke_before)
			_stroke = false
			status = err
			_refresh_labels()
			return
		if not _stroke:
			_finish_stroke()
		_apply_view()
		_refresh_labels()
	elif _stroke:
		_finish_stroke()
		_stroke = false
		_refresh_labels()


func _on_drag() -> void:
	var cell := Board.world_to_cell(get_global_mouse_position())
	if not data.is_inside(cell):
		return
	var err := _apply_tool(cell)
	if err != "":
		return
	_apply_view()
	_refresh_labels()


func _finish_stroke() -> void:
	if data.to_json() == _stroke_before:
		return
	_push_undo(_stroke_before)


func _apply_tool(cell: Vector2i) -> String:
	match tool:
		"path":
			return MapBrush.paint_path(data, lane_index, cell)
		"erase":
			return MapBrush.erase_path(data, lane_index, cell)
		"spawn":
			return MapBrush.set_spawn(data, lane_index, cell)
		"core":
			return MapBrush.set_core(data, cell)
		"pod":
			return MapBrush.place_pod(data, cell, style)
		"remove":
			return MapBrush.remove_pod(data, cell)
		"style":
			return MapBrush.paint_style(data, cell, style)
	return ""


func _push_undo(snapshot: String) -> void:
	undo_stack.append(snapshot)
	if undo_stack.size() > 50:
		undo_stack.remove_at(0)
	redo_stack.clear()


func _edit(snapshot: String) -> void:
	if data.to_json() == snapshot:
		_refresh_labels()
		return
	_push_undo(snapshot)
	_apply_view()
	_refresh_labels()


func _undo() -> void:
	if undo_stack.is_empty():
		status = "Nothing to undo."
		_refresh_labels()
		return
	redo_stack.append(data.to_json())
	data = MapData.from_json(undo_stack.pop_back())
	lane_index = mini(lane_index, maxi(0, data.lanes.size() - 1))
	status = "Undid."
	_apply_view()
	_sync_name_field()
	_rebuild_lanes()
	_refresh_labels()


func _redo() -> void:
	if redo_stack.is_empty():
		status = "Nothing to redo."
		_refresh_labels()
		return
	undo_stack.append(data.to_json())
	data = MapData.from_json(redo_stack.pop_back())
	lane_index = mini(lane_index, maxi(0, data.lanes.size() - 1))
	status = "Redid."
	_apply_view()
	_sync_name_field()
	_rebuild_lanes()
	_refresh_labels()


func _apply_view() -> void:
	if data == null:
		return
	Board.apply(data)
	if view:
		view.queue_redraw()


func _build_ui() -> void:
	var font := Art.ui_font()
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var file_specs := [
		["New", _on_new],
		["Open", _on_open],
		["Save", _save],
		["Save As", _save_as],
		["Delete", _on_delete],
		["Playtest", _playtest],
		["Menu", _back],
	]
	var x := 8.0
	for spec in file_specs:
		var width := 78
		if spec[0] == "Save As" or spec[0] == "Playtest":
			width = 96
		var button := _button(font, spec[0], width, 30, 15)
		button.position = Vector2(x, 6)
		button.pressed.connect(spec[1])
		root.add_child(button)
		match spec[0]:
			"Save":
				_save_button = button
			"Save As":
				_save_as_button = button
			"Delete":
				_delete_button = button
			"Playtest":
				_play_button = button
		x += width + 6

	_name_edit = LineEdit.new()
	_name_edit.position = Vector2(x + 8, 6)
	_name_edit.size = Vector2(250, 30)
	_name_edit.placeholder_text = "Yard name"
	_name_edit.add_theme_font_override("font", font)
	_name_edit.add_theme_font_size_override("font_size", 16)
	_name_edit.text_changed.connect(_on_name_changed)
	root.add_child(_name_edit)

	_status_label = _label(font, 14, Color("#fff6e4"))
	_status_label.position = Vector2(8, 40)
	_status_label.size = Vector2(1264, 22)
	_status_label.add_theme_color_override("font_outline_color", Color("#1a1030"))
	_status_label.add_theme_constant_override("outline_size", 6)
	root.add_child(_status_label)

	var tools := [
		["path", "Path"],
		["erase", "Erase"],
		["spawn", "Spawn"],
		["core", "Core"],
		["pod", "Pod"],
		["remove", "Remove"],
		["style", "Style"],
	]
	x = 8.0
	for spec in tools:
		var button := _button(font, spec[1], 78, 28, 14)
		button.position = Vector2(x, 612)
		button.pressed.connect(_set_tool.bind(spec[0]))
		root.add_child(button)
		_tool_buttons[spec[0]] = button
		x += 84

	_lane_box = HBoxContainer.new()
	_lane_box.position = Vector2(8, 646)
	_lane_box.add_theme_constant_override("separation", 4)
	root.add_child(_lane_box)

	x = 430.0
	for island_style in MapData.STYLES:
		var button := _button(font, island_style.capitalize(), 78, 28, 14)
		button.position = Vector2(x, 646)
		button.pressed.connect(_set_style.bind(island_style))
		root.add_child(button)
		_style_buttons[island_style] = button
		x += 84

	x = 690.0
	for tint in TINTS:
		var button := _button(font, tint[0], 64, 28, 14)
		button.position = Vector2(x, 646)
		button.pressed.connect(_set_tint.bind(tint[1], float(tint[2])))
		root.add_child(button)
		_tint_buttons[tint[0]] = button
		x += 68
	for backdrop in BACKDROPS:
		var button := _button(font, backdrop[0], 70, 28, 14)
		button.position = Vector2(x, 646)
		button.pressed.connect(_set_backdrop.bind(backdrop[1], backdrop[0]))
		root.add_child(button)
		_backdrop_buttons[backdrop[1]] = button
		x += 74

	_grid_label = _label(font, 14, Color("#fff6e4"))
	_grid_label.position = Vector2(8, 682)
	_grid_label.size = Vector2(220, 24)
	_grid_label.add_theme_color_override("font_outline_color", Color("#1a1030"))
	_grid_label.add_theme_constant_override("outline_size", 5)
	root.add_child(_grid_label)

	var grid_specs := [
		["Cols −", _nudge_cols.bind(-1)],
		["Cols +", _nudge_cols.bind(1)],
		["Rows −", _nudge_rows.bind(-1)],
		["Rows +", _nudge_rows.bind(1)],
		["Undo", _undo],
		["Redo", _redo],
		["Clear", _clear],
	]
	x = 230.0
	for spec in grid_specs:
		var button := _button(font, spec[0], 72, 28, 14)
		button.position = Vector2(x, 680)
		button.pressed.connect(spec[1])
		root.add_child(button)
		if spec[0] == "Undo":
			_undo_button = button
		elif spec[0] == "Redo":
			_redo_button = button
		x += 76

	_error_label = _label(font, 15, Color("#ffd0dc"))
	_error_label.position = Vector2(780, 676)
	_error_label.size = Vector2(490, 40)
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.add_theme_color_override("font_outline_color", Color("#1a1030"))
	_error_label.add_theme_constant_override("outline_size", 5)
	root.add_child(_error_label)

	_open_panel = Control.new()
	_open_panel.visible = false
	_open_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_open_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui.add_child(_open_panel)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.14, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_open_panel.add_child(dim)
	var card := Panel.new()
	card.position = Vector2(340, 70)
	card.size = Vector2(600, 580)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#fff6ee")
	panel_style.border_color = Color("#f0b6d4")
	panel_style.set_border_width_all(6)
	panel_style.set_corner_radius_all(24)
	card.add_theme_stylebox_override("panel", panel_style)
	_open_panel.add_child(card)
	var title := _label(font, 28, Color("#6a3d88"))
	title.text = "Open a yard"
	title.position = Vector2(24, 16)
	title.size = Vector2(400, 40)
	card.add_child(title)
	var close := _button(font, "Close", 100, 36, 16)
	close.position = Vector2(476, 16)
	close.pressed.connect(_close_open)
	card.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 68)
	scroll.size = Vector2(552, 488)
	card.add_child(scroll)
	_open_list = VBoxContainer.new()
	_open_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_open_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_open_list)
	_sync_name_field()
	_rebuild_lanes()


func _rebuild_lanes() -> void:
	if _lane_box == null or data == null:
		return
	var font := Art.ui_font()
	for child in _lane_box.get_children():
		_lane_box.remove_child(child)
		child.free()
	for i in data.lanes.size():
		var lane_name := str(data.lanes[i].get("name", "Lane"))
		var button := _button(font, lane_name, 78, 28, 14)
		button.pressed.connect(_set_lane.bind(i))
		_lane_box.add_child(button)
	if data.lanes.size() < MAX_LANES:
		var add := _button(font, "+ Lane", 78, 28, 14)
		add.pressed.connect(_add_lane)
		_lane_box.add_child(add)
	if data.lanes.size() > 1:
		var remove := _button(font, "− Lane", 78, 28, 14)
		remove.pressed.connect(_remove_lane)
		_lane_box.add_child(remove)


func _refresh() -> void:
	_apply_view()
	_sync_name_field()
	_rebuild_lanes()
	_refresh_labels()


func _refresh_labels() -> void:
	if _status_label == null or data == null:
		return
	problems = MapValidator.errors(data)
	var valid := problems.is_empty()
	var saved := _custom_file_exists()
	_save_button.disabled = (not valid) or data.builtin or MapLibrary.is_builtin(data.id)
	_save_as_button.disabled = not valid
	_play_button.disabled = not valid
	_delete_button.disabled = not saved
	_undo_button.disabled = undo_stack.is_empty()
	_redo_button.disabled = redo_stack.is_empty()
	for key in _tool_buttons:
		_tool_buttons[key].modulate = Color.WHITE if key == tool else Color(0.72, 0.72, 0.78)
	for key in _style_buttons:
		_style_buttons[key].modulate = Color.WHITE if key == style else Color(0.72, 0.72, 0.78)
	for key in _backdrop_buttons:
		_backdrop_buttons[key].modulate = Color.WHITE if data.backdrop == key else Color(0.72, 0.72, 0.78)
	_grid_label.text = "Grid %d × %d" % [data.cols, data.rows]
	var lane_name := "Lane"
	if lane_index >= 0 and lane_index < data.lanes.size():
		lane_name = str(data.lanes[lane_index].get("name", "Lane"))
	var where := "built-in" if data.builtin or MapLibrary.is_builtin(data.id) else ("saved" if saved else "unsaved")
	_status_label.text = "%s   ·   %s   ·   editing %s   ·   %s" % [data.map_name, where, lane_name, _tool_hint()]
	if status != "":
		_status_label.text += "   ·   " + status
	if valid:
		_error_label.text = "Valid yard. Save and Playtest are open."
		_error_label.add_theme_color_override("font_color", Color("#d8ffe8"))
	else:
		var extra := ""
		if problems.size() > 1:
			extra = "  (+%d more)" % (problems.size() - 1)
		_error_label.text = problems[0] + extra
		_error_label.add_theme_color_override("font_color", Color("#ffd0dc"))
	if _lane_box:
		var buttons := _lane_box.get_children()
		for i in mini(data.lanes.size(), buttons.size()):
			buttons[i].modulate = Color.WHITE if i == lane_index else Color(0.72, 0.72, 0.78)


func _tool_hint() -> String:
	match tool:
		"path":
			return "Path paints in order and turns like Battle"
		"erase":
			return "Erase cuts this lane from the cell onward"
		"spawn":
			return "Spawn moves this lane's rift"
		"core":
			return "Core sets the Station Core and extends lanes that can reach it"
		"pod":
			return "Pod places a 2×2 hardpoint"
		"remove":
			return "Remove deletes the hardpoint you click"
		"style":
			return "Style paints one island pink, teal, or crystal"
	return ""


func _custom_file_exists() -> bool:
	if data == null or data.builtin or MapLibrary.is_builtin(data.id):
		return false
	return FileAccess.file_exists("%s/%s.json" % [MapLibrary.CUSTOM_DIR, data.id])


func _sync_name_field() -> void:
	if _name_edit == null or data == null:
		return
	_name_lock = true
	_name_edit.text = data.map_name
	_name_lock = false


func _on_name_changed(next: String) -> void:
	if _name_lock or data == null:
		return
	data.map_name = next


func _set_tool(next: String) -> void:
	tool = next
	status = ""
	_refresh_labels()


func _set_style(next: String) -> void:
	style = next
	status = "Island style %s." % next
	_refresh_labels()


func _set_lane(index: int) -> void:
	lane_index = index
	status = ""
	_refresh_labels()


func _set_tint(hex: String, amount: float) -> void:
	var before := data.to_json()
	data.tint = hex
	data.tint_amount = amount
	status = "Tint updated. Health and speed stay as they are."
	_edit(before)


func _set_backdrop(backdrop_id: String, label: String) -> void:
	var before := data.to_json()
	data.backdrop = backdrop_id
	status = "Backdrop is %s." % label
	_edit(before)


func _add_lane() -> void:
	if data.lanes.size() >= MAX_LANES:
		status = "Four lanes is the limit."
		_refresh_labels()
		return
	var before := data.to_json()
	var index := data.lanes.size()
	data.lanes.append({
		"id": LANE_IDS[index],
		"name": LANE_NAMES[index],
		"cells": [] as Array[Vector2i],
	})
	lane_index = index
	status = "Added %s." % LANE_NAMES[index]
	_edit(before)
	_rebuild_lanes()
	_refresh_labels()


func _remove_lane() -> void:
	if data.lanes.size() <= 1:
		status = "Keep at least one lane."
		_refresh_labels()
		return
	var before := data.to_json()
	data.lanes.remove_at(lane_index)
	for i in data.lanes.size():
		data.lanes[i]["id"] = LANE_IDS[i]
	lane_index = mini(lane_index, data.lanes.size() - 1)
	status = "Removed that lane."
	_edit(before)
	_rebuild_lanes()
	_refresh_labels()


func _nudge_cols(delta: int) -> void:
	_nudge_grid(data.cols + delta, data.rows)


func _nudge_rows(delta: int) -> void:
	_nudge_grid(data.cols, data.rows + delta)


func _nudge_grid(cols: int, rows: int) -> void:
	var clamped_cols := clampi(cols, MIN_COLS, MAX_COLS)
	var clamped_rows := clampi(rows, MIN_ROWS, MAX_ROWS)
	if clamped_cols == data.cols and clamped_rows == data.rows and (cols != data.cols or rows != data.rows):
		status = "Grid stays between %d×%d and %d×%d so it fits the window." % [MIN_COLS, MIN_ROWS, MAX_COLS, MAX_ROWS]
		_refresh_labels()
		return
	if clamped_cols == data.cols and clamped_rows == data.rows:
		return
	var before := data.to_json()
	var err := MapBrush.resize(data, clamped_cols, clamped_rows)
	if err != "":
		status = err
		_refresh_labels()
		return
	status = "Grid is %d×%d." % [data.cols, data.rows]
	_edit(before)


func _clear() -> void:
	var before := data.to_json()
	MapBrush.clear_geometry(data)
	status = "Cleared lanes and hardpoints."
	_edit(before)


func _on_new() -> void:
	Sfx.play("ui")
	_new_map()
	_sync_name_field()
	_rebuild_lanes()
	_refresh_labels()


func _on_open() -> void:
	Sfx.play("ui")
	_fill_open_list()
	_open_panel.visible = true


func _close_open() -> void:
	_open_panel.visible = false


func _fill_open_list() -> void:
	var font := Art.ui_font()
	for child in _open_list.get_children():
		child.queue_free()
	_open_heading(font, "Built-in yards")
	for id in MapLibrary.BUILTIN:
		var loaded := MapLibrary.load_builtin(id)
		if loaded == null:
			continue
		_open_row(font, "%s    read-only" % loaded.map_name, loaded)
	_open_heading(font, "Custom yards")
	var custom := MapLibrary.list_custom()
	if custom.is_empty():
		var empty := _label(font, 16, Color("#7a6494"))
		empty.text = "None yet. Save As writes one to this machine."
		_open_list.add_child(empty)
		return
	for id in custom:
		var loaded := MapLibrary.load_custom(id)
		if loaded == null:
			continue
		_open_row(font, loaded.map_name, loaded)


func _open_heading(font: Font, text: String) -> void:
	var label := _label(font, 18, Color("#6a3d88"))
	label.text = text
	_open_list.add_child(label)


func _open_row(font: Font, text: String, loaded: MapData) -> void:
	var button := _button(font, text, 520, 42, 16)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_open_loaded.bind(loaded))
	_open_list.add_child(button)


func _open_loaded(loaded: MapData) -> void:
	Sfx.play("ui")
	lane_index = 0
	show_map(loaded)
	if loaded.builtin:
		status = "Opened %s. Built-in yards cannot be overwritten." % loaded.map_name
	else:
		status = "Opened %s." % loaded.map_name
	_close_open()
	_sync_name_field()
	_rebuild_lanes()
	_refresh_labels()


func _save() -> void:
	if data.builtin or MapLibrary.is_builtin(data.id):
		status = "Built-in yards stay read-only. Use Save As."
		Sfx.play("error")
		_refresh_labels()
		return
	var err := MapLibrary.save_custom(data)
	if err != "":
		status = err
		Sfx.play("error")
		_refresh_labels()
		return
	status = "Saved %s." % data.map_name
	Sfx.play("ui")
	_refresh_labels()


func _save_as() -> void:
	var copy := data.duplicate_map()
	copy.builtin = false
	var base := copy.map_name if copy.map_name.strip_edges() != "" else "custom yard"
	copy.id = MapLibrary.unique_id(base)
	if copy.id == "":
		copy.id = MapLibrary.unique_id("custom yard")
	var err := MapLibrary.save_custom(copy)
	if err != "":
		status = err
		Sfx.play("error")
		_refresh_labels()
		return
	data = copy
	status = "Saved a copy as %s." % data.id
	Sfx.play("ui")
	_sync_name_field()
	_refresh_labels()


func _on_delete() -> void:
	var err := MapLibrary.delete_custom(data.id)
	if err != "":
		status = err
		Sfx.play("error")
	else:
		status = "Deleted the file. This copy is still open."
		Sfx.play("ui")
	_refresh_labels()


func _playtest() -> void:
	if not MapValidator.ok(data):
		status = problems[0] if not problems.is_empty() else "Fix the yard before a playtest."
		Sfx.play("error")
		_refresh_labels()
		return
	Sfx.play("ui")
	MapSession.begin_playtest(data)
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(RUN)


func _back() -> void:
	Sfx.play("ui")
	MapSession.clear_override()
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MENU)


func _label(font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(font: Font, text: String, width: int, height: int, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, height)
	button.size = Vector2(width, height)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#5a3d70"))
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color("#fff6ee")
	style_box.border_color = Color("#e7b4d0")
	style_box.set_border_width_all(3)
	style_box.set_corner_radius_all(12)
	style_box.content_margin_left = 8
	style_box.content_margin_right = 8
	button.add_theme_stylebox_override("normal", style_box)
	var hover := style_box.duplicate()
	hover.bg_color = Color("#fffaf4")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var disabled := style_box.duplicate()
	disabled.bg_color = Color("#e6d8e4")
	button.add_theme_stylebox_override("disabled", disabled)
	return button
