extends Node
class_name FileMapManager

# Path to file_map.json
const FILE_MAP_PATH = "res://file_map.json"

# Example file_map.json:
# {
#   "tilemaps": [
#     {"name": "Ground", "filepath": "res://scenes/levels/Level1.tscn"},
#     {"name": "Obstacles", "filepath": "res://scenes/levels/Level2.tscn"}
#   ]
# }

# Searches for an entry filepath by name
func find_entry_by_name(name: String, partial_match: bool = false) -> String:
    var file = FileAccess.open(FILE_MAP_PATH, FileAccess.READ)
    if not file:
        push_error("Failed to open file_map.json at %s" % FILE_MAP_PATH)
        return ""
    
    var json = JSON.new()
    var parse_error = json.parse(file.get_as_text())
    file.close()
    
    if parse_error != OK:
        push_error("Failed to parse file_map.json: %s" % json.get_error_message())
        return ""
    
    var data = json.get_data()
    if not data is Dictionary:
        push_error("Invalid file_map.json structure: missing 'tilemaps' array")
        return ""
    
    var tilemaps = data.tilemaps
    for entry in tilemaps:
        if not entry is Dictionary or not entry.has("name") or not entry.has("filepath"):
            continue
        var entry_name = entry.name as String
        var filepath = entry.filepath as String
        if partial_match:
            if entry_name.to_lower().find(name.to_lower()) != -1:
                return filepath
        elif entry_name.to_lower() == name.to_lower():
            return entry
    
    push_error("No entry found for name: %s" % name)
    return ""