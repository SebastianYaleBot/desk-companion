# 🖥️ P-113: Sebastian Desk Companion

An autonomous ambient desk companion for Raspberry Pi 5, inspired by [Johnny Castaway](https://en.wikipedia.org/wiki/Johnny_Castaway).

A pixel-art character ("Sabby") lives in a miniature CME office, autonomously going about their day — working at the desk, getting coffee, looking out the window at Chicago. Touch the screen to interact with different zones.

## Tech Stack

- **Display:** Godot 4.4 (GL Compatibility renderer)
- **Hardware:** Raspberry Pi 5 + Touch Display 2
- **Data:** Python Flask bridge polling weather/status
- **Network:** Tailscale mesh to OpenClaw gateway
- **Art:** LimeZu Modern Interiors + Modern Office asset packs (48x48)

## Project Structure

```
godot-project/
├── project.godot          # Godot project config (1280x720, GL Compat)
├── scenes/
│   ├── main.tscn          # Room scene (floor, walls, furniture, Sabby, waypoints)
│   └── sabby.tscn         # Character scene (sprite, collision, nav agent)
├── scripts/
│   ├── character_controller.gd   # Movement, animation, actions
│   ├── behavior_state_machine.gd # Autonomous Johnny Castaway-style behaviors
│   ├── time_manager.gd           # Real clock time-of-day awareness
│   ├── data_bridge.gd            # Polls Flask server for weather/status
│   ├── interactive_zone.gd       # Touchable areas in the room
│   └── room_manager.gd           # Orchestration (ties everything together)
├── server/
│   ├── bridge.py          # Flask data server (weather, time, status)
│   └── requirements.txt
├── assets/                # YOUR purchased assets go here (not in git)
│   ├── tiles/             # Room_Builder_48x48.png, Interiors_48x48.png, etc.
│   ├── characters/        # Premade characters or generator output
│   └── animated/          # Animated object spritesheets
└── .gitignore
```

## Setup (First Time)

### 1. Clone and open in Godot

```bash
git clone https://github.com/SebastianYaleBot/desk-companion.git
```

Open Godot 4.4 → Import → navigate to the `godot-project/` folder → Import & Edit.

### 2. Add your assets

Copy from your purchased LimeZu packs into the `assets/` folder:

```
assets/tiles/Room_Builder_48x48.png          ← from Modern Interiors
assets/tiles/Room_Builder_Office_48x48.png   ← from Modern Office Revamped
assets/tiles/Interiors_48x48.png             ← from Modern Interiors
assets/characters/Premade_Character_48x48_07.png  ← placeholder Sabby (cyan hair)
assets/animated/                              ← animated object spritesheets
```

### 3. Set up TileSet (in Godot Editor)

1. Select the `Floor` TileMapLayer in the scene tree
2. In Inspector, create a new TileSet
3. Add the Room Builder PNGs as tile sources
4. Paint the room!

### 4. Set up Sabby's animations

1. Open `scenes/sabby.tscn`
2. Select AnimatedSprite2D → SpriteFrames
3. Load the premade character spritesheet
4. Define frame regions for each animation (idle_down, walk_down, etc.)

## Behavior System

Sabby autonomously cycles through behaviors with weighted randomness:

| Behavior | Weight | Waypoint |
|----------|--------|----------|
| sit_at_desk | 30 | desk |
| type_at_desk | 25 | desk |
| walk_around | 10 | random |
| look_at_window | 10 | window |
| get_coffee | 8 | coffee_machine |
| check_phone | 8 | desk |
| stretch | 5 | in-place |
| look_around | 4 | in-place |

Weights shift based on time of day (more desk work during work hours, more relaxed in evenings).

## Data Bridge

Run the Flask server alongside Godot:

```bash
cd server/
pip install -r requirements.txt
python bridge.py
```

Godot polls `http://localhost:5113/status` every 30 seconds for weather, time, and status data.

## Roadmap

- [x] Project structure and core systems
- [ ] First room: desk area (based on CME photos)
- [ ] Sabby character with walk/idle animations
- [ ] Autonomous behavior loop running
- [ ] Weather integration (Chicago live weather)
- [ ] Interactive touch zones
- [ ] Additional rooms: snack area, conference room
- [ ] Time-of-day ambient lighting
- [ ] Holiday Easter eggs
- [ ] Custom Sabby sprite (energy/glow aesthetic)
- [ ] Raspberry Pi deployment

## License

Code: MIT. Art assets are separately licensed from LimeZu (not redistributed in this repo).
