# Scrapyard TD

A cozy, **bright** cartoony **grid tower defense**. Cute eldritch horrors leak out of two rifts and hop, cell by cell, toward the **Station Core**. Pop them for scrap, spend it on chunky cartoon guns, and keep the core lit.

One mission. Desktop only (Godot 4). Not a web game. True top-down — not isometric. The menu splash is a staged illustration; the match itself stays on the grid.

## Download

**[v0.1.2](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.2)** is the current build. You do not need Godot.

### Windows

1. Download [ScrapyardTD-v0.1.2-windows-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.1.2/ScrapyardTD-v0.1.2-windows-x86_64.zip).
2. Unzip it.
3. Double-click `ScrapyardTD.exe`.

### Linux (x86_64)

1. Download [ScrapyardTD-v0.1.2-linux-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.1.2/ScrapyardTD-v0.1.2-linux-x86_64.zip).
2. Unzip it.
3. Make it executable and run it:

```bash
chmod +x ScrapyardTD.x86_64
./ScrapyardTD.x86_64
```

Older cuts: [v0.1.1](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.1), [v0.1.0](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.0).

## Open in Godot

1. Install [Godot 4.3 or newer](https://godotengine.org/download) (developed on 4.7).
2. **Import** or **Open** this folder (`project.godot`).
3. Press **F5** / **Play**. The game opens on `scenes/main_menu.tscn`. **Play** starts the run.

Rebuild the executables with Godot 4.7 and the matching export templates. Presets are in `export_presets.cfg`. Each export is one file with the game packed inside.

```bash
godot --headless --path . --export-release "Linux" export/linux/ScrapyardTD.x86_64
godot --headless --path . --export-release "Windows Desktop" export/windows/ScrapyardTD.exe
```

## How to play

The executable opens a **main menu** on the bright splash of the cartoon guns firing on the Big Cute Boss. The title, **Play**, and **Quit** fade in over about a second while the splash eases to a dimmer twin so the buttons stay readable. **Play** starts the run. **Quit** closes the desktop app.

You start with **170 scrap** and a few seconds before the first leak. Cover **both** rifts. The north lane is blue, the south lane is pink, and they merge on the lilac tiles into the core.

1. Pick a tower from the **bottom bar** (the chip shows the weapon sprite, a hotkey, a short name, and the cost) or press `1`–`5`.
2. Click a gold **+** on a hardpoint. Slots come in **pods of four** (a 2×2 of marked cells). Empty cells in a pod can each hold one tower. There is no free placement.
3. Click a built tower to inspect it. Tiles in range light up. Upgrade (`U`) up to 3 tiers, or sell (`Backspace`) for 60% of what you spent.
4. You can build during a wave. `Space` calls the next wave early for a little bonus scrap. `F` toggles 2× speed.

Clear **20 waves**, then pop the **Big Cute Boss**, to win. If the core hits 0, you lose. The end screen offers **Play again** (or `R`) and **Main menu**.

| Input | Action |
| --- | --- |
| `1`–`5` or a bottom chip | Choose a tower |
| Left click a gold pad | Build it on that hardpoint |
| Left click a tower | Inspect it. Range lights up in tiles |
| `U` or **Up** | Upgrade (3 tiers) |
| `Backspace` or **Sell** | Sell for 60% of what you spent |
| `Space` or **Call** | Send the next wave early for a little bonus scrap |
| `F` or **1× / 2×** | Toggle double speed |
| `Esc` | Cancel the current selection |
| `R` | Restart after a win or a loss |

## Design (v0.1.2)

- **Cute and bright.** The yard is a light lavender-and-cream board, not a night scene. UI panels are soft cream and pink. Guns are chunky cartoons with faces — friendly, not hard scrap hardware.
- **Top-down grid.** The board is **24 × 11 tiles**. Lanes are sequences of those cells. Critters sit, then hop to the next cell center. They never path off the grid.
- **Fixed slots, groups of four.** **36 slots** in **nine 2×2 pods** (north entry and mid, both sides of the east lane, the merge, and the south lane).
- **Weapon icons.** Each bottom-bar square shows that tower's cartoon sprite, scaled to fit inside the chip with padding.
- **Waves.** **20 waves, then the boss.** New kinds arrive a few at a time, and the count / gap / speed mix climbs gradually through the early and mid game instead of spiking.
- **Early speed.** Fast Skitters (the opener, and every later wave that reuses them) move **20% slower** than the original v0.1.0 base. Later enemy types were not slowed.
- Range, chain jumps, glue, and bomb splash are measured in **tiles**. Towers shoot whatever is closest to the core. If the boss is in range and nobody is about to leak, they focus the boss.

## Towers

| Tower | Role |
| --- | --- |
| Pea Blaster | Cheap single-target scrap cannon |
| Spark Arc | Hits one critter, then jumps to neighbors |
| Glue Goo | Slows. Tier 3 also gums nearby friends |
| Boom Barrel | Splash on a cluster of tiles |
| Scrap Magnet | No gun. Drips scrap, and a little extra when something pops nearby |

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
- **0.1.2** — Weapon icons fit their squares. 20 waves plus the boss, with a gentler ramp, and starting scrap 170. The yard and UI are candy-bright. Guns are the art-director cartoons (tower sheet), including on the bottom bar. A main menu opens on the bright splash and crossfades to the dimmer one as Play and Quit appear. Win or lose returns to Play again or the menu.

## Art

`assets/concept/` holds the art-direction boards. In-game guns and the bottom-bar icons are cut from `02_towers_sheet.png` (Pea Blaster, Spark Arc, Glue Goo, Boom Barrel, Scrap Magnet) and scaled to fit each square. The menu background is the art-director splash: `assets/ui/main_menu_splash.png` (full color) crossfades to `assets/ui/main_menu_splash_dim.png` as the title and buttons appear.

```bash
python3 tools/slice_towers.py
python3 tools/make_art.py
python3 tools/make_sfx.py
```

UI type is [Nunito](https://fonts.google.com/specimen/Nunito), SIL Open Font License (`assets/fonts/OFL-Nunito.txt`).
