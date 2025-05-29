class_name TileDataExtractor extends RefCounted

func extract_tile_images(tilemap: TileMapLayer) -> Dictionary:
    var tile_images: Dictionary = {} # tile_id -> Image
    if not tilemap.tile_set:
        return tile_images
    
    var source_count = tilemap.tile_set.get_source_count()
    for source_id in source_count:
        var source = tilemap.tile_set.get_source(source_id)
        if source is TileSetAtlasSource:
            var texture = source.texture
            var image = texture.get_image()
            var tiles = source.get_tiles()
            for tile in tiles:
                var region = source.get_tile_texture_region(tile)
                var tile_image = Image.create(region.size.x, region.size.y, false, image.get_format())
                tile_image.blit_rect(image, region, Vector2i(0, 0))
                tile_images[tile] = tile_image
    return tile_images

func get_obstacle_areas(tilemap: TileMapLayer, cell: Vector2i) -> Array[Vector2]:
    var areas: Array[Vector2] = []
    var tile_data = tilemap.get_cell_tile_data(0, cell)
    if tile_data and tile_data.get_collision_polygons_count(0) > 0:
        for i in tile_data.get_collision_polygons_count(0):
            var polygon = tile_data.get_collision_polygon_points(0, i)
            # Convert polygon points to world coordinates
            var world_points = polygon.map(func(p): return tilemap.map_to_local(cell) + p)
            areas.append_array(world_points)
    return areas    

func get_obstacle_tiles(tilemap: TileMapLayer) -> Array[Vector2i]:
    var obstacle_cells: Array[Vector2i] = []
    if not tilemap.tile_set:
        return obstacle_cells
    
    var used_cells = tilemap.get_used_cells(0)
    for cell in used_cells:
        var tile_data = tilemap.get_cell_tile_data(0, cell)
        if tile_data and tile_data.get_collision_polygons_count(0) > 0:
            obstacle_cells.append(cell)
    return obstacle_cells    

func get_tile_size(tilemap: TileMapLayer) -> Vector2i:
    if tilemap.tile_set:
        return tilemap.tile_set.tile_size
    return Vector2i(0, 0) # Fallback for invalid TileSet

func get_grid_dimensions(tilemap: TileMapLayer) -> Vector2i:
    var used_cells = tilemap.get_used_cells(0) # Layer 0
    if used_cells.is_empty():
        return Vector2i(0, 0)
    
    var min_x = used_cells[0].x
    var max_x = min_x
    var min_y = used_cells[0].y
    var max_y = min_y
    
    for cell in used_cells:
        min_x = min(min_x, cell.x)
        max_x = max(max_x, cell.x)
        min_y = min(min_y, cell.y)
        max_y = max(max_y, cell.y)
    
    # Rows = height (y), Columns = width (x)
    return Vector2i(max_x - min_x + 1, max_y - min_y + 1)    