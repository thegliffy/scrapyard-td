# Scrapyard TD

A cozy, **bright** cartoony **grid tower defense**. Cute eldritch horrors leak out of two rifts and hop, cell by cell, toward the **Station Core**. Pop them for **gold**, spend it on chunky cartoon guns, and keep the core lit.

**Battle** is the current mode. **Adventure** is a menu tile only — it is not playable yet. Desktop only (Godot 4). Not a web game. True top-down — not isometric. The menu splash is a staged illustration; the match itself stays on the grid.

## Download

**[v0.2.0](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.2.0)** is the current build. You do not need Godot.

### Windows

1. Download [ScrapyardTD-v0.2.0-windows-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.2.0/ScrapyardTD-v0.2.0-windows-x86_64.zip).
2. Unzip it.
3. Double-click `ScrapyardTD.exe`.

### Linux (x86_64)

1. Download [ScrapyardTD-v0.2.0-linux-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.2.0/ScrapyardTD-v0.2.0-linux-x86_64.zip).
2. Unzip it.
3. Make it executable and run it:

```bash
chmod +x ScrapyardTD.x86_64
./ScrapyardTD.x86_64
```

Older cuts: [v0.1.2](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.2), [v0.1.1](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.1), [v0.1.0](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.0).

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
| **Settings** | Mute. The choice is saved |
| **Quit** | Closes the desktop app |

Two currencies:

- **Gold** is the in-run currency. You start each Battle with **170 gold**. It pays for placing and upgrading, and it resets when the Battle ends. Popping critters, the Scrap Magnet, and calling a wave early all pay gold.
- **Scrap** is meta progress. It is never spent during a Battle. A win pays **18 scrap**, plus 1 for every 5 waves cleared, capped at **25**. A loss pays a flat **8 scrap**, no matter how far you got. Scrap is saved on this machine (`user://profile.cfg`).

You own **Pea Blaster**, **Glue Goo**, and the **Yard Approach** map from the start. The Battle bar shows only the guns in your loadout, not every gun you own.

1. On **Unlocks**, click a gun you own, then click a loadout slot. Click a filled slot to clear it. Putting a gun into a slot that already holds another one swaps them.
2. The loadout has **5 slots**. Slots **1–3 are free**. Slot **4 costs 30 scrap** and slot **5 costs 50 scrap**. Until you buy one, it shows a lock and the cost. You cannot equip a gun into a locked slot, and slot 5 cannot be bought before slot 4.
3. **Battle**, pick a yard, then pick a tower from the **bottom bar** (the chip shows the weapon sprite, the slot number, a short name, and the gold cost) or press `1`–`5` for that slot. An empty slot does nothing.
4. Click a gold **+** on a hardpoint. Slots come in **pods of four** (a 2×2 of marked cells). Empty cells in a pod can each hold one tower. There is no free placement.
5. Click a built tower to inspect it. Tiles in range light up. Upgrade (`U`) up to 3 tiers, or sell (`Backspace`) for 60% of the gold you spent.
6. You can build during a wave. `Space` calls the next wave early for a little bonus gold. `F` toggles 2× speed.

Clear **20 waves**, then pop the **Big Cute Boss**, to win. If the core hits 0, you lose. The end screen shows gold earned and scrap gained, and offers **Battle again** (or `R`) and **Main menu**.

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

## Design (v0.2.0)

- **Cute and bright.** The yard is a light lavender-and-cream board, not a night scene. UI panels are soft cream and pink. Guns are chunky cartoons with faces — friendly, not hard scrap hardware.
- **Top-down grid.** The board is **24 × 11 tiles**. Lanes are sequences of those cells. Critters sit, then hop to the next cell center. They never path off the grid.
- **Fixed slots, groups of four.** **36 slots** in **nine 2×2 pods** (north entry and mid, both sides of the east lane, the merge, and the south lane).
- **Weapon icons.** Each gun tile — the Battle bar and the Unlocks rows and slots — shows that tower's cartoon sprite scaled down so the whole drawing sits inside the square with padding.
- **Loadout.** Five Battle slots. The first three are free. Slot 4 is 30 scrap and slot 5 is 50 scrap. Only equipped guns appear on the bar. Starters sit in slots 1 and 2 (Pea, Glue).
- **Yards.** **Yard Approach** is free. **Side Dock** (50 scrap) and **Deep Yard** (100 scrap) use the same lanes, with a tint and a light health / speed bump. They are not new layouts.
- **Waves.** **20 waves, then the boss.** New kinds arrive a few at a time, and the count / gap / speed mix climbs gradually through the early and mid game instead of spiking.
- **Early speed.** Fast Skitters (the opener, and every later wave that reuses them) move **20% slower** than the original v0.1.0 base. Later enemy types were not slowed.
- Range, chain jumps, glue, and bomb splash are measured in **tiles**. Towers shoot whatever is closest to the core. If the boss is in range and nobody is about to leak, they focus the boss.

## Unlocks

Spent from persistent scrap. Starters are already owned.

| Unlock | Scrap |
| --- | --- |
| Spark Arc | 40 |
| Boom Barrel | 60 |
| Scrap Magnet | 80 |
| Side Dock | 50 |
| Deep Yard | 100 |
| Loadout slot 4 | 30 |
| Loadout slot 5 | 50 |

## Towers

| Tower | Role |
| --- | --- |
| Pea Blaster | Cheap single-target cannon. Starts equipped |
| Spark Arc | Hits one critter, then jumps to neighbors |
| Glue Goo | Slows. Tier 3 also gums nearby friends. Starts equipped |
| Boom Barrel | Splash on a cluster of tiles |
| Scrap Magnet | No gun. Drips gold, and a little extra when something pops nearby |

## Enemies

Cute cosmic weirdos, not ships. Cozy first, uncanny second. No gore.

| Critter | Role |
| --- | --- |
| Fast Skitter | Tiny pink spider. Quick, but the opening gives you a beat to build |
| Chunky Tank | Purple turtle. Heavy shell, slow |
| Shielded | Shy mint creature in a glass bubble. Pop the bubble, then the critter |
| Swarm-Splitter | Orange blob. On pop, splits into three Swarmlings |
| Swarmling | A little piece of the swarm. Tiny and quick |
| Big Cute Boss | The final boss. Purple, horned, many eyes. Burps Swarmlings. Do not let it reach the core |

Popping a Swarm-Splitter is not always safer than letting it walk: the Swarmlings are faster than the blob was.

## Version history

- **0.1.0** — First playable cut. Top-down grid, fixed slots, cute eldritch roster, scrapyard towers, one map, win/lose. Windows and Linux builds.
- **0.1.1** — Hardpoints expanded to nine 2×2 pods (36 slots). Bottom bar shows each tower's sprite. Fast Skitters slowed 20%.
- **0.1.2** — Weapon icons fit their squares. 20 waves plus the boss, with a gentler ramp, and starting gold 170. The yard and UI are candy-bright. Guns are the art-director cartoons (tower sheet), including on the bottom bar. A main menu opens on the bright splash and crossfades to the dimmer one as the buttons appear.
- **0.2.0** — Meta layer. The menu is Battle, Adventure (coming soon), Unlocks, Settings, and Quit, with persistent scrap on the splash. In-run currency is gold and resets every Battle. Scrap is awarded at the end (a win pays more; a loss is a flat 8) and is spent only on the Unlocks screen. Guns and yards you have not bought stay out of the Battle. A 5-slot loadout gates the bottom bar: slots 1–3 are free, slots 4 and 5 cost scrap. Side Dock and Deep Yard reuse the Yard Approach lanes.

## Art

`assets/concept/` holds the art-direction boards. In-game guns and the gun tiles are cut from `02_towers_sheet.png` (Pea Blaster, Spark Arc, Glue Goo, Boom Barrel, Scrap Magnet) and scaled to fit each square. The menu background is the art-director splash: `assets/ui/main_menu_splash.png` (full color) crossfades to `assets/ui/main_menu_splash_dim.png` as the title and buttons appear.

```bash
python3 tools/slice_towers.py
python3 tools/make_art.py
python3 tools/make_sfx.py
```

UI type is [Nunito](https://fonts.google.com/specimen/Nunito), SIL Open Font License (`assets/fonts/OFL-Nunito.txt`).
