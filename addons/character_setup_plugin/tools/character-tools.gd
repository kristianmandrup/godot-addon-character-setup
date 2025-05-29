func create_character_scene(scene_path: String, name):
    var scene = Node2D.new()
    var character = CharacterBody2D.new()
    character.name = name or "Player"
    scene.add_child(character)
    character.owner = scene
    ResourceSaver.save(scene, scene_path)
    return "Scene created at " + scene_path

func assign_sprite(scene_path: String, node_name: String, sprite_path: String):
    var scene = ResourceLoader.load(scene_path, "PackedScene")
    var instance = scene.instantiate()
    var sprite_node = instance.find_child(node_name)
    if sprite_node is Sprite2D:
        sprite_node.texture = ResourceLoader.load(sprite_path)
        ResourceSaver.save(instance, scene_path)
        return "Sprite assigned to " + node_name
    return "Error: Node not found or not a Sprite2D"

func _enter_tree():
    if not PythonTools.check_opencv_availability():
        print("Installing Python dependencies...")
        if not PythonTools.install_python_dependencies():
            print("Try creating a virtual environment: 'python -m venv venv' and activate it before running Godot.")        
    
func add_collision_shape(scene_path: String, node_name: String, collision_points: Array):
    var scene = ResourceLoader.load(scene_path, "PackedScene")
    var instance = scene.instantiate()
    var node = instance.find_child(node_name)
    if node:
        var collision_shape = CollisionPolygon2D.new()
        collision_shape.polygon = collision_points.map(func(p): return Vector2(p[0], p[1]))
        node.add_child(collision_shape)
        collision_shape.owner = instance
        ResourceSaver.save(instance, scene_path)
        print("Collision shape added to ", node_name)    


func cache_analysis(image_path: String, result: Dictionary):
    var file_map = {}
    var file = FileAccess.open("res://addons/character_setup_plugin/file_map.json", FileAccess.READ)
    if file:
        file_map = JSON.parse_string(file.get_as_text())
        file.close()
    file_map[image_path] = result
    file = FileAccess.open("res://addons/character_setup_plugin/file_map.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(file_map, "  "))
    file.close()