class_name ScriptDetector extends BaseFileTypeDetector

var tag_inferer: TagInferer

func _init(_tag_inferer: TagInferer):
    tag_inferer = _tag_inferer

func detect(file_path: String, file_name: String) -> Dictionary:
    if file_name.ends_with(".gd"):
        var character_name = determine_name(file_path)
        var linked_scene = find_linked_scene(file_path)
        var metadata = {
            "type": "script",
            "tag": tag_inferer.infer_tag(file_path),
            "character_name": character_name,
            "last_modified": FileAccess.get_modified_time(file_path)
        }
        if linked_scene:
            metadata["linked_scene"] = linked_scene
        return metadata
    return {}

func find_linked_scene(script_path: String) -> String:
    var base_name = script_path.get_basename()
    var scene_path = base_name + ".tscn"
    if FileAccess.file_exists(scene_path):
        return scene_path
    
    var dir = script_path.get_base_dir()
    var dir_access = DirAccess.open(dir)
    if dir_access:
        dir_access.list_dir_begin()
        var file = dir_access.get_next()
        while file != "":
            if file.ends_with(".tscn") and file.get_basename() == script_path.get_file().get_basename():
                return dir + "/" + file
            file = dir_access.get_next()
        dir_access.list_dir_end()
    
    return ""