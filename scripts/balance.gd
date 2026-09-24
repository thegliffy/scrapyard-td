class_name Balance
extends RefCounted

## Speeds are cells per second. Ranges and splash are in tiles.
## Enemies are cute eldritch horrors; towers stay scrapyard gadgets.

const START_SCRAP := 150
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
	"eye_squid": {
		"name": "Eye-Squid",
		"hp": 30,
		"shield": 0,
		"speed": 2.85,
		"scrap": 7,
		"leak": 1,
		"display": 40.0,
		"tex": 128.0,
		"color": "#d6baff",
		"split": 0,
		"split_kind": "",
		"skitter": true,
		"baby_every": 0.0,
		"babies": 0,
	},
	"star_toad": {
		"name": "Star-Toad",
		"hp": 170,
		"shield": 0,
		"speed": 1.05,
		"scrap": 16,
		"leak": 3,
		"display": 46.0,
		"tex": 128.0,
		"color": "#ffba66",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
	},
	"halo_wisp": {
		"name": "Halo Wisp",
		"hp": 55,
		"shield": 48,
		"speed": 1.5,
		"scrap": 13,
		"leak": 2,
		"display": 40.0,
		"tex": 128.0,
		"color": "#ffd6e8",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
	},
	"egg_sac": {
		"name": "Egg Sac",
		"hp": 62,
		"shield": 0,
		"speed": 1.15,
		"scrap": 9,
		"leak": 2,
		"display": 44.0,
		"tex": 128.0,
		"color": "#ffb0d2",
		"split": 3,
		"split_kind": "fractal_baby",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
	},
	"fractal_baby": {
		"name": "Fractal Baby",
		"hp": 16,
		"shield": 0,
		"speed": 2.35,
		"scrap": 3,
		"leak": 1,
		"display": 30.0,
		"tex": 128.0,
		"color": "#beefef",
		"split": 0,
		"split_kind": "",
		"skitter": true,
		"baby_every": 0.0,
		"babies": 0,
	},
	"grand_nibbler": {
		"name": "Grand Nibbler",
		"hp": 1900,
		"shield": 160,
		"speed": 0.62,
		"scrap": 120,
		"leak": 10,
		"display": 88.0,
		"tex": 192.0,
		"color": "#c6b0ff",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 6.5,
		"babies": 2,
	},
}

const WAVES: Array = [
	{
		"title": "Eye-Squids",
		"preview": "8 Eye-Squids",
		"entries": [
			{"kind": "eye_squid", "count": 8, "gap": 0.8, "lane": "alt"},
		],
	},
	{
		"title": "More Eye-Squids",
		"preview": "12 Eye-Squids",
		"entries": [
			{"kind": "eye_squid", "count": 12, "gap": 0.55, "lane": "alt"},
		],
	},
	{
		"title": "Star-Toads",
		"preview": "6 Eye-Squids & 3 Star-Toads",
		"entries": [
			{"kind": "eye_squid", "count": 6, "gap": 0.65, "lane": "alt"},
			{"kind": "star_toad", "count": 3, "gap": 0.9, "lane": "alt"},
		],
	},
	{
		"title": "Plump Parade",
		"preview": "5 Star-Toads & 8 Eye-Squids",
		"entries": [
			{"kind": "star_toad", "count": 5, "gap": 0.85, "lane": "alt"},
			{"kind": "eye_squid", "count": 8, "gap": 0.5, "lane": "alt"},
		],
	},
	{
		"title": "Halo Wisps",
		"preview": "7 Halo Wisps",
		"entries": [
			{"kind": "halo_wisp", "count": 7, "gap": 0.75, "lane": "alt"},
		],
	},
	{
		"title": "Bubbles & Eyes",
		"preview": "8 Eye-Squids & 4 Halo Wisps",
		"entries": [
			{"kind": "eye_squid", "count": 8, "gap": 0.48, "lane": "alt"},
			{"kind": "halo_wisp", "count": 4, "gap": 0.7, "lane": "alt"},
		],
	},
	{
		"title": "Egg Sacs",
		"preview": "5 Egg Sacs & 6 Eye-Squids",
		"entries": [
			{"kind": "egg_sac", "count": 5, "gap": 0.9, "lane": "alt"},
			{"kind": "eye_squid", "count": 6, "gap": 0.5, "lane": "alt"},
		],
	},
	{
		"title": "Rush Hour",
		"preview": "4 Star-Toads, 4 Halo Wisps, 8 Eye-Squids",
		"entries": [
			{"kind": "star_toad", "count": 4, "gap": 0.7, "lane": "alt"},
			{"kind": "halo_wisp", "count": 4, "gap": 0.55, "lane": "alt"},
			{"kind": "eye_squid", "count": 8, "gap": 0.4, "lane": "alt"},
		],
	},
	{
		"title": "Sacs & Toads",
		"preview": "6 Egg Sacs & 4 Star-Toads",
		"entries": [
			{"kind": "egg_sac", "count": 6, "gap": 0.75, "lane": "alt"},
			{"kind": "star_toad", "count": 4, "gap": 0.8, "lane": "alt"},
		],
	},
	{
		"title": "Soft Crowd",
		"preview": "6 Halo Wisps, 5 Egg Sacs, 8 Eye-Squids",
		"entries": [
			{"kind": "halo_wisp", "count": 6, "gap": 0.5, "lane": "alt"},
			{"kind": "egg_sac", "count": 5, "gap": 0.6, "lane": "alt"},
			{"kind": "eye_squid", "count": 8, "gap": 0.36, "lane": "alt"},
		],
	},
	{
		"title": "Heavy Nap",
		"preview": "7 Star-Toads & 5 Halo Wisps",
		"entries": [
			{"kind": "star_toad", "count": 7, "gap": 0.62, "lane": "alt"},
			{"kind": "halo_wisp", "count": 5, "gap": 0.55, "lane": "alt"},
		],
	},
	{
		"title": "Before the Nap",
		"preview": "10 Eye-Squids, 4 Star-Toads, 4 Halo Wisps, 3 Egg Sacs",
		"entries": [
			{"kind": "eye_squid", "count": 10, "gap": 0.34, "lane": "alt"},
			{"kind": "star_toad", "count": 4, "gap": 0.55, "lane": "alt"},
			{"kind": "halo_wisp", "count": 4, "gap": 0.5, "lane": "alt"},
			{"kind": "egg_sac", "count": 3, "gap": 0.7, "lane": "alt"},
		],
	},
	{
		"title": "Grand Nibbler",
		"preview": "Grand Nibbler, plus Eye-Squids & Egg Sacs",
		"boss": true,
		"entries": [
			{"kind": "grand_nibbler", "count": 1, "gap": 1.2, "lane": "a"},
			{"kind": "eye_squid", "count": 8, "gap": 0.48, "lane": "alt"},
			{"kind": "egg_sac", "count": 2, "gap": 1.0, "lane": "b"},
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
