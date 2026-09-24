class_name Balance
extends RefCounted

## Speeds are cells per second. Ranges and splash are in tiles.
## Enemies are cute eldritch horrors; towers stay scrapyard gadgets.

const START_SCRAP := 170
const CORE_HP := 22

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
		"blurb": "Lobs a scrap bomb. Splashes a tile or two.",
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
		"blurb": "No shooting. Pulls extra scrap out of the yard.",
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
		"hp": 30,
		"shield": 0,
		"speed": 2.28,
		"scrap": 7,
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
		"hp": 170,
		"shield": 0,
		"speed": 1.05,
		"scrap": 16,
		"leak": 3,
		"display": 50.0,
		"tex": 128.0,
		"color": "#b48ae0",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"shielded": {
		"name": "Shielded",
		"hp": 55,
		"shield": 48,
		"speed": 1.5,
		"scrap": 13,
		"leak": 2,
		"display": 36.0,
		"tex": 128.0,
		"color": "#7ed6ba",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"minion_kind": "",
	},
	"swarm_splitter": {
		"name": "Swarm-Splitter",
		"hp": 62,
		"shield": 0,
		"speed": 1.15,
		"scrap": 9,
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
	"swarmling": {
		"name": "Swarmling",
		"hp": 16,
		"shield": 0,
		"speed": 2.35,
		"scrap": 3,
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
		"hp": 1900,
		"shield": 160,
		"speed": 0.62,
		"scrap": 120,
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

## 20 build-up waves, then the boss. New kinds arrive a few at a time.
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
