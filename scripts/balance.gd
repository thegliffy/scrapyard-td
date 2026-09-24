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
		"tint": "#6a62d8",
		"tint_amount": 0.3,
		"hp_scale": 1.18,
		"speed_scale": 1.06,
	},
}

const TOWERS := {
	"pea": {
		"name": "Pea Blaster",
		"short": "Pea",
		"target": "both",
		"blurb": "Cheap and peppy. Hits ground and air.",
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
		"target": "both",
		"blurb": "Zaps a critter, then jumps. Hits ground and air.",
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
		"target": "ground",
		"blurb": "Slows critters on the ground.",
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
		"target": "ground",
		"blurb": "Lobs a bomb. Splash hits the ground only.",
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
		"target": "none",
		"blurb": "No shooting. Pulls extra gold out of the yard.",
		"cost": 80,
		"upgrade": [65, 110],
		"range": [3.0, 3.4, 3.8],
		"income": [5, 8, 12],
		"income_every": [4.0, 3.3, 2.6],
		"bonus": [2, 4, 6],
	},
	"flak": {
		"name": "Flak Puff",
		"short": "Flak",
		"target": "air",
		"blurb": "A cheap puff of flak. Splash hits air only.",
		"cost": 70,
		"upgrade": [55, 90],
		"range": [3.2, 3.5, 3.8],
		"damage": [10.0, 16.0, 26.0],
		"rate": [0.7, 0.85, 1.0],
		"shot_speed": 9.0,
		"splash": [1.2, 1.4, 1.6],
	},
	"needle": {
		"name": "Sky Needle",
		"short": "Needle",
		"target": "air",
		"blurb": "A fast stitch of light. One flyer at a time.",
		"cost": 60,
		"upgrade": [50, 85],
		"range": [4.0, 4.4, 4.8],
		"damage": [9.0, 15.0, 24.0],
		"rate": [2.2, 2.6, 3.1],
		"shot_speed": 16.0,
	},
	"dual": {
		"name": "Dual Rail",
		"short": "Dual",
		"target": "both",
		"blurb": "Two little rails. Hits ground and air.",
		"cost": 110,
		"upgrade": [80, 120],
		"range": [3.6, 4.0, 4.3],
		"damage": [11.0, 18.0, 28.0],
		"rate": [1.3, 1.5, 1.75],
		"shot_speed": 14.0,
	},
	"net": {
		"name": "Net Lob",
		"short": "Net",
		"target": "air",
		"blurb": "Slows flyers. Tier 3 also gums nearby ground critters.",
		"cost": 85,
		"upgrade": [65, 100],
		"range": [3.4, 3.7, 4.0],
		"damage": [3.0, 5.0, 8.0],
		"rate": [1.0, 1.15, 1.3],
		"shot_speed": 10.0,
		"slow": [0.5, 0.38, 0.28],
		"slow_time": [1.8, 2.3, 2.8],
		"slow_splash": [0.0, 0.0, 1.3],
	},
	"orbit": {
		"name": "Orbit Drone",
		"short": "Orbit",
		"target": "both",
		"blurb": "Slow, heavy, and a little splash. Hits ground and air.",
		"cost": 140,
		"upgrade": [100, 150],
		"range": [3.8, 4.2, 4.6],
		"damage": [28.0, 42.0, 64.0],
		"rate": [0.45, 0.55, 0.65],
		"shot_speed": 7.0,
		"splash": [1.1, 1.25, 1.4],
	},
	"stomper": {
		"name": "Stomper",
		"short": "Stomp",
		"target": "ground",
		"blurb": "Slams the ground around itself. No shot. Ignores flyers.",
		"cost": 100,
		"upgrade": [80, 120],
		"range": [2.3, 2.6, 2.9],
		"damage": [16.0, 26.0, 42.0],
		"rate": [0.5, 0.62, 0.75],
	},
	"fizz": {
		"name": "Fizz Cloud",
		"short": "Fizz",
		"target": "air",
		"blurb": "Lobs a cloud onto flyers. It lingers and ignores the ground.",
		"cost": 110,
		"upgrade": [85, 130],
		"range": [3.5, 3.9, 4.3],
		"damage": [4.0, 7.0, 11.0],
		"rate": [0.32, 0.4, 0.48],
		"radius": [1.5, 1.75, 2.0],
		"tick": [0.4, 0.4, 0.35],
		"linger": [2.0, 2.6, 3.2],
	},
	"nova": {
		"name": "Nova",
		"short": "Nova",
		"target": "both",
		"blurb": "A slow heavy pulse. Hits everything in range, ground and air.",
		"cost": 175,
		"upgrade": [130, 190],
		"range": [3.2, 3.6, 4.0],
		"damage": [16.0, 28.0, 48.0],
		"rate": [0.3, 0.38, 0.46],
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
		"flying": false,
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
		"flying": false,
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
		"flying": false,
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
		"flying": false,
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
		"flying": false,
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
		"flying": false,
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
		"flying": false,
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
		"flying": false,
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
		"flying": false,
		"minion_kind": "swarmling",
	},
	"small_flyer": {
		"name": "Small Flyer",
		"hp": 22,
		"shield": 0,
		"speed": 2.55,
		"gold": 5,
		"leak": 1,
		"display": 26.0,
		"tex": 128.0,
		"color": "#ffd0ea",
		"split": 0,
		"split_kind": "",
		"skitter": true,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"flying": true,
		"minion_kind": "",
	},
	"flyer": {
		"name": "Flyer",
		"hp": 64,
		"shield": 0,
		"speed": 1.75,
		"gold": 9,
		"leak": 2,
		"display": 40.0,
		"tex": 128.0,
		"color": "#9ad7ff",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"flying": true,
		"minion_kind": "",
	},
	"shielded_flyer": {
		"name": "Shielded Flyer",
		"hp": 48,
		"shield": 44,
		"speed": 1.4,
		"gold": 12,
		"leak": 2,
		"display": 42.0,
		"tex": 128.0,
		"color": "#7ee0c8",
		"split": 2,
		"split_kind": "small_flyer",
		"skitter": false,
		"baby_every": 0.0,
		"babies": 0,
		"boss": false,
		"flying": true,
		"minion_kind": "",
	},
	"flying_boss": {
		"name": "Sky Nap",
		"hp": 2000,
		"shield": 140,
		"speed": 0.58,
		"gold": 110,
		"leak": 8,
		"display": 84.0,
		"tex": 192.0,
		"color": "#c9a0ff",
		"split": 0,
		"split_kind": "",
		"skitter": false,
		"baby_every": 7.0,
		"babies": 2,
		"boss": true,
		"flying": true,
		"minion_kind": "small_flyer",
	},
}

const BESTIARY := [
	"fast_skitter", "chunky_tank", "tanklet", "shielded", "open_shell",
	"swarm_splitter", "swarmling", "elite_tank", "big_cute_boss",
	"small_flyer", "flyer", "shielded_flyer", "flying_boss",
]

const BLURBS := {
	"fast_skitter": "A tiny pink spider. Quick, and it stays on the tiles.",
	"chunky_tank": "A heavy purple shell. Pops into three smaller Tanklets.",
	"tanklet": "What is left of a Chunky Tank. It does not split again.",
	"shielded": "A shy mint creature in a glass bubble. The pop drops two Open Shells.",
	"open_shell": "The creature after the bubble breaks. Softer, and done splitting.",
	"swarm_splitter": "An orange blob. Pops into three quick Swarmlings.",
	"swarmling": "A little piece of the swarm. Fast, and it does not split.",
	"elite_tank": "A darker, heavier tank. Pops into two Chunky Tanks.",
	"big_cute_boss": "The ground boss. Many eyes, slow crawl, burps Swarmlings.",
	"small_flyer": "A tiny moth above the lane. Fast, and easy to pop.",
	"flyer": "A medium flyer. It follows the lane, one tile up in the air.",
	"shielded_flyer": "A flyer in a bubble. Pop it and two Small Flyers fall out.",
	"flying_boss": "Sky Nap. An aerial boss that sheds Small Flyers as it drifts.",
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
		"title": "First Flight",
		"preview": "8 Small Flyers & 4 Fast Skitters",
		"entries": [
			{"kind": "small_flyer", "count": 8, "gap": 0.7, "lane": "alt"},
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
		"preview": "6 Shielded, 4 Flyers, 6 Skitters",
		"entries": [
			{"kind": "shielded", "count": 6, "gap": 0.65, "lane": "alt"},
			{"kind": "flyer", "count": 4, "gap": 0.75, "lane": "alt"},
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
	if wave_number == 50 or wave_number == 90:
		return _flying_boss_wave(wave_number)
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
	for extra in _air_pack(wave_number, t, gap):
		entries.append(extra)
	return {"title": title, "preview": _preview_from(entries), "entries": entries}


static func _air_pack(wave_number: int, t: float, gap: float) -> Array:
	var pack: Array = []
	if wave_number < 22:
		return pack
	pack.append({"kind": "small_flyer", "count": 4 + int(t * 8), "gap": gap, "lane": "alt"})
	if wave_number >= 28:
		pack.append({"kind": "flyer", "count": 2 + int(t * 4), "gap": gap + 0.06, "lane": "alt"})
	if wave_number >= 42:
		pack.append({"kind": "shielded_flyer", "count": 1 + int(t * 3), "gap": gap + 0.1, "lane": "alt"})
	return pack


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
	if wave_number >= 40:
		entries.append({"kind": "small_flyer", "count": 4 + int(t * 4), "gap": 0.55, "lane": "alt"})
	if wave_number >= 100:
		entries.append({"kind": "elite_tank", "count": 1, "gap": 1.5, "lane": "b"})
	var preview := "Big Cute Boss, plus a deeper escort"
	if wave_number >= 100:
		preview = "The last Big Cute Boss"
	return {"title": title, "preview": preview, "boss": true, "entries": entries}


static func _flying_boss_wave(wave_number: int) -> Dictionary:
	var late := wave_number >= 90
	var entries: Array = [
		{"kind": "flying_boss", "count": 1, "gap": 1.2, "lane": "a"},
		{"kind": "small_flyer", "count": 6 if not late else 10, "gap": 0.45, "lane": "alt"},
		{"kind": "flyer", "count": 3 if not late else 5, "gap": 0.7, "lane": "alt"},
		{"kind": "shielded_flyer", "count": 2 if not late else 4, "gap": 0.85, "lane": "b"},
	]
	var title := "Sky Nap" if not late else "High Nap"
	return {"title": title, "preview": "Sky Nap and a cloud of flyers", "boss": true, "entries": entries}


static func _preview_from(entries: Array) -> String:
	var bits := PackedStringArray()
	for entry in entries:
		var data: Dictionary = ENEMIES[str(entry["kind"])]
		bits.append("%d %s" % [int(entry["count"]), str(data["name"])])
	return ", ".join(bits)


static func cost(id: String) -> int:
	return int(TOWERS[id]["cost"])


static func tower_target(id: String) -> String:
	return str(TOWERS[id].get("target", "ground"))


static func target_label(id: String) -> String:
	match tower_target(id):
		"air":
			return "Air"
		"both":
			return "Both"
		"none":
			return "Yard"
		_:
			return "Ground"


static func layer_matches(layer: String, flying: bool) -> bool:
	if layer == "both":
		return true
	if layer == "air":
		return flying
	if layer == "ground":
		return not flying
	return false


static func can_hit(tower_id: String, enemy_id: String) -> bool:
	if not TOWERS.has(tower_id) or not ENEMIES.has(enemy_id):
		return false
	return layer_matches(tower_target(tower_id), bool(ENEMIES[enemy_id].get("flying", false)))


static func blurb(enemy_id: String) -> String:
	return str(BLURBS.get(enemy_id, ""))


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
