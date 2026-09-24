class_name Board
extends RefCounted

## 24×11 yard. One tile is one cell. Lanes are orthogonal cell sequences.
## Build slots are exact cells. Nothing places off the grid.

const COLS := 24
const ROWS := 11
const TILE := 48
const ORIGIN := Vector2(64, 80)
const CORE := Vector2i(22, 5)

const SLOTS: Array[Vector2i] = [
	Vector2i(2, 0),
	Vector2i(5, 2),
	Vector2i(9, 2),
	Vector2i(15, 2),
	Vector2i(2, 10),
	Vector2i(6, 8),
	Vector2i(15, 8),
	Vector2i(20, 6),
]

static var lane_a: Array[Vector2i] = []
static var lane_b: Array[Vector2i] = []
static var path_info: Dictionary = {}
static var spawn_a: Vector2i = Vector2i.ZERO
static var spawn_b: Vector2i = Vector2i.ZERO
static var _ready_paths := false


static func ensure() -> void:
	if _ready_paths:
		return
	_ready_paths = true
	lane_a = _walk([
		Vector2i(0, 1), Vector2i(12, 1), Vector2i(12, 3),
		Vector2i(19, 3), Vector2i(19, 5), Vector2i(22, 5),
	])
	lane_b = _walk([
		Vector2i(0, 9), Vector2i(11, 9), Vector2i(11, 7),
		Vector2i(19, 7), Vector2i(19, 5), Vector2i(22, 5),
	])
	spawn_a = lane_a[0]
	spawn_b = lane_b[0]
	path_info = {}
	for i in range(lane_a.size() - 1):
		var cell := lane_a[i]
		path_info[cell] = {"lane": "a", "dir": lane_a[i + 1] - cell}
	for i in range(lane_b.size() - 1):
		var cell := lane_b[i]
		var dir := lane_b[i + 1] - cell
		if path_info.has(cell):
			path_info[cell]["lane"] = "both"
			path_info[cell]["dir"] = dir
		else:
			path_info[cell] = {"lane": "b", "dir": dir}
	path_info[CORE] = {"lane": "core", "dir": Vector2i.ZERO}


static func lane(which: String) -> Array[Vector2i]:
	ensure()
	return lane_a if which == "a" else lane_b


static func is_slot(cell: Vector2i) -> bool:
	return cell in SLOTS


static func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < COLS and cell.y < ROWS


static func cell_center(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell.x + 0.5, cell.y + 0.5) * float(TILE)


static func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(ORIGIN + Vector2(cell) * float(TILE), Vector2(TILE, TILE))


static func world_to_cell(world: Vector2) -> Vector2i:
	var local := world - ORIGIN
	return Vector2i(int(floor(local.x / float(TILE))), int(floor(local.y / float(TILE))))


static func cells_in_range(origin: Vector2i, radius: float) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var reach := int(ceil(radius))
	for y in range(origin.y - reach, origin.y + reach + 1):
		for x in range(origin.x - reach, origin.x + reach + 1):
			var cell := Vector2i(x, y)
			if not is_inside(cell):
				continue
			if Vector2(x - origin.x, y - origin.y).length() <= radius + 0.001:
				result.append(cell)
	return result


static func validate() -> PackedStringArray:
	ensure()
	var errs := PackedStringArray()
	if SLOTS.size() != 8:
		errs.append("expected 8 build slots")
	if lane_a.is_empty() or lane_b.is_empty():
		errs.append("lanes missing")
	_check_lane(lane_a, "north", errs)
	_check_lane(lane_b, "south", errs)
	var seen := {}
	for cell in SLOTS:
		if not is_inside(cell):
			errs.append("slot out of bounds %s" % cell)
		if path_info.has(cell):
			errs.append("slot sits on a lane %s" % cell)
		if seen.has(cell):
			errs.append("duplicate slot %s" % cell)
		seen[cell] = true
	# Shared tail must agree on direction.
	for i in range(lane_a.size() - 1):
		var cell: Vector2i = lane_a[i]
		if not path_info.has(cell):
			continue
		if str(path_info[cell]["lane"]) == "both":
			var dir_a: Vector2i = lane_a[i + 1] - cell
			var dir_b: Vector2i = path_info[cell]["dir"]
			if dir_a != dir_b:
				errs.append("shared cell direction mismatch %s" % cell)
	return errs


static func _check_lane(cells: Array[Vector2i], name: String, errs: PackedStringArray) -> void:
	if cells[-1] != CORE:
		errs.append("%s lane must end on the core" % name)
	for i in range(1, cells.size()):
		var step: Vector2i = cells[i] - cells[i - 1]
		if absi(step.x) + absi(step.y) != 1:
			errs.append("%s lane leaves the grid at %s" % [name, cells[i - 1]])


static func _walk(points: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for point in points:
		var target := point as Vector2i
		if cells.is_empty():
			cells.append(target)
			continue
		var cur := cells[-1]
		while cur != target:
			var delta := target - cur
			var step := Vector2i(signi(delta.x), signi(delta.y))
			if absi(step.x) + absi(step.y) != 1:
				push_error("Board waypoint is not orthogonal: %s -> %s" % [cur, target])
				break
			cur += step
			cells.append(cur)
	return cells
