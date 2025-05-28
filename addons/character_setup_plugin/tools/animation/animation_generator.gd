class_name AnimationGenerator extends RefCounted

var asset_manager: GameAssetManager
var sprite_analyzer: SpriteAnalyzer
var collision_box: CollisionBox
var hit_box: HitBox
var DetectionArea: DetectionArea

func _init(_asset_manager: GameAssetManager, _sprite_analyzer: SpriteAnalyzer):
    asset_manager = _asset_manager
    sprite_analyzer = _sprite_analyzer
    collision_box_generator = CollisionBox.new(_sprite_analyzer)
    hit_box_generator = HitBox.new(_sprite_analyzer)
    detection_area_generator = DetectionArea.new(_sprite_analyzer)

func generate_animation_player(character_name: String, sprite_path: String = "") -> Node2D:
var sprite_metadata = {}
    if sprite_path:
        sprite_metadata = asset_manager.get_asset(sprite_path)
        if sprite_metadata.is_empty() and asset_manager.gas_url:
            # Fetch from GAS
            var headers = ["Content-Type: application/json"]
            if asset_manager.gas_api_key:
                headers.append("x-api-key: " + asset_manager.gas_api_key)
            var error = asset_manager.http_client.request(asset_manager.gas_url + "/assets?type=sprite&name=" + sprite_path.get_file(), headers, HTTPClient.METHOD_GET, "")
            if error == OK:
                var response = await asset_manager.http_client.request_completed
                if response[1] == 200:
                    var json_data = JSON.parse(response[3].get_string_from_utf8())
                    if json_data and json_data.size() > 0:
                        sprite_path = json_data[0].file_path
                        sprite_metadata = json_data[0].metadata
    else:
        var search_results = asset_manager.search_assets({"name": character_name, "type": "sprite", "tags": ["character"]})
        if search_results.is_empty():
            print("Error: No sprite found for character: ", character_name)
            return null
        sprite_path = search_results[0].file_path
        sprite_metadata = search_results[0].metadata
    
    # Create root node
    var root = Node2D.new()
    root.name = character_name
    
    # Create sprite
    var sprite = Sprite2D.new()
    sprite.texture = ResourceLoader.load(sprite_path)
    sprite.name = "Sprite"
    root.add_child(sprite)
    
    # Add collision boxes
    if sprite_metadata.has("collision_box") and sprite_metadata.collision_box:
        var collision_box = collision_box_generator.generate_collision_box(sprite_path)
        if collision_box:
            collision_box.name = "CollisionBox"
            root.add_child(collision_box)
    
    if sprite_metadata.has("hit_box") and sprite_metadata.hit_box:
        var hit_box = hit_box_generator.generate_hit_box(sprite_path)
        if hit_box:
            hit_box.name = "HitBox"
            root.add_child(hit_box)
    
    if sprite_metadata.has("character_area") and sprite_metadata.character_area:
        var detection_area = detection_area_generator.generate_character_area(sprite_path)
        if detection_area:
            detection_area.name = "DetectionArea"
            root.add_child(detection_area)
    
    # Create AnimationPlayer
    var anim_player = AnimationPlayer.new()
    anim_player.name = "AnimationPlayer"
    root.add_child(anim_player)
    
    # Generate animations
    var rows = sprite_metadata.get("rows", 1)
    var columns = sprite_metadata.get("columns", 1)
    var frame_count = sprite_metadata.get("sprite_count", 1)
    
    if frame_count > 1:
        sprite.hframes = columns
        sprite.vframes = rows
        
        # Idle animation (first frame)
        var idle_anim = Animation.new()
        idle_anim.length = 0.1
        var track_idx = idle_anim.add_track(Animation.TYPE_VALUE)
        idle_anim.track_set_path(track_idx, "Sprite:frame")
        idle_anim.track_insert_key(track_idx, 0.0, 0)
        anim_player.add_animation("Idle", idle_anim)
        
        # Walk animation (all frames)
        if frame_count >= 4:  # Assume 4 frames for walk
            var walk_anim = Animation.new()
            walk_anim.length = 0.4  # 0.1s per frame
            track_idx = walk_anim.add_track(Animation.TYPE_VALUE)
            walk_anim.track_set_path(track_idx, "Sprite:frame")
            for i in range(4):
                walk_anim.track_insert_key(track_idx, i * 0.1, i % frame_count)
            walk_anim.loop = true
            anim_player.add_animation("Walk", walk_anim)
    
    return root

