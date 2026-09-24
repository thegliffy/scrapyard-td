extends Control

const RUN := "res://scenes/main.tscn"
const BRIGHT_SPLASH := "res://assets/concept/05_main_menu_splash.png"
const DIM_SPLASH := "res://assets/concept/05_main_menu_splash_dim.png"
const FADE_TIME := 0.8

var _bright: TextureRect
var _card: Panel
var _play: Button
var _quit: Button
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
	if _card:
		_card.modulate.a = t
	var ready := t > 0.45
	if _play:
		_play.disabled = not ready
	if _quit:
		_quit.disabled = not ready
	if _fade >= 1.0:
		set_process(false)


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var font := Art.ui_font()

	var dim := _splash(DIM_SPLASH)
	add_child(dim)
	_bright = _splash(BRIGHT_SPLASH)
	add_child(_bright)

	var card := Panel.new()
	card.position = Vector2(56, 150)
	card.size = Vector2(460, 420)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.97, 0.94, 0.92)
	style.border_color = Color("#f0b6d4")
	style.set_border_width_all(6)
	style.set_corner_radius_all(32)
	style.shadow_color = Color(0.45, 0.28, 0.55, 0.18)
	style.shadow_size = 18
	card.add_theme_stylebox_override("panel", style)
	card.modulate.a = 0.0
	add_child(card)
	_card = card

	var title := _label(font, 54, Color("#6a3d88"))
	title.text = "Scrapyard TD"
	title.position = Vector2(28, 36)
	title.size = Vector2(404, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)

	var flavor := _label(font, 20, Color("#8a6498"))
	flavor.text = "Cute guns. Cuter monsters.\nKeep the core lit."
	flavor.position = Vector2(28, 118)
	flavor.size = Vector2(404, 64)
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(flavor)

	_play = _button(font, "Play", Color("#b6f3c8"))
	_play.position = Vector2(70, 220)
	_play.disabled = true
	_play.pressed.connect(_play_run)
	card.add_child(_play)

	_quit = _button(font, "Quit", Color("#ffe0f0"))
	_quit.position = Vector2(70, 304)
	_quit.disabled = true
	_quit.pressed.connect(_quit_game)
	card.add_child(_quit)


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


func _button(font: Font, text: String, bg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.size = Vector2(320, 64)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("#5a3d70"))
	button.add_theme_color_override("font_hover_color", Color("#3d2858"))
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = Color("#e7b4d0")
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = bg.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button


func _play_run() -> void:
	Sfx.play("ui")
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(RUN)


func _quit_game() -> void:
	get_tree().quit()
