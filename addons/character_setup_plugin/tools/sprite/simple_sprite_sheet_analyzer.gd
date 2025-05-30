extends Node
class_name SpriteSheetAnalyzer

# Signal emitted when analysis is complete
signal analysis_completed(success: bool, metadata: Dictionary, error_message: String)

# Possible sprite sizes to test (common tile sizes in pixels)
const POSSIBLE_SIZES = [8, 16, 32, 64, 128]

# Analyzes a spritesheet image to determine sprite size and grid layout
func analyze_spritesheet(image_path: String, tilemap_name: String, file_map_manager: FileMapManager) -> void:
    # Load the image
    var image = Image.load_from_file(image_path)
    if not image:
        emit_signal("analysis_completed", false, {}, "Failed to load image: %s" % image_path)
        return
    
    # Get image dimensions
    var img_width = image.get_width()
    var img_height = image.get_height()
    
    # Test possible sprite sizes
    var best_size = Vector2i(0, 0)
    var best_score = -1.0
    var best_grid = Vector2i(0, 0)
    
    for size in POSSIBLE_SIZES:
        # Check if size evenly divides the image
        if img_width % size != 0 or img_height % size != 0:
            continue
        
        var grid_cols = img_width / size
        var grid_rows = img_height / size
        var score = evaluate_grid_fit(image, size, grid_cols, grid_rows)
        
        if score > best_score:
            best_score = score
            best_size = Vector2i(size, size)
            best_grid = Vector2i(grid_cols, grid_rows)
    
    if best_size == Vector2i(0, 0):
        emit_signal("analysis_completed", false, {}, "No suitable sprite size found for %s" % image_path)
        return
    
    # Get filepath from FileMapManager
    var filepath = file_map_manager.find_tilemap_path(tilemap_name)
    if filepath.is_empty():
        emit_signal("analysis_completed", false, {}, "No filepath found for TileMapLayer: %s" % tilemap_name)
        return
    
    # Create metadata
    var metadata = {
        "tilemap_name": tilemap_name,
        "filepath": filepath,
        "tile_size": [best_size.x, best_size.y],
        "grid_dimensions": [best_grid.x, best_grid.y],
        "tiles": []
    }
    
    # Optionally populate tiles array with basic metadata
    for row in best_grid.y:
        for col in best_grid.x:
            metadata.tiles.append({
                "tile_id": [col, row],
                "is_obstacle": false # Placeholder; requires further analysis
            })
    
    # Save metadata to JSON
    var local_path = "user://tilemap_%s.json" % tilemap_name
    var file = FileAccess.open(local_path, FileAccess.WRITE)
    if not file:
        emit_signal("analysis_completed", false, {}, "Failed to save metadata to %s" % local_path)
        return
    
    file.store_string(JSON.stringify(metadata, "  "))
    file.close()
    emit_signal("analysis_completed", true, metadata, "Metadata saved to %s" % local_path)

# Evaluates how well a grid size fits the spritesheet
func evaluate_grid_fit(image: Image, size: int, cols: int, rows: int) -> float:
    image.lock()
    var score = 0.0
    var total_tiles = cols * rows
    
    for row in rows:
        for col in cols:
            var tile_rect = Rect2i(col * size, row * size, size, size)
            var has_content = false
            var has_border = true
            
            # Check for non-transparent content in the tile
            for x in range(tile_rect.position.x, tile_rect.position.x + tile_rect.size.x):
                for y in range(tile_rect.position.y, tile_rect.position.y + tile_rect.size.y):
                    if image.get_pixel(x, y).a > 0:
                        has_content = true
                        break
                
            # Check for transparent or uniform border (simplified edge detection)
            for x in [tile_rect.position.x, tile_rect.position.x + tile_rect.size.x - 1]:
                for y in range(tile_rect.position.y, tile_rect.position.y + tile_rect.size.y):
                    if image.get_pixel(x, y).a > 0:
                        has_border = false
                        break
            for y in [tile_rect.position.y, tile_rect.position.y + tile_rect.size.y - 1]:
                for x in range(tile_rect.position.x, tile_rect.position.x + tile_rect.size.x):
                    if image.get_pixel(x, y).a > 0:
                        has_border = false
                        break
            
            if has_content and has_border:
                score += 1.0
    
    image.unlock()
    return score / total_tiles if total_tiles > 0 else 0.0