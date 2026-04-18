@tool
extends EditorScript

## Automated Importer for LimeZu 48x48 Character Sheets.
## To use:
## 1. Open scenes/sabby.tscn in the editor.
## 2. Select this script in the FileSystem dock.
## 3. Go to File -> Run (or right click -> Run) to reconstruct SpriteFrames.

const TEX_PATH = "res://assets/characters/Premade_Character_48x48_07.png"
const CELL_SIZE = 48

func _run() -> void:
    print("[CharacterImporter] Running...")
    
    var root = get_scene()
    if not root or not root.has_node("AnimatedSprite2D"):
        print("[CharacterImporter] Error: Open scenes/sabby.tscn in the editor first!")
        return
        
    var sprite: AnimatedSprite2D = root.get_node("AnimatedSprite2D")
    var tex: Texture2D = load(TEX_PATH)
    if not tex:
        print("[CharacterImporter] Error: Could not load texture at ", TEX_PATH)
        return
        
    var frames = SpriteFrames.new()
    frames.remove_animation("default")
    
    # LimeZu 48x48 "Modern Interiors" Character Format Mapping:
    # Row 0: empty/headers
    # Row 1: Idle Right (6 frames)
    # Row 2: Idle Up (6 frames)
    # Row 3: Idle Left (6 frames)
    # Row 4: Idle Down (6 frames)
    # Row 5: Walk Right (6 frames)
    # Row 6: Walk Up (6 frames)
    # Row 7: Walk Left (6 frames)
    # Row 8: Walk Down (6 frames)
    # Row 9: Sit Right (4 frames)
    # Row 10: Sit Up (4 frames)
    # Row 11: Sit Left (4 frames)
    # Row 12: Sit Down (4 frames)
    
    var anim_map = {
        "idle_right":   {"row": 1, "cols": [0, 1, 2, 3, 4, 5]},
        "idle_up":      {"row": 2, "cols": [0, 1, 2, 3, 4, 5]},
        "idle_left":    {"row": 3, "cols": [0, 1, 2, 3, 4, 5]},
        "idle_down":    {"row": 4, "cols": [0, 1, 2, 3, 4, 5]},
        "walk_right":   {"row": 5, "cols": [0, 1, 2, 3, 4, 5]},
        "walk_up":      {"row": 6, "cols": [0, 1, 2, 3, 4, 5]},
        "walk_left":    {"row": 7, "cols": [0, 1, 2, 3, 4, 5]},
        "walk_down":    {"row": 8, "cols": [0, 1, 2, 3, 4, 5]},
        "sit_right":    {"row": 9, "cols": [0, 1, 2, 3]},
        "sit_up":       {"row": 10, "cols": [0, 1, 2, 3]},
        "sit_left":     {"row": 11, "cols": [0, 1, 2, 3]},
        "sit_down":     {"row": 12, "cols": [0, 1, 2, 3]}
    }
    
    for anim_name in anim_map:
        frames.add_animation(anim_name)
        frames.set_animation_speed(anim_name, 6.0)
        frames.set_animation_loop(anim_name, true)
        
        var data = anim_map[anim_name]
        var row_idx = data["row"]
        for col_idx in data["cols"]:
            var atlas = AtlasTexture.new()
            atlas.atlas = tex
            atlas.region = Rect2(col_idx * CELL_SIZE, row_idx * CELL_SIZE, CELL_SIZE, CELL_SIZE)
            frames.add_frame(anim_name, atlas)
            
    sprite.sprite_frames = frames
    print("[CharacterImporter] Successfully generated ", anim_map.size(), " animations for Sabby!")
