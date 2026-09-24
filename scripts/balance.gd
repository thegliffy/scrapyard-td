class_name Balance
extends RefCounted

## Speeds are cells per second. Ranges and splash are in tiles.
## Enemies are cute eldritch horrors; towers stay scrapyard gadgets.

const START_GOLD := 170
const CORE_HP := 22

## Same lane layout. Tint and a light stat tweak tell the yards apart.
const MAPS := {
	"yard_approach": {
		"name": "Yard Approach",
		"blurb": "The home yard. Two rifts, one core.",
		"tint": "#ffffff",
		"tint_amount": 0.0,
		"hp_scale": 1.0,
		"speed_scale": 1.0,
	},
	"side_dock": {
		"name": "Side Dock",
		"blurb": "Same lanes, cooler light. A little tougher.",
		"tint": "#7eb6ff",
		"tint_amount": 0.22,
		"hp_scale": 1.1,
		"speed_scale": 1.0,
	},
	"deep_yard": {
		"name": "Deep Yard",
		"blurb": "Same lanes, deeper dusk. A harder crawl.",
		"tint": "#b794f0",
		"tint_amount": 0.3,
		"hp_scale": 1.18,
		"speed_scale": 1.06,
	},
}

const TOWERS := {
	"pea": {
		"name": "Pea Blaster",
		"short": "Pea",
		"blurb": "Cheap, peppy, one critter at a time.",
		"cost": 50,
		"upgrade": [45, 80],
		"range": [3.5, 3.9, 4.3],
		"damage": [12.0, 20.0, 34.0],
		"rate": [1.55, 1.95, 2.4],
		"shot_speed": 13.0,
	},
	"spark": {
		"name": "Spark Arc",
		"short": "Spark",
		"blurb": "Zaps a critter, then jumps to its friends.",
		"cost": 100,
		"upgrade": [75, 120],
		"range": [3.2, 3.5, 3.9],
		"damage": [14.0, 22.0, 34.0],
		"rate": [0.9, 1.05, 1.2],
		"chains": [2, 3, 4],
		"chain_range": [2.6, 2.9, 3.2],
		"falloff": 0.8,
	},
	"glue": {
		"name": "Glue Goo",
		"short": "Glue",
		"blurb": "Slows the soft things down.",
		"cost": 75,
		"upgrade": [60, 95],
		"range": [3.0, 3.3, 3.6],
		"damage": [4.0, 7.0, 11.0],
		"rate": [1.0, 1.15, 1.3],
		"shot_speed": 10.0,
		"slow": [0.58, 0.42, 0.3],
		"slow_time": [2.0, 2.5, 3.1],
		"slow_splash": [0.0, 0.0, 1.2],
	},
	"boom": {
		"name": "Boom Barrel",
		"short": "Boom",
		"blurb": "Lobs a bomb. Splashes a tile or two.",
		"cost": 125,
		"upgrade": [95, 150],
		"range": [3.6, 4.0, 4.4],
		"damage": [22.0, 36.0, 56.0],
		"rate": [0.55, 0.68, 0.8],
		"shot_speed": 8.0,
		"splash": [1.5, 1.75, 2.0],
	},
	"magnet": {
		"name": "Scrap Magnet",
		"short": "Magnet",
		"blurb": "No shooting. Pulls extra gold out of the yard.",
		"cost": 80,
		"upgrade": [65, 110],
		"range": [3.0, 3.4, 3.8],
		"income": [5, 8, 12],
		"income_every": [4.0, 3.3, 2.6],
		"bonus": [2, 4, 6],
	},
}

const ENEMIES := {
	"fast_skitter": {
		"name": "Fast Skitter",
		"hp": 38,
		"shield": 0,
		"speed": 2.28,
		"gold": 7,
		"leak": 1,
		"display": 34.0,
		"tex": 128.0,
		"color": "#ffb0cc",
		"split": 0,
		"split_kind": "",
		"skitter": true,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"chunky_tank": {
		"name": "Chunky Tank",
		"hp": 210,
		"shield": 0,
		"speed": 1.05,
		"gold": 16,
		"leak": 3,
		"display": 50.0,
		"tex": 128.0,
		"color": "#b48ae0",
		"split": 3,
		"split_kind": "tanklet",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"shielded": {
		"name": "Shielded",
		"hp": 70,
		"shield": 56,
		"speed": 1.5,
		"gold": 13,
		"leak": 2,
		"display": 36.0,
		"tex": 128.0,
		"color": "#7ed6ba",
		"split": 2,
		"split_kind": "open_shell",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"swarm_splitter": {
		"name": "Swarm-Splitter",
		"hp": 78,
		"shield": 0,
		"speed": 1.15,
		"gold": 9,
		"leak": 2,
		"display": 46.0,
		"tex": 128.0,
		"color": "#f5a830",
		"split": 3,
		"split_kind": "swarmling",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"tanklet": {
		"name": "Tanklet",
		"hp": 58,
		"shield": 0,
		"speed": 1.22,
		"gold": 4,
		"leak": 1,
		"display": 34.0,
		"tex": 128.0,
		"color": "#d2b4f0",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"open_shell": {
		"name": "Open Shell",
		"hp": 36,
		"shield": 0,
		"speed": 1.65,
		"gold": 4,
		"leak": 1,
		"display": 30.0,
		"tex": 128.0,
		"color": "#b6ead8",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"elite_tank": {
		"name": "Elite Tank",
		"hp": 480,
		"shield": 0,
		"speed": 0.92,
		"gold": 24,
		"leak": 4,
		"display": 60.0,
		"tex": 128.0,
		"color": "#6a3d99",
		"split": 2,
		"split_kind": "chunky_tank",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"swarmling": {
		"name": "Swarmling",
		"hp": 18,
		"shield": 0,
		"speed": 2.35,
		"gold": 3,
		"leak": 1,
		"display": 28.0,
		"tex": 128.0,
		"color": "#ffc24a",
		"split": 0,
		"split_kind": "",
		"skitter": true,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"big_cute_boss": {
		"name": "Big Cute Boss",
		"hp": 2400,
		"shield": 200,
		"speed": 0.62,
		"gold": 120,
		"leak": 10,
		"display": 90.0,
		"tex": 192.0,
		"color": "#8a56cc",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 6.5,
		"babies": 2,
		"boss": true,
		"minion_kind": "swarmling",
	},
}

## First 21 waves are handcrafted (20 build-up waves, then the first boss).
## Waves 22–100 are generated. Boss milestones: 21, 40, 60, 80, and 100.
const WAVE_COUNT := 100
const BOSS_WAVES := [21, 40, 60, 80, 100]
const WAVES: Array = [
	{
		"title": "Fast Skitters",
		"preview": "6 Fast Skitters",
		"entries": [
			{"kind": "fast_skitter", "count": 6, "gap": 1.0, "lane": "alt"},
		],
	},
	{
		"title": "More Skitters",
		"preview": "8 Fast Skitters",
		"entries": [
			{"kind": "fast_skitter", "count": 8, "gap": 0.9, "lane": "alt"},
		],
	},
	{
		"title": "Skitter Line",
		"preview": "10 Fast Skitters",
		"entries": [
			{"kind": "fast_skitter", "count": 10, "gap": 0.8, "lane": "alt"},
		],
	},
	{
		"title": "One Tank",
		"preview": "8 Fast Skitters & 1 Chunky Tank",
		"entries": [
			{"kind": "fast_skitter", "count": 8, "gap": 0.75, "lane": "alt"},
			{"kind": "chunky_tank", "count": 1, "gap": 1.2, "lane": "alt"},
		],
	},
	{
		"title": "Two Tanks",
		"preview": "6 Fast Skitters & 2 Chunky Tanks",
		"entries": [
			{"kind": "fast_skitter", "count": 6, "gap": 0.75, "lane": "alt"},
			{"kind": "chunky_tank", "count": 2, "gap": 1.1, "lane": "alt"},
		],
	},
	{
		"title": "Chunky Tanks",
		"preview": "6 Fast Skitters & 3 Chunky Tanks",
		"entries": [
			{"kind": "fast_skitter", "count": 6, "gap": 0.7, "lane": "alt"},
			{"kind": "chunky_tank", "count": 3, "gap": 1.0, "lane": "alt"},
		],
	},
	{
		"title": "Shielded",
		"preview": "4 Shielded & 4 Fast Skitters",
		"entries": [
			{"kind": "shielded", "count": 4, "gap": 0.9, "lane": "alt"},
			{"kind": "fast_skitter", "count": 4, "gap": 0.7, "lane": "alt"},
		],
	},
	{
		"title": "More Bubbles",
		"preview": "6 Shielded",
		"entries": [
			{"kind": "shielded", "count": 6, "gap": 0.85, "lane": "alt"},
		],
	},
	{
		"title": "Bubbles & Shells",
		"preview": "5 Shielded, 2 Chunky Tanks, 4 Skitters",
		"entries": [
			{"kind": "shielded", "count": 5, "gap": 0.8, "lane": "alt"},
			{"kind": "chunky_tank", "count": 2, "gap": 1.0, "lane": "alt"},
			{"kind": "fast_skitter", "count": 4, "gap": 0.65, "lane": "alt"},
		],
	},
	{
		"title": "Swarm-Splitters",
		"preview": "2 Swarm-Splitters & 6 Fast Skitters",
		"entries": [
			{"kind": "swarm_splitter", "count": 2, "gap": 1.1, "lane": "alt"},
			{"kind": "fast_skitter", "count": 6, "gap": 0.65, "lane": "alt"},
		],
	},
	{
		"title": "Soft Split",
		"preview": "3 Swarm-Splitters & 4 Shielded",
		"entries": [
			{"kind": "swarm_splitter", "count": 3, "gap": 1.0, "lane": "alt"},
			{"kind": "shielded", "count": 4, "gap": 0.75, "lane": "alt"},
		],
	},
	{
		"title": "Splitters & Tanks",
		"preview": "4 Swarm-Splitters & 3 Chunky Tanks",
		"entries": [
			{"kind": "swarm_splitter", "count": 4, "gap": 0.95, "lane": "alt"},
			{"kind": "chunky_tank", "count": 3, "gap": 0.95, "lane": "alt"},
		],
	},
	{
		"title": "Mixed Yard",
		"preview": "3 Chunky Tanks, 3 Shielded, 6 Skitters",
		"entries": [
			{"kind": "chunky_tank", "count": 3, "gap": 0.9, "lane": "alt"},
			{"kind": "shielded", "count": 3, "gap": 0.75, "lane": "alt"},
			{"kind": "fast_skitter", "count": 6, "gap": 0.55, "lane": "alt"},
		],
	},
	{
		"title": "Soft Crowd",
		"preview": "4 Swarm-Splitters, 4 Shielded, 4 Skitters",
		"entries": [
			{"kind": "swarm_splitter", "count": 4, "gap": 0.9, "lane": "alt"},
			{"kind": "shielded", "count": 4, "gap": 0.7, "lane": "alt"},
			{"kind": "fast_skitter", "count": 4, "gap": 0.55, "lane": "alt"},
		],
	},
	{
		"title": "Heavy Nap",
		"preview": "5 Chunky Tanks & 4 Shielded",
		"entries": [
			{"kind": "chunky_tank", "count": 5, "gap": 0.8, "lane": "alt"},
			{"kind": "shielded", "count": 4, "gap": 0.7, "lane": "alt"},
		],
	},
	{
		"title": "Busy Lanes",
		"preview": "5 Swarm-Splitters, 3 Tanks, 6 Skitters",
		"entries": [
			{"kind": "swarm_splitter", "count": 5, "gap": 0.85, "lane": "alt"},
			{"kind": "chunky_tank", "count": 3, "gap": 0.8, "lane": "alt"},
			{"kind": "fast_skitter", "count": 6, "gap": 0.5, "lane": "alt"},
		],
	},
	{
		"title": "Bubble Swarm",
		"preview": "6 Shielded, 4 Swarm-Splitters, 6 Skitters",
		"entries": [
			{"kind": "shielded", "count": 6, "gap": 0.65, "lane": "alt"},
			{"kind": "swarm_splitter", "count": 4, "gap": 0.8, "lane": "alt"},
			{"kind": "fast_skitter", "count": 6, "gap": 0.48, "lane": "alt"},
		],
	},
	{
		"title": "Armored Lane",
		"preview": "6 Chunky Tanks & 5 Shielded",
		"entries": [
			{"kind": "chunky_tank", "count": 6, "gap": 0.7, "lane": "alt"},
			{"kind": "shielded", "count": 5, "gap": 0.6, "lane": "alt"},
		],
	},
	{
		"title": "Before the Nap",
		"preview": "8 Skitters, 4 Tanks, 4 Shielded, 3 Splitters",
		"entries": [
			{"kind": "fast_skitter", "count": 8, "gap": 0.45, "lane": "alt"},
			{"kind": "chunky_tank", "count": 4, "gap": 0.65, "lane": "alt"},
			{"kind": "shielded", "count": 4, "gap": 0.6, "lane": "alt"},
			{"kind": "swarm_splitter", "count": 3, "gap": 0.8, "lane": "alt"},
		],
	},
	{
		"title": "Last Leak",
		"preview": "6 Tanks, 5 Shielded, 4 Splitters, 6 Skitters",
		"entries": [
			{"kind": "chunky_tank", "count": 6, "gap": 0.6, "lane": "alt"},
			{"kind": "shielded", "count": 5, "gap": 0.55, "lane": "alt"},
			{"kind": "swarm_splitter", "count": 4, "gap": 0.7, "lane": "alt"},
			{"kind": "fast_skitter", "count": 6, "gap": 0.42, "lane": "alt"},
		],
	},
	{
		"title": "Big Cute Boss",
		"preview": "Big Cute Boss, plus Skitters & Splitters",
		"boss": true,
		"entries": [
			{"kind": "big_cute_boss", "count": 1, "gap": 1.2, "lane": "a"},
			{"kind": "fast_skitter", "count": 6, "gap": 0.55, "lane": "alt"},
			{"kind": "swarm_splitter", "count": 2, "gap": 1.1, "lane": "b"},
		],
	},
]


static func wave_at(index: int) -> Dictionary:
	if index < 0 or index >= WAVE_COUNT:
		return {}
	if index < WAVES.size():
		return WAVES[index]
	return _generated_wave(index + 1)


static func is_boss_wave(wave_number: int) -> bool:
	return wave_number in BOSS_WAVES


## Gentle through the curated intro, then a steady climb. Does not flatten after 21.
static func wave_hp_scale(wave_number: int) -> float:
	var n := maxi(1, wave_number)
	if n <= 20:
		return 1.0 + float(n - 1) * 0.012
	return 1.228 + float(n - 20) * 0.042


## Extra boss health on later milestones. Wave 21 stays near the old finale.
static func boss_hp_scale(wave_number: int) -> float:
	var steps := 0
	if wave_number >= 100:
		steps = 4
	elif wave_number >= 80:
		steps = 3
	elif wave_number >= 60:
		steps = 2
	elif wave_number >= 40:
		steps = 1
	return 1.0 + float(steps) * 0.35


static func _generated_wave(wave_number: int) -> Dictionary:
	if is_boss_wave(wave_number):
		return _boss_wave(wave_number)
	var t := clampf(float(wave_number - 22) / 77.0, 0.0, 1.0)
	var gap := maxf(0.34, 0.72 - t * 0.38)
	var entries: Array = []
	var title := "Deeper Yard"
	match wave_number % 5:
		0:
			title = "Skitter Rush"
			entries = [
				{"kind": "fast_skitter", "count": 8 + int(t * 8), "gap": gap, "lane": "alt"},
				{"kind": "chunky_tank", "count": 2 + int(t * 3), "gap": gap + 0.15, "lane": "alt"},
			]
		1:
			title = "Bubble Line"
			entries = [
				{"kind": "shielded", "count": 4 + int(t * 5), "gap": gap + 0.05, "lane": "alt"},
				{"kind": "swarm_splitter", "count": 2 + int(t * 3), "gap": gap + 0.1, "lane": "alt"},
			]
		2:
			title = "Shell March"
			entries = [
				{"kind": "chunky_tank", "count": 3 + int(t * 5), "gap": gap + 0.08, "lane": "alt"},
				{"kind": "fast_skitter", "count": 4 + int(t * 4), "gap": gap, "lane": "alt"},
			]
			if wave_number >= 36:
				entries.append({
					"kind": "elite_tank",
					"count": 1 if wave_number < 70 else 2,
					"gap": 1.3,
					"lane": "alt",
				})
				title = "Elite Shells"
		3:
			title = "Soft Split"
			entries = [
				{"kind": "swarm_splitter", "count": 3 + int(t * 4), "gap": gap + 0.08, "lane": "alt"},
				{"kind": "shielded", "count": 3 + int(t * 3), "gap": gap, "lane": "alt"},
				{"kind": "fast_skitter", "count": 4 + int(t * 3), "gap": gap, "lane": "alt"},
			]
		_:
			title = "Full Yard"
			entries = [
				{"kind": "chunky_tank", "count": 3 + int(t * 4), "gap": gap + 0.05, "lane": "alt"},
				{"kind": "shielded", "count": 3 + int(t * 3), "gap": gap, "lane": "alt"},
				{"kind": "swarm_splitter", "count": 2 + int(t * 3), "gap": gap + 0.08, "lane": "alt"},
				{"kind": "fast_skitter", "count": 5 + int(t * 4), "gap": gap, "lane": "alt"},
			]
			if wave_number >= 55:
				entries.append({"kind": "elite_tank", "count": 1, "gap": 1.4, "lane": "a"})
	return {"title": title, "preview": _preview_from(entries), "entries": entries}


static func _boss_wave(wave_number: int) -> Dictionary:
	var t := clampf(float(wave_number - 21) / 79.0, 0.0, 1.0)
	var title := "Big Cute Boss" if wave_number < 100 else "Final Nap"
	var entries: Array = [
		{"kind": "big_cute_boss", "count": 1, "gap": 1.2, "lane": "a"},
		{"kind": "fast_skitter", "count": 4 + int(t * 8), "gap": 0.5, "lane": "alt"},
		{"kind": "swarm_splitter", "count": 2 + int(t * 3), "gap": 0.9, "lane": "b"},
	]
	if wave_number >= 60:
		entries.append({"kind": "chunky_tank", "count": 2 + int(t * 3), "gap": 0.8, "lane": "alt"})
	if wave_number >= 80:
		entries.append({"kind": "shielded", "count": 3, "gap": 0.7, "lane": "alt"})
	if wave_number >= 100:
		entries.append({"kind": "elite_tank", "count": 1, "gap": 1.5, "lane": "b"})
	var preview := "Big Cute Boss, plus a deeper escort"
	if wave_number >= 100:
		preview = "The last Big Cute Boss"
	return {"title": title, "preview": preview, "boss": true, "entries": entries}


static func _preview_from(entries: Array) -> String:
	var bits := PackedStringArray()
	for entry in entries:
		var data: Dictionary = ENEMIES[str(entry["kind"])]
		bits.append("%d %s" % [int(entry["count"]), str(data["name"])])
	return ", ".join(bits)


static func cost(id: String) -> int:
	return int(TOWERS[id]["cost"])


static func tier_value(id: String, key: String, tier: int) -> float:
	var value = TOWERS[id][key]
	if typeof(value) == TYPE_ARRAY:
		var idx := clampi(tier - 1, 0, value.size() - 1)
		return float(value[idx])
	return float(value)


static func upgrade_cost(id: String, tier: int) -> int:
	if tier >= 3:
		return 0
	return int(TOWERS[id]["upgrade"][tier - 1])


static func enemy(id: String) -> Dictionary:
	return ENEMIES[id]
