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

func create_tilemap_from_metadata(metadata: Dictionary, spritesheet_path: String) -> TileMapLayer:
    var tilemap = TileMapLayer.new()
    var tile_set = TileSet.new()
    tile_set.tile_size = Vector2i(metadata.tile_size[0], metadata.tile_size[1])
    
    var source = TileSetAtlasSource.new()
    source.texture = load(spritesheet_path)
    tile_set.add_source(source)
    
    for tile in metadata.tiles:
        var tile_id = Vector2i(tile.tile_id[0], tile.tile_id[1])
        source.create_tile(tile_id)
        var tile_data = source.get_tile_data(tile_id, 0)
        tile_data.set_custom_data("is_obstacle", tile.is_obstacle)
    
    tilemap.tile_set = tile_set
    return tilemap

func create_sprite_frames_from_metadata(metadata: Dictionary, spritesheet_path: String) -> SpriteFrames:
    var sprite_frames = SpriteFrames.new()
    sprite_frames.add_animation("default")
    
    var texture = load(spritesheet_path)
    var tile_size = Vector2i(metadata.tile_size[0], metadata.tile_size[1])
    var grid_cols = metadata.grid_dimensions[0]
    
    for row in metadata.grid_dimensions[1]:
        for col in grid_cols:
            var region = Rect2(col * tile_size.x, row * tile_size.y, tile_size.x, tile_size.y)
            sprite_frames.add_frame("default", texture, 1.0, region)
    
    return sprite_frames    