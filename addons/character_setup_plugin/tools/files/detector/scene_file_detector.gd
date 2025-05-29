class_name SceneDetector extends BaseFileTypeDetector

var tag_inferer: TagInferer

func _init(_tag_inferer: TagInferer):
    tag_inferer = _tag_inferer

func detect(file_path: String, file_name: String) -> Dictionary:
    if file_name.ends_with(".tscn"):
        var character_name = determine_name(file_path)
        return {
            "type": "scene",
            "tag": tag_inferer.infer_tag(file_path),
            "character_name": character_name,
            "last_modified": FileAccess.get_modified_time(file_path)
        }