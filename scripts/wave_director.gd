extends Node

var queue: Array = []
var spawn_wait := 0.0
var lane_flip := 0


func start() -> void:
	_begin_prep(0)


func call_early() -> void:
	if Game.phase != "prep" or Game.ended:
		return
	var bonus := Game.early_bonus()
	if bonus > 0:
		Game.add_gold(bonus)
		var fx = get_tree().get_first_node_in_group("vfx")
		if fx:
			fx.float_text(Board.cell_center(Vector2i(11, 5)), "+%d early" % bonus, Color("#ffe08a"))
		Sfx.play("scrap")
	_begin_combat()


func _begin_prep(index: int) -> void:
	Game.phase = "prep"
	Game.upcoming = index
	Game.preview = str(Balance.wave_at(index)["preview"])
	Game.prep_left = 16.0 if index == 0 else 9.0
	Game.combat_label = ""
	Game.changed.emit()


func _begin_combat() -> void:
	var index := Game.upcoming
	var wave: Dictionary = Balance.wave_at(index)
	Game.wave_index = index
	Game.phase = "combat"
	Game.combat_label = str(wave["title"])
	Game.banner = str(wave["title"])
	Game.banner_t = 2.15
	Game.preview = str(wave["preview"])
	queue = _build_queue(wave)
	spawn_wait = 0.4
	lane_flip = 0
	Sfx.play("wave")
	Game.changed.emit()
	if Game.autoplay:
		print("WAVE %d %s hp=%d gold=%d" % [index + 1, wave["title"], Game.core_hp, Game.gold])
		if wave.get("boss", false):
			for tower in get_tree().get_nodes_in_group("towers"):
				print("  TOWER %s T%d %s" % [tower.kind, tower.tier, tower.cell])


func _build_queue(wave: Dictionary) -> Array:
	var pools: Array = []
	for entry in wave["entries"]:
		pools.append({
			"kind": entry["kind"],
			"left": int(entry["count"]),
			"lane": entry["lane"],
			"gap": float(entry["gap"]),
		})
	var out: Array = []
	var guard := 0
	while guard < 800:
		var any := false
		for pool in pools:
			if int(pool["left"]) <= 0:
				continue
			out.append({
				"kind": pool["kind"],
				"lane": pool["lane"],
				"gap": pool["gap"],
			})
			pool["left"] = int(pool["left"]) - 1
			any = true
		if not any:
			break
		guard += 1
	return out


func _process(delta: float) -> void:
	if Game.ended:
		return
	if Game.phase == "prep":
		Game.prep_left = max(0.0, Game.prep_left - delta)
		if Game.prep_left <= 0.0:
			_begin_combat()
		return
	if Game.phase != "combat":
		return
	if not queue.is_empty():
		spawn_wait -= delta
		while spawn_wait <= 0.0 and not queue.is_empty():
			var item: Dictionary = queue.pop_front()
			_spawn_item(item)
			spawn_wait += float(item["gap"])
	if queue.is_empty() and _living() == 0:
		_on_clear()


func _spawn_item(item: Dictionary) -> void:
	var lane := str(item["lane"])
	if lane == "alt":
		var count := maxi(1, Board.lane_ids.size())
		lane = Board.lane_ids[lane_flip % count] if not Board.lane_ids.is_empty() else "a"
		lane_flip += 1
	get_parent().spawn_enemy(str(item["kind"]), lane)


func _living() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.alive:
			count += 1
	return count


func _on_clear() -> void:
	if Game.ended:
		return
	if Game.wave_index >= Balance.WAVE_COUNT - 1:
		Game.win()
	else:
		_begin_prep(Game.wave_index + 1)
