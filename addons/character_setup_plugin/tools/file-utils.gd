class_name FileUtils extends RefCounted

func scan_project_files(incremental: bool = true, ignore_patterns: Array = [".godot", ".import"])  -> Dictionary:
    var file_map = {}
    var scan_metadata = {
        "last_scan_time": Time.get_unix_time_from_system(),
        "files": {}
    }
    
    # Load existing file map and scan metadata
    var existing_file_map = {}
    var existing_scan_metadata = {"files": {}}
    if FileAccess.file_exists("res://addons/character_setup_plugin/file_map.json"):
        var file = FileAccess.open("res://addons/character_setup_plugin/file_map.json", FileAccess.READ)
        existing_file_map = JSON.parse_string(file.get_as_text())
        file.close()
    
    if FileAccess.file_exists("res://addons/character_setup_plugin/scan_metadata.json"):
        var file = FileAccess.open("res://addons/character_setup_plugin/scan_metadata.json", FileAccess.READ)
        existing_scan_metadata = JSON.parse_string(file.get_as_text())
        file.close()
    
    # Scan filesystem
    var dir = DirAccess.open("res://")
    var changed_files = []
    var scanned_files = []
    
    _scan_directory(dir, file_map, scan_metadata, existing_scan_metadata, incremental, changed_files, scanned_files, ignore_patterns)
    
    # Remove deleted files
    for file_path in existing_file_map.keys():
        if not scanned_files.has(file_path):
            file_map.erase(file_path)
            scan_metadata.files.erase(file_path)
    
    # Copy unchanged files from existing file map
    for file_path in existing_file_map.keys():
        if not changed_files.has(file_path) and file_map.has(file_path):
            file_map[file_path] = existing_file_map[file_path]
    
    # Save updated file map
    var file = FileAccess.open("res://addons/character_setup_plugin/file_map.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(file_map, "  "))
    file.close()
    
    # Save updated scan metadata
    file = FileAccess.open("res://addons/character_setup_plugin/scan_metadata.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(scan_metadata, "  "))
    file.close()
    
    return file_map

func get_file_hash(file_path: String) -> String:
    var file = FileAccess.open(file_path, FileAccess.READ)
    var content = file.get_as_binary()
    file.close()
    return content.md5_text()

func _scan_directory(dir: DirAccess, file_map: Dictionary, scan_metadata: Dictionary, existing_scan_metadata: Dictionary, incremental: bool, changed_files: Array, scanned_files: Array, ignore_patterns: Array = []):
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        var file_path = dir.get_current_dir() + "/" + file_name
        scanned_files.append(file_path)
        
        if dir.current_is_dir():
            var sub_dir = DirAccess.open(file_path)
            _scan_directory(sub_dir, file_map, scan_metadata, existing_scan_metadata, incremental, changed_files, scanned_files, ignore_patterns)
        else:
            var last_modified = FileAccess.get_modified_time(file_path)
            var prev_modified = existing_scan_metadata.files.get(file_path, 0.0)
            
            # Check if file is new or modified
            if not incremental or not existing_scan_metadata.files.has(file_path) or last_modified > prev_modified:
                changed_files.append(file_path)
                scan_metadata.files[file_path] = last_modified
                
                if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
                    var analysis = analyze_sprite_local(file_path)
                    file_map[file_path] = {
                        "type": "sprite",
                        "tag": _infer_tag(file_path),
                        "last_modified": last_modified,
                        "sprite_count": analysis.get("sprite_count", 1),
                        "rows": analysis.get("rows", 1),
                        "columns": analysis.get("columns", 1),
                        "collision_shapes": analysis.get("collision_shapes", [])
                    }
                elif file_name.ends_with(".tscn"):
                    file_map[file_path] = {
                        "type": "scene",
                        "tag": _infer_tag(file_path),
                        "last_modified": last_modified
                    }
                elif file_name.ends_with(".gd"):
                    file_map[file_path] = {
                        "type": "script",
                        "tag": _infer_tag(file_path),
                        "last_modified": last_modified
                    }
                else:
                    file_map[file_path] = {
                        "type": "other",
                        "tag": "generic",
                        "last_modified": last_modified
                    }
            else:
                # Preserve unchanged file's metadata
                scan_metadata.files[file_path] = last_modified
        
        file_name = dir.get_next()
    
    dir.list_dir_end()

func _infer_tag(file_path: String) -> String:
    if file_path.contains("character") or file_path.contains("player"):
        return "character"
    elif file_path.contains("ui"):
        return "ui"
    return "generic"

func analyze_sprite_local(image_path: String) -> Dictionary:
    if not check_opencv_availability():
        print("Installing Python dependencies...")
        if not install_python_dependencies():
            print("Falling back to heuristic analysis due to dependency installation failure.")
            return heuristic_sprite_analysis(image_path)
    
    var python_path = get_python_path()
    if python_path == "":
        print("Python not found. Please install Python 3.x.")
        return heuristic_sprite_analysis(image_path)
    
    var script_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/scripts/sprite_analyzer.py")
    var absolute_image_path = ProjectSettings.globalize_path(image_path)
    
    if not FileAccess.file_exists("res://addons/character_setup_plugin/scripts/sprite_analyzer.py"):
        print("Python script not found: sprite_analyzer.py")
        return heuristic_sprite_analysis(image_path)
    if not FileAccess.file_exists(image_path):
        print("Image file not found: ", image_path)
        return heuristic_sprite_analysis(image_path)
    
    var output = []
    var exit_code = OS.execute(python_path, [script_path, absolute_image_path], output, true)
    
    if exit_code == 0 and output.size() > 0:
        var json = JSON.parse_string(output[0])
        if json.has("error"):
            print("Python error: ", json.error)
            return heuristic_sprite_analysis(image_path)
        return json
    else:
        print("Python script failed: ", output)
        return heuristic_sprite_analysis(image_path)

func heuristic_sprite_analysis(image_path: String) -> Dictionary:
    var image = Image.load_from_file(image_path)
    return {
        "sprite_count": 1,
        "rows": 1,
        "columns": 1,
        "collision_shapes": [[Vector2(0, 0), Vector2(image.get_width(), 0), Vector2(image.get_width(), image.get_height()), Vector2(0, image.get_height())]]
    }

func check_opencv_availability() -> bool:
    var output = []
    var exit_code = OS.execute("python", ["-c", "import cv2, numpy"], output, true)
    if exit_code != 0:
        print("Error: Python dependencies missing. Run 'pip install -r res://addons/character_setup_plugin/requirements.txt' to install opencv-python and numpy.")
        return false
    return true

func install_python_dependencies() -> bool:
    var python_path = get_python_path()
    if python_path == "":
        print("Error: Python not found. Please install Python 3.x.")
        return false
    
    var requirements_path = ProjectSettings.globalize_path("res://addons/character_setup_plugin/requirements.txt")
    if not FileAccess.file_exists("res://addons/character_setup_plugin/requirements.txt"):
        print("Error: requirements.txt not found.")
        return false
    
    var output = []
    var exit_code = OS.execute(python_path, ["-m", "pip", "install", "-r", requirements_path], output, true)
    
    if exit_code == 0:
        print("Python dependencies installed successfully.")
        return true
    else:
        print("Failed to install dependencies: ", output)
        return false

func get_python_path() -> String:
    var candidates = [
        "python",
        "python3",
        "C:/Python39/python.exe",
        "/usr/bin/python3",
        "/usr/local/bin/python3"
    ]
    for candidate in candidates:
        var output = []
        if OS.execute(candidate, ["-c", "import sys"], output, true) == 0:
            return candidate
    return ""