class_name AnimationGenerator extends RefCounted

var asset_manager: GameAssetManager
var sprite_analyzer: SpriteAnalyzer
var collision_box_generator: CollisionBox
var hit_box_generator: HitBox
var detection_area_generator: DetectionArea

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
            var headers = ["Content-Type: application/json"]
            if asset_manager.gas_api_key:
                headers.append("x-api-key: " + asset_manager.gas_api_key)
            var error = asset_manager.http_client.request(asset_manager.gas_url + "/assets?type=sprite&name=" + sprite_path.get_file(), headers, HTTPClient.METHOD_GET, "")
            if error == OK:
                var response = await asset_manager.http_client.request_completed
                if response[1] == 200:
                    var json_data = JSON.parse_string(response[3].get_string_from_utf8())
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
    
    if sprite_path.is_empty():
        return null
    
    var root = Node2D.new()
    root.name = character_name
    
    var sprite = Sprite2D.new()
    sprite.texture = ResourceLoader.load(sprite_path)
    sprite.name = "Sprite"
    root.add_child(sprite)
    
    if sprite_metadata.get("collision_box"):
        var collision_box = collision_box_generator.generate_collision_box(sprite_path)
        if collision_box:
            collision_box.name = "CollisionBox"
            root.add_child(collision_box)
    
    if sprite_metadata.get("hit_box"):
        var hit_box = hit_box_generator.generate_hit_box(sprite_path)
        if hit_box:
            hit_box.name = "HitBox"
            root.add_child(hit_box)
    
    if sprite_metadata.get("detection_area"):
        var detection_area = detection_area_generator.generate_detection_area(sprite_path, sprite_metadata.get("character_name", ""))
        if detection_area:
            detection_area.name = "CharacterArea"
            root.add_child(detection_area)
    
    var anim_player = AnimationPlayer.new()
    anim_player.name = "AnimationPlayer"
    root.add_child(anim_player)
    
    if sprite_metadata.get("image_type") == "sprite_sheet":
        var rows = sprite_metadata.get("rows", 1)
        var columns = sprite_metadata.get("columns", 1)
        sprite.hframes = columns
        sprite.vframes = rows
        
        for anim in sprite_metadata.get("animations", []):
            var animation = Animation.new()
            animation.length = anim.frame_count * 0.1
            var track_idx = animation.add_track(Animation.TYPE_VALUE)
            animation.track_set_path(track_idx, "Sprite:frame")
            for frame in range(anim.frame_range[0] - 1, anim.frame_range[1]):
                animation.track_insert_key(track_idx, (frame - (anim.frame_range[0] - 1)) * 0.1, frame)
            animation.loop_mode = Animation.LOOP_LINEAR if anim.name in ["Walk", "Run"] else Animation.LOOP_NONE
            
            # Add audio track if linked
            var audio_path = find_linked_audio(sprite_path, anim.name)
            if audio_path:
                var audio_player = AudioStreamPlayer.new()
                audio_player.stream = ResourceLoader.load(audio_path)
                audio_player.name = "Audio_" + anim.name
                root.add_child(audio_player)
                var audio_track = animation.add_track(Animation.TYPE_METHOD)
                animation.track_set_path(audio_track, audio_player.get_path())
                animation.track_insert_key(audio_track, 0.0, {"method": "play", "args": []})
                animation.track_insert_key(audio_track, animation.length, {"method": "stop", "args": []})
            
            anim_player.add_animation_library("", AnimationLibrary.new())
            anim_player.get_animation_library("").add_animation(anim.name, animation)
    else:
        var idle_anim = Animation.new()
        idle_anim.length = 0.1
        var track_idx = idle_anim.add_track(Animation.TYPE_VALUE)
        idle_anim.track_set_path(track_idx, "Sprite:frame")
        idle_anim.track_insert_key(track_idx, 0.0, 0)
        anim_player.add_animation_library("", AnimationLibrary.new())
        anim_player.get_animation_library("").add_animation("Idle", idle_anim)
    
    return root

func find_linked_audio(sprite_path: String, animation_name: String) -> String:
    var sprite_metadata = asset_manager.get_asset(sprite_path)
    var character_name = sprite_metadata.get("character_name", "")
    var audio_assets = asset_manager.search_assets({"type": "audio", "character_name": character_name})
    
    for audio in audio_assets:
        if audio.metadata.get("linked_animation", {}).get("sprite_path") == sprite_path and \
           audio.metadata.get("linked_animation", {}).get("animation_name") == animation_name:
            return audio.file_path
    
    return ""
