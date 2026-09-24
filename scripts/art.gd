class_name Art
extends RefCounted

static var _font: Font

const ENEMY := {
	"eye_squid": "res://assets/sprites/enemies/eye_squid.png",
	"star_toad": "res://assets/sprites/enemies/star_toad.png",
	"halo_wisp": "res://assets/sprites/enemies/halo_wisp.png",
	"egg_sac": "res://assets/sprites/enemies/egg_sac.png",
	"fractal_baby": "res://assets/sprites/enemies/fractal_baby.png",
	"grand_nibbler": "res://assets/sprites/enemies/grand_nibbler.png",
}

const TOWER := {
	"pea": "res://assets/sprites/towers/pea.png",
	"spark": "res://assets/sprites/towers/spark.png",
	"glue": "res://assets/sprites/towers/glue.png",
	"boom": "res://assets/sprites/towers/boom.png",
	"magnet": "res://assets/sprites/towers/magnet.png",
}

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


static func tower_tex(kind: String) -> Texture2D:
	return load(TOWER[kind])


static func projectile_tex(kind: String) -> Texture2D:
	return load(PROJECTILE.get(kind, PROJECTILE["pea"]))
