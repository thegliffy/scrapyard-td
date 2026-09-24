# Scrapyard TD

A cozy, **bright** cartoony **grid tower defense**. Cute eldritch horrors leak out of two rifts and hop, cell by cell, toward the **Station Core**. Pop them for **gold**, spend it on chunky cartoon guns, and keep the core lit.

**Battle** is the current mode. **Adventure** is a menu tile only — it is not playable yet. Desktop only (Godot 4). Not a web game. True top-down — not isometric. The menu splash is a staged illustration; the match itself stays on the grid.

## Download

**[v0.3.0](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.3.0)** is the current build. You do not need Godot.

### Windows

1. Download [ScrapyardTD-v0.3.0-windows-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.3.0/ScrapyardTD-v0.3.0-windows-x86_64.zip).
2. Unzip it.
3. Double-click `ScrapyardTD.exe`.

### Linux (x86_64)

1. Download [ScrapyardTD-v0.3.0-linux-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.3.0/ScrapyardTD-v0.3.0-linux-x86_64.zip).
2. Unzip it.
3. Make it executable and run it:

```bash
chmod +x ScrapyardTD.x86_64
./ScrapyardTD.x86_64
```

Older cuts: [v0.2.2](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.2.2), [v0.2.1](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.2.1), [v0.2.0](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.2.0), [v0.1.2](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.2), [v0.1.1](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.1), [v0.1.0](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.0).

## Open in Godot

1. Install [Godot 4.3 or newer](https://godotengine.org/download) (developed on 4.7).
2. **Import** or **Open** this folder (`project.godot`).
3. Press **F5** / **Play**. The game opens on `scenes/main_menu.tscn`. **Battle** picks a yard and starts the run.

Rebuild the executables with Godot 4.7 and the matching export templates. Presets are in `export_presets.cfg`. Each export is one file with the game packed inside.

```bash
godot --headless --path . --export-release "Linux" export/linux/ScrapyardTD.x86_64
godot --headless --path . --export-release "Windows Desktop" export/windows/ScrapyardTD.exe
```

## How to play

The executable opens a **main menu** on the bright splash of the cartoon guns firing on the Big Cute Boss. The title and buttons fade in over about a second while the splash eases to a dimmer twin. Your persistent **scrap** total sits under the title.

| Button | What it does |
| --- | --- |
| **Battle** | Pick an unlocked yard, then start a run |
| **Adventure** | Coming soon. It does not start a mode |
| **Unlocks** | Spend scrap on guns, yards, and loadout slots |
| **Bestiary** | Enemy notes. Unseen critters stay a silhouette until you meet them in Battle |
| **Settings** | Mute. The choice is saved |
| **Quit** | Closes the desktop app |

Two currencies:

- **Gold** is the in-run currency. You start each Battle with **170 gold**. It pays for placing and upgrading, and it resets when the Battle ends. Popping critters, the Scrap Magnet, and calling a wave early all pay gold.
- **Scrap** is meta progress. It is never spent during a Battle. A win pays **2 scrap for each wave cleared** (200 if you finish all 100). A loss pays a flat **1 scrap**, no matter how far you got. Scrap is saved on this machine (`user://profile.cfg`).

You own **Pea Blaster**, **Glue Goo**, and the **Yard Approach** map from the start. The Battle bar shows only the guns in your loadout, not every gun you own.

1. On **Unlocks**, click a gun you own, then click a loadout slot. Click a filled slot to clear it. Putting a gun into a slot that already holds another one swaps them.
2. The loadout has **5 slots**. Slots **1–3 are free**. Slot **4 costs 30 scrap** and slot **5 costs 50 scrap**. Until you buy one, it shows a lock and the cost. You cannot equip a gun into a locked slot, and slot 5 cannot be bought before slot 4.
3. **Battle**, pick a yard, then pick a tower from the **bottom bar** (the chip shows the weapon sprite, the slot number, a short name, and the gold cost) or press `1`–`5` for that slot. An empty slot does nothing.
4. Click a gold **+** on a hardpoint. Slots come in **pods of four** (a 2×2 of marked cells). Empty cells in a pod can each hold one tower. There is no free placement.
5. Click a built tower to inspect it. Tiles in range light up. Upgrade (`U`) up to 3 tiers, or sell (`Backspace`) for 60% of the gold you spent.
6. You can build during a wave. `Space` calls the next wave early for a little bonus gold. `F` toggles 2× speed.

Clear **100 waves** to win. The Big Cute Boss shows up at waves **21, 40, 60, 80, and 100**. Sky Nap, a flying boss, shows up at **50** and **90**. Later visits have more health. If the core hits 0, you lose. The end screen shows gold earned and scrap gained, and offers **Battle again** (or `R`) and **Main menu**.

Guns only hit the layer printed on them: **Ground**, **Air**, or **Both**. Scrap Magnet does not shoot. Pea Blaster and Spark Arc hit both. Glue and Boom stay on the ground. Flak, Needle, and Net are for flyers (Net's tier 3 also slows nearby ground critters). Dual Rail and Orbit Drone hit both.

| Input | Action |
| --- | --- |
| `1`–`5` or a bottom chip | Choose the gun in that loadout slot |
| Left click a gold pad | Build it on that hardpoint |
| Left click a tower | Inspect it. Range lights up in tiles |
| `U` or **Up** | Upgrade (3 tiers) |
| `Backspace` or **Sell** | Sell for 60% of the gold you spent |
| `Space` or **Call** | Send the next wave early for a little bonus gold |
| `F` or **1× / 2×** | Toggle double speed |
| `Esc` | Cancel the current selection |
| `R` | Restart after a win or a loss |

## Design (v0.3.0)

- **Cute and bright.** The yard is a light lavender-and-cream board, not a night scene. UI panels are soft cream and pink. Guns are chunky cartoons with faces — friendly, not hard scrap hardware.
- **Top-down grid.** The board is **24 × 11 tiles**. Lanes are sequences of those cells. Critters sit, then hop to the next cell center. They never path off the grid.
- **Fixed slots, groups of four.** **36 slots** in **nine 2×2 pods** (north entry and mid, both sides of the east lane, the merge, and the south lane).
- **Weapon icons.** Each Battle selection chip, and the Unlocks gun tiles, shows the whole cartoon inside the box. The drawing is trimmed to its real edges, kept in proportion, and inset so it cannot spill over the frame.
- **Loadout.** Five Battle slots. The first three are free. Slot 4 is 30 scrap and slot 5 is 50 scrap. Only equipped guns appear on the bar. Starters sit in slots 1 and 2 (Pea, Glue).
- **Yards.** **Yard Approach** is free. **Side Dock** (50 scrap) and **Deep Yard** (100 scrap) use the same lanes, with a tint and a light health / speed bump. They are not new layouts.
- **Waves.** **100 waves.** The first 21 are still curated, including a first flight of Small Flyers on wave 14. After that, waves are built from templates: more critters, tighter gaps, flyers mixed in, and a health multiplier that keeps climbing. Ground bosses return at 40, 60, 80, and 100. Flying bosses are at 50 and 90. Health does not freeze at the old wave-21 cap.
- **Early speed.** Fast Skitters (the opener, and every later wave that reuses them) move **20% slower** than the original v0.1.0 base. Later enemy types were not slowed.
- Range, chain jumps, glue, and bomb splash are measured in **tiles**. A tower only acquires and damages critters on its layer. Splash and Spark chains follow the same rule. Among valid targets, they shoot whatever is closest to the core, and they focus a boss they can actually hit.

## Unlocks

Spent from persistent scrap. Starters are already owned.

| Unlock | Scrap |
| --- | --- |
| Spark Arc | 40 |
| Flak Puff | 45 |
| Sky Needle | 55 |
| Boom Barrel | 60 |
| Net Lob | 65 |
| Dual Rail | 70 |
| Scrap Magnet | 80 |
| Orbit Drone | 90 |
| Side Dock | 50 |
| Deep Yard | 100 |
| Loadout slot 4 | 30 |
| Loadout slot 5 | 50 |

## Towers

| Tower | Hits | Role |
| --- | --- | --- |
| Pea Blaster | Both | Cheap single-target cannon. Starts equipped |
| Spark Arc | Both | Hits one critter, then jumps to neighbors it can reach |
| Glue Goo | Ground | Slows ground critters. Tier 3 also gums nearby friends. Starts equipped |
| Boom Barrel | Ground | Splash on ground critters only |
| Scrap Magnet | — | No gun. Drips gold, and a little extra when something pops nearby |
| Flak Puff | Air | Cheap air splash |
| Sky Needle | Air | Fast single-target shots at flyers |
| Dual Rail | Both | A medium gun for either layer |
| Net Lob | Air | Slows flyers. Tier 3 also slows nearby ground critters |
| Orbit Drone | Both | Slow, heavy, with a little splash on either layer |

## Enemies

Cute cosmic weirdos, not ships. Cozy first, uncanny second. No gore.

| Critter | Role |
| --- | --- |
| Fast Skitter | Tiny pink spider. Quick, but the opening gives you a beat to build |
| Chunky Tank | Purple turtle. Heavy shell, slow. Pops into three smaller Tanklets |
| Tanklet | A smaller tank. Does not split again |
| Shielded | Shy mint creature in a glass bubble. On pop, drops two Open Shells with no bubble |
| Open Shell | The creature after the bubble breaks. Weaker, and it does not split |
| Swarm-Splitter | Orange blob. On pop, splits into three Swarmlings |
| Swarmling | A little piece of the swarm. Tiny, quick, and it does not split |
| Elite Tank | A mid-game heavy. Pops into two Chunky Tanks, and those still drop Tanklets |
| Big Cute Boss | Ground boss at waves 21, 40, 60, 80, and 100. Later visits have more health. Burps Swarmlings |
| Small Flyer | Tiny moth above the lane. Fast, low health. First shows up on wave 14 |
| Flyer | A medium flyer on the same lane, drawn a bit above the tiles |
| Shielded Flyer | A flyer in a bubble. Pops into two Small Flyers |
| Sky Nap | Flying boss at waves 50 and 90. Sheds Small Flyers as it drifts |

Popping a splitter is not always safer than letting it walk. Swarmlings are faster than the blob, and a Chunky Tank leaves three Tanklets behind. The chain stops at the smallest tier.

## Version history

- **0.1.0** — First playable cut. Top-down grid, fixed slots, cute eldritch roster, scrapyard towers, one map, win/lose. Windows and Linux builds.
- **0.1.1** — Hardpoints expanded to nine 2×2 pods (36 slots). Bottom bar shows each tower's sprite. Fast Skitters slowed 20%.
- **0.1.2** — Weapon icons fit their squares. 20 waves plus the boss, with a gentler ramp, and starting gold 170. The yard and UI are candy-bright. Guns are the art-director cartoons (tower sheet), including on the bottom bar. A main menu opens on the bright splash and crossfades to the dimmer one as the buttons appear.
- **0.2.0** — Meta layer. The menu is Battle, Adventure (coming soon), Unlocks, Settings, and Quit, with persistent scrap on the splash. In-run currency is gold and resets every Battle. Scrap is awarded at the end (a win pays more; a loss is a flat 8) and is spent only on the Unlocks screen. Guns and yards you have not bought stay out of the Battle. A 5-slot loadout gates the bottom bar: slots 1–3 are free, slots 4 and 5 cost scrap. Side Dock and Deep Yard reuse the Yard Approach lanes.
- **0.2.1** — Battle selection icons actually fit in their boxes. The tower image was being left at its full pixel size, so the gun spilled out of the chip. Each icon is now inset inside the frame, aspect kept, with padding around the drawing. Unlocks tiles use the same fit.
- **0.2.2** — Battles are 100 waves, with bosses at 21, 40, 60, 80, and 100. Health keeps scaling after the old finale. Chunky Tanks, Shielded, and Elite Tanks pop into weaker versions of themselves. A win pays 2 scrap per wave cleared. A loss pays 1 scrap.
- **0.3.0** — Bestiary on the main menu, remembered per critter. Four flying kinds ride the lane a little above the tiles. Every gun has a layer: Ground, Air, or Both (Pea hits both). Five new unlocks: Flak Puff, Sky Needle, Dual Rail, Net Lob, and Orbit Drone. Flyers join from wave 14, and Sky Nap arrives at waves 50 and 90.

## Art

`assets/concept/` holds the art-direction boards. The original five guns are cut from `02_towers_sheet.png` and scaled to fit each square. Flak Puff, Sky Needle, Dual Rail, Net Lob, Orbit Drone, and the four flying critters use stand-in drawings in the same cute style until the art director drops replacements into `assets/sprites/towers/` and `assets/sprites/enemies/`. The menu background is the art-director splash: `assets/ui/main_menu_splash.png` (full color) crossfades to `assets/ui/main_menu_splash_dim.png` as the title and buttons appear.

```bash
python3 tools/slice_towers.py
python3 tools/make_art.py
python3 tools/make_sfx.py
```

UI type is [Nunito](https://fonts.google.com/specimen/Nunito), SIL Open Font License (`assets/fonts/OFL-Nunito.txt`).
