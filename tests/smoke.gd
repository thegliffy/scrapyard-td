extends SceneTree

## Grid contract check. Gameplay smoke runs with SCRAPYARD_SMOKE=1
## because autoload singletons are easier to reach from the main scene.


func _initialize() -> void:
	Board.ensure()
	var errs := Board.validate()
	if errs.size() > 0:
		for err in errs:
			push_error(err)
		quit(1)
		return
	var reach := Board.cells_in_range(Vector2i(2, 0), 3.5)
	if not (Vector2i(2, 1) in reach) or Vector2i(22, 5) in reach:
		push_error("range highlight is not grid-native")
		quit(1)
		return
	for cell in Board.SLOTS:
		if not Board.is_inside(cell) or Board.path_info.has(cell):
			push_error("slot is not a free grid cell: %s" % cell)
			quit(1)
			return
	print("GRID_OK")
	quit(0)
