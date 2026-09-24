# Scrapyard TD

A cozy top-down tower defense. You are the dock boss of a tiny scrap yard. Cute eldritch things leak out of two rifts and hop along the lanes toward the **Station Core**. Pop them for scrap, spend it on towers, and keep the core lit.

Godot 4 · desktop · one mission. Not a web game.

## Download

**[v0.1.1](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.1.1)** is the current playable build. You do not need the Godot editor.

### Windows

1. Download [ScrapyardTD-v0.1.1-windows-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.1.1/ScrapyardTD-v0.1.1-windows-x86_64.zip).
2. Unzip it.
3. Double-click `ScrapyardTD.exe`.

### Linux (x86_64)

1. Download [ScrapyardTD-v0.1.1-linux-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.1.1/ScrapyardTD-v0.1.1-linux-x86_64.zip).
2. Unzip it.
3. Make it executable and run it:

```bash
chmod +x ScrapyardTD.x86_64
./ScrapyardTD.x86_64
```

## Play from source

1. Install [Godot 4.3 or newer](https://godotengine.org/download) (developed on 4.7).
2. Open this folder as a project (`project.godot`).
3. Press **Play**.

To rebuild the executables (Godot 4.7, with the matching export templates installed):

```bash
godot --headless --path . --export-release "Linux" export/linux/ScrapyardTD.x86_64
godot --headless --path . --export-release "Windows Desktop" export/windows/ScrapyardTD.exe
```

Presets live in `export_presets.cfg`. Each build is one file with the game packed inside.

You have a few seconds before the first leak. Cover **both** rifts. The north lane is blue, the south lane is pink, and they merge on the lilac tiles into the core. Gold squares with a plus are the only build spots, grouped as **2×2 pods**. The bottom bar shows each weapon's sprite.

Clear all 12 waves and pop the **Big Cute Boss** to win. If the core hits 0, the yard goes dark. **Try again** is on the end screen (or press `R`).

## Controls

| Input | Action |
| --- | --- |
| `1`–`5` or a bottom chip | Choose a tower |
| Left click a gold pad | Build it there |
| Left click a tower | Inspect it. Its range lights up the tiles |
| `U` or **Up** | Upgrade (3 tiers) |
| `Backspace` or **Sell** | Sell for 60% of what you spent |
| `Space` or **Call** | Send the next wave early for a little bonus scrap |
| `F` or **1× / 2×** | Toggle double speed |
| `Esc` | Cancel the current selection |
| `R` | Restart after a win or a loss |

You can build and upgrade during a wave, not only between them.

## The yard is a grid

The board is **24 × 11 tiles**. Lanes are sequences of those tiles. Critters move **cell to cell** (they sit, then hop to the next center). They never path off the grid.

Build slots are **36 marked cells in nine 2×2 pods** (north entry and mid, both sides of the east lane, the merge, and the south lane). There is no free placement.

Range, chain jumps, glue, and bomb splash are all measured in **tiles**. Selecting a tower lights every cell in range.

## Towers

| Tower | Role |
| --- | --- |
| Pea Blaster | Cheap single-target scrap cannon |
| Spark Arc | Hits one critter, then jumps to neighbors |
| Glue Goo | Slows. Tier 3 also gums nearby friends |
| Boom Barrel | Splash on a cluster of tiles |
| Scrap Magnet | No gun. Drips scrap, and a little extra when something pops nearby |

Towers shoot whatever is closest to the core. If the Big Cute Boss is in range and nobody is about to leak, they focus the boss instead.

## The leaks

These are cute cosmic weirdos, not ships. Cozy first, uncanny second. No gore.

| Critter | Role |
| --- | --- |
| Fast Skitter | Tiny pink spider. Quick, but the opening gives you a beat to build |
| Chunky Tank | Purple turtle. Heavy shell, slow |
| Shielded | Shy mint creature in a glass bubble. Pop the bubble, then the critter |
| Swarm-Splitter | Orange blob. On pop, splits into three Swarmlings |
| Swarmling | A little piece of the swarm. Tiny and quick |
| Big Cute Boss | The final boss. Purple, horned, many eyes, very huggable. Burps swarmlings. Do not let it reach the core |

Killing a sac is not always safer than letting it walk: the babies are faster than the sac was.

## Art

`assets/concept/` holds the art-direction boards. Gameplay is true top-down on the grid; the 3/4 mood vignette is mood only. Enemy sprites follow the latest roster sheet: a pink Fast Skitter, a purple Chunky Tank, a shy mint Shielded inside a glass bubble, an orange Swarm-Splitter, and a horned many-eyed Big Cute Boss. In-game sprites are original flat cartoons in that same bold-outline language, drawn to read on a single tile.

Sprites and blips can be regenerated with:

```bash
python3 tools/make_art.py
python3 tools/make_sfx.py
```

UI type is [Nunito](https://fonts.google.com/specimen/Nunito), under the SIL Open Font License (`assets/fonts/OFL-Nunito.txt`).
