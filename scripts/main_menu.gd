extends Control

const RUN := "res://scenes/main.tscn"
const UNLOCKS := "res://scenes/unlocks.tscn"
const BESTIARY := "res://scenes/bestiary.tscn"
const MAP_SELECT := "res://scenes/map_select.tscn"
const SETTINGS := "res://scenes/settings.tscn"
const EDITOR := "res://scenes/map_editor.tscn"
const BRIGHT_SPLASH := "res://assets/ui/main_menu_splash.png"
const DIM_SPLASH := "res://assets/ui/main_menu_splash_dim.png"
const FADE_TIME := 0.8

var _bright: TextureRect
var _ui: Control
var _buttons: Array[Button] = []
var _notice: Label
var _fade := 0.0


func _ready() -> void:
	Engine.time_scale = 1.0
	if OS.get_environment("SCRAPYARD_SMOKE") == "1" or OS.get_environment("SCRAPYARD_AUTOPLAY") == "1":
		get_tree().call_deferred("change_scene_to_file", RUN)
		return
	_build()


func _process(delta: float) -> void:
	if _bright == null or _fade >= 1.0:
		set_process(false)
		return
	_fade = minf(1.0, _fade + delta / FADE_TIME)
	var t := smoothstep(0.0, 1.0, _fade)
	_bright.modulate.a = 1.0 - t
	if _ui:
		_ui.modulate.a = t
	var ready := t > 0.45
	for button in _buttons:
		button.disabled = not ready
	if _fade >= 1.0:
		set_process(false)


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font := Art.ui_font()

	var dim := _splash(DIM_SPLASH)
	add_child(dim)
	_bright = _splash(BRIGHT_SPLASH)
	add_child(_bright)

	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.modulate.a = 0.0
	add_child(ui)
	_ui = ui

	var title := _label(font, 58, Color("#fff6e4"))
	title.text = "Scrapyard TD"
	title.position = Vector2(0, 18)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#1a1030"))
	title.add_theme_constant_override("outline_size", 14)
	ui.add_child(title)

	var scrap := _label(font, 26, Color("#ffe08a"))
	scrap.text = "SCRAP  %d" % Profile.scrap
	scrap.position = Vector2(0, 92)
	scrap.size = Vector2(1280, 36)
	scrap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scrap.add_theme_color_override("font_outline_color", Color("#1a1030"))
	scrap.add_theme_constant_override("outline_size", 8)
	ui.add_child(scrap)

	var specs := [
		["Battle", Color("#b6f3c8"), _battle],
		["Adventure\nComing Soon", Color("#ddd4ee"), _adventure],
		["Unlocks", Color("#ffe9a8"), _unlocks],
		["Bestiary", Color("#d8f4ff"), _bestiary],
		["Map Editor\nbeta", Color("#c9f6ff"), _editor],
		["Settings", Color("#efe4ff"), _settings],
		["Quit", Color("#ffe0f0"), _quit_game],
	]
	var widths := [120, 168, 118, 128, 140, 118, 88]
	var gap := 8
	var total := gap * (widths.size() - 1)
	for w in widths:
		total += w
	var x := (1280 - total) / 2.0
	for i in specs.size():
		var button := _button(font, specs[i][0], specs[i][1], 14 if i == 1 or i == 4 else 18)
		button.position = Vector2(x, 624)
		button.size = Vector2(widths[i], 72)
		button.disabled = true
		button.pressed.connect(specs[i][2])
		ui.add_child(button)
		_buttons.append(button)
		x += widths[i] + gap

	_notice = _label(font, 18, Color("#fff6e4"))
	_notice.position = Vector2(0, 584)
	_notice.size = Vector2(1280, 28)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.add_theme_color_override("font_outline_color", Color("#1a1030"))
	_notice.add_theme_constant_override("outline_size", 6)
	ui.add_child(_notice)


func _splash(path: String) -> TextureRect:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = load(path)
	if backdrop.texture == null:
		push_error("Missing menu splash: %s" % path)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return backdrop


func _label(font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(font: Font, text: String, bg: Color, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("#5a3d70"))
	button.add_theme_color_override("font_hover_color", Color("#3d2858"))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("#e7b4d0")
	style.set_border_width_all(4)
	style.set_corner_radius_all(18)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = bg.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var disabled := style.duplicate()
	disabled.bg_color = bg.darkened(0.08)
	button.add_theme_stylebox_override("disabled", disabled)
	return button


func _battle() -> void:
	Sfx.play("ui")
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MAP_SELECT)


func _adventure() -> void:
	Sfx.play("error")
	if _notice:
		_notice.text = "Adventure is coming soon."


func _unlocks() -> void:
	Sfx.play("ui")
	get_tree().change_scene_to_file(UNLOCKS)


func _bestiary() -> void:
	Sfx.play("ui")
	get_tree().change_scene_to_file(BESTIARY)


func _editor() -> void:
	Sfx.play("ui")
	if MapSession.editor_json == "":
		MapSession.clear_override()
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(EDITOR)


func _settings() -> void:
	Sfx.play("ui")
	get_tree().change_scene_to_file(SETTINGS)


func _quit_game() -> void:
	get_tree().quit()
