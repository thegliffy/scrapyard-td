extends Control

var title_label: Label
var body_label: Label
var stats_label: Label
var portrait: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()
	Game.game_over.connect(_show)


func _build() -> void:
	var font := Art.ui_font()
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.12, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var card := Panel.new()
	card.position = Vector2(340, 150)
	card.size = Vector2(600, 400)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2a2154")
	style.border_color = Color("#120e22")
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

	title_label = _label(font, 40, Color("#fff6e4"))
	title_label.position = Vector2(148, 36)
	title_label.size = Vector2(420, 52)
	card.add_child(title_label)

	body_label = _label(font, 18, Color("#f0e4ff"))
	body_label.position = Vector2(40, 140)
	body_label.size = Vector2(520, 80)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(body_label)

	stats_label = _label(font, 18, Color("#ffe08a"))
	stats_label.position = Vector2(40, 230)
	stats_label.size = Vector2(520, 80)
	card.add_child(stats_label)

	var button := Button.new()
	button.text = "Try again"
	button.position = Vector2(180, 320)
	button.size = Vector2(240, 52)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#2a2048"))
	button.add_theme_color_override("font_hover_color", Color("#1a1430"))
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color("#b6f3c8")
	bstyle.border_color = Color("#2a2048")
	bstyle.set_border_width_all(4)
	bstyle.set_corner_radius_all(16)
	button.add_theme_stylebox_override("normal", bstyle)
	var hover := bstyle.duplicate()
	hover.bg_color = Color("#d4ffe4")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(_restart)
	card.add_child(button)


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
	stats_label.text = "Wave %d / %d\nPops %d    Leaks %d    Scrap earned %d" % [
		clampi(Game.display_wave(), 1, Game.wave_total),
		Game.wave_total,
		Game.kills,
		Game.leaks,
		Game.earned,
	]


func _restart() -> void:
	Sfx.play("ui")
	var root := get_tree().get_first_node_in_group("game_root")
	if root and root.has_method("restart"):
		root.restart()
	else:
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
