class_name DetectionArea extends RefCounted

var sprite_analyzer: SpriteAnalyzer
var debug_color: Color

func _init(_sprite_analyzer: SpriteAnalyzer):
    sprite_analyzer = _sprite_analyzer
    debug_color = ProjectSettings.get_setting("plugins/character_setup_plugin/detection_area_color", Color.GREEN)

func generate_detection_area(sprite_path: String) -> Area2D:
    var shape_data = sprite_analyzer.generate_collision_shape(sprite_path, SpriteAnalyzer.CollisionShapeType.CIRCLE, "feet")
    if shape_data.is_empty():
        return null
    
    var area = Area2D.new()
    var collision_shape = CollisionShape2D.new()
    var circle_shape = CircleShape2D.new()
    
    var base_radius = shape_data["size"].y * 0.4  # Based on feet circle
    circle_shape.radius = base_radius * 3.0  # 3x size
    collision_shape.shape = circle_shape
    collision_shape.debug_color = debug_color
    collision_shape.position = shape_data["offset"]
    
    area.add_child(collision_shape)
    return area