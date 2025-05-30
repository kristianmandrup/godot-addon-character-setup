extends Node
class_name SpriteSheetAnalyzer

# Signal emitted when analysis is complete
signal analysis_completed(success: bool, metadata: Dictionary, error_message: String)

# Splits the spritesheet using ImageMagick and analyzes the fit
func analyze_spritesheet(image_path: String, tilemap_name: String, file_map_manager: FileMapManager, tile_size: int = 32) -> void:
    # Ensure ImageMagick is available
    var test_output = []
    var test_error = OS.execute("magick", ["--version"], test_output)
    if test_error != 0:
        emit_signal("analysis_completed", false, {}, "ImageMagick not found. Please install it and ensure 'magick' is in PATH.")
        return
    
    # Prepare output directory
    var output_dir = "user://tiles_%s" % tilemap_name
    var output_pattern = "%s/tile_%%d.png" % output_dir
    DirAccess.make_dir_absolute(output_dir)
    
    # Run ImageMagick command to split the spritesheet
    # saves each tile to a separate file user://tiles_<tilemap_name>/tile_<tile_id>.png
    var args = [image_path, "-crop", "%dx%d" % [tile_size, tile_size], "+repage", output_pattern]
    var output = []
    var error = OS.execute("magick", args, output)
    if error != 0:
        emit_signal("analysis_completed", false, {}, "Failed to split spritesheet with ImageMagick: %s" % output)
        return
    
    # Load the image to determine dimensions
    var image = Image.load_from_file(image_path)
    if not image:
        emit_signal("analysis_completed", false, {}, "Failed to load image: %s" % image_path)
        return
    
    var img_width = image.get_width()
    var img_height = image.get_height()
    
    # Calculate grid dimensions
    if img_width % tile_size != 0 or img_height % tile_size != 0:
        emit_signal("analysis_completed", false, {}, "Image dimensions (%dx%d) not divisible by tile size %d" % [img_width, img_height, tile_size])
        return
    
    var grid_cols = img_width / tile_size
    var grid_rows = img_height / tile_size
    
    # Get filepath from FileMapManager
    var filepath = file_map_manager.find_tilemap_path(tilemap_name)
    if filepath.is_empty():
        emit_signal("analysis_completed", false, {}, "No filepath found for TileMapLayer: %s" % tilemap_name)
        return
    
    # Create metadata
    var metadata = {
        "tilemap_name": tilemap_name,
        "filepath": filepath,
        "tile_size": [tile_size, tile_size],
        "grid_dimensions": [grid_cols, grid_rows],
        "tiles": []
    }
    
    # Populate metadata with tile paths
    for row in grid_rows:
        for col in grid_cols:
            var tile_path = "user://tiles_%s/tile_%d.png" % [tilemap_name, (row * grid_cols + col)]
            metadata.tiles.append({
                "tile_id": [col, row],
                "file_path": tile_path,
                "is_obstacle": false # Placeholder
            })
    
    # Save metadata to JSON
    var local_path = "user://tilemap_%s.json" % tilemap_name
    var file = FileAccess.open(local_path, FileAccess.WRITE)
    if not file:
        emit_signal("analysis_completed", false, {}, "Failed to save metadata to %s" % local_path)
        return
    
    file.store_string(JSON.stringify(metadata, "  "))
    file.close()
    emit_signal("analysis_completed", true, metadata, "Metadata and tiles saved to %s" % local_path)