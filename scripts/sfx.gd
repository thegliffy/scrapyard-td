extends Node

var muted := false
var _pool := {}

const FILES := {
	"ui": "res://assets/audio/ui.wav",
	"place": "res://assets/audio/place.wav",
	"upgrade": "res://assets/audio/upgrade.wav",
	"sell": "res://assets/audio/sell.wav",
	"error": "res://assets/audio/error.wav",
	"pea": "res://assets/audio/pea.wav",
	"spark": "res://assets/audio/spark.wav",
	"glue": "res://assets/audio/glue.wav",
	"boom": "res://assets/audio/boom.wav",
	"hit": "res://assets/audio/hit.wav",
	"pop": "res://assets/audio/pop.wav",
	"shield": "res://assets/audio/shield.wav",
	"leak": "res://assets/audio/leak.wav",
	"wave": "res://assets/audio/wave.wav",
	"scrap": "res://assets/audio/scrap.wav",
	"win": "res://assets/audio/win.wav",
	"lose": "res://assets/audio/lose.wav",
}


func _ready() -> void:
	for id in FILES.keys():
		var copies := 4 if id in ["pea", "hit", "pop", "spark", "glue", "boom", "scrap"] else 2
		var stream = load(FILES[id])
		var players: Array[AudioStreamPlayer] = []
		for _i in copies:
			var player := AudioStreamPlayer.new()
			player.stream = stream
			player.volume_db = -8.0
			add_child(player)
			players.append(player)
		_pool[id] = {"players": players, "next": 0}


func play(id: String, pitch: float = 1.0) -> void:
	if muted or not _pool.has(id):
		return
	var bucket: Dictionary = _pool[id]
	var players: Array = bucket["players"]
	if players.is_empty():
		return
	var index := int(bucket["next"]) % players.size()
	bucket["next"] = index + 1
	var player: AudioStreamPlayer = players[index]
	if player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()


func toggle_mute() -> void:
	muted = not muted
	if muted:
		for id in _pool.keys():
			for player in _pool[id]["players"]:
				player.stop()
