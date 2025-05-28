class_name HitBox extends RefCounted

var sprite_analyzer: SpriteAnalyzer
var shape_type: SpriteAnalyzer.CollisionShapeType
var debug_color: Color

func _init(_sprite_analyzer: SpriteAnalyzer, _shape_type: SpriteAnalyzer.CollisionShapeType = SpriteAnalyzer.CollisionShapeType.RECTANGLE):
    sprite_analyzer = _sprite_analyzer
    shape_type = _shape_type
    debug_color = ProjectSettings.get_setting("plugins/character_setup_plugin/hit_box_color", Color.RED)

func generate_hit_box(sprite_path: String) -> CollisionShape2D:
    var shape_data = sprite_analyzer.generate_collision_shape(sprite_path, shape_type, "full")
    if shape_data.is_empty():
        return null
    var collision_shape = shape_data["shape"] as CollisionShape2D
    collision_shape.debug_color = debug_color
    return collision_shape