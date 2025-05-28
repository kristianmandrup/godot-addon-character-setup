class_name TagInferer extends RefCounted

func infer_tag(file_path: String) -> String:
    if file_path.contains("character") or file_path.contains("player"):
        return "character"
    elif file_path.contains("ui"):
        return "ui"
    return "generic"

