class_name FontDetector extends BaseFileTypeDetector

var tag_inferer: TagInferer
var extensions: Array[String] = [".tff"]

func _init(_tag_inferer: TagInferer, _extensions: Array[String]):
    tag_inferer = _tag_inferer
    extensions = _extensions || extensions

func detect(file_path: String, file_name: String) -> Dictionary:
    return {
        "type": "font",
        "tag": tag_inferer.infer_tag(file_path),
        "last_modified": FileAccess.get_modified_time(file_path)
    }