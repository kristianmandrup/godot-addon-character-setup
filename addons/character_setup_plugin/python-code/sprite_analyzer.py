import cv2
import numpy as np
import sys
import json
import os
import requests
import base64

def image_to_base64(image_path):
    """Convert image to base64 for API calls."""
    with open(image_path, "rb") as img_file:
        return base64.b64encode(img_file.read()).decode("utf-8")

def call_openai_api(image_path, api_key):
    """Use OpenAI GPT-4o to classify image type and suggest animation names."""
    if not api_key:
        return {"error": "No API key provided"}

    try:
        base64_image = image_to_base64(image_path)
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        payload = {
            "model": "gpt-4o",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": (
                                "Analyze this image and determine if it is a single sprite, a background image, or a sprite sheet. "
                                "If it is a sprite sheet, suggest animation names for each row (e.g., Idle, Walk, Attack). "
                                "Return JSON with 'image_type' (single_sprite, background, sprite_sheet) and 'animation_names' (list of strings)."
                            )
                        },
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/png;base64,{base64_image}"}
                        }
                    ]
                }
            ]
        }
        response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        content = result["choices"][0]["message"]["content"]
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            # Extract JSON from possible markdown code block
            start = content.find("{")
            end = content.rfind("}") + 1
            if start != -1 and end != -1:
                return json.loads(content[start:end])
            return {"error": "Invalid API response"}
    except Exception as e:
        return {"error": str(e)}

def analyze_sprite_sheet(image_path, api_key=""):
    """Analyze image to classify type and extract sprite sheet metadata."""
    # Load image
    img = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)
    if img is None:
        return {"error": "Failed to load image"}

    height, width = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img
    _, thresh = cv2.threshold(gray, 1, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    # Heuristic classification
    sprite_count = len(contours)
    edge_density = len(cv2.Canny(gray, 100, 200).nonzero()[0]) / (height * width)
    foreground_ratio = cv2.countNonZero(thresh) / (height * width)

    image_type = "single_sprite"
    if height * width > 512 * 512 and edge_density > 0.1 and sprite_count > 10:
        image_type = "background"
    elif sprite_count > 1 and height * width < 1024 * 1024 and foreground_ratio < 0.8:
        image_type = "sprite_sheet"

    # AI-based classification (optional)
    animation_names = []
    if api_key:
        ai_result = call_openai_api(image_path, api_key)
        if not ai_result.get("error"):
            image_type = ai_result.get("image_type", image_type)
            animation_names = ai_result.get("animation_names", [])

    # If not a sprite sheet, return basic metadata
    if image_type != "sprite_sheet":
        collision_shapes = [contour.squeeze().tolist() for contour in contours]
        return {
            "image_type": image_type,
            "height": height,
            "width": width,
            "sprite_count": sprite_count,
            "collision_shapes": collision_shapes
        }

    # Sprite sheet analysis
    # Estimate grid using contour centroids
    centroids = []
    for contour in contours:
        M = cv2.moments(contour)
        if M["m00"] != 0:
            cx = int(M["m10"] / M["m00"])
            cy = int(M["m01"] / M["m00"])
            centroids.append((cx, cy))

    if not centroids:
        return {"error": "No valid centroids found"}

    # Cluster centroids into rows
    centroids = sorted(centroids, key=lambda c: c[1])  # Sort by y-coordinate
    rows = []
    current_row = [centroids[0]]
    for centroid in centroids[1:]:
        if abs(centroid[1] - current_row[-1][1]) < height / 20:  # Same row
            current_row.append(centroid)
        else:
            rows.append(sorted(current_row, key=lambda c: c[0]))  # Sort by x
            current_row = [centroid]
    rows.append(sorted(current_row, key=lambda c: c[0]))

    # Build animations
    animations = []
    frame_index = 1
    for i, row in enumerate(rows):
        frame_count = len(row)
        animation_name = f"Animation_{i+1}"
        
        # Heuristic name from filename
        filename = os.path.basename(image_path).lower()
        if "idle" in filename:
            animation_name = "Idle"
        elif "walk" in filename or "run" in filename:
            animation_name = "Walk"
        elif "attack" in filename:
            animation_name = "Attack"
        elif "jump" in filename:
            animation_name = "Jump"
        
        # Use AI name if available
        if i < len(animation_names):
            animation_name = animation_names[i]
        
        animations.append({
            "name": animation_name,
            "frame_count": frame_count,
            "frame_range": [frame_index, frame_index + frame_count - 1]
        })
        frame_index += frame_count

    # Collision shapes
    collision_shapes = [contour.squeeze().tolist() for contour in contours]

    return {
        "image_type": "sprite_sheet",
        "height": height,
        "width": width,
        "sprite_count": sprite_count,
        "rows": len(rows),
        "columns": max(len(row) for row in rows),
        "animations": animations,
        "collision_shapes": collision_shapes
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No image path provided"}))
        sys.exit(1)
    image_path = sys.argv[1]
    api_key = os.environ.get("OPENAI_API_KEY", "")
    result = analyze_sprite_sheet(image_path, api_key)
    print(json.dumps(result, indent=2))