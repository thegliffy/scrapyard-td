class_name Art
extends RefCounted

static var _font: Font

const ENEMY := {
	"fast_skitter": "res://assets/sprites/enemies/fast_skitter.png",
	"chunky_tank": "res://assets/sprites/enemies/chunky_tank.png",
	"shielded": "res://assets/sprites/enemies/shielded.png",
	"swarm_splitter": "res://assets/sprites/enemies/swarm_splitter.png",
	"swarmling": "res://assets/sprites/enemies/swarmling.png",
	"tanklet": "res://assets/sprites/enemies/chunky_tank.png",
	"open_shell": "res://assets/sprites/enemies/shielded.png",
	"elite_tank": "res://assets/sprites/enemies/chunky_tank.png",
	"big_cute_boss": "res://assets/sprites/enemies/big_cute_boss.png",
	"small_flyer": "res://assets/sprites/enemies/small_flyer.png",
	"flyer": "res://assets/sprites/enemies/flyer.png",
	"shielded_flyer": "res://assets/sprites/enemies/shielded_flyer.png",
	"flying_boss": "res://assets/sprites/enemies/flying_boss.png",
}

const TOWER := {
	"pea": "res://assets/sprites/towers/pea.png",
	"spark": "res://assets/sprites/towers/spark.png",
	"glue": "res://assets/sprites/towers/glue.png",
	"boom": "res://assets/sprites/towers/boom.png",
	"magnet": "res://assets/sprites/towers/magnet.png",
	"flak": "res://assets/sprites/towers/flak_puff.png",
	"needle": "res://assets/sprites/towers/sky_needle.png",
	"dual": "res://assets/sprites/towers/dual_rail.png",
	"net": "res://assets/sprites/towers/net_lob.png",
	"orbit": "res://assets/sprites/towers/orbit_drone.png",
}

const MAP := {
	"space": "res://assets/sprites/map/backdrop_space.png",
	"path_tile": "res://assets/sprites/map/path_tile_128.png",
	"path_strip": "res://assets/sprites/map/path_strip.png",
	"island_a": "res://assets/sprites/map/hardpoint_island_a_pink.png",
	"island_b": "res://assets/sprites/map/hardpoint_island_b_teal.png",
	"island_c": "res://assets/sprites/map/hardpoint_island_c_crystal.png",
	"core_island": "res://assets/sprites/map/core_island.png",
	"core": "res://assets/sprites/map/core.png",
	"rift": "res://assets/sprites/map/rift.png",
}

const ISLANDS := ["island_a", "island_b", "island_c"]

const PROJECTILE := {
	"pea": "res://assets/sprites/projectiles/pea.png",
	"glue": "res://assets/sprites/projectiles/glue.png",
	"boom": "res://assets/sprites/projectiles/boom.png",
}


static func ui_font() -> Font:
	if _font != null:
		return _font
	var loaded = load("res://assets/fonts/Nunito.ttf")
	if loaded is Font:
		var variant := FontVariation.new()
		variant.base_font = loaded
		variant.variation_opentype = {"wght": 700}
		_font = variant
		return _font
	_font = ThemeDB.fallback_font
	return _font


static func enemy_tex(kind: String) -> Texture2D:
	return load(ENEMY[kind])


static func map_tex(id: String) -> Texture2D:
	return load(MAP[id])


static var _icon_cache := {}


static func tower_tex(kind: String) -> Texture2D:
	return load(TOWER[kind])


## UI icon with the transparent margin trimmed, so the gun fills its box
## instead of scaling a mostly empty canvas.
static func tower_icon(kind: String) -> Texture2D:
	if _icon_cache.has(kind):
		return _icon_cache[kind]
	var source := tower_tex(kind)
	var image := source.get_image()
	if image == null or image.is_empty():
		_icon_cache[kind] = source
		return source
	var bounds := Rect2i(Vector2i.ZERO, image.get_size())
	var used := image.get_used_rect().grow(1).intersection(bounds)
	var trimmed := source
	if used.size.x >= 2 and used.size.y >= 2 and used != bounds:
		trimmed = ImageTexture.create_from_image(image.get_region(used))
	_icon_cache[kind] = trimmed
	return trimmed


## TextureRect.size is ignored if the texture is assigned while expand mode
## is still KEEP_SIZE — the rect stays at the raw image size and overflows
## the chip. Expand mode has to be set before the texture, then the size
## locked again afterwards.
static func make_tower_icon(rect: Rect2, kind: String = "") -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_meta("fit", rect)
	show_tower_icon(icon, kind)
	return icon


static func show_tower_icon(icon: TextureRect, kind: String) -> void:
	var rect: Rect2 = icon.get_meta("fit")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ZERO
	icon.texture = tower_icon(kind) if kind != "" else null
	icon.custom_minimum_size = Vector2.ZERO
	icon.position = rect.position
	icon.size = rect.size


static func projectile_tex(kind: String) -> Texture2D:
	var shot := kind
	if kind == "flak" or kind == "orbit":
		shot = "boom"
	elif kind == "net":
		shot = "glue"
	elif kind == "needle" or kind == "dual":
		shot = "pea"
	return load(PROJECTILE.get(shot, PROJECTILE["pea"]))
