class_name NameDetector extends RefCounted

# Configurable array of folder names to ignore
var ignore_patterns: Array[String] = ["asset", "script", "scene", "game", "world", "level", "audio", "sounds", "music", "sfx", "voice", "voices", "music", "audio", "video", "videos", "image", "images", "sprite", "sprites", "texture", "textures", "font", "fonts", "model", "models", "animation", "animations", "animation_set", "animation_sets", "characters", "players", "enemies", "npcs"]

func determine_name(file_path: String) -> String:
    # Get all path components by splitting the file path
    var path_components = file_path.get_base_dir().split("/", false)
    
    # Start from the deepest directory (last component)
    for i in range(path_components.size() - 1, -1, -1):
        var component = path_components[i]
        # Check if the component does not start with any ignore pattern
        var is_ignored = false
        for pattern in ignore_patterns:
            if component.to_lower().begins_with(pattern.to_lower()):
                is_ignored = true
                break
        if not is_ignored:
            # Return the capitalized component as the name
            return component.capitalize()
    
    # Fallback: If no suitable component is found, use the file's basename
    return file_path.get_file().get_basename().capitalize()