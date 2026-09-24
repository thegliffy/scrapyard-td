extends Control

var main: Node
var font: Font
var gold_label: Label
var wave_label: Label
var core_label: Label
var status_label: Label
var banner_label: Label
var info_label: Label
var boss_label: Label
var upgrade_button: Button
var sell_button: Button
var call_button: Button
var speed_button: Button
var mute_button: Button
var core_fill: ColorRect
var boss_fill: ColorRect
var boss_track: ColorRect
var flash: ColorRect
var chips := {}

const CHIP_KINDS := ["pea", "spark", "glue", "boom", "magnet"]
const CHIP_COLORS := {
	"pea": Color("#c6ee9a"),
	"spark": Color("#ffe58a"),
	"glue": Color("#9af0ea"),
	"boom": Color("#ffc09a"),
	"magnet": Color("#f3b4ea"),
}


func _ready() -> void:
	main = get_parent().get_parent()
	font = Art.ui_font()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	Game.changed.connect(refresh_all)
	refresh_all()


func _process(_delta: float) -> void:
	_refresh_live()
	if flash and flash.color.a > 0.0:
		var color := flash.color
		color.a = max(0.0, color.a - _delta * 1.3)
		flash.color = color


func pulse_hurt() -> void:
	if flash:
		flash.color = Color(1, 0.45, 0.62, 0.38)


func refresh_all() -> void:
	if gold_label == null:
		return
	gold_label.text = "GOLD  %d" % Game.gold
	wave_label.text = "WAVE  %d / %d" % [Game.display_wave(), Game.wave_total]
	core_label.text = "%d / %d" % [Game.core_hp, Game.core_max]
	var ratio := 0.0 if Game.core_max == 0 else clampf(float(Game.core_hp) / float(Game.core_max), 0.0, 1.0)
	core_fill.size = Vector2(220.0 * ratio, 14)
	core_fill.color = Color("#ff8aa8") if ratio < 0.35 else Color("#7dffc0")
	speed_button.text = "2×" if Game.speed > 1.5 else "1×"
	mute_button.text = "Muted" if Sfx.muted else "Sound"
	_style_chips()
	_fill_info()


func _refresh_live() -> void:
	if status_label == null:
		return
	if Game.phase == "prep":
		status_label.text = "Next in %ds   ·   %s" % [int(ceil(Game.prep_left)), Game.preview]
		call_button.disabled = false
		call_button.text = "Call\n+%d" % Game.early_bonus()
	elif Game.phase == "combat":
		status_label.text = "%s   ·   %s" % [Game.combat_label, Game.preview]
		call_button.disabled = true
		call_button.text = "On the lane"
	elif Game.phase == "win":
		status_label.text = "Yard's quiet"
		call_button.disabled = true
	elif Game.phase == "lose":
		status_label.text = "Core went dark"
		call_button.disabled = true
	var show_banner := Game.banner_t > 0.05
	banner_label.visible = show_banner
	banner_label.text = Game.banner
	banner_label.modulate.a = clampf(Game.banner_t, 0.0, 1.0)
	var boss = _boss()
	var show_boss := boss != null
	boss_label.visible = show_boss
	boss_track.visible = show_boss
	if show_boss:
		boss_label.text = str(boss.display_name)
		var hp_ratio := clampf(boss.hp / boss.max_hp, 0.0, 1.0)
		boss_fill.size = Vector2(180.0 * hp_ratio, 12)


func _boss():
	var nodes := get_tree().get_nodes_in_group("boss")
	for node in nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion() and node.alive:
			return node
	return null


func _build() -> void:
	var top := Panel.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(1280, 80)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	top.add_theme_stylebox_override("panel", _panel_style(true))
	add_child(top)

	var title := _text(Profile.map_name().to_upper(), 18, Color("#6a3d88"))
	title.position = Vector2(18, 8)
	title.size = Vector2(220, 30)
	top.add_child(title)
	wave_label = _text("WAVE  1 / 21", 26, Color("#5c3d78"))
	wave_label.position = Vector2(280, 6)
	wave_label.size = Vector2(560, 34)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(wave_label)

	status_label = _text("", 13, Color("#7a6494"))
	status_label.position = Vector2(390, 40)
	status_label.size = Vector2(420, 36)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.clip_text = true
	top.add_child(status_label)

	var scrap_icon := TextureRect.new()
	scrap_icon.texture = load("res://assets/sprites/ui/scrap.png")
	scrap_icon.position = Vector2(900, 18)
	scrap_icon.size = Vector2(36, 36)
	scrap_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrap_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	scrap_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(scrap_icon)
	gold_label = _text("GOLD  %d" % Balance.START_GOLD, 24, Color("#c47a20"))
	gold_label.position = Vector2(944, 16)
	gold_label.size = Vector2(320, 40)
	top.add_child(gold_label)

	var core_name := _text("CORE", 14, Color("#2f8a62"))
	core_name.position = Vector2(18, 46)
	core_name.size = Vector2(52, 20)
	top.add_child(core_name)
	var track := ColorRect.new()
	track.position = Vector2(70, 48)
	track.size = Vector2(220, 14)
	track.color = Color("#efe0ff")
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(track)
	core_fill = ColorRect.new()
	core_fill.position = Vector2(0, 0)
	core_fill.size = Vector2(220, 14)
	core_fill.color = Color("#7dffc0")
	core_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(core_fill)
	core_label = _text("22 / 22", 14, Color("#4a3568"))
	core_label.position = Vector2(296, 44)
	core_label.size = Vector2(90, 22)
	top.add_child(core_label)

	boss_label = _text("Big Cute Boss", 14, Color("#7a5aaa"))
	boss_label.position = Vector2(820, 44)
	boss_label.size = Vector2(160, 22)
	boss_label.visible = false
	top.add_child(boss_label)
	boss_track = ColorRect.new()
	boss_track.position = Vector2(990, 48)
	boss_track.size = Vector2(180, 12)
	boss_track.color = Color("#efe0ff")
	boss_track.visible = false
	boss_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(boss_track)
	boss_fill = ColorRect.new()
	boss_fill.size = Vector2(180, 12)
	boss_fill.color = Color("#c6b0ff")
	boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_track.add_child(boss_fill)

	var bottom := Panel.new()
	bottom.position = Vector2(0, 608)
	bottom.size = Vector2(1280, 112)
	bottom.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom.add_theme_stylebox_override("panel", _panel_style(false))
	add_child(bottom)

	var entries: Array = Profile.equipped_entries()
	for entry in entries:
		var slot := int(entry["slot"])
		var kind: String = str(entry["id"])
		var button := Button.new()
		button.clip_contents = true
		button.focus_mode = Control.FOCUS_NONE
		button.position = Vector2(12 + slot * 136, 12)
		button.size = Vector2(128, 88)
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("#2a2048"))
		button.add_theme_color_override("font_hover_color", Color("#1a1430"))
		button.add_theme_color_override("font_pressed_color", Color("#1a1430"))
		button.text = ""
		button.pressed.connect(_on_chip.bind(kind))
		var icon_rect := _chip_icon_rect()
		var icon := Art.make_tower_icon(icon_rect, kind)
		button.add_child(icon)
		Art.show_tower_icon(icon, kind)
		var caption := Label.new()
		caption.text = "%d  %s   %d" % [slot + 1, Balance.TOWERS[kind]["short"], Balance.cost(kind)]
		caption.position = Vector2(6, icon_rect.end.y + 4.0)
		caption.size = Vector2(116, 16)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		caption.add_theme_font_override("font", font)
		caption.add_theme_font_size_override("font_size", 14)
		caption.add_theme_color_override("font_color", Color("#2a2048"))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(caption)
		chips[kind] = button
		bottom.add_child(button)

	var info := Panel.new()
	info.position = Vector2(696, 12)
	info.size = Vector2(250, 88)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color("#fffaf4")
	info_style.border_color = Color("#f0c4de")
	info_style.set_border_width_all(3)
	info_style.set_corner_radius_all(14)
	info.add_theme_stylebox_override("panel", info_style)
	bottom.add_child(info)

	info_label = _text("", 14, Color("#4a3568"))
	info_label.position = Vector2(10, 6)
	info_label.size = Vector2(230, 44)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.clip_text = true
	info.add_child(info_label)

	upgrade_button = _small_button("Upgrade")
	upgrade_button.position = Vector2(10, 50)
	upgrade_button.size = Vector2(110, 30)
	sell_button = _small_button("Sell")
	sell_button.position = Vector2(128, 50)
	sell_button.size = Vector2(110, 30)
	upgrade_button.pressed.connect(func():
		Sfx.play("ui")
		main.upgrade_selected()
	)
	sell_button.pressed.connect(func():
		Sfx.play("ui")
		main.sell_selected()
	)
	info.add_child(upgrade_button)
	info.add_child(sell_button)

	call_button = _small_button("Call")
	call_button.position = Vector2(958, 12)
	call_button.size = Vector2(110, 88)
	call_button.add_theme_font_size_override("font_size", 16)
	call_button.pressed.connect(func():
		Sfx.play("ui")
		main.call_early()
	)
	bottom.add_child(call_button)

	speed_button = _small_button("1×")
	speed_button.position = Vector2(1078, 12)
	speed_button.size = Vector2(84, 88)
	speed_button.pressed.connect(func():
		Game.toggle_speed()
		refresh_all()
	)
	bottom.add_child(speed_button)

	mute_button = _small_button("Sound")
	mute_button.position = Vector2(1172, 12)
	mute_button.size = Vector2(96, 88)
	mute_button.pressed.connect(func():
		Profile.set_muted(not Sfx.muted)
		if not Sfx.muted:
			Sfx.play("ui")
		refresh_all()
	)
	bottom.add_child(mute_button)

	banner_label = _text("", 42, Color("#6a3d88"))
	banner_label.position = Vector2(200, 250)
	banner_label.size = Vector2(880, 70)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_label.visible = false
	banner_label.add_theme_color_override("font_outline_color", Color("#fffaf4"))
	banner_label.add_theme_constant_override("outline_size", 10)
	add_child(banner_label)

	flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 0.4, 0.55, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	_style_chips()


## Largest square that stays inside the 128×88 chip with at least 10px
## above the gun and a caption band below it.
func _chip_icon_rect() -> Rect2:
	var top := 10.0
	var bottom := 6.0
	var caption_h := 16.0
	var gap := 4.0
	var side := 88.0 - top - gap - caption_h - bottom
	var x := (128.0 - side) * 0.5
	return Rect2(x, top, side, side)


func _on_chip(kind: String) -> void:
	Sfx.play("ui")
	main.select_build(kind)


func _style_chips() -> void:
	for kind in chips.keys():
		var button: Button = chips[kind]
		var border := Color("#e8a04a") if main and main.build_kind == kind else Color("#f0c4de")
		var width := 5 if main and main.build_kind == kind else 3
		var style := _chip_style(CHIP_COLORS[kind], border, width)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("focus", style)


func _fill_info() -> void:
	if main == null:
		return
	var tower = null
	if main.selected_cell != null:
		tower = main.tower_at(main.selected_cell)
	if tower != null:
		info_label.text = _tower_blurb(tower)
		upgrade_button.visible = true
		sell_button.visible = true
		var refund := int(floor(float(tower.invested) * 0.6))
		sell_button.text = "Sell %d" % refund
		if tower.tier >= 3:
			upgrade_button.text = "Maxed"
			upgrade_button.disabled = true
		else:
			upgrade_button.text = "Up %d" % tower.upgrade_cost()
			upgrade_button.disabled = false
		return
	upgrade_button.visible = false
	sell_button.visible = false
	if main.build_kind != "":
		var id: String = main.build_kind
		var data: Dictionary = Balance.TOWERS[id]
		info_label.text = "Placing %s · %d\nRange %.1f tiles" % [
			data["name"], Balance.cost(id), Balance.tier_value(id, "range", 1)
		]
	else:
		info_label.text = "Gold pads only. Cover both rifts.\n1–5 build, U upgrade, Space call."


func _tower_blurb(tower) -> String:
	var data: Dictionary = Balance.TOWERS[tower.kind]
	var detail := ""
	match tower.kind:
		"spark":
			detail = "%.0f dmg, %d jumps" % [
				Balance.tier_value(tower.kind, "damage", tower.tier),
				int(Balance.tier_value(tower.kind, "chains", tower.tier)),
			]
		"glue":
			var slow := Balance.tier_value(tower.kind, "slow", tower.tier)
			detail = "slow %d%% for %.1fs" % [int(round((1.0 - slow) * 100.0)), Balance.tier_value(tower.kind, "slow_time", tower.tier)]
		"boom":
			detail = "%.0f dmg, splash %.1f" % [
				Balance.tier_value(tower.kind, "damage", tower.tier),
				Balance.tier_value(tower.kind, "splash", tower.tier),
			]
		"magnet":
			detail = "+%d / %.0fs, +%d pops" % [
				int(Balance.tier_value(tower.kind, "income", tower.tier)),
				Balance.tier_value(tower.kind, "income_every", tower.tier),
				int(Balance.tier_value(tower.kind, "bonus", tower.tier)),
			]
		_:
			detail = "%.0f dmg, %.1f/s" % [
				Balance.tier_value(tower.kind, "damage", tower.tier),
				Balance.tier_value(tower.kind, "rate", tower.tier),
			]
	return "%s  T%d/3\n%s · %.1f tiles" % [data["name"], tower.tier, detail, tower.range_tiles()]


func _text(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(top_bar: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff6ee")
	style.border_color = Color("#f0c4de")
	if top_bar:
		style.border_width_bottom = 4
	else:
		style.border_width_top = 4
	return style


func _chip_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(14)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _small_button(value: String) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(78, 32)
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#2a2048"))
	button.add_theme_color_override("font_hover_color", Color("#1a1430"))
	button.add_theme_color_override("font_disabled_color", Color("#6a6280"))
	var style := _chip_style(Color("#fff0f8"), Color("#e7b4d0"), 3)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	var disabled := style.duplicate()
	disabled.bg_color = Color("#f0e4ee")
	button.add_theme_stylebox_override("disabled", disabled)
	return button
