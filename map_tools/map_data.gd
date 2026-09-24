class_name MapData
extends RefCounted

## Standalone yard description. Battle, the map editor, and later Adventure
## all load this. Geometry is JSON; the editor shell is not required to read it.

const FORMAT_VERSION := 1
const STYLES := ["pink", "teal", "crystal"]
const STYLE_TEX := {
	"pink": "island_a",
	"teal": "island_b",
	"crystal": "island_c",
}

var version := FORMAT_VERSION
var id := ""
var map_name := "Untitled yard"
var blurb := ""
var builtin := false
var cols := 24
var rows := 11
var tile := 48
var origin := Vector2(64, 80)
var backdrop := "space"
var tint := "#ffffff"
var tint_amount := 0.0
var hp_scale := 1.0
var speed_scale := 1.0
var core := Vector2i(22, 5)
var lanes: Array = []
var pods: Array = []


static func from_dict(raw: Dictionary) -> MapData:
	var data := MapData.new()
	data.version = int(raw.get("version", FORMAT_VERSION))
	data.id = str(raw.get("id", ""))
	data.map_name = str(raw.get("name", "Untitled yard"))
	data.blurb = str(raw.get("blurb", ""))
	data.builtin = bool(raw.get("builtin", false))
	data.cols = maxi(1, int(raw.get("cols", 24)))
	data.rows = maxi(1, int(raw.get("rows", 11)))
	data.tile = maxi(8, int(raw.get("tile", 48)))
	var origin_raw = raw.get("origin", [64, 80])
	data.origin = Vector2(float(origin_raw[0]), float(origin_raw[1]))
	data.backdrop = str(raw.get("backdrop", "space"))
	data.tint = str(raw.get("tint", "#ffffff"))
	data.tint_amount = float(raw.get("tint_amount", 0.0))
	data.hp_scale = float(raw.get("hp_scale", 1.0))
	data.speed_scale = float(raw.get("speed_scale", 1.0))
	var core_raw = raw.get("core", [0, 0])
	data.core = Vector2i(int(core_raw[0]), int(core_raw[1]))
	data.lanes = []
	for lane in raw.get("lanes", []):
		var cells: Array[Vector2i] = []
		for pair in lane.get("cells", []):
			cells.append(Vector2i(int(pair[0]), int(pair[1])))
		data.lanes.append({
			"id": str(lane.get("id", "a")),
			"name": str(lane.get("name", "Lane")),
			"cells": cells,
		})
	data.pods = []
	for pod in raw.get("pods", []):
		var origin_pair = pod.get("origin", [0, 0])
		var pod_cells: Array = []
		for cell in pod.get("cells", []):
			var at = cell.get("at", [0, 0])
			pod_cells.append({
				"at": Vector2i(int(at[0]), int(at[1])),
				"style": str(cell.get("style", "pink")),
			})
		data.pods.append({
			"origin": Vector2i(int(origin_pair[0]), int(origin_pair[1])),
			"cells": pod_cells,
		})
	return data


static func from_json(text: String) -> MapData:
	var parsed = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		return null
	return from_dict(parsed)


func to_dict() -> Dictionary:
	var lane_rows: Array = []
	for lane in lanes:
		var cells: Array = []
		for cell in lane["cells"]:
			var point := cell as Vector2i
			cells.append([point.x, point.y])
		lane_rows.append({
			"id": str(lane["id"]),
			"name": str(lane["name"]),
			"cells": cells,
		})
	var pod_rows: Array = []
	for pod in pods:
		var origin := pod["origin"] as Vector2i
		var cells: Array = []
		for cell in pod["cells"]:
			var at := cell["at"] as Vector2i
			cells.append({"at": [at.x, at.y], "style": str(cell["style"])})
		pod_rows.append({"origin": [origin.x, origin.y], "cells": cells})
	return {
		"version": version,
		"id": id,
		"name": map_name,
		"blurb": blurb,
		"builtin": builtin,
		"cols": cols,
		"rows": rows,
		"tile": tile,
		"origin": [origin.x, origin.y],
		"backdrop": backdrop,
		"tint": tint,
		"tint_amount": tint_amount,
		"hp_scale": hp_scale,
		"speed_scale": speed_scale,
		"core": [core.x, core.y],
		"lanes": lane_rows,
		"pods": pod_rows,
	}


func to_json() -> String:
	return JSON.stringify(to_dict(), "\t")


func duplicate_map() -> MapData:
	return from_dict(to_dict())


func lane_cells(index: int) -> Array:
	if index < 0 or index >= lanes.size():
		return []
	return lanes[index]["cells"]


func all_slots() -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	for pod in pods:
		for cell in pod["cells"]:
			slots.append(cell["at"])
	return slots


func style_at(cell: Vector2i) -> String:
	for pod in pods:
		for entry in pod["cells"]:
			if entry["at"] == cell:
				return str(entry.get("style", "pink"))
	return "pink"


func tex_for_style(style: String) -> String:
	return str(STYLE_TEX.get(style, "island_a"))


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows


func path_cells() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var seen := {}
	for lane in lanes:
		for cell in lane["cells"]:
			var point := cell as Vector2i
			if seen.has(point):
				continue
			seen[point] = true
			found.append(point)
	return found


static func blank(map_id: String, display_name: String) -> MapData:
	var data := MapData.new()
	data.id = map_id
	data.map_name = display_name
	data.blurb = "A custom yard."
	data.builtin = false
	data.cols = 24
	data.rows = 11
	data.core = Vector2i(22, 5)
	data.lanes = [
		{"id": "a", "name": "North", "cells": [] as Array[Vector2i]},
		{"id": "b", "name": "South", "cells": [] as Array[Vector2i]},
	]
	return data
