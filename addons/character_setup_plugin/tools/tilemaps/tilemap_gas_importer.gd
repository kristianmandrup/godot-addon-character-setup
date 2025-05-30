extends Node
class_name TileMapDataRetriever

# Signal emitted when retrieval and saving are complete
signal data_retrieved(success: bool, error_message: String)

# FileMapManager and SpriteSheetAnalyzer instances
var file_map_manager = FileMapManager.new()
var sprite_sheet_analyzer = SpriteSheetAnalyzer.new()

func _ready():
    add_child(file_map_manager)
    add_child(sprite_sheet_analyzer)

# Retrieves TileMap data from GAS and saves to a local JSON file
# {
#   "tilemap_name": "Ground",
#   "filepath": "res://scenes/levels/Level1.tscn",
#   "tile_size": [16, 16],
#   "grid_dimensions": [10, 5],
#   "tiles": [
#     {
#       "tile_id": [0, 0],
#       "is_obstacle": true,
#       "collision_polygons": [[0, 0, 16, 0, 16, 16, 0, 16]]
#     },
#     ...
#   ]
# }
# Retrieves TileMap data from GAS or analyzes a spritesheet
func retrieve_tilemap_data(tilemap_name: String, gas_base_url: String, spritesheet_path: String = "") -> void:
    if spritesheet_path:
        # Analyze spritesheet if provided
        sprite_sheet_analyzer.analyze_spritesheet(spritesheet_path, tilemap_name, file_map_manager)
        sprite_sheet_analyzer.analysis_completed.connect(
            func(success: bool, metadata: Dictionary, message: String):
                emit_signal("data_retrieved", success, message)
        )
        return
    
    # Otherwise, retrieve from GAS
    var filepath = file_map_manager.find_tilemap_path(tilemap_name)
    if filepath.is_empty():
        emit_signal("data_retrieved", false, "No filepath found for TileMapLayer: %s" % tilemap_name)
        return
    
    var gas_url = "%s/tilemap_%s.json" % [gas_base_url, tilemap_name]
    var local_path = "user://tilemap_%s.json" % tilemap_name
    
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    http_request.request_completed.connect(
        func(result: int, response_code: int, headers: Array, body: PackedByteArray):
            _on_request_completed(result, response_code, body, local_path, tilemap_name, filepath)
    )
    
    var error = http_request.request(gas_url, [], HTTPClient.METHOD_GET)
    if error != OK:
        emit_signal("data_retrieved", false, "Failed to send HTTP request: %s" % error_string(error))
        http_request.queue_free()

func _on_request_completed(result: int, response_code: int, body: PackedByteArray, local_path: String, tilemap_name: String, filepath: String) -> void:
    var http_request = get_node_or_null("HTTPRequest")
    if http_request:
        http_request.queue_free()
    
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        emit_signal("data_retrieved", false, "HTTP request failed: result=%d, response_code=%d" % [result, response_code])
        return
    
    var json = JSON.new()
    var parse_error = json.parse(body.get_string_from_utf8())
    if parse_error != OK:
        emit_signal("data_retrieved", false, "Failed to parse JSON: %s" % json.get_error_message())
        return
    
    var data = json.get_data()
    if not data is Dictionary or not data.has("tile_size") or not data.has("grid_dimensions"):
        emit_signal("data_retrieved", false, "Invalid JSON structure: missing required fields")
        return
    
    data["tilemap_name"] = tilemap_name
    data["filepath"] = filepath
    
    var file = FileAccess.open(local_path, FileAccess.WRITE)
    if not file:
        emit_signal("data_retrieved", false, "Failed to open file for writing: %s" % local_path)
        return
    
    file.store_string(JSON.stringify(data, "  "))
    file.close()
    emit_signal("data_retrieved", true, "TileMap data for %s saved to %s" % [tilemap_name, local_path])

# Example usage
func _test_retrieval():
    var gas_base_url = "https://example.com/gas"
    var tilemap_name = "Ground"
    var spritesheet_path = "res://spritesheet.jpg" # Set to empty for GAS retrieval
    retrieve_tilemap_data(tilemap_name, gas_base_url, spritesheet_path)
    data_retrieved.connect(
        func(success: bool, message: String):
            print("Data retrieval: %s - %s" % ["Success" if success else "Failed", message])
    )