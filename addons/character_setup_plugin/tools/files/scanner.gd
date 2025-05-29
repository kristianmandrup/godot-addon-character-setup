class_name Scanner extends RefCounted

enum ComparisonMethod { MODIFIED_TIME, FILE_HASH }

@export var comparison_method: ComparisonMethod = ComparisonMethod.MODIFIED_TIME
var detectors: Array[BaseFileTypeDetector] = []
var tag_inferer: TagInferer
var asset_manager: GameAssetManager

func _init():
    asset_manager = GameAssetManager.new()
    var api_key = ProjectSettings.get_setting("plugins/character_setup_plugin/api_key", "")
    tag_inferer = AITagDetector.new(api_key) if api_key else TagInferer.new()
    var image_extensions = ProjectSettings.get_setting("plugins/character_setup_plugin/image_extensions", [".png", ".jpg", ".jpeg", ".bmp"])
    var audio_extensions = ProjectSettings.get_setting("plugins/character_setup_plugin/audio_extensions", [".wav", ".ogg", ".mp3"])
    detectors = [
        ImageDetector.new(tag_inferer, image_extensions, asset_manager),
        AudioDetector.new(tag_inferer, audio_extensions, asset_manager),
        SceneDetector.new(tag_inferer),
        ScriptDetector.new(tag_inferer),
        OtherDetector.new(tag_inferer)
    ]

func scan_filesystem() -> Dictionary:
    var file_map = {}
    var directories = ["res://"]
    while not directories.is_empty():
        var dir_path = directories.pop_front()
        var dir = DirAccess.open(dir_path)
        if dir:
            dir.list_dir_begin()
            var file_name = dir.get_next()
            while file_name != "":
                var full_path = dir_path + file_name
                if dir.current_is_dir():
                    directories.append(full_path + "/")
                else:
                    for detector in detectors:
                        var metadata = detector.detect(full_path, file_name)
                        if not metadata.is_empty():
                            # Extract character_name from folder or filename
                            metadata["character_name"] = infer_character_name(full_path, file_name)
                            file_map[full_path] = metadata
                            break
                file_name = dir.get_next()
            dir.list_dir_end()
    
    # Save file_map.json
    var file = FileAccess.open("res://addons/character_setup_plugin/file_map.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(file_map, "\t"))
    file.close()
    
    return file_map

func infer_character_name(file_path: String, file_name: String) -> String:
    # Extract from folder (e.g., res://characters/player/)
    var parts = file_path.split("/")
    var character_name = ""
    
    for i in range(parts.size()):
        if parts[i] == "characters" and i + 1 < parts.size():
            character_name = parts[i + 1].capitalize()
            break
    
    # Fallback to filename (e.g., player_walk.wav -> Player)
    if not character_name:
        var base_name = file_name.get_basename()
        var name_parts = base_name.split("_")
        character_name = name_parts[0].capitalize() if name_parts.size() > 0 else base_name.capitalize()
    
    # Optional AI-based naming (if api_key exists)
    var api_key = ProjectSettings.get_setting("plugins/character_setup_plugin/api_key", "")
    if api_key and (file_path.ends_with(".png") or file_path.ends_with(".wav")):
        var ai_name = call_openai_for_name(file_path, api_key)
        if ai_name:
            character_name = ai_name
    
    return character_name

func call_openai_for_name(file_path: String, api_key: String) -> String:
    # Placeholder for AI API call (implemented in Python for images/audio)
    # Returns empty string if API call fails
    var python_path = PythonUtils..get_python_path()
    var script_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/scripts/infer_name.py")
    var absolute_file_path = ProjectSettings.globalize_path(file_path)
    
    OS.set_environment("OPENAI_API_KEY", api_key)
    var output = []
    var exit_code = OS.execute(python_path, [script_path, absolute_file_path], output, true)
    
    if exit_code == 0 and output.size() > 0:
        var json = JSON.parse_string(output[0])
        if json is Dictionary and json.has("character_name"):
            return json.character_name
    return ""