from PIL import Image, ImageDraw

def draw_grid(image_path, output_path, tile_size=32):
    img = Image.open(image_path)
    draw = ImageDraw.Draw(img)
    width, height = img.size
    
    for x in range(tile_size, width, tile_size):
        draw.line((x, 0, x, height), fill="red", width=1)
    for y in range(tile_size, height, tile_size):
        draw.line((0, y, width, y), fill="red", width=1)
    
    img.save(output_path)

draw_grid("tilemap.png", "tilemap_with_grid.png", 32)

# Imagemagick
# magick Grass-01.png -fill none -stroke red -strokewidth 1 -draw "path 'M 0,32 L 512,32 M 0,64 L 512,64 M 0,96 L 512,96 M 0,128 L 512,128 M 0,160 L 512,160 M 0,192 L 512,192 M 0,224 L 512,224'" Grass-01-grid.png