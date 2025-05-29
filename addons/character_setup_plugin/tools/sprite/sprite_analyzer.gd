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
    if not PythonUtils.check_opencv_availability():
        print("OpenCV not available; falling back to heuristic")
        return heuristic_sprite_analysis(image_path)
    
    var python_path = PythonUtils.get_python_path()
    var script_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/scripts/analyze_sprite_sheet.py")
    var absolute_image_path = ProjectSettings.globalize_path(image_path)
    
    var output = []
    var api_key = ProjectSettings.get_setting("plugins/character_setup_plugin/api_key", "")
    var args = [script_path, absolute_image_path]
    
    # Set OPENAI_API_KEY environment variable if available
    if api_key:
        OS.set_environment("OPENAI_API_KEY", api_key)
    
    var exit_code = OS.execute(python_path, args, output, true)
    
    if exit_code == 0 and output.size() > 0:
        var json = JSON.parse_string(output[0])
        if json is Dictionary and not json.has("error"):
            return json
        print("Python error: ", json.get("error", "Invalid JSON"))
    else:
        print("Python script failed: ", output)
    
    return heuristic_sprite_analysis(image_path)

func heuristic_sprite_analysis(image_path: String) -> Dictionary:
    var image = Image.load_from_file(image_path)
    return {
        "image_type": "single_sprite",
        "height": image.get_height(),
        "width": image.get_width(),
        "sprite_count": 1,
        "rows": 1,
        "columns": 1,
        "collision_shapes": [],
        "animations": [{"name": "Idle", "frame_count": 1, "frame_range": [1, 1]}]
    }