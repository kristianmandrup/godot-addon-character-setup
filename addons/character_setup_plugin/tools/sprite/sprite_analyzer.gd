class_name SpriteAnalyzer extends RefCounted

enum CollisionShapeType { RECTANGLE, CAPSULE, CIRCLE }

func generate_collision_shape(sprite_path: String, shape_type: CollisionShapeType = CollisionShapeType.RECTANGLE, region: String = "full") -> Dictionary:
    var sprite = ResourceLoader.load(sprite_path)
    if not sprite is Texture2D:
        print("Error: Invalid sprite resource at ", sprite_path)
        return {}
    
    var sprite_size = sprite.get_size()
    if sprite_size.x <= 0 or sprite_size.y <= 0:
        print("Error: Invalid sprite size ", sprite_size)
        return {}
    
    var analysis = analyze_sprite_local(sprite_path)
    var shape_size = sprite_size
    var offset = Vector2.ZERO
    
    # Adjust size based on region
    if region == "feet":
        shape_size.y *= 0.5  # Half height for feet
        offset.y = sprite_size.y * 0.25  # Center at bottom half
        if analysis.get("sprite_count", 1) > 1:
            var frame_height = sprite_size.y / analysis.get("rows", 1)
            shape_size.y = frame_height * 0.5
            offset.y = frame_height * 0.25
    
    var collision_shape = CollisionShape2D.new()
    var shape
    
    var configured_shape_type = shape_type
    if shape_type == CollisionShapeType.RECTANGLE:
        var setting = ProjectSettings.get_setting("plugins/character_setup_plugin/collision_shape_type", "rectangle").to_lower()
        if setting == "capsule":
            configured_shape_type = CollisionShapeType.CAPSULE
        elif setting == "circle":
            configured_shape_type = CollisionShapeType.CIRCLE
    
    match configured_shape_type:
        CollisionShapeType.RECTANGLE:
            var rect_shape = RectangleShape2D.new()
            rect_shape.extents = shape_size * 0.4
            shape = rect_shape
        CollisionShapeType.CAPSULE:
            var capsule_shape = CapsuleShape2D.new()
            capsule_shape.radius = min(shape_size.x, shape_size.y) * 0.2
            capsule_shape.height = shape_size.y * 0.8
            shape = capsule_shape
        CollisionShapeType.CIRCLE:
            var circle_shape = CircleShape2D.new()
            circle_shape.radius = min(shape_size.x, shape_size.y) * 0.4
            shape = circle_shape
        _:
            print("Warning: Unknown shape type, defaulting to rectangle")
            var rect_shape = RectangleShape2D.new()
            rect_shape.extents = shape_size * 0.4
            shape = rect_shape
    
    collision_shape.shape = shape
    collision_shape.position = offset
    return {
        "shape": collision_shape,
        "size": shape_size,
        "offset": offset
    }

func analyze_sprite_local(image_path: String) -> Dictionary:
    if not check_opencv_availability():
        print("OpenCV not available; falling back to heuristic")
        return heuristic_sprite_analysis(image_path)
    
    var python_path = get_python_path()
    var script_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/scripts/sprite_analyzer.py")
    var absolute_image_path = ProjectSettings.globalize_path(image_path)
    
    var output = []
    var exit_code = OS.execute(python_path, [script_path, absolute_image_path], output, true)
    
    if exit_code == 0 and output.size() > 0:
        var json = JSON.parse_string(output[0])
        if json.has("error"):
            print("Python error: ", json.error)
            return heuristic_sprite_analysis(image_path)
        return json
    else:
        print("Python script failed: ", output)
        return heuristic_sprite_analysis(image_path)

func heuristic_sprite_analysis(image_path: String) -> Dictionary:
    var image = Image.load_from_file(image_path)
    return {
        "sprite_count": 1,
        "rows": 1,
        "columns": 1,
        "collision_shapes": [[Vector2(0, 0), Vector2(image.get_width(), 0), Vector2(image.get_width(), image.get_height()), Vector2(0, image.get_height())]]
    }

func check_opencv_availability() -> bool:
    var output = []
    var exit_code = OS.execute("python", ["-c", "import cv2, numpy"], output, true)
    return exit_code == 0

func install_python_dependencies() -> bool:
    var python_path = get_python_path()
    if python_path == "":
        print("Error: Python not found. Please install Python 3.x.")
        return false
    
    var requirements_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/requirements.txt")
    if not FileAccess.file_exists("res://addons/character_setup_plugin/requirements.txt"):
        print("Error: requirements.txt not found.")
        return false
    
    var output = []
    var exit_code = OS.execute(python_path, ["-m", "pip", "install", "-r", requirements_path], output, true)
    
    if exit_code == 0:
        print("Python dependencies installed successfully.")
        return true
    else:
        print("Failed to install dependencies: ", output)
        return false

func get_python_path() -> String:
    var candidates = [
        "python",
        "python3",
        "C:/Python39/python.exe",
        "/usr/bin/python3",
        "/usr/local/bin/python3"
    ]
    for candidate in candidates:
        var output = []
        if OS.execute(candidate, ["-c", "import sys"], output, true) == 0:
            return candidate
    print("Error: Python not found.")
    return "python"