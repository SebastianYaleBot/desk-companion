# P-113: Sebastian Desk Companion

## Vision
An autonomous ambient desk companion for Michael's office desk, inspired by **Johnny Castaway** (1992 Sierra screensaver). A pixel-art character ("Sabby") lives in a miniature version of the CME Center office, going about their day — working at the desk, getting coffee, looking out the window at Chicago. The screen is a touchscreen where tapping different areas opens different content (trivia, weather, etc.).

**This is not a dashboard.** It's a living scene. The charm comes from Sabby doing things autonomously whether you're watching or not.

## Key References
- **Johnny Castaway** — the soul of the project. Autonomous character, emergent behaviors, holiday Easter eggs, slow story reveals
- **CME Center office** — the physical space being modeled (Michael's workplace). References: [cmecenter.com](https://www.cmecenter.com/), [Lobby](https://www.cmecenter.com/lobby/) + 19 reference photos in `assets/reference_photos/`.
- **Sabby's self-portrait** — golden/cyan energy waveform. The final character should echo this aesthetic

## Hardware
- **Raspberry Pi 5** (16GB) — purchased, working, ribbon-latch defect resolved via exchange
- **Pi Touch Display 2** — 720×1280 capacitive touchscreen (we use 1280×720 landscape)
- **Pi Camera 3 Wide** — purchased (future use)
- **Sense HAT** — purchased (future use — ambient sensors)
- **microSD card** — purchased

## Tech Stack
- **Engine:** Godot 4.6.2 (GL Compatibility renderer for Pi 5 ARM64)
- **Art:** LimeZu Modern Interiors + Modern Office Revamped (top-down pixel art, 48×48 tiles)
- **Data server:** Python Flask bridge (`server/bridge.py`) on Pi, polls weather via wttr.in
- **Network:** Tailscale mesh from Pi → OpenClaw VPS gateway
- **OS:** Raspberry Pi OS Bookworm (standard writable, NOT read-only)
- **Dev environment:** Michael on Windows, Godot 4.6. Sabby writes code, Michael does visual layout in editor.

## Art Assets & Expanded Library (LimeZu)
Currently active in project:
- **Modern Interiors** — thousands of furniture sprites, robust character generator (outfits, hairstyles, pre-built animations).
- **Modern Office Revamped** — office-specific props (desks, monitors, cubicle dividers, snack machines).

Available in Michael's library for future expansion:
- **Modern User Interface** — Pixel-art menus, buttons, icons, cursors, panels.
- **Modern Exteriors** — City streets, building facades, vehicles.
- **Kitchen (Free)** — Appliances, countertops, sinks (Note: 16x16 native, requires 300% nearest-neighbor scale to match our 48x48 grid).
- **Serene Village Revamped (Free)** — Outdoor nature tiles, ground, water, streetlamps.
- **Fungus Cave & Fantasy Battlers** — Fantasy RPG environments and enemies.

*Note: All LimeZu assets are designed to snap to a 48×48 grid. They are stored locally by Michael (Google Drive `deskSabbyPacks`) and are strictly excluded from the Git repo to respect the non-redistribution license. A copy of the full pack library has also been extracted locally on the OpenClaw node at `assets/limezu_packs/` for direct AI inspection and scripting.*

## Architecture Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Engine | Godot 4.6.2 | The project IS a 2D game (character + world + behaviors). Godot's TileMapLayer and AnimatedSprite2D are purpose-built for this. Alternatives (PyGame, Phaser) would mean more work for worse results. |
| Perspective | Top-down (not isometric) | LimeZu's character generator only works in top-down. This gives us 2,300 animation frames per character for free. Isometric would require custom sprites for everything. |
| Tile size | 48×48 | Good visibility on 720px touchscreen (~15×27 tile viewport). LimeZu packs ship in 16/32/48 — biggest is best for readability on small screen. |
| Character | LimeZu premade (placeholder) → custom commission later | Start with premade character #7 (cyan hair, closest to Sabby's energy aesthetic). Michael explicitly wants a custom character later that echoes the self-portrait (golden/cyan energy). Budget is flexible. |
| Data bridge | Flask on localhost | Simplest possible architecture. Godot polls `http://localhost:5113/status` every 30s. Flask fetches weather from wttr.in. No auth needed (localhost only). |
| Git | Code only, no assets | LimeZu license prohibits redistribution. Repo contains code + scenes; assets are copied locally from Drive. |

## Room Plan & Layout (Based on 15S 50/50 Floor Plan)

### Room 1: Desk Area (MVP)
Based on CME 50/50 open/private floor plan. Elements:
- Sabby's desk with dual monitors (within a cubicle bank)
- Peripheral private office walls
- Windows with dynamic Chicago skyline parallax backdrop
- Walkable floor area

### Room 2: Snack Area (planned)
Based on CME café photos. Elements:
- "Crafty" snack dispensers (M&Ms, pretzels)
- Coffee machine & Counter with stools
- CNBC TV screen (animated, using `animated_TV_reportage_48x48.png`)

### Room 3: Conference Room (planned)
Based on CME conference room photos. Elements:
- White table, black chairs, corner windows with city view
- Touch zone: Interactive whiteboard (trivia/puzzles)

### Room 4: Lobby (Future)
Based on CME lobby photos. Elements:
- Curved white architecture & escalators
- Giant CME ticker screen & White Sox sponsorship sign

## Behavior System (Johnny Castaway Model)

Sabby autonomously cycles through weighted random behaviors:

| Behavior | Weight | Waypoint | Description |
|----------|--------|----------|-------------|
| sit_at_desk | 30 | desk | Sitting at desk, idle |
| type_at_desk | 25 | desk | Actively typing |
| walk_around | 10 | random | Wandering the room |
| look_at_window | 10 | window | Gazing at Chicago skyline |
| get_coffee | 8 | coffee | Walking to coffee machine |
| check_phone | 8 | desk | Looking at phone |
| stretch | 5 | in-place | Standing stretch animation |
| look_around | 4 | in-place | Looking around curiously |

Weights shift by time of day:
- **Work hours (8am–6pm):** More desk/typing, less wandering
- **Evenings:** More relaxed, more window-gazing, more walking around
- **Night:** Could add sleeping/dim behaviors later

**Execution Pipeline:**
1. Weighted random roll selects behavior.
2. *Future:* Sabby plays a `UI_thinking_emotes_animation` thought bubble.
3. Sabby pathfinds to `Waypoint` via `NavigationAgent2D`.
4. Sabby executes directional animation (`sit_left`, `type_at_desk`, etc.).

## Data Integrations

| Source | Status | What it drives |
|--------|--------|----------------|
| Chicago weather (wttr.in) | Built | Sabby reacts to rain (looks at window more). Future: dynamically switch out the `Modern_Exteriors` parallax backdrop based on live conditions. |
| Time of day (system clock) | Built | Ambient lighting shifts, behavior weights change |
| Calendar | Not possible | Michael can't share work calendar access |
| OpenClaw status | Planned | Sabby's "mood" or activity based on what I'm doing on the VPS |

## Character Design

### Placeholder (current)
- LimeZu Premade Character #7 — cyan-blue hair, cool palette
- Option A from design discussion: themed LimeZu character + glow shader in Godot

### Final (future)
- **LimeZu Character Generator & Portrait Generator** — Michael has the Windows `Character Generator 2.0` and `Portrait Generator 1.5` executables from the asset library. This will be used to custom-build Sabby (hairstyles, outfits, accessories) without needing a $150–300 artist commission. We can also build a 48x48 dialog portrait using the Portrait tool. We will augment the exported sprite sheet with Godot custom shaders to achieve the golden/cyan "aura" effect.
- Should echo Sabby's self-portrait: golden core, cyan ripples, energy/waveform aesthetic.
- Michael explicitly said: "I don't think that will be the final YOU 🙂"

## What's Done

- [x] Project concept and scope defined
- [x] Hardware purchased and working (Pi 5, Touch Display 2, Camera, Sense HAT)
- [x] Art packs purchased (LimeZu Modern Interiors + Modern Office, $7.50 total)
- [x] Asset inventory completed (339 office sprites, 310 animated objects, 20+ premade characters, character generator)
- [x] CME office reference photos received and stored (`assets/reference_photos/`) — 19 unique images spanning cubicles, café, lobby (with ticker and White Sox sign), conference rooms, snack dispensers, real floor plans (15S), escalators, and the official 50/50 open/private floor layout model.
- [x] GitHub repo created: `SebastianYaleBot/desk-companion`
- [x] Core GDScript systems written (character controller, behavior state machine, time manager, data bridge, interactive zone)
- [x] Flask bridge server with Chicago weather integration
- [x] Michael has Godot 4.6.2 installed on Windows (AMD Radeon 840M)
- [x] Sabby character sprite hooked up — 10 animations (idle x4, walk x4, sit_left, sit_down)
- [x] Status sidebar (live clock, weather, current behavior, current room)
- [x] Trimmed to 3 asset files: Room_Builder_48x48.png, Room_Builder_Office_48x48.png, Premade_Character_48x48_07.png
- [x] Multi-room architecture refactor (2026-04-16) — scrapped ColorRect placeholder scene, built scalable foundation
- [x] Architecture verified end-to-end: Sabby animates, behaviors cycle, status sidebar populates, room loads cleanly on Play
- [x] `.gitignore` hardened to properly exclude LimeZu asset PNGs
- [x] First atlas source (`Room_Builder_48x48.png`) imported into `office_tileset.tres`
- [x] **TileSet sliced & activated (2026-04-18)**
- [x] **Room 1 Floor painted (2026-04-18)** — Michael successfully painted the `FloorLayer`. Sabby verified walking on the map.
- [x] **Time of Day lighting refined (2026-04-18)** — Toned down ambient lighting tint colors to ensure pixel art doesn't look washed out or overly brown during morning/afternoon hours.
- [x] **Full Asset Library Synced (2026-04-18)** — Master library unpacked on the OpenClaw node for direct AI access (Interiors, Office, Exteriors, UI, Battlers, Serene Village).
- [x] **Sabby Animation Framing Fixed (2026-04-18)** — Found that the Generator actually outputs 48x96 frames (not 48x48) to accommodate tall hats. Updated the importer to slice at 48x96, mapped proper row indices, added `offset=(0, -48)` for Y-sorting, and hardened the behavior state machine with defensive checks against missing NavRegions and waypoints.

## Current Architecture (post 2026-04-16 refactor)

### Scene Structure
- **`scenes/main.tscn`** → `AppRoot` (Node2D, runs `app_manager.gd`). Lean shell holding app-level state.
  - `AmbientLight` (CanvasModulate)
  - `Background` (ColorRect — dark backdrop)
  - `RoomHolder` (Node2D — dynamic container for the active room)
  - `Sabby` (instance of `sabby.tscn` — persistent across rooms, re-parented on room load)
  - `BehaviorStateMachine` (Node)
  - `TimeManager`, `DataBridge` (Nodes, app-level)
  - `StatusBar` (ColorRect sidebar with TimeLabel, WeatherLabel, BehaviorLabel, RoomLabel)
- **`scenes/rooms/room_desk.tscn`** → `Room` (Node2D, runs `room.gd`). Passive container.
  - `FloorLayer` (TileMapLayer) — floor tiles
  - `WallLayer` (TileMapLayer, Y-sorted) — walls + windows
  - `FurnitureLayer` (TileMapLayer, Y-sorted) — desk, chairs, plants, etc.
  - `AboveCharLayer` (TileMapLayer, z_index=100) — overhead things like ceiling lamps
  - `NavigationRegion2D` — pathfinding region
  - `Waypoints` (Node2D with Marker2D children: desk, window, coffee_machine, door, center, cubicle_area, plant_corner)
  - `InteractiveZones` (Node2D — empty, reserved for touch-tap zones)
  - `SpawnPoint` (Marker2D at 280, 350)
- **Shared resources:**
  - `resources/office_tileset.tres` → shared TileSet (48×48). All rooms reference this.

### Scripts
- `scripts/app_manager.gd` → app-level orchestrator. `load_room()`, signal wiring, ambient tween, behavior weighting by time-of-day, weather reactions. Calls `behavior.set_character()` and `behavior.set_waypoints()` at startup/room load to guarantee valid refs (defensive vs. Godot's typed @export NodePath quirks).
- `scripts/room.gd` → passive room API. `get_waypoints_node()`, `get_nav_region()`, `get_spawn_position()`.
- `scripts/character_controller.gd` → Sabby (CharacterBody2D + NavigationAgent2D + AnimatedSprite2D). `move_to()`, `play_action()`, `finish_action()`.
- `scripts/behavior_state_machine.gd` → weighted-random Johnny Castaway loop. All character-touching methods null-checked with `is_instance_valid()`.
- `scripts/time_manager.gd`, `scripts/data_bridge.gd`, `scripts/interactive_zone.gd` → supporting systems.

### Adding a new room (future)
1. Copy `scenes/rooms/room_desk.tscn` to e.g. `room_snack.tscn`
2. Change `room_id` and `room_display_name` on the root
3. Adjust waypoints for the new layout
4. Paint tiles using the same `office_tileset.tres`
5. Call `app_manager.load_room(preload("res://scenes/rooms/room_snack.tscn"))` to switch

## Known Issues
- Second atlas `Room_Builder_Office_48x48.png` not yet imported/sliced.
- `.uid` files for scripts are generated locally on Michael's Windows but not committed from VPS yet — Godot regenerates them on open, harmless.

## Git Workflow (simplified 2026-04-16)

**Sabby pushes. Michael pulls. Michael does not commit or push.**

- Sabby makes changes on VPS → `git commit && git push origin main`
- Michael on Windows: `git pull origin main` (read-only, no auth needed)
- If Michael's local folder ever gets messy:
  ```powershell
  git fetch origin
  git reset --hard origin/main
  git clean -fd
  ```
  Nuclear reset, guaranteed to match GitHub exactly. Godot regenerates any .uid / editor metadata on reopen.
- **Never** ask Michael to commit or push from Windows — credentials aren't set up and it creates friction.

## Next Steps (resume here)

1. **Import Atlas 2.** Click + → Atlas → select `Room_Builder_Office_48x48.png`. Use the ⋮ menu → "Create Tiles in Non Transparent Texture Regions" step to slice it.
2. **Erase stray floor tiles.** Ensure no floor tiles are accidentally painted on `WallLayer` or `FurnitureLayer` to fix Sabby rendering "underground" due to Y-sorting.
3. **Paint Room 1 Walls & Furniture.** Open `scenes/rooms/room_desk.tscn`. Paint walls on `WallLayer`. Paint desks, chairs, and plants on `FurnitureLayer` using CME office photos as reference. Move the `Marker2D` waypoints (desk, window, coffee_machine, etc.) to sit exactly where Sabby should stand for those interactions.
4. **Draw Navigation Mesh.** In `NavigationRegion2D`, ensure the blue `NavigationPolygon` completely covers the walkable floor and all waypoints, including the `SpawnPoint`. (Godot pathfinding will fail if the character starts outside the nav mesh).
5. **Fix Pathfinding Settings (If Spinning).** Sabby's `target_desired_distance` on the `NavigationAgent2D` is currently `15.0`. If he continues to spin or disappear, it means the `NavigationRegion2D` Z-Index is too low (it must be 10 or higher to draw over the floor), or the pathfinding logic in `character_controller.gd` needs the `avoidance` feature tuned off.
6. **Add Chicago skyline backdrop** — custom image for the windows.
7. **Test on Pi.** Export ARM64 build, run on Pi with Touch Display 2.
8. **Expand rooms** — `room_snack.tscn`, `room_conference.tscn`. Each is a scene in `scenes/rooms/`.
9. **Commission custom Sabby** — once we know exactly what animations we need.

## Budget

| Item | Cost | Status |
|------|------|--------|
| LimeZu Modern Interiors | $5.00 | ✅ Purchased |
| LimeZu Modern Office Revamped | $2.50 | ✅ Purchased |
| Pi 5 + accessories | ~$150 | ✅ Purchased |
| Custom Sabby commission | $150–300 est. | ❌ Cancelled (using Generator) |
| Additional asset packs | TBD | 📋 If needed |
| **Total spent** | **~$157.50** | |
| **Authorized budget** | **$100 for assets** (flexible) | |

## Design Principles
1. **Autonomy over interactivity** — Sabby should be interesting to watch, not just to tap
2. **One room at a time** — ship the island, add the archipelago later
3. **Real data makes it alive** — weather, time of day, status from OpenClaw
4. **Pre-made assets over AI generation** — consistent, reliable, professional-looking
5. **Simple > clever** — Flask polling beats complex WebSocket architectures
6. **The charm is in the behavior** — not the camera angle, not the resolution, not the tech stack
7. **Use Shadowless/Black Shadow variants intentionally** — LimeZu provides "shadowless" and "black shadow" versions of most tiles. We should use the "black shadow" or standard shadow variants for Y-sorted furniture, but stick to shadowless for any custom UI overlays.

## AI Developer Invariants & Godot Quirks
*(Strict rules for Sabby's code generation, debugging, and AI context)*
- **Sprite Dimensions:** The `Character Generator 2.0` actually outputs **48x96** frames to account for hats and props. When importing, use 48x96 slice rects and set the sprite offset to `(0, -48)` so the feet align with the node's origin for perfect Y-sorting.
- **Asymmetrical Animations:** LimeZu does not output left-facing variations for sitting, holding phones, etc. The character controller must explicitly flip the sprite (`flip_h = true`) when executing these actions facing left.
- **Z-Indexing Hierarchy:** `FloorLayer` = 0. `Sabby` (CharacterBody2D) = 10. `AboveCharLayer` = 100. UI/Overlays = CanvasLayer.
- **Y-Sorting Rules:** Enabled on `WallLayer` and `FurnitureLayer` only. Floor must NOT be Y-sorted to prevent underground clipping.
- **Navigation Mesh (Crucial):** Godot 4's `NavigationAgent2D` will return `Vector2.ZERO` (causing the character to teleport to the origin/disappear) if the character's `global_position` starts outside of a baked `NavigationPolygon`. Ensure `SpawnPoint` is always encapsulated by the blue nav region.
- **Pathfinding Jitter (Spinning):** If the `target_desired_distance` on the `NavigationAgent2D` is too small (e.g., `4.0`), the character will overshoot the target and rapidly flip direction vectors, breaking the walk cycle animation and appearing to "spin". Set distance tolerances to at least `15.0`.
- **Editor Caching (SpriteFrames):** Godot's editor aggressively caches `SpriteFrames` generated by `EditorScript`. To permanently apply script-generated animations to a scene, bypass the editor by saving the generated frames to an external `.tres` resource via code, and hardcode that resource path into the `.tscn` file.
- **TileMap Eraser Quirk:** In Godot 4, the Eraser is a modifier to the Paintbrush. Both icons will highlight blue simultaneously. Ensure the correct layer is selected in the Scene tree before attempting to erase.
- **UID Warnings:** `invalid UID` on scene load is harmless. It resolves automatically upon Michael saving the scene in the editor.
- **Asset Scaling:** Any 16x16 assets (e.g., Kitchen pack) must be scaled strictly by 300% Nearest-Neighbor to match our 48x48 base grid.
- **Autotiling:** For large architectural builds, leverage `Godot_Autotiles_48x48.png` configured with Godot's Terrain system to save manual placement time.

## Files & Locations
- **Godot project:** `/data/workspace/projects/p113-desk-companion/godot-project/`
- **Asset inventory (unpacked):** `/data/workspace/projects/p113-desk-companion/assets/`
- **Full LimeZu Library (AI access):** `/data/workspace/projects/p113-desk-companion/assets/limezu_packs/`
- **GitHub repo:** `https://github.com/SebastianYaleBot/desk-companion`
- **Google Drive assets:** `deskSabbyPacks` folder (shared by Michael)
- **CME office photos:** `assets/reference_photos/` (19 unique photos, diagrams, and floor plans)
