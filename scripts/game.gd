extends Node

signal changed
signal core_hit(amount: int)
signal game_over(won: bool)

var gold: int = Balance.START_GOLD
var meta_awarded: int = 0
var core_hp: int = Balance.CORE_HP
var core_max: int = Balance.CORE_HP
var wave_index: int = -1
var upcoming: int = 0
var wave_total: int = Balance.WAVE_COUNT
var phase: String = "boot"
var prep_left: float = 0.0
var preview: String = ""
var combat_label: String = ""
var banner: String = ""
var banner_t: float = 0.0
var kills: int = 0
var leaks: int = 0
var earned: int = 0
var ended: bool = false
var speed: float = 1.0
var autoplay: bool = false


func boot() -> void:
	gold = Balance.START_GOLD
	meta_awarded = 0
	core_max = Balance.CORE_HP
	core_hp = core_max
	wave_index = -1
	upcoming = 0
	wave_total = Balance.WAVE_COUNT
	phase = "boot"
	prep_left = 0.0
	preview = ""
	combat_label = ""
	banner = ""
	banner_t = 0.0
	kills = 0
	leaks = 0
	earned = 0
	ended = false
	speed = 1.0
	if not autoplay:
		Engine.time_scale = 1.0
	changed.emit()


func _process(delta: float) -> void:
	if banner_t > 0.0:
		banner_t = max(0.0, banner_t - delta)


func add_gold(amount: int) -> void:
	if amount == 0:
		return
	gold += amount
	if amount > 0:
		earned += amount
	changed.emit()


func try_spend(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	changed.emit()
	return true


func register_kill(amount: int) -> void:
	kills += 1
	add_gold(amount)


func damage_core(amount: int) -> void:
	if ended:
		return
	core_hp = maxi(0, core_hp - amount)
	leaks += 1
	changed.emit()
	core_hit.emit(amount)
	if autoplay:
		print("LEAK %d hp=%d wave=%d" % [amount, core_hp, wave_index + 1])
	if core_hp <= 0:
		finish(false)


func win() -> void:
	finish(true)


func finish(won: bool) -> void:
	if ended:
		return
	ended = true
	phase = "win" if won else "lose"
	speed = 1.0
	Engine.time_scale = 1.0
	if not autoplay:
		var cleared := maxi(0, wave_index + 1) if won else 0
		if MapSession.blocks_scrap():
			meta_awarded = 0
		else:
			meta_awarded = Profile.award_battle(won, cleared)
	changed.emit()
	game_over.emit(won)


func toggle_speed() -> void:
	if ended:
		return
	speed = 1.0 if speed > 1.5 else 2.0
	Engine.time_scale = speed
	changed.emit()


func display_wave() -> int:
	if phase == "prep":
		return upcoming + 1
	if wave_index < 0:
		return 1
	return wave_index + 1


## The prep before wave 1. No clock, no bonus, and auto-call does not skip it.
func is_first_prep() -> bool:
	return phase == "prep" and upcoming == 0


func early_bonus() -> int:
	if not is_first_prep() and phase == "prep":
		return mini(12, int(floor(prep_left)))
	return 0
