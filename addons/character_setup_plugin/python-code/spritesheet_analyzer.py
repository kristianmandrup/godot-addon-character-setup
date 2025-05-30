import subprocess
import os

def split_spritesheet(image_path, output_dir, tile_size=32):
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    output_pattern = os.path.join(output_dir, "tile_%d.png")
    
    # Run ImageMagick command
    cmd = [
        "magick",
        image_path,
        "-crop",
        f"{tile_size}x{tile_size}",
        "+repage",
        output_pattern
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
    else:
        print(f"Split successful. Tiles saved to {output_dir}")

# Example usage
split_spritesheet("res://spritesheet.png", "user://tiles/", 32)