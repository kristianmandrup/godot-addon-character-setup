class_name Scanner extends RefCounted

enum ComparisonMethod { MODIFIED_TIME, FILE_HASH }

@export var comparison_method: ComparisonMethod = ComparisonMethod.MODIFIED_TIME
var detectors: Array[BaseFileTypeDetector] = []
var tag_inferer: TagInferer
var asset_manager: GameAssetManager

func _init():
    asset_manager = GameAssetManager.new()
    var api_key = ProjectSettings.get_setting("plugins/character_setup_plugin/api_key", "")
    tag_inferer = AITagDetector.new(api_key) if api_key else TagInferer.new()
    var image_extensions = ProjectSettings.get_setting("plugins/character_setup_plugin/image_extensions", [".png", ".jpg", ".jpeg", ".bmp"])
    var audio_extensions = ProjectSettings.get_setting("plugins/character_setup_plugin/audio_extensions", [".wav", ".ogg", ".mp3"])
    detectors = [
        ImageDetector.new(tag_inferer, image_extensions, asset_manager),
        AudioDetector.new(tag_inferer, audio_extensions, asset_manager),
        SceneDetector.new(tag_inferer),
        ScriptDetector.new(tag_inferer),
        OtherDetector.new(tag_inferer)
    ]

func scan(args: ScannerArgs) -> Dictionary:
    var file_map = {}
    var scan_metadata = {
        "last_scan_time": Time.get_unix_time_from_system(),
        "files": {}
    }
    
    var existing_file_map = load_file_map()
    var existing_scan_metadata = load_scan_metadata()
    var changed_files = []
    var scanned_files = []
    
    var dir = DirAccess.open(args.root_path)
    if DirAccess.get_open_error() != OK:
        print("Error accessing directory: ", args.root_path)
        return {}
    
    scan_directory(dir, file_map, scan_metadata, existing_scan_metadata, args, changed_files, scanned_files)
    
    remove_deleted_files(file_map, scan_metadata, existing_file_map, scanned_files)
    copy_unchanged_files(file_map, existing_file_map, changed_files)
    
    save_file_map(file_map)
    save_scan_metadata(scan_metadata)
    
    return file_map

func load_file_map() -> Dictionary:
    var file_map = {}
    if FileAccess.file_exists("res://addons/character_setup_plugin/file_map.json"):
        var file = FileAccess.open("res://addons/character_setup_plugin/file_map.json", FileAccess.READ)
        file_map = JSON.parse_string(file.get_as_text())
        file.close()
    return file_map

func load_scan_metadata() -> Dictionary:
    var scan_metadata = {"files": {}}
    if FileAccess.file_exists("res://addons/character_setup_plugin/scan_metadata.json"):
        var file = FileAccess.open("res://addons/character_setup_plugin/scan_metadata.json", FileAccess.READ)
        scan_metadata = JSON.parse_string(file.get_as_text())
        file.close()
    return scan_metadata

func save_file_map(file_map: Dictionary):
    var file = FileAccess.open("res://addons/character_setup_plugin/file_map.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(file_map, "  "))
    file.close()

func save_scan_metadata(scan_metadata: Dictionary):
    var file = FileAccess.open("res://addons/character_setup_plugin/scan_metadata.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(scan_metadata, "  "))
    file.close()

func scan_directory(dir: DirAccess, file_map: Dictionary, scan_metadata: Dictionary, existing_scan_metadata: Dictionary, args: ScannerArgs, changed_files: Array, scanned_files: Array):
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        var file_path = dir.get_current_dir() + "/" + file_name
        if should_ignore(file_path, args.ignore_patterns):
            file_name = dir.get_next()
            continue
        
        scanned_files.append(file_path)
        
        if dir.current_is_dir():
            var sub_dir = DirAccess.open(file_path)
            if DirAccess.get_open_error() == OK:
                scan_directory(sub_dir, file_map, scan_metadata, existing_scan_metadata, args, changed_files, scanned_files)
        else:
            process_file(file_path, file_name, file_map, scan_metadata, existing_scan_metadata, args.incremental, changed_files)
        
        file_name = dir.get_next()
    
    dir.list_dir_end()

func should_ignore(file_path: String, ignore_patterns: Array) -> bool:
    for pattern in ignore_patterns:
        if file_path.contains(pattern):
            return true
    return false

func process_file(file_path: String, file_name: String, file_map: Dictionary, scan_metadata: Dictionary, existing_scan_metadata: Dictionary, incremental: bool, changed_files: Array):
    var comparison_value = get_comparison_value(file_path)
    var prev_value = existing_scan_metadata.files.get(file_path, 0.0 if comparison_method == ComparisonMethod.MODIFIED_TIME else "")
    
    if not incremental or not existing_scan_metadata.files.has(file_path) or comparison_value != prev_value:
        changed_files.append(file_path)
        scan_metadata.files[file_path] = comparison_value
        
        for detector in detectors:
            var metadata = detector.detect(file_path, file_name)
            if not metadata.is_empty():
                file_map[file_path] = metadata
                break
    else:
        scan_metadata.files[file_path] = comparison_value

func get_comparison_value(file_path: String) -> Variant:
    if comparison_method == ComparisonMethod.MODIFIED_TIME:
        return FileAccess.get_modified_time(file_path)
    else:
        var file = FileAccess.open(file_path, FileAccess.READ)
        var content = file.get_as_binary()
        file.close()
        return content.md5_text()

func remove_deleted_files(file_map: Dictionary, scan_metadata: Dictionary, existing_file_map: Dictionary, scanned_files: Array):
    for file_path in existing_file_map.keys():
        if not scanned_files.has(file_path):
            file_map.erase(file_path)
            scan_metadata.files.erase(file_path)

func copy_unchanged_files(file_map: Dictionary, existing_file_map: Dictionary, changed_files: Array):
    for file_path in existing_file_map.keys():
        if not changed_files.has(file_path) and file_map.has(file_path):
            file_map[file_path] = existing_file_map[file_path]