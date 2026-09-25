# Scrapyard TD

A cozy cartoon tower defense in deep space. Cute eldritch critters hop a glowing cyan road toward your Station Core. You build only on floating islands, in fixed pods of four, and a run is **100 waves**.

<img src="docs/images/battle.webp" alt="Yard Approach mid-wave. Towers sit on the islands, critters follow the solid cyan road, and Stomper, Fizz Cloud, and Nova are firing." width="880">

**Battle** is the game you can play. **Adventure** is on the menu and coming soon.

## Download

**[v0.4.6](https://github.com/thegliffy/scrapyard-td/releases/tag/v0.4.6)** is the current build. You do not need Godot.

- Windows: [ScrapyardTD-v0.4.6-windows-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.4.6/ScrapyardTD-v0.4.6-windows-x86_64.zip). Unzip it and double-click `ScrapyardTD.exe`.
- Linux x86_64: [ScrapyardTD-v0.4.6-linux-x86_64.zip](https://github.com/thegliffy/scrapyard-td/releases/download/v0.4.6/ScrapyardTD-v0.4.6-linux-x86_64.zip). Unzip, then `chmod +x ScrapyardTD.x86_64` and `./ScrapyardTD.x86_64`.

## How to play

<img src="docs/images/menu.webp" alt="The main menu. The buttons stack in the gap between the two islands, with scrap under the title." width="880">

The menu opens on the splash. The buttons sit in the dark gap between the two islands, and your saved **scrap** is under the title.

You start a fight with **170 gold**, a **Pea Blaster**, and **Glue Goo**. Gold pays for placing and upgrading during the run, and it resets when the run ends. Scrap is the other wallet. You spend it on Unlocks, between fights, and it stays on this machine.

A win pays **2 scrap for each wave cleared** (200 if you finish all 100). A loss pays **1 scrap for each wave cleared**. The wave that knocks the core out does not count. Custom yards and editor playtests pay no scrap.

Wave 1 waits until you press **Start**. Nothing starts it for you, and it pays no bonus. After that, each prep lasts **9 seconds**. **Call** sends the next wave early and pays the seconds left as gold, so a fresh prep pays **9**. **Auto**, under Call, does that for you from the second prep on. It never starts wave 1.

**Pause** (the button, `P`, or `Esc`) freezes the board and the HUD. Resume continues from the same moment, including 1× or 2×.

The core has **22** health. At 0, you lose. Clear all 100 waves to win.

## Yards

Three built-in yards. The picture at the top is **Yard Approach**. The other two are unlocks.

| Yard | Scrap | What is different |
| --- | --- | --- |
| Yard Approach | Starter | Two lanes, nine island pods. Health and speed at their base. |
| Side Dock | 50 | A long pier and a short slip that share a dock. Eight pods. Critters have **1.1×** health. |
| Deep Yard | 100 | Three lanes that merge late, with open ground between the pods. Critters have **1.18×** health and **1.06×** speed. |

<img src="docs/images/side_dock.webp" alt="Side Dock mid-wave. The cyan pier snakes in an S, a short slip joins it, and towers cover the bends." width="880">

<img src="docs/images/deep_yard.webp" alt="Deep Yard mid-wave. Three cyan lanes merge late, with towers on some islands and open ground on others." width="880">

On a two-lane yard the hint says to cover **both** rifts. On Deep Yard it says **all three**. A one-lane yard says to cover **the** rift.

Waves send critters on lane `a`, lane `b`, or `alt`. `a` is the first lane, `b` is the second (or the only lane), and `alt` cycles every lane. On Deep Yard, Cut takes every third alternating spawn. Bosses still walk the first lane.

## Guns and the loadout

<img src="docs/images/unlocks.webp" alt="Unlocks, with buy prices in scrap, and a five-slot loadout holding Pea, Glue, Stomper, Fizz, and Nova." width="880">

Every gun hits **Ground**, **Air**, or **Both**. Scrap Magnet does not shoot. Its label is **Yard**. Starters are already owned. The scrap column is the unlock price. Gold costs show on the Battle chips.

| | Gun | Hits | What it does | Scrap |
| --- | --- | --- | --- | --- |
| <img src="docs/images/guns/pea.png" width="48" alt="Pea Blaster"> | Pea Blaster | Both | Cheap and peppy. Hits ground and air. | Starter |
| <img src="docs/images/guns/glue.png" width="48" alt="Glue Goo"> | Glue Goo | Ground | Slows ground critters. Tier 3 also slows the ones nearby. | Starter |
| <img src="docs/images/guns/spark.png" width="48" alt="Spark Arc"> | Spark Arc | Both | Zaps a critter, then jumps to others it can reach. | 40 |
| <img src="docs/images/guns/flak.png" width="48" alt="Flak Puff"> | Flak Puff | Air | A cheap puff. Splash hits air only. | 45 |
| <img src="docs/images/guns/needle.png" width="48" alt="Sky Needle"> | Sky Needle | Air | A fast stitch. One flyer at a time. | 55 |
| <img src="docs/images/guns/boom.png" width="48" alt="Boom Barrel"> | Boom Barrel | Ground | Lobs a bomb. Splash hits the ground only. | 60 |
| <img src="docs/images/guns/stomper.png" width="48" alt="Stomper"> | Stomper | Ground | Slams the ground around itself. No shot. Ignores flyers. | 60 |
| <img src="docs/images/guns/net.png" width="48" alt="Net Lob"> | Net Lob | Air | Slows flyers. Tier 3 also slows nearby ground critters. | 65 |
| <img src="docs/images/guns/fizz.png" width="48" alt="Fizz Cloud"> | Fizz Cloud | Air | Lobs a cloud that lingers and ticks every flyer inside. | 75 |
| <img src="docs/images/guns/dual.png" width="48" alt="Dual Rail"> | Dual Rail | Both | Two little rails. Hits ground and air. | 70 |
| <img src="docs/images/guns/magnet.png" width="48" alt="Scrap Magnet"> | Scrap Magnet | Yard | No shooting. Pulls extra gold out of the yard. | 80 |
| <img src="docs/images/guns/orbit.png" width="48" alt="Orbit Drone"> | Orbit Drone | Both | Slow and heavy, with a little splash on either layer. | 90 |
| <img src="docs/images/guns/nova.png" width="48" alt="Nova"> | Nova | Both | A slow pulse. Hits every critter in range, ground and air. | 110 |

Boom and Flak are projectile splash. Stomper, Fizz Cloud, and Nova are not: a slam, a lingering cloud, and a heavy pulse. Each of those has three upgrade tiers.

The Battle bar has **5 slots**. Slots **1–3 are free**. Slot **4 costs 30 scrap** and slot **5 costs 50**. Slot 5 cannot be bought before slot 4. On Unlocks, click a gun you own, then a slot. Click a filled slot to clear it. The bar shows only the guns you equipped.

Click a tower to see its range. `U` upgrades it. `Backspace` sells it for 60% of the gold you spent, rounded down.

## Critters

They hop cell to cell. Flyers use the same road, drawn a little above the tiles. In the Bestiary, a critter stays a dark silhouette until you meet it in Battle.

<img src="docs/images/bestiary.webp" alt="The Bestiary, with Fast Skitter and the other critters revealed after a fight." width="880">

### Ground

| | Critter | Notes |
| --- | --- | --- |
| <img src="docs/images/critters/fast_skitter.png" width="48" alt="Fast Skitter"> | Fast Skitter | A tiny pink spider. Quick, and it stays on the tiles. |
| <img src="docs/images/critters/chunky_tank.png" width="48" alt="Chunky Tank"> | Chunky Tank | A heavy purple shell. Pops into three Tanklets. |
| <img src="docs/images/critters/tanklet.png" width="48" alt="Tanklet"> | Tanklet | What is left of a Chunky Tank. It does not split again. |
| <img src="docs/images/critters/shielded.png" width="48" alt="Shielded"> | Shielded | A mint creature in a bubble. The pop drops two Open Shells. |
| <img src="docs/images/critters/open_shell.png" width="48" alt="Open Shell"> | Open Shell | The creature after the bubble breaks. Done splitting. |
| <img src="docs/images/critters/swarm_splitter.png" width="48" alt="Swarm-Splitter"> | Swarm-Splitter | An orange blob. Pops into three Swarmlings. |
| <img src="docs/images/critters/swarmling.png" width="48" alt="Swarmling"> | Swarmling | A little piece of the swarm. Fast, and it does not split. |
| <img src="docs/images/critters/elite_tank.png" width="48" alt="Elite Tank"> | Elite Tank | A darker, heavier tank. Pops into two Chunky Tanks. |

Tanklet and Elite Tank use the Chunky Tank drawing. Open Shell uses the Shielded drawing.

### Flyers

| | Critter | Notes |
| --- | --- | --- |
| <img src="docs/images/critters/small_flyer.png" width="48" alt="Small Flyer"> | Small Flyer | A tiny moth above the lane. First shows up on wave 14. |
| <img src="docs/images/critters/flyer.png" width="48" alt="Flyer"> | Flyer | A medium flyer. It follows the lane, up in the air. |
| <img src="docs/images/critters/shielded_flyer.png" width="48" alt="Shielded Flyer"> | Shielded Flyer | A flyer in a bubble. Pops into two Small Flyers. |

### Bosses

| | Critter | When | Notes |
| --- | --- | --- | --- |
| <img src="docs/images/critters/big_cute_boss.png" width="48" alt="Big Cute Boss"> | Big Cute Boss | Waves 21, 40, 60, 80, and 100 | The ground boss. Slow crawl. Burps Swarmlings. Later visits have more health. |
| <img src="docs/images/critters/flying_boss.png" width="48" alt="Sky Nap"> | Sky Nap | Waves 50 and 90 | The flying boss. Sheds Small Flyers as it drifts. |

Popping a splitter is not always safer than letting it walk. Swarmlings are faster than the blob, and a Chunky Tank leaves three Tanklets behind. The chain stops at the smallest tier.

The first 21 waves are hand-built. After that, waves are generated: more critters, tighter gaps, flyers mixed in, and a health multiplier that keeps climbing.

## Map Editor

<img src="docs/images/editor.webp" alt="The map editor open on Yard Approach. The lanes are one solid cyan road, with islands and the tool bar." width="880">

**Map Editor** on the menu is a beta yard tool. Paint and erase a lane (it stays orthogonal and draws as the same cyan road as Battle), move that lane's spawn, set the Station Core, and place or remove a 2×2 hardpoint. Islands can be pink, teal, or crystal. The backdrop is **Night** (deep space) or **Dusk** (the older brighter field), with a Yard, Dock, or Deep tint. You can resize the grid, undo, redo, and clear. Up to four lanes.

**Playtest** runs a Battle on the draft with Pea and Glue, then **Editor** on the end screen comes back. Playtests and custom yards award **no scrap**. Built-in yards still do.

## Controls

| Key | Action |
| --- | --- |
| `1`–`5` | Pick that loadout slot |
| Click | Place the selected gun, or inspect a tower |
| `U` | Upgrade the selected tower |
| `Backspace` | Sell it for 60% of the gold spent |
| `Space` | Start wave 1, or Call the next wave |
| `F` | Toggle 1× / 2× |
| `P` or `Esc` | Pause or resume |
| `R` | Another Battle after a win or a loss |

## Building from source

The project is **Godot 4.7**. Open `project.godot` and press **F5**. The game starts on `scenes/main_menu.tscn`. Export presets are in `export_presets.cfg`.

```bash
godot --headless --path . --export-release "Linux" export/linux/ScrapyardTD.x86_64
godot --headless --path . --export-release "Windows Desktop" export/windows/ScrapyardTD.exe
```

Yards are JSON. The format, and what a later Adventure mode can reuse, is in [docs/MAP_FORMAT.md](docs/MAP_FORMAT.md). UI type is [Nunito](https://fonts.google.com/specimen/Nunito), SIL Open Font License (`assets/fonts/OFL-Nunito.txt`).
