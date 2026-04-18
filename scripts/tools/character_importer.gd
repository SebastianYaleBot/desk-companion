@tool
extends EditorScript

## V3 Automated Importer for LimeZu Character Sheets.
## We discovered the sheet is actually laid out horizontally with 48x96 cells!

const TEX_PATH = "res://assets/characters/Premade_Character_48x48_07.png"
const CELL_W = 48
const CELL_H = 96

func _run() -> void:
    print("[CharacterImporter] Running V3...")
    
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
    if frames.has_animation("default"):
        frames.remove_animation("default")
        
    # Row indices are based on 96px height blocks.
    # Row 1 (y=96): Idle (Right, Up, Left, Down - 6 frames each)
    # Row 2 (y=192): Walk (Right, Up, Left, Down - 6 frames each)
    # Row 4 (y=384): Sit Right (0-5), Phone Right (6-11)
    
    var anim_map = {
        "idle_right":   {"row": 1, "cols": [0, 1, 2, 3, 4, 5]},
        "idle_up":      {"row": 1, "cols": [6, 7, 8, 9, 10, 11]},
        "idle_left":    {"row": 1, "cols": [12, 13, 14, 15, 16, 17]},
        "idle_down":    {"row": 1, "cols": [18, 19, 20, 21, 22, 23]},
        
        "walk_right":   {"row": 2, "cols": [0, 1, 2, 3, 4, 5]},
        "walk_up":      {"row": 2, "cols": [6, 7, 8, 9, 10, 11]},
        "walk_left":    {"row": 2, "cols": [12, 13, 14, 15, 16, 17]},
        "walk_down":    {"row": 2, "cols": [18, 19, 20, 21, 22, 23]},
        
        # Sitting only has Right-facing sprites in this pack by default.
        # We will map sit_left to use the same frames, but we'll flip the sprite in code.
        "sit_right":    {"row": 4, "cols": [0, 1, 2, 3, 4, 5]},
        "sit_left":     {"row": 4, "cols": [0, 1, 2, 3, 4, 5]}, # Flip handled in controller
        "sit_up":       {"row": 1, "cols": [6, 7, 8, 9, 10, 11]}, # Fallback to idle
        "sit_down":     {"row": 1, "cols": [18, 19, 20, 21, 22, 23]}, # Fallback to idle
        
        "check_phone_right":  {"row": 4, "cols": [6, 7, 8, 9, 10, 11]},
        "check_phone_left":   {"row": 4, "cols": [6, 7, 8, 9, 10, 11]} # Flip handled in controller
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
            atlas.region = Rect2(col_idx * CELL_W, row_idx * CELL_H, CELL_W, CELL_H)
            frames.add_frame(anim_name, atlas)
            
    sprite.sprite_frames = frames
    
    # Adjust offset so the feet align with the node's origin (for perfect Y-sorting)
    # The rect is 96px tall, centered by default. The feet are at the bottom (+48).
    # Shifting by -48 puts the feet exactly at 0.
    sprite.offset = Vector2(0, -48)
    
    print("[CharacterImporter] Successfully generated ", anim_map.size(), " animations for Sabby using 48x96 rects!")
