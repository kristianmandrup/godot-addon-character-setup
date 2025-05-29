class_name TileMapImporter extends RefCounted

func import_tilemap_metadata(tilemap: TileMapLayer, json_path: String):
    var file = FileAccess.open(json_path, FileAccess.READ)
    var json = JSON.parse_string(file.get_as_text())
    file.close()
    
    if not tilemap.tile_set or not json:
        return
    
    # Apply tile metadata
    for tile_info in json.tiles:
        var tile_id = Vector2i(tile_info.tile_id[0], tile_info.tile_id[1])
        var source = tilemap.tile_set.get_source(tilemap.tile_set.get_source_id(tile_id))
        if source is TileSetAtlasSource:
            var tile_data = source.get_tile_data(tile_id, 0)
            tile_data.set_custom_data("is_obstacle", tile_info.is_obstacle)
            # Optionally reapply collision polygons (if needed)
