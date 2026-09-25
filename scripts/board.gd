class_name Board
extends RefCounted

## 24×11 yard. One tile is one cell. Lanes are orthogonal cell sequences.
## Build slots are exact cells. Nothing places off the grid.

const TILE := 48

static var COLS := 24
static var ROWS := 11
static var ORIGIN := Vector2(64, 80)
static var CORE := Vector2i(22, 5)
static var active: MapData
static var SLOTS: Array[Vector2i] = []
static var lanes: Array = []
static var lane_ids: PackedStringArray = PackedStringArray()
static var lane_a: Array[Vector2i] = []
static var lane_b: Array[Vector2i] = []
static var path_info: Dictionary = {}
static var spawn_a: Vector2i = Vector2i.ZERO
static var spawn_b: Vector2i = Vector2i.ZERO
static var _ready_paths := false
static var _styles := {}


static func ensure() -> void:
	if _ready_paths and active != null:
		return
	var data := MapLibrary.load_builtin("yard_approach")
	if data == null:
		push_error("Yard Approach failed to load")
		return
	apply(data)


static func apply(data: MapData) -> void:
	active = data
	COLS = data.cols
	ROWS = data.rows
	ORIGIN = data.origin
	CORE = data.core
	lanes = []
	lane_ids = PackedStringArray()
	for lane in data.lanes:
		var cells: Array[Vector2i] = []
		for cell in lane["cells"]:
			cells.append(cell)
		lanes.append(cells)
		lane_ids.append(str(lane.get("id", "a")))
	lane_a = lanes[0] if not lanes.is_empty() else []
	lane_b = lanes[1] if lanes.size() > 1 else lane_a
	spawn_a = lane_a[0] if not lane_a.is_empty() else CORE
	spawn_b = lane_b[0] if not lane_b.is_empty() else spawn_a
	path_info = {}
	for lane_index in lanes.size():
		var cells: Array = lanes[lane_index]
		var lane_name := "a" if lane_index == 0 else ("b" if lane_index == 1 else str(lane_ids[lane_index]))
		for i in range(cells.size() - 1):
			var cell: Vector2i = cells[i]
			var dir: Vector2i = cells[i + 1] - cell
			if path_info.has(cell):
				path_info[cell]["lane"] = "both"
				path_info[cell]["dir"] = dir
			else:
				path_info[cell] = {"lane": lane_name, "dir": dir}
	path_info[CORE] = {"lane": "core", "dir": Vector2i.ZERO}
	SLOTS = data.all_slots()
	_styles = {}
	for cell in SLOTS:
		_styles[cell] = data.style_at(cell)
	_ready_paths = true


static func style_at(cell: Vector2i) -> String:
	ensure()
	return str(_styles.get(cell, "pink"))


## "a" is the first lane. "b" is the second, or the first again when
## the yard has only one. Any other id, such as Deep Yard's "c", is looked up.
static func lane(which: String) -> Array[Vector2i]:
	ensure()
	if which == "a":
		return lane_a
	if which == "b":
		return lane_b
	for i in lane_ids.size():
		if lane_ids[i] == which and i < lanes.size():
			return lanes[i]
	return lane_a


static func is_slot(cell: Vector2i) -> bool:
	ensure()
	return cell in SLOTS


static func pod_origin(cell: Vector2i) -> Vector2i:
	ensure()
	if active == null:
		return Vector2i(-1, -1)
	for pod in active.pods:
		var origin: Vector2i = pod["origin"]
		if cell.x >= origin.x and cell.x < origin.x + 2 and cell.y >= origin.y and cell.y < origin.y + 2:
			return origin
	return Vector2i(-1, -1)


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
	if active == null:
		errs.append("no map loaded")
		return errs
	if SLOTS.size() != active.pods.size() * 4:
		errs.append("expected %d build slots in pods of 4" % (active.pods.size() * 4))
	for pod in active.pods:
		var origin: Vector2i = pod["origin"]
		for dy in 2:
			for dx in 2:
				if not ((origin + Vector2i(dx, dy)) in SLOTS):
					errs.append("pod %s is not a full 2x2" % origin)
	if lanes.is_empty():
		errs.append("lanes missing")
	for i in lanes.size():
		_check_lane(lanes[i], str(active.lanes[i].get("name", "lane")), errs)
	var seen := {}
	for cell in SLOTS:
		if not is_inside(cell):
			errs.append("slot out of bounds %s" % cell)
		if path_info.has(cell) and cell != CORE:
			errs.append("slot sits on a lane %s" % cell)
		if seen.has(cell):
			errs.append("duplicate slot %s" % cell)
		seen[cell] = true
	return errs


static func _check_lane(cells: Array[Vector2i], name: String, errs: PackedStringArray) -> void:
	if cells.is_empty() or cells[-1] != CORE:
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
