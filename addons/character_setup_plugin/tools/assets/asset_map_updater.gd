class_name AssetMapUpdater extends RefCounted

var asset_manager: GameAssetManager
var sprite_analyzer: SpriteAnalyzer
var image_detector: ImageDetector
var audio_detector: AudioDetector
var detectors: Array[BaseFileTypeDetector] = []
var file_map_path: String = "res://addons/character_setup_plugin/file_map.json"

func _init():
    asset_manager = GameAssetManager.new()
    sprite_analyzer = SpriteAnalyzer.new()
    var tag_inferer = TagInferer.new()
    var image_extensions = ProjectSettings.get_setting("plugins/character_setup_plugin/image_extensions", [".png", ".jpg", ".jpeg", ".bmp"])
    var audio_extensions = ProjectSettings.get_setting("plugins/character_setup_plugin/audio_extensions", [".wav", ".ogg", ".mp3"])
    image_detector = ImageDetector.new(tag_inferer, image_extensions, asset_manager)
    audio_detector = AudioDetector.new(tag_inferer, audio_extensions, asset_manager)
    detectors.append_array([image_detector, audio_detector])

func update_asset_map(sync_gas: bool = false) -> Dictionary:
    var file_map = load_file_map()
    if file_map.is_empty():
        print("Error: file_map.json is empty or not found at ", file_map_path)
        return {"status": "error", "message": "No file map found"}

    var updated_assets = 0
    var errors = []

    # Process sprites first to get animations
    var sprite_animations = {}
    for file_path in file_map.keys():
        var file_metadata = file_map[file_path]
        if file_metadata.get("type") == "sprite" and file_metadata.get("image_type") == "sprite_sheet":
            var metadata = image_detector.detect(file_path, file_path.get_file())
            if not metadata.is_empty():
                sprite_animations[file_path] = {
                    "character_name": file_metadata.get("character_name", ""),
                    "animations": metadata.get("animations", [])
                }
                asset_manager.add_asset(file_path, metadata)
                updated_assets += 1
                if sync_gas:
                    var result_code = await sync_asset_to_gas(file_path, metadata)
                    if result_code.get("error"):
                        errors.append({"file_path": file_path, "error": result_code.error})

    # Match audio to animations
    for file_path in file_map.keys():
        var file_metadata = file_map[file_path]
        if file_metadata.get("type") == "audio":
            var metadata = audio_detector.detect(file_path, file_path.get_file())
            if not metadata.is_empty():
                var audio_character = file_metadata.get("character_name", "")
                var audio_name = file_path.get_basename().get_file().to_lower()
                
                # Find matching sprite animations
                for sprite_path in sprite_animations:
                    var sprite_data = sprite_animations[sprite_path]
                    if sprite_data.character_name == audio_character:
                        for anim in sprite_data.animations:
                            var anim_name = anim.name.to_lower()
                            if anim_name in audio_name:
                                metadata["linked_animation"] = {
                                    "sprite_path": sprite_path,
                                    "animation_name": anim.name
                                }
                                break
                
                asset_manager.add_asset(file_path, metadata)
                updated_assets += 1
                if sync_gas:
                    var result_code = await sync_asset_to_gas(file_path, metadata)
                    if result_code.get("error"):
                        errors.append({"file_path": file_path, "error": result_code.error})

    # Process remaining assets (scenes, scripts, etc.)
    for file_path in file_map.keys():
        var file_metadata = file_map[file_path]
        if file_metadata.get("type") not in ["sprite", "audio"]:
            var metadata = {}
            for detector in detectors:
                metadata = detector.detect(file_path, file_path.get_file())
                if not metadata.is_empty():
                    break
            if not metadata.is_empty():
                asset_manager.add_asset(file_path, metadata)
                updated_assets += 1
                if sync_gas:
                    var result_code = await sync_asset_to_gas(file_path, metadata)
                    if result_code.get("error"):
                        errors.append({"file_path": file_path, "error": result_code.error})

    var result = {
        "status": "success",
        "updated_assets": updated_assets,
        "errors": errors
    }

    print("AssetMapUpdater: Updated ", updated_assets, " assets. Errors: ", errors.size())
    return result


func update_gas_from_asset_map() -> Dictionary:
    asset_manager.save_all_assets_in_gas()
    return {"status": "success"}

func load_file_map() -> Dictionary:
    var file_map = {}
    if FileAccess.file_exists(file_map_path):
        var file = FileAccess.open(file_map_path, FileAccess.READ)
        var json = JSON.parse_string(file.get_as_text())
        if json is Dictionary:
            file_map = json
        file.close()
    return file_map

func sync_asset_to_gas(file_path: String, metadata: Dictionary) -> Dictionary:
    # Rely on GameAssetManager's add_asset to handle GAS sync
    asset_manager.add_asset(file_path, metadata)
    # Check if GAS sync was successful by inspecting metadata for gas_id
    if metadata.has("gas_id"):
        return {"status": "success", "file_path": file_path}
    return {"status": "error", "file_path": file_path, "error": "Failed to sync to GAS"}