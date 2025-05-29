class_name TileMapExporter extends RefCounted


# Exports tile_size, grid_dimensions, and per-tile metadata (e.g., is_obstacle, collision polygons) to a JSON file.
# {
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
func export_tilemap_metadata(tilemap: TileMapLayer, output_path: String):
    if not tilemap.tile_set:
        return
    
    var metadata = {
        "tile_size": tilemap.tile_set.tile_size,
        "grid_dimensions": get_grid_dimensions(tilemap),
        "tiles": []
    }
    
    var source_count = tilemap.tile_set.get_source_count()
    for source_id in source_count:
        var source = tilemap.tile_set.get_source(source_id)
        if source is TileSetAtlasSource:
            var tiles = source.get_tiles()
            for tile in tiles:
                var tile_data = source.get_tile_data(tile, 0)
                var tile_info = {
                    "tile_id": tile,
                    "is_obstacle": tile_data.get_custom_data("is_obstacle") if tile_data.get_custom_data("is_obstacle") else false,
                    "collision_polygons": []
                }
                for i in tile_data.get_collision_polygons_count(0):
                    tile_info.collision_polygons.append(tile_data.get_collision_polygon_points(0, i))
                metadata.tiles.append(tile_info)
    
    var file = FileAccess.open(output_path, FileAccess.WRITE)
    file.store_string(JSON.stringify(metadata, "  "))
    file.close()

func upload_to_gas(url: String, file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    var content = file.get_as_text()
    file.close()
    
    var request = HTTPRequest.new()
    add_child(request)
    request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, content)
    request.request_completed.connect(func(result, response_code, headers, body):
        print("Upload response: ", response_code)
    )    