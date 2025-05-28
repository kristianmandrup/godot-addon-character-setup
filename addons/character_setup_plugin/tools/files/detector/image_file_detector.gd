class_name ImageFileDetector extends BaseFileTypeDetector

var tag_inferer: TagInferer
var extensions: Array[String]

func _init(_tag_inferer: TagInferer, _extensions: Array[String] = [".png", ".jpg", ".jpeg", ".webp"]):
    tag_inferer = _tag_inferer
    extensions = _extensions

func detect(file_path: String, file_name: String) -> Dictionary:
    for ext in extensions:
        if file_name.ends_with(ext):
            var analysis = analyze_sprite_local(file_path)
            return {
                "type": "sprite",
                "tag": tag_inferer.infer_tag(file_path),
                "last_modified": FileAccess.get_modified_time(file_path),
                "sprite_count": analysis.get("sprite_count", 1),
                "rows": analysis.get("rows", 1),
                "columns": analysis.get("columns", 1),
                "collision_shapes": analysis.get("collision_shapes", [])
            }
    return {}