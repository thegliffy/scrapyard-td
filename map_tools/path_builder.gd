class_name PathBuilder
extends RefCounted

## Orthogonal path edits shared by the editor. Adventure can reuse these
## when it builds lanes without the editor screen.


static func walk(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [start]
	var cur := start
	while cur.x != target.x:
		cur.x += 1 if target.x > cur.x else -1
		cells.append(cur)
	while cur.y != target.y:
		cur.y += 1 if target.y > cur.y else -1
		cells.append(cur)
	return cells


static func extend(cells: Array, target: Vector2i) -> void:
	if cells.is_empty():
		cells.append(target)
		return
	var start: Vector2i = cells[-1]
	if start == target:
		return
	var walked := walk(start, target)
	for i in range(1, walked.size()):
		cells.append(walked[i])


static func prepend_spawn(cells: Array, spawn: Vector2i) -> void:
	if cells.is_empty():
		cells.append(spawn)
		return
	var first: Vector2i = cells[0]
	if first == spawn:
		return
	var walked := walk(spawn, first)
	var merged: Array[Vector2i] = []
	for cell in walked:
		merged.append(cell)
	for i in range(1, cells.size()):
		merged.append(cells[i])
	cells.clear()
	for cell in merged:
		cells.append(cell)


static func erase_from(cells: Array, target: Vector2i) -> void:
	var index := -1
	for i in cells.size():
		if cells[i] == target:
			index = i
			break
	if index < 0:
		return
	while cells.size() > index:
		cells.remove_at(cells.size() - 1)
