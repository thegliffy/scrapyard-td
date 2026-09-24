extends MapView

## Battle's map node. Drawing lives on MapView so the editor shares it.
## This script only keeps the in-run stains, range tint, and core hurt flash.


func _ready() -> void:
	super._ready()
	add_to_group("map")
	if Game.has_signal("core_hit"):
		Game.core_hit.connect(func(_amount): hurt = 0.4)


func set_highlights(cells: Array) -> void:
	highlight_set = {}
	for cell in cells:
		highlight_set[cell] = true
	queue_redraw()


func add_stain(cell: Vector2i, color: Color, life: float) -> void:
	stains.append({"cell": cell, "color": color, "life": life, "max": life})
	if stains.size() > 140:
		stains.pop_front()


func _process(delta: float) -> void:
	if hurt > 0.0:
		hurt = max(0.0, hurt - delta)
	var kept: Array = []
	for stain in stains:
		stain["life"] = float(stain["life"]) - delta
		if float(stain["life"]) > 0.0:
			kept.append(stain)
	stains = kept
	queue_redraw()
