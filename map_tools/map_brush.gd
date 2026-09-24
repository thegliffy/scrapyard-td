class_name MapBrush
extends RefCounted

## Grid edits the editor performs on a MapData. Adventure can call these
## without the editor screen. Each call either changes the map or returns
## a reason and leaves it alone.


static func paint_path(data: MapData, lane_index: int, cell: Vector2i) -> String:
	if not _has_lane(data, lane_index):
		return "That lane is missing."
	var cells: Array = data.lanes[lane_index]["cells"]
	if not data.is_inside(cell):
		return "That cell is off the grid."
	if cells.is_empty():
		cells.append(cell)
		return ""
	var start: Vector2i = cells[-1]
	if start == cell:
		return ""
	var walked := PathBuilder.walk(start, cell)
	for step in walked:
		if not data.is_inside(step):
			return "That path would leave the grid."
	PathBuilder.extend(cells, cell)
	return ""


static func erase_path(data: MapData, lane_index: int, cell: Vector2i) -> String:
	if not _has_lane(data, lane_index):
		return "That lane is missing."
	PathBuilder.erase_from(data.lanes[lane_index]["cells"], cell)
	return ""


static func set_spawn(data: MapData, lane_index: int, cell: Vector2i) -> String:
	if not _has_lane(data, lane_index):
		return "That lane is missing."
	var cells: Array = data.lanes[lane_index]["cells"]
	if not data.is_inside(cell):
		return "That spawn is off the grid."
	if not cells.is_empty():
		var walked := PathBuilder.walk(cell, cells[0])
		for step in walked:
			if not data.is_inside(step):
				return "That spawn would leave the grid."
	PathBuilder.prepend_spawn(cells, cell)
	return ""


static func set_core(data: MapData, cell: Vector2i) -> String:
	if not data.is_inside(cell):
		return "The Station Core has to stay on the grid."
	data.core = cell
	for lane in data.lanes:
		var cells: Array = lane["cells"]
		if cells.is_empty():
			continue
		var last: Vector2i = cells[-1]
		if last == cell:
			continue
		var walked := PathBuilder.walk(last, cell)
		var inside := true
		for step in walked:
			if not data.is_inside(step):
				inside = false
				break
		if inside:
			PathBuilder.extend(cells, cell)
	return ""


static func place_pod(data: MapData, origin: Vector2i, style: String) -> String:
	if origin.x < 0 or origin.y < 0 or origin.x + 1 >= data.cols or origin.y + 1 >= data.rows:
		return "A hardpoint needs a 2×2 inside the grid."
	var blocked := {}
	for cell in data.path_cells():
		blocked[cell] = true
	var pod_cells: Array = []
	for dy in 2:
		for dx in 2:
			var at := origin + Vector2i(dx, dy)
			if blocked.has(at):
				return "That hardpoint would sit on the path."
			if _pod_at(data, at) >= 0:
				return "That hardpoint overlaps another one."
			pod_cells.append({"at": at, "style": style})
	data.pods.append({"origin": origin, "cells": pod_cells})
	return ""


static func remove_pod(data: MapData, cell: Vector2i) -> String:
	var index := _pod_at(data, cell)
	if index < 0:
		return "No hardpoint there."
	data.pods.remove_at(index)
	return ""


static func paint_style(data: MapData, cell: Vector2i, style: String) -> String:
	if style not in MapData.STYLES:
		return "Unknown island style."
	for pod in data.pods:
		for entry in pod["cells"]:
			if entry["at"] == cell:
				entry["style"] = style
				return ""
	return "No hardpoint there."


static func resize(data: MapData, cols: int, rows: int) -> String:
	if data.core.x >= cols or data.core.y >= rows:
		return "The Station Core would fall off the grid."
	for lane in data.lanes:
		for cell in lane["cells"]:
			var point := cell as Vector2i
			if point.x >= cols or point.y >= rows:
				return "A path cell would fall off the grid."
	for slot in data.all_slots():
		if slot.x >= cols or slot.y >= rows:
			return "A hardpoint would fall off the grid."
	data.cols = cols
	data.rows = rows
	return ""


static func clear_geometry(data: MapData) -> void:
	for lane in data.lanes:
		lane["cells"] = [] as Array[Vector2i]
	data.pods = []


static func _has_lane(data: MapData, lane_index: int) -> bool:
	return data != null and lane_index >= 0 and lane_index < data.lanes.size()


static func _pod_at(data: MapData, cell: Vector2i) -> int:
	for i in data.pods.size():
		for entry in data.pods[i]["cells"]:
			if entry["at"] == cell:
				return i
	return -1
