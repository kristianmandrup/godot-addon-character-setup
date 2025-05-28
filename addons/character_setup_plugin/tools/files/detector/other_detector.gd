class_name OtherDetector extends BaseFileTypeDetector

var tag_inferer: TagInferer

func _init(_tag_inferer: TagInferer):
    tag_inferer = _tag_inferer

func detect(file_path: String, file_name: String) -> Dictionary:
    return {
        "type": "other",
        "tag": tag_inferer.infer_tag(file_path),
        "last_modified": FileAccess.get_modified_time(file_path)
    }