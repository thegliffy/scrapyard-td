# Scrapyard TD

A cozy top-down tower defense. You are the dock boss of a tiny scrap yard. Cute eldritch things leak out of two rifts and hop along the lanes toward the **Station Core**. Pop them for scrap, spend it on towers, and keep the core lit.

Godot 4 · desktop · one mission. Not a web game.

## Play

1. Install [Godot 4.3 or newer](https://godotengine.org/download) (developed on 4.7).
2. Open this folder as a project (`project.godot`).
3. Press **Play**.

You have a few seconds before the first leak. Cover **both** rifts. The north lane is blue, the south lane is pink, and they merge on the lilac tiles into the core. Gold squares with a plus are the only build spots.

Clear all 12 waves and pop **Grand Nibbler** to win. If the core hits 0, the yard goes dark. **Try again** is on the end screen (or press `R`).

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

Build slots are eight marked cells. There is no free placement.

Range, chain jumps, glue, and bomb splash are all measured in **tiles**. Selecting a tower lights every cell in range.

## Towers

| Tower | Role |
| --- | --- |
| Pea Blaster | Cheap single-target scrap cannon |
| Spark Arc | Hits one critter, then jumps to neighbors |
| Glue Goo | Slows. Tier 3 also gums nearby friends |
| Boom Barrel | Splash on a cluster of tiles |
| Scrap Magnet | No gun. Drips scrap, and a little extra when something pops nearby |

Towers shoot whatever is closest to the core. If Grand Nibbler is in range and nobody is about to leak, they focus the boss instead.

## The leaks

These are cute cosmic weirdos, not ships. Cozy first, uncanny second. No gore.

| Critter | Role |
| --- | --- |
| Eye-Squid | Fast little skitterer |
| Star-Toad | Plump tank |
| Halo Wisp | A bubble shield. Pop the halo, then the wisp |
| Egg Sac | On pop, splits into three Fractal Babies |
| Fractal Baby | Tiny and quick |
| Grand Nibbler | The final boss. Slow, huge, and very huggable. Burps babies. Do not let it reach the core |

Killing a sac is not always safer than letting it walk: the babies are faster than the sac was.

## Art

`assets/concept/` holds the art-direction boards: a 3/4 mood vignette (mood only — gameplay is true top-down), tower sheet, cute-eldritch enemy sheet, and UI chip style. In-game sprites are original flat cartoons in that same bold-outline language, drawn to read on a single tile.

Sprites and blips can be regenerated with:

```bash
python3 tools/make_art.py
python3 tools/make_sfx.py
```

UI type is [Nunito](https://fonts.google.com/specimen/Nunito), under the SIL Open Font License (`assets/fonts/OFL-Nunito.txt`).
