class_name BaseFileTypeDetector extends RefCounted

var tag_inferer: TagInferer
var extensions: Array[String] = []

func _init(_tag_inferer: TagInferer, _extensions: Array[String] = []):
    tag_inferer = _tag_inferer
    extensions = _extensions.map(func(ext): return "." + ext.trim_prefix("."))

func detect(file_path: String, file_name: String) -> Dictionary:
    return {
        "type": "other",
        "tag": tag_inferer.infer_tag(file_path),
        "last_modified": FileAccess.get_modified_time(file_path)
    }


