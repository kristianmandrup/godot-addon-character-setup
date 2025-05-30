# Previous functions omitted for brevity

# Draws a grid on the tilemap image using Godot's Image class
func draw_grid_on_tilemap_godot(image_path: String, tile_size: int = 32, grid_color: Color = Color.RED) -> void:
    # Load the image
    var image = Image.load_from_file(image_path)
    if not image:
        emit_signal("grid_drawn", false, "", "Failed to load image: %s" % image_path)
        return
    
    var img_width = image.get_width()
    var img_height = image.get_height()
    
    image.lock()
    
    # Draw vertical lines
    for x in range(tile_size, img_width, tile_size):
        for y in range(img_height):
            image.set_pixel(x, y, grid_color)
    
    # Draw horizontal lines
    for y in range(tile_size, img_height, tile_size):
        for x in range(img_width):
            image.set_pixel(x, y, grid_color)
    
    image.unlock()
    
    # Save the modified image
    var output_path = image_path.get_basename() + "_with_grid.png"
    var error = image.save_png(output_path)
    if error != OK:
        emit_signal("grid_drawn", false, "", "Failed to save image with grid: %s" % error_string(error))
        return
    
    emit_signal("grid_drawn", true, output_path, "Grid drawn successfully to %s" % output_path)