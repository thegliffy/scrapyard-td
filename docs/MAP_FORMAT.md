# Map format

Yards are JSON files. Battle, the map editor, and later Adventure all read the same `MapData`. The editor screen is a shell on top of that. Deleting `editor/` and `scenes/map_editor.tscn` does not change how a yard loads or how it is drawn.

## Files

| Path | Role |
| --- | --- |
| `res://maps/<id>.json` | Built-in yards. Shipped with the game. Read-only. |
| `user://maps/<id>.json` | Custom yards saved on this machine. |

Built-ins today: `yard_approach`, `side_dock`, `deep_yard`. Side Dock and Deep Yard use the same lanes and hardpoints as Yard Approach. Only the name, blurb, tint, and health / speed scales differ.

## JSON (version 1)

```json
{
  "version": 1,
  "id": "yard_approach",
  "name": "Yard Approach",
  "blurb": "The home yard. Two rifts, one core.",
  "builtin": true,
  "cols": 24,
  "rows": 11,
  "tile": 48,
  "origin": [64, 80],
  "backdrop": "space",
  "tint": "#ffffff",
  "tint_amount": 0.0,
  "hp_scale": 1.0,
  "speed_scale": 1.0,
  "core": [22, 5],
  "lanes": [
    {
      "id": "a",
      "name": "North",
      "cells": [[0, 1], [1, 1]]
    }
  ],
  "pods": [
    {
      "origin": [1, 2],
      "cells": [
        {"at": [1, 2], "style": "pink"},
        {"at": [2, 2], "style": "teal"},
        {"at": [1, 3], "style": "crystal"},
        {"at": [2, 3], "style": "pink"}
      ]
    }
  ]
}
```

- `cols` / `rows` are the grid. `tile` is pixels per cell. `origin` is the top-left of cell `(0, 0)` on the 1280×720 view. Built-in yards stay at 24×11, tile 48, origin `(64, 80)`.
- `lanes` is an ordered list. Each lane's `cells` are the full orthogonal walk from spawn (first cell) to the Station Core (last cell), including both ends. Lane ids for the editor are `a`, `b`, `c`, `d`.
- `core` is the Station Core cell. Every lane must end on it.
- `pods` are hardpoint groups. Each pod is a 2×2 whose `origin` is the top-left cell. `style` is `pink`, `teal`, or `crystal` (island art `island_a`, `island_b`, `island_c`).
- `backdrop` is an `Art` map id. The only one shipped is `space`.
- `tint` and `tint_amount` lerp the backdrop. `hp_scale` and `speed_scale` multiply enemy health and speed for that yard.
- `builtin` is forced `true` when a file is loaded from `res://maps`, and forced `false` for `user://maps`.

## Rules

`MapValidator` is the gate for Save and Playtest:

- The core is inside the grid.
- There is at least one lane, and none of them are empty.
- Every step is one cell orthogonal, and every cell is inside the grid.
- Every lane ends on the core.
- There is at least one hardpoint pod, each pod is a full 2×2, styles are known, slots are unique, and no slot sits on a path cell (the core is part of the path).

## What Battle does with a map

`MapLibrary.load_builtin` / `load_custom` parse JSON into `MapData`. `Board.apply` copies that into the runtime cache the rest of the fight already uses: `lane_a`, `lane_b`, `SLOTS`, `path_info`, `CORE`, and cell size. Enemy hops, towers, and the wave director did not grow their own map format.

Waves still name lanes `a`, `b`, or `alt`. `a` and `b` are the first two lanes (a one-lane yard uses that lane for both). `alt` cycles every lane on the map, so a third and fourth lane do get spawns. On the two-lane built-in yards this is the same north / south flip as before.

`MapView` draws the backdrop, one continuous neon line per lane (rounded corners, pink and cyan), islands, the core island, and rifts. Battle's `scripts/map.gd` is that view plus in-run stains. A segment a later lane shares with an earlier one is drawn once, so a merge is not a double-bright overlap.

## Scrap

Built-in yards still pay scrap (a win is 2 per wave cleared, a loss is 1).

A **playtest** from the editor, and a **custom yard** started from the Battle picker, pay **no scrap**. The profile file is not rewritten for that reward. A playtest also forces the starter loadout (Pea, Glue) in memory only. It does not save over the loadout.

## Modules Adventure should keep

These do not depend on the editor scene:

| Module | Reuse |
| --- | --- |
| `map_tools/map_data.gd` | The model. `from_json` / `to_json`. |
| `map_tools/map_validator.gd` | Can this yard be played? |
| `map_tools/path_builder.gd` | Orthogonal walks: extend, prepend a spawn, erase a tail. |
| `map_tools/map_brush.gd` | Paint, pods, core, resize. Same checks the editor uses. |
| `map_tools/map_library.gd` | Built-in and `user://` load, save, delete. |
| `map_tools/map_view.gd` | Draw a map `Board.apply` has loaded. |
| `map_tools/map_session.gd` | Hand a `MapData` to Battle and know whether scrap is blocked. |
| `scripts/board.gd` | Runtime grid cache filled from `MapData`. |

Safe to delete later, without touching Battle or the model:

- `editor/map_editor.gd`
- `scenes/map_editor.tscn`
- The Map Editor button on the main menu

The Battle screen's custom-yard picker is optional. It only lists `user://maps` and starts them through `MapSession`. Adventure can ignore it and load `MapData` itself.
