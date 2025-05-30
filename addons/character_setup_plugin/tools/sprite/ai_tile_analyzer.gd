class_name TileAnalyzer extends RefCounted

func analyze_tiles_with_custom_api(tilemap_name: String, server_url: String) -> void:
    var metadata_path = "user://tilemap_%s.json" % tilemap_name
    var file = FileAccess.open(metadata_path, FileAccess.READ)
    if not file:
        emit_signal("api_analysis_completed", false, "Failed to load metadata")
        return
    
    var json = JSON.new()
    var parse_error = json.parse(file.get_as_text())
    file.close()
    if parse_error != OK:
        emit_signal("api_analysis_completed", false, "Failed to parse metadata")
        return
    
    var metadata = json.get_data()
    var tiles = metadata.tiles
    var remaining_tiles = tiles.size()
    
    for tile in tiles:
        var tile_path = tile.file_path
        var image = Image.load_from_file(tile_path)
        if not image:
            continue
            
        var buffer = image.save_png_to_buffer()
        var http_request = HTTPRequest.new()
        add_child(http_request)
        http_request.request_completed.connect(
            func(result, response_code, headers, body):
                remaining_tiles -= 1
                if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
                    var response = JSON.parse_string(body.get_string_from_utf8())
                    tile["is_full_sprite"] = response["is_full_sprite"]
                    # Add description logic if implemented
                if remaining_tiles == 0:
                    var save_file = FileAccess.open(metadata_path, FileAccess.WRITE)
                    if save_file:
                        save_file.store_string(JSON.stringify(metadata, "  "))
                        save_file.close()
                        emit_signal("api_analysis_completed", true, "Analysis complete")
                    else:
                        emit_signal("api_analysis_completed", false, "Failed to save metadata")
                http_request.queue_free()
        )
        var url = server_url + "/predict"
        var headers = ["Content-Type: multipart/form-data"]
        var error = http_request.request(url, headers, HTTPClient.METHOD_POST, buffer)
        if error != OK:
            remaining_tiles -= 1
            http_request.queue_free()

# Takes in a tilemap metadata and analyzes each tile using an AI API (e.g., Google Cloud Vision)
# {
#   "tilemap_name": "Ground",
#   "filepath": "res://scenes/levels/Level1.tscn",
#   "tile_size": [32, 32],
#   "grid_dimensions": [2, 2],
#   "tiles": [
#     {"tile_id": [0, 0], "file_path": "user://tiles_Ground/tile_0.png", "is_obstacle": false},
#     {"tile_id": [1, 0], "file_path": "user://tiles_Ground/tile_1.png", "is_obstacle": false},
#     ...
#   ]
# }

# After analysis, the updated user://tilemap_Ground.json might look like:

# json

# Copy
# {
#   "tilemap_name": "Ground",
#   "filepath": "res://scenes/levels/Level1.tscn",
#   "tile_size": [32, 32],
#   "grid_dimensions": [2, 2],
#   "tiles": [
#     {
#       "tile_id": [0, 0],
#       "file_path": "user://tiles_Ground/tile_0.png",
#       "is_obstacle": false,
#       "is_full_sprite": true,
#       "description": "dirt path"
#     },
#     {
#       "tile_id": [1, 0],
#       "file_path": "user://tiles_Ground/tile_1.png",
#       "is_obstacle": false,
#       "is_full_sprite": false,
#       "description": "corner tile with grass"
#     },
#     ...
#   ]
# }

# Analyzes tiles using an AI API (e.g., Google Cloud Vision)
func analyze_tiles_with_api(tilemap_name: String, api_key: String) -> void:
    # Load metadata
    var metadata_path = "user://tilemap_%s.json" % tilemap_name
    var file = FileAccess.open(metadata_path, FileAccess.READ)
    if not file:
        emit_signal("api_analysis_completed", false, "Failed to load metadata from %s" % metadata_path)
        return
    
    var json = JSON.new()
    var parse_error = json.parse(file.get_as_text())
    file.close()
    if parse_error != OK:
        emit_signal("api_analysis_completed", false, "Failed to parse metadata JSON: %s" % json.get_error_message())
        return
    
    var metadata = json.get_data()
    if not metadata is Dictionary or not metadata.has("tiles"):
        emit_signal("api_analysis_completed", false, "Invalid metadata structure")
        return
    
    # Process each tile
    var tiles = metadata.tiles
    var remaining_tiles = tiles.size()
    var successful = true
    var error_message = ""
    
    for tile in tiles:
        var tile_path = tile.file_path
        var image = Image.load_from_file(tile_path)
        if not image:
            successful = false
            error_message = "Failed to load tile image: %s" % tile_path
            break
        
        # Convert image to base64
        var buffer = image.save_png_to_buffer()
        var base64_image = Marshalls.raw_to_base64(buffer)
        
        # Prepare API request (Google Cloud Vision API)
        var request_body = {
            "requests": [{
                "image": {"content": base64_image},
                "features": [
                    {"type": "LABEL_DETECTION", "maxResults": 5},
                    {"type": "OBJECT_LOCALIZATION", "maxResults": 5}
                ]
            }]
        }
        
        var http_request = HTTPRequest.new()
        add_child(http_request)
        http_request.request_completed.connect(
            func(result, response_code, headers, body):
                remaining_tiles -= 1
                var response = _process_api_response(result, response_code, body, tile)
                if response.success:
                    tile["is_full_sprite"] = response.is_full_sprite
                    tile["description"] = response.description
                else:
                    successful = false
                    error_message = response.error_message
                
                # Check if all tiles are processed
                if remaining_tiles == 0:
                    if successful:
                        # Save updated metadata
                        var save_file = FileAccess.open(metadata_path, FileAccess.WRITE)
                        if save_file:
                            save_file.store_string(JSON.stringify(metadata, "  "))
                            save_file.close()
                            emit_signal("api_analysis_completed", true, "All tiles analyzed and metadata updated")
                        else:
                            emit_signal("api_analysis_completed", false, "Failed to save updated metadata")
                    else:
                        emit_signal("api_analysis_completed", false, error_message)
                http_request.queue_free()
        )
        
        # Send API request
        var url = "https://vision.googleapis.com/v1/images:annotate?key=%s" % api_key
        var headers = ["Content-Type: application/json"]
        var body_str = JSON.stringify(request_body)
        var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body_str)
        if error != OK:
            remaining_tiles -= 1
            successful = false
            error_message = "Failed to send API request for tile %s" % tile_path
            http_request.queue_free()

# Processes the API response
func _process_api_response(result: int, response_code: int, body: PackedByteArray, tile: Dictionary) -> Dictionary:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        return {"success": false, "error_message": "API request failed: result=%d, response_code=%d" % [result, response_code]}
    
    var json = JSON.new()
    var parse_error = json.parse(body.get_string_from_utf8())
    if parse_error != OK:
        return {"success": false, "error_message": "Failed to parse API response: %s" % json.get_error_message()}
    
    var data = json.get_data()
    if not data.has("responses") or not data.responses[0]:
        return {"success": false, "error_message": "Invalid API response structure"}
    
    var response = data.responses[0]
    
    # Extract description from label annotations
    var description = "Unknown"
    if response.has("labelAnnotations"):
        var labels = response.labelAnnotations
        if labels.size() > 0:
            description = labels[0].description
            if labels.size() > 1:
                description += " with " + labels[1].description
    
    # Determine if the sprite is full or cut-off using object localization
    var is_full_sprite = true
    if response.has("localizedObjectAnnotations"):
        var objects = response.localizedObjectAnnotations
        if objects.size() > 0:
            var bounds = objects[0].boundingPoly.normalizedVertices
            # Check if the object touches the edges (indicating a cut-off)
            for vertex in bounds:
                if vertex.x <= 0.05 or vertex.x >= 0.95 or vertex.y <= 0.05 or vertex.y >= 0.95:
                    is_full_sprite = false
                    break
    
    return {
        "success": true,
        "is_full_sprite": is_full_sprite,
        "description": description
    }