class_name MapValidator
extends RefCounted

## Rules a yard must pass before it can be saved or playtested.
## Adventure can call this without opening the editor.


static func errors(data: MapData) -> PackedStringArray:
	var out := PackedStringArray()
	if data == null:
		out.append("This map has no data.")
		return out
	if data.core.x < 0 or data.core.y < 0 or data.core.x >= data.cols or data.core.y >= data.rows:
		out.append("Station Core is outside the grid.")
	if data.lanes.is_empty():
		out.append("Add at least one lane from a spawn to the Station Core.")
	var path := {}
	var lane_index := 0
	for lane in data.lanes:
		lane_index += 1
		var label := str(lane.get("name", "Lane %d" % lane_index))
		var cells: Array = lane["cells"]
		if cells.is_empty():
			out.append("%s has no cells. Paint a path or remove the lane." % label)
			continue
		var first: Vector2i = cells[0]
		if not data.is_inside(first):
			out.append("%s spawn is outside the grid." % label)
		var last: Vector2i = cells[-1]
		if last != data.core:
			out.append("%s must end on the Station Core." % label)
		for i in range(1, cells.size()):
			var prev: Vector2i = cells[i - 1]
			var curr: Vector2i = cells[i]
			if not data.is_inside(curr):
				out.append("%s leaves the grid at %s." % [label, _cell(prev)])
				break
			var step := curr - prev
			if absi(step.x) + absi(step.y) != 1:
				out.append("%s is not a one-cell step at %s." % [label, _cell(prev)])
				break
		for cell in cells:
			path[cell] = true
	if data.pods.is_empty():
		out.append("Place at least one hardpoint pod.")
	var seen := {}
	for pod in data.pods:
		var origin: Vector2i = pod["origin"]
		if pod["cells"].size() != 4:
			out.append("Hardpoint at %s must be a group of four." % _cell(origin))
		for dy in 2:
			for dx in 2:
				var expected := origin + Vector2i(dx, dy)
				var found := false
				for entry in pod["cells"]:
					if entry["at"] == expected:
						found = true
				if not found:
					out.append("Hardpoint at %s is missing %s." % [_cell(origin), _cell(expected)])
		for entry in pod["cells"]:
			var at: Vector2i = entry["at"]
			if not data.is_inside(at):
				out.append("Hardpoint %s is outside the grid." % _cell(at))
			if path.has(at):
				out.append("Hardpoint %s sits on the path." % _cell(at))
			if seen.has(at):
				out.append("Two hardpoints share %s." % _cell(at))
			seen[at] = true
			var style := str(entry.get("style", ""))
			if style not in MapData.STYLES:
				out.append("Hardpoint %s has an unknown island style." % _cell(at))
	return out


static func ok(data: MapData) -> bool:
	return errors(data).is_empty()


static func _cell(cell: Vector2i) -> String:
	return "(%d,%d)" % [cell.x, cell.y]
