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
        
    # Row 1 is y=96. Col 18 is x = 18 * 48 = 864. But notice there's a 6-pixel gap.
    # The actual character pixels start at y=117 according to check_gaps_v2.gd
    # So if we slice at y=96, the head starts at y=117 (21px padding).
    
    # In Godot, Row 0 is y=0, Row 1 is y=96, Row 2 is y=192, Row 4 is y=384.
    # Wait, earlier script check_gaps_v3 said:
    # y=24 to y=95 (directional)
    # y=117 to y=191 (Right-facing walking)
    # y=213 to y=287 (Right-facing running)
    # y=294 to y=344 (Front-facing squished dome)
    
    # Let's map everything based on the 96px slice strategy since it successfully prevented clipping.
    # The columns are 6 frames each (288px wide blocks per direction or action).
    
    # We found out that the character generator spits out horizontal grids!
    # A single row contains Right, Up, Left, Down for the SAME animation.
    # y=96  (Row 1): Idle
    # y=192 (Row 2): Walk
    # y=384 (Row 4): Sit/Phone
    
    # BUT wait, the image analysis of rows 0-8 of the first 6 columns showed:
    # y=96  (Row 1): Right-facing Walking
    # y=192 (Row 2): Right-facing Running
    # y=384 (Row 4): Right-facing Sitting/Crawling
    
    # The character generator exports an entirely different layout than the generic LimeZu sheet!
    # The first 6 columns (x=0 to x=287) are ALL right-facing actions.
    # The next 6 columns (x=288 to x=575) are ALL up-facing actions.
    # The next 6 columns (x=576 to x=863) are ALL left-facing actions.
    # The next 6 columns (x=864 to x=1151) are ALL down-facing actions.
    
    # Let's map the actions by row index (y / 96):
    # Row 0: Idle (y=0)
    # Row 1: Walk (y=96)
    # Row 2: Run (y=192)
    # Row 3: Squish (y=288)
    # Row 4: Sit/Scoot (y=384)
    # Row 9: Walk (y=864) -- wait, there are duplicate rows.
    
    # Let's just use Row 0 for Idle, Row 1 for Walk, Row 4 for Sit!
    
    var anim_map = {
        "idle_right":   {"row": 0, "cols": [0, 1, 2, 3, 4, 5]},
        "idle_up":      {"row": 0, "cols": [6, 7, 8, 9, 10, 11]},
        "idle_left":    {"row": 0, "cols": [12, 13, 14, 15, 16, 17]},
        "idle_down":    {"row": 0, "cols": [18, 19, 20, 21, 22, 23]},
        
        "walk_right":   {"row": 1, "cols": [0, 1, 2, 3, 4, 5]},
        "walk_up":      {"row": 1, "cols": [6, 7, 8, 9, 10, 11]},
        "walk_left":    {"row": 1, "cols": [12, 13, 14, 15, 16, 17]},
        "walk_down":    {"row": 1, "cols": [18, 19, 20, 21, 22, 23]},
        
        # Sit is row 4
        "sit_right":    {"row": 4, "cols": [0, 1, 2, 3, 4, 5]},
        "sit_up":       {"row": 4, "cols": [6, 7, 8, 9, 10, 11]}, 
        "sit_left":     {"row": 4, "cols": [12, 13, 14, 15, 16, 17]}, 
        "sit_down":     {"row": 4, "cols": [18, 19, 20, 21, 22, 23]}, 
        
        # Phone: The generator doesn't output "phone" explicitly in this block layout,
        # but let's fall back to sitting idle.
        "check_phone_right":  {"row": 4, "cols": [0, 1, 2, 3, 4, 5]},
        "check_phone_up":     {"row": 4, "cols": [6, 7, 8, 9, 10, 11]},
        "check_phone_left":   {"row": 4, "cols": [12, 13, 14, 15, 16, 17]},
        "check_phone_down":   {"row": 4, "cols": [18, 19, 20, 21, 22, 23]}
    }
    
    for anim_name in anim_map:
        frames.add_animation(anim_name)
        frames.set_animation_speed(anim_name, 6.0)
        # We need walking animations to loop!
        if "walk" in anim_name:
            frames.set_animation_loop(anim_name, true)
        else:
            frames.set_animation_loop(anim_name, true) # Default to loop anyway for idle/sit
            
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
