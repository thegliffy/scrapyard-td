class_name Art
extends RefCounted

static var _font: Font

const ENEMY := {
	"fast_skitter": "res://assets/sprites/enemies/fast_skitter.png",
	"chunky_tank": "res://assets/sprites/enemies/chunky_tank.png",
	"shielded": "res://assets/sprites/enemies/shielded.png",
	"swarm_splitter": "res://assets/sprites/enemies/swarm_splitter.png",
	"swarmling": "res://assets/sprites/enemies/swarmling.png",
	"big_cute_boss": "res://assets/sprites/enemies/big_cute_boss.png",
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
