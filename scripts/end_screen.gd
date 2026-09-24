extends Control

var title_label: Label
var body_label: Label
var stats_label: Label
var portrait: TextureRect
var again_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()
	Game.game_over.connect(_show)


func _build() -> void:
	var font := Art.ui_font()
	var dim := ColorRect.new()
	dim.color = Color(1, 0.94, 0.98, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var card := Panel.new()
	card.position = Vector2(340, 140)
	card.size = Vector2(600, 430)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff6ee")
	style.border_color = Color("#f0b6d4")
	style.set_border_width_all(6)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 16
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	portrait = TextureRect.new()
	portrait.position = Vector2(36, 28)
	portrait.size = Vector2(96, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(portrait)

	title_label = _label(font, 40, Color("#6a3d88"))
	title_label.position = Vector2(148, 36)
	title_label.size = Vector2(420, 52)
	card.add_child(title_label)

	body_label = _label(font, 18, Color("#7a6494"))
	body_label.position = Vector2(40, 140)
	body_label.size = Vector2(520, 80)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(body_label)

	stats_label = _label(font, 18, Color("#c47a20"))
	stats_label.position = Vector2(40, 230)
	stats_label.size = Vector2(520, 80)
	card.add_child(stats_label)

	again_button = _action_button(font, "Battle again", Color("#b6f3c8"), Color("#d4ffe4"))
	again_button.position = Vector2(36, 328)
	again_button.pressed.connect(_restart)
	card.add_child(again_button)

	var menu := _action_button(font, "Main menu", Color("#ffe0f0"), Color("#fff0f8"))
	menu.position = Vector2(314, 328)
	menu.pressed.connect(_main_menu)
	card.add_child(menu)


func _label(font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _show(won: bool) -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if won:
		title_label.text = "Yard's quiet"
		body_label.text = "Big Cute Boss curled up and drifted off.\nThe Station Core is still humming."
		portrait.texture = Art.enemy_tex("big_cute_boss")
		Sfx.play("win")
	else:
		title_label.text = "Core went dark"
		body_label.text = "The soft things snuggled the reactor\na little too close."
		portrait.texture = load("res://assets/sprites/map/core.png")
		Sfx.play("lose")
	var note := ""
	if MapSession.playtest:
		again_button.text = "Editor"
		note = "\nPlaytest. No scrap."
	else:
		again_button.text = "Battle again"
		if MapSession.blocks_scrap():
			note = "\nCustom yard. No scrap."
	stats_label.text = "Wave %d / %d\nPops %d    Leaks %d    Gold %d\nScrap +%d%s" % [
		clampi(Game.display_wave(), 1, Game.wave_total),
		Game.wave_total,
		Game.kills,
		Game.leaks,
		Game.earned,
		Game.meta_awarded,
		note,
	]


func _action_button(font: Font, text: String, bg: Color, hover_bg: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.size = Vector2(250, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#5a3d70"))
	button.add_theme_color_override("font_hover_color", Color("#3d2858"))
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = bg
	bstyle.border_color = Color("#e7b4d0")
	bstyle.set_border_width_all(4)
	bstyle.set_corner_radius_all(16)
	button.add_theme_stylebox_override("normal", bstyle)
	var hover := bstyle.duplicate()
	hover.bg_color = hover_bg
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button


func _restart() -> void:
	get_tree().paused = false
	Sfx.play("ui")
	if MapSession.playtest:
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/map_editor.tscn")
		return
	var root := get_tree().get_first_node_in_group("game_root")
	if root and root.has_method("restart"):
		root.restart()
	else:
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()


func _main_menu() -> void:
	get_tree().paused = false
	Sfx.play("ui")
	MapSession.clear_override()
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
