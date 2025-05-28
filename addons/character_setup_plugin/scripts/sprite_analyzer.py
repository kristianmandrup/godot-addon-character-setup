import cv2
import numpy as np
import sys
import json

def analyze_sprite_sheet(image_path):
    img = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)
    if img is None:
        return {"error": "Failed to load image"}
    
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 1, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    sprite_count = len(contours)
    height, width = img.shape[:2]
    rows = int(np.sqrt(sprite_count))
    cols = sprite_count // rows if sprite_count % rows == 0 else sprite_count // rows + 1
    
    collision_shapes = []
    for contour in contours:
        points = contour.squeeze().tolist()
        collision_shapes.append(points)
    
    return {
        "sprite_count": sprite_count,
        "rows": rows,
        "columns": cols,
        "collision_shapes": collision_shapes
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No image path provided"}))
        sys.exit(1)
    image_path = sys.argv[1]
    result = analyze_sprite_sheet(image_path)
    print(json.dumps(result))