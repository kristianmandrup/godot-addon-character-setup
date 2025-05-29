class_name TileMapDataEnricher extends RefCounted

func add_tile_metadata(tilemap: TileMapLayer):
    if not tilemap.tile_set:
        return
    var source_count = tilemap.tile_set.get_source_count()
    for source_id in source_count:
        var source = tilemap.tile_set.get_source(source_id)
        if source is TileSetAtlasSource:
            var tiles = source.get_tiles()
            for tile in tiles:
                var tile_data = source.get_tile_data(tile, 0)
                # Example: Mark tiles with collisions as obstacles
                tile_data.set_custom_data("is_obstacle", tile_data.get_collision_polygons_count(0) > 0)